import Foundation

class Interpreter: ExprVisitor, StmtVisitor {
    typealias ReturnType = Object
    typealias ErrorType = RuntimeError

    var globals: Environment
    private var environment: Environment
    private var locals = [UUID: Int]()

    init() {
        globals = Environment()
        environment = globals
        defineNativeFunctions()
    }

    func resolve(expr: Expr, depth: Int) {
        locals[expr.id] = depth
    }

    func interpret(statements: [Stmt]) throws(SloxError) {
        do throws(ErrorType) {
            for stmt in statements {
                let result = try stmt.accept(self, &environment)
                switch result {
                case .Normal: break
                case .Return(let value): fatalError("Value: \(value) reached top.")
                }
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

    func visit(_ expression: Expression, _ env: inout Environment) throws(ErrorType) -> ControlFlow
    {
        _ = try expression.expression.accept(self, &env)

        return .Normal
    }

    func visit(_ print: Print, _ env: inout Environment) throws(ErrorType) -> ControlFlow {
        let value: Object = try print.expression.accept(self, &env)
        Swift.print(value.toString)

        return .Normal
    }

    func visit(_ _var: Var, _ env: inout Environment) throws(ErrorType) -> ControlFlow {
        let value: Object
        if let initializer = _var.initializer {
            value = try initializer.accept(self, &env)
        } else {
            value = .Nil
        }

        env.define(name: _var.name.lexeme, value: value)

        return .Normal
    }

    func visit(_ _class: Class, _ env: inout Environment) throws(RuntimeError) -> ControlFlow {
        env.define(name: _class.name.lexeme, value: .Nil)

        let methods = _class.methods.reduce(into: [String: SloxFunction]()) { dict, method in
            dict[method.name.lexeme] = SloxFunction(declaration: method, closure: env)
        }

        let sloxClass = SloxClass(name: _class.name.lexeme, methods: methods)
        try env.assign(name: _class.name, value: .Callable(._class(sloxClass)))
        return .Normal
    }

    func visit(_ variable: Variable, _ env: inout Environment) throws(ErrorType) -> ReturnType {
        let result = lookupVariable(name: variable.name, expr: variable, env: env) ?? .Nil
        return result
    }

    private func lookupVariable(name: Token, expr: any Expr, env: Environment) -> Object? {
        if let distance = locals[expr.id] {
            let result = env.getAt(distance: distance, name: name)
            return result
        }

        let result = globals.get(name: name)
        return result
    }

    func visit(_ assign: Assign, _ env: inout Environment) throws(RuntimeError) -> ReturnType {
        let value: Object = try assign.value.accept(self, &env)

        if let distance = locals[assign.id] {
            env.assignAt(distance: distance, name: assign.name, value: value)
        } else {
            try globals.assign(name: assign.name, value: value)
        }

        return value
    }

    func visit(_ block: Block, _ env: inout Environment) throws(RuntimeError) -> ControlFlow {
        var blockEnvironment = Environment(enclosing: env)

        return try executeBlock(statements: block.statements, env: &blockEnvironment)
    }

    func visit(_ _if: _If, _ env: inout Environment) throws(RuntimeError) -> ControlFlow {
        let evaluatedIf = try _if.condition.accept(self, &env)

        if evaluatedIf.isTruthy {
            return try _if.thenBranch.accept(self, &env)
        } else if let elseBranch = _if.elseBranch {
            return try elseBranch.accept(self, &env)
        }

        return .Normal
    }

    func visit(_ logical: Logical, _ env: inout Environment) throws(ErrorType) -> ReturnType {
        let left: Object = try logical.left.accept(self, &env)
        let operatorType = logical._operator.type

        if (operatorType == .OR && left.isTruthy) || (operatorType == .AND && !left.isTruthy) {
            return left
        }

        return try logical.right.accept(self, &env)
    }

    func visit(_ _while: _While, _ env: inout Environment) throws(RuntimeError) -> ControlFlow {
        while try _while.condition.accept(self, &env).isTruthy {
            let result = try _while.body.accept(self, &env)
            switch result {
            case .Normal: continue
            case .Return(let value):
                return .Return(value)
            }
        }

        return .Normal
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

    func visit(_ get: Get, _ env: inout Environment) throws(RuntimeError) -> Object {
        let object = try get.object.accept(self, &env)

        guard case .Instance(var instance) = object else {
            throw .onlyInstancesHaveProperties(get.name)
        }

        guard let value = instance.get(name: get.name) else {
            throw .undefinedProperty(get.name)
        }

        return value
    }

    func visit(_ set: Set, _ env: inout Environment) throws(RuntimeError) -> Object {
        let object = try set.object.accept(self, &env)

        guard case .Instance(var instance) = object else {
            throw .onlyInstancesHaveFields(set.name)
        }

        let value = try set.value.accept(self, &env)
        instance.set(name: set.name, value: value)

        return value
    }

    func visit(_ function: Function, _ env: inout Environment) throws(RuntimeError) -> ControlFlow {
        let sloxFunction: SloxFunction = SloxFunction(declaration: function, closure: env)
        env.define(name: function.name.lexeme, value: .Callable(.userDefined(sloxFunction)))
        return .Normal
    }
    func visit(_ _return: Return, _ env: inout Environment) throws(RuntimeError) -> ControlFlow {
        let value: Object

        if let rv = _return.value {
            value = try rv.accept(self, &env)
        } else {
            value = .Nil
        }

        return .Return(value)
    }

    func executeBlock(statements: [Stmt], env: inout Environment) throws(RuntimeError)
        -> ControlFlow
    {
        for stmt in statements {
            let result = try stmt.accept(self, &env)
            switch result {
            case .Normal: continue
            case .Return(let value):
                return .Return(value)
            }
        }

        return .Normal
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
