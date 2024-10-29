//
//  AUCCacheCombine.m
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import "AUCCacheCombine.h"
#import "AUCMemoryCache.h"
#import "AUCDiskCache.h"
#import "AUCCacheConfig.h"
#import "AUCCompat.h"
#import "AUCCacheOperation.h"

@interface AUCCacheCombine ()

@property (nonatomic, strong, readwrite, nonnull) id<AUCMemoryCacheProtocol> memoryCache;
@property (nonatomic, strong, readwrite, nonnull) id<AUCDiskCacheProtocol> diskCache;
@property (nonatomic, copy, readwrite, nonnull) AUCCacheConfig *config;
@property (nonatomic, copy, readwrite, nonnull) NSString *diskCachePath;
@property (nonatomic, strong, nullable) dispatch_queue_t ioQueue;

@end

@implementation AUCCacheCombine
#pragma mark - 单例, 初始化, 反初始化
+ (nonnull instancetype)sharedCache {
    static dispatch_once_t once;
    static id _instance;
    dispatch_once(&once, ^{
        _instance = [[AUCCacheCombine alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    return [self initWithNamespace:@"default"];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns {
    return [self initWithNamespace:ns diskCacheDirectory:nil];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns
                       diskCacheDirectory:(nullable NSString *)directory {
    return [self initWithNamespace:ns diskCacheDirectory:directory config:AUCCacheConfig.defaultConfig];
}

- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns
                       diskCacheDirectory:(nullable NSString *)directory
                                   config:(nullable AUCCacheConfig *)config {
    if ((self = [super init])) {
        NSAssert(ns, @"缓存的 namespace 不可以为 nil");
        
        // 创建 IO 串行队列
        _ioQueue = dispatch_queue_create("com.vantage.AUCCache", DISPATCH_QUEUE_SERIAL);
        
        if (!config) {
            config = AUCCacheConfig.defaultConfig;
        }
        
        // 确保更改当前配置不会意外影响其他缓存的配置
        _config = [config copy];
        
        // 初始化内存缓存
        NSAssert([config.memoryCacheClass conformsToProtocol:@protocol(AUCMemoryCacheProtocol)], @"自定义内存缓存类必须符合 `AUCMemoryCache` 协议");
        _memoryCache = [[config.memoryCacheClass alloc] initWithConfig:_config];
        
        // 初始化磁盘缓存
        if (directory != nil) {
            _diskCachePath = [directory stringByAppendingPathComponent:ns];
        } else {
            NSString *path = [[[self userCacheDirectory] stringByAppendingPathComponent:@"com.vantage.AUCCache"] stringByAppendingPathComponent:ns];
            _diskCachePath = path;
        }
        
        NSAssert([config.diskCacheClass conformsToProtocol:@protocol(AUCDiskCacheProtocol)], @"自定义磁盘缓存类必须符合 `AUCDiskCache` 协议");
        _diskCache = [[config.diskCacheClass alloc] initWithCachePath:_diskCachePath config:_config];
        
        // 如果需要，检查并迁移磁盘缓存目录
        [self migrateDiskCacheDirectory];

#if AU_UIKIT
        // 订阅 Application 事件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
#endif
#if AU_OS_MAC
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
#endif
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 缓存路径
- (nullable NSString *)cachePathForKey:(nullable NSString *)key {
    if (!key) return nil;
    return [self.diskCache cachePathForKey:key];
}

- (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

- (void)migrateDiskCacheDirectory {
    if ([self.diskCache isKindOfClass:[AUCDiskCache class]]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // ~/Library/Caches/com.vantage.AUCCache/default/
            NSString *newDefaultPath = [[[self userCacheDirectory] stringByAppendingPathComponent:@"com.vantage.AUCCache"] stringByAppendingPathComponent:@"default"];
            // ~/Library/Caches/default/com.vantage.AUCCache.default/
            NSString *oldDefaultPath = [[[self userCacheDirectory] stringByAppendingPathComponent:@"default"] stringByAppendingPathComponent:@"com.vantage.AUCCache.default"];
            dispatch_async(self.ioQueue, ^{
                [((AUCDiskCache *)self.diskCache) moveCacheDirectoryFromPath:oldDefaultPath toPath:newDefaultPath];
            });
        });
    }
}

#pragma mark - Store Ops
- (void)storeData:(id)data
           forKey:(NSString *)key
       completion:(AUCVoidParamsBlock)completionBlock {
    [self storeData:data forKey:key toDisk:YES completion:completionBlock];
}

- (void)storeData:(id)data
           forKey:(NSString *)key
           toDisk:(BOOL)toDisk
       completion:(AUCVoidParamsBlock)completionBlock {
    return [self storeData:data forKey:key toMemory:YES toDisk:toDisk completion:completionBlock];
}

- (void)storeData:(nullable id)data
            forKey:(nullable NSString *)key
          toMemory:(BOOL)toMemory
            toDisk:(BOOL)toDisk
        completion:(nullable AUCVoidParamsBlock)completionBlock {
    if (!data || [data isKindOfClass:NSNull.class] || !key) {
        if (completionBlock) completionBlock();
        return;
    }
    
    // 如果内存缓存被允许的话
    if (toMemory && self.config.shouldCacheInMemory) {
        NSUInteger cost = 0;
        // TODO: 调整此缓存对象的“成本” (cost)值, `NSCache` 会根据所有缓存对象的成本以及设定的最大成本 (totalCostLimit) 来决定何时自动清除缓存对象。当缓存的总成本超过设定的 `totalCostLimit` 时，系统会根据需要自动移除一些缓存对象，优先移除成本较大的对象，以释放空间。
        [self.memoryCache setObject:data forKey:key cost:cost];
    }
    
    if (toDisk) {
        dispatch_async(self.ioQueue, ^{
            @autoreleasepool {
                NSData *transferData = nil;
                NSError *error = nil;
                /**
                 * @note `NSJSONWritingOptions` 枚举各参数
                 * `NSJSONWritingPrettyPrinted` - 使生成的 `JSON` 更具可读性（即带有换行和缩进）。适用于调试或开发中希望查看整齐的 `JSON` 格式。此选项生成的 `JSON` 体积稍大，适合调试或非生产环境。对于生产环境，通常不使用这个选项。
                 * `NSJSONWritingSortedKeys` (iOS 11.0+) - 确保字典的键在 `JSON` 输出中按字母顺序排列。对于需要对 `JSON` 进行排序（如生成一致的签名或调试）的情况很有用。
                 * `NSJSONWritingFragmentsAllowed` (iOS 13.0+) - 通常 `JSON` 必须以数组或字典作为顶层结构，使用此选项可以将其他基本类型（如字符串、数字、布尔值）序列化为有效的`JSON`。
                 * `NSJSONWritingWithoutEscapingSlashes` - 使用此选项时，`JSON` 中的斜杠字符（/）将不会被转义为 \/。
                 */
                if ([data isKindOfClass:NSData.class]) {
                    transferData = (NSData *)data;
                } else if ([data isKindOfClass:NSString.class]) {
                    transferData = [(NSString *)data dataUsingEncoding:NSUTF8StringEncoding];
                } else if ([data isKindOfClass:NSDictionary.class] || [data isKindOfClass:NSArray.class]) {
                    transferData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
                }
                
                if (transferData && error == nil) {
                    [self _storeDataToDisk:transferData forKey:key];
                }
            }
            
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock();
                });
            }
        });
    } else {
        if (completionBlock) {
            completionBlock();
        }
    }
}

- (void)storeDataToMemory:(id)data forKey:(NSString *)key {
    if (!data || !key) return;
    NSUInteger cost = 0;
    [self.memoryCache setObject:data forKey:key cost:cost];
}

- (void)storeDataToDisk:(nullable NSData *)data
                 forKey:(nullable NSString *)key {
    if (!data || !key) return;
    
    dispatch_sync(self.ioQueue, ^{
        [self _storeDataToDisk:data forKey:key];
    });
}

// 确保按调用者从 io 队列调用
- (void)_storeDataToDisk:(nullable NSData *)data forKey:(nullable NSString *)key {
    if (!data || !key) return;
    
    [self.diskCache setData:data forKey:key];
}

#pragma mark - Query and Retrieve Ops
- (void)diskCacheExistsWithKey:(nullable NSString *)key completion:(nullable AUCCacheCheckCompletionBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        BOOL exists = [self _diskCacheDataExistsWithKey:key];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(exists);
            });
        }
    });
}

