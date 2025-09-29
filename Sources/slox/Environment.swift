class Environment {
    var enclosing: Environment?
    private var values = [String: Object]()

    init(enclosing: Environment? = nil) {
        self.enclosing = enclosing
    }

    func define(name: String, value: Object) {
        values[name] = value
    }

    func get(name: Token) -> Object? {
        if let value = values[name.lexeme] {
            return value
        }

        return enclosing?.get(name: name)
    }

    func getAt(distance: Int, name: Token) -> Object? {
        return ancestor(distance: distance).values[name.lexeme]
    }

    func assign(name: Token, value: Object) throws(RuntimeError) {
        if values.keys.contains(name.lexeme) {
            values[name.lexeme] = value
            return
        }

        if let enclosing = enclosing {
            try enclosing.assign(name: name, value: value)
            return
        }

        throw .undefinedVariable(name)
    }

    func assignAt(distance: Int, name: Token, value: Object) {
        ancestor(distance: distance).values[name.lexeme] = value
    }

    private func ancestor(distance: Int) -> Environment {
        var environment: Environment = self

        for _ in 0..<distance {
            if let enclosingEnv = environment.enclosing {
                environment = enclosingEnv
            }
        }

        return environment
    }
}
