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
            if match(types: .FUN) {
                return try function(.function)
            }
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
        if match(types: .FOR) {
            return try forStatement()
        }

        if match(types: .WHILE) {
            return try whileStatement()
        }

        if match(types: .IF) {
            return try ifStatement()
        }

        if match(types: .PRINT) {
            return try printStatement()
        }

        if match(types: .LEFT_BRACE) {
            return Block(statements: try block())
        }

        if match(types: .RETURN) {
            return try returnStatement()
        }

        return try expressionStatement()
    }

    mutating private func returnStatement() throws(ParserError) -> Stmt {
        let keyword: Token = previous()
        var value = check(type: .SEMICOLON) ? nil : try expression()

        _ = try consume(.SEMICOLON)

        return Return(keyword: keyword, value: value)
    }

    mutating private func forStatement() throws(ParserError) -> Stmt {
        _ = try consume(.LEFT_PAREN)

        let initializer: Stmt?
        if match(types: .SEMICOLON) {
            initializer = nil
        } else if match(types: .VAR) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }

        var condition: Expr = Literal(value: .Boolean(true))
        if !check(type: .SEMICOLON) {
            condition = try expression()
        }
        _ = try consume(.SEMICOLON)

        var increment: Expr?
        if !check(type: .RIGHT_PAREN) {
            increment = try expression()
        }
        _ = try consume(.RIGHT_PAREN)

        var body: Stmt = try statement()

        if let increment = increment {
            let incExpr = Expression(expression: increment)
            body = Block(statements: [body, incExpr])
        }

        body = _While(condition: condition, body: body)

        if let initializer = initializer {
            body = Block(statements: [initializer, body])
        }

        return body
    }

    mutating private func whileStatement() throws(ParserError) -> Stmt {
        _ = try consume(.LEFT_PAREN)
        let condition: Expr = try expression()
        _ = try consume(.RIGHT_PAREN)
        let body: Stmt = try statement()

        return _While(condition: condition, body: body)
    }

    mutating private func ifStatement() throws(ParserError) -> Stmt {
        _ = try consume(.LEFT_PAREN)
        let condition: Expr = try expression()
        _ = try consume(.RIGHT_PAREN)

        let thenBranch: Stmt = try statement()
        var elseBranch: Stmt?

        if match(types: .ELSE) {
            elseBranch = try statement()
        }

        return _If(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
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

    mutating private func function(_ kind: FunctionKind) throws(ParserError) -> Function {
        let name: Token = try consume(.IDENTIFIER)
        _ = try consume(.LEFT_PAREN)

        var params = [Token]()
        if !check(type: .RIGHT_PAREN) {
            repeat {
                guard params.count <= 255 else {
                    throw .toManyParameters(token: peek(), amount: params.count)
                }
                let parameter = try consume(.IDENTIFIER)
                params.append(parameter)
            } while match(types: .COMMA)
        }

        _ = try consume(.RIGHT_PAREN)
        _ = try consume(.LEFT_BRACE)

        let body: [Stmt] = try block()

        return Function(name: name, params: params, body: body)
    }

    mutating private func assignment() throws(ParserError) -> Expr {
        let expr: Expr = try or()

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

    mutating private func or() throws(ParserError) -> Expr {
        var expression: Expr = try and()

        while match(types: .OR) {
            let _operator: Token = previous()
            let right: Expr = try and()
            expression = Logical(left: expression, _operator: _operator, right: right)
        }

        return expression
    }

    mutating private func and() throws(ParserError) -> Expr {
        var expression: Expr = try equality()

        while match(types: .AND) {
            let _operator: Token = previous()
            let right: Expr = try equality()
            expression = Logical(left: expression, _operator: _operator, right: right)
        }

        return expression
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

        return try call()
    }

    mutating private func call() throws(ParserError) -> Expr {
        var expression: Expr = try primary()

        while true {
            if match(types: .LEFT_PAREN) {
                expression = try finishCall(callee: expression)
            } else {
                break
            }
        }

        return expression
    }

    mutating private func finishCall(callee: Expr) throws(ParserError) -> Expr {
        var arguments = [Expr]()
        if !check(type: .RIGHT_PAREN) {
            repeat {
                guard arguments.count <= 255 else {
                    throw .toManyArguments(token: peek(), amount: arguments.count)
                }
                let expr = try expression()
                arguments.append(expr)
            } while match(types: .COMMA)
        }

        let paren: Token = try consume(.RIGHT_PAREN)

        return Call(callee: callee, paren: paren, arguments: arguments)
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
            return Variable(name: token)
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
        for tokentype in types where check(type: tokentype) {
            _ = advance()
            return true
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
