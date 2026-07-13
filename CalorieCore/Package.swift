// swift-tools-version: 5.10
import PackageDescription

let strictConcurrency: [SwiftSetting] = [
    .unsafeFlags(["-strict-concurrency=complete"])
]

let package = Package(
    name: "CalorieCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "FeatureDashboard", targets: ["FeatureDashboard"]),
        .library(name: "FeatureHistory", targets: ["FeatureHistory"]),
        .library(name: "FeatureLog", targets: ["FeatureLog"]),
        .library(name: "FeatureScanner", targets: ["FeatureScanner"]),
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
        .library(name: "FeatureWeight", targets: ["FeatureWeight"])
    ],
    targets: [
        // MARK: - Domain (framework-frei, keine Imports außer Foundation)

        .target(
            name: "Domain",
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            swiftSettings: strictConcurrency
        ),

        // MARK: - Data (SwiftData + Netzwerk, implementiert Domain-Protokolle)

        .target(
            name: "Data",
            dependencies: ["Domain"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data", "Domain"],
            swiftSettings: strictConcurrency
        ),

        // MARK: - DesignSystem (Tokens, Komponenten)

        .target(
            name: "DesignSystem",
            swiftSettings: strictConcurrency
        ),

        // MARK: - Features (importieren Domain + DesignSystem, niemals Data)

        .target(
            name: "FeatureDashboard",
            dependencies: ["Domain", "DesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "FeatureDashboardTests",
            dependencies: ["FeatureDashboard"],
            swiftSettings: strictConcurrency
        ),

        .target(
            name: "FeatureHistory",
            dependencies: ["Domain", "DesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "FeatureHistoryTests",
            dependencies: ["FeatureHistory"],
            swiftSettings: strictConcurrency
        ),

        .target(
            name: "FeatureLog",
            dependencies: ["Domain", "DesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "FeatureLogTests",
            dependencies: ["FeatureLog"],
            swiftSettings: strictConcurrency
        ),

        .target(
            name: "FeatureScanner",
            dependencies: ["Domain", "DesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "FeatureScannerTests",
            dependencies: ["FeatureScanner"],
            swiftSettings: strictConcurrency
        ),

        .target(
            name: "FeatureSettings",
            dependencies: ["Domain", "DesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "FeatureSettingsTests",
            dependencies: ["FeatureSettings"],
            swiftSettings: strictConcurrency
        ),

        .target(
            name: "FeatureWeight",
            dependencies: ["Domain", "DesignSystem"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "FeatureWeightTests",
            dependencies: ["FeatureWeight"],
            swiftSettings: strictConcurrency
        )
    ]
)
