private struct Line {
    var number: UInt
    var range: Range<UInt>
    var singleLabels: [SingleLabel]
    var multiLabels: [(UInt, LabelStyle, MultiLabel)]
    var mustRender: Bool
}

private struct LabeledFile<FileId: Equatable> {
    var fileId: FileId
    var start: UInt
    var name: String
    var location: Location
    var numMultiLabels: UInt
    var lines: [UInt: Line]
    var maxLabelStyle: LabelStyle

    mutating func updateLine(
        lineIndex: UInt,
        lineRange: Range<UInt>,
        lineNumber: UInt,
        update: (inout Line) -> Void
    ) {
        var line = lines[lineIndex]
            ?? Line(
                number: lineNumber,
                range: lineRange,
                singleLabels: [],
                multiLabels: [],
                // This has to be false by default so we know if it must be rendered by another condition already.
                mustRender: false
            )
        update(&line)
        lines[lineIndex] = line
    }
}

/// Calculate the number of decimal digits in `n`.
private func countDigits(_ number: UInt) -> Int {
    if number == 0 {
        return 1
    }

    var count = 0
    var value = number

    while value > 0 {
        count += 1
        value /= 10
    }

    return count
}

private func insertionIndex(for range: Range<UInt>, in labels: [SingleLabel]) -> Int {
    var index = 0

    while index < labels.count {
        let existing = labels[index].range

        if existing.lowerBound > range.lowerBound {
            break
        }

        if existing.lowerBound == range.lowerBound
            && existing.upperBound >= range.upperBound
        {
            break
        }

        index += 1
    }

    return index
}

private func slice<Source: StringProtocol>(source: Source, range: Range<UInt>) throws -> String {
    let length = UInt(source.utf8.count)
    if range.lowerBound > length || range.upperBound > length {
        let maxIndex = length > 0 ? length - 1 : 0
        let given = Swift.max(range.lowerBound, range.upperBound)
        throw FilesError.indexTooLarge(given: given, max: maxIndex)
    }

    guard let startIndex = source.index(atUTF8Offset: range.lowerBound) else {
        throw FilesError.invalidCharBoundary(given: range.lowerBound)
    }
    guard let endIndex = source.index(atUTF8Offset: range.upperBound) else {
        throw FilesError.invalidCharBoundary(given: range.upperBound)
    }

    return String(source[startIndex..<endIndex])
}

struct RichDiagnosticView<FileId: Equatable> {
    var diagnostic: Diagnostic<FileId>
    var config: Config

    init(
        diagnostic: Diagnostic<FileId>,
        config: Config
    ) {
        self.diagnostic = diagnostic
        self.config = config
    }

