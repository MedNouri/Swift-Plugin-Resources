// swift-tools-version: 5.7
import PackageDescription

let pluginName = "GenerateAssetResources"
let description = "Generate Asset Resources"
let permissionReason = "The plugin writes the generaterated assets swift file"
let packageMetadataPluginName = "GeneratePackageMetadata"
let packageMetadataPluginDescription = "Generate Package Metadata"
let packageMetadataPluginPermissionReason = "The plugin writes the generaterated README.md file"

let package = Package(
  name: "SwiftPluginResources",
  platforms: [
         .macOS(.v10_15),
         .iOS(.v13),
   ],
  products: [
    .plugin(
      name: "AssetResources",
      targets: [pluginName]
    ),
    .plugin(
      name: "GeneratePackageMetadata",
      targets: [packageMetadataPluginName]
    )
  ],

  targets: [
    .plugin(
      name: pluginName,
      capability: .command(
        intent: .custom(
          verb: "generate-asset-resources",
          description: description
        ),
        permissions: [
          .writeToPackageDirectory(reason: permissionReason)
        ]
      )
    ),
    .plugin(
      name: packageMetadataPluginName,
      capability: .command(
        intent:  .custom(
            verb: "generate-package-metadata",
            description: description
          ),
        permissions: [
          .writeToPackageDirectory(reason: packageMetadataPluginPermissionReason)
        ]
      )
    )
  ]
)
