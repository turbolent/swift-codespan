
/// An enum representing an error that happened while looking up a file
/// or a piece of content in that file.
public enum FilesError: Error {

    /// A required file is not in the file database.
    case fileMissing

    /// The file is present, but does not contain the specified byte index.
    case indexTooLarge(given: UInt, max: UInt)

    /// The file is present, but does not contain the specified line index.
    case lineTooLarge(given: UInt, max: UInt)

    /// The file is present and contains the specified line index,
    /// but the line does not contain the specified column index.
    case columnTooLarge(given: UInt, max: UInt)

    /// The given index is contained in the file, but is not a boundary of a UTF-8 code point.
    case invalidCharBoundary(given: UInt)

    /// There was a error during formatting.
    case formatError
}

/// A minimal interface for accessing source files when rendering diagnostics.
public protocol FilesProtocol {

    /// A unique identifier for files in the file provider.
    /// This will be used for rendering `Label`s in the corresponding source files.
    associatedtype FileId: Equatable

    /// The user-facing name of a file, to be displayed in diagnostics.
    associatedtype Name: CustomStringConvertible

    /// The source code of a file.
    associatedtype Source

    /// The user-facing name of a file.
    func name(of fileId: FileId) throws -> Name

    /// The source code of a file.
    func source(of fileId: FileId) throws -> Source

    /// The index of the line at the given byte index.
    /// If the byte index is past the end of the file, returns the maximum line index in the file.
    /// This means that this function only fails if the file is not present.
    ///
    /// # Note for trait implementors
    ///
    /// This can be implemented efficiently by performing a binary search over
    /// a list of line starts that was computed by calling the `lineStarts` function.
    /// It might be useful to pre-compute and cache these line starts.
    ///
    func lineIndex(of fileId: FileId, at byteIndex: UInt) throws -> UInt

    /// The user-facing line number at the given line index.
    /// It is not necessarily checked that the specified line index
    /// is actually in the file.
    ///
    /// # Note for trait implementors
    ///
    /// This is usually 1-indexed from the beginning of the file,
    /// but can be useful for implementing something like the
    /// [C preprocessor's `#line` macro][line-macro].
    ///
    /// [line-macro]: https://en.cppreference.com/w/c/preprocessor/line
    func lineNumber(of fileId: FileId, lineIndex: UInt) throws -> UInt

    /// The user-facing column number at the given line index and byte index.
    ///
    /// # Note for trait implementors
    ///
    /// This is usually 1-indexed from the the start of the line.
    /// A default implementation is provided when `Source: StringProtocol`,
    /// based on the `columnIndex` function.
    ///
    func columnNumber(of fileId: FileId, lineIndex: UInt, byteIndex: UInt) throws -> UInt

    /// The byte range of line in the source of the file.
    func lineRange(of fileId: FileId, lineIndex: UInt) throws -> Range<UInt>
}

public extension FilesProtocol {
    func lineNumber(of fileId: FileId, lineIndex: UInt) throws -> UInt {
        lineIndex + 1
    }

    /// Convenience method for returning line and column number at the given byte index in the file.
    func location(of fileId: FileId, at byteIndex: UInt) throws -> Location {
        let lineIndex = try lineIndex(of: fileId, at: byteIndex)
        return Location(
            lineNumber: try lineNumber(
                of: fileId,
                lineIndex: lineIndex
            ),
            columnNumber: try columnNumber(
                of: fileId,
                lineIndex: lineIndex,
                byteIndex: byteIndex
            )
        )
    }
}

public extension FilesProtocol where Source: StringProtocol {
    func columnNumber(of fileId: FileId, lineIndex: UInt, byteIndex: UInt) throws -> UInt {
        let sourceString = try source(of: fileId)
        let lineRange = try lineRange(of: fileId, lineIndex: lineIndex)
        let columnIndex = columnIndex(
            in: sourceString,
            lineRange: lineRange,
            byteIndex: byteIndex
        )
        return columnIndex + 1
    }
}

/// The column index at the given byte index in the source file.
/// This is the number of characters to the given byte index.
///
/// If the byte index is smaller than the start of the line, then `0` is returned.
/// If the byte index is past the end of the line, the column index of the last
/// character `+ 1` is returned.
///
public func columnIndex<Source: StringProtocol>(
    in source: Source,
    lineRange: Range<UInt>,
    byteIndex: UInt
) -> UInt {
    let sourceLength = UInt(source.utf8.count)
    let endIndex = min(byteIndex, min(lineRange.upperBound, sourceLength))

    if lineRange.lowerBound >= endIndex {
        return 0
    }

    var count: UInt = 0
    var index = lineRange.lowerBound
    while index < endIndex {
        if source.index(atUTF8Offset: index + 1) != nil {
            count += 1
        }
        index += 1
    }
    return count
}

