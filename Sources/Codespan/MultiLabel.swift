/// A multi-line label to render.
enum MultiLabel {

    /// Multi-line label top.
    ///
    /// ```text
    /// ╭────────────^
    /// ```
    ///
    /// Can also be rendered at the beginning of the line
    /// if there is only whitespace before the label starts.
    ///
    /// ```text
    /// ╭
    /// ```
    case top(labelStart: UInt)

    /// Left vertical labels for multi-line labels.
    ///
    /// ```text
    /// │
    /// ```
    case left

    /// Multi-line label bottom, with an optional message.
    ///
    /// ```text
    /// ╰────────────^ blah blah
    /// ```
    case bottom(labelEnd: UInt, message: String)
}
