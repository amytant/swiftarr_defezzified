import Vapor
import FluentPostgreSQL

// model uses Int as primary key
extension Forum: PostgreSQLModel {}

// model can be passed as HTTP body data
extension Forum: Content {}

// model can be used as endpoint parameter
extension Forum: Parameter {}

// MARK: - Custom Migration

extension Forum: Migration {
    /// Required by `Migration` protocol. Creates the table, with foreign key  constraint
    /// to `Category`.
    ///
    /// - Parameter connection: The connection to the database, usually the Request.
    /// - Returns: Void.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) {
            (builder) in
            try addProperties(to: builder)
            // foreign key constraint to Category
            builder.reference(from: \.categoryID, to: \Category.id)
        }
    }
}

// MARK: - Timestamping Conformance

extension Forum {
    /// Required key for `\.createdAt` functionality.
    static var createdAtKey: TimestampKey? { return \.createdAt }
    /// Required key for `\.updatedAt` functionality.
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    /// Required key for `\.deletedAt` soft delete functionality.
    static var deletedAtKey: TimestampKey? { return \.deletedAt }
}
