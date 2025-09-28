enum ResolverError: ReportableError, @unchecked Sendable {
    case cannotReadVariableInItsOwnInit(Token)

    var errorType: String {
        String(describing: Self.self)
    }

    var line: Int {
        switch self {
        case .cannotReadVariableInItsOwnInit(let token): return token.line
        }
    }

    var message: String {
        switch self {
        case .cannotReadVariableInItsOwnInit:
            return "Can't read local variable in its own initializer."
        }
    }
}
