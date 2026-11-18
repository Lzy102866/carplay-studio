import SwiftUI
import UIKit

// MARK: - 解密图片缓存

final class ContentImageCache {
    static let shared = ContentImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = AppConfig.imageCacheCount
        return cache
    }()

    func image(for asset: WallpaperAsset?) -> UIImage? {
        guard let asset else { return nil }
        let key = "\(asset.sha256).\(asset.fileExtension)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let data = ContentVault.data(named: asset.sha256, ext: asset.fileExtension),
              let image = UIImage(data: data) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }

    func purge() {
        cache.removeAllObjects()
    }
}

struct ContentImage: View {
    let asset: WallpaperAsset?

    var body: some View {
        Group {
            if let image = ContentImageCache.shared.image(for: asset) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Palette.surface
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .clipped()
    }
}

// MARK: - 小组件

struct ModeBadge: View {
    let isNight: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isNight ? "moon.stars.fill" : "sun.max.fill")
            Text(isNight ? "夜间" : "白天")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.footnote.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct NoticeCard: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.accent)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Palette.textSecondary)
            Text(title).font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 按钮样式

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.black.opacity(enabled ? 0.9 : 0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Palette.accent.opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.28))
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.06))
            )
    }
}
