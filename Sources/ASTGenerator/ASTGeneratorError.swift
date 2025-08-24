import Foundation

enum ASTGeneratorError: Error, LocalizedError {
    case unableToLoadFile(String)
    case missingExpressionKey(String)
    case invalidYamlStructure(String)
    case invalidFieldProperties(String)
    case errorWhileWritingFile(String, Error)

    var errorDescription: String? {
        switch self {
        case .unableToLoadFile(let file): return "Unable to load file: \(file)"
        case .missingExpressionKey(let file): return "Expression key missing in: \(file)"
        case .invalidYamlStructure(let details): return "Invalid yaml structure: \(details)"
        case .invalidFieldProperties(let details): return "Invalid field properties: \(details)"
        case .errorWhileWritingFile(let path, let error):
            return "Failed writing to \(path): \(error)"
        }
    }
}
