// From https://gist.github.com/wonderbit/c8896ff429a858021a7623f312dcdbf9

import AppKit

enum WBDockPosition: Int {
    case bottom = 0
    case left = 1
    case right = 2
}

func getDockPosition() -> WBDockPosition {
    if NSScreen.main!.visibleFrame.origin.y == 0 {
        if NSScreen.main!.visibleFrame.origin.x == 0 {
            return .right
        } else {
            return .left
        }
    } else {
        return .bottom
    }
}

func getDockSize() -> CGFloat {
    let dockPosition = getDockPosition()
    switch dockPosition {
    case .right:
        let size = NSScreen.main!.frame.width - NSScreen.main!.visibleFrame.width
        return size
    case .left:
        let size = NSScreen.main!.visibleFrame.origin.x
        return size
    case .bottom:
        let size = NSScreen.main!.visibleFrame.origin.y
        return size
    }
}

func isDockHidden() -> Bool {
    let dockSize = getDockSize()

    if dockSize < 25 {
        return true
    } else {
        return false
    }
}

// From me

extension NSScreen {
//    var dockRect: CGRect {
//        let dockPosition = getDockPosition()
//        let dockSize = getDockSize()
//        // Dock is centered along its edge
//        switch dockPosition {
//            case .bottom:
//                return CGRect(x: frame.minX + (frame.width - dockSize.width) / 2, y: frame.maxY - dockSize.height, width: dockSize.width, height: dockSize)
//            case .left:
//                return CGRect(x: frame.minX, y: frame.minY + (frame.height - dockSize.height) / 2, width: dockSize, height: dockSize.height)
//            case .right:
//                return CGRect(x: frame.maxX - dockSize, y: frame.minY + (frame.height - dockSize.height) / 2, width: dockSize, height: dockSize.height)
//        }
//    }

    var inferredRectOfHoveredDockIcon: CGRect {
        // Keep in mind coords are inverted (y=0 at bottom)
        let dockSize = getDockSize()
        let dockPos = getDockPosition()
        let tileSize = dockSize * (64.0 / 79.0)
        // First, set center to the mouse pos
        var center = NSEvent.mouseLocation
        if dockPos == .bottom {
            center.y = frame.minY + tileSize / 2
            // Dock icons are a little above the center of the dock rect
            center.y += 2.5 / 79 * dockSize
        }
        return CGRect(x: center.x - tileSize / 2, y: center.y - tileSize / 2, width: tileSize, height: tileSize)
    }
}
