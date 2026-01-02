//
//  AI.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation

struct AiIdentifyResponse: Codable {
    let querySummary: String
    let candidates: [Candidate]
    let provider: String?
    let model: String?
    let latencyMs: Int?

    enum CodingKeys: String, CodingKey {
        case querySummary = "query_summary"
        case candidates
        case provider
        case model
        case latencyMs = "latency_ms"
    }
}

struct Candidate: Codable, Identifiable {
    let id: UUID = .init()
    let title: String
    let type: MediaType
    let year: String
    let confidence: Double
    let rationale: String

    enum CodingKeys: String, CodingKey {
        case title, type, year, confidence, rationale
    }
}

struct AiURLResponse: Codable {
    let uploadURL: String
    let path: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case path
        case expiresIn = "expires_in"
    }
}
