import Foundation
import Yams

/*
 * Commandline arguments are passed in from the plugin defintion in
 * Plugins/GenerateASTPlugin/plugin.swift
 */

let argv = CommandLine.arguments
let inputFilePath = argv[1]
let outputFilePath = argv[2]

do {
    let yaml = try loadYaml(filePath: inputFilePath)
    try generateAST(from: yaml, outputPath: outputFilePath)
} catch {
    print("Error Generating AST: \(error)")
    exit(1)
}

private func loadYaml(filePath: String) throws(ASTGeneratorError) -> Any {
    do {
        let yaml = try String(contentsOfFile: filePath, encoding: .utf8)
        return try Yams.load(yaml: yaml) as Any
    } catch {
        throw .unableToLoadFile(filePath)
    }
}

private func generateAST(from yaml: Any, outputPath: String) throws(ASTGeneratorError) {
    guard let yaml = yaml as? [String: Any] else {
        throw .invalidYamlStructure("Unable to convert YAML to dict")
    }

    guard let expressions = yaml["expressions"] as? [String: Any] else {
        throw .missingExpressionKey(inputFilePath)
    }

    var ast: String = ""
    appendGenerationComment(ast: &ast, path: inputFilePath)

    for (expr, data) in expressions {
        try buildExpressionStruct(expr: expr, data: data, ast: &ast)
    }

    try writeToFile(content: ast, path: outputFilePath)
}

private func buildExpressionStruct(
    expr: String,
    data: Any,
    ast: inout String
)
    throws(ASTGeneratorError)
{
    appendStructSignature(ast: &ast, expr: expr)

    guard
        let fieldsData = data as? [String: Any],
        let fields = fieldsData["fields"] as? [[String: Any]]
    else {
        throw .invalidYamlStructure("Unable to convert YAML data to dict")
    }

    try parseFields(fields: fields, ast: &ast)
    appendStructClosingBrace(ast: &ast)
}

private func parseFields(fields: [[String: Any]], ast: inout String) throws(ASTGeneratorError) {
    for field in fields {
        guard let name = field["name"] as? String else {
            throw .invalidFieldProperties("Missing name property")
        }

        guard let type = field["type"] as? String else {
            throw .invalidFieldProperties("Missing type property")
        }

        appendField(ast: &ast, name: name, type: type)
    }
}

private func writeToFile(content: String, path: String) throws(ASTGeneratorError) {
    let outputFile = URL(fileURLWithPath: path)
    do {
        try content.write(to: outputFile, atomically: true, encoding: .utf8)
    } catch {
        throw .errorWhileWritingFile(path, error)
    }
}

private func appendGenerationComment(ast: inout String, path: String) {
    ast += "/*\n * Generated AST from \(path)\n */\n\n"
}

private func appendStructSignature(ast: inout String, expr: String) {
    ast += "struct \(expr): Expression {\n"
}

private func appendField(ast: inout String, name: String, type: String) {
    ast += "\tlet \(name): \(type)\n"
}

private func appendStructClosingBrace(ast: inout String) {
    ast += "}\n\n"
}