- (BOOL)diskCacheExistsWithKey:(nullable NSString *)key {
    if (!key) return NO;
    
    __block BOOL exists = NO;
    dispatch_sync(self.ioQueue, ^{
        exists = [self _diskCacheDataExistsWithKey:key];
    });
    
    return exists;
}

// 确保从 io 队列调用
- (BOOL)_diskCacheDataExistsWithKey:(nullable NSString *)key {
    if (!key) return NO;
    
    return [self.diskCache containsDataForKey:key];
}

- (nullable NSData *)diskCacheDataForKey:(nullable NSString *)key {
    if (!key) return nil;
    __block NSData *data = nil;
    dispatch_sync(self.ioQueue, ^{
        data = [self diskCacheDataBySearchingAllPathsForKey:key];
    });
    
    return data;
}

- (nullable id)dataFromMemoryCacheForKey:(nullable NSString *)key {
    return [self.memoryCache objectForKey:key];
}

- (nullable id)dataFromDiskCacheForKey:(nullable NSString *)key {
    id diskData = [self diskCacheDataForKey:key];
    if (diskData && self.config.shouldCacheInMemory) {
        NSUInteger cost = 0;
        [self.memoryCache setObject:diskData forKey:key cost:cost];
    }

    return diskData;
}

- (nullable id)dataFromCacheForKey:(nullable NSString *)key {
    // 首先查询内存缓存
    id data = [self dataFromMemoryCacheForKey:key];
    if (data) return data;
    
    // 其次查询磁盘缓存
    data = [self dataFromDiskCacheForKey:key];
    return data;
}

