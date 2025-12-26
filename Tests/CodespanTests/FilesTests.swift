import XCTest

@testable import Codespan

final class FilesTests: XCTestCase {
    private let testSource = "foo\nbar\r\n\nbaz"

    func testFileRecordLineStarts() throws {
        let file = FileRecord(name: "test", source: testSource)
        XCTAssertEqual(file.lineStarts, [0, 4, 9, 10])
    }

    func testFilesLineStarts() throws {
        let files = Files<String>()
        let fileId = files.add(name: "test", source: testSource)
        XCTAssertEqual(try files.lineStarts(of: fileId), [0, 4, 9, 10])
    }

    func testInteroperabilityPlaceholder() throws {
        let files = Files<String>()
        let fileId = files.add(name: "test", source: testSource)
        let diagnostic = Diagnostic<FileId>.note(
            message: "middle",
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 4..<7,
                    message: "middle"
                )
            ]
        )
        var output = ""
        try emit(
            writer: &output,
            config: .init(),
            styles: .standard,
            styleEmitter: DebugStyleEmitter(),
            files: files,
            diagnostic: diagnostic
        )
    }

    func testLineIndex() throws {
        let lineStarts: [UInt] = [0, 4, 9, 10]

        XCTAssertEqual(lineIndex(lineStarts: lineStarts, byteIndex: 0), 0)
        XCTAssertEqual(lineIndex(lineStarts: lineStarts, byteIndex: 2), 0)
        XCTAssertEqual(lineIndex(lineStarts: lineStarts, byteIndex: 4), 1)
        XCTAssertEqual(lineIndex(lineStarts: lineStarts, byteIndex: 6), 1)
        XCTAssertEqual(lineIndex(lineStarts: lineStarts, byteIndex: 9), 2)
        XCTAssertEqual(lineIndex(lineStarts: lineStarts, byteIndex: 10), 3)
        XCTAssertEqual(lineIndex(lineStarts: lineStarts, byteIndex: 12), 3)
    }

    func testColumnIndex() throws {
        let source = "\n\n🗻∈🌏\n\n";

        XCTAssertEqual(columnIndex(in: source, lineRange: 0..<1, byteIndex: 0), 0)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 0), 0)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 0), 0)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 1), 0)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 4), 1)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 8), 2)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 10), 2)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 11), 3)
        XCTAssertEqual(columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 12), 3)
    }
}
