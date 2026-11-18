import SwiftUI
import Combine

enum RootTab: Hashable {
    case wallpapers
    case library
    case settings
}

@MainActor
final class AppState: ObservableObject {
    @Published var tab: RootTab = .wallpapers
    @Published var showConnectSheet = false
    @Published private(set) var connection: BridgeState = .idle

    let catalog = CatalogStore()
    let library = LibraryStore()
    private let bridge: DeviceBridge

    init(bridge: DeviceBridge = StubDeviceBridge()) {
        self.bridge = bridge
        self.connection = bridge.state
    }

    var isConnected: Bool { connection.isReady }

    func connect() async {
        connection = .pairing
        do {
            try await bridge.pair()
            connection = bridge.state
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            connection = .failed(message)
        }
    }

    func disconnect() async {
        await bridge.disconnect()
        connection = .idle
    }

    func apply(_ wallpaper: Wallpaper, imageData: Data) async throws {
        guard isConnected else { throw BridgeError.notPaired }
        let payload = WallpaperPayload(
            imageData: imageData,
            slot: wallpaper.isNight ? .night : .day,
            fileName: wallpaper.file
        )
        try await bridge.write(payload)
    }
}
