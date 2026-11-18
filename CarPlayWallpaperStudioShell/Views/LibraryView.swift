import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var state: AppState

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if state.library.saved.isEmpty {
                    EmptyState(
                        title: "还没有收藏",
                        message: "在壁纸详情里点「收藏」，这里就会出现。",
                        systemImage: "square.stack.3d.up.slash"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(state.library.saved) { item in
                                tile(item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .screenBackground()
            .navigationTitle("我的壁纸")
        }
    }

    private func tile(_ item: Wallpaper) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ContentImage(asset: item.preview)
                .frame(height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(item.title)
                .font(.footnote.weight(.medium))
                .lineLimit(1)
            Text("\(item.modeTitle) · \(item.preview?.resolutionText ?? "")")
                .font(.caption2)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
        .contextMenu {
            Button(role: .destructive) {
                state.library.toggle(item)
            } label: {
                Label("移除", systemImage: "trash")
            }
        }
    }
}
