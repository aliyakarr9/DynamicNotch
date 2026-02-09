import SwiftUI

struct DashboardView: View {
    var viewModel: NotchViewModel

    var body: some View {
        ZStack {
            // Background - Solid Black to match hardware notch
            Color.black
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: AppConstants.Window.cornerRadius,
                        bottomTrailingRadius: AppConstants.Window.cornerRadius,
                        topTrailingRadius: 0
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: AppConstants.Window.cornerRadius,
                        bottomTrailingRadius: AppConstants.Window.cornerRadius,
                        topTrailingRadius: 0
                    )
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            // Content Container
            if viewModel.isExpanded {
                VStack(spacing: 20) {
                    // 1. Media Player Bölümü (Üst)
                    HStack(spacing: 12) {
                        // Artwork
                        if let artworkData = viewModel.mediaInfo.artworkData, let nsImage = NSImage(data: artworkData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(.white.opacity(0.5))
                                )
                        }

                        // Text Info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.mediaInfo.title.isEmpty ? "Müzik Yok" : viewModel.mediaInfo.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(viewModel.mediaInfo.artist.isEmpty ? "Spotify veya Music Açın" : viewModel.mediaInfo.artist)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Controls
                        HStack(spacing: 16) {
                            Button(action: { viewModel.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { viewModel.togglePlayPause() }) {
                                Image(systemName: viewModel.mediaInfo.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: { viewModel.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)

                    // Ayırıcı Çizgi
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 16)

                    // 2. Quick Actions Bölümü (Alt - Grid)
                    QuickActionsView(viewModel: viewModel)
                }
                .padding(.bottom, 20)
                .padding(.top, 40) // Çentik payı
                .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(
            width: viewModel.isExpanded ? AppConstants.Window.expandedWidth : AppConstants.Window.defaultWidth,
            height: viewModel.isExpanded ? AppConstants.Window.expandedHeight : AppConstants.Window.defaultHeight
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isExpanded)
    }
}

// Yardımcı Buton Görünümü
struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovering ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// Grid Menüsü
struct QuickActionsView: View {
    var viewModel: NotchViewModel

    // Grid items: 4 columns
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            QuickActionButton(icon: "camera.fill", label: "Capture") {
                viewModel.performQuickAction(.screenshot)
            }

            QuickActionButton(icon: "plus.slash.minus", label: "Calc") {
                viewModel.performQuickAction(.calculator)
            }

            QuickActionButton(icon: "gear", label: "Settings") {
                viewModel.performQuickAction(.settings)
            }

            QuickActionButton(icon: "lock.fill", label: "Lock") {
                viewModel.performQuickAction(.lock)
            }
        }
        .padding(.horizontal, 16)
    }
}