//
//  PowerSourceCadenceTests.swift
//  ThermalForge
//
//  The thermal tick drops to 1 Hz on battery: the SMC read is the whole cost of
//  a tick and a laptop idling on battery does not need a 10 Hz control loop.
//  These pin the decision, including the case where the caller already asked for
//  something slower than the battery floor.
//

import Testing

@testable import ThermalForgeCore

@Suite("Power source cadence")
struct PowerSourceCadenceTests {

    @Test("AC keeps the configured 100ms cadence")
    func acCadence() {
        #expect(ThermalMonitor.cadence(configured: 0.1, onBattery: false) == 0.1)
    }

    @Test("Battery drops the 100ms cadence to 1s")
    func batteryCadence() {
        #expect(ThermalMonitor.cadence(configured: 0.1, onBattery: true) == 1.0)
    }

    @Test("A caller that asked for something slower keeps its own interval")
    func slowCallerWins() {
        #expect(ThermalMonitor.cadence(configured: 2.5, onBattery: true) == 2.5)
        #expect(ThermalMonitor.cadence(configured: 2.5, onBattery: false) == 2.5)
    }
}
