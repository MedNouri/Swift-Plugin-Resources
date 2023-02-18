// swift-tools-version: 5.7
import PackageDescription

let pluginName = "GenerateAssetResources"
let description = "Generate Asset Resources"
let permissionReason = "The plugin writes the generaterated assets swift file"

let package = Package(
  name: "Swift-Plugin-Resources",
  products: [
    .plugin(
      name: "AssetResources",
      targets: [pluginName]
    )
  ],

  targets: [
    .plugin(
      name: pluginName,
      capability: .command(
        intent: .custom(
          verb: "Generate-Asset-Resources",
          description: description
        ),
        permissions: [
          .writeToPackageDirectory(reason: permissionReason)
        ]
      )
    )
  ]
)
