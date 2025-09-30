protocol CallableProtocol {
    var arity: Int { get }
    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object
}

enum SloxCallable: Equatable {
    case native(NativeFunction)
    case userDefined(SloxFunction)
    case _class(SloxClass)

    var arity: Int {
        switch self {
        case .native(let fn): return fn.arity
        case .userDefined(let fn): return fn.arity
        case ._class(let cls): return cls.arity
        }
    }

    func call(interpreter: Interpreter, arguments: [Object]) throws(RuntimeError) -> Object {
        switch self {
        case .native(let fn): return try fn.call(interpreter: interpreter, arguments: arguments)
        case .userDefined(let fn):
            return try fn.call(interpreter: interpreter, arguments: arguments)
        case ._class(let cls): return try cls.call(interpreter: interpreter, arguments: arguments)
        }
    }
}
