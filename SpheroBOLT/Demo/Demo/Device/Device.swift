//
//  SpheroDevice.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation
import Combine
import CoreBluetooth

enum DeviceError: Error {
	case unableToConnect
	case alreadyConnected
}

enum ConnectionState {
	case connecting
	case interrogating
	case acknowledging
	case connected
}

enum DeviceState {
	case discovered
	case connecting
	case connected
}

protocol DeviceDelegate {
	/**
	 * @discussion Called when the device changes its state.
	 *
	 * @parameter The device instance.
	 */
	func deviceDidChangeState(_ device: Device)
}

class Device: NSObject, CBPeripheralDelegate {
	/// Underlying bluetooth peripheral instance.
	private var peripheral: CBPeripheral!

	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic?

	/// Bluetooth characteristic for antidos check.
	private var antidosCharacteristic: CBCharacteristic?

	/// Command buffer to enqueue all device commands into.
	private var commandQueue: CommandQueue?

	/// Current sequence number of the command.
	private var sequenceNumber: UInt8 = 0

	/// Broadcasts events during the connection process.
	private var connectionSubject: PassthroughSubject<ConnectionState, DeviceError>?

	/// The delegate of the device instance that will receive messages of changes.
	var delegate: DeviceDelegate?

	/// The current state of the device depends on what the coordinator does with it and is based on the connection to it.
	var state = DeviceState.discovered {
		didSet {
			delegate?.deviceDidChangeState(self)
		}
	}

	/// Representative name of the device.
	var name: String? {
		return peripheral.name
	}

	override var hash: Int {
		return peripheral.hash
	}

	init(_ peripheral: CBPeripheral) {
		super.init()

		self.peripheral = peripheral
		self.peripheral.delegate = self
	}

	override func isEqual(_ object: Any?) -> Bool {
		if let otherDevice = object as? Device {
			return peripheral == otherDevice.peripheral
		} else if let otherPeripheral = object as? CBPeripheral {
			return peripheral == otherPeripheral
		} else {
			return false
		}
	}

	/// Connect to the given device using the manager. Don't call directly!
	func connect(toManager manager: CBCentralManager) -> PassthroughSubject<ConnectionState, DeviceError> {
		state = .connecting

		connectionSubject = PassthroughSubject<ConnectionState, DeviceError>()

		manager.connect(peripheral)

		return connectionSubject!
	}

	/// Disconnect from the given device using the manager. Don't call directly!
	func disconnect(fromManager manager: CBCentralManager) {
		commandQueue?.cancelAll()
		connectionSubject = nil

		manager.cancelPeripheralConnection(peripheral)
	}

	/// Returns the sequence number of the next packet.
	private var nextSequenceNumber: UInt8 {
		get {
			let nextSequenceNumber = (sequenceNumber + 1) % 255
			sequenceNumber += 1

			return nextSequenceNumber
		}
	}

	internal func enqueueCommand<T: CommandRepresentable>(deviceId: DeviceId, commandId: T, sourceId: UInt8? = nil, targetId: UInt8? = nil) {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue, deviceId: deviceId.rawValue, commandId: commandId.rawValue, sequenceNumber: nextSequenceNumber, contents: nil, sourceId: sourceId, targetId: targetId)

		commandQueue?.enqueue(command)
	}

	internal func enqueueCommand<T: CommandRepresentable, D: CommandDataConvertible>(deviceId: DeviceId, commandId: T, data: D?, sourceId: UInt8? = nil, targetId: UInt8? = nil) {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags.rawValue, deviceId: deviceId.rawValue, commandId: commandId.rawValue, sequenceNumber: nextSequenceNumber, contents: data?.packet, sourceId: sourceId, targetId: targetId)

		commandQueue?.enqueue(command)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {

	}

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
			if error != nil {
				connectionSubject?.send(completion: .failure(.unableToConnect))

				return
			}

			// At this point we know we have successfully passed the antidos protection and we are connected to the central manager.
			state = .connected

			connectionSubject?.send(.connected)
			connectionSubject?.send(completion: .finished)

			commandQueue = CommandQueue(peripheral, apiCharacteristic: apiCharacteristic!)
		}

//		if let error = error {
//			print(error.localizedDescription)
//		}
//		else {
//			print("Successfully wrote to \(peripheral).")
//
//			if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
//				guard let apiCharacteristic = apiCharacteristic else {
//					return
//				}
//
//				let start: UInt8 = 0x8d
//				let end: UInt8 = 0xd8
//				let response: UInt8 = 0x0a
////				let sourceId: UInt8 = 0xff
////				let targetId: UInt8 = 0x11
//				let deviceId: UInt8 = 0x13
//				let commandId : UInt8 = 0x0d
//	//			let led: UInt8 = LED.all()
//	//			let r: UInt8 = 0xff
//	//			let g: UInt8 = 0x00
//	//			let b: UInt8 = 0x00
//	//			let a: UInt8 = 0x00
//				let seqNum: UInt8 = (1) % 255
//				let sum = response + deviceId + commandId + seqNum
//				let checksum: UInt8 = (~sum) & 0xff
//
//				let bytes: [UInt8] = [start, response, deviceId, commandId, seqNum, checksum, end]
//				let data = Data(bytes)
//
//				peripheral.writeValue(data, for: apiCharacteristic, type: .withResponse)
//			}
//		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			connectionSubject?.send(completion: .failure(.unableToConnect))

			return
		}

		connectionSubject?.send(.interrogating)

		for service in services {
			peripheral.discoverCharacteristics([Constants.apiCharacteristicUUID, Constants.antidosCharacteristicUUID], for: service)
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		if error != nil {
			connectionSubject?.send(completion: .failure(.unableToConnect))

			return
		}

		guard let characteristics = service.characteristics else {
			connectionSubject?.send(completion: .failure(.unableToConnect))

			return
		}

		if (service.uuid == Constants.serviceUUID) {
			for characteristic in characteristics {
				if (characteristic.uuid == Constants.apiCharacteristicUUID) {
					apiCharacteristic = characteristic

					break
				}
			}
		} else if (service.uuid == Constants.initializeServiceUUID) {
			for characteristic in characteristics {
				if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
					antidosCharacteristic = characteristic

					break
				}
			}
		}

		// Only after we made sure we got both characteristics we proceed.
		guard let antidosCharacteristic = antidosCharacteristic, let _ = apiCharacteristic else {
			return
		}

		// Send the andidos protection data to the robot.
		peripheral.writeValue(Data(Constants.antidosData), for: antidosCharacteristic, type: .withResponse)

		// Mark the connection state as acknowledging and continue to full connection.
		connectionSubject?.send(.acknowledging)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("characteristic: \(characteristic)")

		switch characteristic.uuid {
		default:
			print("Unhandled Characteristic UUID: \(characteristic.uuid)")
		}
	}
}
