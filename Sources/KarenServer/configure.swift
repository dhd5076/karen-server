import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "192.168.1.156",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "karen",
        password: Environment.get("DATABASE_PASSWORD") ?? "DB_PASSWORD",
        database: Environment.get("DATABASE_NAME") ?? "karen",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateLocation())
    
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
