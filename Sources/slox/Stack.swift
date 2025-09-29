struct Stack<Key: Equatable & Hashable, Value> {
    private var elements: [[Key: Value]] = []

    var isEmpty: Bool {
        return elements.isEmpty
    }

    var size: Int {
        return elements.count
    }

    var topToBottom: ReversedCollection<[[Key: Value]]> {
        return elements.reversed()
    }

    mutating func push(_ item: [Key: Value]) {
        elements.append(item)
    }

    mutating func pop() -> [Key: Value]? {
        return elements.popLast()
    }

    mutating func withTopElement<R>(_ body: (inout [Key: Value]) -> R) -> R? {
        guard !elements.isEmpty else { return nil }
        return body(&elements[elements.count - 1])
    }

    func peek() -> [Key: Value]? {
        return elements.last
    }

    func containsKey(key: Key) -> Bool {
        return elements.contains { dict in
            dict.keys.contains(key)
        }
    }
}
