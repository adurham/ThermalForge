//
//  MenuBarLabelGateTests.swift
//  ThermalForge
//

import Testing

@testable import ThermalForgeCore

@Suite("Menu bar label gate")
struct MenuBarLabelGateTests {

    private func label(_ tempC: Int?, _ state: MonitorState = .idle, badge: Bool = false) -> MenuBarLabelGate.Label {
        .init(tempC: tempC, state: state, badge: badge)
    }

    @Test("First label always publishes")
    func firstLabelPublishes() {
        var gate = MenuBarLabelGate()
        let published = gate.shouldPublish(label(47), menuOpen: false)
        #expect(published)
    }

    @Test("Identical label is suppressed — the 2 Hz monitor tick must not re-snapshot it")
    func identicalLabelSuppressed() {
        var gate = MenuBarLabelGate()
        _ = gate.shouldPublish(label(47), menuOpen: false)
        for _ in 0..<20 {
            let published = gate.shouldPublish(label(47), menuOpen: false)
            #expect(published == false)
        }
    }

    @Test("A one-degree change publishes; a state or badge change publishes")
    func visibleChangesPublish() {
        var gate = MenuBarLabelGate()
        let first = gate.shouldPublish(label(47), menuOpen: false)
        #expect(first)

        let warmer = gate.shouldPublish(label(48), menuOpen: false)
        #expect(warmer)

        let active = gate.shouldPublish(label(48, .active(profileName: "Performance")), menuOpen: false)
        #expect(active)

        let badged = gate.shouldPublish(label(48, .active(profileName: "Performance"), badge: true), menuOpen: false)
        #expect(badged)

        let repeatBadged = gate.shouldPublish(label(48, .active(profileName: "Performance"), badge: true), menuOpen: false)
        #expect(repeatBadged == false)
    }

    @Test("Temperature becoming unavailable publishes")
    func nilTemperaturePublishes() {
        var gate = MenuBarLabelGate()
        _ = gate.shouldPublish(label(47), menuOpen: false)

        let lost = gate.shouldPublish(label(nil), menuOpen: false)
        #expect(lost)

        let stillLost = gate.shouldPublish(label(nil), menuOpen: false)
        #expect(stillLost == false)
    }

    @Test("Open menu publishes every tick, and closing it restores suppression")
    func openMenuForcesLivePublishing() {
        var gate = MenuBarLabelGate()
        _ = gate.shouldPublish(label(47), menuOpen: false)

        // Same label, but the dropdown is on screen: live values win.
        let firstOpen = gate.shouldPublish(label(47), menuOpen: true)
        let secondOpen = gate.shouldPublish(label(47), menuOpen: true)
        #expect(firstOpen)
        #expect(secondOpen)

        // Closed again with no visible change: back to suppression.
        let closed = gate.shouldPublish(label(47), menuOpen: false)
        #expect(closed == false)
    }
}
