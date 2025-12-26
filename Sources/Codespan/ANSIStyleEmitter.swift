public struct ANSIStyleEmitter: StyleEmitter {
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
        startStyle(style, output: &output)
    }

    public mutating func setHeaderMessage<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        startStyle(style, output: &output)
    }

    public mutating func setLineNumber<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        startStyle(style, output: &output)
    }

    public mutating func setNoteBullet<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        startStyle(style, output: &output)
    }

    public mutating func setSourceBorder<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        startStyle(style, output: &output)
    }

    public mutating func setLabel<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        style: Style,
        output: inout Output
    ) {
        startStyle(style, output: &output)
    }

    public mutating func reset<Output: TextOutputStream>(output: inout Output) {
        endStyle(output: &output)
    }

    private mutating func endStyle<Output: TextOutputStream>(output: inout Output) {
        if current == .none {
            return
        }
        output.write("\u{001B}[0m")
        current = .none
    }

    private mutating func startStyle<Output: TextOutputStream>(
        _ style: Style,
        output: inout Output
    ) {
        if style == current {
            return
        }

        endStyle(output: &output)

        if style == .none {
            return
        }

        var codes: [UInt8] = []

        if let foreground = style.foreground {
            let colorCode = ANSIStyleEmitter.ansiForegroundCode(for: foreground)
                + ANSIStyleEmitter.intenseOffset(style.isIntense)
            codes.append(colorCode)
        }

        if let background = style.background {
            let colorCode = ANSIStyleEmitter.ansiBackgroundCode(for: background)
                + ANSIStyleEmitter.intenseOffset(style.isIntense)
            codes.append(colorCode)
        }

        if style.isBold {
            codes.append(1)
        }

        if style.isUnderline {
            codes.append(4)
        }

        output.write("\u{001B}[")
        for (index, code) in codes.enumerated() {
            if index > 0 {
                output.write(";")
            }
            output.write(String(code))
        }
        output.write("m")

        current = style
    }

    private static func ansiColorOffset(for color: Color) -> UInt8 {
        switch color {
            case .black:
                return 0
            case .red:
                return 1
            case .green:
                return 2
            case .yellow:
                return 3
            case .blue:
                return 4
            case .magenta:
                return 5
            case .cyan:
                return 6
            case .white:
                return 7
        }
    }

    private static func intenseOffset(_ intense: Bool) -> UInt8 {
        return intense ? 60 : 0
    }

    private static func ansiForegroundCode(for color: Color) -> UInt8 {
        return 30 + ansiColorOffset(for: color)
    }

    private static func ansiBackgroundCode(for color: Color) -> UInt8 {
        return 40 + ansiColorOffset(for: color)
    }
}
