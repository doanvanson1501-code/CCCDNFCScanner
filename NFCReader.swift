import Foundation
import Combine
import CoreNFC

@MainActor
final class NFCReader: NSObject, ObservableObject {
    @Published var status = "Chưa bắt đầu quét NFC"
    @Published var isScanning = false

    private var session: NFCTagReaderSession?

    func begin() {
        guard NFCTagReaderSession.readingAvailable else {
            status = "Thiết bị hoặc cấu hình hiện tại không hỗ trợ đọc NFC."
            return
        }
        status = "Đưa mặt sau iPhone lại gần chip NFC trên CCCD."
        isScanning = true
        let newSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
        newSession.alertMessage = "Giữ iPhone gần CCCD, không di chuyển trong lúc quét."
        session = newSession
        newSession.begin()
    }
}

extension NFCReader: NFCTagReaderSessionDelegate {
    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Task { @MainActor in
            self.status = "Đang tìm chip NFC…"
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.isScanning = false
            if let nfcError = error as? NFCReaderError,
               nfcError.code == .readerSessionInvalidationErrorUserCanceled {
                self.status = "Bạn đã hủy phiên quét."
            } else {
                self.status = "Phiên NFC kết thúc: \(error.localizedDescription)"
            }
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: "Không kết nối được với chip: \(error.localizedDescription)")
                return
            }

            switch tag {
            case .iso7816(let isoTag):
                // Chỉ xác nhận đã nhận diện được giao tiếp ISO 7816.
                // Không gửi APDU, không đọc/giải mã dữ liệu CCCD.
                let aidInfo = isoTag.initialSelectedAID ?? "Chưa có AID được chọn"
                session.alertMessage = "Đã nhận diện thẻ ISO 7816. Chưa đọc dữ liệu CCCD."
                session.invalidate()
                Task { @MainActor in
                    self.status = """
                    Đã kết nối thẻ ISO 7816.
                    AID ban đầu: \(aidInfo)
                    Đây chưa phải kết quả đọc CCCD. Cần AID, quy trình xác thực và giao thức được cấp phép.
                    """
                    self.isScanning = false
                }
            default:
                session.invalidate(errorMessage: "Đã thấy thẻ NFC nhưng không phải thẻ ISO 7816 phù hợp.")
                Task { @MainActor in
                    self.status = "Thẻ được phát hiện nhưng không thuộc loại ISO 7816."
                    self.isScanning = false
                }
            }
        }
    }
}
