import PackagePlugin

@main
struct FetchCSS: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        []
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension FetchCSS: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        []
    }
}
#endif


