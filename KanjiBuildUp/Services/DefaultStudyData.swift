import Foundation

struct DefaultStudyData: Codable {
    let version: String
    let items: [StudyItem]
    var replacesVersion: String? = nil
    var previousItems: [StudyItem]? = nil
    var replacementAdditionIDs: [UUID]? = nil
    var deduplicateByQuestion: Bool? = nil

    static func loadAll() throws -> [DefaultStudyData] {
        try ["DefaultStudyData", "YojiKakiStudyData", "KojikotoStudyData", "OnyomiStudyData", "OnyomiContinuationStudyData", "OmidashiStudyData", "Omidashi2StudyData", "OnkunStudyData", "RongoKunyomiStudyData", "ShikyoKunyomiStudyData", "TajigoStudyData", "SentenceNibanStudyData", "SentenceKunyomiStudyData", "ReadingTablesStudyData"].map { try load(resource: $0) }
    }

    static func load(resource: String = "DefaultStudyData") throws -> DefaultStudyData {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json")
            ?? Bundle.main.url(forResource: resource, withExtension: "json", subdirectory: "Resources") else {
            throw LearningError(message: "初期問題データ「\(resource).json」がアプリ内に見つかりません。")
        }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}
