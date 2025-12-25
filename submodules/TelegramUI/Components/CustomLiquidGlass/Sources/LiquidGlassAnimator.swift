//
//  LiquidGlassAnimator.swift
//  CustomLiquidGlass
//
//  Created by MUS
//

import Foundation
import UIKit
import QuartzCore

/// Utility class for Liquid Glass animations matching iOS 26 behavior
public final class LiquidGlassAnimator {

    // MARK: - Rubber Band Effects

    /// Calculate rubber-band offset for drag past bounds
    /// - Parameters:
    ///   - offset: The drag offset beyond bounds
    ///   - dimension: The dimension (width or height) of the element
    ///   - constant: Resistance constant (default: 0.55)
    /// - Returns: The rubber-banded offset value
    public static func rubberBandOffset(
        offset: CGFloat,
        dimension: CGFloat,
        constant: CGFloat = LiquidGlassConfiguration.RubberBand.constant
    ) -> CGFloat {
        guard dimension > 0 else { return offset }
        let resistance = 1.0 / (abs(offset) * constant / dimension + 1.0)
        return offset * resistance
    }

    /// Apply stretch transform to view based on drag offset
    /// - Parameters:
    ///   - view: The view to stretch
    ///   - offset: The drag offset
    ///   - bounds: The bounds size of the element
    ///   - animated: Whether to animate the change
    public static func applyStretch(
        to view: UIView,
        offset: CGPoint,
        bounds: CGSize,
        animated: Bool = false
    ) {
        let maxStretch = LiquidGlassConfiguration.RubberBand.maxStretch

        let stretchX = 1.0 + abs(rubberBandOffset(offset: offset.x, dimension: bounds.width)) / bounds.width * maxStretch
        let stretchY = 1.0 + abs(rubberBandOffset(offset: offset.y, dimension: bounds.height)) / bounds.height * maxStretch

        let transform = CGAffineTransform(scaleX: stretchX, y: stretchY)

        if animated {
            UIView.animate(
                withDuration: LiquidGlassConfiguration.Duration.transition,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    view.transform = transform
                }
            )
        } else {
            view.transform = transform
        }
    }

    /// Animate snap-back from stretched state with bounce
    /// - Parameters:
    ///   - view: The view to snap back
    ///   - completion: Optional completion handler
    public static func snapBack(
        view: UIView,
        completion: (() -> Void)? = nil
    ) {
        let springAnimation = CASpringAnimation(keyPath: "transform")
        springAnimation.fromValue = view.layer.presentation()?.transform ?? view.layer.transform
        springAnimation.toValue = CATransform3DIdentity
        springAnimation.mass = LiquidGlassConfiguration.Bounce.mass
        springAnimation.stiffness = LiquidGlassConfiguration.Bounce.stiffness
        springAnimation.damping = LiquidGlassConfiguration.Bounce.damping
        springAnimation.initialVelocity = 0
        springAnimation.duration = springAnimation.settlingDuration
        springAnimation.fillMode = .forwards
        springAnimation.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            view.layer.removeAnimation(forKey: "snapBack")
            view.transform = .identity
            completion?()
        }
        view.layer.add(springAnimation, forKey: "snapBack")
        CATransaction.commit()
    }

    // MARK: - Spring Animations

    /// Create a spring animation matching iOS 26 parameters
    /// - Parameters:
    ///   - keyPath: The key path to animate
    ///   - from: Starting value
    ///   - to: Ending value
    /// - Returns: Configured CASpringAnimation
    public static func makeSpringAnimation(
        keyPath: String,
        from: Any?,
        to: Any?
    ) -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.mass = LiquidGlassConfiguration.Spring.mass
        animation.stiffness = LiquidGlassConfiguration.Spring.stiffness
        animation.damping = LiquidGlassConfiguration.Spring.damping
        animation.initialVelocity = 0
        animation.duration = animation.settlingDuration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }

    /// Create a bounce spring animation
    /// - Parameters:
    ///   - keyPath: The key path to animate
    ///   - from: Starting value
    ///   - to: Ending value
    ///   - initialVelocity: Initial velocity (default: 0)
    ///   - damping: Custom damping (default: 88.0)
    /// - Returns: Configured CASpringAnimation
    public static func makeBounceAnimation(
        keyPath: String,
        from: Any?,
        to: Any?,
        initialVelocity: CGFloat = 0,
        damping: CGFloat = LiquidGlassConfiguration.Bounce.damping
    ) -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.mass = LiquidGlassConfiguration.Bounce.mass
        animation.stiffness = LiquidGlassConfiguration.Bounce.stiffness
        animation.damping = damping
        animation.initialVelocity = initialVelocity
        animation.duration = animation.settlingDuration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }

    // MARK: - Scale Animations

    /// Animate scale with spring physics
    /// - Parameters:
    ///   - layer: The layer to animate
    ///   - from: Starting scale
    ///   - to: Ending scale
    ///   - completion: Optional completion handler
    public static func animateScale(
        layer: CALayer,
        from: CGFloat,
        to: CGFloat,
        completion: (() -> Void)? = nil
    ) {
        let animation = makeSpringAnimation(
            keyPath: "transform.scale",
            from: from,
            to: to
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.removeAnimation(forKey: "scaleAnimation")
            layer.transform = CATransform3DMakeScale(to, to, 1.0)
            completion?()
        }
        layer.add(animation, forKey: "scaleAnimation")
        CATransaction.commit()
    }

    /// Animate scale with bounce physics
    /// - Parameters:
    ///   - layer: The layer to animate
    ///   - from: Starting scale
    ///   - to: Ending scale
    ///   - velocity: Initial velocity
    ///   - completion: Optional completion handler
    public static func animateScaleBounce(
        layer: CALayer,
        from: CGFloat,
        to: CGFloat,
        velocity: CGFloat = 0,
        completion: (() -> Void)? = nil
    ) {
        let animation = makeBounceAnimation(
            keyPath: "transform.scale",
            from: from,
            to: to,
            initialVelocity: velocity
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.removeAnimation(forKey: "scaleBounceAnimation")
            layer.transform = CATransform3DMakeScale(to, to, 1.0)
            completion?()
        }
        layer.add(animation, forKey: "scaleBounceAnimation")
        CATransaction.commit()
    }

    // MARK: - Position Animations

    /// Animate position with spring physics
    /// - Parameters:
    ///   - layer: The layer to animate
    ///   - from: Starting position
    ///   - to: Ending position
    ///   - completion: Optional completion handler
    public static func animatePosition(
        layer: CALayer,
        from: CGPoint,
        to: CGPoint,
        completion: (() -> Void)? = nil
    ) {
        let animation = makeSpringAnimation(
            keyPath: "position",
            from: NSValue(cgPoint: from),
            to: NSValue(cgPoint: to)
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.removeAnimation(forKey: "positionAnimation")
            layer.position = to
            completion?()
        }
        layer.add(animation, forKey: "positionAnimation")
        CATransaction.commit()
    }

    // MARK: - Bounds Animations

    /// Animate bounds with spring physics
    /// - Parameters:
    ///   - layer: The layer to animate
    ///   - from: Starting bounds
    ///   - to: Ending bounds
    ///   - completion: Optional completion handler
    public static func animateBounds(
        layer: CALayer,
        from: CGRect,
        to: CGRect,
        completion: (() -> Void)? = nil
    ) {
        let animation = makeSpringAnimation(
            keyPath: "bounds",
            from: NSValue(cgRect: from),
            to: NSValue(cgRect: to)
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            layer.removeAnimation(forKey: "boundsAnimation")
            layer.bounds = to
            completion?()
        }
        layer.add(animation, forKey: "boundsAnimation")
        CATransaction.commit()
    }

    // MARK: - Highlight Animation

    /// Apply highlight animation to a view
    /// - Parameters:
    ///   - view: The view to highlight
    ///   - highlighted: Whether to apply or remove highlight
    public static func applyHighlight(to view: UIView, highlighted: Bool) {
        let scale: CGFloat = highlighted ? LiquidGlassConfiguration.Scale.pressed : 1.0

        if highlighted {
            // Quick scale down
            UIView.animate(
                withDuration: LiquidGlassConfiguration.Duration.press,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            )
        } else {
            // Bounce back
            animateScaleBounce(
                layer: view.layer,
                from: LiquidGlassConfiguration.Scale.pressed,
                to: 1.0,
                velocity: 0.5
            )
        }
    }
}

