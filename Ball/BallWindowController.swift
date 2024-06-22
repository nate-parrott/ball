import AppKit

class BallWindowController: NSWindowController, NSWindowDelegate {
    override func windowDidLoad() {
        super.windowDidLoad()
        let window = self.window!
        window.backgroundColor = NSColor.clear // NSColor.red.withAlphaComponent(0.5)
        window.isOpaque = false
        window.delegate = self
        window.acceptsMouseMovedEvents = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        updateWindowSize()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        updateWindowSize()
    }

    func windowDidChangeScreenProfile(_ notification: Notification) {
        updateWindowSize()
    }

    private func updateWindowSize() {
        guard let screen = window?.screen else { return }
        let frame = CGRect(x: screen.frame.minX, y: screen.frame.minY, width: screen.frame.width, height: screen.frame.height)
        window?.setFrame(frame, display: true)
    }
}
