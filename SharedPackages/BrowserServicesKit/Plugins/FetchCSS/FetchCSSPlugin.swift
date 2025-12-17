#if canImport(PackagePlugin)
import Foundation
import PackagePlugin

@main
struct FetchCSS: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        return try buildCommands(
            packageDirectory: context.package.directory,
            workingDirectory: context.pluginWorkDirectory
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension FetchCSS: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
            let packageDirectory = try resolvePackageDirectory(from: target, projectDirectory: context.xcodeProject.directory)
            return try buildCommands(
                packageDirectory: packageDirectory,
                workingDirectory: context.pluginWorkDirectory
            )
    }
}
#endif

// MARK: - Helpers

private extension FetchCSS {
    func buildCommands(packageDirectory: Path, workingDirectory: Path) throws -> [Command] {
        let resourcesDirectory = packageDirectory
            .appending("Sources")
            .appending("ContentScopeScripts")
            .appending("Resources")

        if FileManager.default.fileExists(atPath: resourcesDirectory.string) {
            return []
        }

        let outputFilesDirectory = workingDirectory.appending("FetchCSSOutput")
        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: outputFilesDirectory.string), withIntermediateDirectories: true)

        let script = """
        NPM="$(/usr/bin/which npm)"
        "$NPM" install
        """

        return [
            .prebuildCommand(
                displayName: "FetchCSS: npm install",
                executable: Path("/bin/bash"),
                arguments: ["-clx", script],
                environment: [
                    "HOME": FileManager.default.homeDirectoryForCurrentUser.path,
                ],
                outputFilesDirectory: outputFilesDirectory
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
private extension FetchCSS {
    func resolvePackageDirectory(from target: XcodeTarget, projectDirectory: Path) throws -> Path {
        if let anyInput = target.inputFiles.first {
            var candidate = anyInput.path
            while candidate.stem.count > 1 {
                let potential = candidate.appending("Package.swift")
                if FileManager.default.fileExists(atPath: potential.string) {
                    return candidate
                }
                candidate = candidate.removingLastComponent()
            }
        }
        return projectDirectory
    }
}
#endif
#else
// Non-SPM environments: no-op for tooling that cannot import PackagePlugin.
#endif


