import AppKit
import Foundation

enum WorktrunkAgent: String, CaseIterable, Identifiable {
    case claude
    case codex
    case opencode
    case agent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .claude: return "Claude Code"
        case .codex: return "Codex"
        case .opencode: return "OpenCode"
        case .agent: return "Cursor Agent"
        }
    }

    var command: String {
        switch self {
        case .claude: return "claude"
        case .codex: return "codex"
        case .opencode: return "opencode"
        case .agent: return "agent"
        }
    }

    var isAvailable: Bool {
        Self.isExecutableAvailable(command)
    }

    static func availableAgents() -> [WorktrunkAgent] {
        allCases.filter { $0.isAvailable }
    }

    static func preferredAgent(from rawValue: String, availableAgents: [WorktrunkAgent]) -> WorktrunkAgent? {
        if let preferred = WorktrunkAgent(rawValue: rawValue),
           availableAgents.contains(preferred) {
            return preferred
        }
        return availableAgents.first
    }

    private static func isExecutableAvailable(_ name: String) -> Bool {
        let binDir = AgentStatusPaths.binDir.path
        for path in searchPaths(excluding: binDir) {
            let candidate = URL(fileURLWithPath: path).appendingPathComponent(name).path
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return true
            }
        }
        return false
    }

    private static func searchPaths(excluding excludedPath: String) -> [String] {
        var paths: [String] = []
        let prefix = ["/opt/homebrew/bin", "/usr/local/bin"]
        let existingPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let existingComponents = existingPath.split(separator: ":").map(String.init)

        for path in prefix + existingComponents {
            let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let normalized = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
            guard normalized != excludedPath else { continue }
            if !paths.contains(normalized) {
                paths.append(normalized)
            }
        }

        return paths
    }
}

enum WorktrunkDefaultAction: String, CaseIterable, Identifiable {
    case terminal
    case claude
    case codex
    case opencode
    case agent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terminal: return "Terminal"
        case .claude: return "Claude Code"
        case .codex: return "Codex"
        case .opencode: return "OpenCode"
        case .agent: return "Cursor Agent"
        }
    }

    var agent: WorktrunkAgent? {
        switch self {
        case .terminal: return nil
        case .claude: return .claude
        case .codex: return .codex
        case .opencode: return .opencode
        case .agent: return .agent
        }
    }

    var isAvailable: Bool {
        switch self {
        case .terminal: return true
        default: return agent?.isAvailable ?? false
        }
    }

    static func availableActions() -> [WorktrunkDefaultAction] {
        allCases.filter { $0.isAvailable }
    }

    static func preferredAction(from rawValue: String, availableActions: [WorktrunkDefaultAction]) -> WorktrunkDefaultAction {
        if let preferred = WorktrunkDefaultAction(rawValue: rawValue),
           availableActions.contains(preferred) {
            return preferred
        }
        return .terminal
    }
}

enum WorktrunkOpenBehavior: String, CaseIterable, Identifiable {
    case newTab = "new_tab"
    case splitRight = "split_right"
    case splitDown = "split_down"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newTab: return "New Tab"
        case .splitRight: return "Split Right"
        case .splitDown: return "Split Down"
        }
    }
}

enum ExternalEditorCategory: String {
    case editors
    case git
    case finder
}

enum ExternalEditor: String, CaseIterable, Identifiable {
    // Editors
    case cursor
    case vscode
    case vscodium
    case zed
    case sublime
    case nova
    case textmate
    case xcode
    // JetBrains
    case intellij
    case webstorm
    case pycharm
    case goland
    case rubymine
    case clion
    case rider
    case phpstorm
    case fleet
    // Git clients
    case tower
    case fork
    case gitkraken
    case sourcetree
    case githubDesktop
    // Finder
    case finder

    var id: String { rawValue }

    var category: ExternalEditorCategory {
        switch self {
        case .tower, .fork, .gitkraken, .sourcetree, .githubDesktop:
            return .git
        case .finder:
            return .finder
        default:
            return .editors
        }
    }

