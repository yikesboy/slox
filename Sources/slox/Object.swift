indirect enum Object: Equatable {
    case String(Swift.String)
    case Number(Double)
    case Boolean(Bool)
    case Nil
    case Callable(SloxCallable)
    case Instance(SloxInstance)

    var typeName: Swift.String {
        let fullDescription = Swift.String(describing: self)
        return fullDescription.components(separatedBy: "(").first ?? "Unknown"
    }

    var toString: Swift.String {
        switch self {
        case .String(let value): return value
        case .Number(let value): return Swift.String(value)
        case .Boolean(let value): return Swift.String(value)
        case .Nil: return "nil"
        case .Callable(let value): return Swift.String(describing: value)
        case .Instance(let value): return Swift.String(describing: value)
        }
    }

    var isTruthy: Bool {
        switch self {
        case .Boolean(let value): return value
        case .Nil: return false
        default: return true
        }
    }
}
