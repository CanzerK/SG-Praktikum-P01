//
//  DeviceManagerDemo.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 03.12.23.
//

import Foundation
import Combine
import CoreBluetooth
import CoreGraphics
//import SpheroBOLT

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
			device.resetYaw()
			device.resetLocator()
			device.setAllLEDColors(front: CGColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), back: CGColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0))
			device.setLEDMatrixTextScrolling("Text", color: CGColor(red: 0.5, green: 0.4, blue: 0.0, alpha: 1.0), speed: 5, rep: true)

			device.driveWithHeading(speed: 60, heading: 50, direction: .forward)
			device.enqueueDelayCommand(2.5)
			device.driveWithHeading(speed: 0, heading: 0, direction: .forward)

			device.enterSoftSleep()
		default:
			print("Connection state changed to \(state).")
		}
	}
}
