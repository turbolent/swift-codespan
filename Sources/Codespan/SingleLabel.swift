/// Single-line label, with an optional message.
///
/// ```text
/// ^^^^^^^^^ blah blah
/// ```
struct SingleLabel {
    /// The style of the label.
    let labelStyle: LabelStyle

    /// The range in bytes we are going to underline.
    let range: Range<UInt>

    /// An optional message to provide some additional information for the underlined code.
    /// These should not include line breaks.
    let message: String
}
