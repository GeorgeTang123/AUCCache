//
//  AUCCachesManager.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import <Foundation/Foundation.h>
#import "AUCProtocolsDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// ``缓存管理器: 用于注册管理多个缓存``
///
/// - Warning: 暂未启用
@interface AUCCachesManager : NSObject <AUCCacheProtocol>

@property (nonatomic, class, readonly, nonnull) AUCCachesManager *sharedManager;

#pragma mark - 这些是缓存管理器的运行策略
/// 查询操作的操作策略
///
/// - Note: 默认为 "AUCCachesManagerOperationPolicySerial"，即串行查询所有缓存（一次完成后调用下一次开始），直到一次缓存查询成功
@property (nonatomic, assign) AUCCachesManagerOperationPolicy queryOperationPolicy;

/// 存储操作的操作策略
///
/// - Note: 默认为 "AUCCachesManagerOperationPolicyHighestOnly"，表示只存储到最高优先级的缓存中
@property (nonatomic, assign) AUCCachesManagerOperationPolicy storeOperationPolicy;

/// 删除操作的操作策略
///
/// - Note: 默认为 "AUCCachesManagerOperationPolicyConcurrent"，表示同时删除所有缓存
@property (nonatomic, assign) AUCCachesManagerOperationPolicy removeOperationPolicy;

/// 包含操作的操作策略
///
/// - Note: 默认为 "AUCCachesManagerOperationPolicySerial"，即串行检查所有缓存（调用一次完成，然后开始下一次），直到一次缓存检查成功（"containsCacheType" != None）
@property (nonatomic, assign) AUCCachesManagerOperationPolicy containsOperationPolicy;

/// 清除操作的操作策略
///
/// - Note: 默认为 "AUCCachesManagerOperationPolicyConcurrent"，表示同时清除所有缓存
@property (nonatomic, assign) AUCCachesManagerOperationPolicy clearOperationPolicy;

/// 缓存管理器中的所有缓存。缓存数组是一个优先级队列，这意味着后添加的缓存具有最高优先级
@property (nonatomic, copy, nullable) NSArray<id<AUCCacheProtocol>> *caches;

/// 在缓存数组的末尾添加一个新缓存。其优先级最高
///
/// - Parameter cache: 在缓存数组的末尾添加一个新缓存。该缓存具有最高优先级
- (void)addCache:(nonnull id<AUCCacheProtocol>)cache;

/// 删除缓存数组中的缓存
/// 
/// - Parameter cache: 需要删除的缓存
- (void)removeCache:(nonnull id<AUCCacheProtocol>)cache;

@end

NS_ASSUME_NONNULL_END
