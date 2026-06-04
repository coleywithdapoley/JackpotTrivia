//
//  SupabaseHTTPClient.swift
//  JackpotTrivia
//

import Foundation

enum SupabaseHTTPError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpStatus(Int, String?)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured."
        case .invalidResponse:
            return "Invalid server response."
        case .httpStatus(let code, let message):
            if let message, !message.isEmpty { return "Server error (\(code)): \(message)" }
            return "Server error (\(code))."
        case .decodingFailed:
            return "Could not read server data."
        }
    }
}

struct SupabaseHTTPClient {
    let baseURL: URL
    let anonKey: String
    var urlSession: URLSession = .shared

    init?() {
        guard let url = SupabaseConfig.projectURL,
              let key = SupabaseConfig.anonKey else {
            return nil
        }
        baseURL = url
        anonKey = key
    }

    func get(
        path: String,
        query: [URLQueryItem] = [],
        accessToken: String? = nil
    ) async throws -> Data {
        try await request(method: "GET", path: path, query: query, body: nil, accessToken: accessToken)
    }

    func post(
        path: String,
        body: some Encodable,
        accessToken: String? = nil,
        prefer: String? = nil
    ) async throws -> Data {
        let data = try JSONEncoder().encode(AnyEncodable(body))
        return try await request(method: "POST", path: path, body: data, accessToken: accessToken, prefer: prefer)
    }

    func rpc(
        name: String,
        body: some Encodable,
        accessToken: String? = nil
    ) async throws -> Data {
        try await post(path: "/rest/v1/rpc/\(name)", body: body, accessToken: accessToken)
    }

    private func request(
        method: String,
        path: String,
        query: [URLQueryItem] = [],
        body: Data?,
        accessToken: String? = nil,
        prefer: String? = nil
    ) async throws -> Data {
        let normalized = path.hasPrefix("/") ? path : "/\(path)"
        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(string: "\(base)\(normalized)")
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else {
            throw SupabaseHTTPError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseHTTPError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw SupabaseHTTPError.httpStatus(http.statusCode, message)
        }
        return data
    }
}

/// Type-erased Encodable for generic POST bodies.
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: some Encodable) {
        encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
