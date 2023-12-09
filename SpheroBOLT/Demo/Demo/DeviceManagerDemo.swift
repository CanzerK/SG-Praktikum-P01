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
			.retry(3)
			.receive(on: DispatchQueue.main)
			.flatMap {
				return device.wake()
			}
			.delay(for: .seconds(2), scheduler: DispatchQueue.main, options: .none)
			.flatMap {
				return device.driveWithHeading(speed: 50, heading: 180, direction: .forward)
			}
//			.flatMap {
//				return device.setPixelColor(Color(1.0, 0.0, 0.0), pixel: Pixel(2, 2))
//			}
//			.delay(for: .seconds(2), scheduler: DispatchQueue.main, options: .none)
//			.flatMap {
//				return device.enterSoftSleep()
//			}
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					print(error)
				}
			} receiveValue: { value in
				print("Got \(value).")
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
