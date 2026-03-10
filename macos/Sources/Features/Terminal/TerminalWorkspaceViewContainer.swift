import AppKit
import SwiftUI

class TerminalWorkspaceViewContainer<ViewModel: TerminalViewModel>: NSView {
    private let contentView: NSView

    private var glassEffectView: NSView?
    private var tintOverlayView: NSView?
    private var glassTopConstraint: NSLayoutConstraint?
    private var derivedConfig: DerivedConfig

    private var windowCornerRadius: CGFloat? {
        guard let window, window.responds(to: Selector(("_cornerRadius"))) else {
            return nil
        }

        return window.value(forKey: "_cornerRadius") as? CGFloat
    }

    init(
        ghostty: Ghostty.App,
        viewModel: ViewModel,
        delegate: (any TerminalViewDelegate)? = nil,
        worktrunkStore: WorktrunkStore,
        worktrunkSidebarState: WorktrunkSidebarState,
        openTabsModel: WorktrunkOpenTabsModel,
        gitDiffSidebarState: GitDiffSidebarState,
        openWorktree: @escaping (String) -> Void,
        openWorktreeAgent: @escaping (String, WorktrunkAgent) -> Void,
        resumeSession: ((AISession) -> Void)? = nil,
        focusNativeTab: @escaping (Int) -> Void,
        closeNativeTab: @escaping (Int) -> Void,
        moveNativeTabBefore: @escaping (Int, Int) -> Void,
        moveNativeTabAfter: @escaping (Int, Int) -> Void,
        onSidebarWidthChange: @escaping (CGFloat) -> Void,
        onGitDiffWorktreeSelect: @escaping (String?) -> Void
    ) {
        self.derivedConfig = DerivedConfig(config: ghostty.config)
        self.contentView = NSHostingView(rootView: TerminalWorkspaceView(
            ghostty: ghostty,
            viewModel: viewModel,
            delegate: delegate,
            worktrunkStore: worktrunkStore,
            worktrunkSidebarState: worktrunkSidebarState,
            openTabsModel: openTabsModel,
            gitDiffSidebarState: gitDiffSidebarState,
            openWorktree: openWorktree,
            openWorktreeAgent: openWorktreeAgent,
            resumeSession: resumeSession,
            focusNativeTab: focusNativeTab,
            closeNativeTab: closeNativeTab,
            moveNativeTabBefore: moveNativeTabBefore,
            moveNativeTabAfter: moveNativeTabAfter,
            onSidebarWidthChange: onSidebarWidthChange,
            onGitDiffWorktreeSelect: onGitDiffWorktreeSelect
        ))
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var intrinsicContentSize: NSSize {
        contentView.intrinsicContentSize
    }

    private func setup() {
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ghosttyConfigDidChange(_:)),
            name: .ghosttyConfigDidChange,
            object: nil
        )
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateGlassEffectIfNeeded()
        updateGlassEffectTopInsetIfNeeded()
    }

    override func layout() {
        super.layout()
        updateGlassEffectTopInsetIfNeeded()
    }

    @objc private func ghosttyConfigDidChange(_ notification: Notification) {
        guard let config = notification.userInfo?[
            Notification.Name.GhosttyConfigChangeKey
        ] as? Ghostty.Config else { return }
        let preferredBackgroundColor = (window as? TerminalWindow)?.preferredBackgroundColor
        let newValue = DerivedConfig(
            config: config,
            preferredBackgroundColor: preferredBackgroundColor,
            cornerRadius: windowCornerRadius
        )
        guard newValue != derivedConfig else { return }
        derivedConfig = newValue
        DispatchQueue.main.async(execute: updateGlassEffectIfNeeded)
    }
}

extension TerminalWorkspaceViewContainer: TerminalGlassContainer {
    func ghosttyConfigDidChange(_ config: Ghostty.Config, preferredBackgroundColor: NSColor?) {
        let newValue = DerivedConfig(
            config: config,
            preferredBackgroundColor: preferredBackgroundColor,
            cornerRadius: windowCornerRadius
        )
        guard newValue != derivedConfig else { return }
        derivedConfig = newValue
        DispatchQueue.main.async(execute: updateGlassEffectIfNeeded)
    }

