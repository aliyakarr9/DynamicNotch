import Foundation

struct AppConstants {
    struct Window {
        static let defaultWidth: CGFloat = 200 // Initial width when collapsed
        static let defaultHeight: CGFloat = 38 // Initial height (match typical menu bar)
        static let expandedWidth: CGFloat = 400
        static let expandedHeight: CGFloat = 280 // Increased for Quick Actions
        static let animationDuration: TimeInterval = 0.3
        static let cornerRadius: CGFloat = 32
    }

    struct Notch {
        // These are defaults; we should rely on safeAreaInsets if possible
        static let defaultHeight: CGFloat = 32
    }
}