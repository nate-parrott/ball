import Cocoa
import SpriteKit
import SwiftUI

protocol BallViewControllerDelegate: AnyObject {
    func ballViewController(_ vc: BallViewController, ballDidMoveToPosition pos: CGRect)
}

class BallViewController: NSViewController {
    weak var delegate: BallViewControllerDelegate?

    let scene = SKScene(size: .init(width: 200, height: 200))
    let sceneView = SKView()

    let collisionSounds: [NSSound] = ["pop_01", "pop_02", "pop_03"].map { id in
        NSSound(contentsOf: Bundle.main.url(forResource: id, withExtension: "caf")!, byReference: true)!
    }

    var targetMouseCatcherRect: CGRect? {
        if let rect = tempOverrideMouseCatcherRect ?? ball?.rect, let win = self.view.window {
            return win.convertToScreen(rect)
        }
        return nil
    }

    private var tempOverrideMouseCatcherRect: CGRect?

    var ball: Ball? {
        didSet(old) {
            old?.removeFromParent()
            old?.physicsBody = nil
//            old?.view.removeFromSuperview()
            if let ball {
                scene.addChild(ball)
//                view.addSubview(ball.view)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(sceneView)
        sceneView.presentScene(scene)
        scene.backgroundColor = NSColor.clear
        sceneView.allowsTransparency = true

        sceneView.preferredFramesPerSecond = 120
        scene.physicsWorld.contactDelegate = self
        scene.delegate = self

        for sound in collisionSounds {
            sound.volume = 0
            sound.play() // Ensure ready to play
        }
    }


    override func viewDidLayout() {
        super.viewDidLayout()
        scene.size = view.bounds.size
        sceneView.frame = view.bounds
        scene.physicsBody = SKPhysicsBody(edgeLoopFrom: view.bounds)
        scene.physicsBody?.contactTestBitMask = 1
    }

    // MARK: - Mouse handling

    private struct DragState {
        var ballStart: CGPoint
        var mouseStart: CGPoint
        var currentMousePos: CGPoint
        var velocityTracker = VelocityTracker()

        var currentBallPos: CGPoint {
            let delta = CGPoint(x: currentMousePos.x - mouseStart.x, y: currentMousePos.y - mouseStart.y)
            return CGPoint(x: ballStart.x + delta.x, y: ballStart.y + delta.y)
        }
    }

    private var dragState: DragState? {
        didSet {
            if let dragState, let ball {
                ball.physicsBody?.isDynamic = false
                let pos = dragState.currentBallPos
                let rect = CGRect(origin: .init(x: pos.x - ball.radius, y: pos.y - ball.radius), size: .init(width: ball.radius * 2, height: ball.radius * 2))
                let constrainedRect = rect.byConstraining(withinBounds: view.bounds)
                ball.position = CGPoint(x: constrainedRect.midX, y: constrainedRect.midY)
            } else {
               ball?.physicsBody?.isDynamic = true
            }
            ball?.beingDragged = dragState != nil
        }
    }

    func onMouseDown() {
        let scenePos = mouseScenePos
        if let ball, ball.contains(scenePos) {
            self.dragState = .init(ballStart: ball.position, mouseStart: scenePos, currentMousePos: scenePos)
        } else {
            self.dragState = nil
        }
    }

    func onMouseDrag() {
        if var dragState {
            dragState.currentMousePos = mouseScenePos
            dragState.velocityTracker.add(pos: dragState.currentMousePos)
            self.dragState = dragState
        }
    }

    func onMouseUp() {
        let velocity = dragState?.velocityTracker.velocity ?? .zero
        self.dragState = nil

        if velocity.length > 0 {
            ball?.physicsBody?.applyImpulse(CGVector(dx: velocity.x, dy: velocity.y))
        }
    }

    func onScroll(event: NSEvent) {
        switch event.phase {
        case .began:
            if let ball {
                dragState = .init(ballStart: ball.position, mouseStart: .zero, currentMousePos: .zero)
                tempOverrideMouseCatcherRect = targetMouseCatcherRect
            }
        case .changed:
            if var dragState {
                dragState.currentMousePos.x += event.scrollingDeltaX
                dragState.currentMousePos.y -= event.scrollingDeltaY
                dragState.velocityTracker.add(pos: dragState.currentMousePos)
                self.dragState = dragState
            }
        case .ended, .cancelled:
            let velocity = dragState?.velocityTracker.velocity ?? .zero
            self.dragState = nil

            if velocity.length > 0 {
                ball?.physicsBody?.applyImpulse(CGVector(dx: velocity.x, dy: velocity.y))
            }
            
            tempOverrideMouseCatcherRect = nil
        default: ()
        }
    }

    private var mouseScenePos: CGPoint {
        let viewPos = sceneView.convert(self.view.window!.mouseLocationOutsideOfEventStream, from: nil)
        let scenePos = scene.convertPoint(fromView: viewPos)
        return scenePos
    }

    // MARK: - Animations
    func animateBallFromRect(_ rect: CGRect) {
        guard let screen = self.view.window?.screen else { return }
        var targetRect = rect
        targetRect = targetRect.byConstraining(withinBounds: screen.frame)

        let ball = Ball(radius: Constants.radius, pos: .init(x: targetRect.midX, y: targetRect.midY), id: UUID().uuidString)
        self.ball = ball

        dragState = nil
        // self.ball?.position = CGPoint(x: targetRect.midX, y: targetRect.midY)

        // Add impulse to fling ball to center of screen
        let strength: CGFloat = 2000
        var impulse = CGVector(dx: 0, dy: 0)
        let distFromLeft = targetRect.midX - screen.frame.minX
        let distFromRight = screen.frame.maxX - targetRect.midX
        let distFromBottom = targetRect.midY - screen.frame.minY
        if distFromBottom < 200 {
            impulse.dy = strength
        }
        if distFromLeft < 200 {
            impulse.dx = strength
        } else if distFromRight < 200 {
            impulse.dx = -strength
        }

        ball.setScale(rect.width / (ball.radius * 2))
        let scaleUp = SKAction.scale(to: 1, duration: 0.5)
        ball.run(scaleUp)
//        ball.physicsBody?.applyImpulse(impulse)

        ball.animateShadow(visible: true, duration: 0.5)

        nextRenderBlocks.append {
            ball.position = CGPoint(x: targetRect.midX, y: targetRect.midY)
            ball.physicsBody?.applyImpulse(impulse)
        }
    }

    func animatePutBack(rect: CGRect, completion: @escaping () -> Void) {
        guard let ball else {
            completion()
            return
        }
        dragState = nil

        ball.physicsBody?.isDynamic = false
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.velocity = .zero

        let scale = SKAction.scale(to: rect.width / (ball.radius * 2), duration: 0.25)
        ball.animateShadow(visible: false, duration: 0.25)
        ball.run(scale)
        let move = SKAction.move(to: CGPoint(x: rect.midX, y: rect.midY), duration: 0.25)
        ball.run(move) {
            self.ball = nil
            completion()
        }
    }

    fileprivate var nextRenderBlocks = [() -> Void]()
}

extension BallViewController: SKSceneDelegate {
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        if let ball {
            delegate?.ballViewController(self, ballDidMoveToPosition: ball.rect)
        }
    }

    func didSimulatePhysics(for scene: SKScene) {
        let blocks = nextRenderBlocks
        nextRenderBlocks = []
        for block in blocks {
            block()
        }
    }

    func didFinishUpdate(for scene: SKScene) {
        if let ball {
            ball.update()
//            ball.view.setCenter(CGPoint(x: ball.position.x, y: ball.position.y))
        }
    }
}

extension NSView {
    func setCenter(_ pt: CGPoint) {
        self.frame = CGRect(x: pt.x - bounds.width / 2, y: pt.y - bounds.height / 2, width: bounds.width, height: bounds.height)
    }
}

extension BallViewController: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let minImpulse: Double = 1000
        let maxImpulse: Double = 2000

