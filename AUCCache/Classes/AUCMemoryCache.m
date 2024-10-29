//
//  AUCMemoryCache.m
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import "AUCMemoryCache.h"
#import "AUCTypeDefines.h"
#import "AUCCacheConfig.h"
#import "AUCCompat.h"
#import "AUCInternalMacros.h"

static void * AUCMemoryCacheContext = &AUCMemoryCacheContext;
@interface AUCMemoryCache <KeyType, ObjectType> ()

@property (nonatomic, strong, nullable) AUCCacheConfig *config;
#if AU_UIKIT
// 弱引用缓存表
@property (nonatomic, strong, nonnull) NSMapTable<KeyType, ObjectType> *weakCache;
// 保持对 “weakCache” 的访问线程安全的信号量锁
@property (nonatomic, strong, nonnull) dispatch_semaphore_t weakCacheLock;
#endif

@end

@implementation AUCMemoryCache
- (void)dealloc {
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) context:AUCMemoryCacheContext];
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) context:AUCMemoryCacheContext];
#if AU_UIKIT
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    self.delegate = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [[AUCCacheConfig alloc] init];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithConfig:(AUCCacheConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    AUCCacheConfig *config = self.config;
    self.totalCostLimit = config.maxMemoryCost;
    self.countLimit = config.maxMemoryCount;

    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) options:0 context:AUCMemoryCacheContext];
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) options:0 context:AUCMemoryCacheContext];

#if AU_UIKIT
    self.weakCache = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    self.weakCacheLock = dispatch_semaphore_create(1);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
#endif
}

// macOS 使用虚拟内存，并且在内存警告时不清除缓存。所以只需要在 iOS/tvOS 平台上进行覆盖。
#if AU_UIKIT
- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    // 只删除缓存，但保留弱缓存
    [super removeAllObjects];
}

// `setObject:forKey:` 只需以 0 成本调用即可。覆盖这个就足够了
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    [super setObject:obj forKey:key cost:g];
    if (!self.config.shouldUseWeakMemoryCache) return;
    
    if (key && obj) {
        // 存储弱缓存
        AUC_DISPATCH_SEMAPHORE_LOCK(self.weakCacheLock);
        [self.weakCache setObject:obj forKey:key];
        AUC_DISPATCH_SEMAPHORE_UNLOCK(self.weakCacheLock);
    }
}

- (id)objectForKey:(id)key {
    id obj = [super objectForKey:key];
    if (!self.config.shouldUseWeakMemoryCache) return obj;
    
    if (key && !obj) {
        // 检查弱引用缓存
        AUC_DISPATCH_SEMAPHORE_LOCK(self.weakCacheLock);
        obj = [self.weakCache objectForKey:key];
        AUC_DISPATCH_SEMAPHORE_UNLOCK(self.weakCacheLock);
        if (obj) {
            // 同步缓存
            NSUInteger cost = 0;
            [super setObject:obj forKey:key cost:cost];
        }
    }
    return obj;
}

- (void)removeObjectForKey:(id)key {
    [super removeObjectForKey:key];
    if (!self.config.shouldUseWeakMemoryCache) return;
    if (key) {
        // 删除弱引用缓存
        AUC_DISPATCH_SEMAPHORE_LOCK(self.weakCacheLock);
        [self.weakCache removeObjectForKey:key];
        AUC_DISPATCH_SEMAPHORE_UNLOCK(self.weakCacheLock);
    }
}

- (void)removeAllObjects {
    [super removeAllObjects];
    if (!self.config.shouldUseWeakMemoryCache) return;
    
    // 手动删除也应该删除弱引用缓存
    AUC_DISPATCH_SEMAPHORE_LOCK(self.weakCacheLock);
    [self.weakCache removeAllObjects];
    AUC_DISPATCH_SEMAPHORE_UNLOCK(self.weakCacheLock);
}
#endif

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == AUCMemoryCacheContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCost))]) {
            self.totalCostLimit = self.config.maxMemoryCost;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCount))]) {
            self.countLimit = self.config.maxMemoryCount;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
