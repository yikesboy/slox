struct SloxClass: CallableProtocol, Equatable {
    let name: String

    var arity: Int {
        return 0
    }

    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object {
        let sloxInstance = SloxInstance(_class: self)
        return .Instance(sloxInstance)
    }

}