- (nullable NSData *)diskCacheDataBySearchingAllPathsForKey:(nullable NSString *)key {
    if (!key) {
        return nil;
    }
    
    NSData *data = [self.diskCache dataForKey:key];
    if (data) return data;
    
    // 自定义预加载缓存的附加缓存路径
    if (self.additionalCachePathBlock) {
        NSString *filePath = self.additionalCachePathBlock(key);
        if (filePath) {
            data = [NSData dataWithContentsOfFile:filePath options:self.config.diskCacheReadingOptions error:nil];
        }
    }

    return data;
}

- (nullable NSOperation *)queryCacheOperationForKey:(NSString *)key done:(AUCCacheQueryCompletionBlock)doneBlock {
    return [self queryCacheOperationForKey:key options:0 done:doneBlock];
}

- (nullable NSOperation *)queryCacheOperationForKey:(NSString *)key options:(AUCCacheLoadOptions)loadOptions done:(AUCCacheQueryCompletionBlock)doneBlock {
    return [self queryCacheOperationForKey:key options:loadOptions context:nil done:doneBlock];
}

- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key options:(AUCCacheLoadOptions)loadOptions context:(nullable AUCCacheContext *)context done:(nullable AUCCacheQueryCompletionBlock)doneBlock {
    if (!key) {
        if (doneBlock) doneBlock(nil, AUCCacheTypeNone);
        return nil;
    }
    
    // 首先检查内存缓存
    id memoryData = [self dataFromMemoryCacheForKey:key];
    BOOL shouldQueryMemoryOnly = (memoryData && !(loadOptions & AUCCacheLoadFromMemoryData));
    if (shouldQueryMemoryOnly) {
        if (doneBlock) doneBlock(memoryData, AUCCacheTypeMemory);
        return nil;
    }
    
    // 其次检查磁盘缓存
    NSOperation *operation = [NSOperation new];
    
    // 检查是否需要同步查询磁盘
    // 1. 内存缓存命中 & memoryDataSync
    // 2. 内存缓存未命中 & diskDataSync
    BOOL shouldQueryDiskSync = ((memoryData && loadOptions & AUCCacheLoadFromMemoryDataSync) ||
                                (!memoryData && loadOptions & AUCCacheLoadFromDiskDataSync));
    void(^queryDiskBlock)(void) =  ^{
        if (operation.isCancelled) {
            if (doneBlock) doneBlock(nil, AUCCacheTypeNone);
            return;
        }
        
        @autoreleasepool {
            NSData *diskData = [self diskCacheDataBySearchingAllPathsForKey:key];
            AUCCacheType cacheType = AUCCacheTypeNone;

            if (diskData) {
                cacheType = AUCCacheTypeDisk;
                if (self.config.shouldCacheInMemory) {
                    NSUInteger cost = 0;
                    NSError *error = nil;
                    id localeResponse = [NSJSONSerialization JSONObjectWithData:diskData options:NSJSONReadingFragmentsAllowed error:&error];
                    if (error) {
                        [self.memoryCache setObject:diskData forKey:key cost:cost];
                    } else {
                        [self.memoryCache setObject:localeResponse forKey:key cost:cost];
                    }
                }
            }
            // NSDictionary、NSArray、NSString、NSData
            // 保持回调给上层的数据结构和内存缓存一致
            if (memoryData && [memoryData isKindOfClass:NSData.class]) {
                if (doneBlock) {
                    if (shouldQueryDiskSync) {
                        doneBlock(diskData, cacheType);
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            doneBlock(diskData, cacheType);
                        });
                    }
                }
            } else if (diskData) {
                // 将磁盘 `Data` 数据转换成 `JSON` 数据返回给上层
                NSError *error = nil;
                id localeResponse = [NSJSONSerialization JSONObjectWithData:diskData options:NSJSONReadingFragmentsAllowed error:&error];
                if (!error && doneBlock) {
                    if (shouldQueryDiskSync) {
                        doneBlock(localeResponse, cacheType);
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            doneBlock(localeResponse, cacheType);
                        });
                    }
                }
            }
        }
    };
    
    // 在 ioQueue 中查询，以确保 IO 安全
    if (shouldQueryDiskSync) {
        dispatch_sync(self.ioQueue, queryDiskBlock);
    } else {
        dispatch_async(self.ioQueue, queryDiskBlock);
    }
    
    return operation;
}

