// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "slox",
    products: [
        .executable(name: "slox", targets: ["slox"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.1")
    ],
    targets: [
        .executableTarget(
            name: "slox",
            plugins: ["GenerateASTPlugin"]
        ),
        .executableTarget(
            name: "ASTGenerator",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ],
        ),
        .plugin(
            name: "GenerateASTPlugin",
            capability: .buildTool(),
            dependencies: ["ASTGenerator"]
        ),
    ]
)
