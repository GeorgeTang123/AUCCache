//
//  AUCProtocolsDefine.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#ifndef AUCProtocolsDefine_h
#define AUCProtocolsDefine_h

#import "AUCCacheOperation.h"
#import "AUCTypeDefines.h"

@class AUCCacheConfig;
#pragma mark - 缓存
/// ``提供缓存的基本功能协议``
/// 如果基本功能无法满足具体需求，需要更高级的功能，可以实现此协议并提供给 `AUCNetwork、AUCCachesManager` 等类使用
@protocol AUCCacheProtocol <NSObject>

@required
/// 从缓存中查询给定键的缓存数据。该操作可用于取消查询
/// 如果缓存在内存中，则同步完成，否则异步完成，并取决于选项 arg（参见 `AUCCacheQueryDiskSync`)
///
/// - Parameters:
///     - key: 数据缓存键
///     - manually: 是否手动存储
///     ```
///     非手动存储的情况下，会检索`AUCCacheConfig`中的`whitelistApis`。 如果`whitelistApis`覆盖到当前请求`API`，并且在缓存中命中数据，会立马在网络请求成功回调中返回数据。 不影响原有网络请求逻辑，因此网络请求完成可能会响应两次
///
///     手动存储的情况下，无论是否在`whitelistApis`配置白名单，都会强制检索缓存数据
///     ```
///     - options: 缓存选项
///     - context: 上下文包含不同的选项，用于执行指定更改或进程
///     - completionBlock: 完成回调。
/// - Warning: 如果操作被取消，则 completionBlock 不会被调用
/// - Returns: 该查询的操作
- (nullable id<AUCCacheOperation>)queryCacheDataForKey:(nullable NSString *)key
                                              manually:(BOOL)manually
                                               options:(AUCCacheOptions)options
                                               context:(nullable AUCCacheContext *)context
                                            completion:(nullable AUCCacheQueryCompletionBlock)completionBlock;

/// 根据给定的键将数据存储到缓存中。如果缓存类型仅为内存，则同步完成，否则异步完成
///
/// - Parameters:
///     - data: 需要存储的数据
///     - key: 数据缓存键
///     - manually: 是否手动存储
///     ```
///     非手动存储的情况下，会在网络请求成功回调中检索`AUCCacheConfig`中的`whitelistApis`， 如果`whitelistApis`覆盖到当前请求`API`，则会存入到缓存中，否则将抛弃
///
///     手动存储的情况下，无论是否在`whitelistApis`配置白名单都会强制存储数据到缓存中
///     ```
///     - cacheType: 图像存储操作缓存类型
///     - completionBlock: 操作完成后执行的块
- (void)storeData:(nullable id)data
           forKey:(nullable NSString *)key
         manually:(BOOL)manually
        cacheType:(AUCCacheType)cacheType
       completion:(nullable AUCVoidParamsBlock)completionBlock;

/// 从缓存中删除指定键的数据。如果【cacheType】为【AUCCacheTypeMemory】，则同步完成，否则异步完成
///
/// - Parameters:
///     - key: 数据缓存键
///     - cacheType - 移除操作缓存类型
///     - completionBlock - 操作完成后执行的代码块
- (void)removeCacheForKey:(nullable NSString *)key
                cacheType:(AUCCacheType)cacheType
               completion:(nullable AUCVoidParamsBlock)completionBlock;

/// 检查缓存中是否包含给定键的缓存数据【不加载缓存】。如果【cacheType】为【AUCCacheTypeMemory】，则同步完成，否则异步完成
///
/// - Parameters:
///     - key: 数据缓存键
///     - cacheType - 缓存类型
///     - completionBlock - 操作完成后所需要执行的代码块
- (void)containsCacheForKey:(nullable NSString *)key
                  cacheType:(AUCCacheType)cacheType
                 completion:(nullable AUCCacheContainsCompletionBlock)completionBlock;

/// 清除缓存中缓存类型的所有缓存数据。如果缓存类型仅是内存，则同步调用完成，否则异步调用
///
/// - Parameter cacheType - 清除操作缓存类型
/// - Parameter completionBlock - 清除完成后所需要执行的代码块
- (void)clearWithCacheType:(AUCCacheType)cacheType
                completion:(nullable AUCVoidParamsBlock)completionBlock;

@optional
/// 异步获取磁盘缓存的大小
///
/// - Parameter completionBlock: 缓存计算完成回调
- (void)calculateCacheSize:(nullable AUCCacheCalculateSizeBlock)completionBlock;

@end


#pragma mark - 内存缓存协议 AUCMemoryCacheProtocol
@protocol AUCMemoryCacheProtocol <NSObject>

@required
/// 使用指定的缓存配置创建新的内存缓存实例
/// 可以检查内存缓存使用的 "maxMemoryCost "和 "maxMemoryCount"
///
/// - Parameter config - 用于创建缓存的缓存配置
/// - Returns: 新的内存缓存实例
- (nonnull instancetype)initWithConfig:(nonnull AUCCacheConfig *)config;

/// 返回与给定键相关的值
///
/// - Parameter key: 数据缓存键
/// - Note: 如果为 nil，则返回 nil
/// - Returns: 与 key 关联的值，如果没有与 key 关联的值，则返回 nil
- (nullable id)objectForKey:(nonnull id)key;

