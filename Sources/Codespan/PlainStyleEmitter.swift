public struct PlainStyleEmitter: StyleEmitter {
    public init() {}

    public func write<Output: TextOutputStream>(
        _ string: String,
        to output: inout Output
    ) {
        // Plain style writes strings without any styling directives.
        output.write(string)
    }

    public mutating func setHeader<Output: TextOutputStream>(
        severity: Severity,
        style: Style,
        output: inout Output
    ) {
        // Plain style ignores all styling directives.
    }

    public mutating func setHeaderMessage<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        // Plain style ignores all styling directives.
    }

    public mutating func setLineNumber<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        // Plain style ignores all styling directives.
    }

    public mutating func setNoteBullet<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        // Plain style ignores all styling directives.
    }

    public mutating func setSourceBorder<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    ) {
        // Plain style ignores all styling directives.
    }

    public mutating func setLabel<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        style: Style,
        output: inout Output
    ) {
        // Plain style ignores all styling directives.
    }

    public mutating func reset<Output: TextOutputStream>(output: inout Output) {
        // Plain style ignores all styling directives.
    }
}
