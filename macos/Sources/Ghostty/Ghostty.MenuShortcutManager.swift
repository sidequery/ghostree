import AppKit

extension Ghostty {
    /// The manager that's responsible for updating shortcuts of Ghostty's app menu
    @MainActor
    class MenuShortcutManager {

        /// Ghostty menu items indexed by their normalized shortcut. This avoids traversing
        /// the entire menu tree on every key equivalent event.
        ///
        /// We store a weak reference so this cache can never be the owner of menu items.
        /// If multiple items map to the same shortcut, the most recent one wins.
        private var menuItemsByShortcut: [MenuShortcutKey: Weak<NSMenuItem>] = [:]

        /// Reset our shortcut index since we're about to rebuild all menu bindings.
        func reset() {
            menuItemsByShortcut.removeAll(keepingCapacity: true)
        }

        /// Syncs a single menu shortcut for the given action. The action string is the same
        /// action string used for the Ghostty configuration.
        func syncMenuShortcut(_ config: Ghostty.Config, action: String?, menuItem: NSMenuItem?) {
            guard let menu = menuItem else { return }

            guard let action, let shortcut = config.keyboardShortcut(for: action) else {
                // No shortcut, clear the menu item
                menu.keyEquivalent = ""
                menu.keyEquivalentModifierMask = []
                return
            }

            let keyEquivalent = shortcut.key.character.description
            let modifierMask = NSEvent.ModifierFlags(swiftUIFlags: shortcut.modifiers)
            menu.keyEquivalent = keyEquivalent
            menu.keyEquivalentModifierMask = modifierMask

            // Build a direct lookup for key-equivalent dispatch so we don't need to
            // linearly walk the full menu hierarchy at event time.
            guard let key = MenuShortcutKey(
                // We don't want to check missing `shift` for Ghostty configured shortcuts,
                // because we know it's there when it needs to be
                keyEquivalent: keyEquivalent.lowercased(),
                modifiers: modifierMask
            ) else {
                return
            }

            // Later registrations intentionally override earlier ones for the same key.
            menuItemsByShortcut[key] = .init(menu)
        }

        /// Attempts to perform a menu key equivalent only for menu items that represent
        /// Ghostty keybind actions. This is important because it lets our surface dispatch
        /// bindings through the menu so they flash but also lets our surface override macOS built-ins
        /// like Cmd+H.
        func performGhosttyBindingMenuKeyEquivalent(with event: NSEvent) -> Bool {
            // Convert this event into the same normalized lookup key we use when
            // syncing menu shortcuts from configuration.
            guard let key = MenuShortcutKey(event: event) else {
                return false
            }

            // If we don't have an entry for this key combo, no Ghostty-owned
            // menu shortcut exists for this event.
            guard let weakItem = menuItemsByShortcut[key] else {
                return false
            }

            // Weak references can be nil if a menu item was deallocated after sync.
            guard let item = weakItem.value else {
                menuItemsByShortcut.removeValue(forKey: key)
                return false
            }

            guard let parentMenu = item.menu else {
                return false
            }

            // Keep enablement state fresh in case menu validation hasn't run yet.
            parentMenu.update()
            guard item.isEnabled else {
                return false
            }

            let index = parentMenu.index(of: item)
            guard index >= 0 else {
                return false
            }

            parentMenu.performActionForItem(at: index)
            return true
        }
    }
}

extension Ghostty.MenuShortcutManager {
    /// Hashable key for a menu shortcut match, normalized for quick lookup.
    struct MenuShortcutKey: Hashable {
        private static let shortcutModifiers: NSEvent.ModifierFlags = [.shift, .control, .option, .command]

        let keyEquivalent: String
        let modifiersRawValue: UInt

        init?(keyEquivalent: String, modifiers: NSEvent.ModifierFlags) {
            let normalized = keyEquivalent.lowercased()
            guard !normalized.isEmpty else { return nil }
            var mods = modifiers.intersection(Self.shortcutModifiers)
            if
                keyEquivalent.lowercased() != keyEquivalent.uppercased(),
                normalized.uppercased() == keyEquivalent {
                // If key equivalent is case sensitive and
                // it's originally uppercased, then we need to add `shift` to the modifiers
                mods.insert(.shift)
            }
            self.keyEquivalent = normalized
            self.modifiersRawValue = mods.rawValue
        }

        init?(event: NSEvent) {
            guard let keyEquivalent = event.charactersIgnoringModifiers else { return nil }
            self.init(keyEquivalent: keyEquivalent, modifiers: event.modifierFlags)
        }
    }
}
