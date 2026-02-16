/// The 'location focus' of a source code snippet.
public struct Locus: Sendable {
    /// The user-facing name of the file.
    var name: String

    /// The location.
    var location: Location

    public init(
        name: String,
        location: Location
    ) {
        self.name = name
        self.location = location
    }
}
