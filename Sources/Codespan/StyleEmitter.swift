/// Applies styling for different parts of a diagnostic renderer.
public protocol StyleEmitter {

    func write<Output: TextOutputStream>(
        _ string: String,
        to output: inout Output
    )

    mutating func setHeader<Output: TextOutputStream>(
        severity: Severity,
        style: Style,
        output: inout Output
    )

    mutating func setHeaderMessage<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    )

    mutating func setLineNumber<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    )

    mutating func setNoteBullet<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    )

    mutating func setSourceBorder<Output: TextOutputStream>(
        style: Style,
        output: inout Output
    )

    mutating func setLabel<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        style: Style,
        output: inout Output
    )

    mutating func reset<Output: TextOutputStream>(output: inout Output)
}
