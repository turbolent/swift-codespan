/// A label describing an underlined region of code associated with a diagnostic.
public struct Label<FileId: Equatable>: Equatable {

    /// The style of the label.
    public var style: LabelStyle

    /// The file that we are labelling.
    public var fileId: FileId

    /// The range in bytes we are going to include in the final snippet.
    public var range: Range<UInt>

    /// An optional message to provide some additional information for the
    /// underlined code. These should not include line breaks.
    public var message: String

    /// Create a new label.
    public init(
        style: LabelStyle,
        fileId: FileId,
        range: Range<UInt>,
        message: String = ""
    ) {
        self.style = style
        self.fileId = fileId
        self.range = range
        self.message = message
    }

    /// Create a new label with a style of `LabelStyle.primary`.
    public static func primary(
        fileId: FileId,
        range: Range<UInt>,
        message: String = ""
    ) -> Label<FileId> {
        Label(
            style: .primary,
            fileId: fileId,
            range: range,
            message: message
        )
    }

    /// Create a new label with a style of `LabelStyle.secondary`.
    public static func secondary(
        fileId: FileId,
        range: Range<UInt>,
        message: String = ""
    ) -> Label<FileId> {
        Label(
            style: .secondary,
            fileId: fileId,
            range: range,
            message: message
        )
    }
}
