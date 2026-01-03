//
//  AiViewModel.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Combine
import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class AiViewModel: ObservableObject {
    enum State {
        case idle
        case selectingImage
        case imageSelected(UIImage) // New state to show image before identifying
        case uploadingImage
        case identifying
        case loaded(AiIdentifyResponse)
        case failed(Error)
    }

    @Published var state: State = .idle
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var textHint: String = ""

    private let aiService: AIService
    private var identifyTask: Task<Void, Never>?

    init(aiService: AIService = AIService()) {
        self.aiService = aiService
    }

    func selectPhoto(_ item: PhotosPickerItem?) async {
        selectedPhoto = item
        guard let item else { return }

        do {
            // Load image data to show preview
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw AIServiceError.uploadFailed
            }

            selectedImage = image
            state = .imageSelected(image)
        } catch {
            state = .failed(error)
        }
    }

    func identifySelectedImage() async {
        guard let selectedPhoto else { return }

        state = .uploadingImage

        do {
            // Load image data from PhotosPickerItem
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                throw AIServiceError.uploadFailed
            }

            // Determine content type (default to JPEG)
            let contentType: String
            if let mimeType = selectedPhoto.supportedContentTypes.first?.preferredMIMEType {
                contentType = mimeType
            } else {
                contentType = "image/jpeg"
            }

            // Upload to signed URL
            state = .identifying
            let uploadResult = try await aiService.uploadImageToSignedURL(
                imageData: data,
                contentType: contentType
            )

            // Identify the image
            let result = try await aiService.identifyImage(
                imagePath: uploadResult.path,
                textHint: textHint.isEmpty ? nil : textHint
            )

            state = .loaded(result)
        } catch {
            state = .failed(error)
        }
    }

    func clearImage() {
        selectedPhoto = nil
        selectedImage = nil
        state = .idle
    }

    func reset() {
        identifyTask?.cancel()
        state = .idle
        selectedPhoto = nil
        textHint = ""
    }

    func retry() {
        identifyTask?.cancel()
        if let photo = selectedPhoto {
            identifyTask = Task {
                await selectPhoto(photo)
            }
        }
    }
}

extension AiViewModel {
    @MainActor
    func selectCameraImage(_ image: UIImage) {
        self.state = .imageSelected(image)
    }
}

private extension AiViewModel {
    var stateIsPreviewLike: Bool {
        switch state {
        case .imageSelected, .uploadingImage, .identifying, .loaded, .failed:
            return true
        case .idle, .selectingImage:
            return false
        }
    }
}
