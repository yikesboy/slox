struct SloxScanner {
    let source: String
    var tokens: [Token] = []

    private var start: Int = 0
    private var current: Int = 0
    private var line: Int = 1

    var isAtEnd: Bool {
        return current >= source.count
    }

    init(source: String) {
        self.source = source
    }

    mutating func scanTokens() throws(ScannerError) -> [Token] {
        while !isAtEnd {
            start = current
            try scanToken()
        }

        tokens.append(.init(type: .EOF, lexeme: "", literal: nil, line: line))
        return tokens
    }

    mutating private func scanToken() throws(ScannerError) {
        let character: Character = advance()
        switch character {
        case "(": addToken(.LEFT_PAREN)
        case ")": addToken(.RIGHT_PAREN)
        case "{": addToken(.LEFT_BRACE)
        case "}": addToken(.RIGHT_BRACE)
        case ",": addToken(.COMMA)
        case ".": addToken(.DOT)
        case "-": addToken(.MINUS)
        case "+": addToken(.PLUS)
        case ";": addToken(.SEMICOLON)
        case "*": addToken(.STAR)
        case "!": addToken(match("=") ? .BANG_EQUAL : .BANG)
        case "=": addToken(match("=") ? .EQUAL_EQUAL : .EQUAL)
        case "<": addToken(match("=") ? .LESS_EQUAL : .LESS)
        case ">": addToken(match("=") ? .GREATER_EQUAL : .GREATER)
        case "/": handleSlash()
        case " ", "\r", "\t": break
        case "\n": line += 1
        case "\"": try string()
        default:
            if character.isDigit {
                number()
            } else if character.isAlpha {
                try identifier()
            } else {
                throw .unexpectedCharacter(character, line)
            }
        }
    }

    mutating private func handleSlash() {
        if match("/") {
            while peek() != "\n" && !isAtEnd { _ = advance() }
        } else {
            addToken(.SLASH)
        }
    }

    mutating private func advance() -> Character {
        guard let char = source.char(at: current) else {
            assertionFailure("Scanner tried to advance beyond string bounds")
            return "\0"
        }
        self.current += 1
        return char
    }

    private func peek() -> Character {
        return source.char(at: current) ?? "\0"
    }

    private func peekNext() -> Character {
        return source.char(at: current + 1) ?? "\0"
    }

    mutating private func addToken(_ type: TokenType) {
        addToken(type, literal: nil)
    }

    mutating private func addToken(_ type: TokenType, literal: Literal?) {
        guard let text = source[safe: start..<current] else {
            assertionFailure("Scanner state violation: invalid range \(start)..<\(current)")
            return
        }
        tokens.append(.init(type: type, lexeme: text, literal: literal, line: line))
    }

    mutating private func match(_ expected: Character) -> Bool {
        guard !isAtEnd else { return false }

        if source.char(at: current) != expected { return false }
        current += 1

        return true
    }

    mutating private func string() throws(ScannerError) {
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" { line += 1 }
            _ = advance()
        }

        guard !isAtEnd else { throw .unterminatedString(line) }

        _ = advance()

        guard let value = source[safe: start + 1..<current - 1] else {
            fatalError("invalid substring operation")
        }
        addToken(.STRING, literal: .String(value))
    }

    mutating private func number() {
        while peek().isDigit { _ = advance() }

        if peek() == "." && peekNext().isDigit {
            _ = advance()
            while peek().isDigit { _ = advance() }
        }

        if let rawValue = source[safe: start..<current], let value = Double(rawValue) {
            addToken(.NUMBER, literal: .Number(value))
        }
    }

    mutating private func identifier() throws(ScannerError) {
        while peek().isAlphaNumeric { _ = advance() }

        guard let text = source[safe: start..<current] else {
            fatalError("invalid substring operation")
        }

        if let type = Keywords.map[text] {
            addToken(type)
        } else {
            addToken(.IDENTIFIER)
        }
    }
}
