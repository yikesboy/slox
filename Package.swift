// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "slox",
    products: [
        .executable(name: "slox", targets: ["slox"])
    ],
    targets: [
        .executableTarget(
            name: "slox",
            plugins: ["GenerateASTPlugin"]
        ),
        .executableTarget(
            name: "ASTGenerator"
        ),
        .plugin(
            name: "GenerateASTPlugin",
            capability: .buildTool(),
            dependencies: ["ASTGenerator"]
        ),
    ]
)
