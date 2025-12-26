/// Styles to use when rendering the diagnostic.
public struct Styles {

    /// The style used to mark a header at a given severity.
    public var header: (Severity) -> Style

    /// The style to use when the main diagnostic message.
    public var headerMessage: Style

    /// The style used to mark a label at a given severity.
    public var label: (Severity, LabelStyle) -> Style

    /// The style to use when rendering the line numbers.
    public var lineNumber: Style

    /// The style to use when rendering the source code borders.
    public var sourceBorder: Style

    /// The style to use when rendering the note bullets.
    public var noteBullet: Style

    public init(
        header: @escaping (Severity) -> Style,
        headerMessage: Style,
        label: @escaping (Severity, LabelStyle) -> Style,
        lineNumber: Style,
        sourceBorder: Style,
        noteBullet: Style
    ) {
        self.header = header
        self.headerMessage = headerMessage
        self.label = label
        self.lineNumber = lineNumber
        self.sourceBorder = sourceBorder
        self.noteBullet = noteBullet
    }

    public static var standard: Styles {
        noColor
    }

    public static var standardColor: Styles {
        let cyan = Style(foreground: .cyan)
        return Styles(
            header: { severity in
                Style(
                    foreground: severity.color,
                    isBold: true,
                    isIntense: true
                )
            },
            headerMessage: Style(isBold: true, isIntense: true),
            label: { severity, labelStyle in
                switch labelStyle {
                    case .primary:
                        return Style(foreground: severity.color)
                    case .secondary:
                        return cyan
                }
            },
            lineNumber: cyan,
            sourceBorder: cyan,
            noteBullet: cyan
        )
    }

    public static var noColor: Styles {
        let none = Style()
        return Styles(
            header: { _ in none },
            headerMessage: none,
            label: { _, _ in none },
            lineNumber: none,
            sourceBorder: none,
            noteBullet: none
        )
    }
}
