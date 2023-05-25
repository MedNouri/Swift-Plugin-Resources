import Foundation
import PackagePlugin

@main
struct GeneratePackageMetadata: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        // Package Header
        var gneratedCode = try getPackageBaseInformations(package: context.package)
        // Code Top Contributors
        gneratedCode.append(try getPackageContributors(directoryPath: context.package.directory))
        //Pakcage Files Statistics
        gneratedCode.append(getPakcageStatistics(context: context))
        //Dependencies Table
        gneratedCode.append(getDependenciesTable(dependencies: context.package.dependencies))
        // Products Class Diagram
        gneratedCode.append(generateProductsClassDiagram(packageTargets: context.package.targets))
        //Dependecies Usage Graph
        gneratedCode.append(getDependeciesUsageGraph(context: context, dependencies: context.package.dependencies))
        
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
        -  Last changed date: *\(try getLastUpdateDate(folderPath: package.directory.removingLastComponent().string))*
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
    /// Returns the Contributors Array.
    func getPackageContributors(directoryPath: Path , limit : Int = 7) throws -> String {
        let arguments = ["-C", directoryPath.removingLastComponent().string, "shortlog", "-s", "-n", "--all", "--no-merges", "--", directoryPath.lastComponent]
        
        guard let output = try runGitCommand(arguments: arguments) else {
            throw NSError(domain: "GitError", code: -1, userInfo: nil)
        }
        
        var markdownTable = "\n## Contributors \n\n| Number of Commits | Committer | Last Commit Date |\n"
        markdownTable.append("|------|-----------|-----------------|\n")
        
        let contributors = output.split(separator: "\n")
        let topContributors = contributors.prefix(limit)
        for contributor in topContributors {
            let components = contributor.split(separator: "\t")
            if components.count == 2 {
                let commitCount = components[0]
                let authorName = components[1]
                let lastCommitDate = getLastCommitDate(for: String(authorName), in: directoryPath)
                markdownTable.append("| \(commitCount) | \(authorName) | \(lastCommitDate) | \n")
            }
        }
        
        return markdownTable
    }
    
    func getLastCommitDate(for author: String, in directoryPath: Path) -> String {
        let arguments = ["-C", directoryPath.string, "log", "-1", "--author=\(author)", "--format=%cd", "--date=short"]
        
        guard let output = try? runGitCommand(arguments: arguments) else {
            return "N/A"
        }
        
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedOutput
    }
    
}

extension GeneratePackageMetadata {
    // Generate Mermaid target dependencies diagram syntax
    func generateProductsClassDiagram(packageTargets: [Target]) -> String {
        func mapNamingToAnnotation(name: String) -> String{
            if name.contains("Contract") {
                return "class \(name)\n<<interface>> \(name)\n "
            }
            if name.contains("Mock") {
                return "class \(name)\n<<Mock>> \(name)\n "
            }
            return "class \(name)\n"
        }
        var alreadyAdd:Set<String> = []
        var mermaidSyntax = "## Dependency Graph \n\n```mermaid\nclassDiagram\ndirection RL\n"
        for target in packageTargets {
            target.recursiveTargetDependencies.forEach({
                if !alreadyAdd.contains($0.name){
                    alreadyAdd.insert($0.name)
                    mermaidSyntax.append(mapNamingToAnnotation(name: $0.name))
                }
                mermaidSyntax.append("\(target.name) ..> \($0.name)\n")
            })
        }
        mermaidSyntax.append("```")
        return mermaidSyntax
    }
    
