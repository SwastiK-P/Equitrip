//
//  MediaStore.swift
//  Equitrip
//

import SwiftUI
import Supabase

/// The two images people upload themselves: a face and a receipt.
///
/// Separate from `CoverStore`, which downloads someone else's photograph and
/// re-hosts it. These start as bytes already on the device — from the photo
/// library or the camera — so there's nothing to fetch first, and they belong
/// to a person or a booking rather than to a trip.
@MainActor
final class MediaStore {
    static let shared = MediaStore()

    /// Buckets must exist and be public. Create them once in the Supabase
    /// dashboard: Storage → New bucket → public.
    static let avatarBucket = "avatars"
    static let receiptBucket = "receipts"

    enum StoreError: LocalizedError {
        case tooLarge
        case bucketMissing(String)
        case uploadFailed(String)

        var errorDescription: String? {
            switch self {
            case .tooLarge:
                "That image is too big. Try a smaller one."
            case .bucketMissing(let name):
                // Named precisely, because the fix is one click in a dashboard
                // and "upload failed" sends people looking for a network fault.
                "Storage isn't set up: create a public \"\(name)\" bucket in Supabase → Storage."
            case .uploadFailed(let message):
                message
            }
        }
    }

    /// Anything above this is a photo nobody needs at full resolution for a
    /// 44-point circle or a receipt thumbnail, and the upload is the slowest
    /// part of picking one.
    private static let maxBytes = 8 * 1024 * 1024

    private func bucket(_ name: String) -> StorageFileApi {
        AuthService.shared.client.storage.from(name)
    }

    /// Stores the signed-in user's profile photograph and hands back the URL
    /// to save on their profile row.
    func uploadAvatar(_ data: Data, for profileID: UUID) async throws -> URL {
        try await upload(data, path: "\(profileID.uuidString).jpg", bucket: Self.avatarBucket)
    }

    /// Stores a payment confirmation against the booking it belongs to.
    func uploadReceipt(_ data: Data, for itemID: UUID) async throws -> URL {
        try await upload(data, path: "\(itemID.uuidString).jpg", bucket: Self.receiptBucket)
    }

    /// Stores proof of a direct settlement — a UPI or transfer screenshot —
    /// against the settlement it backs. Same bucket as a booking receipt: it's
    /// the same kind of object (a photographed confirmation of money having
    /// moved), just attached to a settlement id instead of an item id.
    func uploadSettlementProof(_ data: Data, for settlementID: UUID) async throws -> URL {
        try await upload(data, path: "settlement-\(settlementID.uuidString).jpg", bucket: Self.receiptBucket)
    }

    /// One path per owner, so replacing an image overwrites rather than
    /// accumulating orphans. The cache-busting token is what stops the
    /// replaced file from carrying on being served.
    private func upload(_ data: Data, path: String, bucket name: String) async throws -> URL {
        guard data.count <= Self.maxBytes else { throw StoreError.tooLarge }

        do {
            _ = try await bucket(name).upload(
                path,
                data: data,
                options: FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)
            )

            let publicURL = try bucket(name).getPublicURL(path: path)
            var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [.init(name: "v", value: String(Int(Date().timeIntervalSince1970)))]
            return components?.url ?? publicURL
        } catch {
            if "\(error)".lowercased().contains("bucket not found") {
                throw StoreError.bucketMissing(name)
            }
            throw StoreError.uploadFailed(AuthService.message(for: error))
        }
    }
}

// MARK: - Downscaling

extension UIImage {
    /// JPEG bytes at a sane size for upload.
    ///
    /// A modern phone photo is several thousand pixels wide and a few
    /// megabytes; nothing in this app draws one larger than a card. Resizing
    /// before upload is the difference between a picker that feels instant and
    /// one that spins.
    func jpegForUpload(maxDimension: CGFloat = 1600, quality: CGFloat = 0.8) -> Data? {
        let longest = Swift.max(size.width, size.height)
        guard longest > maxDimension else { return jpegData(compressionQuality: quality) }

        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: target, format: {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            return format
        }())

        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: target)) }
            .jpegData(compressionQuality: quality)
    }
}
