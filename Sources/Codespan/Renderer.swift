private enum VerticalBound {
    case top
    case bottom
}

private struct Metrics {
    var byteIndex: UInt
    var unicodeWidth: UInt
}

private struct Underline {
    var labelStyle: LabelStyle
    var verticalBound: VerticalBound
}

/// A renderer of display list entries.
///
/// The following diagram gives an overview of each of the parts of the renderer's output:
///
/// ```text
///                     ┌ outer gutter
///                     │ ┌ left border
///                     │ │ ┌ inner gutter
///                     │ │ │   ┌─────────────────────────── source ─────────────────────────────┐
///                     │ │ │   │                                                                │
///                  ┌────────────────────────────────────────────────────────────────────────────
///        header ── │ error[0001]: oh noes, a cupcake has occurred!
/// snippet start ── │    ┌─ test:9:0
/// snippet empty ── │    │
///  snippet line ── │  9 │   ╭ Cupcake ipsum dolor. Sit amet marshmallow topping cheesecake
///  snippet line ── │ 10 │   │ muffin. Halvah croissant candy canes bonbon candy. Apple pie jelly
///                  │    │ ╭─│─────────^
/// snippet break ── │    · │ │
///  snippet line ── │ 33 │ │ │ Muffin danish chocolate soufflé pastry icing bonbon oat cake.
///  snippet line ── │ 34 │ │ │ Powder cake jujubes oat cake. Lemon drops tootsie roll marshmallow
///                  │    │ │ ╰─────────────────────────────^ blah blah
/// snippet break ── │    · │
///  snippet line ── │ 38 │ │   Brownie lemon drops chocolate jelly-o candy canes. Danish marzipan
///  snippet line ── │ 39 │ │   jujubes soufflé carrot cake marshmallow tiramisu caramels candy canes.
///                  │    │ │           ^^^^^^^^^^^^^^^^^^^ -------------------- blah blah
///                  │    │ │           │
///                  │    │ │           blah blah
///                  │    │ │           note: this is a note
///  snippet line ── │ 40 │ │   Fruitcake jelly-o danish toffee. Tootsie roll pastry cheesecake
///  snippet line ── │ 41 │ │   soufflé marzipan. Chocolate bar oat cake jujubes lollipop pastry
///  snippet line ── │ 42 │ │   cupcake. Candy canes cupcake toffee gingerbread candy canes muffin
///                  │    │ │                                ^^^^^^^^^^^^^^^^^^ blah blah
///                  │    │ ╰──────────^ blah blah
/// snippet break ── │    ·
///  snippet line ── │ 82 │     gingerbread toffee chupa chups chupa chups jelly-o cotton candy.
///                  │    │                 ^^^^^^                         ------- blah blah
/// snippet empty ── │    │
///  snippet note ── │    = blah blah
///  snippet note ── │    = blah blah blah
///                  │      blah blah
///  snippet note ── │    = blah blah blah
///                  │      blah blah
///         empty ── │
/// ```
///
/// > Filler text from <http://www.cupcakeipsum.com>
struct Renderer<Emitter: StyleEmitter> {
    private let config: Config
    private let styles: Styles
    private var styleEmitter: Emitter

    init(
        config: Config,
        styles: Styles,
        styleEmitter: Emitter
    ) {
        self.config = config
        self.styles = styles
        self.styleEmitter = styleEmitter
    }

    /// Diagnostic header, with severity, code, and message.
    ///
    /// ```text
    /// error[E0001]: unexpected type in `+` application
    /// ```
    mutating func renderHeader<Output: TextOutputStream>(
        locus: Locus?,
        severity: Severity,
        code: String?,
        message: String,
        output: inout Output
    ) {
         // Write locus
        //
        // ```text
        // test:2:9:
        // ```
        if let locus = locus {
            snippetLocus(locus, output: &output)
            styleEmitter.write(": ", to: &output)
        }

        // Write severity name
        //
        // ```text
        // error
        // ```
        setHeader(severity: severity, output: &output)
        styleEmitter.write(severity.description, to: &output)

        // Write error code
        //
        // ```text
        // [E0001]
        // ```
        if let code = code, !code.isEmpty {
            styleEmitter.write("[\(code)]", to: &output)
        }

        // Write diagnostic message
        //
        // ```text
        // : unexpected type in `+` application
        // ```
        setHeaderMessage(output: &output)
        styleEmitter.write(": \(message)", to: &output)
        resetStyle(output: &output)

        renderEmpty(output: &output)
    }

