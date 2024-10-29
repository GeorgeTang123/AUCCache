//
//  AUCCache.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AUCCacheConfig.h"
#import "AUCProtocolsDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// `AUCCacheCombine`维护一个``内存缓存``和一个``磁盘缓存``
/// 磁盘缓存的写入操作是异步执行的，并且做了相应的优化，因此不会给用户界面增加不必要的延迟
///
/// ```
/// AUCCacheCombine
///    ├── AUCCacheConfig       缓存配置
///    ├── AUCMemoryCache       内存缓存
///    ├── AUCDiskCache         磁盘缓存
///    ├── AUCCacheDirectory    缓存目录管理(暂未依据优先级划分)
/// ```
@interface AUCCacheCombine : NSObject

#pragma mark - Singleton
/// 缓存单例对象
@property (nonatomic, class, readonly, nonnull) AUCCacheCombine *sharedCache;

#pragma mark - 属性
/// 缓存配置对象 - 存储缓存相关配置
///
/// - Note: 该属性关键字为copy，因此更改当前配置不会意外影响其他缓存的配置
@property (nonatomic, copy, readonly, nonnull) AUCCacheConfig *config;

/// 内存缓存
///
/// - Attention: 未自定义指定时，将由`AUCMemoryCache`类接手管理
@property (nonatomic, strong, readonly, nonnull) id<AUCMemoryCacheProtocol> memoryCache;

/// 磁盘缓存
///
/// - Attention: 未自定义指定时，将使用`AUCDiskCache`类接手管理
@property (nonatomic, strong, readonly, nonnull) id<AUCDiskCacheProtocol> diskCache;

/// 默认磁盘缓存路径
@property (nonatomic, copy, nonnull, readonly) NSString *diskCachePath;

/// 自定义预加载缓存的附加缓存路径
/// 如果磁盘缓存中的查询不存在，则检查附加磁盘缓存路径
///
/// - Note: block中的参数 `key` 是数据缓存键。返回为文件路径，用于加载磁盘缓存。如果文件路径返回 nil，则会被忽略
/// - Warning: 如果想在应用程序中捆绑预加载的资源，可以启用该参数
@property (nonatomic, copy, nullable) AUCCacheAdditionalCachePathBlock additionalCachePathBlock;


#pragma mark - Initialization
/// 使用特定命名空间启动新的缓存存储空间
///
/// - Parameter namespace: 缓存存储要使用的命名空间 - 默认为`default`
- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns;

/// 使用特定的命名空间和目录初始化一个新的缓存存储空间
/// 如果没有提供磁盘缓存目录，将使用带前缀的用户缓存目录（~/Library/Caches/com.vantage.AUCCache/）
///
/// - Parameters:
///     - namespace: 缓存存储要使用的命名空间
///     - directory: 缓存磁盘目录
- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns diskCacheDirectory:(nullable NSString *)directory;

/// 【指定初始化器】 使用特定命名空间、目录和缓存配置来启动新的缓存存储空间
///
/// - Parameters:
///     - namespace: 该缓存存储要使用的命名空间
///     - directory: 缓存磁盘目录
///     - config: 用于创建缓存的缓存配置
/// - Note: 可以在缓存配置中提供自定义内存缓存或磁盘缓存类
/// - Note: 最终的磁盘缓存目录应该是`${directory}/${namespace}`
/// - Note: 共享缓存的默认配置应为 `~/Library/Caches/com.vantage.AUCCache/default/`
- (nonnull instancetype)initWithNamespace:(nonnull NSString *)ns
                       diskCacheDirectory:(nullable NSString *)directory
                                   config:(nullable AUCCacheConfig *)config NS_DESIGNATED_INITIALIZER;


#pragma mark - Cache Path
/// 获取某个键的缓存路径
///
/// - Parameter key: 数据缓存键
/// - Returns: 缓存路径
/// - Note: 注意返回值是`缓存路径`，如要获取文件名，请获取后使用 `lastPathComponent`
- (nullable NSString *)cachePathForKey:(nullable NSString *)key;

