
import Foundation
// MARK: - API Error

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Your session has expired. Please sign in again."
        case .notFound: return "The requested resource was not found."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .decodingError: return "Failed to parse server response."
        case .networkError(let e): return e.localizedDescription
        case .unknown(let msg): return msg
        }
    }
}

// MARK: - API Wrappers

struct APIListResponse<T: Codable>: Codable {
    let data: [T]?
    let items: [T]?
    let error: String?

    var results: [T] { data ?? items ?? [] }
}

struct APISingleResponse<T: Codable>: Codable {
    let data: T?
    let error: String?
}
