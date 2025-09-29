enum SloxError: ReportableError {
    case scanner(ScannerError)
    case parser(ParserError)
    case resolver(ResolverError)
    case runtime(RuntimeError)

    var errorType: String {
        switch self {
        case .scanner(let error): return error.errorType
        case .parser(let error): return error.errorType
        case .resolver(let error): return error.errorType
        case .runtime(let error): return error.errorType
        }
    }

    var line: Int {
        switch self {
        case .scanner(let error): return error.line
        case .parser(let error): return error.line
        case .resolver(let error): return error.line
        case .runtime(let error): return error.line
        }
    }

    var message: String {
        switch self {
        case .scanner(let error): return error.message
        case .parser(let error): return error.message
        case .resolver(let error): return error.message
        case .runtime(let error): return error.message
        }
    }
}
