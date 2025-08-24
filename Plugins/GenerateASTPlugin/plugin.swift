import Foundation
import PackagePlugin

@main
struct GenerateASTPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let inputFile = context.package.directoryURL.appending(path: "ast-definitions.yml")
        let outputDir = context.pluginWorkDirectoryURL.appending(path: "Generated")
        let outputFile = outputDir.appending(path: "AST.swift")

        return [
            .buildCommand(
                displayName: "Generating AST Structs",
                executable: try context.tool(named: "ASTGenerator").url,
                arguments: [
                    inputFile.path,
                    outputFile.path,
                ],
                inputFiles: [inputFile],
                outputFiles: [outputFile]
            )
        ]
    }
}
