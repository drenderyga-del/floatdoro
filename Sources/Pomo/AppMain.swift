import AppKit
import Combine
import CoreImage
import SwiftUI

@main
enum PomoMain {
    @MainActor
    private static var retainedDelegate: PomoAppDelegate?

    @MainActor
    static func main() {
        let previewMode = CommandLine.arguments.contains("--preview")
        let application = NSApplication.shared
        let delegate = PomoAppDelegate(previewMode: previewMode)
        retainedDelegate = delegate
        application.delegate = delegate
        application.setActivationPolicy(previewMode ? .regular : .accessory)
        application.run()
    }
}

@MainActor
final class PomoAppDelegate: NSObject, NSApplicationDelegate {
    private let previewMode: Bool
    private let store = TimerStore()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var previewWindow: NSWindow?
    private lazy var floatingPanelController = FloatingPanelController(store: store)
    private let statusBlurFilter: CIFilter? = {
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(10, forKey: kCIInputRadiusKey)
        return filter
    }()
    private var subscriptions = Set<AnyCancellable>()

    init(previewMode: Bool) {
        self.previewMode = previewMode
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if previewMode {
            showPreviewWindow()
        } else {
            configureMenuBar()
            let shouldShowFocusWindow = store.isRunning
            store.setFloatingVisible(shouldShowFocusWindow)
            floatingPanelController.setVisible(shouldShowFocusWindow)
        }

        store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.refreshChrome()
                }
            }
            .store(in: &subscriptions)
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.persistNow()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        guard !previewMode else { return true }
        if store.isRunning {
            store.setFloatingVisible(true)
            floatingPanelController.setVisible(true)
        } else {
            showPopover()
        }
        return true
    }

    private func configureMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: 108)
        guard let button = item.button else { return }

        button.target = self
        button.action = #selector(togglePopover)
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.toolTip = appText("Macodoro — открыть таймер", "Macodoro — open timer")
        button.setAccessibilityLabel(appText("Macodoro, таймер \(store.displayTime)", "Macodoro, timer \(store.displayTime)"))
        configureStatusItemBackdrop(button)

        statusItem = item
        configurePopover()
        refreshStatusItem()
    }

    private func configureStatusItemBackdrop(_ button: NSStatusBarButton) {
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        button.layer?.cornerCurve = .continuous
        button.layer?.masksToBounds = true

        if let statusBlurFilter {
            button.layer?.backgroundFilters = [statusBlurFilter]
        }
    }

    private func configurePopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 640)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                store: store,
                onQuit: { NSApp.terminate(nil) }
            )
            .environment(\.pomoPalette, store.theme.palette)
        )
        self.popover = popover
    }

    @objc
    private func togglePopover() {
        guard let popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard
            let button = statusItem?.button,
            let popover
        else { return }

        if !popover.isShown {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func refreshChrome() {
        refreshStatusItem()
        floatingPanelController.setVisible(store.isFloatingVisible)
    }

    private func refreshStatusItem() {
        guard let button = statusItem?.button else { return }

        button.image = nil
        button.imagePosition = .noImage
        button.contentTintColor = .black
        button.attributedTitle = NSAttributedString(
            string: " \(store.phaseStatusLabel) · \(store.displayTime) ",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(
                    ofSize: 13,
                    weight: .bold
                ),
                .foregroundColor: NSColor.black
            ]
        )
        button.wantsLayer = true
        button.layer?.cornerRadius = 11
        button.layer?.masksToBounds = true
        button.layer?.backgroundColor = NSColor.white
            .withAlphaComponent(0.96)
            .cgColor
        button.layer?.borderWidth = 0.5
        button.layer?.borderColor = NSColor.black
            .withAlphaComponent(0.10)
            .cgColor
        button.toolTip = "\(store.phaseStatusLabel): \(store.displayTime) — \(store.activeTaskTitle)"
        button.setAccessibilityLabel("Macodoro. \(store.phaseStatusAccessibilityLabel). \(timerAccessibilityLabel(seconds: store.remainingSeconds))")
    }

    private func showPreviewWindow() {
        let content = PopoverView(
            store: store,
            onQuit: { NSApp.terminate(nil) }
        )
        let controller = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: controller)
        window.title = "Macodoro Preview"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 420, height: 640))
        window.center()
        window.makeKeyAndOrderFront(nil)
        previewWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
}
