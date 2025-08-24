import Foundation

@MainActor
@main
struct Slox {
    static func main() throws {
        let argv = CommandLine.arguments
        let argc = argv.count
        if argc == 1 {
            try runPrompt()
        } else if argc == 2 {
            try runFile(argv[1])
        } else {
            print("Usage: slox [script]")
        }
    }

    private static func runPrompt() throws {
        while true {
            print("> ")
            let line = readLine()
            if let line = line {
                _ = try? run(source: line)
            } else {
                break
            }
        }
    }

    private static func runFile(_ script: String) throws {
        do {
            let url = URL(filePath: script)
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else {
                print("Error: Unable to decode file \(script) as utf8")
                exit(65)
            }
            try run(source: content)
        } catch is ScannerError {
            exit(65)
        } catch {
            print("Error: Error reading file \(script): \(error.localizedDescription)")
        }
    }

    private static func run(source: String) throws {
        var scanner = SloxScanner(source: source)
        do {
            let tokens = try scanner.scanTokens()
            for token in tokens {
                print(token)
            }
        } catch {
            report(line: error.line, _where: "", message: error.message)
            throw error
        }

    }

    // TODO: replace with more solid approach
    private static func report(line: Int, _where: String, message: String) {
        print("[line \(line)] Error\(_where): \(message)")
    }
}
