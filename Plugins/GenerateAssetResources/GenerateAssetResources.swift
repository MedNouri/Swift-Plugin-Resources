import Foundation
import PackagePlugin

@main
struct GenerateAssetResources: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        let fileName = "ImageAssets.swift"
        try context.package.targets.forEach { target in
            guard let sourcetarget = target as? SourceModuleTarget else {
                return
            }
            var gneratedCode:String? = ""
            try sourcetarget.sourceFiles(withSuffix: "xcassets").forEach { file in
                gneratedCode?.append(try findAssets(within: file.path.string))
            }
            
            guard let gneratedAssetsCode = gneratedCode else {
                print("No element found at \(target.name)")
                return
            }
            
            try writeToFile(
                contents: baseGneratedCode + gneratedAssetsCode,
                file: fileName,
                target: sourcetarget
            )
        }
    }
}



extension GenerateAssetResources{
    /// writes string contents to file using .utf8 encoding
    /// - Parameters:
    ///   - contents: String contents
    ///   - file: The file name
    ///   - target: The Source Module Target
    private func writeToFile(contents: String, file: String, target: SourceModuleTarget) throws{
        try contents.write(
            toFile: target.directory.string.appending("/Ressources").appending(file),
            atomically: true,
            encoding: .utf8
        )
    }
}

extension GenerateAssetResources{
    /// find image contents within a givin director
    /// - Parameter input: directory path
    /// - Returns: Generated swiftUI Image variable declarationS
    private func findAssets(within path: String) throws -> String  {
        var result  = ""
        try FileManager.default.contentsOfDirectory(atPath: path).forEach({ dirent in
            guard dirent.hasSuffix("imageset") else {
                return
            }
            
            let contentJsonUrl = URL(fileURLWithPath: "\(path)/\(dirent)/Contents.json")
            let jsonData = try Data(contentsOf: contentJsonUrl)
            let asset = try JSONDecoder().decode(Contents.self, from: jsonData)
            if !asset.images.compactMap(\.filename).isEmpty {
                let baseName = contentJsonUrl.deletingLastPathComponent().deletingPathExtension().lastPathComponent
                result.append("let \(baseName) = Image(\"\(baseName)\", bundle: .module)\n")
            }
        })
        return result
    }
}