    // Generate package dependencies table syntax
    func getDependenciesTable(dependencies: [PackagePlugin.PackageDependency]) -> String {
        var markdownTable = "## Package Dependencies:\n\n"
        markdownTable += "| Index | Dependency | Origin |\n"
        markdownTable += "|-------|------------|--------|\n"
        
        for (index, dependency) in dependencies.enumerated() {
            markdownTable += "|  \(index + 1)  |  \(dependency.package.displayName)  | \(dependency.package.origin)  |\n"
        }
        
        return markdownTable
    }
    
}
extension GeneratePackageMetadata {
    func getDependeciesUsageGraph(context: PackagePlugin.PluginContext,dependencies: [PackagePlugin.PackageDependency]) -> String{
        var mermaidSyntax = "\n ## Dependecies Usage \n\n"
        context.package.targets.forEach { target in
            guard let sourcetarget = target as? SourceModuleTarget , sourcetarget.kind == .generic else {
                return
            }
            sourcetarget.sourceFiles.forEach { file in
                let extractedDependencies = extractDependencies(fromFileAtPath: file.path.string, packageDependencies: dependencies)
                if extractedDependencies.isEmpty {
                    return
                }
                mermaidSyntax.append("\n```mermaid\n")
                mermaidSyntax.append("classDiagram\n")
                
                mermaidSyntax.append(generateMermaidCode(
                    filename: file.path.stem,
                    dependencies: extractedDependencies
                ))
                mermaidSyntax.append("```\n")
            }
        }
        return mermaidSyntax
    }
    
    func getPakcageStatistics(context: PackagePlugin.PluginContext) -> String{
        var mermaidSyntax = "\n## Package Structure\n"
        var numberOfSourceFiles = 0
        var numberOfTestFiles = 0
        var numberOfAssetsFiles = 0
        
        context.package.targets.forEach { target in
            guard let sourcetarget = target as? SourceModuleTarget else {
                return
            }
            sourcetarget.sourceFiles(withSuffix: "xcassets").forEach { file in
                try? FileManager.default.contentsOfDirectory(atPath: file.path.string).forEach({ dirent in
                    guard dirent.hasSuffix("imageset") else {
                        return
                    }
                    numberOfAssetsFiles += 1
                })
            }
            if sourcetarget.kind == .generic {
                sourcetarget.sourceFiles.forEach { file in
                    numberOfSourceFiles += 1
                }
            }
            
            if sourcetarget.kind == .test {
                sourcetarget.sourceFiles.forEach { file in
                    numberOfTestFiles += 1
                }
            }
        }
        
        mermaidSyntax += "\n| File Type | Sum |\n"
        mermaidSyntax += "|-------|------------|\n"
        mermaidSyntax += "| Files |**\(numberOfAssetsFiles + numberOfTestFiles + numberOfAssetsFiles)**|\n"
        mermaidSyntax += "| Swift files |\(numberOfTestFiles)|\n"
        mermaidSyntax += "| Tests |\(numberOfTestFiles)|\n"
        mermaidSyntax += "| Assets |\(numberOfAssetsFiles)|\n"
        mermaidSyntax.append("\n```mermaid\npie title Files\n")
        mermaidSyntax.append("\"Tests\" : \(numberOfTestFiles)\n")
        mermaidSyntax.append("\"SwiftFiles\" : \(numberOfSourceFiles)\n")
        mermaidSyntax.append("\"Assets\" : \(numberOfAssetsFiles)\n")
        mermaidSyntax.append("```\n")
        return mermaidSyntax
    }
    
    
    func extractDependencies(fromFileAtPath filePath: String, packageDependencies: [PackagePlugin.PackageDependency]) -> [String] {
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let pattern = "import\\s+([A-Za-z_][A-Za-z_0-9]*)"
            
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            var dependencies: [String] = []
            let commonImports = packageDependencies.map({ a in
                a.package.displayName
            })
            
            for match in matches {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: content) {
                    let dependency = String(content[swiftRange])
                    if commonImports.contains(dependency) {
                        dependencies.append(dependency)
                    }
                }
            }
            
            return dependencies
        } catch {
            print("Failed to read file at path: \(filePath), error: \(error)")
            return []
        }
    }
    
    func generateMermaidCode(
        filename:String,
        dependencies: [String]
    ) -> String {
        var mermaidCode = ""
        for dependency in dependencies {
            mermaidCode += "\(filename) ..> \(dependency)\n"
        }
        return mermaidCode
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