    /// Render a single newline.
    func renderEmpty<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.write("\n", to: &output)
    }

    /// Render a single space.
    func renderSpace<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.write(" ", to: &output)
    }

    /// Top left border and locus.
    ///
    /// ```text
    /// ┌─ test:2:9
    /// ```
    mutating func renderSnippetStart<Output: TextOutputStream>(
        outerPadding: Int,
        locus: Locus,
        output: inout Output
    ) {
        outerGutter(
            outerPadding: outerPadding,
            output: &output
        )

        setSourceBorder(output: &output)
        styleEmitter.write(config.chars.snippetStart, to: &output)
        resetStyle(output: &output)

        renderSpace(output: &output)
        snippetLocus(locus, output: &output)

        renderEmpty(output: &output)
    }

    /// A line of source code.
    ///
    /// ```text
    /// 10 │   │ muffin. Halvah croissant candy canes bonbon candy. Apple pie jelly
    ///    │ ╭─│─────────^
    /// ```
    mutating func renderSnippetSource<Output: TextOutputStream>(
        outerPadding: Int,
        lineNumber: UInt,
        source: String,
        severity: Severity,
        singleLabels: [SingleLabel],
        numMultiLabels: UInt,
        multiLabels: [(UInt, LabelStyle, MultiLabel)],
        output: inout Output
    ) {
        // Trim trailing newlines, linefeeds, and null chars from source, if they exist.
        // FIXME: Use the number of trimmed placeholders when rendering single line carets
        let sourceLine = trimTrailing(source)


        // Write source line
        //
        // ```text
        // 10 │   │ muffin. Halvah croissant candy canes bonbon candy. Apple pie jelly
        // ```
        do {
            // Write outer gutter (with line number) and border
            outerGutterNumber(
                lineNumber: lineNumber,
                outerPadding: outerPadding,
                output: &output
            )
            borderLeft(output: &output)

            // Write inner gutter (with multi-line continuations on the left if necessary)
            var multiLabelsIterIndex = 0
            for labelColumn in 0..<numMultiLabels {
                if multiLabelsIterIndex < multiLabels.count,
                    multiLabels[multiLabelsIterIndex].0 == labelColumn
                {
                    let (_, labelStyle, label) = multiLabels[multiLabelsIterIndex]
                    switch label {
                        case .top(let start) where start <= leadingWhitespaceByteCount(sourceLine):
                            labelMultiTopLeft(
                                severity: severity,
                                labelStyle: labelStyle,
                                output: &output
                            )

                        case .top:
                            innerGutterSpace(output: &output)

                        case .left, .bottom:
                            labelMultiLeft(
                                severity: severity,
                                labelStyle: labelStyle,
                                underline: nil,
                                output: &output
                            )
                    }
                    multiLabelsIterIndex += 1
                } else {
                    innerGutterSpace(output: &output)
                }
            }

            // Write source text
            renderSpace(output: &output)
            var inPrimary = false
            for (metrics, scalar) in charMetrics(
                scalars: unicodeScalarIndices(in: sourceLine),
                tabWidth: config.tabWidth
            ) {
                let columnRange =
                    metrics.byteIndex..<(metrics.byteIndex + UInt(scalar.utf8.count))
                // Check if we are overlapping a primary label
                let isPrimary =
                    singleLabels.contains { label in
                        return label.labelStyle == .primary
                            && label.range.isOverlapping(other: columnRange)
                    }
                    || multiLabels.contains { entry in
                        let (_, style, label) = entry
                        guard style == .primary else { return false }
                        switch label {
                            case .top(let start):
                                return columnRange.lowerBound >= start

                            case .left:
                                return true

                            case .bottom(let start, _):
                                return columnRange.upperBound <= start
                        }
                    }

                // Set the source color if we are in a primary label
                if isPrimary && !inPrimary {
                    setLabel(
                        severity: severity,
                        labelStyle: .primary,
                        output: &output
                    )
                    inPrimary = true
                } else if !isPrimary && inPrimary {
                    resetStyle(output: &output)
                    inPrimary = false
                }

                if scalar == "\t" {
                    for _ in 0..<metrics.unicodeWidth {
                        renderSpace(output: &output)
                    }
                } else {
                    styleEmitter.write(String(scalar), to: &output)
                }
            }
            if inPrimary {
                resetStyle(output: &output)
            }
            renderEmpty(output: &output)
        }

        // Write single labels underneath source
        //
        // ```text
        //   │     - ---- ^^^ second mutable borrow occurs here
        //   │     │ │
        //   │     │ first mutable borrow occurs here
        //   │     first borrow later used by call
        //   │     help: some help here
        // ```
        if !singleLabels.isEmpty {
            // Our plan is as follows:
            //
            // 1. Do an initial scan to find:
            //    - The number of non-empty messages.
            //    - The right-most start and end positions of labels.
            //    - A candidate for a trailing label (where the label's message
            //      is printed to the left of the caret).
            // 2. Check if the trailing label candidate overlaps another label -
            //    if so we print it underneath the carets with the other labels.
            // 3. Print a line of carets, and (possibly) the trailing message
            //    to the left.
            // 4. Print vertical lines pointing to the carets, and the messages
            //    for those carets.
            //
            // We try our best avoid introducing new dynamic allocations,
            // instead preferring to iterate over the labels multiple times. It
            // is unclear what the performance tradeoffs are however, so further
            // investigation may be required.

            // The number of non-empty messages to print.
            var numMessages = 0
            // The right-most start position, eg:
            //
            // ```text
            // -^^^^---- ^^^^^^^
            //           │
            //           right-most start position
            // ```
            var maxLabelStart: UInt = 0
            // The right-most end position, eg:
            //
            // ```text
            // -^^^^---- ^^^^^^^
            //                 │
            //                 right-most end position
            // ```
            var maxLabelEnd: UInt = 0
            // A trailing message, eg:
            //
            // ```text
            // ^^^ second mutable borrow occurs here
            // ```
            var trailingLabel: (Int, SingleLabel)?

            for (index, label) in singleLabels.enumerated() {
                let range = label.range
                if !label.message.isEmpty {
                    numMessages += 1
                }

                maxLabelStart = max(maxLabelStart, range.lowerBound)
                maxLabelEnd = max(maxLabelEnd, range.upperBound)

                // This is a candidate for the trailing label, so let's record it.
                if range.upperBound == maxLabelEnd {
                    trailingLabel = label.message.isEmpty ? nil : (index, label)
                }
            }

            if let (trailingLabelIndex, trailingLabelSingleLabel) = trailingLabel {
                // Check to see if the trailing label candidate overlaps any of
                // the other labels on the current line.

                let trailingRange = trailingLabelSingleLabel.range
                let overlaps = singleLabels.enumerated()
                    .filter { $0.offset != trailingLabelIndex }
                    .contains { trailingRange.isOverlapping(other: $0.element.range) }

                // If it does, we'll instead want to render it below the
                // carets along with the other hanging labels.
                if overlaps {
                    trailingLabel = nil
                }
            }

            // Write a line of carets
            //
            // ```text
            //   │ ^^^^^^  -------^^^^^^^^^-------^^^^^----- ^^^^ trailing label message
            // ```
            outerGutter(
                outerPadding: outerPadding,
                output: &output
            )
            borderLeft(output: &output)
            innerGutter(
                severity: severity,
                numMultiLabels: numMultiLabels,
                multiLabels: multiLabels,
                output: &output
            )
            renderSpace(output: &output)

            var previousLabelStyle: LabelStyle? = nil
            let placeholder = Metrics(
                byteIndex: UInt(sourceLine.utf8.count),
                unicodeWidth: 1
            )
            var allMetrics = charMetrics(
                scalars: unicodeScalarIndices(in: sourceLine),
                tabWidth: config.tabWidth
            )
            // Add a placeholder source column at the end to allow for
            // printing carets at the end of lines, eg:
            //
            // ```text
            // 1 │ Hello world!
            //   │             ^
            // ```
            allMetrics.append((placeholder, "\0"))

            for (metrics, scalar) in allMetrics {
                // Find the current label style at this column
                let columnRange =
                    metrics.byteIndex..<(metrics.byteIndex + UInt(scalar.utf8.count))
                let currentLabelStyle =
                    singleLabels
                    .filter { $0.range.isOverlapping(other: columnRange) }
                    .map { $0.labelStyle }
                    .max(by: { labelPriorityKey($0) < labelPriorityKey($1) })

                // Update style if necessary
                if previousLabelStyle != currentLabelStyle {
                    if let current = currentLabelStyle {
                        setLabel(
                            severity: severity,
                            labelStyle: current,
                            output: &output
                        )
                    } else {
                        resetStyle(output: &output)
                    }
                    previousLabelStyle = currentLabelStyle
                }

                let caret: Character?
                switch currentLabelStyle {
                    case .primary?:
                        caret = config.chars.singlePrimaryCaret

                    case .secondary?:
                        caret = config.chars.singleSecondaryCaret

                    // Only print padding if we are before the end of the last single line caret
                    case nil where metrics.byteIndex < maxLabelEnd:
                        caret = " "

                    default:
                        caret = nil
                }

                if let caret = caret {
                    // FIXME: improve rendering of carets between character boundaries
                    for _ in 0..<metrics.unicodeWidth {
                        styleEmitter.write(String(caret), to: &output)
                    }
                }
            }

            // Reset style if it was previously set
            if previousLabelStyle != nil {
                resetStyle(output: &output)
            }

            // Write first trailing label message
            if let (_, trailingLabelSingleLabel) = trailingLabel {
                renderSpace(output: &output)
                setLabel(
                    severity: severity,
                    labelStyle: trailingLabelSingleLabel.labelStyle,
                    output: &output
                )
                styleEmitter.write(trailingLabelSingleLabel.message, to: &output)
                resetStyle(output: &output)
            }
            renderEmpty(output: &output)

            // Write hanging labels pointing to carets
            //
            // ```text
            //   │     │ │
            //   │     │ first mutable borrow occurs here
            //   │     first borrow later used by call
            //   │     help: some help here
            // ```
            if numMessages > (trailingLabel == nil ? 0 : 1) {
                // Write first set of vertical lines before hanging labels
                //
                // ```text
                //   │     │ │
                // ```
                outerGutter(
                    outerPadding: outerPadding,
                    output: &output
                )
                borderLeft(output: &output)
                innerGutter(
                    severity: severity,
                    numMultiLabels: numMultiLabels,
                    multiLabels: multiLabels,
                    output: &output
                )
                renderSpace(output: &output)
                caretPointers(
                    severity: severity,
                    maxLabelStart: maxLabelStart,
                    singleLabels: singleLabels,
                    trailingLabel: trailingLabel,
                    scalars: unicodeScalarIndices(in: sourceLine),
                    output: &output
                )
                renderEmpty(output: &output)

                // Write hanging labels pointing to carets
                //
                // ```text
                //   │     │ first mutable borrow occurs here
                //   │     first borrow later used by call
                //   │     help: some help here
                // ```
                for label in
                    hangingLabels(
                        singleLabels: singleLabels,
                        trailingLabel: trailingLabel
                    ).reversed()
                {
                    outerGutter(
                        outerPadding: outerPadding,
                        output: &output
                    )
                    borderLeft(output: &output)
                    innerGutter(
                        severity: severity,
                        numMultiLabels: numMultiLabels,
                        multiLabels: multiLabels,
                        output: &output
                    )
                    renderSpace(output: &output)
                    let until = unicodeScalarIndices(in: sourceLine)
                        .filter { $0.0 < label.range.lowerBound }
                    caretPointers(
                        severity: severity,
                        maxLabelStart: maxLabelStart,
                        singleLabels: singleLabels,
                        trailingLabel: trailingLabel,
                        scalars: until,
                        output: &output
                    )
                    setLabel(
                        severity: severity,
                        labelStyle: label.labelStyle,
                        output: &output
                    )
                    styleEmitter.write(label.message, to: &output)
                    resetStyle(output: &output)
                    renderEmpty(output: &output)
                }
            }
        }

        for (multiIndex, (_, labelStyle, label)) in multiLabels.enumerated() {
            let range: UInt
            let bottomMessage: String?
            switch label {
                case .left:
                    continue

                // no label caret needed if this can be started in front of the line
                case .top(let start):
                    let indent = leadingWhitespaceByteCount(sourceLine)
                    if start <= indent {
                        continue
                    }
                    range = start
                    bottomMessage = nil

                case .bottom(let end, let message):
                    range = end
                    bottomMessage = message
            }

            outerGutter(
                outerPadding: outerPadding,
                output: &output
            )
            borderLeft(output: &output)

            // Write inner gutter.
            //
            // ```text
            //  │ ╭─│───│
            // ```
            var underline: Underline? = nil
            var multiLabelsIter = multiLabels.enumerated().makeIterator()
            var next = multiLabelsIter.next()
            var labelColumn: UInt = 0
            while labelColumn < numMultiLabels {
                if let current = next, current.element.0 == labelColumn {
                    let (_, style, label) = current.element
                    switch label {
                        case .left:
                            labelMultiLeft(
                                severity: severity,
                                labelStyle: style,
                                underline: underline?.labelStyle,
                                output: &output
                            )

                        case .top where multiIndex > current.offset:
                            labelMultiLeft(
                                severity: severity,
                                labelStyle: style,
                                underline: underline?.labelStyle,
                                output: &output
                            )

                        case .bottom where multiIndex < current.offset:
                            labelMultiLeft(
                                severity: severity,
                                labelStyle: style,
                                underline: underline?.labelStyle,
                                output: &output
                            )

                        case .top where multiIndex == current.offset:
                            underline = Underline(
                                labelStyle: style,
                                verticalBound: .top
                            )
                            labelMultiTopLeft(
                                severity: severity,
                                labelStyle: labelStyle,
                                output: &output
                            )

                        case .bottom where multiIndex == current.offset:
                            underline = Underline(
                                labelStyle: style,
                                verticalBound: .bottom
                            )
                            labelMultiBottomLeft(
                                severity: severity,
                                labelStyle: labelStyle,
                                output: &output
                            )

                        case .top, .bottom:
                            innerGutterColumn(
                                severity: severity,
                                underline: underline,
                                output: &output
                            )
                    }
                    next = multiLabelsIter.next()
                } else {
                    innerGutterColumn(
                        severity: severity,
                        underline: underline,
                        output: &output
                    )
                }
                labelColumn += 1
            }

            // Finish the top or bottom caret
            if let message = bottomMessage {
                labelMultiBottomCaret(
                    severity: severity,
                    labelStyle: labelStyle,
                    source: sourceLine,
                    start: range,
                    message: message,
                    output: &output
                )
            } else {
                labelMultiTopCaret(
                    severity: severity,
                    labelStyle: labelStyle,
                    source: sourceLine,
                    start: range,
                    output: &output
                )
            }
        }
    }

    /// An empty source line, for providing additional whitespace to source snippets.
    ///
    /// ```text
    /// │ │ │
    /// ```
    mutating func renderSnippetEmpty<Output: TextOutputStream>(
        outerPadding: Int,
        severity: Severity,
        numMultiLabels: UInt,
        multiLabels: [(UInt, LabelStyle, MultiLabel)],
        output: inout Output
    ) {
        outerGutter(
            outerPadding: outerPadding,
            output: &output
        )
        borderLeft(output: &output)
        innerGutter(
            severity: severity,
            numMultiLabels: numMultiLabels,
            multiLabels: multiLabels,
            output: &output
        )
        renderEmpty(output: &output)
    }

    /// A broken source line, for labeling skipped sections of source.
    ///
    /// ```text
    /// · │ │
    /// ```
    mutating func renderSnippetBreak<Output: TextOutputStream>(
        outerPadding: Int,
        severity: Severity,
        numMultiLabels: UInt,
        multiLabels: [(UInt, LabelStyle, MultiLabel)],
        output: inout Output
    ) {
        outerGutter(
            outerPadding: outerPadding,
            output: &output
        )
        borderLeftBreak(output: &output)
        innerGutter(
            severity: severity,
            numMultiLabels: numMultiLabels,
            multiLabels: multiLabels,
            output: &output
        )
        renderEmpty(output: &output)
    }

    /// Additional notes.
    ///
    /// ```text
    /// = expected type `Int`
    ///      found type `String`
    /// ```
    mutating func renderSnippetNote<Output: TextOutputStream>(
        outerPadding: Int,
        message: String,
        output: inout Output
    ) {
        let lines = message.split(
            separator: "\n",
            omittingEmptySubsequences: false
        )
        for (index, line) in lines.enumerated() {
            outerGutter(
                outerPadding: outerPadding,
                output: &output
            )
            if index == 0 {
                setNoteBullet(output: &output)
                styleEmitter.write(String(config.chars.noteBullet), to: &output)
                resetStyle(output: &output)
            } else {
                renderSpace(output: &output)
            }
            // Write line of message
            renderSpace(output: &output)
            styleEmitter.write(String(line), to: &output)
            renderEmpty(output: &output)
        }
    }

    private mutating func setHeader<Output: TextOutputStream>(
        severity: Severity,
        output: inout Output
    ) {
        styleEmitter.setHeader(
            severity: severity,
            style: styles.header(severity),
            output: &output
        )
    }

    private mutating func setHeaderMessage<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.setHeaderMessage(
            style: styles.headerMessage,
            output: &output
        )
    }

    private mutating func setLineNumber<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.setLineNumber(
            style: styles.lineNumber,
            output: &output
        )
    }

    private mutating func setNoteBullet<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.setNoteBullet(
            style: styles.noteBullet,
            output: &output
        )
    }

    private mutating func setSourceBorder<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.setSourceBorder(
            style: styles.sourceBorder,
            output: &output
        )
    }

    private mutating func setLabel<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        output: inout Output
    ) {
        styleEmitter.setLabel(
            severity: severity,
            labelStyle: labelStyle,
            style: styles.label(severity, labelStyle),
            output: &output
        )
    }

    private mutating func resetStyle<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.reset(output: &output)
    }

    /// Location focus.
    private mutating func snippetLocus<Output: TextOutputStream>(
        _ locus: Locus,
        output: inout Output
    ) {
        styleEmitter.write("\(locus.name):\(locus.location.lineNumber):\(locus.location.columnNumber)", to: &output)
    }

    /// The outer gutter of a source line.
    private mutating func outerGutter<Output: TextOutputStream>(
        outerPadding: Int,
        output: inout Output
    ) {
        if outerPadding > 0 {
            styleEmitter.write(String(repeating: " ", count: outerPadding), to: &output)
        }
        renderSpace(output: &output)
    }

    /// The outer gutter of a source line, with line number.
    private mutating func outerGutterNumber<Output: TextOutputStream>(
        lineNumber: UInt,
        outerPadding: Int,
        output: inout Output
    ) {
        let number = String(lineNumber)
        let padding = max(0, outerPadding - number.count)
        setLineNumber(output: &output)
        if padding > 0 {
            styleEmitter.write(String(repeating: " ", count: padding), to: &output)
        }
        styleEmitter.write(number, to: &output)
        resetStyle(output: &output)
        renderSpace(output: &output)
    }

    /// The left-hand border of a source line.
    private mutating func borderLeft<Output: TextOutputStream>(output: inout Output) {
        setSourceBorder(output: &output)
        styleEmitter.write(String(config.chars.sourceBorderLeft), to: &output)
        resetStyle(output: &output)
    }

    /// The broken left-hand border of a source line.
    private mutating func borderLeftBreak<Output: TextOutputStream>(output: inout Output) {
        setSourceBorder(output: &output)
        styleEmitter.write(String(config.chars.sourceBorderLeftBreak), to: &output)
        resetStyle(output: &output)
    }

    /// Write vertical lines pointing to carets.
    private mutating func caretPointers<Output: TextOutputStream>(
        severity: Severity,
        maxLabelStart: UInt,
        singleLabels: [SingleLabel],
        trailingLabel: (Int, SingleLabel)?,
        scalars: [(UInt, UnicodeScalar)],
        output: inout Output
    ) {
        for (metrics, scalar) in charMetrics(
            scalars: scalars,
            tabWidth: config.tabWidth
        ) {
            let length = UInt(scalar.utf8.count)
            let columnRange = metrics.byteIndex..<(metrics.byteIndex + length)
            let labelStyle = hangingLabels(singleLabels: singleLabels, trailingLabel: trailingLabel)
                .filter { columnRange.contains($0.range.lowerBound) }
                .map { $0.labelStyle }
                .max(by: { labelPriorityKey($0) < labelPriorityKey($1) })

            if let labelStyle = labelStyle {
                setLabel(
                    severity: severity,
                    labelStyle: labelStyle,
                    output: &output
                )
                styleEmitter.write(String(config.chars.pointerLeft), to: &output)
                resetStyle(output: &output)
                let remaining = Int(metrics.unicodeWidth) - 1
                // Only print padding if we are before the end of the last single line caret
                if metrics.byteIndex <= maxLabelStart, remaining > 0 {
                    styleEmitter.write(String(repeating: " ", count: remaining), to: &output)
                }
            } else {
                // Only print padding if we are before the end of the last single line caret
                if metrics.byteIndex <= maxLabelStart {
                    styleEmitter.write(String(repeating: " ", count: Int(metrics.unicodeWidth)), to: &output)
                }
            }
        }
    }

    /// The left of a multi-line label.
    ///
    /// ```text
    ///  │
    /// ```
    private mutating func labelMultiLeft<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        underline: LabelStyle?,
        output: inout Output
    ) {
        if let underline = underline {
            // Continue an underline horizontally
            setLabel(
                severity: severity,
                labelStyle: underline,
                output: &output
            )
            styleEmitter.write(String(config.chars.multiTop), to: &output)
            resetStyle(output: &output)
        } else {
            renderSpace(output: &output)
        }
        setLabel(
            severity: severity,
            labelStyle: labelStyle,
            output: &output
        )
        styleEmitter.write(String(config.chars.multiLeft), to: &output)
        resetStyle(output: &output)
    }

    /// The top-left of a multi-line label.
    ///
    /// ```text
    ///  ╭
    /// ```
    private mutating func labelMultiTopLeft<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        output: inout Output
    ) {
        renderSpace(output: &output)
        setLabel(
            severity: severity,
            labelStyle: labelStyle,
            output: &output
        )
        styleEmitter.write(String(config.chars.multiTopLeft), to: &output)
        resetStyle(output: &output)
    }

    /// The bottom left of a multi-line label.
    ///
    /// ```text
    ///  ╰
    /// ```
    private mutating func labelMultiBottomLeft<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        output: inout Output
    ) {
        renderSpace(output: &output)
        setLabel(
            severity: severity,
            labelStyle: labelStyle,
            output: &output
        )
        styleEmitter.write(String(config.chars.multiBottomLeft), to: &output)
        resetStyle(output: &output)
    }

    /// Multi-line label top.
    ///
    /// ```text
    /// ─────────────^
    /// ```
    private mutating func labelMultiTopCaret<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        source: String,
        start: UInt,
        output: inout Output
    ) {
        setLabel(
            severity: severity,
            labelStyle: labelStyle,
            output: &output
        )
        let limit = start == UInt.max ? start : start + 1
        for (metrics, _) in charMetrics(
            scalars: unicodeScalarIndices(in: source),
            tabWidth: config.tabWidth
        ) {
            if metrics.byteIndex >= limit {
                break
            }
            // FIXME: improve rendering of carets between character boundaries
            for _ in 0..<metrics.unicodeWidth {
                styleEmitter.write(String(config.chars.multiTop), to: &output)
            }
        }
        let caret =
            labelStyle == .primary
            ? config.chars.multiPrimaryCaretStart
            : config.chars.multiSecondaryCaretStart
        styleEmitter.write(String(caret), to: &output)
        resetStyle(output: &output)
        renderEmpty(output: &output)
    }

    /// Multi-line label bottom, with a message.
    ///
    /// ```text
    /// ─────────────^ expected `Int` but found `String`
    /// ```
    private mutating func labelMultiBottomCaret<Output: TextOutputStream>(
        severity: Severity,
        labelStyle: LabelStyle,
        source: String,
        start: UInt,
        message: String,
        output: inout Output
    ) {
        setLabel(
            severity: severity,
            labelStyle: labelStyle,
            output: &output
        )
        for (metrics, _) in charMetrics(
            scalars: unicodeScalarIndices(in: source),
            tabWidth: config.tabWidth
        ) {
            if metrics.byteIndex >= start {
                break
            }
            // FIXME: improve rendering of carets between character boundaries
            for _ in 0..<metrics.unicodeWidth {
                styleEmitter.write(String(config.chars.multiBottom), to: &output)
            }
        }
        let caret =
            labelStyle == .primary
            ? config.chars.multiPrimaryCaretStart
            : config.chars.multiSecondaryCaretStart
        styleEmitter.write(String(caret), to: &output)
        if !message.isEmpty {
            styleEmitter.write(" \(message)", to: &output)
        }
        resetStyle(output: &output)
        renderEmpty(output: &output)
    }

    /// Writes an empty gutter space, or continues an underline horizontally.
    private mutating func innerGutterColumn<Output: TextOutputStream>(
        severity: Severity,
        underline: Underline?,
        output: inout Output
    ) {
        if let underline = underline {
            let ch =
                underline.verticalBound == .top
                ? config.chars.multiTop
                : config.chars.multiBottom
            setLabel(
                severity: severity,
                labelStyle: underline.labelStyle,
                output: &output
            )
            styleEmitter.write(String(ch), to: &output)
            styleEmitter.write(String(ch), to: &output)
            resetStyle(output: &output)
        } else {
            innerGutterSpace(output: &output)
        }
    }

    /// Writes an empty gutter space.
    private mutating func innerGutterSpace<Output: TextOutputStream>(output: inout Output) {
        styleEmitter.write("  ", to: &output)
    }

    /// Writes an inner gutter, with the left lines if necessary.
    private mutating func innerGutter<Output: TextOutputStream>(
        severity: Severity,
        numMultiLabels: UInt,
        multiLabels: [(UInt, LabelStyle, MultiLabel)],
        output: inout Output
    ) {
        var iterIndex = 0
        var labelColumn: UInt = 0
        while labelColumn < numMultiLabels {
            if iterIndex < multiLabels.count, multiLabels[iterIndex].0 == labelColumn {
                let (_, style, label) = multiLabels[iterIndex]
                switch label {
                    case .left, .bottom:
                        labelMultiLeft(
                            severity: severity,
                            labelStyle: style,
                            underline: nil,
                            output: &output
                        )
                    case .top:
                        innerGutterSpace(output: &output)
                }
                iterIndex += 1
            } else {
                innerGutterSpace(output: &output)
            }
            labelColumn += 1
        }
    }
}

