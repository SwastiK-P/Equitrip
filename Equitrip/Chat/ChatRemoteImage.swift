//
//  ChatRemoteImage.swift
//  Equitrip
//

import SwiftUI

/// A photo from the thread, loaded once and kept for the session.
///
/// Not `AsyncImage`. Inside the thread's `LazyVStack`, a row laid out and torn
/// down while the list settles on its bottom anchor cancels the load, and
/// `AsyncImage` reports that cancellation as `.failure` and never tries again —
/// so a photo that was perfectly reachable sat on screen as a broken-image
/// glyph. This restarts on every appearance, treats cancellation as "not yet",
/// and caches the decoded image so scrolling back doesn't refetch it.
struct ChatRemoteImage: View {
    let url: URL

    @State private var image: UIImage?
    @State private var failed = false

    private static let cache = NSCache<NSURL, UIImage>()

    var body: some View {
        ZStack {
            if let image = image ?? Self.cache.object(forKey: url as NSURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                AppTheme.card
                if failed {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(AppTheme.inkTertiary)
                } else {
                    ProgressView().tint(AppTheme.inkTertiary)
                }
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        if let cached = Self.cache.object(forKey: url as NSURL) {
            image = cached
            return
        }
        failed = false

        // Two tries: a photo sent seconds ago can be a beat behind on the
        // storage CDN, and the first request is the one that finds out.
        for attempt in 0..<2 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true,
                      let decoded = UIImage(data: data)
                else { throw URLError(.cannotDecodeContentData) }

                Self.cache.setObject(decoded, forKey: url as NSURL)
                withAnimation(.easeOut(duration: 0.2)) { image = decoded }
                return
            } catch {
                // Scrolled away: the next appearance starts a fresh load.
                if Task.isCancelled || (error as? URLError)?.code == .cancelled { return }
                if attempt == 0 { try? await Task.sleep(for: .milliseconds(800)) }
            }
        }
        failed = true
    }
}
