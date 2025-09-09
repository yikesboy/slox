/*struct ASTPrinter: ExprVisitor, StmtVisitor {
    typealias ReturnType = String

    func print(expr: Expr) -> String {
        return expr.accept(self)
    }

    func visit(_ literal: Literal) -> ReturnType {
        return literal.value.toString
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

    private func parenthesize(name: String, expr: Expr...) -> String {
        return "(\(name) \(expr.map { $0.accept(self) }.joined(separator: " ")))"
    }
}*/
