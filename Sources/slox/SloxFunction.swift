struct SloxFunction: CallableProtocol, Equatable {
    let declaration: Function

    var arity: Int {
        return declaration.params.count
    }

    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object? {
        var environment: Environment = Environment(enclosing: interpreter.globals)

        for (parameter, argument) in zip(declaration.params, arguments) {
            environment.define(name: parameter.lexeme, value: argument)
        }

        try interpreter.executeBlock(statements: declaration.body, env: &environment)

        return .Nil
    }

    static func == (lhs: SloxFunction, rhs: SloxFunction) -> Bool {
        return lhs.declaration.name == rhs.declaration.name
            && lhs.declaration.params == rhs.declaration.params
    }
}
