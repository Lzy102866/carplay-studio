import Foundation

/// 目录加载：读包内的 WallpaperCatalog.json（和原版同一份格式）。
@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var catalog: WallpaperCatalog?
    @Published private(set) var loadError: String?

    init() {
        load()
    }

    var themes: [WallpaperTheme] { catalog?.themes ?? [] }
    var wallpaperCount: Int { themes.reduce(0) { $0 + $1.items.count } }

    func load() {
        guard let url = Bundle.main.url(forResource: "WallpaperCatalog", withExtension: "json") else {
            loadError = "缺少 WallpaperCatalog.json"
            return
        }
        do {
            let data = try Data(contentsOf: url)
            catalog = try JSONDecoder().decode(WallpaperCatalog.self, from: data)
            loadError = nil
        } catch {
            loadError = "目录解析失败：\(error.localizedDescription)"
        }
    }
}
