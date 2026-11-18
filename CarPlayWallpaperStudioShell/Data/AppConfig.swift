import Foundation

/// 全局配置。改这里就能切换素材来源，不用动界面。
///
/// 说明：这个工程**没有收费/授权模块**。如果你以后要下发自家 CDN 上的大图，
/// 只需要把 `contentBaseURL` 换成你的域名，并在 `RemoteContent` 里加一个请求头。
enum AppConfig {
    /// 应用显示名与版本（设置页展示用）
    static let displayName = "壁纸工坊"
    static let version = "2.0.0"
    static let build = "shell.1"

    /// 大图下载源。留空表示只用包内素材。
    /// 例：URL(string: "https://cdn.example.com")
    static let contentBaseURL: URL? = nil

    /// 下载接口路径模板（与 v1 目录里的 path 字段保持一致）
    static let contentPath = "/v1/wallpapers/files/%@.%@"

    /// 单次会话最多缓存多少张解密后的图（张）
    static let imageCacheCount = 40
}

enum AppEnvironment {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
