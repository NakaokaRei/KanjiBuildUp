import Foundation

struct LearningError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