#pragma mark - Store Ops
/// 以``异步``方式将数据按给定缓存键值存储到内存和磁盘缓存中
///
/// - Parameters:
///     - data: 需要存储的数据 - 通常为NSDictionary、NSArray、JSON String、JSON Data类型，超出以上类型存储会被短暂存储到内存缓存中，不会做持久化处理
///     - key: 数据缓存键，通常是请求的URL
///     - completionBlock: 操作完成后执行的回调
- (void)storeData:(nullable id)data
           forKey:(nullable NSString *)key
       completion:(nullable AUCVoidParamsBlock)completionBlock;

/// 将JSON数据同步存储到给定键的内存缓存中
///
/// - Parameters:
///     - data: 需要存储的数据 - 通常为NSDictionary、NSArray、JSON String、JSON Data类型，超出以上类型存储会被短暂存储到内存缓存中，不会做持久化处理
///     - key: 数据缓存键，通常是请求的URL
- (void)storeDataToMemory:(nullable id)data
                   forKey:(nullable NSString *)key;

/// 将JSON数据同步存储到给定键的磁盘缓存中
///
/// - Parameters:
///     - data: 需要存储的数据 - 通常为NSDictionary、NSArray、JSON String、JSON Data类型，超出以上类型存储会被短暂存储到内存缓存中，不会做持久化处理
///     - key: 数据缓存键，通常是请求的URL
- (void)storeDataToDisk:(nullable NSData *)data
                 forKey:(nullable NSString *)key;

/// 以``异步``方式将JSON数据按给定键值存储到内存和磁盘缓存中
///
/// - Parameters:
///     - data: 需要存储的数据 - 通常为NSDictionary、NSArray、JSON String、JSON Data类型，超出以上类型存储会被短暂存储到内存缓存中，不会做持久化处理
///     - key: 数据缓存键，通常是请求的URL
///     - toDisk: 如果为YES，则将图像存储到磁盘缓存
///     - completionBlock: 操作完成后执行的块
- (void)storeData:(nullable id)data
           forKey:(nullable NSString *)key
           toDisk:(BOOL)toDisk
       completion:(nullable AUCVoidParamsBlock)completionBlock;


#pragma mark - Contains、Check Ops
/// ``【异步】``检查磁盘缓存中是否已存在数据【不加载】
///
/// - Parameters:
///     - key: 数据缓存键
///     - completionBlock: 检查完成后要执行的回调
/// - Note: 完成块将始终在主队列中执行
- (void)diskCacheExistsWithKey:(nullable NSString *)key completion:(nullable AUCCacheCheckCompletionBlock)completionBlock;

/// 【同步】检查磁盘缓存中是否已存在数据【不加载】
///
/// - Parameter key: 数据缓存键
- (BOOL)diskCacheExistsWithKey:(nullable NSString *)key;

#pragma mark - Query、Retrieve Ops
/// ``【异步】``查询缓存并在完成后调用完成，同步查询给定键的JSON数据
///
/// - Parameter key: 数据缓存键
/// - Returns: 指定键的缓存数据，如果未找到，则返回 nil
- (nullable NSData *)diskCacheDataForKey:(nullable NSString *)key;

/// ``【异步】``查询缓存，查询完成后调用 doneBlock 回调查询到的数据
///
/// - Parameters:
///     - key: 数据缓存键
///     - doneBlock: 查询完成后的回调。若操作被取消，则不会被调用
/// - Returns: 缓存查询操作的 NSOperation 实例
- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key
                                               done:(nullable AUCCacheQueryCompletionBlock)doneBlock;

/// ``【异步】``查询缓存，查询完成后调用 doneBlock 回调查询到的数据
///
/// - Parameters:
///     - key: 数据缓存键
///     - loadOptions: 缓存加载选项所使用选项标识，具体参考`AUCCacheLoadOptions`
///     - doneBlock: 查询完成后的回调。若操作被取消，则不会被调用
/// - Returns: 缓存查询操作的 NSOperation 实例
- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key
                                            options:(AUCCacheLoadOptions)loadOptions
                                               done:(nullable AUCCacheQueryCompletionBlock)doneBlock;

