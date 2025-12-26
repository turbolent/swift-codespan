/// Output a short diagnostic, with a line number, severity, and message.
struct ShortDiagnosticView<FileId: Equatable> {

    var diagnostic: Diagnostic<FileId>
    var showNotes: Bool

    init(
        diagnostic: Diagnostic<FileId>,
        includeNotes: Bool
    ) {
        self.diagnostic = diagnostic
        self.showNotes = includeNotes
    }

    func render<Files: FilesProtocol, Output: TextOutputStream, Emitter: StyleEmitter>(
        files: Files,
        renderer: inout Renderer<Emitter>,
        output: inout Output
    ) throws where Files.FileId == FileId, Files.Source: StringProtocol {

        let primaryLabels = diagnostic.labels.filter { $0.style == .primary }
        if primaryLabels.isEmpty {
            // Fallback to printing a non-located header if no primary labels were encountered
            //
            // ```text
            // error[E0002]: Bad config found
            // ```
            renderer.renderHeader(
                locus: nil,
                severity: diagnostic.severity,
                code: diagnostic.code,
                message: diagnostic.message,
                output: &output
            )
        } else {
            // Located headers
            //
            // ```text
            // test:2:9: error[E0001]: unexpected type in `+` application
            // ```
            for label in primaryLabels {
                let locus = Locus(
                    name: try files.name(of: label.fileId).description,
                    location: try files.location(of: label.fileId, at: label.range.lowerBound)
                )
                renderer.renderHeader(
                    locus: locus,
                    severity: diagnostic.severity,
                    code: diagnostic.code,
                    message: diagnostic.message,
                    output: &output
                )
            }
        }

        if showNotes {
            // Additional notes
            //
            // ```text
            // = expected type `Int`
            //      found type `String`
            // ```
            for note in diagnostic.notes {
                renderer.renderSnippetNote(outerPadding: 0, message: note, output: &output)
            }
        }
    }
}
