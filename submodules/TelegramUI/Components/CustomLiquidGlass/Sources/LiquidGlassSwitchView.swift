//
//  LiquidGlassSwitchView.swift
//  CustomLiquidGlass
//
//  Created by MUS
//

import Foundation
import UIKit
import QuartzCore

/// Custom switch view with blur effect on thumb only for iOS < 26
public final class LiquidGlassSwitchView: UIControl {

    // MARK: - Properties

    public var isOn: Bool = false {
        didSet {
            if oldValue != isOn {
                updateThumbPosition(animated: true)
                sendActions(for: .valueChanged)
            }
        }
    }

    public var onTintColor: UIColor = UIColor.systemGreen {
        didSet {
            updateColors()
        }
    }

    public var thumbTintColor: UIColor = .white {
        didSet {
            thumbOverlayView.backgroundColor = thumbTintColor.withAlphaComponent(0.9)
        }
    }

    private let trackView: UIView
    private let thumbContainer: UIView
    private let thumbBlurView: UIVisualEffectView
    private let thumbOverlayView: UIView
    private let thumbShadowView: UIView

    private var feedbackGenerator: UIImpactFeedbackGenerator?

    // MARK: - Constants

    private let trackHeight: CGFloat = 31.0
    private let trackWidth: CGFloat = 51.0
    private let thumbSize: CGFloat = 27.0
    private let thumbPadding: CGFloat = 2.0

    // MARK: - Initialization

    public override init(frame: CGRect) {
        self.trackView = UIView()
        self.thumbContainer = UIView()
        self.thumbBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        self.thumbOverlayView = UIView()
        self.thumbShadowView = UIView()

        super.init(frame: CGRect(origin: frame.origin, size: CGSize(width: trackWidth, height: trackHeight)))

        setupViews()
        setupGestures()
        configureBlurFilter()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Track
        trackView.frame = CGRect(origin: .zero, size: CGSize(width: trackWidth, height: trackHeight))
        trackView.layer.cornerRadius = trackHeight / 2
        trackView.backgroundColor = UIColor.systemGray4
        addSubview(trackView)

        // Thumb shadow
        thumbShadowView.frame = CGRect(x: thumbPadding, y: thumbPadding, width: thumbSize, height: thumbSize)
        thumbShadowView.backgroundColor = .black
        thumbShadowView.layer.cornerRadius = thumbSize / 2
        thumbShadowView.layer.shadowColor = UIColor.black.cgColor
        thumbShadowView.layer.shadowOffset = CGSize(width: 0, height: 3)
        thumbShadowView.layer.shadowRadius = 8
        thumbShadowView.layer.shadowOpacity = 0.15
        addSubview(thumbShadowView)

        // Thumb container
        thumbContainer.frame = CGRect(x: thumbPadding, y: thumbPadding, width: thumbSize, height: thumbSize)
        thumbContainer.layer.cornerRadius = thumbSize / 2
        thumbContainer.clipsToBounds = true
        addSubview(thumbContainer)

        // Blur view for thumb
        thumbBlurView.frame = thumbContainer.bounds
        thumbBlurView.layer.cornerRadius = thumbSize / 2
        thumbBlurView.clipsToBounds = true
        thumbContainer.addSubview(thumbBlurView)

        // Thumb overlay
        thumbOverlayView.frame = thumbContainer.bounds
        thumbOverlayView.backgroundColor = thumbTintColor.withAlphaComponent(0.9)
        thumbOverlayView.layer.cornerRadius = thumbSize / 2
        thumbContainer.addSubview(thumbOverlayView)

        updateColors()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    }

    private func configureBlurFilter() {
        // Apply custom blur radius for glass effect
        if let sublayer = thumbBlurView.layer.sublayers?[0], let filters = sublayer.filters {
            sublayer.backgroundColor = nil
            sublayer.isOpaque = false

            var blurFilter: NSObject?
            for filter in filters {
                if let filter = filter as? NSObject, String(describing: filter).contains("gaussianBlur") {
                    blurFilter = filter
                    break
                }
            }

            if let filter = blurFilter {
                filter.setValue(LiquidGlassConfiguration.Blur.switchThumb as NSNumber, forKey: "inputRadius")
                sublayer.filters = [filter]
            }
        }
    }

