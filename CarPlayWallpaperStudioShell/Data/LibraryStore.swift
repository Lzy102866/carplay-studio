import Foundation

/// 本地收藏：写入 Documents/UserWallpapers/index.json，和原版同一套目录习惯。
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var saved: [Wallpaper] = []

    private let directory: URL
    private var indexURL: URL { directory.appendingPathComponent("index.json") }

    init() {
        let manager = FileManager.default
        directory = manager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("UserWallpapers", isDirectory: true)
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    func contains(_ wallpaper: Wallpaper) -> Bool {
        saved.contains { $0.id == wallpaper.id }
    }

    @discardableResult
    func toggle(_ wallpaper: Wallpaper) -> Bool {
        if let index = saved.firstIndex(where: { $0.id == wallpaper.id }) {
            saved.remove(at: index)
            save()
            return false
        }
        saved.append(wallpaper)
        save()
        return true
    }

    func remove(at offsets: IndexSet) {
        saved.remove(atOffsets: offsets)
        save()
    }

    func removeAll() {
        saved.removeAll()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let items = try? JSONDecoder().decode([Wallpaper].self, from: data) else {
            return
        }
        saved = items
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
