import Testing

@testable import Codespan

@Suite
struct FilesTests {
    private let testSource = "foo\nbar\r\n\nbaz"

    @Test
    func fileRecordLineStarts() throws {
        let file = FileRecord(name: "test", source: testSource)
        #expect(file.lineStarts == [0, 4, 9, 10])
    }

    @Test
    func filesLineStarts() throws {
        var files = Files<String>()
        let fileId = files.add(name: "test", source: testSource)
        #expect(try files.lineStarts(of: fileId) == [0, 4, 9, 10])
    }

    @Test
    func interoperabilityPlaceholder() throws {
        var files = Files<String>()
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

    @Test
    func lineIndex() {
        let lineStarts: [UInt] = [0, 4, 9, 10]

        #expect(Codespan.lineIndex(lineStarts: lineStarts, byteIndex: 0) == 0)
        #expect(Codespan.lineIndex(lineStarts: lineStarts, byteIndex: 2) == 0)
        #expect(Codespan.lineIndex(lineStarts: lineStarts, byteIndex: 4) == 1)
        #expect(Codespan.lineIndex(lineStarts: lineStarts, byteIndex: 6) == 1)
        #expect(Codespan.lineIndex(lineStarts: lineStarts, byteIndex: 9) == 2)
        #expect(Codespan.lineIndex(lineStarts: lineStarts, byteIndex: 10) == 3)
        #expect(Codespan.lineIndex(lineStarts: lineStarts, byteIndex: 12) == 3)
    }

    @Test
    func columnIndex() {
        let source = "\n\n🗻∈🌏\n\n";

        #expect(Codespan.columnIndex(in: source, lineRange: 0..<1, byteIndex: 0) == 0)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 0) == 0)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 0) == 0)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 1) == 0)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 4) == 1)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 8) == 2)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 10) == 2)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 11) == 3)
        #expect(Codespan.columnIndex(in: source, lineRange: 2..<13, byteIndex: 2 + 12) == 3)
    }
}
