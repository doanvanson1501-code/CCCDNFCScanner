import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CitizenStore
    @StateObject private var nfc = NFCReader()
    @State private var showingAdd = false
    @State private var exportURL: URL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("CCCDNFCScanner", systemImage: "wave.3.right")
                            .font(.title2.bold())
                        Text("Quản lý hồ sơ CCCD và xuất Excel trên iPhone.")
                            .foregroundStyle(.secondary)
                        Button {
                            nfc.begin()
                        } label: {
                            Label("Bắt đầu quét NFC", systemImage: "wave.3.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(nfc.isScanning)
                        Text(nfc.status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Danh sách hồ sơ · \(store.citizens.count)") {
                    if store.citizens.isEmpty {
                        ContentUnavailableView("Chưa có hồ sơ", systemImage: "person.text.rectangle",
                                               description: Text("Nhấn dấu + để thêm hồ sơ thử nghiệm."))
                    } else {
                        ForEach(store.citizens) { person in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(person.fullName).font(.headline)
                                Text("\(person.idNumber) · \(person.dateOfBirth)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                }

                Section {
                    Button {
                        do {
                            exportURL = try XLSXExporter.makeFile(citizens: store.citizens)
                        } catch {
                            exportError = error.localizedDescription
                        }
                    } label: {
                        Label("Xuất Excel (.xlsx)", systemImage: "tablecells")
                    }
                    .disabled(store.citizens.isEmpty)
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Chia sẻ / lưu file Excel", systemImage: "square.and.arrow.up")
                        }
                    }
                } footer: {
                    Text("Bản thử nghiệm: dữ liệu được lưu cục bộ trong ứng dụng. Không nhập CCCD thật cho đến khi hoàn thiện bảo mật và quy trình đọc chip.")
                }
            }
            .navigationTitle("CCCDNFCScanner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddCitizenView()
                    .environmentObject(store)
            }
            .alert("Thông báo", isPresented: Binding(
                get: { store.errorMessage != nil || exportError != nil },
                set: { if !$0 { store.errorMessage = nil; exportError = nil } }
            )) {
                Button("Đóng", role: .cancel) { store.errorMessage = nil; exportError = nil }
            } message: {
                Text(store.errorMessage ?? exportError ?? "")
            }
        }
    }
}

struct AddCitizenView: View {
    @EnvironmentObject private var store: CitizenStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var dob = ""
    @State private var gender = ""
    @State private var number = ""
    @State private var address = ""
    @State private var issue = ""
    @State private var expiry = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Họ và tên", text: $name)
                TextField("Ngày sinh (dd/mm/yyyy)", text: $dob)
                TextField("Giới tính", text: $gender)
                TextField("Số định danh (12 chữ số)", text: $number)
                    .keyboardType(.numberPad)
                TextField("Địa chỉ", text: $address)
                TextField("Ngày cấp", text: $issue)
                TextField("Ngày hết hạn", text: $expiry)
            }
            .navigationTitle("Thêm hồ sơ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        store.add(Citizen(fullName: name, dateOfBirth: dob, gender: gender,
                                          idNumber: number, address: address,
                                          issueDate: issue, expiryDate: expiry))
                        if store.errorMessage == nil { dismiss() }
                    }
                    .disabled(name.isEmpty || number.isEmpty)
                }
            }
        }
    }
}