#pragma mark - Remove Ops
- (void)removeCacheForKey:(nullable NSString *)key withCompletion:(nullable AUCVoidParamsBlock)completion {
    [self removeCacheForKey:key fromDisk:YES withCompletion:completion];
}

- (void)removeCacheForKey:(nullable NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(nullable AUCVoidParamsBlock)completion {
    [self removeCacheForKey:key fromMemory:YES fromDisk:fromDisk withCompletion:completion];
}

- (void)removeCacheForKey:(nullable NSString *)key fromMemory:(BOOL)fromMemory fromDisk:(BOOL)fromDisk withCompletion:(nullable AUCVoidParamsBlock)completion {
    if (key == nil) return;

    if (fromMemory && self.config.shouldCacheInMemory) {
        [self.memoryCache removeObjectForKey:key];
    }

    if (fromDisk) {
        dispatch_async(self.ioQueue, ^{
            [self.diskCache removeCacheForKey:key];
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        });
    } else if (completion) {
        completion();
    }
}

#pragma mark - Cache clean Ops
- (void)clearMemory {
    [self.memoryCache removeAllObjects];
}

- (void)clearDiskOnCompletion:(nullable AUCVoidParamsBlock)completion {
    dispatch_async(self.ioQueue, ^{
        [self.diskCache removeAllData];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)deleteOldFilesWithCompletionBlock:(nullable AUCVoidParamsBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        [self.diskCache removeExpiredData];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

#pragma mark - UIApplicationWillTerminateNotification
#if AU_UIKIT || AU_OS_MAC
- (void)applicationWillTerminate:(NSNotification *)notification {
    [self deleteOldFilesWithCompletionBlock:nil];
}
#endif

#pragma mark - UIApplicationDidEnterBackgroundNotification
#if AU_UIKIT
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (!self.config.shouldRemoveExpiredDataWhenEnterBackground) return;
    
    Class ApplicationClass = NSClassFromString(@"UIApplication");
    if (!ApplicationClass || ![ApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // 通过标记位置来清理任何未完成的任务事务
        // 彻底停止或结束任务
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];

    // 启动长时间运行的任务并立即返回
    [self deleteOldFilesWithCompletionBlock:^{
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];
}
#endif

#pragma mark - Cache Info
- (NSUInteger)totalDiskSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        size = [self.diskCache totalSize];
    });
    return size;
}

- (NSUInteger)totalDiskCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        count = [self.diskCache totalCount];
    });
    return count;
}

