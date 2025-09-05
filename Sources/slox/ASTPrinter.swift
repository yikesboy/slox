struct ASTPrinter: Visitor {
    typealias ReturnType = String

    func print(expr: Expression) -> String {
        return expr.accept(self)
    }

    func visit(_ literal: Literal) -> ReturnType {
        return literal.value.description
    }

    func visit(_ unary: Unary) -> ReturnType {
        return parenthesize(name: unary._operator.lexeme, expr: unary.right)
    }

    func visit(_ grouping: Grouping) -> ReturnType {
        return parenthesize(
            name: String(describing: type(of: grouping)), expr: grouping.expression)
    }

    func visit(_ binary: Binary) -> ReturnType {
        return parenthesize(name: binary._operator.lexeme, expr: binary.left, binary.right)
    }

    private func parenthesize(name: String, expr: Expression...) -> String {
        return "(\(name) \(expr.map { $0.accept(self) }.joined(separator: " ")))"
    }
}
