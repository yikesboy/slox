struct NativeFunction: CallableProtocol, Equatable {
    let name: String
    let arity: Int
    let implementation: (Interpreter, [Object]) throws(RuntimeError) -> Object

    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object {
        try implementation(interpreter, arguments)
    }

    static func == (lhs: NativeFunction, rhs: NativeFunction) -> Bool {
        lhs.name == rhs.name && lhs.arity == rhs.arity
    }
}
