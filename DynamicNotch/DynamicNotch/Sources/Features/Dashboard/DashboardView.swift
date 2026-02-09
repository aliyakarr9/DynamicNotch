import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DashboardView: View {
    var viewModel: NotchViewModel
    
    @AppStorage("showCalendar") private var showCalendar: Bool = true
    
    let gridColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var currentWidth: CGFloat {
        if viewModel.isExpanded {
            if viewModel.isTrayOpen || !viewModel.droppedFiles.isEmpty {
                return AppConstants.Window.expandedWidth
            }
            return showCalendar ? AppConstants.Window.expandedWidth : (AppConstants.Window.expandedWidth - 162)
        } else {
            return AppConstants.Window.defaultWidth
        }
    }

    var body: some View {
        ZStack {
            
            Color.black.opacity(0.7)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
                .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
                .overlay(
                    UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

            
            if viewModel.isExpanded {
                HStack(spacing: 12) {
                    
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            viewModel.isTrayOpen.toggle()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(viewModel.isTrayOpen ? Color.blue : Color.white.opacity(0.1))
                            
                            Image(systemName: viewModel.isTrayOpen ? "xmark" : "tray.and.arrow.down.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 50, height: 90)
                    
                    
                    if viewModel.isTrayOpen {
                        
                        DropZoneView(viewModel: viewModel)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        
                        HStack(spacing: 12) {
                            MusicPlayerView(viewModel: viewModel)
                                .frame(width: 240, height: 90)
                                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))

                            if showCalendar {
                                CalendarWidgetView()
                                    .frame(width: 150, height: 90)
                                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
                                    .transition(.scale.combined(with: .opacity))
                            }

                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ModernActionButton(icon: "plus.slash.minus", action: { viewModel.performQuickAction(.calculator) })
                                ModernActionButton(icon: "gearshape", action: { viewModel.performQuickAction(.settings) })
                                ModernActionButton(icon: "lock.fill", action: { viewModel.performQuickAction(.lock) })
                                ModernActionButton(icon: "viewfinder", action: { viewModel.performQuickAction(.screenshot) })
                            }
                            .frame(width: 100, height: 90)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: AppConstants.Window.expandedHeight)
            }
        }
        .frame(width: currentWidth, height: viewModel.isExpanded ? AppConstants.Window.expandedHeight : AppConstants.Window.defaultHeight)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isExpanded)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isTrayOpen)
    }
}


struct DropZoneView: View {
    var viewModel: NotchViewModel
    @State private var isHoveringDrop = false

    var body: some View {
        ZStack {
            
            NativeDropArea(viewModel: viewModel, isHovering: $isHoveringDrop)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .fill(isHoveringDrop ? Color.green : Color.white.opacity(0.3))
                
                if viewModel.droppedFiles.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 30))
                            .foregroundColor(isHoveringDrop ? .green : .white)
                        Text("Dosyaları Buraya Bırak")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.droppedFiles, id: \.self) { url in
                                FileItemView(url: url) {
                                    viewModel.removeFile(url)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: 90)
    }
}

struct NativeDropArea: NSViewRepresentable {
    var viewModel: NotchViewModel
    @Binding var isHovering: Bool

    func makeNSView(context: Context) -> DropViewNS {
        let view = DropViewNS()
        view.viewModel = viewModel
        view.onHoverChange = { hovering in
            self.isHovering = hovering
        }
        return view
    }

    func updateNSView(_ nsView: DropViewNS, context: Context) {
        nsView.viewModel = viewModel
    }
}

class DropViewNS: NSView {
    weak var viewModel: NotchViewModel?
    var onHoverChange: ((Bool) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
       
        registerForDraggedTypes([.fileURL, .URL, NSPasteboard.PasteboardType("NSFilenamesPboardType")])
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) { fatalError() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onHoverChange?(true)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onHoverChange?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onHoverChange?(false)
        guard let viewModel = viewModel else { return false }
        
        let pasteboard = sender.draggingPasteboard
        var foundURLs: [URL] = []
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            foundURLs.append(contentsOf: urls)
        }
        
