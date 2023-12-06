//
//  QueueOperation.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 04.12.23.
//

import Foundation
import CoreBluetooth

@propertyWrapper
public class Atomic<T> {
	private var _wrappedValue: T
	private var lock = NSLock()

	public var wrappedValue: T {
		get { lock.synchronized { _wrappedValue } }
		set { lock.synchronized { _wrappedValue = newValue } }
	}

	public init(wrappedValue: T) {
		_wrappedValue = wrappedValue
	}
}

extension NSLocking {
	func synchronized<T>(block: () throws -> T) rethrows -> T {
		lock()
		defer { unlock() }
		return try block()
	}
}

private extension SerialOperation {
	/// State for this operation.
	@objc enum OperationState: Int {
		case ready
		case executing
		case finished
	}
}

class SerialOperation: Operation {
	@Atomic @objc private dynamic var state: OperationState = .ready

	// MARK: - Various `Operation` properties

	open override var isReady: Bool {
		state == .ready && super.isReady
	}

	public final override var isExecuting: Bool {
		state == .executing
	}

	public final override var isFinished: Bool {
		state == .finished
	}

	public final override var isAsynchronous: Bool {
		true
	}

	public final override var isConcurrent: Bool {
		return false
	}

	// KVO for dependent properties

	open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
		if [#keyPath(isReady), #keyPath(isFinished), #keyPath(isExecuting)].contains(key) {
			return [#keyPath(state)]
		}

		return super.keyPathsForValuesAffectingValue(forKey: key)
	}

	public final override func start() {
		if isCancelled {
			state = .finished

			return
		}

		state = .executing

		main()
	}

	/// Subclasses must implement this to perform their work and they must not call `super`. The default implementation of this function throws an exception.
	open override func main() {
		fatalError("Subclasses must implement `main`.")
	}

	/// Call this function to finish an operation that is currently executing
	public final func finish() {
		if !isFinished {
			state = .finished
		}
	}
}

/// Base for all peripheral operations.
class PeripheralOperation<R>: SerialOperation {
	internal let packet: Data
	internal let peripheral: CBPeripheral
	internal var completion: ((Result<R, DeviceError>) -> Void)?

	fileprivate var dataWritten = false
	fileprivate var operationCancelled = false

	override var isCancelled: Bool {
		return operationCancelled
	}

	init(_ packet: Data,
		 peripheral: CBPeripheral,
		 completion: ((Result<R, DeviceError>) -> Void)?) {
		self.packet = packet
		self.peripheral = peripheral
		self.completion = completion

		super.init()
	}

	/// Called when the operation has been cancelled.
	override func cancel() {
		super.cancel()

		operationCancelled = true
	}
}

/// A connection operation that returns the api characteristics once finished.
final class ConnectOperation: PeripheralOperation<ConnectionProgress>, CBPeripheralDelegate {
	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic?

	/// Bluetooth characteristic for antidos check.
	private var antidosCharacteristic: CBCharacteristic?

	init(peripheral: CBPeripheral,
		 completion: ((Result<ConnectionProgress, DeviceError>) -> Void)?) {
		super.init(Constants.antidosData,
				   peripheral: peripheral,
				   completion: completion)
	}

	override func main() {
		if (isCancelled) {
			return
		}

		// Set ourselves as the delegate to get the message callbacks and write the value.
		peripheral.delegate = self

		// Discover services with the given UUIDs to be able to write to the characteristics.
		peripheral.discoverServices([Constants.serviceUUID, Constants.initializeServiceUUID])
	}

	//MARK: CBPeripheralDelegate

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
			if error != nil {
				completion?(.failure(.unableToWrite))

				return
			}

			// Only after we made sure we got both characteristics we proceed.
			guard let _ = antidosCharacteristic, let apiCharacteristic = apiCharacteristic else {
				completion?(.failure(.unableToWrite))

				return
			}

			completion?(.success(.completed(apiCharacteristic)))

			finish()
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			completion?(.failure(.unableToWrite))

			finish()

			return
		}

		completion?(.failure(.unableToWrite))

		for service in services {
			peripheral.discoverCharacteristics([Constants.apiCharacteristicUUID, Constants.antidosCharacteristicUUID], for: service)
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		if error != nil {
			completion?(.failure(.unableToConnect))

			finish()

			return
		}

		guard let characteristics = service.characteristics else {
			completion?(.failure(.unableToConnect))

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
	}
}

/// A single command operation that is scheduled onto the command queue.
final class CommandOperation: PeripheralOperation<Void>, CBPeripheralDelegate {
	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic

	init(_ packet: Data,
		 peripheral: CBPeripheral,
		 completion: ((Result<Void, DeviceError>) -> Void)?,
		 apiCharacteristic: CBCharacteristic) {
		self.apiCharacteristic = apiCharacteristic

		super.init(packet, peripheral: peripheral, completion: completion)
	}

	override func main() {
		if (isCancelled) {
			return
		}

		peripheral.delegate = self

		// Set ourselves as the delegate to get the message callbacks and write the value.
		peripheral.writeValue(packet, for: apiCharacteristic, type: .withResponse)
	}

	//MARK: CBPeripheralDelegate

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			completion?(.failure(.unableToWrite))

			finish()

			return
		}

		if (characteristic.uuid == Constants.apiCharacteristicUUID) {
			completion?(.success(()))

			finish()
		}
	}
}

/// A single command operation that is scheduled onto the command queue.
final class DataCommandOperation<R: DataInitializable>: PeripheralOperation<R>, CBPeripheralDelegate {
	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic

	init(_ packet: Data,
		 peripheral: CBPeripheral,
		 completion: ((Result<R, DeviceError>) -> Void)?,
		 apiCharacteristic: CBCharacteristic) {
		self.apiCharacteristic = apiCharacteristic

		super.init(packet, peripheral: peripheral, completion: completion)
	}

	override func main() {
		if (isCancelled) {
			return
		}

		peripheral.delegate = self

		// Set ourselves as the delegate to get the message callbacks and write the value.
		peripheral.writeValue(packet, for: apiCharacteristic, type: .withResponse)
	}

	//MARK: CBPeripheralDelegate

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			completion?(.failure(.unableToWrite))

			finish()

			return
		}

		if (characteristic.uuid == Constants.apiCharacteristicUUID) {
			peripheral.readValue(for: characteristic)

			finish()
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			completion?(.failure(.unableToWrite))

			finish()

			return
		}

		if (characteristic.uuid == Constants.apiCharacteristicUUID) {
			guard let data = characteristic.value else {
				completion?(.failure(.unableToWrite))

				finish()

				return
			}

			guard let value = try? R(fromData: data) else {
				completion?(.failure(.unableToWrite))

				finish()

				return
			}

			completion?(.success(value))

			finish()
		}
	}
}
