import Foundation

@main
struct Slox {
    static func main() {
        let argv = CommandLine.arguments
        let argc = argv.count
        if argc == 1 {
            runPrompt()
        } else if argc == 2 {
            runFile(argv[1])
        } else {
            print("Usage: slox [script]")
        }
    }

    private static func runPrompt() {
        let interpreter = Interpreter()
        while true {
            print("> ")
            guard let line = readLine() else { break }
            do {
                try run(interpreter: interpreter, source: line)
            } catch {
                Slox.error(error: error)
            }
        }
    }

    private static func runFile(_ script: String) {
        do {
            let url = URL(filePath: script)
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else {
                print("Error: Unable to decode file \(script) as utf8")
                exit(65)
            }
            let interpreter = Interpreter()
            try run(interpreter: interpreter, source: content)
        } catch let error as ReportableError {
            Slox.error(error: error)
            exit(65)
        } catch {
            print("Error reading file \(script): \(error.localizedDescription)")
            exit(65)
        }
    }

    private static func run(interpreter: Interpreter, source: String) throws(SloxError) {
        var scanner = SloxScanner(source: source)
        let tokens = try scanner.scanTokens()
        var parser = Parser(tokens: tokens)
        let statements = parser.parse()  // NOTE: has to throw evenutally
        let resolver = Resolver(interpreter: interpreter)
        try resolver.resolveParsedStatements(statements)
        try interpreter.interpret(statements: statements)
    }

    static func error(error: ReportableError) {
        report(errorType: error.errorType, line: error.line, message: error.message)
    }

    private static func report(errorType: String, line: Int, message: String) {
        print("[line \(line)] \(errorType): \(message)")
    }
}
