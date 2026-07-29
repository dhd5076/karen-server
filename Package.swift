// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "KarenServer",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        
        //KarenShared
        .package(url: "https://github.com/dhd5076/karen-lib.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "KarenServer",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "KarenShared", package: "karen-lib"),
                .product(name: "KarenKit", package: "karen-lib"),
                .product(name: "KarenAtlas", package: "karen-lib")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "KarenServerTests",
            dependencies: [
                "KarenServer",
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "KarenAtlas", package: "karen-lib"),
                .product(name: "KarenKit", package: "karen-lib"),
                .product(name: "Vapor", package: "vapor")
            ]
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
