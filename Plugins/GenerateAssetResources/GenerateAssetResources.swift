import Foundation
import PackagePlugin

@main
struct GenerateAssetResources: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        let fileName = "ImageAssetsRessources.swift"
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
        let folderPath = target.directory.string.appending("/Utils")
        do {
            try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            let filePath = folderPath.appending("/\(file)")
            
            do {
                try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
                print("File created and written successfully.")
            } catch {
                print("Error writing file: \(error)")
            }
        } catch {
            print("Error creating folder: \(error)")
        }
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
                let camelCaseBaseName = baseName.split(separator: "-").reduce("") { $0 + $1.capitalized }
                result.append("let \(camelCaseBaseName.prefix(1).lowercased() + camelCaseBaseName.dropFirst()) = Image(\"\(baseName)\", bundle: .module)\n")
            }
        })
        return result
    }
}
