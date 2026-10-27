//
//  MenuWindowVisibility.swift
//  ThermalForge
//
//  Reports whether the menu bar dropdown's window is actually on screen.
//

import AppKit
import SwiftUI

/// Reports the visibility of the window hosting the dropdown.
///
/// `MenuBarExtra` builds its content view eagerly and keeps it alive while the
/// dropdown is closed, so `onAppear`/`onDisappear` do not track the menu: onAppear
/// fires once at launch and onDisappear never fires at all. That made `AppState`
/// think the user was always watching and publish live values at the monitor's
/// 2 Hz cadence — the exact re-snapshot cost this fix exists to remove.
///
/// The window itself is the authoritative signal: key/occlusion notifications give
/// the instant answer, and a 1 Hz check covers any transition those miss. Both are
/// far cheaper than the layout + bitmap work a needless publish costs.
struct MenuWindowVisibility: NSViewRepresentable {
    let onChange: (Bool) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = TrackingView()
        view.onChange = onChange
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? TrackingView)?.report()
    }

    final class TrackingView: NSView {
        var onChange: ((Bool) -> Void)?
        private var observers: [NSObjectProtocol] = []
        private var timer: Timer?
        private var lastReported: Bool?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopObserving()
            guard let window else {
                report()
                return
            }
            let names: [Notification.Name] = [
                NSWindow.didBecomeKeyNotification,
                NSWindow.didResignKeyNotification,
                NSWindow.didChangeOcclusionStateNotification,
                NSWindow.willCloseNotification,
            ]
            observers = names.map { name in
                NotificationCenter.default.addObserver(
                    forName: name, object: window, queue: .main
                ) { [weak self] _ in
                    self?.report()
                }
            }
            let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                self?.report()
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
            report()
        }

        func report() {
            let visible = (window?.isVisible ?? false) && (window?.occlusionState.contains(.visible) ?? false)
            guard visible != lastReported else { return }
            lastReported = visible
            onChange?(visible)
        }

        private func stopObserving() {
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
            timer?.invalidate()
            timer = nil
        }

        deinit {
            observers.forEach(NotificationCenter.default.removeObserver)
            timer?.invalidate()
        }
    }
}
