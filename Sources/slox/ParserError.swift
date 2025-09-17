enum ParserError: ReportableError, @unchecked Sendable {
    case unexpected(Token)
    case expected(expected: TokenType, got: Token)
    case invalidAssignmentTarget(Token)
    case toManyArguments(token: Token, amount: Int)
    case toManyParameters(token: Token, amount: Int)

    var errorType: String {
        String(describing: Self.self)
    }

    var line: Int {
        switch self {
        case .unexpected(let token),
            .expected(_, let token),
            .invalidAssignmentTarget(let token),
            .toManyArguments(let token, _),
            .toManyParameters(let token, _):
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
        case .toManyArguments(_, let amount):
            return "To many arguments: \(amount), maxium: 255"
        case .toManyParameters(_, let amount):
            return "To many parameters: \(amount), maxium: 255"
        }
    }
}