- (BOOL)isWhitelistApisContainsKey:(NSString *)key {
    BOOL isContains = NO;
    AUCCacheConfig *config = self.config;
    for (NSString *api in config.whitelistAPIs) {
        if (![api hasPrefix:@"http"]) {
            NSString *adaptApi = api;
            if ([api hasPrefix:@"/"]) {
                adaptApi = [NSString stringWithFormat:@"%@%@", config.baseURL, api];
            } else {
                adaptApi = [NSString stringWithFormat:@"%@/%@", config.baseURL, api];
            }
            if ([adaptApi isEqualToString:key]) {
                isContains = YES;
                break;
            }
            continue;
        } else if ([api isEqualToString:key]) {
            isContains = YES;
            break;
        }
    }
    return isContains;
}

@end

#pragma mark - AUCCache
@implementation AUCCacheCombine (AUCCache)
- (nullable id<AUCCacheOperation>)queryCacheDataForKey:(nullable NSString *)key
                                              manually:(BOOL)manually
                                               options:(AUCCacheOptions)options
                                               context:(nullable AUCCacheContext *)context
                                            completion:(nullable AUCCacheQueryCompletionBlock)completionBlock {
    // 白名单过滤
    BOOL isContains = [self isWhitelistApisContainsKey:key];
    if (!isContains && manually == NO) return nil;
    
    AUCCacheLoadOptions loadOptions = 0;
    if (options & AUCCacheQueryMemoryData) loadOptions |= AUCCacheLoadFromMemoryData;
    if (options & AUCCacheQueryMemoryDataSync) loadOptions |= AUCCacheLoadFromMemoryDataSync;
    if (options & AUCCacheQueryDiskDataSync) loadOptions |= AUCCacheLoadFromDiskDataSync;
    
    return [self queryCacheOperationForKey:key options:loadOptions context:context done:completionBlock];
}

- (void)storeData:(nullable id)data
           forKey:(nullable NSString *)key
         manually:(BOOL)manually
        cacheType:(AUCCacheType)cacheType
       completion:(nullable AUCVoidParamsBlock)completionBlock {
    // 白名单过滤
    BOOL isContains = [self isWhitelistApisContainsKey:key];
    if (!isContains && manually == NO) return;
    
    switch (cacheType) {
        case AUCCacheTypeNone: {
            [self storeData:data forKey:key toMemory:NO toDisk:NO completion:completionBlock];
        }
            break;
        case AUCCacheTypeMemory: {
            [self storeData:data forKey:key toMemory:YES toDisk:NO completion:completionBlock];
        }
            break;
        case AUCCacheTypeDisk: {
            [self storeData:data forKey:key toMemory:NO toDisk:YES completion:completionBlock];
        }
            break;
        case AUCCacheTypeAll: {
            [self storeData:data forKey:key toMemory:YES toDisk:YES completion:completionBlock];
        }
            break;
        default: {
            if (completionBlock) completionBlock();
        }
            break;
    }
}

- (void)removeCacheForKey:(nullable NSString *)key
               cacheType:(AUCCacheType)cacheType
              completion:(nullable AUCVoidParamsBlock)completionBlock {
    switch (cacheType) {
        case AUCCacheTypeNone: {
            [self removeCacheForKey:key fromMemory:NO fromDisk:NO withCompletion:completionBlock];
        }
            break;
        case AUCCacheTypeMemory: {
            [self removeCacheForKey:key fromMemory:YES fromDisk:NO withCompletion:completionBlock];
        }
            break;
        case AUCCacheTypeDisk: {
            [self removeCacheForKey:key fromMemory:NO fromDisk:YES withCompletion:completionBlock];
        }
            break;
        case AUCCacheTypeAll: {
            [self removeCacheForKey:key fromMemory:YES fromDisk:YES withCompletion:completionBlock];
        }
            break;
        default: {
            if (completionBlock) completionBlock();
        }
            break;
    }
}

