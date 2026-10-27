//
//  MenuBarLabelGate.swift
//  ThermalForge
//
//  Decides when the menu bar label may be published.
//

import Foundation

/// The menu bar label is backed by an `NSStatusItem`: every publish re-renders it
/// and AppKit snapshots the view to a bitmap for MenuBarAgent, which also costs
/// WindowServer work. The monitor calls `onUpdate` every 500ms, so publishing
/// unconditionally re-snapshots identical content twice a second — measured at a
/// steady ~13% of a core for a label that only shows a rounded temperature.
///
/// Publish only when the rendered label would actually change: the rounded
/// temperature (the only text), the monitor state (the icon), or the daemon badge.
/// While the dropdown is open the user is watching live values, so publish every
/// tick regardless.
public struct MenuBarLabelGate {

    /// Everything the rendered label depends on, already reduced to display form.
    /// `tempC` is rounded by the caller so sub-degree sensor noise can never differ.
    public struct Label: Equatable {
        public let tempC: Int?
        public let state: MonitorState
        public let badge: Bool

        public init(tempC: Int?, state: MonitorState, badge: Bool) {
            self.tempC = tempC
            self.state = state
            self.badge = badge
        }
    }

    private var last: Label?

    public init() {}

    /// Records `label` and reports whether the caller should publish it.
    public mutating func shouldPublish(_ label: Label, menuOpen: Bool) -> Bool {
        if menuOpen {
            last = label
            return true
        }
        guard label != last else { return false }
        last = label
        return true
    }
}
