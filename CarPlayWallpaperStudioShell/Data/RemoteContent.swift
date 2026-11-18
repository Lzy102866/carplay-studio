import Foundation

/// 大图下载（包内只带预览图，全尺寸图按需下载）。
/// 这里刻意不接任何授权：把你的 CDN 地址填到 `AppConfig.contentBaseURL` 就能用。
enum ContentError: LocalizedError {
    case noSource
    case http(Int)
    case emptyPayload

    var errorDescription: String? {
        switch self {
        case .noSource:
            return "还没有配置大图来源（AppConfig.contentBaseURL）"
        case .http(let code):
            return "下载失败：HTTP \(code)"
        case .emptyPayload:
            return "下载到的内容是空的"
        }
    }
}

enum RemoteContent {
    static func fetch(_ asset: WallpaperAsset) async throws -> Data {
        guard let base = AppConfig.contentBaseURL else { throw ContentError.noSource }
        let path = String(format: AppConfig.contentPath, asset.sha256, asset.fileExtension)
        guard let url = URL(string: path, relativeTo: base) else { throw ContentError.noSource }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("image/*", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ContentError.http(http.statusCode)
        }
        guard !data.isEmpty else { throw ContentError.emptyPayload }
        return data
    }
}

/// 取图：先看保险柜（包内密文），再退回远端。
enum ContentResolver {
    static func imageData(for asset: WallpaperAsset) async throws -> Data {
        if let local = ContentVault.data(named: asset.sha256, ext: asset.fileExtension) {
            return local
        }
        return try await RemoteContent.fetch(asset)
    }
}
