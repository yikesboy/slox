enum RuntimeError: ReportableError, @unchecked Sendable {
    case binaryTypeError(operator: String, lhs: Object, rhs: Object, token: Token)
    case unaryTypeError(operator: String, operand: Object, token: Token)
    case undefinedVariable(Token)
    case callError(Token)
    case expectedArguments(token: Token, expected: Int, got: Int)
    case onlyInstancesHaveProperties(Token)
    case undefinedProperty(Token)
    case onlyInstancesHaveFields(Token)

    var errorType: String {
        String(describing: Self.self)
    }

    var line: Int {
        switch self {
        case .binaryTypeError(operator: _, lhs: _, rhs: _, let token),
            .unaryTypeError(operator: _, operand: _, let token),
            .undefinedVariable(let token),
            .callError(let token),
            .expectedArguments(let token, _, _),
            .onlyInstancesHaveProperties(let token),
            .undefinedProperty(let token),
            .onlyInstancesHaveFields(let token):
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
        case .callError:
            return "Can only call functions and classes."
        case .expectedArguments(token: _, let expected, let got):
            return "Expected \(expected) arguments but got \(got)."
        case .onlyInstancesHaveProperties:
            return "Only instances have properties."
        case .undefinedProperty(let token):
            return "Undefined property '\(token.lexeme)'."
        case .onlyInstancesHaveFields:
            return "Only instances have fields."
        }
    }
}
