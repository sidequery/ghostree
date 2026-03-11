import Foundation

enum TerminalRepoPromptAction: String, CaseIterable {
    case smart
    case commit
    case commitAndPush
    case push
    case pushAndOpenPR
    case openPR
    case pushAndUpdatePR
    case updatePR

    static let menuActions: [TerminalRepoPromptAction] = [
        .commit,
        .push,
        .openPR,
        .updatePR,
    ]

    var title: String {
        switch self {
        case .smart: return "Smart"
        case .commit: return "Commit"
        case .commitAndPush: return "Commit + Push"
        case .push: return "Push"
        case .pushAndOpenPR: return "Push + Open PR"
        case .openPR: return "Open PR"
        case .pushAndUpdatePR: return "Push + Update PR"
        case .updatePR: return "Update PR"
        }
    }

    var paletteTitle: String {
        "Repo: \(title)"
    }
}

struct TerminalRepoPromptActionState: Equatable {
    let action: TerminalRepoPromptAction
    let isAvailable: Bool
    let description: String
}

struct TerminalRepoPromptShortcutState: Equatable {
    let action: TerminalRepoPromptAction
    let description: String
}

enum TerminalRepoPromptDisabledReason: Equatable {
    case noFocusedTerminal
    case noGitRepo
    case detachedHead
    case notGitHubRepo
    case ghUnavailable(String)

    var title: String {
        switch self {
        case .noFocusedTerminal:
            return "No Focused Terminal"
        case .noGitRepo:
            return "Not in a Git Repo"
        case .detachedHead:
            return "Detached HEAD"
        case .notGitHubRepo:
            return "Not a GitHub Repo"
        case .ghUnavailable:
            return "Unavailable"
        }
    }

    var description: String {
        switch self {
        case .noFocusedTerminal:
            return "Focus a terminal first."
        case .noGitRepo:
            return "The focused terminal is not inside a git repository."
        case .detachedHead:
            return "Switch to a branch first."
        case .notGitHubRepo:
            return "The current repository is not backed by GitHub."
        case .ghUnavailable(let detail):
            return detail
        }
    }
}

struct TerminalRepoPromptSnapshot: Equatable {
    let repoRoot: String
    let branch: String
    let sessions: [AISession]
    let hasDirtyChanges: Bool
    let openPR: PRStatus?
    let gitTracking: WorktrunkStore.GitTracking?
}

struct TerminalRepoPromptReadyState: Equatable {
    let snapshot: TerminalRepoPromptSnapshot
    let primaryAction: TerminalRepoPromptAction
    let shortcutAction: TerminalRepoPromptShortcutState?
    let actionStates: [TerminalRepoPromptActionState]

    func state(for action: TerminalRepoPromptAction) -> TerminalRepoPromptActionState? {
        actionStates.first(where: { $0.action == action })
    }

    func supports(_ action: TerminalRepoPromptAction) -> Bool {
        if action == .smart { return true }
        if shortcutAction?.action == action { return true }
        return state(for: action)?.isAvailable == true
    }
}

enum TerminalRepoPromptResolution: Equatable {
    case disabled(TerminalRepoPromptDisabledReason)
    case ready(TerminalRepoPromptReadyState)
}

enum TerminalRepoPrompt {
    static func classify(snapshot: TerminalRepoPromptSnapshot) -> TerminalRepoPromptReadyState {
        let actionStates = actionStates(for: snapshot)
        let primaryAction = actionStates.first(where: \.isAvailable)?.action ?? .commit
        let shortcutAction = shortcutAction(for: snapshot, primaryAction: primaryAction)

        return .init(
            snapshot: snapshot,
            primaryAction: primaryAction,
            shortcutAction: shortcutAction,
            actionStates: actionStates
        )
    }

    private static func shortcutAction(
        for snapshot: TerminalRepoPromptSnapshot,
        primaryAction: TerminalRepoPromptAction
    ) -> TerminalRepoPromptShortcutState? {
        let hasOpenPR = snapshot.openPR != nil
        let hasUpstream = snapshot.gitTracking?.hasUpstream ?? false
        let aheadCount = snapshot.gitTracking?.ahead ?? 0
        let needsPush = !hasUpstream || aheadCount > 0

        switch primaryAction {
        case .commit:
            return .init(
                action: .commitAndPush,
                description: "Create one commit, then push the current branch."
            )

        case .push where hasOpenPR:
            return .init(
                action: .pushAndUpdatePR,
                description: "Push the branch, then update the existing PR if needed."
            )

        case .push where needsPush:
            return .init(
                action: .pushAndOpenPR,
                description: "Push the branch, then open a PR."
            )

        default:
            return nil
        }
    }

