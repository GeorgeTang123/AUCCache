//
//  AUCCacheHelper.m
//  AUOptimize
//
//  Created by aaron lee on 2024/10/18.
//

#import "AUCCacheHelper.h"
#import "AUCCacheCombine.h"

static AUCCacheCombine *_dataCache;
@implementation AUCCacheHelper
#pragma mark - 缓存相关
+ (id<AUCCacheProtocol>)dataCache {
    if (!_dataCache) {
        _dataCache = AUCCacheCombine.sharedCache;
    }
    return _dataCache;
}

+ (void)setDataCache:(id<AUCCacheProtocol>)dataCache {
    if (dataCache && ![dataCache conformsToProtocol:@protocol(AUCCacheProtocol)]) {
        return;
    }
    if (_dataCache != dataCache) {
        _dataCache = dataCache;
    }
}

// 存储数据
+ (void)store:(id)data forKey:(NSString *)key {
    [self store:data forKey:key cacheType:AUCCacheTypeAll];
}

+ (void)store:(id)data forKey:(NSString *)key completion:(AUCVoidParamsBlock)completion {
    [self store:data forKey:key cacheType:AUCCacheTypeAll completion:completion];
}

+ (void)store:(id)data forKey:(NSString *)key cacheType:(AUCCacheType)cacheType {
    [self store:data forKey:key cacheType:AUCCacheTypeAll completion:nil];
}

+ (void)store:(id)data forKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(nullable AUCVoidParamsBlock)completion {
    [self.dataCache storeData:data forKey:key manually:YES cacheType:cacheType completion:completion];
}

+ (void)store:(id)data forKey:(NSString *)key cacheType:(AUCCacheType)cacheType manually:(BOOL)manually completion:(nullable AUCVoidParamsBlock)completion {
    [self.dataCache storeData:data forKey:key manually:manually cacheType:cacheType completion:completion];
}

// 查询缓存数据
+ (void)queryCacheForKey:(NSString *)key completion:(AUCCacheQueryCompletionBlock)completion {
    [self.dataCache queryCacheDataForKey:key manually:YES options:0 context:nil completion:completion];
}

+ (void)queryCacheForKey:(NSString *)key options:(AUCCacheOptions)options completion:(AUCCacheQueryCompletionBlock)completion {
    [self.dataCache queryCacheDataForKey:key manually:YES options:options context:nil completion:completion];
}

+ (void)queryCacheForKey:(NSString *)key options:(AUCCacheOptions)options context:(nullable AUCCacheContext *)context completion:(AUCCacheQueryCompletionBlock)completion {
    [self.dataCache queryCacheDataForKey:key manually:YES options:options context:context completion:completion];
}

// 清除缓存
+ (void)clearAllHTTPCache {
    [self.dataCache clearWithCacheType:AUCCacheTypeAll completion:nil];
}

+ (void)clearAllHTTPCacheWithCompletion:(nullable AUCVoidParamsBlock)completion {
    [self.dataCache clearWithCacheType:AUCCacheTypeAll completion:completion];
}

+ (void)clearHTTPCacheForCacheType:(AUCCacheType)cacheType {
    [self.dataCache clearWithCacheType:cacheType completion:nil];
}

+ (void)clearHTTPCacheForCacheType:(AUCCacheType)cacheType completion:(nullable AUCVoidParamsBlock)completion {
    [self.dataCache clearWithCacheType:cacheType completion:completion];
}

+ (void)clearHTTPCacheForKey:(NSString *)key {
    [self clearHTTPCacheForKey:key cacheType:AUCCacheTypeAll];
}

+ (void)clearHTTPCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType {
    [self clearHTTPCacheForKey:key cacheType:cacheType completion:nil];
}

+ (void)clearHTTPCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(nullable AUCVoidParamsBlock)completion {
    [self.dataCache removeCacheForKey:key cacheType:cacheType completion:completion];
}

// 缓存是否存在
+ (void)cacheExistForKey:(NSString *)key completion:(AUCCacheContainsCompletionBlock)completion {
    [self.dataCache containsCacheForKey:key cacheType:AUCCacheTypeAll completion:completion];
}

+ (void)cacheExistForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(AUCCacheContainsCompletionBlock)completion {
    [self.dataCache containsCacheForKey:key cacheType:cacheType completion:completion];
}

// 计算缓存大小
+ (void)calculateHTTPCacheSize:(nullable AUCCacheCalculateSizeBlock)completionBlock {
    if ([self.dataCache respondsToSelector:@selector(calculateCacheSize:)]) {
        [self.dataCache calculateCacheSize:completionBlock];
    }
}

@end
