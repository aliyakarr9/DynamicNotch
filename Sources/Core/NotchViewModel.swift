import SwiftUI
import Combine

@Observable
class NotchViewModel {
    var isExpanded: Bool = false {
        didSet {
            if oldValue != isExpanded {
                onExpandChange?(isExpanded)
            }
        }
    }
    var isHovering: Bool = false
    var mediaInfo: MediaInfo = MediaInfo()

    var onExpandChange: ((Bool) -> Void)?

    private let hoverManager = HoverManager()
    private let mediaService = MediaService()
    // Yeni eklenen servis:
    private let quickActionsService = QuickActionsService()

    init() {
        hoverManager.onHoverChange = { [weak self] hovering in
            Task { @MainActor in
                self?.isHovering = hovering
                self?.updateExpansionState()
            }
        }

        mediaService.onMediaChange = { [weak self] info in
            Task { @MainActor in
                self?.mediaInfo = info
            }
        }

        mediaService.startPolling()
    }

    deinit {
        mediaService.stopPolling()
    }

    private func updateExpansionState() {
        if isHovering {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = true
            }
        } else {
            // Add a small delay if needed
            // For now, collapse immediately when hover ends
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = false
            }
        }
    }

    // MARK: - Media Controls

    func togglePlayPause() {
        mediaService.playPause()
    }

    func nextTrack() {
        mediaService.nextTrack()
    }

    func previousTrack() {
        mediaService.previousTrack()
    }

    // MARK: - Quick Actions

    func performQuickAction(_ action: QuickActionType) {
        quickActionsService.perform(action)
    }
}