import Testing

@testable import Codespan

@Suite
struct DiagnosticTests {
    @Test
    func severityOrdering() {
        #expect(Severity.bug > Severity.error)
        #expect(Severity.error > Severity.warning)
        #expect(Severity.warning > Severity.note)
        #expect(Severity.note > Severity.help)
    }

    @Test
    func labelMessage() {
        let label = Label.primary(
            fileId: UInt(1),
            range: 5..<10,
            message: "msg"
        )
        #expect(label.message == "msg")
    }

    @Test
    func diagnosticFields() {
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

        #expect(diagnostic.severity == .error)
        #expect(diagnostic.code == "E0001")
        #expect(diagnostic.message == "bad")
        #expect(diagnostic.labels.count == 1)
        #expect(diagnostic.notes.count == 1)
    }
}
