enum ResolverError: ReportableError, @unchecked Sendable {
    case cannotReadVariableInItsOwnInit(Token)
    case variableWithThisNameAlreadyInScope(Token)
    case cannotReturnFromTopLevelCode(Token)

    var errorType: String {
        String(describing: Self.self)
    }

    var line: Int {
        switch self {
        case .cannotReadVariableInItsOwnInit(let token),
            .variableWithThisNameAlreadyInScope(let token),
            .cannotReturnFromTopLevelCode(let token):
            return token.line
        }
    }

    var message: String {
        switch self {
        case .cannotReadVariableInItsOwnInit(let token):
            return "Can't read local variable '\(token.lexeme)' in its own initializer."
        case .variableWithThisNameAlreadyInScope(let token):
            return "Already a variable with name '\(token.lexeme)' in scope."
        case .cannotReturnFromTopLevelCode:
            return "Cannot return from top level code."
        }
    }
}