/// 设置缓存中指定键的值（成本为 0）
///
/// - Note: object 要存储在缓存中的对象。如果为空，则调用 `removeObjectForKey:`
/// - Note: 要将值与之关联的键。如果为空，此方法将不起作用
/// - Warning: 与 NSMutableDictionary 对象不同，缓存不会复制被放入其中的 key 对象
- (void)setObject:(nullable id)object forKey:(nonnull id)key;

/// 在缓存中设置指定键的值，并将键值对与指定费用关联起来。与指定的成本关联
///
/// - Parameters:
///     - object: 要存储在缓存中的对象。如果为空，则调用 `removeObjectForKey`
///     - key: 要与值关联的键。如果为空，此方法将不起作用
///     - cost: 与键值对关联的代价
/// - Warning: 与 NSMutableDictionary 对象不同，缓存不会复制放入其中的 key 对象
- (void)setObject:(nullable id)object forKey:(nonnull id)key cost:(NSUInteger)cost;

/// 删除缓存中指定键的值。
///
/// - Parameter key 标识要删除的值的键。如果为空，本方法将不起作用
- (void)removeObjectForKey:(nonnull id)key;

/// 立即清空缓存
- (void)removeAllObjects;

@end

#pragma mark - 磁盘缓存协议 AUCDiskCacheProtocol
@protocol AUCDiskCacheProtocol <NSObject>

/// - Attention: 所有这些方法都从同一个全局队列中调用，以避免主队列阻塞和线程安全问题
/// - Note: 也建议使用锁或其他方法确保线程安全
@required
/// 根据指定路径创建新磁盘缓存。可以检查磁盘缓存使用的 "maxDiskSize "和 "maxDiskAge"
///
/// - Parameters:
///     - cachePath: 缓存写入数据的完整目录路径
///     - config: 缓存配置
/// - Returns: 新的缓存对象，如果出错则为 nil
- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePath config:(nonnull AUCCacheConfig *)config;

/// 返回给定键是否在缓存中
///
/// - Parameter key: 数据缓存键
/// - Note: 如果key为nil，则直接返回 nil
/// - Returns: key是否在缓存中
/// - Warning: 该方法可能会阻塞调用线程，直到文件读取完成
- (BOOL)containsDataForKey:(nonnull NSString *)key;

/// 返回与给定键相关的值
///
/// - Parameter key: 数据缓存键
/// - Note: 如果key为nil，则直接返回 nil
/// - Returns: 与 key 关联的值，如果没有与 key 关联的值，则返回 nil
- (nullable NSData *)dataForKey:(nonnull NSString *)key;

/// 设置缓存中指定键的值
///
/// - Parameters:
///     - data: 要存储在缓存中的数据
///     - key: 数据缓存键。如果为nil，本方法将不起作用
/// - Warning: 该方法可能会阻塞调用线程，直到文件写入完成
- (void)setData:(nullable NSData *)data forKey:(nonnull NSString *)key;

/// 返回与给定密钥相关的扩展数据
///
/// - Parameter key - 数据缓存键
/// - Returns: 与 key 相关联的值
/// - Note: 如果key为nil，则直接返回 nil
/// - Note: 如果没有与 key 相关联的值，则返回 nil
/// - Warning: 该方法可能会阻塞调用线程，直到文件读取完成
- (nullable NSData *)extendedDataForKey:(nonnull NSString *)key;

/// 用给定密钥设置扩展数据
/// 您可以将任何扩展数据设置为存在缓存键。而不覆盖存在的磁盘文件数据
///
/// - Parameters:
///     - extendedData: 扩展数据
///     - key: 数据缓存键
/// - Note: 如果 extendedData 传递 nil 表示删除
/// - Note: 如果 key 为nil，则此方法无效
- (void)setExtendedData:(nullable NSData *)extendedData forKey:(nonnull NSString *)key;



/** ========================== 删除数据 ========================== */
/// 删除缓存中指定键的值
///
/// - Parameter key - 标识要删除的值的键。如果为nil，则此方法无效
/// - Warning: 此方法可能会阻塞调用线程，直到文件删除完成
- (void)removeCacheForKey:(nonnull NSString *)key;

/// 清空缓存。
///
/// - Warning: 此方法可能会阻塞调用线程，直到文件删除完成。
- (void)removeAllData;

/// 从缓存中删除过期数据
///
/// - Note: 可以根据 `ageLimit`、`countLimit` 和 `sizeLimit` 选项选择要删除的数据
- (void)removeExpiredData;

/// key对应的完整缓存路径
///
/// - Parameter key - 数据缓存键
/// - Returns: 返回存储键值 key 对应的的缓存路径
/// - Note: 如果键无法关联到路径，则返回 nil
- (nullable NSString *)cachePathForKey:(nonnull NSString *)key;

/// 返回此缓存中的数据数量
///
/// - Returns: 总缓存数量
/// - Warning: 该方法可能会阻塞调用线程，直到文件读取完成
- (NSUInteger)totalCount;

/// 返回缓存中数据的总大小（以字节为单位）
///
/// - Returns: 数据的总大小（以字节 byte 为单位）
/// - Warning: 该方法可能会阻塞调用线程，直到文件读取完成
- (NSUInteger)totalSize;

@end


#endif /* AUCProtocolsDefine_h */
