struct Stack<T> {
    private var elements: [T] = []

    var isEmpty: Bool {
        return elements.isEmpty
    }

    var size: Int {
        return elements.count
    }

    var topToBottom: ReversedCollection<[T]> {
        return elements.reversed()
    }

    mutating func push(_ item: T) {
        elements.append(item)
    }

    mutating func pop() -> T? {
        return elements.popLast()
    }

    mutating func withTopElement<R>(_ body: (inout T) -> R) -> R? {
        guard !elements.isEmpty else { return nil }
        return body(&elements[elements.count - 1])
    }

    func peek() -> T? {
        return elements.last
    }
}
