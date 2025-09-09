/*
 *  program        → statement* EOF ;
 *
 *  statement      → exprStmt | printStmt ;
 *  exprStmt       → expression | ";" ;
 *  printStmt      → "print" expression ";" ;
 *
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

    mutating func parse() -> [Stmt] {
        var statements: [Stmt] = []
        while !isAtEnd {
            do {
                statements.append(try declaration())
            } catch {
                Slox.error(error: error)
                // Note: we cant just ignore eventually.
            }
        }

        return statements
    }

    mutating private func expression() throws(ParserError) -> Expr {
        return try assignment()
    }

    mutating private func declaration() throws(ParserError) -> Stmt {
        do {
            if match(types: .VAR) {
                return try varDeclaration()
            }
            return try statement()
        } catch {
            synchronize()
            throw error
        }
    }

    mutating private func varDeclaration() throws(ParserError) -> Stmt {
        let name: Token = try consume(.IDENTIFIER)

        var initializer: Expr?
        if match(types: .EQUAL) {
            initializer = try expression()
        }

        _ = try consume(.SEMICOLON)

        return Var(name: name, initializer: initializer)
    }

    mutating private func statement() throws(ParserError) -> Stmt {
        if match(types: .PRINT) {
            return try printStatement()
        }

        if match(types: .LEFT_BRACE) {
            return Block(statements: try block())
        }

        return try expressionStatement()
    }

    mutating private func block() throws(ParserError) -> [Stmt] {
        var statements: [Stmt] = []
        while !check(type: .RIGHT_BRACE) && !isAtEnd {
            statements.append(try declaration())
        }

        _ = try consume(.RIGHT_BRACE)

        return statements
    }

    mutating private func printStatement() throws(ParserError) -> Stmt {
        let value: Expr = try expression()
        _ = try consume(.SEMICOLON)
        return Print(expression: value)
    }

    mutating private func expressionStatement() throws(ParserError) -> Stmt {
        let expression: Expr = try expression()
        _ = try consume(.SEMICOLON)
        return Expression(expression: expression)
    }

    mutating private func assignment() throws(ParserError) -> Expr {
        let expr: Expr = try equality()

        if match(types: .EQUAL) {
            let equals: Token = previous()
            let value: Expr = try assignment()

            guard let variable = expr as? Variable else {
                throw .invalidAssignmentTarget(equals)
            }

            let name: Token = variable.name
            return Assign(name: name, value: value)
        }

        return expr
    }

    mutating private func equality() throws(ParserError) -> Expr {
        var expression: Expr = try comparison()
        while match(types: .BANG_EQUAL, .EQUAL_EQUAL) {
            let _operator: Token = previous()
            let right: Expr = try comparison()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func comparison() throws(ParserError) -> Expr {
        var expression: Expr = try term()

        while match(types: .GREATER, .GREATER_EQUAL, .LESS, .LESS_EQUAL) {
            let _operator: Token = previous()
            let right: Expr = try term()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func term() throws(ParserError) -> Expr {
        var expression: Expr = try factor()

        while match(types: .MINUS, .PLUS) {
            let _operator: Token = previous()
            let right: Expr = try factor()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func factor() throws(ParserError) -> Expr {
        var expression: Expr = try unary()

        while match(types: .SLASH, .STAR) {
            let _operator: Token = previous()
            let right: Expr = try unary()
            expression = Binary(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func unary() throws(ParserError) -> Expr {
        if match(types: .BANG, .MINUS) {
            let _operator: Token = previous()
            let right: Expr = try unary()
            return Unary(_operator: _operator, right: right)
        }

        return try primary()
    }

    mutating private func primary() throws(ParserError) -> Expr {
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
        case .IDENTIFIER:
            let token = advance()
            return Variable(name: token)  // NOTE: ???
        case .LEFT_PAREN:
            _ = advance()
            let expression: Expr = try expression()
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
            throw .expected(expected: tokenType, got: peek())
        }

        return advance()
    }
}
