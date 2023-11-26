//
//  SpheroDevice.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation
import CoreBluetooth

class Device: NSObject, CBPeripheralDelegate {
	/// Underlying bluetooth peripheral instance.
	private var peripheral: CBPeripheral!

	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic?

	/// Bluetooth characteristic for antidos check.
	private var antidosCharacteristic: CBCharacteristic?

	/// Command buffer to enqueue all device commands into.
	private var commandQueue = CommandQueue()

	/// Current sequence number of the command.
	private var sequenceNumber: UInt8 = 0

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
		guard let otherDevice = object as? Device else {
			return false
		}

		return peripheral == otherDevice.peripheral
	}

	func connect(toManager manager: CBCentralManager) {
		manager.connect(peripheral)

		peripheral.discoverServices([Constants.serviceUUID, Constants.initializeServiceUUID])
	}

	func disconnect(fromManager manager: CBCentralManager) {
		commandQueue.empty()

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

	internal func enqueueCommand(deviceId: DeviceId, commandId: CommandId, contents: [UInt8], sourceId: UInt8?, targetId: UInt8?) {
		var flags: PacketFlags = [.requestsResponse, .resetsInactivityTimeout]

		if (sourceId != nil) {
			flags.insert(PacketFlags.commandHasSourceId)
		}

		if (targetId != nil) {
			flags.insert(PacketFlags.commandHasTargetId)
		}

		let command = Command(flags, deviceId: deviceId, commandId: commandId, sequenceNumber: nextSequenceNumber, contents: contents, sourceId: sourceId, targetId: targetId)

		commandQueue.enqueue(command)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {

	}

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if let error = error {
			print(error.localizedDescription)
		}
		else {
			print("Successfully wrote to \(peripheral).")

			if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
				guard let apiCharacteristic = apiCharacteristic else {
					return
				}

				let start: UInt8 = 0x8d
				let end: UInt8 = 0xd8
				let response: UInt8 = 0x0a
//				let sourceId: UInt8 = 0xff
//				let targetId: UInt8 = 0x11
				let deviceId: UInt8 = 0x13
				let commandId : UInt8 = 0x0d
	//			let led: UInt8 = LED.all()
	//			let r: UInt8 = 0xff
	//			let g: UInt8 = 0x00
	//			let b: UInt8 = 0x00
	//			let a: UInt8 = 0x00
				let seqNum: UInt8 = (1) % 255
				let sum = response + deviceId + commandId + seqNum
				let checksum: UInt8 = (~sum) & 0xff

				let bytes: [UInt8] = [start, response, deviceId, commandId, seqNum, checksum, end]
				let data = Data(bytes)

				peripheral.writeValue(data, for: apiCharacteristic, type: .withResponse)
			}
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else { return }

		for service in services {
			peripheral.discoverCharacteristics([Constants.apiCharacteristicUUID, Constants.antidosCharacteristicUUID], for: service)
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let characteristics = service.characteristics else { return }

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

		guard let characteristic = antidosCharacteristic else {
			print("Unable to get antidos characteristic.")

			return
		}

		peripheral.writeValue(Data(Constants.antidosData), for: characteristic, type: .withResponse)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("characteristic: \(characteristic)")

		switch characteristic.uuid {
		default:
			print("Unhandled Characteristic UUID: \(characteristic.uuid)")
		}
	}
}
