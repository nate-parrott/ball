import AppKit

enum Constants {
    static let radius: CGFloat = 100
}

class AppController {
    // MARK: - Init

    init() {
        ballViewController.delegate = self
        setupClickWindow()
    }

    private func setupClickWindow() {
        //        clickWindow.contentViewController = NSViewController()
        let catcher = MouseCatcherView()
        clickWindow.contentView = catcher
        catcher.frame = CGRect(x: 0, y: 0, width: Constants.radius * 2, height: Constants.radius * 2)
        catcher.wantsLayer = true
        // This is needed so that the window accepts mouse events
        catcher.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.01).cgColor
        catcher.layer?.cornerRadius = Constants.radius


        catcher.onMouseDown = { [weak self] in self?.ballViewController.onMouseDown() }
        catcher.onMouseDrag = { [weak self] in self?.ballViewController.onMouseDrag() }
        catcher.onMouseUp = { [weak self] in self?.ballViewController.onMouseUp() }
        catcher.onScroll = { [weak self] in self?.ballViewController.onScroll(event: $0) }
    }

    // MARK: - External actions
    func dockIconClicked() {
        guard let screen = NSScreen.main else { return }

        if ballVisible {
            self.ballViewController.animatePutBack(rect: screen.inferredRectOfHoveredDockIcon) {
                self.ballVisible = false
            }
            return
        }

        _ = ballViewController.view

        self.ballViewController.animateBallFromRect(screen.inferredRectOfHoveredDockIcon)
        self.ballVisible = true
    }

    // MARK: - State
    private var ballVisible = false {
        didSet(old) {
            guard ballVisible != old else { return }

            ballWindowController.window!.setIsVisible(ballVisible)
            clickWindow.setIsVisible(ballVisible)

            ballViewController.sceneView.isPaused = !ballVisible
            showPutBackIcon = ballVisible

            if ballVisible {
                updateClickWindowPosition()
            }
        }
    }

    // MARK - Windows
    fileprivate let ballWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Main") as! BallWindowController
    fileprivate var ballViewController: BallViewController {
        ballWindowController.window!.contentViewController as! BallViewController
    }

    private lazy var clickWindow: NSWindow = {
        let clickWindow = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: Constants.radius * 2, height: Constants.radius * 2),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        clickWindow.isReleasedWhenClosed = false
        clickWindow.level = .screenSaver // ?
        clickWindow.backgroundColor = NSColor.clear
        return clickWindow
    }()

    // MARK: - Dock icon
    private var showPutBackIcon = false {
        didSet {
            if showPutBackIcon {
                NSApp.dockTile.contentView = putBackDockView
            } else {
                NSApp.dockTile.contentView = nil
            }
            NSApp.dockTile.display()
        }
    }
    private let putBackDockView = NSImageView(image: NSImage(named: "PutBack")!)
}

extension AppController: BallViewControllerDelegate {
    func ballViewController(_ vc: BallViewController, ballDidMoveToPosition pos: CGRect) {
        updateClickWindowPosition()
    }

    fileprivate func updateClickWindowPosition() {
        guard ballVisible, var rect = ballViewController.targetMouseCatcherRect else { return }
        let rounding: CGFloat = 10
        rect.origin.x = round(rect.minX / rounding) * rounding
        rect.origin.y = round(rect.minY / rounding) * rounding
        // HACK: Assume scene coords are same as window coords
        guard let window = self.ballWindowController.window, let screen = window.screen else { return }
        rect = rect.byConstraining(withinBounds: screen.frame)
        clickWindow.setFrame(rect, display: false)
    }
}
