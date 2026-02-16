import Testing

@testable import Codespan

@Suite
struct ReadmeExampleTests {
    @Test
    func readmeExampleOutput() throws {
        let example = ReadmeExample.make()

        var output = ""
        try emit(
            writer: &output,
            config: .init(),
            styles: .standard,
            styleEmitter: DebugStyleEmitter(),
            files: example.files,
            diagnostic: example.diagnostic
        )
        #expect(
            trimTrailingNewlines(output) == trimTrailingNewlines(example.expectedOutput)
        )
    }
}

private func trimTrailingNewlines(_ text: String) -> String {
    var result = text
    while result.hasSuffix("\n") {
        result.removeLast()
    }
    return result
}
