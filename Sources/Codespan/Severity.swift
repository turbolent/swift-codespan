/// A severity level for diagnostic messages.
///
public enum Severity: UInt8, Comparable, CustomStringConvertible {

    /// A help message.
    case help

    /// A note.
    case note

    /// A warning.
    case warning

    /// An error.
    case error

    /// An unexpected bug.
    case bug

    public static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
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

    public var color: Color {
        switch self {
            case .bug, .error:
                return .red

            case .warning:
                return .yellow

            case .note:
                return .green

            case .help:
                return .cyan
        }
    }
}
