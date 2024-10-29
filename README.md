# AUCCache使用

### 全局配置方案：

此种情况下传入 `whitelistAPIs` 最好使用 `完整的 API 路径`。

> 示例：设置用户密码接口的完整接口路径是： `https://au-xxx.app-alpha.com:port/vau/user/password/set`，则此时配置 `whitelistAPIs` 最好使用 <a>user/password/set</a> 或者 <a>/user/password/set</a>。

```objective-c
// 全局配置方案下，内部存储、检索缓存数据时，使用的是接口的 `完整请求路径`，
AUCCacheConfig.defaultConfig.whitelistAPIs = @[@"user/password/set"， @"/user/login/password"];
```

> 此方式数据处理流程如下：
>
> 1. 检索阶段
>
>    - 当 <font color=green>检索到缓存数据时</font>，会调用`completionHandler`直接进行数据返回；
>
>
>    - 当 <font color=red>未检索到缓存数据时</font>，整体流程和加入缓存功能之前一致。只是会在网络请求完成阶段数据返回时，`进行数据缓存存储处理`。
>
>      
>
> 2. 网络请求完成阶段
>
>    - 当 <font color=red>网络请求失败时</font>，流程和之前一致；
>
>    - 当 <font color=green>网络请求成功时</font>，回调时会检索`网络数据和本地缓存数据的一致性`。
>
>       - 当数据一致时将不再进行回调处理
>
>       - 当数据不一致时，和之前流程一致，`同时会覆盖更新本地缓存数据`。



### 手动存储方式

```objective-c
// 存储数据到缓存
[AUCCacheHelper store:data forKey:@"/user/password/set"];

// data为缓存中取到的存储数据。若缓存未命中（内存 + 磁盘），则 `completion` 回调会被抛弃不会被调用
[AUCCacheHelper queryCacheForKey:@"/user/password/set" completion:^(id  _Nullable data, AUCCacheType cacheType) {

}]
```





