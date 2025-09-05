enum Object {
    case String(Swift.String)
    case Number(Double)
    case Boolean(Bool)
    case Nil

    var description: Swift.String {
        switch self {
        case .String(let value): return value
        case .Number(let value): return Swift.String(value)
        case .Boolean(let value): return Swift.String(value)
        case .Nil: return "nil"
        }
    }
}
