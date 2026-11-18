import Foundation

// MARK: - 目录（与 WallpaperCatalog.json 一一对应）

struct WallpaperCatalog: Codable {
    let schema: Int
    let bundleID: String
    let revision: Int
    let themes: [WallpaperTheme]

    enum CodingKeys: String, CodingKey {
        case schema
        case revision
        case themes
        case bundleID = "bundle_id"
    }
}

struct WallpaperTheme: Codable, Identifiable, Hashable {
    let name: String
    let items: [Wallpaper]

    var id: String { name }
}

struct Wallpaper: Codable, Identifiable, Hashable {
    let file: String
    let mode: String
    let resourceID: String
    let title: String
    let styleMode: Int?
    let preview: WallpaperAsset?
    let full: WallpaperAsset?

    enum CodingKeys: String, CodingKey {
        case file
        case mode
        case title
        case preview
        case full
        case resourceID = "resource_id"
        case styleMode = "style_mode"
    }

    var id: String { resourceID }
    var isNight: Bool { mode.lowercased() == "night" }
    var modeTitle: String { isNight ? "夜间" : "白天" }
}

struct WallpaperAsset: Codable, Hashable {
    let sha256: String
    let ext: String?
    let sizeBytes: Int?
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case sha256
        case ext
        case width
        case height
        case sizeBytes = "size_bytes"
    }

    var fileExtension: String { ext ?? "jpg" }
    var resolutionText: String {
        guard let width, let height else { return "未知" }
        return "\(width) × \(height)"
    }
    var sizeText: String {
        guard let sizeBytes else { return "未知" }
        return ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }
}

extension Wallpaper {
    static let placeholder = Wallpaper(
        file: "",
        mode: "day",
        resourceID: "placeholder",
        title: "未命名",
        styleMode: nil,
        preview: nil,
        full: nil
    )
}
