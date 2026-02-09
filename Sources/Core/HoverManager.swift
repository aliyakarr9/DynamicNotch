import AppKit
import Combine

class HoverManager {
    var isHovering: Bool = false {
        didSet {
            if oldValue != isHovering {
                onHoverChange?(isHovering)
            }
        }
    }

    var onHoverChange: ((Bool) -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let hoverZoneWidth: CGFloat = 300 // Wider than the notch
    private let hoverZoneHeight: CGFloat = 40 // Height of the area around the notch

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        // Global monitor for when the app is in the background
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.checkHover()
        }

        // Local monitor for when the app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkHover()
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func checkHover() {
        guard let screen = NSScreen.withNotch else { return }

        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = screen.frame
        let notchHeight = screen.safeAreaInsets.top > 0 ? screen.safeAreaInsets.top : AppConstants.Notch.defaultHeight

        // Define the hover zone (top center of the screen)
        let midX = screenFrame.midX
        let zoneMinX = midX - hoverZoneWidth / 2
        let zoneMaxX = midX + hoverZoneWidth / 2

        let screenTop = screenFrame.maxY
        let zoneMinY = screenTop - max(notchHeight, hoverZoneHeight)

        let isInside = mouseLocation.x >= zoneMinX && mouseLocation.x <= zoneMaxX &&
                       mouseLocation.y >= zoneMinY

        if isInside != isHovering {
            // Ensure updates happen on the main thread
            DispatchQueue.main.async {
                self.isHovering = isInside
            }
        }
    }
}
