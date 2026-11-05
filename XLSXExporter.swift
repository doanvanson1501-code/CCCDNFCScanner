import Foundation
import ZIPFoundation

enum XLSXExporter {
    static func makeFile(citizens: [Citizen]) throws -> URL {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("DanhSachCCCD-\(Int(Date().timeIntervalSince1970)).xlsx")
        let fm = FileManager.default
        if fm.fileExists(atPath: temp.path) { try fm.removeItem(at: temp) }
        guard let archive = Archive(url: temp, accessMode: .create) else {
            throw NSError(domain: "XLSX", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không tạo được tệp Excel."])
        }

        let entries: [(String, String)] = [
            ("[Content_Types].xml", contentTypes),
            ("_rels/.rels", rootRels),
            ("xl/workbook.xml", workbook),
            ("xl/_rels/workbook.xml.rels", workbookRels),
            ("xl/worksheets/sheet1.xml", sheetXML(citizens: citizens))
        ]

        for (path, content) in entries {
            let data = Data(content.utf8)
            try archive.addEntry(
                with: path,
                type: .file,
                uncompressedSize: UInt32(data.count),
                compressionMethod: .deflate,
                provider: { position, size in
                    let start = Int(position)
                    let end = min(start + size, data.count)
                    return data.subdata(in: start..<end)
                }
            )
        }
        return temp
    }

    private static func xml(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func cell(_ value: String, column: String, row: Int) -> String {
        "<c r=\"\(column)\(row)\" t=\"inlineStr\"><is><t>\(xml(value))</t></is></c>"
    }

    private static func sheetXML(citizens: [Citizen]) -> String {
        let headers = ["STT", "HỌ VÀ TÊN", "NGÀY SINH", "GIỚI TÍNH", "SỐ ĐỊNH DANH", "ĐỊA CHỈ", "NGÀY CẤP", "NGÀY HẾT HẠN"]
        let columns = ["A", "B", "C", "D", "E", "F", "G", "H"]
        var rows = "<row r=\"1\">" + zip(headers, columns).map { cell($0.0, column: $0.1, row: 1) }.joined() + "</row>"
        for (index, person) in citizens.enumerated() {
            let row = index + 2
            let values = [
                String(index + 1), person.fullName, person.dateOfBirth, person.gender,
                person.idNumber, person.address, person.issueDate, person.expiryDate
            ]
            rows += "<row r=\"\(row)\">" + zip(values, columns).map { cell($0.0, column: $0.1, row: row) }.joined() + "</row>"
        }
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>\(rows)</sheetData>
        </worksheet>
        """
    }

    private static let contentTypes = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml" ContentType="application/xml"/>
      <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
      <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
    </Types>
    """
    private static let rootRels = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
    </Relationships>
    """
    private static let workbook = """
    <?xml version="1.0" encoding="UTF-8"?>
    <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
      <sheets><sheet name="Danh sach CCCD" sheetId="1" r:id="rId1"/></sheets>
    </workbook>
    """
    private static let workbookRels = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
    </Relationships>
    """
}
