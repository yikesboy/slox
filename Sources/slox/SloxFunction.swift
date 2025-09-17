struct SloxFunction: CallableProtocol, Equatable {
    let declaration: Function
    let closure: Environment

    var arity: Int {
        return declaration.params.count
    }

    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object {
        var environment: Environment = Environment(enclosing: closure)

        for (parameter, argument) in zip(declaration.params, arguments) {
            environment.define(name: parameter.lexeme, value: argument)
        }

        let result = try interpreter.executeBlock(statements: declaration.body, env: &environment)

        switch result {
        case .Normal: return .Nil
        case .Return(let value): return value
        }
    }

    static func == (lhs: SloxFunction, rhs: SloxFunction) -> Bool {
        return lhs.declaration.name == rhs.declaration.name
            && lhs.declaration.params == rhs.declaration.params
    }
}
