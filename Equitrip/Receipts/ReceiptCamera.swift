//
//  ReceiptCamera.swift
//  Equitrip
//

import SwiftUI
import VisionKit

/// The system document camera, pointed at a receipt.
///
/// VisionKit's rather than a camera of our own because it already does the
/// part that decides whether a receipt reads at all: it finds the paper's
/// edges live, waits for the phone to be steady, captures on its own, and
/// flattens the perspective. It also takes several pages, which is how a
/// receipt longer than the screen gets scanned — two or three overlapping
/// shots that `ReceiptLayout.stitch` joins back together.
struct ReceiptCamera: UIViewControllerRepresentable {
    var onFinish: ([UIImage]) -> Void
    var onCancel: () -> Void

    static var isAvailable: Bool { VNDocumentCameraViewController.isSupported }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: ([UIImage]) -> Void
        let onCancel: () -> Void

        init(onFinish: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let pages = (0..<scan.pageCount).prefix(6).map { scan.imageOfPage(at: $0) }
            if pages.isEmpty {
                onCancel()
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onFinish(pages)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCancel()
        }
    }
}
