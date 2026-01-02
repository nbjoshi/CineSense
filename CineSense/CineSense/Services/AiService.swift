//
//  AiService.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation
import Supabase

enum AIServiceError: LocalizedError {
    case invalidContentType
    case uploadFailed
    case invalidImagePath
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidContentType:
            return "Content type must be image/jpeg, image/png, or image/webp"
        case .uploadFailed:
            return "Failed to upload image to storage"
        case .invalidImagePath:
            return "Invalid image path provided"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

class AIService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func getSignedUploadURL(contentType: String) async throws -> AiURLResponse {
        // Validate content type matches edge function schema
        guard ["image/jpeg", "image/png", "image/webp"].contains(contentType) else {
            throw AIServiceError.invalidContentType
        }

        struct UploadURLRequest: Encodable {
            let content_type: String
        }

        let requestBody = UploadURLRequest(content_type: contentType)

        // Use the Supabase SDK's invoke method - it should automatically include auth
        let response: AiURLResponse = try await client.functions.invoke(
            "ai_upload_url",
            options: FunctionInvokeOptions(body: requestBody)
        )

        return response
    }

    func identifyImage(imagePath: String, textHint: String?) async throws -> AiIdentifyResponse {
        guard !imagePath.isEmpty else {
            throw AIServiceError.invalidImagePath
        }

        struct IdentifyRequest: Encodable {
            let image_path: String
            let text_hint: String?
        }

        let requestBody = IdentifyRequest(
            image_path: imagePath,
            text_hint: textHint?.isEmpty == true ? nil : textHint
        )

        // Use the Supabase SDK's invoke method - it should automatically include auth
        let response: AiIdentifyResponse = try await client.functions.invoke(
            "ai_identify",
            options: FunctionInvokeOptions(body: requestBody)
        )

        return response
    }

    func uploadImageToSignedURL(imageData: Data, contentType: String) async throws -> AiURLResponse {
        // 1) Get signed URL + storage path
        let signed = try await getSignedUploadURL(contentType: contentType)

        // 2) Upload bytes to signed URL
        guard let url = URL(string: signed.uploadURL) else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.httpBody = imageData

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw AIServiceError.uploadFailed
        }

        return signed
    }
}
