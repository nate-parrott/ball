import AppKit

class MouseCatcherView: NSView {
    var onMouseDown: (() -> Void)?
    var onMouseDrag: (() -> Void)?
    var onMouseUp: (() -> Void)?
    var onScroll: ((NSEvent) -> Void)?

    override func mouseDown(with event: NSEvent) {
        onMouseDown?()
    }

    override func mouseDragged(with event: NSEvent) {
        onMouseDrag?()
    }

    override func mouseUp(with event: NSEvent) {
        onMouseUp?()
    }

    override func scrollWheel(with event: NSEvent) {
        guard event.hasPreciseScrollingDeltas, event.momentumPhase.rawValue == 0 else {
            return
        }
        onScroll?(event)
    }
}