    var title: String {
        switch self {
        case .cursor: return "Cursor"
        case .vscode: return "VS Code"
        case .vscodium: return "VSCodium"
        case .zed: return "Zed"
        case .sublime: return "Sublime Text"
        case .nova: return "Nova"
        case .xcode: return "Xcode"
        case .textmate: return "TextMate"
        case .intellij: return "IntelliJ IDEA"
        case .webstorm: return "WebStorm"
        case .pycharm: return "PyCharm"
        case .goland: return "GoLand"
        case .rubymine: return "RubyMine"
        case .clion: return "CLion"
        case .rider: return "Rider"
        case .phpstorm: return "PhpStorm"
        case .fleet: return "Fleet"
        case .tower: return "Tower"
        case .fork: return "Fork"
        case .gitkraken: return "GitKraken"
        case .sourcetree: return "Sourcetree"
        case .githubDesktop: return "GitHub Desktop"
        case .finder: return "Finder"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .cursor: return "com.todesktop.230313mzl4w4u92"
        case .vscode: return "com.microsoft.VSCode"
        case .vscodium: return "com.vscodium"
        case .zed: return "dev.zed.Zed"
        case .sublime: return "com.sublimetext.4"
        case .nova: return "com.panic.Nova"
        case .xcode: return "com.apple.dt.Xcode"
        case .textmate: return "com.macromates.TextMate"
        case .intellij: return "com.jetbrains.intellij"
        case .webstorm: return "com.jetbrains.WebStorm"
        case .pycharm: return "com.jetbrains.pycharm"
        case .goland: return "com.jetbrains.goland"
        case .rubymine: return "com.jetbrains.rubymine"
        case .clion: return "com.jetbrains.CLion"
        case .rider: return "com.jetbrains.rider"
        case .phpstorm: return "com.jetbrains.PhpStorm"
        case .fleet: return "fleet.app"
        case .tower: return "com.fournova.Tower3"
        case .fork: return "com.DanPristupov.Fork"
        case .gitkraken: return "com.axosoft.gitkraken"
        case .sourcetree: return "com.torusknot.SourceTreeNotMAS"
        case .githubDesktop: return "com.github.GitHubClient"
        case .finder: return "com.apple.finder"
        }
    }

    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    var isInstalled: Bool {
        appURL != nil
    }

    var appIcon: NSImage? {
        guard let url = appURL else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    static func installedEditors() -> [ExternalEditor] {
        allCases.filter { $0.isInstalled }
    }

    static func installedByCategory() -> [(category: ExternalEditorCategory, editors: [ExternalEditor])] {
        let installed = installedEditors()
        var result: [(category: ExternalEditorCategory, editors: [ExternalEditor])] = []
        for cat in [ExternalEditorCategory.editors, .git, .finder] {
            let group = installed.filter { $0.category == cat }
            if !group.isEmpty {
                result.append((category: cat, editors: group))
            }
        }
        return result
    }
}

enum WorktrunkPreferences {
    static let openBehaviorKey = "GhosttyWorktrunkOpenBehavior.v1"
    static let worktreeTabsKey = "GhosttyWorktreeTabs.v1"
    static let sidebarTabsKey = "GhostreeWorktrunkSidebarTabs.v1"
    static let defaultAgentKey = "GhosttyWorktrunkDefaultAgent.v1"
    static let githubIntegrationKey = "GhostreeGitHubIntegration.v1"
    static let lastEditorKey = "GhostreeLastEditor.v1"

    static var worktreeTabsEnabled: Bool {
        UserDefaults.standard.bool(forKey: worktreeTabsKey)
    }

    static var sidebarTabsEnabled: Bool {
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains(sidebarTabsKey) {
            return true
        }
        return UserDefaults.standard.bool(forKey: sidebarTabsKey)
    }

    static var githubIntegrationEnabled: Bool {
        // Default to true if gh CLI is likely available
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains(githubIntegrationKey) {
            return true  // Default enabled
        }
        return UserDefaults.standard.bool(forKey: githubIntegrationKey)
    }

    static var lastEditor: ExternalEditor? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: lastEditorKey) else { return nil }
            return ExternalEditor(rawValue: raw)
        }
        set {
            UserDefaults.standard.set(newValue?.rawValue, forKey: lastEditorKey)
        }
    }

    static var preferredEditor: ExternalEditor? {
        let installed = ExternalEditor.installedEditors()
        if let last = lastEditor, installed.contains(last) {
            return last
        }
        return installed.first
    }
}
