import Foundation

// MARK: - 对外暴露给界面的状态

enum BridgeState: Equatable {
    case idle
    case pairing
    case ready
    case failed(String)

    var title: String {
        switch self {
        case .idle: return "未连接"
        case .pairing: return "正在配对…"
        case .ready: return "已连接"
        case .failed: return "连接失败"
        }
    }

    var detail: String {
        switch self {
        case .idle: return "点此完成本机配对"
        case .pairing: return "请保持 App 在前台"
        case .ready: return "可以写入车机壁纸"
        case .failed(let reason): return reason
        }
    }

    var isReady: Bool { self == .ready }
}

enum WallpaperSlot: String, CaseIterable, Identifiable {
    case day
    case night

    var id: String { rawValue }
    var title: String { self == .day ? "白天" : "夜间" }
    var suffix: String { self == .day ? "Light" : "Dark" }
}

enum BridgeError: LocalizedError {
    case notPaired
    case tunnelUnavailable
    case encoderUnavailable
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notPaired:
            return "还没有和本机完成配对"
        case .tunnelUnavailable:
            return "设备隧道未接入。需要在 Mac 上接 StikDebug（开发者模式 + personalized DDI），详见 README「接入设备隧道」"
        case .encoderUnavailable:
            return "cpbitmap 编码器未接入"
        case .writeFailed(let reason):
            return "写入车机失败：\(reason)"
        }
    }
}

/// 车机侧的目标位置（来自对 v1 的分析，接入时按这里写）
enum CarPlayTarget {
    static let wallpaperCache = "/Library/Caches/com.apple.CarPlayApp/wallpaper-images"
    static let helperApp = "/Applications/CarPlayWallpaper.app"
    static let fileNamePattern = "CARWallpaper<id>-<Dark|Light>-<index>.cpbitmap"
}

struct WallpaperPayload {
    let imageData: Data
    let slot: WallpaperSlot
    let fileName: String
}

// MARK: - 协议（界面只认这个，不认具体实现）

protocol DeviceBridge: AnyObject {
    var state: BridgeState { get }
    func pair() async throws
    func write(_ payload: WallpaperPayload) async throws
    func disconnect() async
}

// MARK: - 空实现：把"写车机"隔离掉，界面先跑起来

/// 现在能用：配对流程、状态机、错误提示、界面反馈。
/// 还差一步：真正的隧道 + 写文件，见 README。
final class StubDeviceBridge: DeviceBridge {
    private(set) var state: BridgeState = .idle

    func pair() async throws {
        state = .pairing
        try? await Task.sleep(nanoseconds: 800_000_000)
        state = .failed("设备隧道未接入")
        throw BridgeError.tunnelUnavailable
    }

    func write(_ payload: WallpaperPayload) async throws {
        guard state.isReady else { throw BridgeError.notPaired }
        throw BridgeError.tunnelUnavailable
    }

    func disconnect() async {
        state = .idle
    }
}
