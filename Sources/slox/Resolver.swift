import Foundation

class Resolver: ResolverExprVisitor, ResolverStmtVisitor {
    typealias ErrorType = ResolverError
    typealias ReturnType = Void

    private let interpreter: Interpreter
    private var scopes = Stack<String, Bool>()
    private var currentFunction = FunctionType.NONE

    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }

    func resolveParsedStatements(_ statements: [Stmt]) throws(SloxError) {
        do {
            try resolve(statements: statements)
        } catch {
            throw .resolver(error)
        }
    }

    func visit(_ block: Block) throws(ErrorType) -> ControlFlow {
        beginScope()
        try resolve(statements: block.statements)
        endScope()
        return .Normal
    }

    func visit(_ _var: Var) throws(ErrorType) -> ControlFlow {
        try declare(name: _var.name)
        if let initilizer = _var.initializer {
            try resolve(expr: initilizer)
        }
        define(name: _var.name)

        return .Normal
    }

    func visit(_ variable: Variable) throws(ErrorType)
        -> ReturnType
    {
        if let topScope = scopes.peek(), topScope[variable.name.lexeme] == false {
            throw .cannotReadVariableInItsOwnInit(variable.name)
        }

        resolveLocal(expr: variable, name: variable.name)
    }

    func visit(_ assign: Assign) throws(ErrorType)
        -> ReturnType
    {
        try resolve(expr: assign.value)
        resolveLocal(expr: assign, name: assign.name)
    }

    func visit(_ function: Function) throws(ErrorType)
        -> ControlFlow
    {
        try declare(name: function.name)
        define(name: function.name)
        try resolveFunction(function: function, functionType: .FUNCTION)
        return .Normal
    }

    func visit(_ expression: Expression) throws(ErrorType)
        -> ControlFlow
    {
        try resolve(expr: expression.expression)
        return .Normal
    }

    func visit(_ _if: _If) throws(ErrorType) -> ControlFlow {
        try resolve(expr: _if.condition)
        try resolve(stmt: _if.thenBranch)

        if let elseBranch = _if.elseBranch {
            try resolve(stmt: elseBranch)
        }

        return .Normal
    }

    func visit(_ print: Print) throws(ErrorType) -> ControlFlow {
        try resolve(expr: print.expression)
        return .Normal
    }

    func visit(_ _class: Class) throws(ResolverError) -> ControlFlow {
        try declare(name: _class.name)
        define(name: _class.name)

        for method in _class.methods {
            try resolveFunction(function: method, functionType: .METHOD)
        }

        return .Normal
    }

    func visit(_ get: Get) throws(ResolverError) {
        try resolve(expr: get.object)
    }

    func visit(_ set: Set) throws(ResolverError) {
        try resolve(expr: set.value)
        try resolve(expr: set.object)
    }

    func visit(_ _return: Return) throws(ResolverError)
        -> ControlFlow
    {
        guard currentFunction != .NONE else {
            throw .cannotReturnFromTopLevelCode(_return.keyword)
        }

        if let value = _return.value {
            try resolve(expr: value)
        }

        return .Normal
    }

    func visit(_ _while: _While) throws(ResolverError)
        -> ControlFlow
    {
        try resolve(expr: _while.condition)
        try resolve(stmt: _while.body)

        return .Normal
    }

    func visit(_ binary: Binary) throws(ResolverError) {
        try resolve(expr: binary.left)
        try resolve(expr: binary.right)
    }

    func visit(_ call: Call) throws(ResolverError) {
        try resolve(expr: call.callee)

        for arg in call.arguments {
            try resolve(expr: arg)
        }
    }

    func visit(_ grouping: Grouping) throws(ResolverError) {
        try resolve(expr: grouping.expression)
    }

    func visit(_ literal: Literal) throws(ResolverError) {
        return
    }

    func visit(_ logical: Logical) throws(ResolverError) {
        try resolve(expr: logical.left)
        try resolve(expr: logical.right)
    }

    func visit(_ unary: Unary) throws(ResolverError) {
        try resolve(expr: unary)
    }

    private func resolve(statements: [Stmt])
        throws(ResolverError)
    {
        for stmt in statements { try resolve(stmt: stmt) }
    }

    private func resolve(stmt: Stmt) throws(ResolverError) {
        var visitor: any ResolverStmtVisitor<ResolverError> = self
        _ = try stmt.accept(&visitor)
    }

    private func resolve(expr: Expr) throws(ResolverError) {
        var visitor: any ResolverExprVisitor<Void, ResolverError> = self
        _ = try expr.accept(&visitor)
    }

    private func resolveFunction(
        function: Function, functionType: FunctionType
    )
        throws(ResolverError)
    {
        let enclosingFunction = currentFunction
        currentFunction = functionType

        beginScope()
        for param in function.params {
            try declare(name: param)
            define(name: param)
        }
        try resolve(statements: function.body)
        endScope()

        currentFunction = enclosingFunction
    }

    private func beginScope() {
        scopes.push([:])
    }

    private func endScope() {
        _ = scopes.pop()
    }

    private func declare(name: Token) throws(ResolverError) {
        guard !scopes.containsKey(key: name.lexeme) else {
            throw .variableWithThisNameAlreadyInScope(name)
        }

        scopes.withTopElement { scope in
            scope[name.lexeme] = false
        }
    }

    private func define(name: Token) {
        scopes.withTopElement { scope in
            scope[name.lexeme] = true
        }
    }

    private func resolveLocal(expr: Expr, name: Token) {
        for (index, element) in scopes.topToBottom.enumerated()
        where element.keys.contains(name.lexeme) {
            interpreter.resolve(expr: expr, depth: scopes.size - 1 - index)
            return
        }
    }
}
