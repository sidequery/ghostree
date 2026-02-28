import AppKit

class DockTilePlugin: NSObject, NSDockTilePlugIn {
    // WARNING: An instance of this class is alive as long as Ghostty's icon is
    // in the doc (running or not!), so keep any state and processing to a
    // minimum to respect resource usage.

    private let pluginBundle = Bundle(for: DockTilePlugin.self)

    // Separate defaults based on debug vs release builds so we can test icons
    // without messing up releases.
    #if DEBUG
    private let ghosttyUserDefaults = UserDefaults(suiteName: "com.mitchellh.ghostty.debug")
    #else
    private let ghosttyUserDefaults = UserDefaults(suiteName: "com.mitchellh.ghostty")
    #endif

    private var iconChangeObserver: Any?

    /// The path to the Ghostty.app, determined based on the bundle path of this plugin.
    var ghosttyAppPath: String {
        var url = pluginBundle.bundleURL
        // Remove "/Contents/PlugIns/DockTilePlugIn.bundle" from the bundle URL to reach Ghostty.app.
        while url.lastPathComponent != "Ghostty.app", !url.lastPathComponent.isEmpty {
            url.deleteLastPathComponent()
        }
        return url.path
    }

    /// The primary NSDockTilePlugin function.
    func setDockTile(_ dockTile: NSDockTile?) {
        // If no dock tile or no access to Ghostty defaults, we can't do anything.
        guard let dockTile, let ghosttyUserDefaults else {
            iconChangeObserver = nil
            return
        }

        // Try to restore the previous icon on launch.
        iconDidChange(ghosttyUserDefaults.appIcon, dockTile: dockTile)

        // Setup a new observer for when the icon changes so we can update. This message
        // is sent by the primary Ghostty app.
        iconChangeObserver = DistributedNotificationCenter
            .default()
            .publisher(for: .ghosttyIconDidChange)
            .map { [weak self] _ in self?.ghosttyUserDefaults?.appIcon }
            .receive(on: DispatchQueue.global())
            .sink { [weak self] newIcon in self?.iconDidChange(newIcon, dockTile: dockTile) }
    }

    private func iconDidChange(_ newIcon: AppIcon?, dockTile: NSDockTile) {
        guard let appIcon = newIcon?.image(in: pluginBundle) else {
            resetIcon(dockTile: dockTile)
            return
        }

        let appBundlePath = self.ghosttyAppPath
        NSWorkspace.shared.setIcon(appIcon, forFile: appBundlePath)
        NSWorkspace.shared.noteFileSystemChanged(appBundlePath)

        dockTile.setIcon(appIcon)
    }

    /// Reset the application icon and dock tile icon to the default.
    private func resetIcon(dockTile: NSDockTile) {
        let appBundlePath = self.ghosttyAppPath
        let appIcon: NSImage
        if #available(macOS 26.0, *) {
            // Reset to the default (glassy) icon.
            NSWorkspace.shared.setIcon(nil, forFile: appBundlePath)

            #if DEBUG
            // Use the `Blueprint` icon to distinguish Debug from Release builds.
            appIcon = pluginBundle.image(forResource: "BlueprintImage")!
            #else
            // Get the composed icon from the app bundle.
            if let iconRep = NSWorkspace.shared.icon(forFile: appBundlePath)
                .bestRepresentation(
                    for: CGRect(origin: .zero, size: dockTile.size),
                    context: nil,
                    hints: nil
            ) {
                appIcon = NSImage(size: dockTile.size)
                appIcon.addRepresentation(iconRep)
            } else {
                // If something unexpected happens on macOS 26,
                // fall back to a bundled icon.
                appIcon = pluginBundle.image(forResource: "AppIconImage")!
            }
            #endif
        } else {
            // Use the bundled icon to keep the corner radius consistent with pre-Tahoe apps.
            appIcon = pluginBundle.image(forResource: "AppIconImage")!
            NSWorkspace.shared.setIcon(appIcon, forFile: appBundlePath)
        }

        // Notify Finder/Dock so icon caches refresh immediately.
        NSWorkspace.shared.noteFileSystemChanged(appBundlePath)
        dockTile.setIcon(appIcon)
    }
}

private extension NSDockTile {
    func setIcon(_ newIcon: NSImage) {
        // Update the Dock tile on the main thread.
        DispatchQueue.main.async {
            let iconView = NSImageView(frame: CGRect(origin: .zero, size: self.size))
            iconView.wantsLayer = true
            iconView.image = newIcon
            self.contentView = iconView
            self.display()
        }
    }
}

// This is required because of the DispatchQueue call above. This doesn't
// feel right but I don't know a better way to solve this.
extension NSDockTile: @unchecked @retroactive Sendable {}
