//
//  LiquidGlassButtonDecorator.swift
//  CustomLiquidGlass
//
//  Created by MUS
//

import Foundation
import UIKit
import QuartzCore

/// Decorator class for applying Liquid Glass effects to buttons
public final class LiquidGlassButtonDecorator {

    // MARK: - State Management

    private weak var view: UIView?
    private var isHighlighted: Bool = false

    public init(view: UIView) {
        self.view = view
    }

    // MARK: - Press State

    /// Apply pressed state with scale down
    /// - Parameter animated: Whether to animate the change
    public func applyPressedState(animated: Bool = true) {
        guard let view = view, !isHighlighted else { return }
        isHighlighted = true

        let scale = LiquidGlassConfiguration.Scale.pressed

        if animated {
            UIView.animate(
                withDuration: LiquidGlassConfiguration.Duration.press,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            )
        } else {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    /// Apply released state with bounce back
    /// - Parameter animated: Whether to animate the change
    public func applyReleasedState(animated: Bool = true) {
        guard let view = view, isHighlighted else { return }
        isHighlighted = false

        if animated {
            // Use spring bounce animation
            let animation = CASpringAnimation(keyPath: "transform.scale")
            animation.fromValue = LiquidGlassConfiguration.Scale.pressed
            animation.toValue = 1.0
            animation.mass = LiquidGlassConfiguration.Bounce.mass
            animation.stiffness = LiquidGlassConfiguration.Bounce.stiffness
            animation.damping = LiquidGlassConfiguration.Bounce.damping
            animation.initialVelocity = 0.5
            animation.duration = animation.settlingDuration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false

            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak view] in
                view?.layer.removeAnimation(forKey: "bounceBack")
                view?.transform = .identity
            }
            view.layer.add(animation, forKey: "bounceBack")
            CATransaction.commit()
        } else {
            view.transform = .identity
        }
    }

    /// Update state based on highlight
    /// - Parameter highlighted: Whether the button is highlighted
    public func setHighlighted(_ highlighted: Bool, animated: Bool = true) {
        if highlighted {
            applyPressedState(animated: animated)
        } else {
            applyReleasedState(animated: animated)
        }
    }

    // MARK: - Static Methods

    /// Apply pressed state to a view
    public static func applyPressedState(to view: UIView, animated: Bool = true) {
        let scale = LiquidGlassConfiguration.Scale.pressed

        if animated {
            UIView.animate(
                withDuration: LiquidGlassConfiguration.Duration.press,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            )
        } else {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    /// Apply released state with bounce to a view
    public static func applyReleasedState(to view: UIView, animated: Bool = true) {
        if animated {
            LiquidGlassAnimator.animateScaleBounce(
                layer: view.layer,
                from: LiquidGlassConfiguration.Scale.pressed,
                to: 1.0,
                velocity: 0.5
            ) {
                view.transform = .identity
            }
        } else {
            view.transform = .identity
        }
    }

    /// Apply bounce animation to a layer
    public static func applyBounceAnimation(
        to layer: CALayer,
        from: CGFloat = LiquidGlassConfiguration.Scale.pressed,
        to: CGFloat = 1.0,
        velocity: CGFloat = 0.5
    ) {
        let animation = CASpringAnimation(keyPath: "transform.scale")
        animation.fromValue = from
        animation.toValue = to
        animation.mass = LiquidGlassConfiguration.Bounce.mass
        animation.stiffness = LiquidGlassConfiguration.Bounce.stiffness
        animation.damping = LiquidGlassConfiguration.Bounce.damping
        animation.initialVelocity = velocity
        animation.duration = animation.settlingDuration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.removeAnimation(forKey: "liquidGlassBounce")
            layer.transform = CATransform3DMakeScale(to, to, 1.0)
        }
        layer.add(animation, forKey: "liquidGlassBounce")
        CATransaction.commit()
    }

    /// Apply scale animation with spring physics
    public static func applyScaleAnimation(
        to view: UIView,
        from: CGFloat,
        to: CGFloat,
        useSpring: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        if useSpring {
            LiquidGlassAnimator.animateScale(
                layer: view.layer,
                from: from,
                to: to,
                completion: completion
            )
        } else {
            UIView.animate(
                withDuration: LiquidGlassConfiguration.Duration.transition,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    view.transform = CGAffineTransform(scaleX: to, y: to)
                },
                completion: { _ in
                    completion?()
                }
            )
        }
    }
}

// MARK: - HighlightTrackingButton Extension

/// Protocol for buttons that support highlight tracking
public protocol LiquidGlassHighlightable: AnyObject {
    var liquidGlassDecorator: LiquidGlassButtonDecorator? { get set }
    func setupLiquidGlassEffect()
}

extension LiquidGlassHighlightable where Self: UIView {
    public func setupLiquidGlassEffect() {
        self.liquidGlassDecorator = LiquidGlassButtonDecorator(view: self)
    }
}
