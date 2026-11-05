import Foundation
import SwiftUI

@MainActor
final class CitizenStore: ObservableObject {
    @Published private(set) var citizens: [Citizen] = []
    @Published var errorMessage: String?

    private let filename = "citizens.json"

    init() {
        load()
    }

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }

    func add(_ citizen: Citizen) {
        let number = citizen.idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard number.count == 12, number.allSatisfy(\.isNumber) else {
            errorMessage = "Số định danh phải gồm đúng 12 chữ số."
            return
        }
        guard !citizens.contains(where: { $0.idNumber == number }) else {
            errorMessage = "Số định danh này đã có trong danh sách."
            return
        }
        var newCitizen = citizen
        newCitizen.idNumber = number
        citizens.insert(newCitizen, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        citizens.remove(atOffsets: offsets)
        save()
    }

    func deleteAll() {
        citizens.removeAll()
        save()
    }

    private func load() {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            let data = try Data(contentsOf: fileURL)
            citizens = try JSONDecoder().decode([Citizen].self, from: data)
        } catch {
            errorMessage = "Không đọc được dữ liệu đã lưu: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(citizens)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            errorMessage = "Không lưu được dữ liệu: \(error.localizedDescription)"
        }
    }
}
