enum RuntimeError: ReportableError {
    case binaryTypeError(operator: String, lhs: Object, rhs: Object, token: Token)
    case unaryTypeError(operator: String, operand: Object, token: Token)
    case undefinedVariable(Token)

    var errorType: String {
        String(describing: Self.self)
    }

    var line: Int {
        switch self {
        case .binaryTypeError(operator: _, lhs: _, rhs: _, let token),
            .unaryTypeError(operator: _, operand: _, let token),
            .undefinedVariable(let token):
            return token.line
        }
    }

    var message: String {
        switch self {
        case .binaryTypeError(let op, let lhs, let rhs, _):
            return "Cannot apply '\(op)' to \(lhs.typeName) and \(rhs.typeName)"
        case .unaryTypeError(let op, let operand, _):
            return "Cannot apply '\(op)' to \(operand.typeName)"
        case .undefinedVariable(let token):
            return "Undefined variable '\(token.lexeme)'"
        }
    }
}
