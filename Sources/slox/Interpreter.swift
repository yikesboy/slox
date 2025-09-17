import Foundation

struct Interpreter: ExprVisitor, StmtVisitor {
    typealias ReturnType = Object
    typealias ErrorType = RuntimeError

    var globals: Environment
    private var environment: Environment

    init() {
        globals = Environment()
        environment = globals
        defineNativeFunctions()
    }

    mutating func interpret(statements: [Stmt]) throws(SloxError) {
        do throws(ErrorType) {
            for stmt in statements {
                try stmt.accept(self, &environment)
            }
        } catch {
            throw .runtime(error)
        }
    }

    func visit(_ literal: Literal, _ env: inout Environment) -> ReturnType {
        return literal.value
    }

    func visit(_ grouping: Grouping, _ env: inout Environment) throws(ErrorType) -> ReturnType {
        try grouping.expression.accept(self, &env)
    }

    func visit(_ unary: Unary, _ env: inout Environment) throws(ErrorType) -> ReturnType {
        let right: Object = try unary.right.accept(self, &env)

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

    func visit(_ binary: Binary, _ env: inout Environment) throws(ErrorType) -> ReturnType {
        let right: Object = try binary.right.accept(self, &env)
        let left: Object = try binary.left.accept(self, &env)

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

    func visit(_ expression: Expression, _ env: inout Environment) throws(ErrorType) {
        _ = try expression.expression.accept(self, &env)
    }

    func visit(_ print: Print, _ env: inout Environment) throws(ErrorType) {
        let value: Object = try print.expression.accept(self, &env)
        Swift.print(value.toString)
    }

    func visit(_ _var: Var, _ env: inout Environment) throws(ErrorType) {
        let value: Object
        if let initializer = _var.initializer {
            value = try initializer.accept(self, &env)
        } else {
            value = .Nil
        }

        env.define(name: _var.name.lexeme, value: value)
    }

    func visit(_ variable: Variable, _ env: inout Environment) throws(ErrorType) -> ReturnType {
        guard let value: Object = env.get(name: variable.name) else {
            throw .undefinedVariable(variable.name)
        }

        return value
    }

    func visit(_ assign: Assign, _ env: inout Environment) throws(RuntimeError) -> ReturnType {
        let value: Object = try assign.value.accept(self, &env)
        try env.assign(name: assign.name, value: value)
        return value
    }

    func visit(_ block: Block, _ env: inout Environment) throws(RuntimeError) {
        var blockEnvironment = Environment(enclosing: env)
        try executeBlock(statements: block.statements, env: &blockEnvironment)

    }

    func visit(_ _if: _If, _ env: inout Environment) throws(RuntimeError) {
        let evaluatedIf = try _if.condition.accept(self, &env)

        if evaluatedIf.isTruthy {
            try _if.thenBranch.accept(self, &env)
        } else if let elseBranch = _if.elseBranch {
            try elseBranch.accept(self, &env)
        }
    }

    func visit(_ logical: Logical, _ env: inout Environment) throws(ErrorType) -> ReturnType {
        let left: Object = try logical.left.accept(self, &env)
        let operatorType = logical._operator.type

        if (operatorType == .OR && left.isTruthy) || (operatorType == .AND && !left.isTruthy) {
            return left
        }

        return try logical.right.accept(self, &env)
    }

    func visit(_ _while: _While, _ env: inout Environment) throws(RuntimeError) {
        while try _while.condition.accept(self, &env).isTruthy {
            try _while.body.accept(self, &env)
        }
    }

    func visit(_ call: Call, _ env: inout Environment) throws(RuntimeError) -> Object {
        let callee: Object = try call.callee.accept(self, &env)

        let arguments = try call.arguments.map { arg throws(ErrorType) -> Object in
            try arg.accept(self, &env)
        }

        guard case .Callable(let function) = callee else {
            throw .callError(call.paren)
        }

        guard arguments.count == function.arity else {
            throw .expectedArguments(
                token: call.paren, expected: function.arity, got: arguments.count
            )
        }

        return try function.call(interpreter: self, arguments: arguments)
    }

    func visit(_ function: Function, _ env: inout Environment) throws(RuntimeError) {
        let function: SloxFunction = SloxFunction(declaration: function)
        env.define(
            name: function.declaration.name.lexeme, value: .Callable(.userDefined(function))
        )
    }

    func executeBlock(statements: [Stmt], env: inout Environment) throws(RuntimeError) {
        for stmt in statements {
            try stmt.accept(self, &env)
        }
    }

    private func defineNativeFunctions() {
        let clock = NativeFunction(
            name: "clock",
            arity: 0,
            implementation: { _, _ in
                .Number(Date().timeIntervalSince1970)
            }
        )

        globals.define(name: "clock", value: .Callable(.native(clock)))
    }
}
