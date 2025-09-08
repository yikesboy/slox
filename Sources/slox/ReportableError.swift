protocol ReportableError: Error {
    var errorType: String { get }
    var line: Int { get }
    var message: String { get }
}
