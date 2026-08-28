//
//  CoverStore.swift
//  Equitrip
//

import SwiftUI
import Supabase

/// Trip cover images, stored once and reused.
///
/// A cover used to be re-resolved from the photo API on every appearance,
/// which meant a network round trip per card, a different photograph whenever
/// the search results shifted, and nothing at all offline. Now the bytes are
/// uploaded to Supabase Storage the first time a cover is chosen and every
/// device on the trip reads that same file — so the group all see the same
/// picture, and it keeps working without the photo provider.
@MainActor
@Observable
final class CoverStore {
    static let shared = CoverStore()

    /// Bucket must exist and be public. Create it once in the Supabase
    /// dashboard: Storage → New bucket → "trip-covers" → Public.
    static let bucket = "trip-covers"

    private var uploading: Set<UUID> = []
    private let session = URLSession(configuration: .default)

    private var storage: StorageFileApi {
        AuthService.shared.client.storage.from(Self.bucket)
    }

    /// Downloads a resolved photo and parks it in storage under the trip's id,
    /// returning the durable public URL. Falls back to the original URL when
    /// storage isn't reachable, so a missing bucket degrades rather than
    /// breaking the trip.
    func persist(_ photo: TripPhoto, for tripID: UUID) async -> TripPhoto {
        guard !uploading.contains(tripID) else { return photo }
        uploading.insert(tripID)
        defer { uploading.remove(tripID) }

        do {
            let (data, response) = try await session.data(from: photo.url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return photo }
            return try await upload(data, for: tripID, contentType: "image/jpeg") ?? photo
        } catch {
            return photo
        }
    }

    /// Stores an image the user picked themselves.
    func persist(imageData: Data, for tripID: UUID) async -> TripPhoto? {
        guard !uploading.contains(tripID) else { return nil }
        uploading.insert(tripID)
        defer { uploading.remove(tripID) }

        return try? await upload(imageData, for: tripID, contentType: "image/jpeg")
    }

    private func upload(_ data: Data, for tripID: UUID, contentType: String) async throws -> TripPhoto? {
        // Same path per trip so replacing a cover doesn't leak orphaned files;
        // the cache-busting token below keeps a replaced image from sticking.
        let path = "\(tripID.uuidString).jpg"

        _ = try await storage.upload(
            path,
            data: data,
            options: FileOptions(cacheControl: "3600", contentType: contentType, upsert: true)
        )

        let publicURL = try storage.getPublicURL(path: path)
        var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [.init(name: "v", value: String(Int(Date().timeIntervalSince1970)))]

        guard let url = components?.url ?? Optional(publicURL) else { return nil }
        return TripPhoto(url: url, thumbURL: url, photographer: "", photographerURL: nil, sourceName: "")
    }
}
