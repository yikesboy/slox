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
}
