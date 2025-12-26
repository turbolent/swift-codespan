import XCTest

@testable import Codespan

final class DiagnosticTests: XCTestCase {
    func testSeverityOrdering() {
        XCTAssertTrue(Severity.bug > Severity.error)
        XCTAssertTrue(Severity.error > Severity.warning)
        XCTAssertTrue(Severity.warning > Severity.note)
        XCTAssertTrue(Severity.note > Severity.help)
    }

    func testLabelMessage() {
        let label = Label.primary(
            fileId: UInt(1),
            range: 5..<10,
            message: "msg"
        )
        XCTAssertEqual(label.message, "msg")
    }

    func testDiagnosticFields() {
        let diagnostic = Diagnostic<Int>.error(
            code: "E0001",
            message: "bad",
            labels: [
                Label.primary(
                    fileId: 1,
                    range: 0..<1
                )
            ],
            notes: ["note"]
        )

        XCTAssertEqual(diagnostic.severity, .error)
        XCTAssertEqual(diagnostic.code, "E0001")
        XCTAssertEqual(diagnostic.message, "bad")
        XCTAssertEqual(diagnostic.labels.count, 1)
        XCTAssertEqual(diagnostic.notes.count, 1)
    }
}
