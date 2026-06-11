#if os(macOS)
import AppKit

enum RepoPromptSplitButton {
    private static let fallbackImage = NSImage(
        systemSymbolName: "arrow.trianglehead.branch",
        accessibilityDescription: "Repo action"
    ) ?? NSImage()

    static func make(target: TerminalController?) -> NSSegmentedControl {
        let segmented = NSSegmentedControl()
        segmented.segmentCount = 2
        segmented.trackingMode = .momentary
        segmented.segmentStyle = .separated

        segmented.setImage(fallbackImage, forSegment: 0)
        segmented.setImageScaling(.scaleProportionallyDown, forSegment: 0)
        segmented.setLabel("Action", forSegment: 0)
        segmented.setWidth(0, forSegment: 0)
        segmented.setWidth(22, forSegment: 1)
        segmented.setShowsMenuIndicator(true, forSegment: 1)
        segmented.target = target
        segmented.action = #selector(TerminalController.repoPromptToolbarAction(_:))

        update(segmented, resolution: target?.repoPromptResolution ?? .disabled(.noFocusedTerminal))
        return segmented
    }

    static func update(
        _ segmented: NSSegmentedControl,
        resolution: TerminalRepoPromptResolution
    ) {
        segmented.setToolTip("Type a repo workflow prompt into the current AI session", forSegment: 0)
        segmented.setToolTip("Choose a repo workflow prompt", forSegment: 1)

        switch resolution {
        case .disabled(let reason):
            segmented.isEnabled = false
            segmented.setLabel("Action", forSegment: 0)
            segmented.toolTip = reason.description
            segmented.setToolTip(reason.description, forSegment: 0)
            segmented.setToolTip(reason.description, forSegment: 1)
            segmented.setMenu(disabledMenu(reason: reason), forSegment: 1)

        case .ready(let readyState):
            segmented.isEnabled = true
            segmented.setLabel(readyState.primaryAction.title, forSegment: 0)
            let primaryDescription = readyState.state(for: readyState.primaryAction)?.description
                ?? "Type a repo workflow prompt into the current AI session."
            segmented.toolTip = primaryDescription
            segmented.setToolTip(primaryDescription, forSegment: 0)
            segmented.setToolTip("Choose a repo workflow prompt", forSegment: 1)
            segmented.setMenu(menu(for: readyState, target: segmented.target), forSegment: 1)
        }
    }

    private static func disabledMenu(reason: TerminalRepoPromptDisabledReason) -> NSMenu {
        let menu = NSMenu()
        let item = NSMenuItem(title: reason.title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.toolTip = reason.description
        menu.addItem(item)
        return menu
    }

    private static func menu(
        for readyState: TerminalRepoPromptReadyState,
        target: AnyObject?
    ) -> NSMenu {
        let menu = NSMenu()
        if let shortcut = readyState.shortcutAction {
            menu.addItem(shortcutItem(for: shortcut, target: target))
            menu.addItem(.separator())
        }
        for state in readyState.actionStates {
            menu.addItem(item(for: state, target: target))
        }
        return menu
    }

    private static func selector(for action: TerminalRepoPromptAction) -> Selector {
        switch action {
        case .smart:
            return #selector(TerminalController.insertSmartRepoPrompt(_:))
        case .commit:
            return #selector(TerminalController.insertCommitRepoPrompt(_:))
        case .commitAndPush:
            return #selector(TerminalController.insertCommitAndPushRepoPrompt(_:))
        case .push:
            return #selector(TerminalController.insertPushRepoPrompt(_:))
        case .pushAndOpenPR:
            return #selector(TerminalController.insertPushAndOpenPRRepoPrompt(_:))
        case .openPR:
            return #selector(TerminalController.insertOpenPRRepoPrompt(_:))
        case .pushAndUpdatePR:
            return #selector(TerminalController.insertPushAndUpdatePRRepoPrompt(_:))
        case .updatePR:
            return #selector(TerminalController.insertUpdatePRRepoPrompt(_:))
        }
    }

    private static func shortcutItem(
        for shortcut: TerminalRepoPromptShortcutState,
        target: AnyObject?
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: shortcut.action.title,
            action: selector(for: shortcut.action),
            keyEquivalent: ""
        )
        item.target = target
        item.toolTip = shortcut.description
        return item
    }

    private static func item(
        for state: TerminalRepoPromptActionState,
        target: AnyObject?
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: state.action.title,
            action: state.isAvailable ? selector(for: state.action) : nil,
            keyEquivalent: ""
        )
        item.target = target
        item.isEnabled = state.isAvailable
        item.toolTip = state.description
        return item
    }
}
#endif
