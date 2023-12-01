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
struct DemoApp: App, DeviceCoordinatorDelegate, DeviceDelegate {
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

	mutating func deviceCoordinatorDidUpdateBluetoothState(_ coordinator: DeviceCoordinator, state: CBManagerState) {
		if (state == .poweredOn) {
			coordinator.findDevices()
				.map { device in
					print("Found to \(device.name!).")

					return coordinator.connect(toDevice: device)
				}
				.sink { state in
					print("Connected to \(state).")

				} receiveValue: { value in
					print("Connection state: \(state).")
				}
				.store(in: &disposeBag)
		}
	}

	mutating func deviceCoordinatorDidFindDevice(_ coordinator: DeviceCoordinator, device: Device) {
		device.delegate = self

		coordinator.connect(toDevice: device)
			.receive(on: DispatchQueue.main)
			.filter { state in
				return state == .connected
			}
			.map { o in
				print("Connected to \(device.name!).")

//				return device.enterSoftSleep()
//				return device.wake()
			}
			.sink { event in
				print("Finished.")

			} receiveValue: { value in
				print(value)
			}
			.store(in: &disposeBag)
	}

	func deviceDidChangeState(_ device: Device) {
		print("State is now \(device.state).")
	}
}
