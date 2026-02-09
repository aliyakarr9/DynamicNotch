import AppKit
import SwiftUI
import QuartzCore

class NotchWindowController: NSWindowController {
    let viewModel = NotchViewModel()

    init() {
        let window = NotchWindow()
        super.init(window: window)

        let contentView = DashboardView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

        window.contentViewController = hostingController

        setupWindow()

        viewModel.onExpandChange = { [weak self] expanded in
            self?.animateWindowFrame(expanded: expanded)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        updateWindowFrame(expanded: false, animate: false)

        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func screenChanged() {
        updateWindowFrame(expanded: viewModel.isExpanded, animate: false)
    }

    private func updateWindowFrame(expanded: Bool, animate: Bool) {
        guard let window = window, let screen = NSScreen.withNotch else { return }

        let screenFrame = screen.frame
        let notchHeight = screen.safeAreaInsets.top > 0 ? screen.safeAreaInsets.top : AppConstants.Notch.defaultHeight

        let width = expanded ? AppConstants.Window.expandedWidth : AppConstants.Window.defaultWidth
        let height = expanded ? AppConstants.Window.expandedHeight : AppConstants.Window.defaultHeight

        let x = screenFrame.midX - width / 2
        // Position at absolute top (screen.frame.maxY) and extend downwards by height
        let y = screenFrame.maxY - height

        let newFrame = NSRect(x: x, y: y, width: width, height: height)

        if animate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = AppConstants.Window.animationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(newFrame, display: true)
            }
        } else {
            window.setFrame(newFrame, display: true)
        }
    }

    private func animateWindowFrame(expanded: Bool) {
        updateWindowFrame(expanded: expanded, animate: true)
    }
}