    func render<Files: FilesProtocol, Output: TextOutputStream, Emitter: StyleEmitter>(
        files: Files,
        styles: Styles,
        renderer: inout Renderer<Emitter>,
        output: inout Output
    ) throws where Files.FileId == FileId, Files.Source: StringProtocol {

        var labeledFiles: [LabeledFile<FileId>] = []
        // Keep track of the outer padding to use when rendering the snippets of source code.
        var outerPadding = 0

        // Group labels by file
        for label in diagnostic.labels {
            let startLineIndex = try files.lineIndex(of: label.fileId, at: label.range.lowerBound)
            let startLineNumber = try files.lineNumber(of: label.fileId, lineIndex: startLineIndex)
            let startLineRange = try files.lineRange(of: label.fileId, lineIndex: startLineIndex)
            let endLineIndex = try files.lineIndex(of: label.fileId, at: label.range.upperBound)
            let endLineNumber = try files.lineNumber(of: label.fileId, lineIndex: endLineIndex)
            let endLineRange = try files.lineRange(of: label.fileId, lineIndex: endLineIndex)

            outerPadding = max(outerPadding, countDigits(startLineNumber))
            outerPadding = max(outerPadding, countDigits(endLineNumber))

            // NOTE: This could be made more efficient by using an associative
            // data structure like a hashmap or B-tree, but we use an array to
            // preserve the order that unique files appear in the list of labels.
            let currentIndex: Int
            if let index = labeledFiles.firstIndex(where: { $0.fileId == label.fileId }) {
                // another diagnostic also referenced this file
                currentIndex = index
                if labeledFiles[currentIndex].maxLabelStyle > label.style
                    || (labeledFiles[currentIndex].maxLabelStyle == label.style
                        && labeledFiles[currentIndex].start > label.range.lowerBound)
                {
                    // this label has a higher style or has the same style but starts earlier
                    labeledFiles[currentIndex].start = label.range.lowerBound
                    labeledFiles[currentIndex].location = try files.location(
                        of: label.fileId,
                        at: label.range.lowerBound
                    )
                    labeledFiles[currentIndex].maxLabelStyle = label.style
                }
            } else {
                // no other diagnostic referenced this file yet
                let name = try files.name(of: label.fileId).description
                let location = try files.location(of: label.fileId, at: label.range.lowerBound)
                labeledFiles.append(
                    LabeledFile(
                        fileId: label.fileId,
                        start: label.range.lowerBound,
                        name: name,
                        location: location,
                        numMultiLabels: 0,
                        lines: [:],
                        maxLabelStyle: label.style
                    )
                )
                // use the index of the just pushed element
                currentIndex = labeledFiles.count - 1
            }

            // insert context lines before label
            if config.beforeLabelLines > 0 {
                // start from 1 because 0 would be the start of the label itself
                for offset in 1...config.beforeLabelLines {
                    if startLineIndex < offset {
                        // we are going from smallest to largest offset,
                        // so if the offset can not be subtracted from the start
                        // then we reached the first line
                        break
                    }
                    let index = startLineIndex - offset
                    if let range = try? files.lineRange(of: label.fileId, lineIndex: index) {
                        let number = startLineNumber - offset
                        labeledFiles[currentIndex].updateLine(
                            lineIndex: index,
                            lineRange: range,
                            lineNumber: number
                        ) { line in
                            line.mustRender = true
                        }
                    } else {
                        break
                    }
                }
            }

            // insert context lines after label
            if config.afterLabelLines > 0 {
                // start from 1 because 0 would be the end of the label itself
                for offset in 1...config.afterLabelLines {
                    let index = endLineIndex + offset
                    if let range = try? files.lineRange(of: label.fileId, lineIndex: index) {
                        let number = endLineNumber + offset
                        labeledFiles[currentIndex].updateLine(
                            lineIndex: index,
                            lineRange: range,
                            lineNumber: number
                        ) { line in
                            line.mustRender = true
                        }
                    } else {
                        break
                    }
                }
            }

            if startLineIndex == endLineIndex {
                // Single line
                //
                // ```text
                // 2 │ (+ test "")
                //   │         ^^ expected `Int` but found `String`
                // ```

                let labelStart = label.range.lowerBound - startLineRange.lowerBound
                // Ensure that we print at least one caret, even when we
                // have a zero-length source range.
                let labelEnd = max(
                    label.range.upperBound - startLineRange.lowerBound,
                    labelStart + 1
                )

                labeledFiles[currentIndex].updateLine(
                    lineIndex: startLineIndex,
                    lineRange: startLineRange,
                    lineNumber: startLineNumber
                ) { line in
                    // Ensure that the single line labels are lexicographically
                    // sorted by the range of source code that they cover.
                    let insertIndex = insertionIndex(
                        for: labelStart..<labelEnd,
                        in: line.singleLabels
                    )
                    line.singleLabels.insert(
                        SingleLabel(
                            labelStyle: label.style,
                            range: labelStart..<labelEnd,
                            message: label.message
                        ),
                        at: insertIndex
                    )
                    // If this line is not rendered, the SingleLabel is not visible.
                    line.mustRender = true
                }
            } else {
                // Multiple lines
                //
                // ```text
                // 4 │   fizz₁ num = case (mod num 5) (mod num 3) of
                //   │ ╭─────────────^
                // 5 │ │     0 0 => "FizzBuzz"
                // 6 │ │     0 _ => "Fizz"
                // 7 │ │     _ 0 => "Buzz"
                // 8 │ │     _ _ => num
                //   │ ╰──────────────^ `case` clauses have incompatible types
                // ```

                let labelIndex = labeledFiles[currentIndex].numMultiLabels
                labeledFiles[currentIndex].numMultiLabels += 1

                let labelStart = label.range.lowerBound - startLineRange.lowerBound
                labeledFiles[currentIndex].updateLine(
                    lineIndex: startLineIndex,
                    lineRange: startLineRange,
                    lineNumber: startLineNumber
                ) { startLine in
                    startLine.multiLabels.append(
                        (
                            labelIndex,
                            label.style,
                            .top(labelStart: labelStart)
                        )
                    )
                    // The first line has to be rendered so the start of the label is visible.
                    startLine.mustRender = true
                }

                if startLineIndex + 1 < endLineIndex {
                    for lineIndex in (startLineIndex + 1)..<endLineIndex {
                        let lineRange = try files.lineRange(of: label.fileId, lineIndex: lineIndex)
                        let lineNumber = try files.lineNumber(of: label.fileId, lineIndex: lineIndex)

                        outerPadding = max(outerPadding, countDigits(lineNumber))

                        labeledFiles[currentIndex].updateLine(
                            lineIndex: lineIndex,
                            lineRange: lineRange,
                            lineNumber: lineNumber
                        ) { line in
                            line.multiLabels.append((labelIndex, label.style, .left))
                            // The line should be rendered to match the configuration of how much context to show.
                            line.mustRender =
                                line.mustRender
                                // Is this line part of the context after the start of the label?
                                || (lineIndex - startLineIndex <= config.startContextLines)
                                // Is this line part of the context before the end of the label?
                                || (endLineIndex - lineIndex <= config.endContextLines)
                        }
                    }
                }

                // Last labeled line
                //
                // ```text
                // 8 │ │     _ _ => num
                //   │ ╰──────────────^ `case` clauses have incompatible types
                // ```
                let labelEnd = label.range.upperBound - endLineRange.lowerBound

                labeledFiles[currentIndex].updateLine(
                    lineIndex: endLineIndex,
                    lineRange: endLineRange,
                    lineNumber: endLineNumber
                ) { line in
                    line.multiLabels.append(
                        (
                            labelIndex,
                            label.style,
                            .bottom(labelEnd: labelEnd, message: label.message)
                        )
                    )
                    // The last line has to be rendered so the end of the label is visible.
                    line.mustRender = true
                }
            }
        }

        // Header and message
        //
        // ```text
        // error[E0001]: unexpected type in `+` application
        // ```
        renderer.renderHeader(
            locus: nil,
            severity: diagnostic.severity,
            code: diagnostic.code,
            message: diagnostic.message,
            output: &output
        )

        // Source snippets
        //
        // ```text
        //   ┌─ test:2:9
        //   │
        // 2 │ (+ test "")
        //   │         ^^ expected `Int` but found `String`
        //   │
        // ```
        for (labeledFileIndex, labeledFile) in labeledFiles.enumerated() {
            let source = try files.source(of: labeledFile.fileId)

            // Top left border and locus.
            //
            // ```text
            // ┌─ test:2:9
            // ```
            if !labeledFile.lines.isEmpty {
                renderer.renderSnippetStart(
                    outerPadding: outerPadding,
                    locus: Locus(name: labeledFile.name, location: labeledFile.location),
                    output: &output
                )
                renderer.renderSnippetEmpty(
                    outerPadding: outerPadding,
                    severity: diagnostic.severity,
                    numMultiLabels: labeledFile.numMultiLabels,
                    multiLabels: [],
                    output: &output
                )
            }

            let renderedLines = labeledFile.lines
                .filter { $0.value.mustRender }
                .sorted(by: { $0.key < $1.key })

            for (renderedLineIndex, (lineIndex, line)) in renderedLines.enumerated() {
                let lineSource = try slice(source: source, range: line.range)

                renderer.renderSnippetSource(
                    outerPadding: outerPadding,
                    lineNumber: line.number,
                    source: lineSource,
                    severity: diagnostic.severity,
                    singleLabels: line.singleLabels,
                    numMultiLabels: labeledFile.numMultiLabels,
                    multiLabels: line.multiLabels,
                    output: &output
                )

                // Check to see if we need to render any intermediate stuff
                // before rendering the next line.
                if renderedLineIndex + 1 < renderedLines.count {
                    let (nextLineIndex, nextLine) = renderedLines[renderedLineIndex + 1]
                    let diff = nextLineIndex >= lineIndex ? nextLineIndex - lineIndex : 0

                    // diff == 1: Consecutive lines

                    if diff == 2 {
                        // Write a source line

                        // This line was not intended to be rendered initially.
                        // To render the line right, we have to get back the original labels.

                        let fileId = labeledFile.fileId
                        let labels = labeledFile.lines[lineIndex + 1]?.multiLabels ?? []
                        let middleNumber = try files.lineNumber(
                            of: fileId,
                            lineIndex: lineIndex + 1
                        )
                        let middleSource = try slice(
                            source: source,
                            range: try files.lineRange(of: fileId, lineIndex: lineIndex + 1)
                        )
                        renderer.renderSnippetSource(
                            outerPadding: outerPadding,
                            lineNumber: middleNumber,
                            source: middleSource,
                            severity: diagnostic.severity,
                            singleLabels: [],
                            numMultiLabels: labeledFile.numMultiLabels,
                            multiLabels: labels,
                            output: &output
                        )
                    } else if diff > 2 {
                        // More than one line between the current line and the next line.

                        // Source break
                        //
                        // ```text
                        // ·
                        // ```
                        renderer.renderSnippetBreak(
                            outerPadding: outerPadding,
                            severity: diagnostic.severity,
                            numMultiLabels: labeledFile.numMultiLabels,
                            multiLabels: nextLine.multiLabels,
                            output: &output
                        )
                    }
                }
            }

            // Check to see if we should render a trailing border after the
            // final line of the snippet.
            if labeledFileIndex == labeledFiles.count - 1 && diagnostic.notes.isEmpty {
                // We don't render a border if we are at the final newline
                // without trailing notes, because it would end up looking too
                // spaced-out in combination with the final new line.
            } else {
                // Render the trailing snippet border.
                renderer.renderSnippetEmpty(
                    outerPadding: outerPadding,
                    severity: diagnostic.severity,
                    numMultiLabels: labeledFile.numMultiLabels,
                    multiLabels: [],
                    output: &output
                )
            }
        }

        // Additional notes
        //
        // ```text
        // = expected type `Int`
        //      found type `String`
        // ```
        for note in diagnostic.notes {
            renderer.renderSnippetNote(outerPadding: outerPadding, message: note, output: &output)
        }

        renderer.renderEmpty(output: &output)
    }
}
