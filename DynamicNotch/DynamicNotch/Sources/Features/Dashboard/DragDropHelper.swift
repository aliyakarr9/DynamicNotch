import SwiftUI
import AppKit

struct DropView: NSViewRepresentable {
    var viewModel: NotchViewModel

    func makeNSView(context: Context) -> DropHandlerView {
        let view = DropHandlerView()
        view.viewModel = viewModel
        return view
    }

    func updateNSView(_ nsView: DropHandlerView, context: Context) {
        nsView.viewModel = viewModel
    }
}

class DropHandlerView: NSView {
    weak var viewModel: NotchViewModel?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
       
        registerForDraggedTypes([.fileURL, .URL, .string])
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        DispatchQueue.main.async {
            self.viewModel?.isDropping = true
            if self.viewModel?.isExpanded == false {
                withAnimation { self.viewModel?.isExpanded = true }
            }
        }
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        DispatchQueue.main.async {
            self.viewModel?.isDropping = false
        }
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        var foundURLs: [URL] = []

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            foundURLs.append(contentsOf: urls)
        }
        
        if foundURLs.isEmpty, let filePaths = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            foundURLs = filePaths.map { URL(fileURLWithPath: $0) }
        }

        guard !foundURLs.isEmpty else { return false }

        DispatchQueue.main.async {
            print("✅ Dosyalar Yakalandı: \(foundURLs.count) adet")
            foundURLs.forEach { _ = $0.startAccessingSecurityScopedResource() }
            
            self.viewModel?.addFiles(foundURLs)
            self.viewModel?.isDropping = false
        }
        return true
    }
}
