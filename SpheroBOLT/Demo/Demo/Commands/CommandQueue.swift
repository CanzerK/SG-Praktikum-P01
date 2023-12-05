//
//  Queue.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 23.11.23.
//

import Foundation
import CoreBluetooth
import Combine

/// A device error specific to the queue request type.
enum DeviceError: Error {
	case unableToConnect
	case unableToDisconnect
	case notConnected
	case alreadyConnected
	case unableToWrite
}

/// The connection state during a device connection.
enum ConnectionState {
	case connecting
	case interrogating
	case acknowledging
	case connected
}

enum ConnectionProgress {
	case updated(_ state: ConnectionState)
	case completed(_ apiCharacteristic: CBCharacteristic)
}

//<R: DataInitializable>

class CommandQueue {
	private let operationQueue = OperationQueue()

	/// Underlying bluetooth peripheral instance.
	private var peripheral: CBPeripheral!

	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic?

	init(_ peripheral: CBPeripheral) {
		self.peripheral = peripheral

		self.operationQueue.maxConcurrentOperationCount = 1
		self.operationQueue.qualityOfService = .default
		self.operationQueue.name = "CommandQueue"
	}

	func enqueue<R>(_ command: Command, completion: ((Result<R, DeviceError>) -> Void)?) {
		guard let apiCharacteristic = apiCharacteristic else {
			completion?(.failure(.notConnected))

			return
		}

		let operation = CommandOperation(command.packet,
										 peripheral: peripheral,
										 completion: { result in
			completion?(result)
		},
										 apiCharacteristic: apiCharacteristic)

		operationQueue.addOperation(operation)
	}

	func enqueue<R: DataInitializable>(_ command: Command, completion: ((Result<R, DeviceError>) -> Void)?) {
		guard let apiCharacteristic = apiCharacteristic else {
			completion?(.failure(.notConnected))

			return
		}

		let operation = DataCommandOperation(command.packet,
											 peripheral: peripheral,
											 completion: { result in
			completion?(result)
		},
										 apiCharacteristic: apiCharacteristic)

		operationQueue.addOperation(operation)
	}

	func cancelAll() {
		operationQueue.cancelAllOperations()
	}

	func connect(_ device: Device, completion: ((Result<ConnectionProgress, DeviceError>) -> Void)?) {
		let operation = ConnectOperation(peripheral: peripheral,
										 completion: { [weak self] result in
			guard let self = self else {
				return
			}

			switch result {
			case .success(let progress):
				switch progress {
				case .completed(let characteristic):
					self.apiCharacteristic = characteristic
				case .updated(_): break
				}
			case .failure(_): break
			}

			completion?(result)
		})

		operationQueue.addOperation(operation)
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
