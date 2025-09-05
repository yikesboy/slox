/*
 *  expression     → equality ;
 *  equality       → comparison ( ( "!=" | "==" ) comparison )* ;
 *  comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
 *  term           → factor ( ( "-" | "+" ) factor )* ;
 *  factor         → unary ( ( "/" | "*" ) unary )* ;
 *  unary          → ( "!" | "-" ) unary | primary ;
 *  primary        → NUMBER | STRING | "true" | "false" | "nil" | "(" expression ")" ;
*/

struct Parser {
    private let tokens: [Token]
    private var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    var isAtEnd: Bool {
        return peek().type == .EOF
    }

    mutating func parse() throws(ParserError) -> Expression {
        return try expression()
    }

    mutating private func expression() throws(ParserError) -> Expression {
        return try equality()
    }

    mutating private func equality() throws(ParserError) -> Expression {
        var expression: Expression = try comparison()
        while match(types: .BANG_EQUAL, .EQUAL_EQUAL) {
            let _operator: Token = previous()
            let right: Expression = try comparison()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func comparison() throws(ParserError) -> Expression {
        var expression: Expression = try term()

        while match(types: .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL) {
            let _operator: Token = previous()
            let right: Expression = try term()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func term() throws(ParserError) -> Expression {
        var expression: Expression = try factor()

        while match(types: .MINUS, .PLUS) {
            let _operator: Token = previous()
            let right: Expression = try factor()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func factor() throws(ParserError) -> Expression {
        var expression: Expression = try unary()

        while match(types: .SLASH, .STAR) {
            let _operator: Token = previous()
            let right: Expression = try unary()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func unary() throws(ParserError) -> Expression {
        if match(types: .BANG, .MINUS) {
            let _operator: Token = previous()
            let right: Expression = try unary()
            return Unary(_operator: _operator, right: right)
        }

        return try primary()
    }

    mutating private func primary() throws(ParserError) -> Expression {
        switch peek().type {
        case .NUMBER, .STRING:
            let token = advance()
            if let value = token.literal {
                return Literal(value: value)
            }
        case .TRUE:
            _ = advance()
            return Literal(value: .Boolean(true))
        case .FALSE:
            _ = advance()
            return Literal(value: .Boolean(false))
        case .NIL:
            _ = advance()
            return Literal(value: .Nil)
        case .LEFT_PAREN:
            _ = advance()
            let expression: Expression = try expression()
            _ = try consume(.RIGHT_PAREN)
            return Grouping(expression: expression)
        default: break
        }
        throw .unexpected(peek())
    }

    mutating private func match(types: TokenType...) -> Bool {
        for tokentype in types {
            if check(type: tokentype) {
                _ = advance()
                return true
            }
        }

        return false
    }

    private func check(type: TokenType) -> Bool {
        guard !isAtEnd else {
            return false
        }

        return peek().type == type
    }

    mutating private func synchronize() {
        _ = advance()
        while !isAtEnd {
            guard previous().type != .SEMICOLON else { return }

            switch peek().type {
            case .CLASS, .FOR, .FUN, .IF, .PRINT, .RETURN, .VAR, .WHILE:
                return
            default:
                _ = advance()
            }
        }
    }

    private func previous() -> Token {
        return tokens[current - 1]
    }

    mutating private func advance() -> Token {
        if !isAtEnd { current += 1 }
        return previous()
    }

    private func peek() -> Token {
        return tokens[current]
    }

    mutating private func consume(_ tokenType: TokenType) throws(ParserError) -> Token {
        guard check(type: tokenType) else {
            throw .expected(peek())
        }

        return advance()
    }
}
