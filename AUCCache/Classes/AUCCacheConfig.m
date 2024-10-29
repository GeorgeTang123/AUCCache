//
//  AUCCacheConfig.m
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import "AUCCacheConfig.h"
#import "AUCMemoryCache.h"
#import "AUCDiskCache.h"

static AUCCacheConfig *_defaultConfig;
static const NSInteger DEFAULT_CACHE_MAX_DISK_AGE = 60 * 60 * 24 * 7; // 1 week
@implementation AUCCacheConfig
+ (AUCCacheConfig *)defaultConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultConfig = [[AUCCacheConfig alloc] init];
    });
    return _defaultConfig;
}

- (instancetype)init {
    if (self = [super init]) {
        _shouldDisableICloud = YES;
        _shouldCacheInMemory = YES;
        _shouldUseWeakMemoryCache = YES;
        _shouldRemoveExpiredDataWhenEnterBackground = YES;
        _diskCacheReadingOptions = 0;
        _diskCacheWritingOptions = NSDataWritingAtomic;
        _maxDiskAge = DEFAULT_CACHE_MAX_DISK_AGE;
        _maxDiskSize = 0;
        _diskCacheExpireType = AUCCacheConfigExpireTypeModificationDate;
        _memoryCacheClass = [AUCMemoryCache class];
        _diskCacheClass = [AUCDiskCache class];
        _whitelistAPIs = @[];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    // malloc
    AUCCacheConfig *config = [[self.class allocWithZone:zone] init];
    config.shouldDisableICloud = self.shouldDisableICloud;
    config.shouldCacheInMemory = self.shouldCacheInMemory;
    config.shouldUseWeakMemoryCache = self.shouldUseWeakMemoryCache;
    config.shouldRemoveExpiredDataWhenEnterBackground = self.shouldRemoveExpiredDataWhenEnterBackground;
    config.diskCacheReadingOptions = self.diskCacheReadingOptions;
    config.diskCacheWritingOptions = self.diskCacheWritingOptions;
    config.maxDiskAge = self.maxDiskAge;
    config.maxDiskSize = self.maxDiskSize;
    config.maxMemoryCost = self.maxMemoryCost;
    config.maxMemoryCount = self.maxMemoryCount;
    config.diskCacheExpireType = self.diskCacheExpireType;
    
    /// NSFileManager 并未遵守 NSCopying协议，只需传递引用
    config.fileManager = self.fileManager;
    config.memoryCacheClass = self.memoryCacheClass;
    config.diskCacheClass = self.diskCacheClass;
    config.baseURL = self.baseURL;
    config.whitelistAPIs = [[NSArray alloc] initWithArray:self.whitelistAPIs copyItems:YES];
    
    return config;
}

@end