    private static func actionStates(
        for snapshot: TerminalRepoPromptSnapshot
    ) -> [TerminalRepoPromptActionState] {
        let hasDirtyChanges = snapshot.hasDirtyChanges
        let hasOpenPR = snapshot.openPR != nil
        let hasUpstream = snapshot.gitTracking?.hasUpstream ?? false
        let aheadCount = snapshot.gitTracking?.ahead ?? 0
        let needsPush = !hasUpstream || aheadCount > 0

        return TerminalRepoPromptAction.menuActions.map { action in
            switch action {
            case .commit:
                if hasDirtyChanges {
                    return .init(
                        action: action,
                        isAvailable: true,
                        description: "Create one commit from the current working tree changes."
                    )
                }

                return .init(
                    action: action,
                    isAvailable: false,
                    description: "No uncommitted changes."
                )

            case .push:
                if hasDirtyChanges {
                    return .init(
                        action: action,
                        isAvailable: false,
                        description: "Commit changes first."
                    )
                }

                if needsPush {
                    let description = if hasOpenPR {
                        "Push the current branch to the existing PR branch."
                    } else if !hasUpstream {
                        "Push the current branch and set upstream if needed."
                    } else {
                        "Push the current branch."
                    }

                    return .init(
                        action: action,
                        isAvailable: true,
                        description: description
                    )
                }

                return .init(
                    action: action,
                    isAvailable: false,
                    description: "Nothing to push."
                )

            case .openPR:
                if hasDirtyChanges {
                    return .init(
                        action: action,
                        isAvailable: false,
                        description: "Commit changes first."
                    )
                }

                if hasOpenPR {
                    return .init(
                        action: action,
                        isAvailable: false,
                        description: "A PR is already open for this branch."
                    )
                }

                if !hasUpstream || aheadCount > 0 {
                    return .init(
                        action: action,
                        isAvailable: false,
                        description: "Push the branch first."
                    )
                }

                return .init(
                    action: action,
                    isAvailable: true,
                    description: "Open a PR for the current branch."
                )

            case .updatePR:
                if snapshot.openPR == nil {
                    return .init(
                        action: action,
                        isAvailable: false,
                        description: "No open PR for this branch."
                    )
                }

                if hasDirtyChanges {
                    return .init(
                        action: action,
                        isAvailable: false,
                        description: "Commit changes first."
                    )
                }

                if needsPush {
                    return .init(
                        action: action,
                        isAvailable: false,
                        description: "Push latest commits first."
                    )
                }

                return .init(
                    action: action,
                    isAvailable: true,
                    description: "Update the existing PR text if needed."
                )

            case .commitAndPush, .pushAndOpenPR, .pushAndUpdatePR:
                preconditionFailure("combo actions are not base menu actions")

            case .smart:
                preconditionFailure("smart is not a menu action")
            }
        }
    }

    static func prompt(
        for action: TerminalRepoPromptAction,
        readyState: TerminalRepoPromptReadyState
    ) -> String {
        let snapshot = readyState.snapshot
        let resolvedAction = action == .smart ? readyState.primaryAction : action
        let location = "In \(snapshot.repoRoot) on branch \(snapshot.branch)"
        let existingPR = snapshot.openPR.map { "PR #\($0.number)" }

        let prompt: String = switch resolvedAction {
        case .commit:
            "\(location), create exactly one appropriate commit for the current changes. Do not push or open or update a PR. If blocked, say why and stop."

        case .commitAndPush:
            "\(location), create exactly one appropriate commit for the current changes, then push the branch. Do not open or update a PR. If blocked, say why and stop."

        case .push:
            "\(location), push the current branch and set upstream if needed. Do not create or update a PR. If there is nothing to push, say so and stop."

        case .pushAndOpenPR:
            "\(location), push the current branch and set upstream if needed, then open a PR. Generate a clear title from the branch and changes, and write the PR summary with no markdown headers. If blocked, say why and stop."

        case .openPR:
            "\(location), open a PR for the current branch. Generate a clear title from the branch and changes, and write the PR summary with no markdown headers. Do not create extra commits unless needed to unblock the PR. If blocked, say why and stop."

        case .pushAndUpdatePR:
            "\(location), push the current branch and set upstream if needed, then update \(existingPR ?? "the existing PR") if needed. Keep the PR summary free of markdown headers. Do not create a new PR. If blocked, say why and stop."

        case .updatePR:
            "\(location), update \(existingPR ?? "the existing PR") if needed. Keep the PR summary free of markdown headers. Do not push or create commits or create a new PR. If the PR text is already correct, say so and stop."

        case .smart:
            preconditionFailure("smart must resolve to a concrete action")
        }

        return prompt + "\n"
    }

    @MainActor
    static func resolve(
        pwd: String?,
        worktrunkStore: WorktrunkStore?,
        gitDiffStore: GitDiffStore = GitDiffStore()
    ) async -> TerminalRepoPromptResolution {
        guard let pwd, !pwd.isEmpty else {
            return .disabled(.noFocusedTerminal)
        }

        guard let repoRoot = await gitDiffStore.repoRoot(for: pwd) else {
            return .disabled(.noGitRepo)
        }

        guard let branch = await gitDiffStore.currentBranch(repoRoot: repoRoot) else {
            return .disabled(.detachedHead)
        }

        let sessions = worktrunkStore?.sessions(for: repoRoot) ?? []

        let hasDirtyChanges: Bool
        do {
            hasDirtyChanges = try await gitDiffStore.statusEntries(repoRoot: repoRoot).isEmpty == false
        } catch {
            return .disabled(.ghUnavailable(error.localizedDescription))
        }

        do {
            _ = try await GHClient.getRepoInfo(repoPath: repoRoot)
        } catch let ghError as GHClientError {
            switch ghError {
            case .notGitHubRepo:
                return .disabled(.notGitHubRepo)
            default:
                return .disabled(.ghUnavailable(ghError.localizedDescription))
            }
        } catch {
            return .disabled(.ghUnavailable(error.localizedDescription))
        }

        let openPR: PRStatus?
        do {
            let pr = try await GHClient.prForBranch(repoPath: repoRoot, branch: branch)
            openPR = pr?.isOpen == true ? pr : nil
        } catch let ghError as GHClientError {
            return .disabled(.ghUnavailable(ghError.localizedDescription))
        } catch {
            return .disabled(.ghUnavailable(error.localizedDescription))
        }

        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: repoRoot,
            branch: branch,
            sessions: sessions,
            hasDirtyChanges: hasDirtyChanges,
            openPR: openPR,
            gitTracking: worktrunkStore?.gitTracking(for: repoRoot)
        )
        return .ready(classify(snapshot: snapshot))
    }
}
