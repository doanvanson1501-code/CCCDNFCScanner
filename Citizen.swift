import Foundation

struct Citizen: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var fullName: String
    var dateOfBirth: String
    var gender: String
    var idNumber: String
    var address: String
    var issueDate: String
    var expiryDate: String
    var createdAt: Date = Date()
}
