/// Configures how a diagnostic is rendered.
public struct Config {
    /// The display style to use when rendering diagnostics.
    /// Defaults to: `DisplayStyle.rich`.
    public var displayStyle: DisplayStyle

    /// Column width of tabs.
    /// Defaults to: `4`.
    public var tabWidth: UInt

    /// Characters to use when rendering the diagnostic.
    /// Defaults to: `TermChars.boxDrawing`.
    public var chars: Chars

    /// The minimum number of lines to be shown after the line on which a multiline `Label` begins.
    /// Defaults to: `3`.
    public var startContextLines: UInt

    /// The minimum number of lines to be shown before the line on which a multiline `Label` ends.
    /// Defaults to: `1`.
    public var endContextLines: UInt

    /// The minimum number of lines before a label that should be included for context.
    /// Defaults to: `0`.
    public var beforeLabelLines: UInt

    /// The minimum number of lines after a label that should be included for context.
    /// Defaults to: `0`.
    public var afterLabelLines: UInt

    public init(
        displayStyle: DisplayStyle = .rich,
        tabWidth: UInt = 4,
        chars: Chars = .boxDrawing,
        startContextLines: UInt = 3,
        endContextLines: UInt = 1,
        beforeLabelLines: UInt = 0,
        afterLabelLines: UInt = 0
    ) {
        self.displayStyle = displayStyle
        self.tabWidth = tabWidth
        self.chars = chars
        self.startContextLines = startContextLines
        self.endContextLines = endContextLines
        self.beforeLabelLines = beforeLabelLines
        self.afterLabelLines = afterLabelLines
    }
}
