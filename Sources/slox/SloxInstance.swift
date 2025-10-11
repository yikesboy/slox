class SloxInstance: Equatable {
    let _class: SloxClass
    var fields = [String: Object]()

    init(_class: SloxClass) {
        self._class = _class
    }

    func get(name: Token) -> Object? {
        if let property = fields[name.lexeme] {
            return property
        }

        if let method = _class.findMethod(name: name.lexeme) {
            return .Callable(.userDefined(method))
        }

        return nil
    }

    func set(name: Token, value: Object) {
        fields[name.lexeme] = value
    }

    static func == (lhs: SloxInstance, rhs: SloxInstance) -> Bool {
        return lhs._class == rhs._class && lhs.fields == rhs.fields
    }
}
