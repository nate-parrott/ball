import SpriteKit

class Ball: SKNode {
    let id: String

    private let imgOffsetContainer = SKNode()
    /**/ private let imgRotationContainer = SKNode()
    private let ballColour = UserDefaults.standard.string(forKey: "selectedBallColour")
    private var img: SKSpriteNode

    let radius: CGFloat

    private let shadowSprite = SKSpriteNode(imageNamed: "ContactShadow")
    private let shadowContainer = SKNode() // For fading in/out

    private let squish = MomentumValue(initialValue: 1, scale: 1000, params: .init(response: 0.3, dampingRatio: 0.5))
    private let dragScale = MomentumValue(initialValue: 1, scale: 1000, params: .init(response: 0.2, dampingRatio: 0.8))

    var beingDragged = false {
        didSet(old) {
            if beingDragged != old {
                dragScale.animate(toValue: beingDragged ? 1.05 : 1, velocity: dragScale.velocity, completion: nil)
            }
        }
    }

    init(radius: CGFloat, pos: CGPoint, id: String) {
        img = SKSpriteNode(imageNamed: ballColour!)
        
        self.id = id
        self.radius = radius
        super.init()
        self.position = pos

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.restitution = 0.6
        body.allowsRotation = false
        body.usesPreciseCollisionDetection = true
        body.contactTestBitMask = 1
        self.physicsBody = body

        addChild(shadowContainer)
        shadowContainer.addChild(shadowSprite)
        let shadowWidth: CGFloat = radius * 4
        shadowSprite.size = CGSize(width: shadowWidth, height: 0.564 * shadowWidth)
        shadowSprite.alpha = 0
        shadowContainer.alpha = 0

        addChild(imgOffsetContainer)
        imgOffsetContainer.addChild(imgRotationContainer)

        img.size = CGSize(width: radius * 2, height: radius * 2)
        imgRotationContainer.addChild(img)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var rect: CGRect {
        CGRect(origin: .init(x: position.x - radius, y: position.y - radius), size: .init(width: radius * 2, height: radius * 2))
    }

    func animateShadow(visible: Bool, duration: TimeInterval) {
        if visible {
            shadowContainer.run(SKAction.fadeIn(withDuration: duration))
        } else {
            shadowContainer.run(SKAction.fadeOut(withDuration: duration))
        }
    }

    func update() {
        shadowSprite.position = CGPoint(x: 0, y: (radius * 0.3) - position.y)
        let distFromBottom = position.y - radius
        shadowSprite.alpha = remap(x: distFromBottom, domainStart: 0, domainEnd: 200, rangeStart: 1, rangeEnd: 0)
        imgRotationContainer.xScale = squish.value

        let yDelta = -(1 - imgRotationContainer.xScale) * radius / 2
        imgOffsetContainer.position = .init(x: 0, y: yDelta)

        img.setScale(dragScale.value)
    }

}