private func leadingWhitespaceByteCount(_ string: String) -> UInt {
    var count: UInt = 0
    for scalar in string.unicodeScalars {
        if scalar == " " || scalar == "\t" {
            count += UInt(scalar.utf8.count)
        } else {
            break
        }
    }
    return count
}

private func trimTrailing(_ string: String) -> String {
    var result = string
    while let last = result.last,
        last == "\n" || last == "\r" || last == "\0"
    {
        result.removeLast()
    }
    return result
}

private func unicodeWidth(of scalar: UnicodeScalar) -> UInt {
    let value = scalar.value
    if value == 0 || value < 0x20 || (0x7F...0x9F).contains(value) {
        return 0
    }

    let properties = scalar.properties
    switch properties.generalCategory {
        case .nonspacingMark, .enclosingMark, .format:
            return 0
        default:
            break
    }

    if properties.isEmojiPresentation {
        return 2
    }

    if isWideScalar(value) {
        return 2
    }

    return 1
}

private func isWideScalar(_ value: UInt32) -> Bool {
    switch value {
        case 0x1100...0x115F,
            0x2329...0x232A,
            0x2E80...0xA4CF,
            0xAC00...0xD7A3,
            0xF900...0xFAFF,
            0xFE10...0xFE19,
            0xFE30...0xFE6F,
            0xFF01...0xFF60,
            0xFFE0...0xFFE6,
            0x1F300...0x1F64F,
            0x1F900...0x1F9FF,
            0x20000...0x2FFFD,
            0x30000...0x3FFFD:
            return true
        default:
            return false
    }
}

