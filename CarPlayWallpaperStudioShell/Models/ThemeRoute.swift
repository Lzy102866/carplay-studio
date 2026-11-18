import Foundation

/// 详情页的路由：带上同主题的整组壁纸，方便左右切换。
struct ThemeRoute: Hashable {
    let themeName: String
    let items: [Wallpaper]
    let startID: String

    var startIndex: Int {
        items.firstIndex { $0.id == startID } ?? 0
    }
}
