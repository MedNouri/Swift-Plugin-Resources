import Foundation
import PackagePlugin

@main
struct GeneratePackageMetadata: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        // Package Header
        var gneratedCode = getPackageBaseInformations(package: context.package)
        // Code Top Contributors
        gneratedCode.append(try getPackageContributors(folderPath: context.package.directory.string))
        try writeToFile(
            contents: gneratedCode
        )
    }
    
}

extension GeneratePackageMetadata {
    /// Returns the package base header informations
    /// - Parameter package: PackagePlugin
    /// - Returns: Base informations
    func getPackageBaseInformations(package: PackagePlugin.Package) -> String {
        """
        # Package: \(package.displayName) 📦
        -  ToolsVersion: *\(package.toolsVersion)*
        -  Origin: *\(package.origin)*
        -  Directory: *\(package.directory.stem)*
        -  Dependencies Count: *\(package.dependencies.count)*
        -  Products Count: *\(package.products.count)*
        -  Targets Count: *\(package.targets.count)*
        \n
        """
    }
    
    /// Runs a Git Command
    /// - Parameter arguments: Git arguments
    /// - Returns: outputData as String using .utf8 encoding
    func runGitCommand(arguments: [String]) throws -> String? {
        // Create a Process instance for the git command
        let gitProcess = Process()
        gitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")

        // Set up the standard output pipe to capture the command output
        let outputPipe = Pipe()
        gitProcess.standardOutput = outputPipe

        // Launch the git command
        gitProcess.arguments = arguments
        try gitProcess.run()

        // Read the output from the standard output pipe
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: outputData, encoding: .utf8)
    }
}

extension GeneratePackageMetadata {
    func getPackageContributors(folderPath: String, limit: Int = 7) throws -> String {
        """
         ## Top contributors:
         
         """
    }
}

extension GeneratePackageMetadata{
    /// writes string contents to README.md using .utf8 encoding
    /// - Parameters:
    ///   - contents: String contents
    ///   - file: The file name
    ///   - target: The Source Module Target
    private func writeToFile(contents: String) throws{
        try contents.write(
            toFile: "README.md",
            atomically: true,
            encoding: .utf8
        )
    }
}
