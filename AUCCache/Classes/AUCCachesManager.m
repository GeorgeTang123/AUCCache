//
//  AUCCachesManager.m
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import "AUCCachesManager.h"
#import "AUCCachesManagerOperation.h"
#import "AUCProtocolsDefine.h"
#import "AUCCacheCombine.h"
#import "AUCInternalMacros.h"
#import "AUCCacheOperation.h"

@interface AUCCachesManager ()

@property (nonatomic, strong, nonnull) dispatch_semaphore_t cachesLock;

@end

@implementation AUCCachesManager {
    NSMutableArray<id<AUCCacheProtocol>> *_dataCaches;
}

+ (AUCCachesManager *)sharedManager {
    static dispatch_once_t onceToken;
    static AUCCachesManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[AUCCachesManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.queryOperationPolicy = AUCCachesManagerOperationPolicySerial;
        self.storeOperationPolicy = AUCCachesManagerOperationPolicyHighestOnly;
        self.removeOperationPolicy = AUCCachesManagerOperationPolicyConcurrent;
        self.containsOperationPolicy = AUCCachesManagerOperationPolicySerial;
        self.clearOperationPolicy = AUCCachesManagerOperationPolicyConcurrent;
        
        /// 使用默认缓存进行初始化
        _dataCaches = [NSMutableArray arrayWithObject:AUCCacheCombine.sharedCache];
        _cachesLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (NSArray<id<AUCCacheProtocol>> *)caches {
    AUC_DISPATCH_SEMAPHORE_LOCK(self.cachesLock);
    NSArray<id<AUCCacheProtocol>> *caches = [_dataCaches copy];
    AUC_DISPATCH_SEMAPHORE_UNLOCK(self.cachesLock);
    return caches;
}

- (void)setCaches:(NSArray<id<AUCCacheProtocol>> *)caches {
    AUC_DISPATCH_SEMAPHORE_LOCK(self.cachesLock);
    [_dataCaches removeAllObjects];
    if (caches.count) {
        [_dataCaches addObjectsFromArray:caches];
    }
    AUC_DISPATCH_SEMAPHORE_UNLOCK(self.cachesLock);
}

#pragma mark - Cache IO operations
- (void)addCache:(id<AUCCacheProtocol>)cache {
    if (![cache conformsToProtocol:@protocol(AUCCacheProtocol)]) {
        return;
    }
    
    AUC_DISPATCH_SEMAPHORE_LOCK(self.cachesLock);
    [_dataCaches addObject:cache];
    AUC_DISPATCH_SEMAPHORE_UNLOCK(self.cachesLock);
}

- (void)removeCache:(id<AUCCacheProtocol>)cache {
    if (![cache conformsToProtocol:@protocol(AUCCacheProtocol)]) {
        return;
    }
    AUC_DISPATCH_SEMAPHORE_LOCK(self.cachesLock);
    [_dataCaches removeObject:cache];
    AUC_DISPATCH_SEMAPHORE_UNLOCK(self.cachesLock);
}

#pragma mark - AUCCacheProtocol
- (nullable id<AUCCacheOperation>)queryCacheDataForKey:(nullable NSString *)key
                                              manually:(BOOL)manually
                                               options:(AUCCacheOptions)options
                                               context:(nullable AUCCacheContext *)context
                                            completion:(nullable AUCCacheQueryCompletionBlock)completionBlock {
    if (!key) {
        return nil;
    }
    NSArray<id<AUCCacheProtocol>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return nil;
    } else if (count == 1) {
        return [caches.firstObject queryCacheDataForKey:key manually:manually options:options context:context completion:completionBlock];
    }
    
    switch (self.queryOperationPolicy) {
        case AUCCachesManagerOperationPolicyHighestOnly: {
            id<AUCCacheProtocol> cache = caches.lastObject;
            return [cache queryCacheDataForKey:key manually:manually options:options context:context completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyLowestOnly: {
            id<AUCCacheProtocol> cache = caches.firstObject;
            return [cache queryCacheDataForKey:key manually:manually options:options context:context completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyConcurrent: {
            AUCCachesManagerOperation *operation = [AUCCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentQueryCacheDataForKey:key manually:manually options:options context:context completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
            return operation;
        }
            break;
        case AUCCachesManagerOperationPolicySerial: {
            AUCCachesManagerOperation *operation = [AUCCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self serialQueryCacheDataForKey:key manually:manually options:options context:context completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
            return operation;
        }
            break;
        default:
            return nil;
            break;
    }
}

- (void)storeData:(nullable id)data
           forKey:(nullable NSString *)key
         manually:(BOOL)manually
        cacheType:(AUCCacheType)cacheType
       completion:(nullable AUCVoidParamsBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<AUCCacheProtocol>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject storeData:data forKey:key manually:manually cacheType:cacheType completion:completionBlock];
        return;
    }
    
    switch (self.storeOperationPolicy) {
        case AUCCachesManagerOperationPolicyHighestOnly: {
            id<AUCCacheProtocol> cache = caches.lastObject;
            [cache storeData:data forKey:key manually:manually cacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyLowestOnly: {
            id<AUCCacheProtocol> cache = caches.firstObject;
            [cache storeData:data forKey:key manually:manually cacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyConcurrent: {
            AUCCachesManagerOperation *operation = [AUCCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentStoreData:data forKey:key manually:manually cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case AUCCachesManagerOperationPolicySerial: {
            [self serialStoreData:data forKey:key manually:manually cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}
- (void)removeCacheForKey:(nullable NSString *)key
                cacheType:(AUCCacheType)cacheType
               completion:(nullable AUCVoidParamsBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<AUCCacheProtocol>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject removeCacheForKey:key cacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.removeOperationPolicy) {
        case AUCCachesManagerOperationPolicyHighestOnly: {
            id<AUCCacheProtocol> cache = caches.lastObject;
            [cache removeCacheForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyLowestOnly: {
            id<AUCCacheProtocol> cache = caches.firstObject;
            [cache removeCacheForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyConcurrent: {
            AUCCachesManagerOperation *operation = [AUCCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentRemoveCacheForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case AUCCachesManagerOperationPolicySerial: {
            [self serialremoveCacheForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}

- (void)containsCacheForKey:(NSString *)key
                  cacheType:(AUCCacheType)cacheType
                 completion:(AUCCacheContainsCompletionBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<AUCCacheProtocol>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject containsCacheForKey:key cacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.clearOperationPolicy) {
        case AUCCachesManagerOperationPolicyHighestOnly: {
            id<AUCCacheProtocol> cache = caches.lastObject;
            [cache containsCacheForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyLowestOnly: {
            id<AUCCacheProtocol> cache = caches.firstObject;
            [cache containsCacheForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyConcurrent: {
            AUCCachesManagerOperation *operation = [AUCCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentcontainsCacheForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case AUCCachesManagerOperationPolicySerial: {
            AUCCachesManagerOperation *operation = [AUCCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self serialcontainsCacheForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        default:
            break;
    }
}

- (void)clearWithCacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock {
    NSArray<id<AUCCacheProtocol>> *caches = self.caches;
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject clearWithCacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.clearOperationPolicy) {
        case AUCCachesManagerOperationPolicyHighestOnly: {
            id<AUCCacheProtocol> cache = caches.lastObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyLowestOnly: {
            id<AUCCacheProtocol> cache = caches.firstObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case AUCCachesManagerOperationPolicyConcurrent: {
            AUCCachesManagerOperation *operation = [AUCCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentClearWithCacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case AUCCachesManagerOperationPolicySerial: {
            [self serialClearWithCacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Concurrent Operation
- (void)concurrentQueryCacheDataForKey:(NSString *)key manually:(BOOL)manually options:(AUCCacheOptions)options context:(AUCCacheContext *)context completion:(AUCCacheQueryCompletionBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator operation:(AUCCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<AUCCacheProtocol> cache in enumerator) {
        [cache queryCacheDataForKey:key manually:manually options:options context:context completion:^(NSData * _Nullable data, AUCCacheType cacheType) {
            if (operation.isCancelled || operation.isFinished) return;
            
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock(nil, AUCCacheTypeNone);
                }
            }
        }];
    }
}

- (void)concurrentStoreData:(id)data forKey:(NSString *)key manually:(BOOL)manually cacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator operation:(AUCCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<AUCCacheProtocol> cache in enumerator) {
        [cache storeData:data forKey:key manually:manually cacheType:cacheType completion:^{
            if (operation.isCancelled || operation.isFinished) return;
            
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

- (void)concurrentRemoveCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator operation:(AUCCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<AUCCacheProtocol> cache in enumerator) {
        [cache removeCacheForKey:key cacheType:cacheType completion:^{
            if (operation.isCancelled || operation.isFinished) return;
            
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

- (void)concurrentcontainsCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(AUCCacheContainsCompletionBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator operation:(AUCCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<AUCCacheProtocol> cache in enumerator) {
        [cache containsCacheForKey:key cacheType:cacheType completion:^(AUCCacheType containsCacheType) {
            if (operation.isCancelled || operation.isFinished) return;
            
            [operation completeOne];
            if (containsCacheType != AUCCacheTypeNone) {
                // Success
                [operation done];
                if (completionBlock) {
                    completionBlock(containsCacheType);
                }
                return;
            }
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock(AUCCacheTypeNone);
                }
            }
        }];
    }
}

- (void)concurrentClearWithCacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator operation:(AUCCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<AUCCacheProtocol> cache in enumerator) {
        [cache clearWithCacheType:cacheType completion:^{
            if (operation.isCancelled || operation.isFinished) return;
            
            [operation completeOne];
            if (operation.pendingCount == 0) {
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

#pragma mark - Serial Operation
- (void)serialQueryCacheDataForKey:(NSString *)key manually:(BOOL)manually options:(AUCCacheOptions)options context:(AUCCacheContext *)context completion:(AUCCacheQueryCompletionBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator operation:(AUCCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    id<AUCCacheProtocol> cache = enumerator.nextObject;
    if (!cache) {
        [operation done];
        if (completionBlock) {
            completionBlock(nil, AUCCacheTypeNone);
        }
        return;
    }
    @weakify(self);
    [cache queryCacheDataForKey:key manually:manually options:options context:context completion:^(NSData * _Nullable data, AUCCacheType cacheType) {
        @strongify(self);
        if (operation.isCancelled || operation.isFinished) return;
        
        [operation completeOne];
        if (data) {
            [operation done];
            if (completionBlock) completionBlock(data, cacheType);
            return;
        }
        [self serialQueryCacheDataForKey:key manually:manually options:options context:context completion:completionBlock enumerator:enumerator operation:operation];
    }];
}

- (void)serialStoreData:(id)data forKey:(NSString *)key manually:(BOOL)manually cacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator {
    NSParameterAssert(enumerator);
    id<AUCCacheProtocol> cache = enumerator.nextObject;
    if (!cache) {
        if (completionBlock) completionBlock();
        return;
    }
    @weakify(self);
    [cache storeData:data forKey:key manually:manually cacheType:cacheType completion:^{
        @strongify(self);
        [self serialStoreData:data forKey:key manually:manually cacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

- (void)serialremoveCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator {
    NSParameterAssert(enumerator);
    id<AUCCacheProtocol> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) completionBlock();
        return;
    }
    @weakify(self);
    [cache removeCacheForKey:key cacheType:cacheType completion:^{
        @strongify(self);
        // Next
        [self serialremoveCacheForKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

- (void)serialcontainsCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(AUCCacheContainsCompletionBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator operation:(AUCCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    id<AUCCacheProtocol> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        [operation done];
        if (completionBlock) {
            completionBlock(AUCCacheTypeNone);
        }
        return;
    }
    @weakify(self);
    [cache containsCacheForKey:key cacheType:cacheType completion:^(AUCCacheType containsCacheType) {
        @strongify(self);
        if (operation.isCancelled || operation.isFinished) return;
        
        [operation completeOne];
        if (containsCacheType != AUCCacheTypeNone) {
            // Success
            [operation done];
            if (completionBlock) {
                completionBlock(containsCacheType);
            }
            return;
        }
        // Next
        [self serialcontainsCacheForKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator operation:operation];
    }];
}

- (void)serialClearWithCacheType:(AUCCacheType)cacheType completion:(AUCVoidParamsBlock)completionBlock enumerator:(NSEnumerator<id<AUCCacheProtocol>> *)enumerator {
    NSParameterAssert(enumerator);
    id<AUCCacheProtocol> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    @weakify(self);
    [cache clearWithCacheType:cacheType completion:^{
        @strongify(self);
        // Next
        [self serialClearWithCacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

@end