- (void)containsCacheForKey:(nullable NSString *)key
                 cacheType:(AUCCacheType)cacheType
                completion:(nullable AUCCacheContainsCompletionBlock)completionBlock {
    switch (cacheType) {
        case AUCCacheTypeNone: {
            if (completionBlock) completionBlock(AUCCacheTypeNone);
        }
            break;
        case AUCCacheTypeMemory: {
            BOOL isInMemoryCache = ([self dataFromMemoryCacheForKey:key] != nil);
            if (completionBlock) {
                completionBlock(isInMemoryCache ? AUCCacheTypeMemory : AUCCacheTypeNone);
            }
        }
            break;
        case AUCCacheTypeDisk: {
            [self diskCacheExistsWithKey:key completion:^(BOOL isInDiskCache) {
                if (completionBlock) {
                    completionBlock(isInDiskCache ? AUCCacheTypeDisk : AUCCacheTypeNone);
                }
            }];
        }
            break;
        case AUCCacheTypeAll: {
            BOOL isInMemoryCache = ([self dataFromMemoryCacheForKey:key] != nil);
            if (isInMemoryCache) {
                if (completionBlock) completionBlock(AUCCacheTypeMemory);
                return;
            }
            [self diskCacheExistsWithKey:key completion:^(BOOL isInDiskCache) {
                if (completionBlock) {
                    completionBlock(isInDiskCache ? AUCCacheTypeDisk : AUCCacheTypeNone);
                }
            }];
        }
            break;
        default:
            if (completionBlock) completionBlock(AUCCacheTypeNone);
            break;
    }
}

- (void)clearWithCacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock {
    switch (cacheType) {
        case AUCCacheTypeNone: {
            if (completionBlock) completionBlock();
        }
            break;
        case AUCCacheTypeMemory: {
            [self clearMemory];
            if (completionBlock) completionBlock();
        }
            break;
        case AUCCacheTypeDisk: {
            [self clearDiskOnCompletion:completionBlock];
        }
            break;
        case AUCCacheTypeAll: {
            [self clearMemory];
            [self clearDiskOnCompletion:completionBlock];
        }
            break;
        default: {
            if (completionBlock) completionBlock();
        }
            break;
    }
}

- (void)calculateCacheSize:(AUCCacheCalculateSizeBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        NSUInteger fileCount = [self.diskCache totalCount];
        NSUInteger totalSize = [self.diskCache totalSize];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

- (void)storeDataManually:(id)data
                   forKey:(NSString *)key
                cacheType:(AUCCacheType)cacheType
               completion:(AUCVoidParamsBlock)completionBlock {
    switch (cacheType) {
        case AUCCacheTypeNone: {
            [self storeData:data forKey:key toMemory:NO toDisk:NO completion:completionBlock];
        }
            break;
        case AUCCacheTypeMemory: {
            [self storeData:data forKey:key toMemory:YES toDisk:NO completion:completionBlock];
        }
            break;
        case AUCCacheTypeDisk: {
            [self storeData:data forKey:key toMemory:NO toDisk:YES completion:completionBlock];
        }
            break;
        case AUCCacheTypeAll: {
            [self storeData:data forKey:key toMemory:YES toDisk:YES completion:completionBlock];
        }
            break;
        default: {
            if (completionBlock) completionBlock();
        }
            break;
    }
}

- (id<AUCCacheOperation>)queryCacheDataManuallyForKey:(NSString *)key
                                              options:(AUCCacheOptions)options
                                              context:(AUCCacheContext *)context
                                           completion:(AUCCacheQueryCompletionBlock)completionBlock {
    AUCCacheLoadOptions loadOptions = 0;
    if (options & AUCCacheQueryMemoryData) loadOptions |= AUCCacheLoadFromMemoryData;
    if (options & AUCCacheQueryMemoryDataSync) loadOptions |= AUCCacheLoadFromMemoryDataSync;
    if (options & AUCCacheQueryDiskDataSync) loadOptions |= AUCCacheLoadFromDiskDataSync;
    
    return [self queryCacheOperationForKey:key options:loadOptions context:context done:completionBlock];
}

@end
