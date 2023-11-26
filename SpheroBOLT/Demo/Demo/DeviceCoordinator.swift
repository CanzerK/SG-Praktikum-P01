//
//  SpheroManager.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 10.11.23.
//

import Foundation
import CoreBluetooth
import Combine

enum DeviceCoordinatorError: Error {
	case deviceAlreadyConnected
	case deviceUnableToConnect
}

///
/// @protocol DeviceCoordinatorDelegate
///
/// @discussion Provides functionality to find which devices have been discovered and when we are connected to them.
protocol DeviceCoordinatorDelegate {
	///
	/// @method deviceCoordinatorDidFindDevice
	///
	/// @param coordinator The instance of the coordinator that sent the message.
	/// @param device The device that was found.
	///
	func deviceCoordinatorDidFindDevice(coordinator: DeviceCoordinator, device: Device)
}

class DeviceCoordinator: NSObject, CBCentralManagerDelegate {
	typealias DeviceFuture = Future<Device, DeviceCoordinatorError>

	/// Bluetooth central manager for all connections.
	private var centralManager: CBCentralManager!

	/// All currently connected devices.
	private var connectedDevices = Set<Device>()

	/// All devices that we have discovered so far.
	private var discoveredDevices = Set<Device>()

	/// All devices that we are currently establishing connection with.
	private var connectingDevices = Set<Device>()

	/// The current promise for a request to discover all devices.
	private var findSubject: PassthroughSubject<Device, DeviceCoordinatorError>?

	/// Future for when the state has been updated.
	private var stateSubject = PassthroughSubject<CBManagerState, Never>()

	/// Delegate that listens for messages sent by the coordinator.
	var delegate: DeviceCoordinatorDelegate?

	var state: AnyPublisher<CBManagerState, Never> {
		return stateSubject.eraseToAnyPublisher()
	}

	public override init() {
		super.init()

		centralManager = CBCentralManager(delegate: self, queue: nil)
	}

	public func findDevices() -> AnyPublisher<Device, DeviceCoordinatorError> {
		findSubject = PassthroughSubject<Device, DeviceCoordinatorError>()

		centralManager.scanForPeripherals(withServices: [Constants.serviceUUID], options: nil)

		return findSubject!.eraseToAnyPublisher()
	}

	public func stop() {
		centralManager.stopScan()
		findSubject = nil
	}

	public func connect(toDevice device: Device) -> Result<Void, DeviceCoordinatorError> {
		// If a device is currently being connected or is already connected then don't do anything.
		if (connectedDevices.contains(device) || connectingDevices.contains(device)) {
			return .failure(.deviceAlreadyConnected)
		}

		device.connect(toManager: centralManager)

		connectingDevices.insert(device)

		return .success(())
	}

	internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
		stateSubject.send(central.state)
	}

	internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
	{
		let foundDevice = Device(peripheral)

		findSubject?.send(foundDevice)

		// Notify the delegate we have found a new device.
		delegate?.deviceCoordinatorDidFindDevice(coordinator: self, device: foundDevice)
	}

	internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		let newDevice = Device(peripheral)

		// Move the device to the list of connected devices and remove it from the other pending lists.
		connectedDevices.insert(newDevice)

//		connectingDevices.filter { $0. == peripheral }.first
	}

	internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {

	}

	internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		
	}
}
