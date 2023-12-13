//
//  ConnectOperation.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 05.12.23.
//

import Foundation
import CoreBluetooth

enum DeviceCharacteristics: Int, CaseIterable {
	case api = 0
	case antidos = 1
	case dfuControl = 2
	case dfuInfo = 3
	case subs = 4
}

extension Array {
	subscript<I>(position: I) -> Element where I: RawRepresentable, I.RawValue == Int {
	get {
	  return self[position.rawValue]
	}
	set {
	  self[position.rawValue] = newValue
	}
  }
}

/// A connection operation that returns the api characteristics once finished.
final class ConnectOperation: PeripheralOperation<ConnectionProgress>, CBPeripheralDelegate {
	/// Bluetooth characteristic for API calls.
	private var discoveredCharacteristics = Array<CBCharacteristic?>(repeating: nil, count: DeviceCharacteristics.allCases.count)

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

	internal func complete(_ apiCharacteristic: CBCharacteristic) {
		completion?(.success(.completed(apiCharacteristic)))

		finish()
	}

	internal func fail(_ error: DeviceError) {
		completion?(.failure(error))

		finish()
	}

	//MARK: CBPeripheralDelegate

	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			fail(.unableToWrite)

			return
		}

		for service in services {
			switch service.uuid {
			case Constants.serviceUUID:
				peripheral.discoverCharacteristics([Constants.apiCharacteristicUUID], for: service) 
				break
			case Constants.initializeServiceUUID:
				peripheral.discoverCharacteristics([Constants.antidosCharacteristicUUID,
													Constants.DFUControlCharacteristicUUID,
													Constants.DFUInfoCharacteristicUUID,
													Constants.SubsCharacteristicUUID],
												   for: service)
				break
			default:
				break
			}
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
					discoveredCharacteristics[DeviceCharacteristics.api] = characteristic

					break
				}
			}
		} else if (service.uuid == Constants.initializeServiceUUID) {
			for characteristic in characteristics {
				switch (characteristic.uuid) {
				case Constants.antidosCharacteristicUUID:
					discoveredCharacteristics[DeviceCharacteristics.antidos] = characteristic
					break
				case Constants.DFUControlCharacteristicUUID:
					discoveredCharacteristics[DeviceCharacteristics.dfuControl] = characteristic
					break
				case Constants.DFUInfoCharacteristicUUID:
					discoveredCharacteristics[DeviceCharacteristics.dfuInfo] = characteristic
					break
				case Constants.SubsCharacteristicUUID:
					discoveredCharacteristics[DeviceCharacteristics.subs] = characteristic
					break
				default:
					break
				}
			}
		}

		// Only after we made sure we got all characteristics we proceed.
		if discoveredCharacteristics.contains(nil) {
			return
		}

		guard let antidosCharacteristic = discoveredCharacteristics[DeviceCharacteristics.antidos] else {
			return
		}

		// Send the andidos protection data to the robot.
		peripheral.writeValue(packet, for: antidosCharacteristic, type: .withResponse)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if (characteristic.uuid == Constants.antidosCharacteristicUUID) {
			if error != nil {
				fail(.unableToWrite)

				return
			}

			// Receive notification from the peripheral.
			guard let apiCharacteristic = discoveredCharacteristics[DeviceCharacteristics.api] else {
				fail(.unableToSetNotification)

				return
			}

			peripheral.setNotifyValue(true, for: apiCharacteristic)
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			fail(.unableToSetNotification)

			return
		}

		complete(characteristic)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		if error != nil {
			fail(.unableToSetNotification)

			return
		}
		
		guard let apiCharacteristic = discoveredCharacteristics[DeviceCharacteristics.api] else {
			fail(.unableToSetNotification)

			return
		}

		complete(apiCharacteristic)

		// Discover the descriptors, so we can set up our device for reading as well.
//		peripheral.discoverDescriptors(for: apiCharacteristic)
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

		peripheral.writeValue(Data([0x00, 0x01]), for: foundDescriptor)
	}

	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
		guard let apiCharacteristic = discoveredCharacteristics[DeviceCharacteristics.api] else {
			fail(.unableToWrite)

			return
		}

		complete(apiCharacteristic)
	}
}
