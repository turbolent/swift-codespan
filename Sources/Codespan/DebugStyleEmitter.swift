
// Color tester from:
// https://github.com/wycats/language-reporting/blob/b021c87e0d4916b5f32756151bf215c220eee52d/crates/render-tree/src/stylesheet/accumulator.rs

/// A facility for creating visually inspectable representations of colored output
/// so they can be easily tested.
///
/// A new color is represented as `{style}` and a reset is represented by `{/}`.
///
/// Attributes are printed in this order:
///
/// - Foreground color as `fg:Color`
/// - Background color as `bg:Color`
/// - Bold as `bold`
/// - Underline as `underline`
/// - Intense as `bright`
///
/// For example, the style "intense, bold red foreground" would be printed as:
///
/// ```text
/// {fg:Red bold intense}
/// ```
///
/// Since this implementation attempts to make it possible to faithfully understand
/// what a real implementations would do, it tries to approximate the contract:
/// "Subsequent writes to this write will use these settings until either reset is
/// called or new color settings are set."
///
/// - If `set` is called with a style, `{...}` is emitted containing the color attributes.
/// - If `set` is called with no style, `{/}` is emitted
/// - If reset is called, `{/}` is emitted.
public struct DebugStyleEmitter: StyleEmitter {
    private var current: Style = .none

    public init() {}

    public func write<Output: TextOutputStream>(
        _ string: String,
        to output: inout Output
    ) {
        output.write(string)
    }

    public mutating func setHeader<Output: TextOutputStream>(
        severity: Severity,
        style: Style,
        output: inout Output
    ) {
        setStyle(style, output: &output)
    }

    public mutating func setHeaderMessage<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        setStyle(style, output: &output)
    }

    public mutating func setLineNumber<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        setStyle(style, output: &output)
    }

    public mutating func setNoteBullet<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        setStyle(style, output: &output)
    }

    public mutating func setSourceBorder<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        setStyle(style, output: &output)
    }

    public mutating func setLabel<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        style: Style,
        output: inout Output
    ) {
        setStyle(style, output: &output)
    }

    private mutating func setStyle<Output: TextOutputStream>(
        _ style: Style,
        output: inout Output
    ) {
        if style == current {
            return
        }
        current = style

        if style == .none {
            output.write("{/}")
            return
        }

        output.write("{")

        var first = true
        func writeSeparator() {
            if !first {
                output.write(" ")
            }
            first = false
        }

        if let foreground = style.foreground {
            writeSeparator()
            let colorName = DebugStyleEmitter.colorName(for: foreground)
            output.write("fg:\(colorName)")
        }

        if let background = style.background {
            writeSeparator()
            let colorName = DebugStyleEmitter.colorName(for: background)
            output.write("bg:\(colorName)")
        }

        if style.isBold {
            writeSeparator()
            output.write("bold")
        }

        if style.isUnderline {
            writeSeparator()
            output.write("underline")
        }

        if style.isIntense {
            writeSeparator()
            output.write("bright")
        }

        output.write("}")
    }

    public mutating func reset<Output: TextOutputStream>(output: inout Output) {
        if current == .none {
            return
        }
        output.write("{/}")
        current = .none
    }

    private static func colorName(for color: Color) -> String {
        switch color {
        case .black:
            return "Black"
        case .red:
            return "Red"
        case .green:
            return "Green"
        case .yellow:
            return "Yellow"
        case .blue:
            return "Blue"
        case .magenta:
            return "Magenta"
        case .cyan:
            return "Cyan"
        case .white:
            return "White"
        }
    }
}
