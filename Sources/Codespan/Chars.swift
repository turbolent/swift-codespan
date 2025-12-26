/// Characters to use when rendering the diagnostic.
public struct Chars {
    /// The characters to use for the top-left border of the snippet.
    public var snippetStart: String

    /// The character to use for the left border of the source.
    public var sourceBorderLeft: Character

    /// The character to use for the left border break of the source.
    public var sourceBorderLeftBreak: Character

    /// The character to use for the note bullet.
    public var noteBullet: Character

    /// The character to use for marking a single-line primary label.
    public var singlePrimaryCaret: Character

    /// The character to use for marking a single-line secondary label.
    public var singleSecondaryCaret: Character

    /// The character to use for marking the start of a multi-line primary label.
    public var multiPrimaryCaretStart: Character

    /// The character to use for marking the end of a multi-line primary label.
    public var multiPrimaryCaretEnd: Character

    /// The character to use for marking the start of a multi-line secondary label.
    public var multiSecondaryCaretStart: Character

    /// The character to use for marking the end of a multi-line secondary label.
    public var multiSecondaryCaretEnd: Character

    /// The character to use for the top-left corner of a multi-line label.
    public var multiTopLeft: Character

    /// The character to use for the top of a multi-line label.
    public var multiTop: Character

    /// The character to use for the bottom-left corner of a multi-line label.
    public var multiBottomLeft: Character

    /// The character to use when marking the bottom of a multi-line label.
    public var multiBottom: Character

    /// The character to use for the left of a multi-line label.
    public var multiLeft: Character

    /// The character to use for the left of a pointer underneath a caret.
    public var pointerLeft: Character

    public init(
        snippetStart: String,
        sourceBorderLeft: Character,
        sourceBorderLeftBreak: Character,
        noteBullet: Character,
        singlePrimaryCaret: Character,
        singleSecondaryCaret: Character,
        multiPrimaryCaretStart: Character,
        multiPrimaryCaretEnd: Character,
        multiSecondaryCaretStart: Character,
        multiSecondaryCaretEnd: Character,
        multiTopLeft: Character,
        multiTop: Character,
        multiBottomLeft: Character,
        multiBottom: Character,
        multiLeft: Character,
        pointerLeft: Character
    ) {
        self.snippetStart = snippetStart
        self.sourceBorderLeft = sourceBorderLeft
        self.sourceBorderLeftBreak = sourceBorderLeftBreak
        self.noteBullet = noteBullet
        self.singlePrimaryCaret = singlePrimaryCaret
        self.singleSecondaryCaret = singleSecondaryCaret
        self.multiPrimaryCaretStart = multiPrimaryCaretStart
        self.multiPrimaryCaretEnd = multiPrimaryCaretEnd
        self.multiSecondaryCaretStart = multiSecondaryCaretStart
        self.multiSecondaryCaretEnd = multiSecondaryCaretEnd
        self.multiTopLeft = multiTopLeft
        self.multiTop = multiTop
        self.multiBottomLeft = multiBottomLeft
        self.multiBottom = multiBottom
        self.multiLeft = multiLeft
        self.pointerLeft = pointerLeft
    }

    /// A character set that uses Unicode box drawing characters.
    public static var boxDrawing: Chars {
        Chars(
            snippetStart: "┌─",
            sourceBorderLeft: "│",
            sourceBorderLeftBreak: "·",
            noteBullet: "=",
            singlePrimaryCaret: "^",
            singleSecondaryCaret: "-",
            multiPrimaryCaretStart: "^",
            multiPrimaryCaretEnd: "^",
            multiSecondaryCaretStart: "'",
            multiSecondaryCaretEnd: "'",
            multiTopLeft: "╭",
            multiTop: "─",
            multiBottomLeft: "╰",
            multiBottom: "─",
            multiLeft: "│",
            pointerLeft: "│"
        )
    }

    /// A character set that only uses ASCII characters.
    ///
    /// This is useful if your terminal's font does not support box drawing
    /// characters well and results in output that looks similar to rustc's
    /// diagnostic output.
    public static var ascii: Chars {
        Chars(
            snippetStart: "-->",
            sourceBorderLeft: "|",
            sourceBorderLeftBreak: ".",
            noteBullet: "=",
            singlePrimaryCaret: "^",
            singleSecondaryCaret: "-",
            multiPrimaryCaretStart: "^",
            multiPrimaryCaretEnd: "^",
            multiSecondaryCaretStart: "'",
            multiSecondaryCaretEnd: "'",
            multiTopLeft: "/",
            multiTop: "-",
            multiBottomLeft: "\\",
            multiBottom: "-",
            multiLeft: "|",
            pointerLeft: "|"
        )
    }
}
