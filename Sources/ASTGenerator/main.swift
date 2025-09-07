import Foundation
import Yams

/*
 * Commandline arguments are passed in from the plugin defintion in
 * Plugins/GenerateASTPlugin/plugin.swift
 */

private struct GenerationDefinition: Codable {
    let protocols: [String: ProtocolDefinition]
    let structs: [String: StructDefinition]
}

private struct ProtocolDefinition: Codable {
    let genericParams: [String]?
    let associatedTypes: [AssociatedTypeDefinition]?
    let functions: [FunctionDefinition]?

    enum CodingKeys: String, CodingKey {
        case genericParams = "generic_params"
        case associatedTypes = "associated_types"
        case functions
    }
}

private struct FunctionDefinition: Codable {
    let name: String
    let genericParams: [String]?
    let params: [ParameterDefinition]?
    let throwing: String?
    let returns: String?

    enum CodingKeys: String, CodingKey {
        case name
        case genericParams = "generic_params"
        case params, throwing, returns
    }
}

private struct ParameterDefinition: Codable {
    let name: String
    let type: String
}

private struct AssociatedTypeDefinition: Codable {
    let name: String
    let constraints: [String]?
}

private struct StructDefinition: Codable {
    let conformsTo: [String]?
    let fields: [FieldDefinition]?

    enum CodingKeys: String, CodingKey {
        case conformsTo = "conforms_to"
        case fields
    }
}

private struct FieldDefinition: Codable {
    let name: String
    let type: String
}

private struct DecodingErrorInfo {
    let title: String
    let location: String
    let details: String?
    let tip: String
}

let argv = CommandLine.arguments
let inputFilePath = argv[1]
let outputFilePath = argv[2]

let ast: String

do {
    let fileContent = try String(contentsOfFile: inputFilePath, encoding: .utf8)
    let definition = try YAMLDecoder().decode(GenerationDefinition.self, from: fileContent)
    ast = generateAST(from: definition, outputFilePath: outputFilePath)
    writeToFile(content: ast, path: outputFilePath)
} catch let error as DecodingError {
    let errorInfo = parseDecodingError(error)
    print("============YAML-Error=============")
    print("Error: \(errorInfo.title)")
    print("Location: \(errorInfo.location)")
    print("Expected: \(errorInfo.details ?? "n/a")")
    print("Tip: \(errorInfo.tip)")
    print("====================================")
    exit(1)
} catch {
    fatalError("Unable to load file: \(inputFilePath)")
}

private func generateAST(from defintion: GenerationDefinition, outputFilePath: String) -> String {
    var ast = generateComment(path: inputFilePath)

    for (name, p) in defintion.protocols {
        ast += generateProtocol(name: name, from: p)
    }

    for (name, s) in defintion.structs {
        ast += generateStruct(name: name, from: s)
    }

    return ast
}

private func generateProtocol(name: String, from definition: ProtocolDefinition) -> String {
    var result: String = "protocol \(name)"

    if let params = definition.genericParams {
        result += "<\(params.joined(separator: ", "))>"
    }

    result += " {\n"

    if let associatedTypes = definition.associatedTypes {
        for type in associatedTypes {
            result += "\tassociatedtype \(type.name)"
            if let constraints = type.constraints, !constraints.isEmpty {
                result += ": \(constraints.joined(separator: ", "))"
            }
            result += "\n"
        }
    }

    if let functions = definition.functions {
        for function in functions {
            result += "\tfunc \(function.name)"
            if let genericParams = function.genericParams {
                result += "<\(genericParams.joined(separator: ", "))>"
            }
            result += "("
            if let params = function.params {
                result += params.map { "_ \($0.name): \($0.type)" }.joined(separator: ", ")
            }
            result += ")"
            if let throwType = function.throwing {
                result += " throws(\(throwType))"
            }
            if let returnType = function.returns {
                result += " -> \(returnType)"
            }
            result += "\n"
        }
    }

    result += "}\n\n"

    return result
}