// MARK: - CALayer Extension

public extension CALayer {

    /// Animate with spring physics using iOS 26 parameters
    func animateLiquidGlassSpring(
        from: Any?,
        to: Any?,
        keyPath: String,
        completion: (() -> Void)? = nil
    ) {
        let animation = LiquidGlassAnimator.makeSpringAnimation(
            keyPath: keyPath,
            from: from,
            to: to
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.removeAnimation(forKey: "liquidGlassSpring_\(keyPath)")
            completion?()
        }
        self.add(animation, forKey: "liquidGlassSpring_\(keyPath)")
        CATransaction.commit()
    }

    /// Animate with bounce physics
    func animateLiquidGlassBounce(
        from: Any?,
        to: Any?,
        keyPath: String,
        velocity: CGFloat = 0,
        damping: CGFloat = LiquidGlassConfiguration.Bounce.damping,
        completion: (() -> Void)? = nil
    ) {
        let animation = LiquidGlassAnimator.makeBounceAnimation(
            keyPath: keyPath,
            from: from,
            to: to,
            initialVelocity: velocity,
            damping: damping
        )

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.removeAnimation(forKey: "liquidGlassBounce_\(keyPath)")
            completion?()
        }
        self.add(animation, forKey: "liquidGlassBounce_\(keyPath)")
        CATransaction.commit()
    }
}

// MARK: - UIView Extension

public extension UIView {

    /// Apply liquid glass highlight effect
    func applyLiquidGlassHighlight(_ highlighted: Bool) {
        LiquidGlassAnimator.applyHighlight(to: self, highlighted: highlighted)
    }

    /// Apply rubber band stretch effect
    func applyLiquidGlassStretch(offset: CGPoint, animated: Bool = false) {
        LiquidGlassAnimator.applyStretch(
            to: self,
            offset: offset,
            bounds: self.bounds.size,
            animated: animated
        )
    }

    /// Snap back from stretched state
    func snapBackFromStretch(completion: (() -> Void)? = nil) {
        LiquidGlassAnimator.snapBack(view: self, completion: completion)
    }
}
