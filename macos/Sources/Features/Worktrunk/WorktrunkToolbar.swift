import AppKit

final class WorktrunkToolbar: NSToolbar, NSToolbarDelegate {
    private weak var targetController: TerminalController?
    private let titleTextField = CenteredDynamicLabel(labelWithString: " ")
    private var titleFont: NSFont?
    private var titleColor: NSColor?

    var titleText: String {
        get { titleTextField.stringValue }
        set {
            titleTextField.stringValue = newValue
            updateTitleAttributes()
        }
    }

    var titleTextFont: NSFont? {
        get { titleFont }
        set {
            titleFont = newValue
            updateTitleAttributes()
        }
    }

    var titleTextColor: NSColor? {
        get { titleColor }
        set {
            titleColor = newValue
            updateTitleAttributes()
        }
    }

    init(target: TerminalController?) {
        self.targetController = target
        super.init(identifier: NSToolbar.Identifier("WorktrunkToolbar.v2"))
        delegate = self
        displayMode = .iconOnly
        allowsUserCustomization = false
        autosavesConfiguration = false
        updateTitleAttributes()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .worktrunkTitleText, .flexibleSpace, .openInEditor]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .worktrunkTitleText, .flexibleSpace, .openInEditor]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .worktrunkTitleText:
            let item = NSToolbarItem(itemIdentifier: .worktrunkTitleText)
            item.view = titleTextField
            item.visibilityPriority = .user
            item.isEnabled = true
            item.isBordered = false
            titleTextField.translatesAutoresizingMaskIntoConstraints = false
            titleTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            titleTextField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            NSLayoutConstraint.activate([
                titleTextField.heightAnchor.constraint(equalToConstant: 22),
            ])
            return item
        case .toggleSidebar:
            let item = NSToolbarItem(itemIdentifier: .toggleSidebar)
            let button = NSButton(frame: NSRect(x: 0, y: 0, width: 38, height: 22))
            button.bezelStyle = .toolbar
            button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Toggle Sidebar")
            button.imagePosition = .imageOnly
            button.target = targetController
            button.action = #selector(TerminalController.toggleSidebar(_:))
            item.view = button
            item.label = "Toggle Sidebar"
            item.isNavigational = true
            return item
        case .openInEditor:
            return makeOpenInEditorItem()
        default:
            return NSToolbarItem(itemIdentifier: itemIdentifier)
        }
    }

    private func makeOpenInEditorItem() -> NSToolbarItem? {
        let installed = ExternalEditor.installedEditors()
        guard !installed.isEmpty else { return nil }

        let item = NSToolbarItem(itemIdentifier: .openInEditor)
        item.label = "Open in Editor"
        item.toolTip = "Open in Editor"

        let segmented = EditorSplitButton.make(
            editors: installed,
            target: targetController
        )

        item.view = segmented
        return item
    }

    private func updateTitleAttributes() {
        let text = titleTextField.stringValue.isEmpty ? " " : titleTextField.stringValue
        let baseFont = titleFont ?? NSFont.titleBarFont(ofSize: NSFont.systemFontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: baseFont.withSize(baseFont.pointSize + 1),
            .foregroundColor: titleColor ?? NSColor.labelColor,
        ]
        titleTextField.attributedStringValue = NSAttributedString(string: text, attributes: attributes)
    }
}

extension NSToolbarItem.Identifier {
    static let worktrunkTitleText = NSToolbarItem.Identifier("WorktrunkTitleText")
    static let openInEditor = NSToolbarItem.Identifier("OpenInEditor")
}

/// A split button for the "Open in Editor" toolbar item.
/// Left segment: click to open in the preferred editor (shows that editor's app icon).
/// Right segment: dropdown arrow that shows a menu of all installed editors.
enum EditorSplitButton {
    private static let iconSize = NSSize(width: 16, height: 16)
    private static let fallbackImage = NSImage(
        systemSymbolName: "curlybraces",
        accessibilityDescription: "Open in Editor"
    )!

    static func make(editors: [ExternalEditor], target: TerminalController?) -> NSSegmentedControl {
        let segmented = NSSegmentedControl()
        segmented.segmentCount = 2
        segmented.trackingMode = .momentary
        segmented.segmentStyle = .separated

        // Segment 0: main action (preferred editor icon + "Open" label)
        let preferred = WorktrunkPreferences.preferredEditor ?? editors.first!
        segmented.setImage(editorIcon(preferred), forSegment: 0)
        segmented.setImageScaling(.scaleProportionallyDown, forSegment: 0)
        segmented.setLabel("Open", forSegment: 0)
        segmented.setWidth(0, forSegment: 0)
        segmented.setToolTip("Open in \(preferred.title)", forSegment: 0)

        // Segment 1: dropdown arrow with menu
        let menu = buildMenu(editors: editors, target: target)
        segmented.setMenu(menu, forSegment: 1)
        segmented.setShowsMenuIndicator(true, forSegment: 1)
        segmented.setWidth(22, forSegment: 1)
        segmented.setToolTip("Choose editor", forSegment: 1)

        segmented.target = target
        segmented.action = #selector(TerminalController.openInEditor(_:))

        return segmented
    }

    static func editorIcon(_ editor: ExternalEditor) -> NSImage {
        guard let icon = editor.appIcon else { return fallbackImage }
        let resized = NSImage(size: iconSize, flipped: false) { rect in
            icon.draw(in: rect)
            return true
        }
        return resized
    }

    static func updateIcon(_ segmented: NSSegmentedControl, editor: ExternalEditor) {
        segmented.setImage(editorIcon(editor), forSegment: 0)
        segmented.setToolTip("Open in \(editor.title)", forSegment: 0)
    }

    private static func buildMenu(editors: [ExternalEditor], target: TerminalController?) -> NSMenu {
        let menu = NSMenu()
        let groups = ExternalEditor.installedByCategory()
        for (index, group) in groups.enumerated() {
            if index > 0 {
                menu.addItem(.separator())
            }
            for editor in group.editors {
                let menuItem = NSMenuItem(
                    title: editor.title,
                    action: #selector(TerminalController.openInSpecificEditor(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = target
                menuItem.representedObject = editor
                if let icon = editor.appIcon {
                    let resized = NSImage(size: iconSize, flipped: false) { rect in
                        icon.draw(in: rect)
                        return true
                    }
                    menuItem.image = resized
                }
                menu.addItem(menuItem)
            }
        }
        return menu
    }
}

private class CenteredDynamicLabel: NSTextField {
    override func viewDidMoveToSuperview() {
        isEditable = false
        isBordered = false
        drawsBackground = false
        alignment = .center
        lineBreakMode = .byTruncatingTail
        cell?.truncatesLastVisibleLine = true
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let attributedString = attributedStringValue.mutableCopy() as? NSMutableAttributedString else {
            super.draw(dirtyRect)
            return
        }

        let textSize = attributedString.size()
        let yOffset = (bounds.height - textSize.height) / 2 - 1
        let centeredRect = NSRect(
            x: bounds.origin.x,
            y: bounds.origin.y + yOffset,
            width: bounds.width,
            height: textSize.height
        )
        attributedString.draw(in: centeredRect)
    }
}
