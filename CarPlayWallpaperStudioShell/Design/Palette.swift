import SwiftUI

enum Palette {
    static let background = Color(red: 0.043, green: 0.051, blue: 0.071)
    static let surface = Color(red: 0.094, green: 0.110, blue: 0.145)
    static let surfaceHigh = Color(red: 0.133, green: 0.153, blue: 0.196)
    static let accent = Color(red: 0.35, green: 0.78, blue: 0.98)
    static let success = Color(red: 0.36, green: 0.85, blue: 0.60)
    static let warning = Color(red: 0.98, green: 0.72, blue: 0.35)
    static let textSecondary = Color(red: 0.62, green: 0.66, blue: 0.74)
    static let hairline = Color.white.opacity(0.08)
}

private struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Palette.background.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}
