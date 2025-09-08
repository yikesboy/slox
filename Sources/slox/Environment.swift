class Environment {
    private var values = [String: Object]()

    func define(name: String, value: Object) {
        values[name] = value
    }

    func get(name: Token) -> Object? {
        return values[name.lexeme]
    }

    func assign(name: Token, value: Object) throws(RuntimeError) {
        guard values.keys.contains(name.lexeme) else {
            throw .undefinedVariable(name)
        }

        values[name.lexeme] = value
    }
}
