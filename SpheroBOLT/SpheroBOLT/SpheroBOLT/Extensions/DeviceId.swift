//
//  DeviceId.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 26.11.23.
//

import Foundation

enum DeviceId: UInt8 {
	case apiProcessor = 0x10
	case systemInfo = 0x11
	case systemModes = 0x12
	case power = 0x13
	case driving = 0x16
	case animatronics = 0x17
	case sensors = 0x18
	case peerConnection = 0x19
	case userIO = 0x1a
	case storageCommand = 0x1b
	case secondaryMCUFirmwareUpdateCommand = 0x1d
	case wifiCommand = 0x1e
	case factoryTest = 0x1f
	case macroSystem = 0x20
	case proto = 0xfe
}
