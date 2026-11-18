import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ConnectBanner()

                    if let error = state.catalog.loadError {
                        NoticeCard(
                            title: "目录加载失败",
                            systemImage: "exclamationmark.triangle",
                            message: error
                        )
                        .padding(.horizontal, 20)
                    }

                    ForEach(state.catalog.themes) { theme in
                        if !theme.items.isEmpty {
                            ThemeSectionView(theme: theme)
                        }
                    }

                    footer
                }
                .padding(.vertical, 16)
            }
            .screenBackground()
            .navigationTitle(AppConfig.displayName)
            .navigationDestination(for: ThemeRoute.self) { route in
                WallpaperDetailView(route: route)
            }
            .sheet(isPresented: $state.showConnectSheet) {
                ConnectView()
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("共 \(state.catalog.themes.count) 个主题 · \(state.catalog.wallpaperCount) 张壁纸")
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
            Text("素材已加密存放，运行时解密；本版本不含任何收费或授权模块。")
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - 连接状态条

struct ConnectBanner: View {
    @EnvironmentObject private var state: AppState

    private var tint: Color {
        switch state.connection {
        case .ready: return Palette.success
        case .failed: return Palette.warning
        default: return Palette.accent
        }
    }

    private var icon: String {
        switch state.connection {
        case .ready: return "checkmark.seal.fill"
        case .pairing: return "arrow.triangle.2.circlepath"
        case .failed: return "exclamationmark.triangle.fill"
        case .idle: return "bolt.horizontal.circle"
        }
    }

    var body: some View {
        Button {
            state.showConnectSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.connection.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(state.connection.detail)
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

// MARK: - 主题行

struct ThemeSectionView: View {
    let theme: WallpaperTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(theme.name)
                    .font(.headline)
                Text("\(theme.items.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(theme.items) { item in
                        NavigationLink(value: ThemeRoute(themeName: theme.name, items: theme.items, startID: item.id)) {
                            WallpaperCard(wallpaper: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct WallpaperCard: View {
    let wallpaper: Wallpaper

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContentImage(asset: wallpaper.preview)
                .frame(width: 236, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topLeading) {
                    ModeBadge(isNight: wallpaper.isNight)
                        .padding(6)
                }

            HStack(spacing: 6) {
                Text(wallpaper.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let full = wallpaper.full {
                    Text(full.resolutionText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .frame(width: 236, alignment: .leading)
        }
    }
}
