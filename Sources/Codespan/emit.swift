public func emit<Files: FilesProtocol, Writer: TextOutputStream, Emitter: StyleEmitter>(
    writer: inout Writer,
    config: Config,
    styles: Styles,
    styleEmitter: Emitter,
    files: Files,
    diagnostic: Diagnostic<Files.FileId>
) throws where Files.Source: StringProtocol {
    var renderer = Renderer(
        config: config,
        styles: styles,
        styleEmitter: styleEmitter
    )

    switch config.displayStyle {
        case .rich:
            try RichDiagnosticView(diagnostic: diagnostic, config: config)
                .render(
                    files: files,
                    styles: styles,
                    renderer: &renderer,
                    output: &writer
                )

        case .medium:
            try ShortDiagnosticView(diagnostic: diagnostic, includeNotes: true)
                .render(
                    files: files,
                    renderer: &renderer,
                    output: &writer
                )

        case .short:
            try ShortDiagnosticView(diagnostic: diagnostic, includeNotes: false)
                .render(
                    files: files,
                    renderer: &renderer,
                    output: &writer
                )
    }
}
