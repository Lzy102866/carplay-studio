import SwiftUI

struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        TabView(selection: $state.tab) {
            HomeView()
                .tabItem {
                    Label("壁纸", systemImage: "photo.on.rectangle.angled")
                }
                .tag(RootTab.wallpapers)

            LibraryView()
                .tabItem {
                    Label("我的", systemImage: "square.stack.3d.up")
                }
                .tag(RootTab.library)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(RootTab.settings)
        }
        .tint(Palette.accent)
    }
}
