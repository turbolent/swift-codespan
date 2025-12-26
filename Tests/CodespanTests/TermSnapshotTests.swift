import XCTest
@testable import Codespan

final class TermSnapshotTests: XCTestCase {
    func testMessageErrorcodeRichNoColor() throws {
        let files = Files<String>()
        let diagnostics = messageErrorcodeDiagnostics()
        let output = try emitAll(diagnostics: diagnostics, config: Config(displayStyle: .rich), files: files)

        let expected = """
error[E0001]: a message

warning[W001]: a message

note[N0815]: a message

help[H4711]: a message

error: where did my errorcode go?

warning: where did my errorcode go?

note: where did my errorcode go?

help: where did my errorcode go?


"""
        XCTAssertEqual(output, expected)
    }

    func testMessageErrorcodeShortNoColor() throws {
        let files = Files<String>()
        let diagnostics = messageErrorcodeDiagnostics()
        let output = try emitAll(diagnostics: diagnostics, config: Config(displayStyle: .short), files: files)

        let expected = """
error[E0001]: a message
warning[W001]: a message
note[N0815]: a message
help[H4711]: a message
error: where did my errorcode go?
warning: where did my errorcode go?
note: where did my errorcode go?
help: where did my errorcode go?

"""
        XCTAssertEqual(output, expected)
    }

    func testEmptyDiagnosticsRichNoColor() throws {
        let files = Files<String>()
        let diagnostics = emptyDiagnostics()
        let output = try emitAll(diagnostics: diagnostics, config: Config(displayStyle: .rich), files: files)

        let expected = """
bug: 

error: 

warning: 

note: 

help: 

bug: 


"""
        XCTAssertEqual(output, expected)
    }

    func testEmptyDiagnosticsMediumNoColor() throws {
        let files = Files<String>()
        let diagnostics = emptyDiagnostics()
        let output = try emitAll(diagnostics: diagnostics, config: Config(displayStyle: .medium), files: files)

        let expected = """
bug: 
error: 
warning: 
note: 
help: 
bug: 

"""
        XCTAssertEqual(output, expected)
    }

    func testEmptyDiagnosticsShortNoColor() throws {
        let files = Files<String>()
        let diagnostics = emptyDiagnostics()
        let output = try emitAll(diagnostics: diagnostics, config: Config(displayStyle: .short), files: files)

        let expected = """
bug: 
error: 
warning: 
note: 
help: 
bug: 

"""
        XCTAssertEqual(output, expected)
    }
}

private func emitAll<F: FilesProtocol>(
    diagnostics: [Diagnostic<F.FileId>],
    config: Config,
    files: F
) throws -> String where F.Source: StringProtocol {
    var output = ""
    for diagnostic in diagnostics {
        try emit(
            writer: &output,
            config: config,
            styles: .standard,
            styleEmitter: DebugStyleEmitter(),
            files: files,
            diagnostic: diagnostic
        )
    }
    return output
}

private func messageErrorcodeDiagnostics() -> [Diagnostic<FileId>] {
    [
        Diagnostic<FileId>.error(code: "E0001", message: "a message"),
        Diagnostic<FileId>.warning(code: "W001", message: "a message"),
        Diagnostic<FileId>.note(code: "N0815", message: "a message"),
        Diagnostic<FileId>.help(code: "H4711", message: "a message"),
        Diagnostic<FileId>.error(code: "", message: "where did my errorcode go?"),
        Diagnostic<FileId>.warning(code: "", message: "where did my errorcode go?"),
        Diagnostic<FileId>.note(code: "", message: "where did my errorcode go?"),
        Diagnostic<FileId>.help(code: "", message: "where did my errorcode go?"),
    ]
}

private func emptyDiagnostics() -> [Diagnostic<FileId>] {
    [
        Diagnostic<FileId>.bug(),
        Diagnostic<FileId>.error(),
        Diagnostic<FileId>.warning(),
        Diagnostic<FileId>.note(),
        Diagnostic<FileId>.help(),
        Diagnostic<FileId>.bug(),
    ]
}
