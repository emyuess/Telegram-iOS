//
//  LiquidGlassConfiguration.swift
//  CustomLiquidGlass
//
//  Created by MUS
//

import Foundation
import UIKit

/// Configuration constants for Liquid Glass effects on iOS 18 and older
public struct LiquidGlassConfiguration {

    // MARK: - Spring Animation Parameters (matching iOS 26)

    /// iOS 26-style spring animation parameters
    public struct Spring {
        /// Mass for standard spring animation
        public static let mass: CGFloat = 1.0
        /// Stiffness for standard spring animation
        public static let stiffness: CGFloat = 555.027
        /// Damping for standard spring animation
        public static let damping: CGFloat = 47.118
        /// Standard spring duration
        public static let duration: Double = 0.3832
    }

    /// Bounce spring animation parameters
    public struct Bounce {
        /// Mass for bounce spring animation
        public static let mass: CGFloat = 5.0
        /// Stiffness for bounce spring animation
        public static let stiffness: CGFloat = 900.0
        /// Default damping for bounce spring animation
        public static let damping: CGFloat = 88.0
        /// Bounce animation duration
        public static let duration: Double = 0.35
    }

    // MARK: - Scale Factors

    public struct Scale {
        /// Scale when button is pressed
        public static let pressed: CGFloat = 0.9
        /// Scale when element is lifted (tab bar selection)
        public static let lifted: CGFloat = 1.15
        /// Scale for highlight effect
        public static let highlight: CGFloat = 1.05
        /// Minimum scale (for animations)
        public static let minimum: CGFloat = 0.001
    }

    // MARK: - Blur Radii

    public struct Blur {
        /// Standard blur radius for glass backgrounds
        public static let glass: CGFloat = 8.0
        /// Blur radius for switch thumb
        public static let switchThumb: CGFloat = 6.0
        /// Blur radius for slider thumb
        public static let sliderThumb: CGFloat = 4.0
    }

    // MARK: - Rubber Band

    public struct RubberBand {
        /// Resistance constant for rubber band effect
        public static let constant: CGFloat = 0.55
        /// Maximum stretch factor
        public static let maxStretch: CGFloat = 0.1
    }

    // MARK: - Animation Durations

    public struct Duration {
        /// Press animation duration
        public static let press: Double = 0.25
        /// Release animation duration
        public static let release: Double = 0.35
        /// Transition animation duration
        public static let transition: Double = 0.3
        /// Snap back animation duration
        public static let snapBack: Double = 0.5
    }

    // MARK: - Colors

    public struct Colors {
        /// Light tint opacity for glass
        public static let lightTintAlpha: CGFloat = 0.1
        /// Dark tint opacity for glass
        public static let darkTintAlpha: CGFloat = 0.1
        /// Glass overlay opacity
        public static let glassOverlay: CGFloat = 0.6
    }

    // MARK: - Sizes

    public struct Sizes {
        /// Lifted inset for lens effect
        public static let liftedInset: CGFloat = 4.0
        /// Standard switch thumb size
        public static let switchThumb: CGFloat = 28.0
        /// Standard slider knob size
        public static let sliderKnob: CGFloat = 28.0
    }
}
