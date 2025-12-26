extension Range where Bound == UInt {

    func isOverlapping(other: Range<UInt>) -> Bool {
        let start = Swift.max(self.lowerBound, other.lowerBound)
        let end = Swift.min(self.upperBound, other.upperBound)
        return start < end
    }
}
