//
//  HTTPClient.swift
//  CineSense
//
//  Created by Neel Joshi on 1/1/26.
//

import Foundation

enum HTTPMethod {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case server(status: Int, body: String?)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .transport:
            return "Network error. Please try again."
        case let .server(status, _):
            return "Server error (\(status))."
        case .decoding:
            return "Failed to read server response."
        }
    }
}

struct APIRequest {
    var method: HTTPMethod = .GET
    var path: String
    var query: [String: String] = [:]
    var headers: [String: String] = [:]
    var body: Data? = nil
}

final class HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let defaultHeaders: [String: String]

    init(baseURL: URL, session: URLSession = .shared, defaultHeaders: [String: String] = [:]) {
        self.baseURL = baseURL
        self.session = session
        self.defaultHeaders = defaultHeaders
    }

    func send<T: Decodable>(_ req: APIRequest, as _: T.Type = T.self) async throws -> T {
        let request = try buildURLRequest(req)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(status: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIError.server(status: http.statusCode, body: body)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func sendNoResponse(_ req: APIRequest) async throws {
        let request = try buildURLRequest(req)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(status: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIError.server(status: http.statusCode, body: body)
        }
    }

    private func buildURLRequest(_ req: APIRequest) throws -> URLRequest {
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(req.path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !req.query.isEmpty {
            comps.queryItems = req.query.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        guard let url = comps.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = String(describing: req.method)
        request.httpBody = req.body

        // Headers
        let headers = defaultHeaders.merging(req.headers) { _, new in new }
        for (k, v) in headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        if req.body != nil && request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
