public struct Style: Equatable {
    public var foreground: Color?
    public var background: Color?
    public var isBold: Bool
    public var isUnderline: Bool
    public var isIntense: Bool

    public init(
        foreground: Color? = nil,
        background: Color? = nil,
        isBold: Bool = false,
        isUnderline: Bool = false,
        isIntense: Bool = false
    ) {
        self.foreground = foreground
        self.background = background
        self.isBold = isBold
        self.isUnderline = isUnderline
        self.isIntense = isIntense
    }

    public static var none: Style {
        Style()
    }
}