        let collisionStrength = remap(x: contact.collisionImpulse, domainStart: minImpulse, domainEnd: maxImpulse, rangeStart: 0, rangeEnd: 0.5)
        guard collisionStrength > 0 else { return }

        ball?.didCollide(strength: collisionStrength, normal: contact.contactNormal)

        DispatchQueue.global().async {
            var sounds = self.collisionSounds
            sounds.shuffle()
            guard let soundToUse = sounds.first(where: { !$0.isPlaying }) else {
                return
            }
            soundToUse.volume = Float(collisionStrength)
            soundToUse.play()
        }
    }
}

extension CGRect {
    func byConstraining(withinBounds bounds: CGRect) -> CGRect {
        var r = self
        if r.minX < bounds.minX {
            r.origin.x = bounds.minX
        }
        if r.maxX > bounds.maxX {
            r.origin.x = bounds.maxX - r.width
        }
        if r.minY < bounds.minY {
            r.origin.y = bounds.minY
        }
        if r.maxY > bounds.maxY {
            r.origin.y = bounds.maxY - r.height
        }
        return r
    }
}

extension CGPoint {
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}

private struct VelocityTracker {
    struct Sample {
        var time: TimeInterval
        var pos: CGPoint
    }
    var samples = [Sample]()

    mutating func add(pos: CGPoint) {
        let time = CACurrentMediaTime()
        let sample = Sample(time: time, pos: pos)
        samples.append(sample)
        self.samples = filteredSamples
    }

    private var filteredSamples: [Sample] {
        let time = CACurrentMediaTime()
        let filtered = samples.filter { time - $0.time < 0.1 }
        return filtered
    }

    var velocity: CGPoint {
        let samples = filteredSamples
        guard samples.count >= 2 else { return .zero }
        let first = samples.first!
        let last = samples.last!
        let delta = CGPoint(x: last.pos.x - first.pos.x, y: last.pos.y - first.pos.y)
        let time = last.time - first.time
        return CGPoint(x: delta.x / CGFloat(time), y: delta.y / CGFloat(time))
    }
}
