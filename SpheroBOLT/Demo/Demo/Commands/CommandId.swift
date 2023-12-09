//
//  Command.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation

enum CommandResult: UInt8 {
	case success = 0x00
	case badDeviceId = 0x01
	case badCommandId = 0x02
	case notYetImplemented = 0x03
	case commandIsRestricted = 0x04
	case badDataLength = 0x05
	case commandFailed = 0x06
	case badParameterValue = 0x07
	case busy = 0x08
	case badTargetId = 0x09
	case targetUnavailable = 0x0a
	case unknown = 0xff
}

enum CommandResponse: UInt8 {
	case escape = 0xab
	case startOfPacket = 0x8d
	case endOfPacket = 0xd8
	case escapeMask = 0x88
	case escapedEscape = 0x23
	case escapedStartOfPacket = 0x05
	case escapedEndOfPacket = 0x50
}
