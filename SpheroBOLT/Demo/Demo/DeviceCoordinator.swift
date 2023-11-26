//
//  SpheroManager.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 10.11.23.
//

import Foundation
import CoreBluetooth
import Combine

///
/// @protocol DeviceCoordinatorDelegate
///
/// @discussion Provides functionality to find which devices have been discovered and when we are connected to them.
protocol DeviceCoordinatorDelegate {
	///
	/// @method deviceCoordinatorDidUpdateBluetoothState:
	///
	/// @param coordinator  The device coordinator whose state has changed.
	///
	//// @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
	/// <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
	///                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
	///                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
	///                  manager become invalid and must be retrieved or discovered again.
	///
	mutating func deviceCoordinatorDidUpdateBluetoothState(_ coordinator: DeviceCoordinator, state: CBManagerState)

	///
	/// @method deviceCoordinatorDidFindDevice
	///
	/// @param coordinator The instance of the coordinator that sent the message.
	/// @param device The device that was found.
	///
	mutating func deviceCoordinatorDidFindDevice(_ coordinator: DeviceCoordinator, device: Device)
}

class DeviceCoordinator: NSObject, CBCentralManagerDelegate {
	/// Bluetooth central manager for all connections.
	private var centralManager: CBCentralManager!

	/// All  devices in all different states.
	private var devices = Set<Device>()

	/// Delegate that listens for messages sent by the coordinator.
	var delegate: DeviceCoordinatorDelegate?

	public init(_ delegate: DeviceCoordinatorDelegate?) {
		super.init()

		self.delegate = delegate

		centralManager = CBCentralManager(delegate: self, queue: nil)
	}

	public func findDevices() {
		centralManager.scanForPeripherals(withServices: [Constants.serviceUUID], options: nil)
	}

	public func stop() {
		centralManager.stopScan()
	}

	public func connect(toDevice device: Device) -> PassthroughSubject<ConnectionState, DeviceError> {
		// If a device is currently being connected or is already connected then don't do anything.
		if (device.state == .connecting || device.state == .connected) {
			let subject = PassthroughSubject<ConnectionState, DeviceError>()
			subject.send(completion: .failure(.alreadyConnected))

			return subject
		}

		// When we exit the scope we will broadcast a single connection state change.
//		connectionSubject?.send(.connecting)

		// This will put the device in the correct state also.
		return device.connect(toManager: centralManager)
	}

	internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
		// Stop scanning immediately if we have switched to another state other than powered on.
		if (central.state != .poweredOn) {
			centralManager.stopScan()
		}

		delegate?.deviceCoordinatorDidUpdateBluetoothState(self, state: central.state)
	}

	/// Called when a new device has been found by our manager, which we will broadcast and add to the discovered devices.
	internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
	{
		let foundDevice = Device(peripheral)
		devices.insert(foundDevice)

		// Notify the delegate we have found a new device.
		delegate?.deviceCoordinatorDidFindDevice(self, device: foundDevice)
	}

	internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		// Move the device to the list of connected devices and remove it from the other pending lists.
		if (!devices.contains(where: { $0.isEqual(peripheral) })) {
			return
		}

		peripheral.discoverServices([Constants.serviceUUID, Constants.initializeServiceUUID])
	}

	internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		// Move the device to the list of connected devices and remove it from the other pending lists.
		guard let connectedDevice = devices.first(where: { $0.isEqual(peripheral) }) else {
			return
		}

		connectedDevice.state = .discovered
	}

	internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		// Move the device to the list of connected devices and remove it from the other pending lists.
		guard let connectedDevice = devices.first(where: { $0.isEqual(peripheral) }) else {
			return
		}

		connectedDevice.state = .discovered
	}
}
