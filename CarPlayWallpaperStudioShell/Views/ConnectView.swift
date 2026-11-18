import SwiftUI

struct ConnectView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    private let steps: [String] = [
        "用数据线把 iPhone 连到车机，或让两者处在同一 Wi-Fi",
        "首次连接时，在系统弹窗里允许「本地网络」访问",
        "保持 App 在前台，配对过程中不要切到后台",
        "等待隧道建立，状态变为「已连接」"
    ]

    private var tint: Color {
        switch state.connection {
        case .ready: return Palette.success
        case .failed: return Palette.warning
        case .pairing: return Palette.accent
        case .idle: return Palette.textSecondary
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusCard
                    stepsCard
                    NoticeCard(
                        title: "当前是空壳工程",
                        systemImage: "hammer",
                        message: "配对状态机、错误提示、界面反馈都已完成。真正建立隧道并写车机的那一步需要接 StikDebug（开发者模式 + personalized DDI），接入点见 README。"
                    )
                    actionButtons
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("本机配对")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.16)).frame(width: 54, height: 54)
                Image(systemName: state.connection.isReady ? "checkmark.seal.fill" : "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(state.connection.title)
                    .font(.headline)
                Text(state.connection.detail)
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("配对步骤")
                .font(.subheadline.weight(.semibold))
            ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Palette.accent)
                        .frame(width: 20, height: 20)
                        .background(Palette.accent.opacity(0.14), in: Circle())
                    Text(text)
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                Task { await state.connect() }
            } label: {
                Text(state.connection == .pairing ? "正在配对…" : "开始配对")
            }
            .buttonStyle(PrimaryButtonStyle(enabled: state.connection != .pairing))
            .disabled(state.connection == .pairing)

            Button {
                Task { await state.disconnect() }
            } label: {
                Text("断开连接")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(state.connection == .idle)
        }
    }
}