        if foundURLs.isEmpty, let filePaths = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            foundURLs = filePaths.map { URL(fileURLWithPath: $0) }
        }
        
        if !foundURLs.isEmpty {
            DispatchQueue.main.async {
                foundURLs.forEach { _ = $0.startAccessingSecurityScopedResource() }
                viewModel.addFiles(foundURLs)
            }
            return true
        }
        return false
    }
}

struct MusicPlayerView: View {
    var viewModel: NotchViewModel
    var body: some View {
        HStack(spacing: 12) {
            if let urlString = viewModel.mediaInfo.artworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().aspectRatio(contentMode: .fill) }
                    else { Color.gray.opacity(0.3) }
                }.frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let artworkData = viewModel.mediaInfo.artworkData, let nsImage = NSImage(data: artworkData) {
                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)).frame(width: 60, height: 60).overlay(Image(systemName: "music.note").foregroundColor(.white.opacity(0.3)))
            }
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.mediaInfo.title.isEmpty ? "Müzik Yok" : viewModel.mediaInfo.title).font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Text(viewModel.mediaInfo.artist.isEmpty ? "Bekleniyor..." : viewModel.mediaInfo.artist).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6)).lineLimit(1)
                }
                Capsule().fill(Color.white.opacity(0.2)).frame(height: 3).overlay(GeometryReader { geo in Capsule().fill(Color.white).frame(width: geo.size.width * 0.4) }, alignment: .leading)
                HStack(spacing: 15) {
                    Button(action: { viewModel.previousTrack() }) { Image(systemName: "backward.fill").font(.system(size: 12)).foregroundColor(.white) }.buttonStyle(PlainButtonStyle())
                    Button(action: { viewModel.togglePlayPause() }) { Image(systemName: viewModel.mediaInfo.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 16)).foregroundColor(.white) }.buttonStyle(PlainButtonStyle())
                    Button(action: { viewModel.nextTrack() }) { Image(systemName: "forward.fill").font(.system(size: 12)).foregroundColor(.white) }.buttonStyle(PlainButtonStyle())
                }
            }
        }.padding(.horizontal, 10)
    }
}

struct FileItemView: View {
    let url: URL; let onDelete: () -> Void; @State private var isHovering = false
    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit).frame(width: 42, height: 42)
                Text(url.lastPathComponent).font(.system(size: 10)).foregroundColor(.white).lineLimit(1).frame(width: 60)
            }.padding(8).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(isHovering ? 0.3 : 0.0), lineWidth: 1))
            if isHovering { Button(action: onDelete) { Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundColor(.red).background(Circle().fill(Color.white)) }.buttonStyle(.plain).offset(x: 6, y: -6) }
        }.contentShape(Rectangle()).onHover { h in withAnimation(.easeInOut(duration: 0.1)) { isHovering = h } }
    }
}

struct CalendarWidgetView: View {
    var body: some View {
        VStack(spacing: 2) {
            Text(Date.now.formatted(.dateTime.weekday(.wide)).uppercased()).font(.system(size: 10, weight: .bold)).foregroundColor(.red).padding(.top, 4)
            Text(Date.now.formatted(.dateTime.day())).font(.system(size: 42, weight: .bold, design: .rounded)).foregroundColor(.white).shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            Text(Date.now.formatted(.dateTime.month().year())).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.5)).padding(.bottom, 4)
        }.contentShape(Rectangle()).onTapGesture {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
        }
    }
}

struct ModernActionButton: View {
    let icon: String; let action: () -> Void; @State private var isHovering = false
    var body: some View {
        Button(action: action) {
            ZStack { RoundedRectangle(cornerRadius: 14).fill(isHovering ? Color.white.opacity(0.2) : Color.white.opacity(0.08)); Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(.white) }.frame(width: 45, height: 40)
        }.buttonStyle(.plain).onHover { h in withAnimation(.easeInOut(duration: 0.2)) { isHovering = h } }
    }
}
