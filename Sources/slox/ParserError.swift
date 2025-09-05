enum ParserError: Error {
    case unexpected(Token)
    case expected(Token)

    var line: Int {
        switch self {
        case .unexpected(let token), .expected(let token): return token.line
        }
    }
    var message: String {
        switch self {
        case .unexpected(let token): return "Expected expression instead of \(token.lexeme)."
        case .expected(let token): return "Expected \(token.lexeme) after expression."
        }
    }
}
