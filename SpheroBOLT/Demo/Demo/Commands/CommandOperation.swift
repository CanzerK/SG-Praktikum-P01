//
//  CommandOperation.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 05.12.23.
//

import Foundation
import CoreBluetooth

/// A single command operation that is scheduled onto the command queue.
class CommandOperationBase<R>: PeripheralOperation<R> {
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

		// Set ourselves as the delegate to get the message callbacks and write the value.
		peripheral.writeValue(packet, for: apiCharacteristic, type: .withResponse)
	}
}

final class CommandOperation: CommandOperationBase<Void>, CBPeripheralDelegate {
	override func main() {
		super.main()

		peripheral.delegate = self
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
final class DataCommandOperation<R: DataInitializable>: CommandOperationBase<R>, CBPeripheralDelegate {
	override func main() {
		super.main()

		peripheral.delegate = self
	}

	// MARK: CBPeripheralDelegate

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			completion?(.failure(.unableToWrite))

			finish()

			return
		}

		if (characteristic.uuid == Constants.apiCharacteristicUUID) {
			peripheral.readValue(for: characteristic)
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

