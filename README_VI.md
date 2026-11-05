# CCCDNFCScanner — mã nguồn thử nghiệm

## Có gì trong bản này?
- Giao diện SwiftUI.
- Thêm hồ sơ thủ công, kiểm tra số định danh 12 chữ số và trùng số.
- Lưu dữ liệu JSON trong thư mục Documents của ứng dụng.
- Xuất tệp Excel `.xlsx` bằng ZIPFoundation.
- Mở phiên Core NFC ISO 14443 và nhận diện loại thẻ ISO 7816 nếu iPhone phát hiện được.

## Giới hạn rất quan trọng
Bản này **chưa đọc dữ liệu cá nhân từ chip CCCD**. Nó chỉ thử mở phiên NFC và xác nhận thẻ ISO 7816. Không có AID, APDU, khóa hay quy trình xác thực CCCD trong dự án này. Không tự ý thêm AID hoặc gửi APDU đoán mò. Muốn đọc dữ liệu thật cần tài liệu/giao thức và quyền truy cập hợp lệ.

## Build bằng GitHub Actions
1. Tạo repository GitHub mới, ví dụ `CCCDNFCScanner`.
2. Giải nén ZIP này trên Windows. Dự án dùng `project.yml`; GitHub Actions cài XcodeGen để tạo Xcode project.
3. Upload toàn bộ nội dung thư mục lên repository, giữ nguyên `.github/workflows/ios-build.yml`.
4. Commit lên nhánh `main`.
5. Mở tab **Actions** → workflow **Build CCCDNFCScanner iOS** → **Run workflow**.
6. Khi chạy thành công, mở lần chạy đó và tải artifact `CCCDNFCScanner-iOS-Simulator-Build`.

Artifact này là bản build cho **iOS Simulator**, không phải IPA cài trực tiếp lên iPhone.

## Cài lên iPhone
Muốn cài bản native lên iPhone cần ký bằng chứng chỉ/provisioning profile hợp lệ. GitHub Actions không tự cấp quyền ký iOS cho Apple ID. Apple Developer Program trả phí thường là cách ổn định để ký phân phối; ký miễn phí cần quy trình Xcode/Personal Team và provisioning giới hạn, thường phải có Mac/Xcode và ghép thiết bị. Vì bạn không có Mac, không thể cam kết cài trực tiếp bản native bằng tài khoản miễn phí chỉ với workflow này.

## Bảo mật
- Chỉ dùng dữ liệu giả khi thử nghiệm.
- Dữ liệu định danh là dữ liệu cá nhân nhạy cảm; trước khi dùng thật cần mã hóa dữ liệu, khóa ứng dụng, kiểm soát truy cập, sao lưu và quy trình xóa dữ liệu.
- JSON cục bộ trong bản mẫu chưa phải kho lưu trữ bảo mật hoàn chỉnh.

## Lưu ý cấu hình NFC
Ứng dụng iOS cần entitlement NFC phù hợp và danh sách AID ISO 7816 được Apple cho phép trong cấu hình ứng dụng. Danh sách AID CCCD không được đoán hoặc tự bịa. Khi có tài liệu tích hợp hợp lệ, cập nhật `Package.swift`/entitlements và phần NFC theo tài liệu đó.
