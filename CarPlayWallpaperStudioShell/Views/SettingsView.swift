import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var showResetConfirm = false

    private var revision: Int { state.catalog.catalog?.revision ?? 0 }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    InfoRow(title: "版本", value: "\(AppConfig.version) (\(AppConfig.build))")
                    InfoRow(title: "主题 / 壁纸", value: "\(state.catalog.themes.count) / \(state.catalog.wallpaperCount)")
                    InfoRow(title: "目录版本", value: "rev \(revision)")
                    InfoRow(title: "素材加密", value: "ChaCha20-Poly1305")
                } header: {
                    Text("应用")
                }

                Section {
                    InfoRow(title: "设备隧道", value: state.connection.title)
                    InfoRow(title: "收费 / 授权", value: "无")
                    InfoRow(title: "素材来源", value: AppConfig.contentBaseURL == nil ? "仅包内" : "包内 + 远端")
                } header: {
                    Text("状态")
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("清空本地收藏（\(state.library.saved.count)）", systemImage: "trash")
                    }
                    Button {
                        ContentImageCache.shared.purge()
                    } label: {
                        Label("清空图片缓存", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("操作")
                }

                Section {
                    Text("这是按原版功能重建的空壳工程：界面、目录、加密素材、收藏、配对状态机都已具备，唯一缺口是「写车机」那一段（需要 Mac + 真机调试）。本工程不含任何收费、授权、卡密、设备绑定逻辑。")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("说明")
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("设置")
            .confirmationDialog("确定清空所有收藏？", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("清空", role: .destructive) { state.library.removeAll() }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
