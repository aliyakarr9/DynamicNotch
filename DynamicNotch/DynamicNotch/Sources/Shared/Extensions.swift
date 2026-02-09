import AppKit

extension NSScreen {
    static var withNotch: NSScreen? {
        return screens.first { $0.safeAreaInsets.top > 0 } ?? screens.first
    }
}