private func generateStruct(name: String, from definition: StructDefinition) -> String {
    var result: String = "struct \(name)"

    if let conformsTo = definition.conformsTo {
        result += ": \(conformsTo.joined(separator: ", "))"
    }

    result += " {\n"

    if let fields = definition.fields {
        result += fields.map { "\tlet \($0.name): \($0.type)\n" }.joined()
        result += "\n"
    }

    // NOTE: can/will be improved if the requirements are fully fleshed out
    if let conformsTo = definition.conformsTo {
        if conformsTo.contains("Expr") {
            result +=
                "\tfunc accept<T, E: Error>(_ visitor: any ExprVisitor<T, E>) throws(E) -> T {\n"
        } else if conformsTo.contains("Stmt") {
            result += "\tfunc accept<E: Error>(_ visitor: any StmtVisitor<E>) throws(E) {\n"
        }
    }
    result += "\t\ttry visitor.visit(self)\n"
    result += "\t}\n"

    result += "}\n\n"

    return result
}

private func writeToFile(content: String, path: String) {
    let outputFile = URL(fileURLWithPath: path)
    do {
        try content.write(to: outputFile, atomically: true, encoding: .utf8)
    } catch {
        fatalError("Unable to write content to file: \(path)")
    }
}

private func generateComment(path: String) -> String {
    return "/*\n * Generated AST from \(path)\n */\n\n"
}

private func parseDecodingError(_ error: DecodingError) -> DecodingErrorInfo {
    switch error {
    case .keyNotFound(let key, let context):
        let path = renderPath(context)
        return DecodingErrorInfo(
            title: "Missing required field \(key.stringValue).",
            location: path,
            details: nil,
            tip: getMissingKeyTip(key.stringValue)
        )
    case .typeMismatch(let type, let context):
        let path = renderPath(context)
        return DecodingErrorInfo(
            title: "Wrong data type provided.",
            location: path,
            details: getExpectedTypeDescription(type),
            tip: getTypeMismatchTip(for: path)
        )
    case .valueNotFound(let type, let context):
        let path = renderPath(context)
        return DecodingErrorInfo(
            title: "Missing value.",
            location: path,
            details: getExpectedTypeDescription(type),
            tip: "This field cannot be null or empty."
        )
    case .dataCorrupted(let context):
        let path = renderPath(context)
        return DecodingErrorInfo(
            title: "Invalid YAML structure",
            location: path,
            details: nil,
            tip: "Check the YAML file format."
        )
    @unknown default:
        return DecodingErrorInfo(
            title: "Unknown parsing error.",
            location: "n/a",
            details: nil,
            tip: "You're on your own, buddy."
        )
    }
}

private func renderPath(_ context: DecodingError.Context) -> String {
    return context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
}

private func getMissingKeyTip(_ key: String) -> String {
    return switch key {
    case "protocols": "Add a 'protocols:' section to define your protocols"
    case "structs": "Add a 'structs:' section to define your structs"
    case "functions": "Add a 'functions:' array to list protocol methods"
    case "fields": "Add a 'fields:' array to define struct properties"
    case "name": "Each function/field needs a 'name' property"
    case "type": "Each parameter/field needs a 'type' property"
    case "generic_params": "Use 'generic_params: [T, U]' for generic parameters"
    case "associated_types": "Use 'associated_types:' array for protocol associated types"
    case "conforms_to": "Use 'conforms_to: [ProtocolName]' for protocol conformance"
    default: "No tips for you lil bro."
    }
}

private func getExpectedTypeDescription(_ type: Any.Type) -> String {
    return String(describing: type)
}

private func getTypeMismatchTip(for path: String) -> String {
    let lastComponent = path.split(separator: " -> ").last?.lowercased() ?? ""
    return switch lastComponent {
    case "generic_params": "Should be an array like [T, 'U: Protocol']"
    case "functions", "fields", "params": "Should be an array of definitions"
    case "contraints", "conforms_to": "Should be an array of strings"
    default: "No idea what's going on, bud."
    }
}
