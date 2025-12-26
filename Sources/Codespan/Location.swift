/// A user-facing location in a source file.
/// Line number and column number are both 1-indexed.
public struct Location: Equatable {

    /// The user-facing line number.
    public var lineNumber: UInt

    /// The user-facing column number.
    public var columnNumber: UInt

    public init(
        lineNumber: UInt,
        columnNumber: UInt
    ) {
        self.lineNumber = lineNumber
        self.columnNumber = columnNumber
    }
}
