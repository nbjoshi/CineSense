//
//  AiResultsViewModel.swift
//  CineSense
//
//  Created by Claude Code on 1/3/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AiResultsViewModel: ObservableObject {
    @Published var candidates: [ResolvedCandidate] = []
    @Published var isResolving = false

    private let response: AiIdentifyResponse
    private let imagePath: String
    private let textHint: String?
    private let resolutionService: MediaResolutionService
    private let cache: AICandidatesCache
    private var resolutionTask: Task<Void, Never>?

    init(
        response: AiIdentifyResponse,
        imagePath: String,
        textHint: String?,
        resolutionService: MediaResolutionService = MediaResolutionService(),
        cache: AICandidatesCache = .shared
    ) {
        self.response = response
        self.imagePath = imagePath
        self.textHint = textHint
        self.resolutionService = resolutionService
        self.cache = cache

        // Check cache first
        if let cached = cache.get(imagePath: imagePath, textHint: textHint) {
            self.candidates = cached.candidates
            self.isResolving = false
        } else {
            // Initialize with pending candidates
            self.candidates = response.candidates.map { ResolvedCandidate(from: $0) }
            self.isResolving = true
            // Start resolution
            startResolution()
        }
    }

    deinit {
        resolutionTask?.cancel()
    }

    // MARK: - Resolution

    private func startResolution() {
        resolutionTask?.cancel()

        resolutionTask = Task {
            await resolveAllCandidates()
        }
    }

    private func resolveAllCandidates() async {
        // Set all to resolving state
        for index in candidates.indices {
            candidates[index].state = .resolving
        }

        await withTaskGroup(of: (Int, ResolutionResult).self) { group in
            // Launch resolution for each candidate
            for (index, candidate) in candidates.enumerated() {
                group.addTask {
                    let result = await self.resolutionService.resolve(
                        title: candidate.original.title,
                        type: candidate.original.type,
                        year: candidate.original.year
                    )
                    return (index, result)
                }
            }

            // Collect results as they complete
            for await (index, result) in group {
                guard index < candidates.count else { continue }

                switch result {
                case let .resolved(media):
                    candidates[index].state = .resolved(media)

                case let .ambiguous(matches):
                    candidates[index].state = .ambiguous(matches)

                case let .failed(error):
                    candidates[index].state = .failed(error)
                }
            }
        }

        isResolving = false

        // Cache the resolved candidates
        cache.set(
            imagePath: imagePath,
            textHint: textHint,
            response: response,
            candidates: candidates
        )
    }

    // MARK: - Candidate Selection

    func resolveAmbiguity(for candidateId: UUID, selectedMatch: TMDBMatch) {
        guard let index = candidates.firstIndex(where: { $0.id == candidateId }) else {
            return
        }

        // Update candidate state to resolved with selected match
        candidates[index].state = .resolved(selectedMatch.toResolvedMedia())

        // Update cache
        cache.set(
            imagePath: imagePath,
            textHint: textHint,
            response: response,
            candidates: candidates
        )
    }
}
