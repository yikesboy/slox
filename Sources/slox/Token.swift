struct Token {
    let type: TokenType
    let lexeme: String
    let literal: Object?
    let line: Int
}

extension Token: CustomStringConvertible {
    var description: String {
        return "\(type) \(lexeme) \(literal)"
    }
}
