//
//  AUCHTTPCache.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/18.
//

#import <Foundation/Foundation.h>
#import "AUCProtocolsDefine.h"

NS_ASSUME_NONNULL_BEGIN
/// ``缓存入口使用``
/// ```
/// 其内部持有一个遵循`AUCacheProtocol`协议的私有静态实例对象用于管理缓存部分功能
/// AUCCacheHelper
///      ├── id<AUCCacheProtocol> _dataCache    未提供自定义缓存类的情况下，默认由`AUCCacheCombine.sharedCache`提供缓存服务
///                     ├── AUCCacheConfig      缓存配置类
/// ```
@interface AUCCacheHelper : NSObject

#pragma mark - 缓存相关、自定义使用
+ (id<AUCCacheProtocol>)dataCache;
+ (void)setDataCache:(id<AUCCacheProtocol>)dataCache;

#pragma mark - 缓存存入【一般用于手动存入】
/// 将数据以 `AUCacheTypeAll` - `内存缓存 + 磁盘缓存` 的方式存入
/// - Parameters:
///     - data: 需缓存的数据
///     - key: 缓存存储键
+ (void)store:(id)data forKey:(NSString *)key;

/// 将数据以指定 `AUCCacheType`  的方式存入
///
/// - Parameters:
///     - data: 需缓存的数据
///     - key: 缓存存储键
///     - completion: 存储完成回调
+ (void)store:(id)data forKey:(NSString *)key completion:(nullable AUCVoidParamsBlock)completion;

/// 将数据以指定 `AUCCacheType`  的方式存入
///
/// - Parameters:
///     - data: 需缓存的数据
///     - key: 缓存存储键
///     - cacheType: 缓存方式
+ (void)store:(id)data forKey:(NSString *)key cacheType:(AUCCacheType)cacheType;

/// 将数据以指定 `AUCCacheType`  的方式存入
///
/// - Parameters:
///     - data: 需缓存的数据
///     - key: 缓存存储键
///     - cacheType: 缓存方式
///     - completion: 存储完成回调
+ (void)store:(id)data forKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(nullable AUCVoidParamsBlock)completion;

/// 将数据以指定 `AUCCacheType`  的方式存入
///
/// - Parameters:
///     - data: 需缓存的数据
///     - key: 缓存存储键
///     - cacheType: 缓存方式
///     - manually: 手动存储方案，默认值为YES
///     - completion: 存储完成回调
/// - Warning: 注意 `manually = NO` 时为自动存储方案，会默认根据配置内的 `whitelistApis` 做检索过滤
+ (void)store:(id)data forKey:(NSString *)key cacheType:(AUCCacheType)cacheType manually:(BOOL)manually completion:(nullable AUCVoidParamsBlock)completion;

#pragma mark - 缓存查询获取【一般用于手动缓存查询】
/// 获取给定键值的缓存数据
///
/// - Parameters:
///     - key: 缓存存储键
///     - completion: 查询缓存回调
+ (void)queryCacheForKey:(NSString *)key completion:(AUCCacheQueryCompletionBlock)completion;

/// 获取给定键值的缓存数据
///
/// - Parameters:
///     - key: 缓存存储键
///     - options: 缓存选项
///     ```
///     目前可传入`0 - 即默认值`、 `AUCCacheQueryMemoryData` 、 `AUCCacheQueryMemoryDataSync` 及 `AUCCacheQueryDiskDataSync`，其余暂未启用
///     ```
///     - completion: 查询缓存回调
+ (void)queryCacheForKey:(NSString *)key options:(AUCCacheOptions)options completion:(AUCCacheQueryCompletionBlock)completion;

/// 获取给定键值的缓存数据
///
/// - Parameters:
///     - key: 缓存存储键
///     - options: 缓存选项
///     - context: 缓存上下文
///     - completion: 查询缓存回调
+ (void)queryCacheForKey:(NSString *)key options:(AUCCacheOptions)options context:(nullable AUCCacheContext *)context completion:(AUCCacheQueryCompletionBlock)completion;


#pragma mark - 缓存清除
/// 清除本地所有缓存
+ (void)clearAllHTTPCache;
+ (void)clearAllHTTPCacheWithCompletion:(nullable AUCVoidParamsBlock)completion;

/// 清除指定类型的缓存
+ (void)clearHTTPCacheForCacheType:(AUCCacheType)cacheType;
+ (void)clearHTTPCacheForCacheType:(AUCCacheType)cacheType completion:(nullable AUCVoidParamsBlock)completion;

/// 清除指定缓存键的缓存数据
+ (void)clearHTTPCacheForKey:(NSString *)key;
+ (void)clearHTTPCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType;
+ (void)clearHTTPCacheForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(nullable AUCVoidParamsBlock)completion;

#pragma mark - 缓存查询
/// 是否有指定键的缓存存在
///
/// - Parameters:
///     - key: 缓存存储键
///     - completion: 缓存类型查询回调
/// ```
/// 若缓存存储在内存中，则回调`completion(AUCCacheTypeMemory)`；
/// 若缓存在内存中不存在但存在于磁盘中，则回调`completion(AUCCacheTypeDisk)`；
/// 若缓存在内存、磁盘中均不存在，则回调`completion(AUCCacheTypeNone)`
/// ```
+ (void)cacheExistForKey:(NSString *)key completion:(AUCCacheContainsCompletionBlock)completion;

/// 是否有指定键的缓存存在
///
/// - Parameters:
///     - key: 缓存存储键
///     - cacheType: 缓存类型
///     - completion: 缓存类型查询回调
/// ```
/// 根据传入的缓存类型进行判定
/// 当缓存类型传入`AUCCacheTypeMemory`，且缓存存储在内存中，则回调`completion(AUCCacheTypeMemory)`，否则回调`completion(AUCCacheTypeNone)`
/// 当缓存类型传入`AUCCacheTypeDisk`，且缓存存储在内存中，则回调`completion(AUCCacheTypeDisk)`，否则回调`completion(AUCCacheTypeNone)`
/// 当缓存类型传入`AUCCacheTypeAll`，同`cacheExistForKey:(NSString *)key completion:(AUCCacheContainsCompletionBlock)completion;`逻辑一致
/// 当缓存类型传入`AUCCacheTypeNone`，直接回调`completion(AUCCacheTypeNone)`
/// ```
+ (void)cacheExistForKey:(NSString *)key cacheType:(AUCCacheType)cacheType completion:(AUCCacheContainsCompletionBlock)completion;

#pragma mark - 缓存计算
/// 异步获取磁盘缓存的大小
///
/// - Parameter completionBlock: 磁盘缓存获取完成回调
///
/// ```
/// 其包含以下两个参数:
/// fileCount: 缓存文件数
/// totalSize: 缓存大小，以 `字节` 为单位
/// ```
+ (void)calculateHTTPCacheSize:(nullable AUCCacheCalculateSizeBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
