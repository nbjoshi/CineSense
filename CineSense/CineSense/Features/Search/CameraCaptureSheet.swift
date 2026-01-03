//
//  CameraCaptureSheet.swift
//  CineSense
//
//  Created by Neel Joshi on 1/3/26.
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraCaptureSheet: View {
    @Binding var isPresented: Bool
    let onImageCaptured: (UIImage) -> Void

    @State private var permissionState: PermissionState = .checking
    @State private var cameraAvailable: Bool = UIImagePickerController.isSourceTypeAvailable(.camera)

    enum PermissionState { case checking, authorized, denied }

    var body: some View {
        Group {
            if !cameraAvailable {
                ContentUnavailableView(
                    "Camera Not Available",
                    systemImage: "camera.fill",
                    description: Text("This device doesn’t support the camera (or you’re on Simulator).")
                )
                .padding()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { isPresented = false }
                    }
                }
            } else {
                switch permissionState {
                case .checking:
                    ProgressView("Opening camera...")
                        .onAppear(perform: checkCameraPermission)

                case .authorized:
                    CameraPicker(isPresented: $isPresented) { image in
                        onImageCaptured(image)
                    }

                case .denied:
                    ContentUnavailableView(
                        "Camera Access Needed",
                        systemImage: "camera.fill",
                        description: Text("Enable camera access in Settings to take a picture.")
                    )
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { isPresented = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Open Settings") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            }
        }
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            permissionState = .authorized
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    permissionState = granted ? .authorized : .denied
                }
            }
        default:
            permissionState = .denied
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var isPresented: Bool
        let onImagePicked: (UIImage) -> Void

        init(isPresented: Binding<Bool>, onImagePicked: @escaping (UIImage) -> Void) {
            _isPresented = isPresented
            self.onImagePicked = onImagePicked
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // IMPORTANT: do NOT call picker.dismiss(...) here.
            isPresented = false
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            // IMPORTANT: do NOT call picker.dismiss(...) here.
            isPresented = false
        }
    }
}
