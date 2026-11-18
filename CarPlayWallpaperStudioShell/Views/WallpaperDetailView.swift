import SwiftUI

struct WallpaperDetailView: View {
    let route: ThemeRoute

    @EnvironmentObject private var state: AppState
    @State private var selectedID: String
    @State private var isWorking = false
    @State private var alertMessage: String?

    init(route: ThemeRoute) {
        self.route = route
        _selectedID = State(initialValue: route.startID)
    }

    private var wallpaper: Wallpaper {
        route.items.first { $0.id == selectedID } ?? route.items.first ?? .placeholder
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { newValue in if !newValue { alertMessage = nil } }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                titleBlock
                if route.items.count > 1 { strip }
                actions
                specs
                NoticeCard(
                    title: "空壳状态",
                    systemImage: "hammer",
                    message: "取图、收藏、配对状态机都已实现；「写入车机」这一步依赖开发者模式隧道，需要在 Mac 上接 StikDebug 后才能跑通（见 README）。"
                )
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
        .screenBackground()
        .navigationTitle(wallpaper.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("提示", isPresented: alertBinding) {
            Button("知道了", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - 组件

    private var hero: some View {
        ContentImage(asset: wallpaper.preview)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .topLeading) {
                ModeBadge(isNight: wallpaper.isNight).padding(10)
            }
            .padding(.horizontal, 20)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(wallpaper.title)
                .font(.title2.weight(.semibold))
            HStack(spacing: 8) {
                Text(route.themeName)
                Text("·")
                Text(wallpaper.modeTitle)
                if let full = wallpaper.full {
                    Text("·")
                    Text(full.resolutionText)
                }
            }
            .font(.caption)
            .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(route.items) { item in
                    Button {
                        selectedID = item.id
                    } label: {
                        ContentImage(asset: item.preview)
                            .frame(width: 96, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(item.id == wallpaper.id ? Palette.accent : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                applyToDevice()
            } label: {
                HStack(spacing: 8) {
                    if isWorking {
                        ProgressView().tint(.black)
                    }
                    Text(isWorking ? "处理中…" : "设为车机壁纸")
                }
            }
            .buttonStyle(PrimaryButtonStyle(enabled: !isWorking))
            .disabled(isWorking)

            Button {
                let added = state.library.toggle(wallpaper)
                alertMessage = added ? "已收藏「\(wallpaper.title)」" : "已从收藏中移除"
            } label: {
                Label(
                    state.library.contains(wallpaper) ? "取消收藏" : "收藏",
                    systemImage: state.library.contains(wallpaper) ? "heart.slash" : "heart"
                )
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, 20)
    }

    private var specs: some View {
        VStack(spacing: 10) {
            InfoRow(title: "主题", value: route.themeName)
            InfoRow(title: "模式", value: wallpaper.modeTitle)
            if let preview = wallpaper.preview {
                InfoRow(title: "预览", value: preview.resolutionText)
            }
            if let full = wallpaper.full {
                InfoRow(title: "全尺寸", value: "\(full.resolutionText) · \(full.sizeText)")
                InfoRow(title: "SHA-256", value: String(full.sha256.prefix(16)) + "…")
            }
            InfoRow(title: "包内密文", value: ContentVault.contains(named: wallpaper.preview?.sha256 ?? "", ext: wallpaper.preview?.fileExtension ?? "jpg") ? "有" : "无（走远端）")
        }
        .padding(16)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: - 动作

    private func applyToDevice() {
        guard let full = wallpaper.full else {
            alertMessage = "这张壁纸没有全尺寸资源"
            return
        }
        Task {
            isWorking = true
            defer { isWorking = false }
            do {
                let data = try await ContentResolver.imageData(for: full)
                try await state.apply(wallpaper, imageData: data)
                alertMessage = "已写入车机：\(wallpaper.title)"
            } catch {
                alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
