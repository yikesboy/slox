enum ScannerError: Error {
    case unexpectedCharacter(_ character: Character, _ line: Int)
    case unterminatedString(_ line: Int)

    var line: Int {
        switch self {
        case .unexpectedCharacter(_, let line), .unterminatedString(let line): return line
        }
    }

    var message: String {
        switch self {
        case .unexpectedCharacter(let character, _): return "Unexpected character \"\(character)\"."
        case .unterminatedString: return "Unterminated string."
        }
    }
}
