import SwiftUI
import Combine
import UniformTypeIdentifiers

@Observable
class NotchViewModel {

    var isExpanded: Bool = false {
        didSet {
            if oldValue != isExpanded {
                onExpandChange?(isExpanded)
            }
        }
    }
    
   
    var isDropping: Bool = false
    var droppedFiles: [URL] = []
    

    var isTrayOpen: Bool = false
    

    private(set) var isHovering: Bool = false
    var mediaInfo: MediaInfo = MediaInfo()
    var onExpandChange: ((Bool) -> Void)?

    private let hoverManager = HoverManager()
    private let mediaService = MediaService()
    private let quickActionsService = QuickActionsService()
    
    private var collapseWorkItem: DispatchWorkItem?

    init() {
        hoverManager.onHoverChange = { [weak self] hovering in
            Task { @MainActor in
                self?.handleHoverChange(hovering)
            }
        }

        mediaService.onMediaChange = { [weak self] info in
            Task { @MainActor in
                self?.mediaInfo = info
            }
        }
        mediaService.startPolling()
    }
    
    deinit { mediaService.stopPolling() }


    private func handleHoverChange(_ hovering: Bool) {
      
        if hovering || isDropping || isTrayOpen {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            self.isHovering = true
            self.updateExpansionState()
            
        } else {
            let userDelay = UserDefaults.standard.double(forKey: "hoverDelay")
            let finalDelay = userDelay == 0 ? 2.0 : userDelay
            
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self, !self.isDropping, !self.isTrayOpen else { return }
                self.isHovering = false
                self.updateExpansionState()
            }
            
            self.collapseWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay, execute: workItem)
        }
    }

    private func updateExpansionState() {
       
        if isHovering || isDropping || !droppedFiles.isEmpty || isTrayOpen {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = true
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = false
            }
        }
    }

  
    func addFiles(_ urls: [URL]) {
        DispatchQueue.main.async {
            self.droppedFiles.append(contentsOf: urls)
           
            self.isTrayOpen = true
            self.updateExpansionState()
        }
    }
    
    func removeFile(_ url: URL) {
        DispatchQueue.main.async {
            self.droppedFiles.removeAll { $0 == url }
         
            if self.droppedFiles.isEmpty && !self.isHovering && !self.isTrayOpen {
                self.handleHoverChange(false)
            }
        }
    }

    // MARK: - Aksiyonlar
    func togglePlayPause() { mediaService.playPause() }
    func nextTrack() { mediaService.nextTrack() }
    func previousTrack() { mediaService.previousTrack() }
    func performQuickAction(_ action: QuickActionType) { quickActionsService.perform(action) }
}
