import Cocoa
import ServiceManagement

/// Settings window. AppKit rather than SwiftUI so the app still builds with
/// Command Line Tools, which do not ship the SwiftUI macro plugin.
final class SettingsViewController: NSViewController {
    private let enableToggle = NSButton(checkboxWithTitle: "Enable Click2Minimize", target: nil, action: nil)
    private let loginToggle = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)

    override func loadView() {
        let title = NSTextField(labelWithString: "Click2Minimize")
        title.font = .boldSystemFont(ofSize: 13)

        enableToggle.target = self
        enableToggle.action = #selector(enableChanged(_:))
        enableToggle.state = UserDefaults.standard.object(forKey: "ClickToMinimizeEnabled") == nil
            || UserDefaults.standard.bool(forKey: "ClickToMinimizeEnabled") ? .on : .off

        loginToggle.target = self
        loginToggle.action = #selector(loginChanged(_:))
        loginToggle.state = UserDefaults.standard.bool(forKey: "LaunchAtLoginEnabled") ? .on : .off

        let footnote = NSTextField(wrappingLabelWithString: "If the app doesn't work, enable Accessibility and Automation permissions from the menu-bar menu.")
        footnote.font = .systemFont(ofSize: 11)
        footnote.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [title, divider(), enableToggle, loginToggle, divider(), footnote])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.frame = NSRect(x: 0, y: 0, width: 280, height: 180)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 180))
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 280)
        ])
        view = container
    }

    private func divider() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    @objc private func enableChanged(_ sender: NSButton) {
        let enabled = sender.state == .on
        UserDefaults.standard.set(enabled, forKey: "ClickToMinimizeEnabled")
        NotificationCenter.default.post(
            name: NSNotification.Name("ClickToHideStateChanged"),
            object: enabled
        )
    }

    @objc private func loginChanged(_ sender: NSButton) {
        let enabled = sender.state == .on
        UserDefaults.standard.set(enabled, forKey: "LaunchAtLoginEnabled")
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            sender.state = enabled ? .off : .on
            UserDefaults.standard.set(!enabled, forKey: "LaunchAtLoginEnabled")
        }
    }
}