    // MARK: - Layout

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: trackWidth, height: trackHeight)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: trackWidth, height: trackHeight)
    }

    // MARK: - Updates

    private func updateColors() {
        UIView.animate(withDuration: 0.25) {
            self.trackView.backgroundColor = self.isOn ? self.onTintColor : UIColor.systemGray4
        }
    }

    private func updateThumbPosition(animated: Bool) {
        let thumbX: CGFloat = isOn ? (trackWidth - thumbSize - thumbPadding) : thumbPadding

        updateColors()

        if animated {
            // Use spring animation for natural feel
            let animation = CASpringAnimation(keyPath: "position.x")
            animation.fromValue = thumbContainer.layer.position.x
            animation.toValue = thumbX + thumbSize / 2
            animation.mass = LiquidGlassConfiguration.Spring.mass
            animation.stiffness = LiquidGlassConfiguration.Spring.stiffness
            animation.damping = LiquidGlassConfiguration.Spring.damping
            animation.duration = animation.settlingDuration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false

            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                self.thumbContainer.layer.removeAnimation(forKey: "thumbPosition")
                self.thumbShadowView.layer.removeAnimation(forKey: "shadowPosition")
                self.thumbContainer.frame.origin.x = thumbX
                self.thumbShadowView.frame.origin.x = thumbX
            }

            thumbContainer.layer.add(animation, forKey: "thumbPosition")
            thumbShadowView.layer.add(animation, forKey: "shadowPosition")

            CATransaction.commit()

            feedbackGenerator?.impactOccurred()
        } else {
            thumbContainer.frame.origin.x = thumbX
            thumbShadowView.frame.origin.x = thumbX
        }
    }

    // MARK: - Gestures

    @objc private func handleTap() {
        isOn.toggle()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)

        switch gesture.state {
        case .changed:
            let currentX = thumbContainer.frame.origin.x
            var newX = currentX + translation.x
            gesture.setTranslation(.zero, in: self)

            let minX = thumbPadding
            let maxX = trackWidth - thumbSize - thumbPadding

            // Apply rubber-band when dragging past bounds
            if newX < minX {
                let overflow = minX - newX
                let rubberBandOffset = LiquidGlassConfiguration.RubberBand.constant / (overflow / trackWidth + LiquidGlassConfiguration.RubberBand.constant)
                newX = minX - overflow * rubberBandOffset * 0.3
            } else if newX > maxX {
                let overflow = newX - maxX
                let rubberBandOffset = LiquidGlassConfiguration.RubberBand.constant / (overflow / trackWidth + LiquidGlassConfiguration.RubberBand.constant)
                newX = maxX + overflow * rubberBandOffset * 0.3
            }

            thumbContainer.frame.origin.x = newX
            thumbShadowView.frame.origin.x = newX

            // Update track color based on position
            let progress = (newX - minX) / (maxX - minX)
            trackView.backgroundColor = UIColor.blend(from: .systemGray4, to: onTintColor, progress: progress)

        case .ended, .cancelled:
            let currentX = thumbContainer.frame.origin.x
            let midPoint = trackWidth / 2 - thumbSize / 2

            // Determine final state based on position and velocity
            let shouldBeOn: Bool
            if abs(velocity.x) > 200 {
                shouldBeOn = velocity.x > 0
            } else {
                shouldBeOn = currentX > midPoint
            }

            if shouldBeOn != isOn {
                isOn = shouldBeOn
            } else {
                updateThumbPosition(animated: true)
            }

        default:
            break
        }
    }

    // MARK: - Public Methods

    public func setOn(_ on: Bool, animated: Bool) {
        if isOn != on {
            isOn = on
            if !animated {
                updateThumbPosition(animated: false)
            }
        }
    }
}

// MARK: - UIColor Extension

private extension UIColor {
    static func blend(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        let clampedProgress = max(0, min(1, progress))

        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0

        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)

        return UIColor(
            red: fromR + (toR - fromR) * clampedProgress,
            green: fromG + (toG - fromG) * clampedProgress,
            blue: fromB + (toB - fromB) * clampedProgress,
            alpha: fromA + (toA - fromA) * clampedProgress
        )
    }
}
