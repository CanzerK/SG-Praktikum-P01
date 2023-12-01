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
}

class DeviceCoordinator: NSObject, CBCentralManagerDelegate {
	/// Bluetooth central manager for all connections.
	private var centralManager: CBCentralManager!

	/// All  devices in all different states.
	private var devices = Set<Device>()

	/// Delegate that listens for messages sent by the coordinator.
	var delegate: DeviceCoordinatorDelegate?

	/// Connection established from the central manager subject.
	private var didDiscoverPeripheralSubject = PassthroughSubject<Device, Never>()

	/// Connection established from the central manager publisher.
	private var didDiscoverPeripheralPublisher: AnyPublisher<Device, Never>

	/// Connection established from the central manager cancellable.
	private var didDiscoverSubjectCancellable = Set<AnyCancellable>()

	/// Connection established from the central manager subject.
	private var didConnectPeripheralSubject = PassthroughSubject<Device, DeviceError>()

	/// Connection established from the central manager publisher.
	private var didConnectPeripheralPublisher: AnyPublisher<Device, DeviceError>

	/// Connection established from the central manager cancellable.
	private var didConnectSubjectCancellable = Set<AnyCancellable>()

	/// Connection established from the central manager subject.
	private var didFailToConnectPeripheralSubject = PassthroughSubject<Device, DeviceError>()

	/// Connection established from the central manager publisher.
	private var didFailToConnectPeripheralPublisher: AnyPublisher<Device, DeviceError>

	/// Connection established from the central manager cancellable.
	private var didFailToConnectSubjectCancellable = Set<AnyCancellable>()

	public init(_ delegate: DeviceCoordinatorDelegate?) {
		self.didDiscoverPeripheralPublisher = didDiscoverPeripheralSubject.eraseToAnyPublisher()

		super.init()

		self.delegate = delegate

		centralManager = CBCentralManager(delegate: self,
										  queue: DispatchQueue(label: "spherobolt.central-manager", target: .global()))
	}

	public func findDevices() -> AnyPublisher<Device, Never> {
		return didDiscoverPeripheralPublisher
			.handleEvents(receiveSubscription: { _ in
				self.centralManager.scanForPeripherals(withServices: [Constants.serviceUUID], options: nil)
			}, receiveCancel: {
				self.centralManager.stopScan()
			})
			.shareCurrentValue()
			.eraseToAnyPublisher()
	}

	public func stop() {
		centralManager.stopScan()
	}

	public func connect(toDevice device: Device) -> AnyPublisher<ConnectionState, DeviceError> {
		// If a device is currently being connected or is already connected then don't do anything.
		if (device.state == .connecting || device.state == .connected) {
			let subject = PassthroughSubject<ConnectionState, DeviceError>()
			subject.send(completion: .failure(.alreadyConnected))

			return subject.eraseToAnyPublisher()
		}

		Publishers.Merge(
			didConnectPeripheralPublisher!
				.filter { $0 == device }
				.setFailureType(to: DeviceError.self),
			didFailToConnectPeripheralPublisher!
				.fil
		)

//		return didConnectPeripheralPublisher
//			.map { device in
//				guard let strongSelf = self else { return }
//
//				device.connect(toManager: strongSelf.centralManager)
//			}.eraseToAnyPublisher()
//
//		return didConnectPeripheralPublisher
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
		didDiscoverPeripheralSubject.send(foundDevice)
	}

	internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		// Move the device to the list of connected devices and remove it from the other pending lists.
		guard let connectedDevice = devices.filter({ $0.isEqual(peripheral) }).first else {
			return
		}

//		didConnectPeripheralSubject.send(connectedDevice)
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
		guard let device = devices.filter({ $0.isEqual(peripheral) }).first else {
			return
		}

		device.state = .discovered

//		didConnectPeripheralSubject.send(completion: .failure(.unableToConnect))
	}
}