/// Adds tab-stop aware unicode-width computations to an iterator over
/// character indices. Assumes that the character indices begin at the start
/// of the line.
private func charMetrics(
    scalars: [(UInt, UnicodeScalar)],
    tabWidth: UInt = 0
) -> [(Metrics, UnicodeScalar)] {
    let effectiveTabWidth = tabWidth
    var unicodeColumn: UInt = 0
    return scalars.map { entry in
        let (byteIndex, scalar) = entry
        let width: UInt
        if scalar == "\t" {
            // Guard divide-by-zero
            if effectiveTabWidth == 0 {
                width = 0
            } else {
                width = effectiveTabWidth - (unicodeColumn % effectiveTabWidth)
            }
        } else {
            width = unicodeWidth(of: scalar)
        }
        let metrics = Metrics(
            byteIndex: byteIndex,
            unicodeWidth: width
        )
        unicodeColumn += width
        return (metrics, scalar)
    }
}

private func unicodeScalarIndices(in source: String) -> [(UInt, UnicodeScalar)] {
    var indices: [(UInt, UnicodeScalar)] = []
    var offset: UInt = 0
    for scalar in source.unicodeScalars {
        indices.append((offset, scalar))
        offset += UInt(scalar.utf8.count)
    }
    return indices
}

private func labelPriorityKey(_ style: LabelStyle) -> UInt8 {
    switch style {
        case .secondary:
            return 0

        case .primary:
            return 1
    }
}

private func hangingLabels(
    singleLabels: [SingleLabel],
    trailingLabel: (Int, SingleLabel)?
) -> [SingleLabel] {
    return singleLabels
        .enumerated()
        .filter { index, label in
            return !label.message.isEmpty
                && (trailingLabel == nil || trailingLabel?.0 != index)
        }
        .map { $0.element }
}
