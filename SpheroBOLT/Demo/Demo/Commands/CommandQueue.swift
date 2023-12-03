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

/// Base for all peripheral operations.
class PeripheralOperation<R>: Operation, CBPeripheralDelegate {
	internal let packet: Data
	internal let peripheral: CBPeripheral
	internal var writeSubject: PassthroughSubject<R, DeviceError>
	internal var writePublisher: AnyPublisher<R, DeviceError>
	internal var subjectCancellable = Set<AnyCancellable>()
	internal var dataWritten = false
	internal var subjectCancelled = false

	override var isAsynchronous: Bool {
		return true
	}

	override var isConcurrent: Bool {
		return false
	}

	override var isFinished: Bool {
		return dataWritten
	}

	override var isCancelled: Bool {
		return subjectCancelled
	}

	init(_ packet: Data,
		 peripheral: CBPeripheral,
		 writeSubject: PassthroughSubject<R, DeviceError>,
		 writePublisher: AnyPublisher<R, DeviceError>) {
		self.packet = packet
		self.peripheral = peripheral
		self.writeSubject = writeSubject
		self.writePublisher = writePublisher

		super.init()

		writePublisher.sink { [weak self] completion in
			print("Successfully written value.")

			self?.dataWritten = true
		} receiveValue: { value in

		}.store(in: &subjectCancellable)
	}

	/// Executed as soon as the operation can be started.
	override func main() {
		guard isCancelled else {
			return
		}

		// Set ourselves as the delegate to get the message callbacks and write the value.
		peripheral.delegate = self
	}

	/// Called when the operation has been cancelled.
	override func cancel() {
		super.cancel()

		subjectCancellable.first?.cancel()
		subjectCancelled = true
	}
}

/// A connection operation that returns the api characteristics once finished.
final class ConnectOperation: PeripheralOperation<ConnectionProgress> {
	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic?

	/// Bluetooth characteristic for antidos check.
	private var antidosCharacteristic: CBCharacteristic?

	init(peripheral: CBPeripheral,
		 writeSubject: PassthroughSubject<ConnectionProgress, DeviceError>,
		 writePublisher: AnyPublisher<ConnectionProgress, DeviceError>) {
		super.init(Constants.antidosData,
				   peripheral: peripheral,
				   writeSubject: writeSubject,
				   writePublisher: writePublisher)

		peripheral.discoverServices([Constants.serviceUUID, Constants.initializeServiceUUID])
	}

	//MARK: CBPeripheralDelegate

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
			if error != nil {
				writeSubject.send(completion: .failure(.unableToConnect))

				return
			}

			// Only after we made sure we got both characteristics we proceed.
			guard let _ = antidosCharacteristic, let apiCharacteristic = apiCharacteristic else {
				writeSubject.send(completion: .failure(.unableToConnect))

				return
			}

			writeSubject.send(.updated(.connected))
			writeSubject.send(.completed(apiCharacteristic))

			writeSubject.send(completion: .finished)
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			writeSubject.send(completion: .failure(.unableToConnect))

			return
		}

		writeSubject.send(.updated(.interrogating))

		for service in services {
			peripheral.discoverCharacteristics([Constants.apiCharacteristicUUID, Constants.antidosCharacteristicUUID], for: service)
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		if error != nil {
			writeSubject.send(completion: .failure(.unableToConnect))

			return
		}

		guard let characteristics = service.characteristics else {
			writeSubject.send(completion: .failure(.unableToConnect))

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
		peripheral.writeValue(packet, for: antidosCharacteristic, type: .withResponse)

		// Mark the connection state as acknowledging and continue to full connection.
		writeSubject.send(.updated(.acknowledging))
	}
}

/// A single command operation that is scheduled onto the command queue.
final class CommandOperation<R>: PeripheralOperation<R> {
	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic

	init(_ packet: Data,
		 peripheral: CBPeripheral,
		 writeSubject: PassthroughSubject<R, DeviceError>,
		 writePublisher: AnyPublisher<R, DeviceError>,
		 apiCharacteristic: CBCharacteristic) {
		self.apiCharacteristic = apiCharacteristic

		super.init(packet, peripheral: peripheral, writeSubject: writeSubject, writePublisher: writePublisher)
	}

	override func main() {
		guard isCancelled else {
			return
		}

		// Set ourselves as the delegate to get the message callbacks and write the value.
		peripheral.writeValue(packet, for: apiCharacteristic, type: .withResponse)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if (characteristic.uuid == Constants.apiCharacteristicUUID) {
			writeSubject.send(completion: .finished)
		} else {
			writeSubject.send(completion: .failure(.unableToWrite))
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("Unhandled Characteristic UUID: \(characteristic.uuid)")
	}
}

class CommandQueue: NSObject {
	private let operationQueue = OperationQueue()

	/// Underlying bluetooth peripheral instance.
	private var peripheral: CBPeripheral!

	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic?

	/// All cancellable subjects.
	private var subjectCancellables = Set<AnyCancellable>()

	init(_ peripheral: CBPeripheral) {
		self.peripheral = peripheral

		self.operationQueue.maxConcurrentOperationCount = 1
		self.operationQueue.qualityOfService = .default
		self.operationQueue.name = "CommandQueue"

		super.init()
	}

	func enqueue<R>(_ command: Command) -> AnyPublisher<R, DeviceError> {
		let subject = PassthroughSubject<R, DeviceError>()

		guard let apiCharacteristic = apiCharacteristic else {
			return subject.eraseToAnyPublisher()
		}

		let publisher = subject.eraseToAnyPublisher()
		let operation = CommandOperation(command.packet,
										 peripheral: peripheral,
										 writeSubject: subject,
										 writePublisher: publisher,
										 apiCharacteristic: apiCharacteristic)

		operationQueue.addOperation(operation)

		return publisher
	}

	func cancelAll() {
		for cancellable in subjectCancellables {
			cancellable.cancel()
		}

		subjectCancellables.removeAll()

		operationQueue.cancelAllOperations()
	}

	func connect() -> AnyPublisher<ConnectionProgress, DeviceError> {
		let subject = PassthroughSubject<ConnectionProgress, DeviceError>()
		let publisher = subject.eraseToAnyPublisher()

		let operation = ConnectOperation(peripheral: peripheral,
										 writeSubject: subject,
										 writePublisher: publisher)

		publisher
			.timeout(.seconds(30), scheduler: DispatchQueue.main, options: nil, customError:nil)
			.sink { _ in

			} receiveValue: { [weak self] progress in
				switch progress {
				case .completed(let characteristic):
					self?.apiCharacteristic = characteristic
				default: break
				}
			}
			.store(in: &subjectCancellables)

		operationQueue.addOperation(operation)

		return publisher
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
