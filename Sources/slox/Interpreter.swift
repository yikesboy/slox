struct Interpreter: ExprVisitor, StmtVisitor {
    typealias ReturnType = Object
    typealias ErrorType = RuntimeError

    private let environment = Environment()

    func interpret(statements: [Stmt]) throws(SloxError) {
        do {
            for stmt in statements {
                try stmt.accept(self)
            }
        } catch {
            throw .runtime(error)
        }
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

    func visit(_ expression: Expression) throws(ErrorType) {
        try expression.expression.accept(self)
    }

    func visit(_ print: Print) throws(ErrorType) {
        let value: Object = try print.expression.accept(self)
        Swift.print(value.toString)
    }

    func visit(_ _var: Var) throws(ErrorType) {
        let value: Object
        if let initializer = _var.initializer {
            value = try initializer.accept(self)
        } else {
            value = .Nil
        }

        environment.define(name: _var.name.lexeme, value: value)
    }

    func visit(_ variable: Variable) throws(ErrorType) -> ReturnType {
        guard let value: Object = environment.get(name: variable.name) else {
            throw .undefinedVariable(variable.name)
        }

        return value
    }

    func visit(_ assign: Assign) throws(RuntimeError) -> ReturnType {
        let value: Object = try assign.value.accept(self)
        try environment.assign(name: assign.name, value: value)
        return value
    }
}
