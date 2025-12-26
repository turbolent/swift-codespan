/// An enumeration describing the style of a label in a diagnostic.
public enum LabelStyle: UInt8, Comparable {

    /// Labels that describe the primary cause of a diagnostic.
    case primary

    /// Labels that provide additional context for a diagnostic.
    case secondary

    public static func < (lhs: LabelStyle, rhs: LabelStyle) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
