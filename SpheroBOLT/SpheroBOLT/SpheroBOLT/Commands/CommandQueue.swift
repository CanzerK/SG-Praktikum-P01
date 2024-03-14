//
//  CommandQueue.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 23.11.23.
//

import Foundation
import CoreBluetooth
import Combine

/// A device error specific to the queue request type.
@objc public enum DeviceError: Int, Error {
	case unableToConnect
	case unableToDisconnect
	case notConnected
	case alreadyConnected
	case unableToWrite
	case unableToFindDescriptor
	case unableToSetNotification
}

/// The connection state during a device connection.
@objc public enum ConnectionState: Int {
	case connecting
	case connected
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

	func enqueueDelay(_ duration: Float, completion: ((Result<Void, DeviceError>) -> Void)?) {
		guard let apiCharacteristic = apiCharacteristic else {
			completion?(.failure(.notConnected))

			return
		}

		let operation = DelayOperation(duration,
									   completion: { result in
			completion?(result)
		})

		operationQueue.addOperation(operation)
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

	func connect(_ device: Device, completion: ((Result<CBCharacteristic, DeviceError>) -> Void)?) {
		let operation = ConnectOperation(peripheral: peripheral,
										 completion: { [weak self] result in
			guard let self = self else {
				return
			}

			switch result {
			case .success(let characteristic): self.apiCharacteristic = characteristic
			case .failure(_): break
			}

			completion?(result)
		})

		operationQueue.addOperation(operation)
	}
}
