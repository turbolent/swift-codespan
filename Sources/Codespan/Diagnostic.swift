/// Represents a diagnostic message that can provide information like errors and
/// warnings to the user.
///
/// The position of a Diagnostic is considered to be the position of the `Label`
/// that has the earliest starting position and has the highest style
/// which appears in all the labels of the diagnostic.
public struct Diagnostic<FileId: Equatable>: Equatable {

    /// The overall severity of the diagnostic
    public var severity: Severity

    /// An optional code that identifies this diagnostic.
    public var code: String?

    /// The main message associated with this diagnostic.
    ///
    /// These should not include line breaks, and in order support the 'short'
    /// diagnostic display mod, the message should be specific enough to make
    /// sense on its own, without additional context provided by labels and notes.
    public var message: String

    /// Source labels that describe the cause of the diagnostic.
    /// The order of the labels inside the vector does not have any meaning.
    /// The labels are always arranged in the order they appear in the source code.
    public var labels: [Label<FileId>]

    /// Notes that are associated with the primary cause of the diagnostic.
    /// These can include line breaks for improved formatting.
    public var notes: [String]

    public init(
        severity: Severity,
        code: String? = nil,
        message: String = "",
        labels: [Label<FileId>] = [],
        notes: [String] = []
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.labels = labels
        self.notes = notes
    }

    /// Create a new diagnostic with a severity of `Severity.bug`.
    public static func bug(
        code: String? = nil,
        message: String = "",
        labels: [Label<FileId>] = [],
        notes: [String] = []
    ) -> Diagnostic<FileId> {
        Diagnostic(
            severity: .bug,
            code: code,
            message: message,
            labels: labels,
            notes: notes
        )
    }

    /// Create a new diagnostic with a severity of `Severity.error`.
    public static func error(
        code: String? = nil,
        message: String = "",
        labels: [Label<FileId>] = [],
        notes: [String] = []
    ) -> Diagnostic<FileId> {
        Diagnostic(
            severity: .error,
            code: code,
            message: message,
            labels: labels,
            notes: notes
        )
    }

    /// Create a new diagnostic with a severity of `Severity.warning`.
    public static func warning(
        code: String? = nil,
        message: String = "",
        labels: [Label<FileId>] = [],
        notes: [String] = []
    ) -> Diagnostic<FileId> {
        Diagnostic(
            severity: .warning,
            code: code,
            message: message,
            labels: labels,
            notes: notes
        )
    }

    /// Create a new diagnostic with a severity of `Severity.note`.
    public static func note(
        code: String? = nil,
        message: String = "",
        labels: [Label<FileId>] = [],
        notes: [String] = []
    ) -> Diagnostic<FileId> {
        Diagnostic(
            severity: .note,
            code: code,
            message: message,
            labels: labels,
            notes: notes
        )
    }

    /// Create a new diagnostic with a severity of `Severity.help`.
    public static func help(
        code: String? = nil,
        message: String = "",
        labels: [Label<FileId>] = [],
        notes: [String] = []
    ) -> Diagnostic<FileId> {
        Diagnostic(
            severity: .help,
            code: code,
            message: message,
            labels: labels,
            notes: notes
        )
    }
}
