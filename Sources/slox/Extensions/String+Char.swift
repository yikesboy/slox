extension String {
    func char(at offset: Int) -> Character? {
        guard
            let index = self.index(startIndex, offsetBy: offset, limitedBy: endIndex),
            index < endIndex
        else {
            return nil
        }

        return self[index]
    }
}
