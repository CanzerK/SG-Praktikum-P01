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
	case unableToFindDescriptor
	case unableToSetNotification
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

	func enqueue(command: Command, completion: ((Result<Void, DeviceError>) -> Void)?) {
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

	func enqueueWithData<R: DataInitializable>(command: Command, completion: ((Result<R, DeviceError>) -> Void)?) {
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
}
