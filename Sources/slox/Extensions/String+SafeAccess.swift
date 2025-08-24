extension String {
    subscript(safe range: Range<Int>) -> String? {
        guard range.lowerBound >= 0 && range.upperBound <= count else { return nil }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
}
