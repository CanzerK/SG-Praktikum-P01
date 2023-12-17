//
//  DeviceManagerDemo.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 03.12.23.
//

import Foundation
import Combine
import CoreBluetooth
import SpheroBOLT

extension Device
{
}

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
			.flatMap { device.wake() }
			.flatMap { device.resetYaw() }
			.flatMap { device.resetLocator() }
//			.flatMap { device.getBatteryPercentage() }
//			.flatMap { device.setAllLEDColors(front: Color(0.0, 1.0, 1.0), back: Color(0.2, 0.5, 1.0)) }
//			.flatMap { device.setLEDMatrixCharacter("D", color: Color(0.0, 0.2, 0.1)) }
			.flatMap { device.driveWithHeading(speed: 60, heading: 350, direction: .forward) }
			.delay(for: .seconds(2), scheduler: DispatchQueue.main, options: .none)
			.flatMap { device.driveWithHeading(speed: 0, heading: 0, direction: .forward) }
			.delay(for: .seconds(2), scheduler: DispatchQueue.main, options: .none)
			.flatMap { device.enterSoftSleep() }
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
