import Testing

@testable import Codespan

@Suite
struct TermTests {
    @Test
    func unsizedEmit() throws {
        var files = Files<String>()
        let fileId = files.add(name: "test", source: "")
        let diagnostic = Diagnostic<FileId>.bug(
            labels: [
                Label.primary(
                    fileId: fileId,
                    range: 0..<0
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
}
