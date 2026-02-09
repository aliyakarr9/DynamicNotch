import AppKit

extension NSScreen {
    /// Returns the screen that contains the notch.
    /// This is typically the built-in display where safeAreaInsets.top is greater than 0.
    /// Fallback to the first screen (usually main) if no notch is detected.
    static var withNotch: NSScreen? {
        return screens.first { $0.safeAreaInsets.top > 0 } ?? screens.first
    }
}
