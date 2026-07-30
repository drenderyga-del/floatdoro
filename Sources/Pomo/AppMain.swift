import AppKit
import Combine
import SwiftUI

private extension Notification.Name {
    static let floatdoroShowMainPanel = Notification.Name(
        "io.github.drenderyga-del.floatdoro.show-main-panel"
    )
}

private enum MainPanelMetrics {
    static let contentSize = NSSize(width: 360, height: 480)
}

@main
enum PomoMain {
    @MainActor
    private static var retainedDelegate: PomoAppDelegate?

    @MainActor
    static func main() {
        let previewMode = CommandLine.arguments.contains("--preview")
        if !previewMode, activateRunningInstanceIfNeeded() {
            return
        }

        let application = NSApplication.shared
        let delegate = PomoAppDelegate(previewMode: previewMode)
        retainedDelegate = delegate
        application.delegate = delegate
        application.setActivationPolicy(previewMode ? .regular : .accessory)
        application.run()
    }

    @MainActor
    private static func activateRunningInstanceIfNeeded() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return false
        }

        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        guard let runningApplication = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first(where: {
                $0.processIdentifier != currentProcessIdentifier &&
                    !$0.isTerminated
            })
        else {
            return false
        }

        DistributedNotificationCenter.default().post(
            name: .floatdoroShowMainPanel,
            object: bundleIdentifier
        )
        runningApplication.activate(options: [])
        return true
    }
}

@MainActor
final class PomoAppDelegate: NSObject, NSApplicationDelegate {
    private let previewMode: Bool
    private let store: TimerStore
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var previewWindow: NSWindow?
    private lazy var floatingPanelController = FloatingPanelController(store: store)
    private var subscriptions = Set<AnyCancellable>()

    init(previewMode: Bool) {
        self.previewMode = previewMode
        if previewMode {
            let suiteName = "io.github.drenderyga-del.floatdoro.preview"
            let previewDefaults = UserDefaults(suiteName: suiteName)!
            previewDefaults.removePersistentDomain(forName: suiteName)
            let previewStore = TimerStore(
                defaults: previewDefaults,
                startsTicker: true,
                allowsSystemSideEffects: false
            )
            previewStore.addTask(
                title: appText(
                    "Подготовить описание релиза",
                    "Prepare the release notes"
                )
            )
            previewStore.addTask(
                title: appText(
                    "Проверить скриншоты App Store",
                    "Review App Store screenshots"
                )
            )
            previewStore.completeCurrentTask()
            previewStore.addTask(
                title: appText(
                    "Проверить финальную сборку",
                    "Verify the final build"
                )
            )
            store = previewStore
        } else {
            store = TimerStore()
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if previewMode {
            showPreviewWindow()
        } else {
            DistributedNotificationCenter.default().addObserver(
                self,
                selector: #selector(showMainPanelFromExternalLaunch),
                name: .floatdoroShowMainPanel,
                object: nil
            )
            configureMenuBar()
            let shouldShowFocusWindow = store.isRunning
            store.setFloatingVisible(shouldShowFocusWindow)
            floatingPanelController.setVisible(shouldShowFocusWindow)
        }

        if !previewMode {
            store.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshChrome()
                    }
                }
                .store(in: &subscriptions)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
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
        // Keep the countdown close to the width of two regular menu bar icons.
        // This matters on notched MacBook displays where horizontal space is
        // significantly more constrained.
        let item = NSStatusBar.system.statusItem(withLength: 56)
        guard let button = item.button else { return }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.toolTip = appText("Floatdoro — открыть таймер", "Floatdoro — open timer")
        button.setAccessibilityLabel(appText("Floatdoro, таймер \(store.displayTime)", "Floatdoro, timer \(store.displayTime)"))

        statusItem = item
        configurePopover()
        refreshStatusItem()
    }

    private func configurePopover() {
        let popover = NSPopover()
        popover.contentSize = MainPanelMetrics.contentSize
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
    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu(relativeTo: sender)
            return
        }

        guard let popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showStatusMenu(relativeTo button: NSStatusBarButton) {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: appText("Открыть Floatdoro", "Open Floatdoro"),
            action: #selector(openFromStatusMenu),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        let floatingItem = NSMenuItem(
            title: store.isFloatingVisible
                ? appText("Скрыть плавающее окно", "Hide floating window")
                : appText("Показать плавающее окно", "Show floating window"),
            action: #selector(toggleFloatingFromStatusMenu),
            keyEquivalent: ""
        )
        floatingItem.target = self
        menu.addItem(floatingItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: appText("Выйти из Floatdoro", "Quit Floatdoro"),
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 2),
            in: button
        )
    }

    @objc
    private func openFromStatusMenu() {
        showPopover()
    }

    @objc
    private func toggleFloatingFromStatusMenu() {
        store.setFloatingVisible(!store.isFloatingVisible)
    }

    @objc
    private func quitApplication() {
        NSApp.terminate(nil)
    }

    @objc
    private func showMainPanelFromExternalLaunch() {
        showPopover()
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
        button.contentTintColor = .labelColor
        button.attributedTitle = NSAttributedString(
            string: store.displayTime,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(
                    ofSize: 12.5,
                    weight: .medium
                ),
                .foregroundColor: NSColor.labelColor
            ]
        )
        button.toolTip = "\(store.phaseStatusLabel): \(store.displayTime) — \(store.activeTaskTitle)"
        button.setAccessibilityLabel("Floatdoro. \(store.phaseStatusAccessibilityLabel). \(timerAccessibilityLabel(seconds: store.remainingSeconds))")
    }

    private func showPreviewWindow() {
        let content = PopoverView(
            store: store,
            onQuit: { NSApp.terminate(nil) }
        )
        let controller = NSHostingController(rootView: content)
        controller.sizingOptions = []
        let window = NSWindow(contentViewController: controller)
        window.title = "Floatdoro Preview"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.contentMinSize = MainPanelMetrics.contentSize
        window.contentMaxSize = MainPanelMetrics.contentSize
        window.setContentSize(MainPanelMetrics.contentSize)
        window.center()
        window.makeKeyAndOrderFront(nil)
        previewWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
}
