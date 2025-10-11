struct SloxClass: CallableProtocol, Equatable {
    let name: String
    let methods: [String: SloxFunction]

    var arity: Int {
        return 0
    }

    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object {
        let sloxInstance = SloxInstance(_class: self)
        return .Instance(sloxInstance)
    }

    func findMethod(name: String) -> SloxFunction? {
        return methods[name]
    }
}
