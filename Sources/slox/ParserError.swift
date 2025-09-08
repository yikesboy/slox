enum ParserError: ReportableError {
    case unexpected(Token)
    case expected(expected: TokenType, got: Token)
    case invalidAssignmentTarget(Token)

    var errorType: String {
        String(describing: Self.self)
    }

    var line: Int {
        switch self {
        case .unexpected(let token),
            .expected(_, let token),
            .invalidAssignmentTarget(let token):
            return token.line
        }
    }
    var message: String {
        switch self {
        case .unexpected(let token): return "Expected expression instead of \(token.lexeme)."
        case .expected(let expectedType, let gotToken):
            return "Expected \(expectedType) but got '\(gotToken.lexeme)'"
        case .invalidAssignmentTarget(let token):
            return "Invalid assignemnt target '\(token.lexeme)"
        }
    }
}
