extension Character {
    var isAlpha: Bool {
        return (self >= "a" && self <= "z") || (self >= "A" && self <= "Z") || self == "_"
    }

    var isDigit: Bool {
        return (self >= "0" && self <= "9")
    }

    var isAlphaNumeric: Bool {
        return self.isAlpha || self.isDigit
    }
}
