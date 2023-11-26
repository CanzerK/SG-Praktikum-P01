//
//  DemoApp.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 09.11.23.
//

import SwiftUI
import CoreBluetooth
import Combine

@main
struct DemoApp: App, DeviceCoordinatorDelegate {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}

	var spheroManager: DeviceCoordinator!
	var disposeBag = Set<AnyCancellable>()

	init() {
		spheroManager = DeviceCoordinator(self)
	}

	func deviceCoordinatorDidUpdateBluetoothState(_ coordinator: DeviceCoordinator, state: CBManagerState) {
		if (state == .poweredOn) {
			coordinator.findDevices()
		}
	}

	mutating func deviceCoordinatorDidFindDevice(_ coordinator: DeviceCoordinator, device: Device) {
		coordinator.connect(toDevice: device)
			.receive(on: DispatchQueue.main)
			.filter { state in
				return state == .connected
			}
			.sink { event in
				print("Connected to \(device.name!).")

				device.wake()
			} receiveValue: { value in
				print(value)
			}
			.store(in: &disposeBag)
	}
}
