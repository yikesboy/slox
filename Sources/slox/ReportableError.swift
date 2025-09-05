protocol ReportableError: Error {
    var line: Int { get }
    var message: String { get }
}