    func updateGlassTintOverlay(isKeyWindow: Bool) {
#if compiler(>=6.2)
        guard
            #available(macOS 26.0, *),
            let tintOverlayView,
            derivedConfig.backgroundBlur.isGlassStyle
        else {
            return
        }

        let tint = tintProperties(for: derivedConfig.backgroundColor)
        tintOverlayView.layer?.backgroundColor = tint.color.cgColor
        tintOverlayView.alphaValue = isKeyWindow ? 0 : tint.opacity
#endif
    }
}

private extension TerminalWorkspaceViewContainer {
#if compiler(>=6.2)
    @available(macOS 26.0, *)
    func addGlassEffectViewIfNeeded() -> NSGlassEffectView? {
        if let existed = glassEffectView as? NSGlassEffectView {
            updateGlassEffectTopInsetIfNeeded()
            return existed
        }
        guard let themeFrameView = window?.contentView?.superview else {
            return nil
        }
        let effectView = NSGlassEffectView()
        addSubview(effectView, positioned: .below, relativeTo: contentView)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        let tintOverlayView = NSView()
        tintOverlayView.translatesAutoresizingMaskIntoConstraints = false
        tintOverlayView.wantsLayer = true
        tintOverlayView.alphaValue = 0
        addSubview(tintOverlayView, positioned: .above, relativeTo: effectView)
        glassTopConstraint = effectView.topAnchor.constraint(
            equalTo: topAnchor,
            constant: -themeFrameView.safeAreaInsets.top
        )
        if let glassTopConstraint {
            NSLayoutConstraint.activate([
                glassTopConstraint,
                effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
                effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
                effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
                tintOverlayView.topAnchor.constraint(equalTo: effectView.topAnchor),
                tintOverlayView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
                tintOverlayView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
                tintOverlayView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            ])
        }
        glassEffectView = effectView
        self.tintOverlayView = tintOverlayView
        return effectView
    }
#endif

    func updateGlassEffectIfNeeded() {
#if compiler(>=6.2)
        guard #available(macOS 26.0, *), derivedConfig.backgroundBlur.isGlassStyle else {
            glassEffectView?.removeFromSuperview()
            glassEffectView = nil
            tintOverlayView?.removeFromSuperview()
            tintOverlayView = nil
            glassTopConstraint = nil
            return
        }
        guard let effectView = addGlassEffectViewIfNeeded() else {
            return
        }
        switch derivedConfig.backgroundBlur {
        case .macosGlassRegular:
            effectView.style = NSGlassEffectView.Style.regular
        case .macosGlassClear:
            effectView.style = NSGlassEffectView.Style.clear
        default:
            break
        }
        let backgroundColor = derivedConfig.backgroundColor
        effectView.tintColor = backgroundColor
            .withAlphaComponent(derivedConfig.backgroundOpacity)
        // Note: _cornerRadius is private API used to match the window's corner radius for visual
        // consistency. The responds(to:) check ensures we gracefully handle future macOS changes.
        effectView.cornerRadius = derivedConfig.cornerRadius ?? 0
        updateGlassTintOverlay(isKeyWindow: window?.isKeyWindow ?? true)
#endif
    }

    func updateGlassEffectTopInsetIfNeeded() {
#if compiler(>=6.2)
        guard #available(macOS 26.0, *), derivedConfig.backgroundBlur.isGlassStyle else {
            return
        }
        guard glassEffectView != nil else { return }
        guard let themeFrameView = window?.contentView?.superview else { return }
        glassTopConstraint?.constant = -themeFrameView.safeAreaInsets.top
#endif
    }

    func tintProperties(for color: NSColor) -> (color: NSColor, opacity: CGFloat) {
        let isLight = color.isLightColor
        let vibrant = color.adjustingSaturation(by: 1.2)
        let overlayOpacity: CGFloat = isLight ? 0.35 : 0.85
        return (vibrant, overlayOpacity)
    }

    struct DerivedConfig: Equatable {
        var backgroundOpacity: Double = 0
        var backgroundBlur: Ghostty.Config.BackgroundBlur
        var backgroundColor: NSColor = .clear
        var cornerRadius: CGFloat?

        init(config: Ghostty.Config, preferredBackgroundColor: NSColor? = nil, cornerRadius: CGFloat? = nil) {
            self.backgroundBlur = config.backgroundBlur
            self.backgroundOpacity = config.backgroundOpacity
            self.backgroundColor = preferredBackgroundColor ?? NSColor(config.backgroundColor)
            self.cornerRadius = cornerRadius
        }
    }
}
