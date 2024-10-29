//
//  AUTypeDefines.h
//  AUOptimize
//
//  Created by aaron lee on 2024/10/12.
//

#ifndef AUTypeDefines_h
#define AUTypeDefines_h

/// 请将所有的 `typedef` 定义写入此处
#pragma mark - 缓存方式
/// ``缓存方式``
typedef NS_ENUM(NSInteger, AUCCacheType) {
    AUCCacheTypeNone,
    AUCCacheTypeMemory,
    AUCCacheTypeDisk,
    AUCCacheTypeAll
};

#pragma mark - 缓存过期类型
/// ``缓存过期类型, 缓存淘汰策略受其影响``
typedef NS_ENUM(NSUInteger, AUCCacheConfigExpireType) {
    /// 访问缓存时，会更新该值
    AUCCacheConfigExpireTypeAccessDate,
    /// 创建或修改缓存时，将更新此值（默认）
    AUCCacheConfigExpireTypeModificationDate,
    /// 创建缓存时，会更新该值
    AUCCacheConfigExpireTypeCreationDate,
    /// 当创建、修改、重命名或更新文件属性（如权限、xattr）时，缓存将更新此值
    AUCCacheConfigExpireTypeChangeDate,
};


#pragma mark - 缓存操作策略
/// ``缓存操作策略``
typedef NS_ENUM(NSUInteger, AUCCachesManagerOperationPolicy) {
    /// 串行处理所有缓存（按顺序从最高优先级到最低优先级缓存）
    AUCCachesManagerOperationPolicySerial,
    /// 并行处理所有缓存
    AUCCachesManagerOperationPolicyConcurrent,
    /// 仅处理最高优先级缓存
    AUCCachesManagerOperationPolicyHighestOnly,
    /// 仅处理最低优先级缓存
    AUCCachesManagerOperationPolicyLowestOnly
};


#pragma mark - 查询缓存选项
/// ``查询缓存选项``
typedef NS_OPTIONS(NSUInteger, AUCCacheOptions) {
    /// 默认情况下，当数据已缓存在内存中时，不会查询数据。
    /// 设置该值会强制同时查询数据。除非指定`AUCCacheLoadMemoryDataSync`的情况，否则查询将是异步的。
    AUCCacheQueryMemoryData = 1 << 0,
    
    /// 默认情况下，如果只指定 `AUOptimizeQueryMemoryData`，将异步查询内存数据。结合此值可同步查询内存数据。
    /// - Attention: 除非你想确保数据在同一运行循环中加载，以避免UI刷新出现异常，否则不建议同步查询数据。
    AUCCacheQueryMemoryDataSync = 1 << 1,
    
    /// 默认情况下，当内存缓存未命中时，将异步查询磁盘缓存。该值可以强制``同步``查询磁盘缓存（当内存缓存未命中时）。
    /// - Attention: 不建议同步查询数据，除非您想确保数据在同一运行循环中加载以避免在UI刷新异常。
    AUCCacheQueryDiskDataSync = 1 << 2,
    
    
    /** 以下枚举值暂不启用
    /// 默认情况下，当某个 API 连接异常时，该 API 会被列入黑名单，此后将不再尝试进行连接
    /// 此标可禁用列入黑名单，失败时仍需尝试重新连接
    AUCCacheRetryFailed = 1 << 3,
    
    /// 在 iOS 4+ 中，如果应用进入后台，则继续下载数据。具体方法是请求系统让请求完成。如果后台任务过期，操作将被取消。
    AUCCacheContinueInBackground = 1 << 4,
    
    /// 启用允许使用不受信任的 SSL 证书
    ///
    /// - Warning: 用于测试环境 在生产环境中慎用
    AUCCacheAllowInvalidSSLCertificates = 1 << 5,
    
    /// 只从缓存中加载，无缓存的情况下，不会主动进行数据拉取
    AUCCacheFromCacheOnly = 1 << 6,
    
    /// 默认情况下，会在从加载器加载数据前查询缓存。此标记可以阻止这种情况，只从加载器加载。
    AUCCacheFromRequestOnly = 1 << 7,
    
    /// 默认情况下，当从网络加载数据时，数据将被写入缓存（内存和磁盘，由 `storeCacheType` 缓存方式控制）。
    /// 但缓存存储可能是异步操作，最后的 `completionBlock` 回调并不能保证磁盘缓存的写入已经完成，可能会导致逻辑错误。
    /// 例如: 在`completionBlock`回调中修改了磁盘数据，但磁盘缓存还没准备好。
    /// 如果需要在`completionBlock`回调中处理磁盘缓存，则应使用此选项以确保回调时磁盘缓存已写入。
    AUCCacheWaitStoreCache = 1 << 8,
    */
};


//#pragma mark - 网络缓存加载选项
/// ``网络缓存加载选项``
typedef NS_OPTIONS(NSUInteger, AUCCacheLoadOptions) {
    /// 默认情况下，当数据已缓存在内存中时将不再查询
    
    /// 该选项会 `强制继续` 查询磁盘数据，且这种查询是 ``异步`` 的，除非指定 `AUCCacheLoadFromMemoryDataSync` 将同步查询
    AUCCacheLoadFromMemoryData = 1 << 0,
    
    /// ``同步``查询内存缓存数据，当数据已缓存在内存中时将直接返回内存数据，并不再继续查询
    AUCCacheLoadFromMemoryDataSync = 1 << 1,
    
    /// 默认情况下，当内存缓存缺失时，才会异步查询磁盘缓存
    /// - Note: 此选项会强制``同步``查询磁盘缓存（当内存缓存缺失时）
    AUCCacheLoadFromDiskDataSync = 1 << 2,
};

#pragma mark - Blocks Define
/// 无参通用回调
typedef void(^AUCVoidParamsBlock)(void);
/// 附加缓存路径
typedef NSString * _Nullable (^AUCCacheAdditionalCachePathBlock)(NSString * _Nonnull key);

/// 缓存检索完成回调
///
/// - Parameter isInCache: 缓存是否命中
typedef void(^AUCCacheCheckCompletionBlock)(BOOL isInCache);

/// 缓存大小计算回调 - 以字节 `byte` 为单位
///
/// - Parameter fileCount: 文件数
/// - Parameter totalSize: 总字节数
typedef void(^AUCCacheCalculateSizeBlock)(NSUInteger fileCount, NSUInteger totalSize);

/// 缓存查询完成回调
///
/// - Parameter data: 查询到的数据
/// - Parameter cacheType: 缓存方式
typedef void(^AUCCacheQueryCompletionBlock)(id _Nullable data, AUCCacheType cacheType);
typedef void(^AUCCacheContainsCompletionBlock)(AUCCacheType containsCacheType);


#pragma mark - 其他
typedef NSString *AUCacheContextOption NS_EXTENSIBLE_STRING_ENUM;
typedef NSDictionary<AUCacheContextOption, id> AUCCacheContext;
typedef NSMutableDictionary<AUCacheContextOption, id> AUCCacheMutableContext;

#endif /* AUTypeDefines_h */
