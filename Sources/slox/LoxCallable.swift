protocol CallableProtocol {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object?
}

enum SloxCallable: Equatable {
    case native(NativeFunction)
    case userDefined(SloxFunction)

    var arity: Int {
        switch self {
        case .native(let fn): return fn.arity
        case .userDefined(let fn): return fn.arity
        }
    }

    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object? {
        switch self {
        case .native(let fn): return try fn.call(interpreter: interpreter, arguments: arguments)
        case .userDefined(let fn):
            return try fn.call(interpreter: interpreter, arguments: arguments)
        }
    }
}
