/// An emitter that outputs styles as SVG `<span>` elements with class names.
/// These class names can then be styled via CSS.
/// The actual colors and styles are expected to be defined in CSS.
///
/// All class names are of the form `<element>-<modifier>`, where `<element>` is
/// one of:
/// - `header-<severity>`
/// - `header-message`
/// - `line-number`
/// - `source-border`
/// - `note-bullet`
/// - `label-<label-style>-<severity>`
/// and `<modifier>` is one of:
/// - For `<severity>`:
///   - `bug`
///   - `error`
///   - `warning`
///   - `note`
///   - `help`
/// - For `<label-style>`:
///   - `primary`
///   - `secondary`
///
/// For example:
/// - a primary label with error severity would have the class name `label-primary-error`
/// - a header with warning severity would have the class name `header-warning`
/// - a line number would have the class name `line-number`
///
public struct SVGStyleEmitter: StyleEmitter {
    private var current: Style = .none

    public init() {}

    public func write<Output: TextOutputStream>(
        _ string: String,
        to output: inout Output
    ) {
        var lastIndex = string.startIndex
        var index = string.startIndex
        while index < string.endIndex {
            let character = string[index]
            let escape: String?
            switch character {
            case "<":
                escape = "&lt;"
            case ">":
                escape = "&gt;"
            case "&":
                escape = "&amp;"
            default:
                escape = nil
            }

            if let escape {
                if lastIndex < index {
                    output.write(String(string[lastIndex..<index]))
                }
                output.write(escape)
                lastIndex = string.index(after: index)
            }

            index = string.index(after: index)
        }

        if lastIndex < string.endIndex {
            output.write(String(string[lastIndex..<string.endIndex]))
        }
    }

    public mutating func setHeader<Output: TextOutputStream>(
        severity: Severity,
        style: Style,
        output: inout Output
    ) {
        let severityClassName = SVGStyleEmitter.severityClassName(for: severity)
        openSpan(
            className: "header-\(severityClassName)",
            style: style,
            output: &output
        )
    }

    public mutating func setHeaderMessage<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        openSpan(
            className: "header-message",
            style: style,
            output: &output
        )
    }

    public mutating func setLineNumber<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        openSpan(
            className: "line-number",
            style: style,
            output: &output
        )
    }

    public mutating func setNoteBullet<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        openSpan(
            className: "note-bullet",
            style: style,
            output: &output
        )
    }

    public mutating func setSourceBorder<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        openSpan(
            className: "source-border",
            style: style,
            output: &output
        )
    }

    public mutating func setLabel<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        style: Style,
        output: inout Output
    ) {
        let labelStyleClassName = SVGStyleEmitter.labelStyleClassName(for: labelStyle)
        let severityClassName = SVGStyleEmitter.severityClassName(for: severity)
        openSpan(
            className: "label-\(labelStyleClassName)-\(severityClassName)",
            style: style,
            output: &output
        )
    }

    public mutating func reset<Output: TextOutputStream>(output: inout Output) {
        closeSpan(output: &output)
    }

    private mutating func closeSpan<Output: TextOutputStream>(output: inout Output) {
        if current == .none {
            return
        }
        output.write("</span>")
        current = .none
    }

    private mutating func openSpan<Output: TextOutputStream>(
        className: String,
        style: Style,
        output: inout Output
    ) {
        if style == current {
            return
        }

        closeSpan(output: &output)

        if style == .none {
            return
        }

        output.write("<span class=\"\(className)\">")

        current = style
    }

    public static func severityClassName(for severity: Severity) -> String {
        switch severity {
            case .bug:
                return "bug"
            case .error:
                return "error"
            case .warning:
                return "warning"
            case .note:
                return "note"
            case .help:
                return "help"
        }
    }

    public static func labelStyleClassName(for labelStyle: LabelStyle) -> String {
        switch labelStyle {
            case .primary:
                return "primary"
            case .secondary:
                return "secondary"
        }
    }
}
