//
//  LiquidGlassSliderThumbView.swift
//  CustomLiquidGlass
//
//  Created by MUS
//

import Foundation
import UIKit
import QuartzCore

/// Blur-enabled thumb overlay for sliders on iOS < 26
public final class LiquidGlassSliderThumbView: UIView {

    // MARK: - Properties

    private let blurEffectView: UIVisualEffectView
    private let overlayView: UIView
    private let shadowView: UIView

    private var currentSize: CGSize = .zero

    // MARK: - Initialization

    public override init(frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)
        self.overlayView = UIView()
        self.shadowView = UIView()

        super.init(frame: frame)

        isUserInteractionEnabled = false
        setupViews()
        configureBlurFilter()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Shadow view
        shadowView.backgroundColor = .clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 3)
        shadowView.layer.shadowRadius = 12
        shadowView.layer.shadowOpacity = 0.25
        addSubview(shadowView)

        // Blur view
        blurEffectView.clipsToBounds = true
        addSubview(blurEffectView)

        // Overlay for glass tint
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        overlayView.clipsToBounds = true
        addSubview(overlayView)
    }

    private func configureBlurFilter() {
        // Apply custom blur radius for glass effect
        if let sublayer = blurEffectView.layer.sublayers?[0], let filters = sublayer.filters {
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
                filter.setValue(LiquidGlassConfiguration.Blur.sliderThumb as NSNumber, forKey: "inputRadius")
                sublayer.filters = [filter]
            }
        }
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        if currentSize != bounds.size {
            currentSize = bounds.size
            updateLayout()
        }
    }

    private func updateLayout() {
        let cornerRadius = min(bounds.width, bounds.height) / 2

        shadowView.frame = bounds
        shadowView.layer.cornerRadius = cornerRadius
        shadowView.layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath

        blurEffectView.frame = bounds
        blurEffectView.layer.cornerRadius = cornerRadius

        overlayView.frame = bounds
        overlayView.layer.cornerRadius = cornerRadius
    }

    // MARK: - Public Methods

    /// Update the thumb view with new parameters
    /// - Parameters:
    ///   - size: The size of the thumb
    ///   - tintColor: Optional tint color for the overlay
    public func update(size: CGSize, tintColor: UIColor? = nil) {
        self.frame.size = size
        if let tintColor = tintColor {
            overlayView.backgroundColor = tintColor.withAlphaComponent(0.8)
        }
        setNeedsLayout()
    }

    /// Create a glass-styled thumb image for use with UISlider
    /// - Parameters:
    ///   - size: The size of the thumb image
    ///   - tintColor: The tint color
    /// - Returns: A rendered thumb image
    public static func generateThumbImage(size: CGSize, tintColor: UIColor = .white) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cornerRadius = min(size.width, size.height) / 2

            // Shadow
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 3), blur: 12, color: UIColor.black.withAlphaComponent(0.25).cgColor)

            // Base circle
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            tintColor.withAlphaComponent(0.9).setFill()
            path.fill()

            // Inner highlight
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let highlightPath = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: cornerRadius - 1)
            UIColor.white.withAlphaComponent(0.3).setStroke()
            highlightPath.lineWidth = 0.5
            highlightPath.stroke()
        }
    }
}

/// Extension to track slider thumb position for overlay placement
public final class LiquidGlassSliderOverlay: UIView {

    private let thumbView: LiquidGlassSliderThumbView
    private weak var slider: UISlider?

    private var displayLink: CADisplayLink?

    public init(slider: UISlider, thumbSize: CGSize = CGSize(width: 28, height: 28)) {
        self.thumbView = LiquidGlassSliderThumbView(frame: CGRect(origin: .zero, size: thumbSize))
        self.slider = slider

        super.init(frame: .zero)

        isUserInteractionEnabled = false
        addSubview(thumbView)

        startTracking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopTracking()
    }

    private func startTracking() {
        displayLink = CADisplayLink(target: self, selector: #selector(updatePosition))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopTracking() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updatePosition() {
        guard let slider = slider else { return }

        // Calculate thumb position based on slider value
        let trackRect = slider.trackRect(forBounds: slider.bounds)
        let thumbRect = slider.thumbRect(forBounds: slider.bounds, trackRect: trackRect, value: slider.value)

        let thumbCenter = CGPoint(
            x: slider.frame.origin.x + thumbRect.midX,
            y: slider.frame.origin.y + thumbRect.midY
        )

        thumbView.center = convert(thumbCenter, from: slider.superview)
    }

    public func update(thumbSize: CGSize, tintColor: UIColor? = nil) {
        thumbView.update(size: thumbSize, tintColor: tintColor)
    }
}
