struct Interpreter: Visitor {
    typealias ReturnType = Object
    typealias ErrorType = RuntimeError

    func interpret(expression: Expr) throws(RuntimeError) {
        let value: Object = try expression.accept(self)
        print(value.toString)
    }

    func visit(_ literal: Literal) -> ReturnType {
        return literal.value
    }

    func visit(_ grouping: Grouping) throws(ErrorType) -> ReturnType {
        try grouping.expression.accept(self)
    }

    func visit(_ unary: Unary) throws(ErrorType) -> ReturnType {
        let right: Object = try unary.right.accept(self)

        guard let op = unary._operator.type.asUnaryOp else {
            fatalError("Unsupported unary operator: \(unary._operator.type)")
        }

        switch op {
        case .MINUS:
            switch right {
            case .Number(let value):
                return .Number(-value)
            default:
                throw .unaryTypeError(
                    operator: unary._operator.lexeme, operand: right, token: unary._operator)
            }
        case .BANG:
            return Object.Boolean(!right.isTruthy)
        }
    }

    func visit(_ binary: Binary) throws(ErrorType) -> ReturnType {
        let right: Object = try binary.right.accept(self)
        let left: Object = try binary.left.accept(self)

        guard let op = binary._operator.type.asBinaryOp else {
            fatalError("Unsupported binary operator: \(binary._operator.type)")
        }

        switch op {
        case .MINUS:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Number(lhs - rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .SLASH:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Number(lhs / rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .STAR:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Number(lhs * rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .PLUS:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Number(lhs + rhs)
            case (.String(let lhs), .String(let rhs)): return .String(lhs + rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .GREATER:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Boolean(lhs > rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .GREATER_EQUAL:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Boolean(lhs >= rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .LESS:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Boolean(lhs < rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .LESS_EQUAL:
            switch (left, right) {
            case (.Number(let lhs), .Number(let rhs)): return .Boolean(lhs <= rhs)
            default:
                throw .binaryTypeError(
                    operator: binary._operator.lexeme, lhs: left, rhs: right,
                    token: binary._operator
                )
            }
        case .BANG_EQUAL:
            return .Boolean(right != left)
        case .EQUAL_EQUAL:
            return .Boolean(right == left)
        }
    }
}
