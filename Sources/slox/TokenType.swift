enum TokenType {
    case LEFT_PAREN
    case RIGHT_PAREN
    case LEFT_BRACE
    case RIGHT_BRACE
    case COMMA
    case DOT
    case MINUS
    case PLUS
    case SEMICOLON
    case SLASH
    case STAR

    case BANG
    case BANG_EQUAL
    case EQUAL
    case EQUAL_EQUAL
    case GREATER
    case GREATER_EQUAL
    case LESS
    case LESS_EQUAL
    case IDENTIFIER
    case STRING
    case NUMBER

    case AND
    case CLASS
    case ELSE
    case FALSE
    case FUN
    case FOR
    case IF
    case NIL
    case OR
    case PRINT
    case RETURN
    case SUPER
    case THIS
    case TRUE
    case VAR
    case WHILE

    case EOF

    var asBinaryOp: BinaryOperator? {
        switch self {
        case .MINUS: return .MINUS
        case .PLUS: return .PLUS
        case .STAR: return .STAR
        case .SLASH: return .SLASH
        case .GREATER: return .GREATER
        case .GREATER_EQUAL: return .GREATER_EQUAL
        case .LESS: return .LESS
        case .LESS_EQUAL: return .LESS_EQUAL
        case .BANG_EQUAL: return .BANG_EQUAL
        case .EQUAL_EQUAL: return .EQUAL_EQUAL
        default: return nil
        }
    }

    var asUnaryOp: UnaryOperator? {
        switch self {
        case .MINUS: return .MINUS
        case .BANG: return .BANG
        default: return nil
        }
    }
}

// NOTE: replace with more expressive types later on

enum BinaryOperator: CaseIterable {
    case MINUS, PLUS, STAR, SLASH, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL, BANG_EQUAL, EQUAL_EQUAL
}

enum UnaryOperator: CaseIterable {
    case MINUS, BANG
}
