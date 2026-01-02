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
        case uploadingImage
        case identifying
        case loaded(AiIdentifyResponse)
        case failed(Error)
    }

    @Published var state: State = .idle
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var textHint: String = ""

    private let aiService: AIService
    private var identifyTask: Task<Void, Never>?

    init(aiService: AIService = AIService()) {
        self.aiService = aiService
    }

    func selectPhoto(_ item: PhotosPickerItem?) async {
        selectedPhoto = item
        guard let item else { return }

        state = .uploadingImage

        do {
            // Load image data from PhotosPickerItem
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw AIServiceError.uploadFailed
            }

            // Determine content type (default to JPEG)
            let contentType: String
            if let mimeType = item.supportedContentTypes.first?.preferredMIMEType {
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
