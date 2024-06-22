import QuartzCore
import Motion

public class MomentumValue: ObservableObject {
    // MARK: - Types
    public struct SpringParams {
        var response: Double
        var dampingRatio: Double
        var epsilon: Double = 0.01
        var resolvesUponReachingToValue = false
        public static let interactiveGrab = SpringParams(response: 0.15, dampingRatio: 0.95)
        public static let dismissal = SpringParams(response: 0.15, dampingRatio: 0.85, epsilon: 3, resolvesUponReachingToValue: true)
        public static let passiveEase = SpringParams(response: 0.35, dampingRatio: 0.85)
    }
    public typealias AnimationCompletionBlock = (Bool /* completed */) -> Void
    public typealias ChangeBlock = (Double) -> Void

    // MARK: - Vars
    private let spring = SpringAnimation<Double>()
    private let decay = DecayAnimation<Double>()
    private let externallySetVelocityTracker = VelocityTracker()

    // MARK: - Public
    public var minimum: CGFloat? { didSet { if minimum != oldValue { _snapIntoNewBounds(completion: nil) } } }
    public var maximum: CGFloat?  { didSet { if maximum != oldValue { _snapIntoNewBounds(completion: nil) } } }
    public var onChange: ChangeBlock?
    public var scale: CGFloat = 1

    public init(initialValue: CGFloat = 0, scale: CGFloat = 1, params: SpringParams = SpringParams.passiveEase) {
        self.params = params
        self.value = initialValue
        self.scale = scale
        _updateFromParams()
    }

    public var params: SpringParams {
        didSet {
            _updateFromParams()
        }
    }

    private func _updateFromParams() {
        spring.configure(response: params.response, dampingRatio: params.dampingRatio)
        spring.resolvesUponReachingToValue = params.resolvesUponReachingToValue
        spring.resolvingEpsilon = params.epsilon
    }

    private var _isSettingValueInternally = false
    @Published var value: Double {
        didSet {
            if !_isSettingValueInternally {
                _resetToStationary(animationFinished: false)
                externallySetVelocityTracker.addSample(value)
            }
            onChange?(value)
        }
    }
    @Published var animating = false

    public var rubberBandedValue: Double {
        if let m = minimum, value < m {
            return m - _rubberBand(x: m - value)
        }
        if let m = maximum, value > m {
            return m + _rubberBand(x: value - m)
        }
        return value
    }

    var velocity: Double {
        switch state {
        case .animating:
            return spring.velocity / scale
        case .decelerating:
            return decay.velocity / scale
        case .stationary:
            return externallySetVelocityTracker.velocity
        }
    }

    public func animate(toValue: CGFloat, velocity: CGFloat, completion: AnimationCompletionBlock?) {
        _resetToStationary(animationFinished: false)
        _targetValue = toValue
        state = .animating(completion ?? {_ in () })
        spring.updateValue(to: self.value * scale, postValueChanged: false)
        spring.velocity = velocity * scale
        spring.toValue = toValue * scale
        spring.completion = { [weak self] in
            self?._resetToStationary(animationFinished: true)
        }
        spring.onValueChanged { [weak self] newVal in
            self?._updateValueFromAnimation(scaledVal: newVal, isDecay: false)
        }
        spring.start()
    }

    public func decelerate(velocity: CGFloat, completion: AnimationCompletionBlock?) {
        _resetToStationary(animationFinished: false)
        if velocity == 0 {
            _snapIntoNewBounds(completion: completion)
            return
        }
        decay.updateValue(to: value * scale, postValueChanged: false)
        decay.velocity = velocity * scale
        _targetValue = nil // TODO: can we compute this?
        state = .decelerating(completion ?? { _ in () })
        decay.completion = { [weak self] in
            self?._resetToStationary(animationFinished: true)
        }
        decay.onValueChanged { [weak self] scaledVal in
            self?._updateValueFromAnimation(scaledVal: scaledVal, isDecay: true)
        }
        decay.start()
    }

    func stop() {
        _resetToStationary(animationFinished: false)
    }

    // MARK: - Internal State
    private enum State {
        case stationary
        case animating(AnimationCompletionBlock)
        case decelerating(AnimationCompletionBlock)
    }
    private var state = State.stationary {
        didSet {
            switch state {
            case .stationary:
                animating = false
            case .animating, .decelerating:
                animating = true
            }
        }
    }

    // MARK: - Implementation
    private var _targetValue: CGFloat?

    private func _resetToStationary(animationFinished: Bool) {
        let prevState = state
        state = .stationary
        _targetValue = nil

        spring.completion = nil
        spring.onValueChanged(nil)
        spring.stop(resolveImmediately: false, postValueChanged: false)
        decay.onValueChanged(nil)
        decay.completion = nil
        decay.stop(resolveImmediately: false, postValueChanged: false)

        switch prevState {
        case .stationary: ()
        case .animating(let block):
            block(animationFinished)
        case .decelerating(let block):
            block(animationFinished)
        }
    }

    private func _snapIntoNewBounds(completion: AnimationCompletionBlock?) {
        if let dest = _rubberBandDestinationForValue(value) {
            animate(toValue: dest, velocity: velocity, completion: completion)
        } else {
            completion?(true)
        }
    }

    private func _updateValueFromAnimation(scaledVal: CGFloat, isDecay: Bool) {
        if isDecay, case let .decelerating(completion) = state, let rubberBandDest = _rubberBandDestinationForValue(scaledVal / scale) {
            // We're doing a decay animation and we've decelerated into an area out-of-bounds of the scroll view. We need to do a rubber-banding animation to snap the value to the minimum or maximum.
            let velocity = self.velocity
            state = .stationary // Overwrite `state` so we don't call the completion block
            decay.completion = nil
            decay.stop(resolveImmediately: false, postValueChanged: false)
            animate(toValue: rubberBandDest, velocity: velocity, completion: completion)
            return
        }
        _isSettingValueInternally = true
        value = scaledVal / scale
        _isSettingValueInternally = false
    }

    private func _rubberBandDestinationForValue(_ val: Double) -> Double? {
        if let m = minimum, val < m {
            return m
        }
        if let m = maximum, val > m {
            return m
        }
        return nil
    }

    private func _rubberBand(x: Double) -> Double {
        let dimension: Double = 500 // numberOfUnitsThatRoughlyCorrespondToSizeOfScreen
        let c = 0.55
        return (1.0 - (1.0 / ((x * c / dimension) + 1.0))) * dimension
    }
}

private class VelocityTracker {
    // MARK: - Model
    private struct Sample {
        var time: TimeInterval
        var value: Double
    }
    private var samples = [Sample]()

    // MARK: - API

    init() {}


    func addSample(_ val: Double) {
        samples.append(.init(time: CACurrentMediaTime(), value: val))
        trim()
    }

    var velocity: Double {
        trim()
        if let firstSample = samples.first, let lastSample = samples.last {
            let timeDelta = CACurrentMediaTime() - firstSample.time
            let distDelta = lastSample.value - firstSample.value
            if timeDelta > 0 {
                return distDelta / timeDelta
            }
        }
        return 0
    }

    // MARK: - Helpers
    private let lookBack: TimeInterval = 1.0 / 15

    private func trim() {
        let now = CACurrentMediaTime()
        while let f = samples.first, now - f.time > lookBack {
            samples.removeFirst()
        }
    }
}
