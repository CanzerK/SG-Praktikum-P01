//
//  ConnectOperation.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 05.12.23.
//

import Foundation
import CoreBluetooth

/// A connection operation that returns the api characteristics once finished.
final class ConnectOperation: PeripheralOperation<ConnectionProgress>, CBPeripheralDelegate {
	/// Bluetooth characteristic for API calls.
	private var apiCharacteristic: CBCharacteristic?

	/// Bluetooth characteristic for antidos check.
	private var antidosCharacteristic: CBCharacteristic?

	/// Whether or not the descriptor was found and set.
	private var descriptorSet = false

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

	internal func fail(_ error: DeviceError) {
		completion?(.failure(error))

		finish()
	}

	//MARK: CBPeripheralDelegate

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
			if error != nil {
				fail(.unableToWrite)

				return
			}

			// Only after we made sure we got both characteristics we proceed.
			guard let _ = antidosCharacteristic, let apiCharacteristic = apiCharacteristic else {
				fail(.unableToWrite)

				return
			}

			// Receive notification from the peripheral.
			peripheral.setNotifyValue(true, for: apiCharacteristic)
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			fail(.unableToSetNotification)

			return
		}

		guard let apiCharacteristic = apiCharacteristic else {
			fail(.unableToSetNotification)

			return
		}

		completion?(.success(.completed(apiCharacteristic)))

		finish()
	}

	internal func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			fail(.unableToSetNotification)

			return
		}
		
		guard let apiCharacteristic = apiCharacteristic else {
			fail(.unableToSetNotification)

			return
		}

		completion?(.success(.completed(apiCharacteristic)))

		finish()

		// Discover the descriptors, so we can set up our device for reading as well.
		peripheral.discoverDescriptors(for: apiCharacteristic)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
		guard let apiCharacteristic = apiCharacteristic else {
			fail(.unableToWrite)

			return
		}

		completion?(.success(.completed(apiCharacteristic)))

		finish()
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
		if (characteristic.uuid != Constants.apiCharacteristicUUID) {
			return
		}

		guard let descriptors = characteristic.descriptors,
			  let foundDescriptor = descriptors.first(where: { $0.uuid == Constants.clientCharacteristicConfiguration }) else {
			fail(.unableToFindDescriptor)

			return
		}

		peripheral.writeValue(Data([0x01, 0x00]), for: foundDescriptor)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			fail(.unableToWrite)

			return
		}

		for service in services {
			peripheral.discoverCharacteristics([Constants.apiCharacteristicUUID, Constants.antidosCharacteristicUUID], for: service)
		}
	}

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		if error != nil {
			fail(.unableToConnect)

			return
		}

		guard let characteristics = service.characteristics else {
			fail(.unableToConnect)

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
