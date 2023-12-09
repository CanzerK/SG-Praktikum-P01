//
//  Constants.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 10.11.23.
//

import Foundation
import CoreBluetooth

struct Constants {
	/// Main service UUID of all Sphero BOLT devices.
	static let serviceUUID = CBUUID(string: "00010001-574f-4f20-5370-6865726f2121")

	/// Initialization service UUID of all Sphero BOLT devices.
	static let initializeServiceUUID = CBUUID(string: "00020001-574f-4f20-5370-6865726f2121")
	
	/// Characteristic UUID for all API calls.
	static let apiCharacteristicUUID = CBUUID(string: "00010002-574f-4f20-5370-6865726f2121")

	/// Characteristic UUID for the antidos protection.
	static let antidosCharacteristicUUID = CBUUID(string: "00020005-574f-4f20-5370-6865726f2121")
	
	/// Required configuration to read data from the Sphero device.
	static let clientCharacteristicConfiguration = CBUUID(data: Data([0x29, 0x02]))

	/// Sphero BOLT name.
	static let spheroName = "Sphero Bolt"

	/// Sphero BOLT name prefix.
	static let spheroNamePrefix = "SB-"

	/// Hex representation of 'usetheforce...band' required for authentication before issuing any commands.
	static let antidosData = Data([0x75, 0x73, 0x65, 0x74, 0x68, 0x65, 0x66, 0x6f, 0x72, 0x63, 0x65, 0x2e, 0x2e, 0x2e, 0x62, 0x61, 0x6e, 0x64])
}
