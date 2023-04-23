import Foundation
import PackagePlugin

@main
struct GeneratePackageMetadata: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        // Package Header
        var gneratedCode = try getPackageBaseInformations(package: context.package)
        // Code Top Contributors
        gneratedCode.append(try getPackageContributors(folderPath: context.package.directory.string))
        //Dependencies Diagram
        gneratedCode.append(getDependenciesDiagram(dependencies: context.package.dependencies))
        // Products Class Diagram
        gneratedCode.append(generateProductsClassDiagram(packageTargets: context.package.targets))

        try writeToFile(
            contents: gneratedCode
        )
    }
    
}

extension GeneratePackageMetadata {
    /// Returns the package base header informations
    /// - Parameter package: PackagePlugin
    /// - Returns: Base informations
    func getPackageBaseInformations(package: PackagePlugin.Package) throws -> String {
        """
        # Package: \(package.displayName) 📦
        -  Last changed date: *\(try getLastUpdateDate(folderPath: package.directory.string))*
        -  ToolsVersion: *\(package.toolsVersion)*
        -  Origin: *\(package.origin)*
        -  Directory: *\(package.directory.stem)*
        -  Dependencies Count: *\(package.dependencies.count)*
        -  Products Count: *\(package.products.count)*
        -  Targets Count: *\(package.targets.count)*
        \n
        """
    }
    
    /// Returns the packag last changed date
    func getLastUpdateDate(folderPath: String) throws -> String {
        try runGitCommand(arguments: ["log", "-1", "--format=%cd", "--", folderPath])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
         
        \n
        """
    }
}

extension GeneratePackageMetadata {
    // Generate Mermaid target dependencies diagram syntax
    func generateProductsClassDiagram(packageTargets: [Target]) -> String {
        var mermaidSyntax = ""
        for target in packageTargets {
            mermaidSyntax.append("\n## \(target.name):\n\n```mermaid\nclassDiagram\ndirection RL\n")
            target.recursiveTargetDependencies.forEach({
                mermaidSyntax.append("\(target.name) ..> \($0.name)\n")
            })
            mermaidSyntax.append("```")
        }
        return mermaidSyntax
    }
    
    // Generate Mermaid package dependencies diagram syntax
    func getDependenciesDiagram(dependencies: [PackagePlugin.PackageDependency]) ->String{
        var mermaidSyntax = "## Pckage Dependencies:\n\n```mermaid\nclassDiagram\ndirection RL\n"
        for dependency in dependencies {
            mermaidSyntax.append("class \(dependency.package.displayName)\n")
        }
        mermaidSyntax.append("```")
        return mermaidSyntax
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
