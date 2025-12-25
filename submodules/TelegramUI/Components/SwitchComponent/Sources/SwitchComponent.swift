import Foundation
import UIKit
import Display
import AsyncDisplayKit
import ComponentFlow
import TelegramPresentationData
import CustomLiquidGlass

public final class SwitchComponent: Component {
    public typealias EnvironmentType = Empty

    let tintColor: UIColor?
    let value: Bool
    let valueUpdated: (Bool) -> Void

    public init(
        tintColor: UIColor? = nil,
        value: Bool,
        valueUpdated: @escaping (Bool) -> Void
    ) {
        self.tintColor = tintColor
        self.value = value
        self.valueUpdated = valueUpdated
    }

    public static func ==(lhs: SwitchComponent, rhs: SwitchComponent) -> Bool {
        if lhs.tintColor != rhs.tintColor {
            return false
        }
        if lhs.value != rhs.value {
            return false
        }
        return true
    }

    public final class View: UIView {
        private var nativeSwitchView: UISwitch?
        private var liquidGlassSwitchView: LiquidGlassSwitchView?

        private var component: SwitchComponent?

        override init(frame: CGRect) {
            super.init(frame: frame)

            // Use native UISwitch for iOS 26+, custom LiquidGlassSwitchView for older
            if #available(iOS 26.0, *) {
                let switchView = UISwitch()
                self.nativeSwitchView = switchView
                self.addSubview(switchView)
                switchView.addTarget(self, action: #selector(self.valueChanged(_:)), for: .valueChanged)
            } else {
                let switchView = LiquidGlassSwitchView()
                self.liquidGlassSwitchView = switchView
                self.addSubview(switchView)
                switchView.addTarget(self, action: #selector(self.valueChanged(_:)), for: .valueChanged)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func valueChanged(_ sender: Any) {
            if let nativeSwitch = sender as? UISwitch {
                self.component?.valueUpdated(nativeSwitch.isOn)
            } else if let liquidGlassSwitch = sender as? LiquidGlassSwitchView {
                self.component?.valueUpdated(liquidGlassSwitch.isOn)
            }
        }

        func update(component: SwitchComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: ComponentTransition) -> CGSize {
            self.component = component

            if let switchView = self.nativeSwitchView {
                if let tintColor = component.tintColor {
                    switchView.onTintColor = tintColor
                }
                switchView.setOn(component.value, animated: !transition.animation.isImmediate)
                switchView.sizeToFit()
                switchView.frame = CGRect(origin: .zero, size: switchView.frame.size)
                return switchView.frame.size
            } else if let switchView = self.liquidGlassSwitchView {
                if let tintColor = component.tintColor {
                    switchView.onTintColor = tintColor
                }
                switchView.setOn(component.value, animated: !transition.animation.isImmediate)
                let size = switchView.sizeThatFits(availableSize)
                switchView.frame = CGRect(origin: .zero, size: size)
                return size
            }

            return CGSize(width: 51, height: 31)
        }
    }

    public func makeView() -> View {
        return View(frame: CGRect())
    }

    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
