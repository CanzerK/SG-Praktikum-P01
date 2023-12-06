//
//  DeviceManagerDemo.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 03.12.23.
//

import Foundation
import Combine
import CoreBluetooth

class DeviceManagerDemo: DeviceCoordinatorDelegate, DeviceDelegate {
	var spheroManager: DeviceCoordinator!
	var cancellables = Array<AnyCancellable>()

	init() {
		spheroManager = DeviceCoordinator(self)
	}

	func deviceCoordinatorDidUpdateBluetoothState(_ coordinator: DeviceCoordinator, state: CBManagerState) {
		if (state == .poweredOn) {
			coordinator.findDevices()
		}
	}

	func deviceCoordinatorDidFindDevice(_ coordinator: DeviceCoordinator, device: Device) {
		print("Found device \(device.name!).")

		device.delegate = self

		coordinator.connect(toDevice: device)
			.receive(on: DispatchQueue.main)
			.flatMap {
				return device.wake()
			}
			.flatMap {
				return device.enterSoftSleep()
			}
			.sink { completion in
				switch completion {
				case .finished:
					print("Data written.")
				case .failure(let error):
					print(error)
				}
			} receiveValue: { future in

			}
			.store(in: &cancellables)
	}

	func deviceDidChangeState(_ device: Device) {
		print("State is now \(device.state).")
	}

	func deviceDidUpdateConnectionState(_ device: Device, state: ConnectionState, error: DeviceError?) {
		switch state {
		case .connected:
			print("Connected to \(device.name!).")
		default:
			print("Connection state changed to \(state).")
		}
	}
}
