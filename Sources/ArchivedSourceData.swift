import Foundation

// Retain saved source references and receipts so existing tasks remain readable.
// There is no account access or integration behaviour attached to these values.
struct FlowSourceReference: Codable, Identifiable, Equatable {
    var id: String
    var service: String
    var title: String
    var url: String?
    var captureSourceID: UUID?
}
struct ConnectedRecord: Codable, Identifiable {
    var id: String
    var service: String
    var title: String
    var text: String
    var url: String?
    var date: Date?
    var captureID: UUID?
    var suggestedTaskID: UUID?
    var confidence: Double?
}
struct ExternalChangeReceipt: Codable, Identifiable {
    var id = UUID()
    var title: String
    var kind: String
    var externalID: String?
    var created = Date()
}
