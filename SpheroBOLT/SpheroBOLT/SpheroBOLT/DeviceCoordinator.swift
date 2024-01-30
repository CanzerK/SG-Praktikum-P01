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
@objc public protocol DeviceCoordinatorDelegate: NSObjectProtocol {
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
	@objc optional func deviceCoordinatorDidUpdateBluetoothState(_ coordinator: DeviceCoordinator, state: CBManagerState)

	///
	/// @method deviceCoordinatorDidFindDevice
	///
	/// @param coordinator The instance of the coordinator that sent the message.
	/// @param device The device that was found.
	///
	@objc optional func deviceCoordinatorDidFindDevice(_ coordinator: DeviceCoordinator, device: Device)

	///
	/// @method deviceCoordinatorDidDisconnectDevice
	///
	/// @param coordinator The instance of the coordinator that sent the message.
	/// @param device The device that was found.
	///
	@objc optional func deviceCoordinatorDidDisconnectDevice(_ coordinator: DeviceCoordinator, device: Device)
}

@objc public class DeviceCoordinator: NSObject, CBCentralManagerDelegate {
	/// Bluetooth central manager for all connections.
	private var centralManager: CBCentralManager!

	/// All  devices in all different states.
	private var devices = Set<Device>()

	/// Delegate that listens for messages sent by the coordinator.
	@objc public weak var delegate: DeviceCoordinatorDelegate?

	public override init() {
		super.init()

		centralManager = CBCentralManager(delegate: self,
										  queue: DispatchQueue(label: "spherobolt.central-manager", target: .global()))
	}

	@objc public func findDevices() {
		centralManager.scanForPeripherals(withServices: [Constants.serviceUUID], options: nil)
	}

	@objc public func stop() {
		centralManager.stopScan()
	}

	@objc public func connect(toDevice device: Device) {
		// If a device is currently being connected or is already connected then don't do anything.
		if (device.state == .connecting || device.state == .connected) {
			device.failConnection(.alreadyConnected)

			return
		}

		device.connect(toManager: self.centralManager)
	}

	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		// Stop scanning immediately if we have switched to another state other than powered on.
		if (central.state != .poweredOn) {
			centralManager.stopScan()
		}

		delegate?.deviceCoordinatorDidUpdateBluetoothState?(self, state: central.state)
	}

	/// Called when a new device has been found by our manager, which we will broadcast and add to the discovered devices.
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
	{
		let foundDevice = Device(peripheral)
		devices.insert(foundDevice)

		// Notify the delegate we have found a new device.
		delegate?.deviceCoordinatorDidFindDevice?(self, device: foundDevice)
	}

	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		// Move the device to the list of connected devices and remove it from the other pending lists.
		guard let connectedDevice = devices.filter({ $0.isEqual(peripheral) }).first else {
			return
		}

		connectedDevice.completeConnection()
	}

	public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		// Move the device to the list of connected devices and remove it from the other pending lists.
		guard let connectedDevice = devices.first(where: { $0.isEqual(peripheral) }) else {
			return
		}

		connectedDevice.state = .discovered

		delegate?.deviceCoordinatorDidDisconnectDevice?(self, device: connectedDevice)
	}

	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		// Move the device to the list of connected devices and remove it from the other pending lists.
		guard let device = devices.filter({ $0.isEqual(peripheral) }).first else {
			return
		}

		device.state = .discovered

		device.failConnection(.unableToConnect)
	}
}
