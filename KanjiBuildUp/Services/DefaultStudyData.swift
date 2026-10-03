import Foundation

struct DefaultStudyData: Codable {
    let version: String
    let items: [StudyItem]

    static func load() throws -> DefaultStudyData {
        guard let url = Bundle.main.url(forResource: "DefaultStudyData", withExtension: "json") else {
            throw LearningError(message: "初期問題データが見つかりません。")
        }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}
