// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "TravelKit",
	platforms: [
		.macOS(.v10_10),
		.iOS(.v9),
		.tvOS(.v9),
		.watchOS(.v3)
	],
	products: [
		.library(
			name: "TravelKit",
			targets: ["TravelKit"]),
		.library(
			name: "TravelKit-Dynamic",
			type: .dynamic,
			targets: ["TravelKit"]),
		.library(
			name: "TravelKit-Static",
			type: .static,
			targets: ["TravelKit"]),
	],
	dependencies: [
	.package(name: "FMDB", url: "https://github.com/ccgus/fmdb", from: "2.7.7")
	],
	targets: [
		.target(
			name: "TravelKit",
			dependencies: ["FMDB"],
			path: "TravelKit",
			exclude: [
				"Info.plist",
				"Config.xcconfig",
				"TravelKit-Prefix.pch"
			],
			publicHeadersPath: "PublicHeaders",
			cSettings: [
				.headerSearchPath("PublicHeaders"),
				.define("USE_NSOBJECT_PARSING", to: "1"),
				.define("USE_TRAVELKIT_FOUNDATION", to: "1"),
				.define("USE_TRAVELKIT_AS_SPM", to: "1")
			]
		),
	]
)