/// ``【异步】``查询缓存，查询完成后调用 doneBlock 回调查询到的数据
///
/// - Parameters:
///     - key: 数据缓存键
///     - loadOptions: 缓存加载选项所使用选项标识，具体参考`AUCCacheLoadOptions`
///     - doneBlock: 查询完成后的回调。若操作被取消，则不会被调用
///     - context: 参考`AUCCacheContext`，可扩展保存 “options” 枚举无法保存的额外对象
/// - Returns: 缓存查询操作的 NSOperation 实例
- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key
                                            options:(AUCCacheLoadOptions)loadOptions
                                            context:(nullable AUCCacheContext *)context
                                               done:(nullable AUCCacheQueryCompletionBlock)doneBlock;

/// ``【同步】``查询内存缓存
///
/// - Parameter key: 数据缓存键
/// - Returns: 指定键的缓存数据
/// - Note: 如果没有找到则返回nil
- (nullable id)dataFromMemoryCacheForKey:(nullable NSString *)key;

/// ``【同步】``查询磁盘缓存
///
/// - Parameter key: 数据缓存键
/// - Returns: 指定键的缓存数据
/// - Note: 如果没有找到则返回nil
- (nullable id)dataFromDiskCacheForKey:(nullable NSString *)key;

/// 检查内存缓存后，``【同步】``查询缓存（内存和或磁盘）
///
/// - Parameter key: 数据缓存键
/// - Returns: 指定键的缓存数据
/// - Note: 如果没有找到则返回nil
- (nullable id)dataFromCacheForKey:(nullable NSString *)key;

#pragma mark - Remove Ops
/// ``【异步】``从内存和磁盘缓存中删除
///
/// - Parameters:
///     - key: 数据缓存键
///     - completion: 缓存数据被删除后需要执行的 nullable 回调代码块
- (void)removeCacheForKey:(nullable NSString *)key withCompletion:(nullable AUCVoidParamsBlock)completion;

/// ``【异步】``从内存和磁盘缓存中删除
///
/// - Parameters:
///     - key: 数据缓存键
///     - fromDisk: 如果该值为YES，将【异步】从磁盘中删除缓存条目。如果该值为NO，则同步回调completion block
///     - completion: 缓存数据被删除后需要执行的 nullable 回调代码块
- (void)removeCacheForKey:(nullable NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(nullable AUCVoidParamsBlock)completion;

#pragma mark - Cache clean Ops
/// ``【同步】``清除所有内存缓存数据
- (void)clearMemory;

/// ``【异步】``清除所有磁盘缓存数据。
///
/// - Parameter completion: 缓存清除后需要执行的 nullable 回调代码块
/// - Warning: 非阻塞方法，完成回调会立马执行
- (void)clearDiskOnCompletion:(nullable AUCVoidParamsBlock)completion;

/// ``【异步】``删除磁盘中所有已过期的缓存数据。
///
/// - Parameter completionBlock: 缓存完成后应执行的 nullable 代码块
/// - Warning: 非阻塞方法，完成回调会立马执行
- (void)deleteOldFilesWithCompletionBlock:(nullable AUCVoidParamsBlock)completionBlock;

#pragma mark - Cache Info
/// 总磁盘占用内存大小
- (NSUInteger)totalDiskSize;
/// 磁盘缓存中的数量
- (NSUInteger)totalDiskCount;

@end

/// AUCCacheCombine 是缓存管理器的内置缓存实现
/// 它遵循 "AUCCacheProtocol "协议，为缓存管理器提供用于数据加载过程的功能。
@interface AUCCacheCombine (AUCCache) <AUCCacheProtocol>

@end

NS_ASSUME_NONNULL_END