/// Return the starting byte index of each line in the source string.
///
/// This can make it easier to implement `FilesProtocol.lineIndex` by allowing
/// implementors of `FilesProtocol` to pre-compute the line starts,
/// then search for the corresponding line range.
///
public func lineStarts<Source: StringProtocol>(in source: Source) -> [UInt] {
    var starts: [UInt] = [0]
    for (index, byte) in source.utf8.enumerated() {
        if byte == 0x0A { // newline
            starts.append(UInt(index + 1))
        }
    }
    return starts
}

/// A handle that points to a file in the database.
public struct FileId: Equatable, Comparable, Hashable {

    public var rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static func < (lhs: FileId, rhs: FileId) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A file that is stored in the database.
public struct FileRecord<Source: StringProtocol> {

    /// The name of the file.
    public let name: String

    /// The source code of the file.
    public private(set) var source: Source

    /// The starting byte indices in the source code.
    public private(set) var lineStarts: [UInt]

    public init(
        name: String,
        source: Source
    ) {
        self.name = name
        self.source = source
        self.lineStarts = Codespan.lineStarts(in: source)
    }

    /// Update the source code of the file.
    /// Recomputes the line starts.
    public mutating func update(source: Source) {
        self.source = source
        self.lineStarts = Codespan.lineStarts(in: source)
    }

    /// Get the starting byte index of the line with the specified line index.
    public func lineStart(lineIndex: UInt) throws -> UInt {
        let lastLineIndex = UInt(lineStarts.count)
        if lineIndex < lastLineIndex {
            return lineStarts[Int(lineIndex)]
        }
        if lineIndex == lastLineIndex {
            return UInt(source.utf8.count)
        }
        throw FilesError.lineTooLarge(given: lineIndex, max: lastLineIndex)
    }

    /// Get the line index at the given byte in the source file.
    public func lineIndex(at byteIndex: UInt) throws -> UInt {
        return Codespan.lineIndex(lineStarts: lineStarts, byteIndex: byteIndex)
    }

    /// Get the byte range of line in the source of the file.
    public func lineRange(lineIndex: UInt) throws -> Range<UInt> {
        let start = try lineStart(lineIndex: lineIndex)
        let end = try lineStart(lineIndex: lineIndex + 1)
        return start..<end
    }
}

/// A database of source files.
///
public final class Files<Source: StringProtocol>: FilesProtocol {

    /// The files stored in the database.
    public private(set) var files: [FileRecord<Source>]

    /// Create a new, empty database of files.
    public init() {
        self.files = []
    }

    /// Add a file to the database, returning the handle that can be used to
    /// refer to it again.
    public func add(name: String, source: Source) -> FileId {
        let fileId = FileId(rawValue: UInt(files.count))
        files.append(FileRecord(name: name, source: source))
        return fileId
    }

    /// Update a source file in place.
    ///
    /// This will mean that any outstanding byte indexes will now point to
    /// invalid locations.
    public func update(id: FileId, source: Source) {
        let index = Int(id.rawValue)
        guard files.indices.contains(index) else {
            return
        }
        files[index].update(source: source)
    }

    /// Get the name of the source file.
    public func name(of fileId: FileId) throws -> String {
        try fileRecord(for: fileId).name
    }

    /// Get the source of the file.
    public func source(of fileId: FileId) throws -> Source {
        try fileRecord(for: fileId).source
    }

    /// Get the line index at the given byte in the source file.
    public func lineIndex(of fileId: FileId, at byteIndex: UInt) throws -> UInt {
        try fileRecord(for: fileId).lineIndex(at: byteIndex)
    }

    /// Get the byte range of line in the source of the file.
    public func lineRange(of fileId: FileId, lineIndex: UInt) throws -> Range<UInt> {
        try fileRecord(for: fileId).lineRange(lineIndex: lineIndex)
    }

    public func lineStarts(of fileId: FileId) throws -> [UInt] {
        try fileRecord(for: fileId).lineStarts
    }

    public func fileRecord(for fileId: FileId) throws -> FileRecord<Source> {
        let index = Int(fileId.rawValue)
        guard files.indices.contains(index) else {
            throw FilesError.fileMissing
        }
        return files[index]
    }
}

/// Find the line index for the given byte index using the provided line starts using binary search.
/// Returns the previous line index if the byte index is not exactly at a line start.
///
public func lineIndex(lineStarts: [UInt], byteIndex: UInt) -> UInt {
    var low = 0
    var high = lineStarts.count
    while low < high {
        let mid = (low + high) / 2
        let value = lineStarts[mid]
        if value == byteIndex {
            return UInt(mid)
        }
        if value < byteIndex {
            low = mid + 1
        } else {
            high = mid
        }
    }
    if low == 0 {
        return 0
    }
    return UInt(low - 1)
}

extension StringProtocol {
    func index(atUTF8Offset offset: UInt) -> String.Index? {
        guard offset <= UInt(utf8.count) else {
            return nil
        }
        let utf8View = utf8
        guard let utf8Index = utf8View.index(
            utf8View.startIndex,
            offsetBy: Int(offset),
            limitedBy: utf8View.endIndex
        ) else {
            return nil
        }
        return String.Index(utf8Index, within: self)
    }
}
