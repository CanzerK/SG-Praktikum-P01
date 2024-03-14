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

class DeviceManagerDemo: NSObject, DeviceCoordinatorDelegate, DeviceDelegate {
	var deviceCoordinator: DeviceCoordinator!
	var cancellables = Array<AnyCancellable>()

	override init() {
		super.init()

		deviceCoordinator = DeviceCoordinator()
		deviceCoordinator.delegate = self
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
	}

	func deviceDidChangeState(_ device: Device) {
		print("State is now \(device.state).")
	}

	func deviceDidUpdateConnectionState(_ device: Device, state: ConnectionState) {
		switch state {
		case .connected:
			print("Connected to \(device.name!).")

			device.wake()
//				.flatMap { device.resetYaw() }
//				.flatMap { device.resetLocator() }
	//			.flatMap { device.getBatteryPercentage() }
//				.flatMap { device.setAllLEDColors(front: Color(0.0, 1.0, 1.0), back: Color(0.2, 0.5, 1.0)) }
//				.flatMap { device.setPixelColor(Color(0.0, 1.0, 0.0), pixel: Pixel(5, 5)) }
				.flatMap { device.setLEDMatrixCharacter("A", color: Color(0.0, 0.0, 1.0))}
//				.flatMap { device.setLEDMatrixTextScrolling("Text", color: Color(1.0, 0.0, 0.0), speed: 5, rep: true) }
				.flatMap { device.driveWithHeading(speed: 60, heading: 50, direction: .forward) }
				.delay(for: .seconds(5), scheduler: DispatchQueue.main, options: .none)
				.flatMap { device.driveWithHeading(speed: 0, heading: 0, direction: .forward) }
				.delay(for: .seconds(2), scheduler: DispatchQueue.main, options: .none)
				.flatMap { device.enterSoftSleep() }
//				.retry(3)
				.receive(on: DispatchQueue.main)
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
		default:
			print("Connection state changed to \(state).")
		}
	}
}
