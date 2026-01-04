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

    // Cache for persistence across sheet presentations
    private var cachedResponse: AiIdentifyResponse?
    private var cachedImage: UIImage?

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
        state = .uploadingImage

        do {
            let data: Data
            let contentType: String

            // Support both PhotosPicker and camera images
            if let selectedPhoto {
                // Load image data from PhotosPickerItem
                guard let photoData = try await selectedPhoto.loadTransferable(type: Data.self) else {
                    throw AIServiceError.uploadFailed
                }
                data = photoData

                // Determine content type (default to JPEG)
                if let mimeType = selectedPhoto.supportedContentTypes.first?.preferredMIMEType {
                    contentType = mimeType
                } else {
                    contentType = "image/jpeg"
                }
            } else if let selectedImage {
                // Encode camera image to JPEG data
                guard let jpegData = selectedImage.jpegData(compressionQuality: 0.9) else {
                    throw AIServiceError.uploadFailed
                }
                data = jpegData
                contentType = "image/jpeg"
            } else {
                throw AIServiceError.uploadFailed
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

            // Cache the results
            cachedResponse = result
            cachedImage = selectedImage

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
        selectedImage = nil
        textHint = ""
        cachedResponse = nil
        cachedImage = nil
    }

    func resetTransientUI() {
        identifyTask?.cancel()
        selectedPhoto = nil
        selectedImage = nil
        textHint = ""
        // Keep cachedResponse and cachedImage for restoration
    }

    func restoreCachedResultsIfAvailable() {
        if let cachedResponse {
            state = .loaded(cachedResponse)
        }
    }

    func startNewSearch() {
        cachedResponse = nil
        cachedImage = nil
        selectedPhoto = nil
        selectedImage = nil
        textHint = ""
        state = .idle
    }

    func retry() {
        identifyTask?.cancel()
        if let photo = selectedPhoto {
            identifyTask = Task {
                await selectPhoto(photo)
            }
        } else if let image = selectedImage {
            state = .imageSelected(image)
        }
    }
}

extension AiViewModel {
    @MainActor
    func selectCameraImage(_ image: UIImage) {
        self.selectedImage = image
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
