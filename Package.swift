// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "TravelKit",
	platforms: [
		.macOS(.v10_14),
		.iOS(.v12),
		.tvOS(.v12),
		.watchOS(.v5),
	],
	products: [
		.library(name: "TravelKit",
		         targets: ["TravelKit"]),
		.library(name: "TravelKit-Dynamic",
		         type: .dynamic, targets: ["TravelKit"]),
		.library(name: "TravelKit-Static",
		         type: .static, targets: ["TravelKit"]),
	],
	dependencies: [
		.package(url: "https://github.com/ccgus/fmdb.git", from: "2.7.7"),
	],
	targets: [
		.target(
			name: "TravelKit",
			dependencies: [
				.product(name: "FMDB", package: "fmdb"),
			],
			path: "TravelKit",
			exclude: [
				"Info.plist",
				"Config.xcconfig",
				"TravelKit-Prefix.pch",
			],
			publicHeadersPath: "PublicHeaders",
			cSettings: [
				.headerSearchPath("PublicHeaders"),
				.define("USE_NSOBJECT_PARSING", to: "1"),
				.define("USE_TRAVELKIT_FOUNDATION", to: "1"),
				.define("USE_TRAVELKIT_AS_SPM_PACKAGE", to: "1"),
			]
		),
	]
)
