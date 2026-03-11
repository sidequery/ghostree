import Foundation
import Testing
@testable import Ghostree

struct TerminalRepoPromptTests {
    private func session(source: SessionSource = .codex) -> AISession {
        .init(
            id: "session-1",
            source: source,
            worktreePath: "/tmp/repo",
            cwd: "/tmp/repo",
            timestamp: Date(timeIntervalSince1970: 123),
            snippet: "Working",
            sourcePath: "/tmp/session.jsonl",
            messageCount: 3
        )
    }

    private func openPR() -> PRStatus {
        .init(
            number: 42,
            title: "Refine prompt actions",
            headRefName: "feature/repo-prompts",
            state: "OPEN",
            url: "https://github.com/sidequery/ghostree/pull/42",
            checks: [],
            updatedAt: Date(timeIntervalSince1970: 200),
            fetchedAt: Date(timeIntervalSince1970: 201)
        )
    }

    @Test func dirtySnapshotResolvesToCommit() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session()],
            hasDirtyChanges: true,
            openPR: nil,
            gitTracking: nil
        )

        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)
        #expect(ready.primaryAction == .commit)
        #expect(ready.shortcutAction?.action == .commitAndPush)
        #expect(ready.state(for: .commit)?.isAvailable == true)
        #expect(ready.state(for: .push)?.description == "Commit changes first.")
        #expect(ready.state(for: .openPR)?.description == "Commit changes first.")
        #expect(ready.state(for: .updatePR)?.description == "No open PR for this branch.")
    }

    @Test func dirtySnapshotWithoutKnownSessionsStillResolves() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [],
            hasDirtyChanges: true,
            openPR: nil,
            gitTracking: nil
        )

        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)
        #expect(ready.primaryAction == .commit)
        #expect(ready.shortcutAction?.action == .commitAndPush)
        #expect(ready.state(for: .commit)?.isAvailable == true)
    }

    @Test func cleanSnapshotWithoutPRResolvesToPushBeforeOpenPR() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session()],
            hasDirtyChanges: false,
            openPR: nil,
            gitTracking: .init(
                hasUpstream: true,
                ahead: 1,
                behind: 0,
                stagedCount: 0,
                unstagedCount: 0,
                untrackedCount: 0,
                totalChangesCount: 0,
                lineAdditions: 0,
                lineDeletions: 0
            )
        )

        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)
        #expect(ready.primaryAction == .push)
        #expect(ready.shortcutAction?.action == .pushAndOpenPR)
        #expect(ready.state(for: .push)?.isAvailable == true)
        #expect(ready.state(for: .openPR)?.description == "Push the branch first.")
    }

    @Test func cleanSnapshotWithRemoteBranchResolvesToOpenPR() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session()],
            hasDirtyChanges: false,
            openPR: nil,
            gitTracking: .init(
                hasUpstream: true,
                ahead: 0,
                behind: 0,
                stagedCount: 0,
                unstagedCount: 0,
                untrackedCount: 0,
                totalChangesCount: 0,
                lineAdditions: 0,
                lineDeletions: 0
            )
        )

        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)
        #expect(ready.primaryAction == .openPR)
        #expect(ready.shortcutAction == nil)
        #expect(ready.state(for: .openPR)?.isAvailable == true)
        #expect(ready.state(for: .push)?.description == "Nothing to push.")
    }

    @Test func cleanSnapshotWithOpenPRAndAheadResolvesToPush() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session()],
            hasDirtyChanges: false,
            openPR: openPR(),
            gitTracking: .init(
                hasUpstream: true,
                ahead: 2,
                behind: 0,
                stagedCount: 0,
                unstagedCount: 0,
                untrackedCount: 0,
                totalChangesCount: 0,
                lineAdditions: 0,
                lineDeletions: 0
            )
        )

        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)
        #expect(ready.primaryAction == .push)
        #expect(ready.shortcutAction?.action == .pushAndUpdatePR)
        #expect(ready.state(for: .updatePR)?.description == "Push latest commits first.")
    }

    @Test func cleanSnapshotWithOpenPRAndNoPushNeededResolvesToUpdatePR() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session()],
            hasDirtyChanges: false,
            openPR: openPR(),
            gitTracking: .init(
                hasUpstream: true,
                ahead: 0,
                behind: 0,
                stagedCount: 0,
                unstagedCount: 0,
                untrackedCount: 0,
                totalChangesCount: 0,
                lineAdditions: 0,
                lineDeletions: 0
            )
        )

        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)
        #expect(ready.primaryAction == .updatePR)
        #expect(ready.shortcutAction == nil)
        #expect(ready.state(for: .updatePR)?.isAvailable == true)
        #expect(ready.state(for: .push)?.description == "Nothing to push.")
    }

    @Test func openPRPromptIsCompactAndIncludesHeaderRule() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session(source: .claude), session(source: .codex)],
            hasDirtyChanges: false,
            openPR: nil,
            gitTracking: nil
        )
        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)

        let prompt = TerminalRepoPrompt.prompt(for: .openPR, readyState: ready)

        #expect(prompt.contains("In /tmp/repo on branch feature/repo-prompts"))
        #expect(prompt.contains("write the PR summary with no markdown headers"))
        #expect(!prompt.contains("Known AI session sources"))
        #expect(!prompt.contains("Resolved action:"))
    }

    @Test func commitAndPushPromptIncludesPushStep() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session()],
            hasDirtyChanges: true,
            openPR: nil,
            gitTracking: nil
        )
        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)

        let prompt = TerminalRepoPrompt.prompt(for: .commitAndPush, readyState: ready)

        #expect(prompt.contains("create exactly one appropriate commit"))
        #expect(prompt.contains("then push the branch"))
    }

    @Test func updatePRPromptIncludesExistingPRContext() {
        let snapshot = TerminalRepoPromptSnapshot(
            repoRoot: "/tmp/repo",
            branch: "feature/repo-prompts",
            sessions: [session()],
            hasDirtyChanges: false,
            openPR: openPR(),
            gitTracking: nil
        )
        let ready = TerminalRepoPrompt.classify(snapshot: snapshot)

        let prompt = TerminalRepoPrompt.prompt(for: .updatePR, readyState: ready)

        #expect(prompt.contains("update PR #42 if needed"))
        #expect(prompt.contains("Do not push or create commits or create a new PR."))
    }
}
