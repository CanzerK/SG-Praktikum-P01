//
//  Packet.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation

struct PacketFlags: OptionSet {
	let rawValue: UInt8

	static let response = PacketFlags(rawValue: 0x01)
	static let requestsResponse = PacketFlags(rawValue: 0x02)
	static let requestsOnlyErrorResponse = PacketFlags(rawValue: 0x04)
	static let resetsInactivityTimeout = PacketFlags(rawValue: 0x08)
	static let commandHasTargetId = PacketFlags(rawValue: 0x10)
	static let commandHasSourceId = PacketFlags(rawValue: 0x20)
}

/// Packet structure:
/// ---------------------------------
/// - start		[1 byte] Specifies the beginning of a packet, the value is always FFh.
/// - flags		[1 byte] Bit-encoded selection of per-command options.
/// - source_id 	[1 byte] (optional) Specifies which "virtual device" the command belongs to.
/// - target_id	[1 byte] (optional) Specifies the command to perform.
/// - device_id 	[1 byte]
/// - command_id	[1 byte]
/// - data		[n byte]
/// - checksum	[1 byte]
/// - end		[1 byte]
/// ---------------------------------
/// Usually the first data byte is the api_v2 response code.
class Command {
	let start: UInt8 = 0x8d
	let flags: PacketFlags
	let sourceId: UInt8?
	let targetId: UInt8?
	let deviceId: DeviceId
	let commandId: CommandId
	let contents: [UInt8]
	let sequenceNumber: UInt8
	let end: UInt8 = 0xd8

	init(_ flags: PacketFlags, deviceId: DeviceId, commandId: CommandId, sequenceNumber: UInt8, contents: [UInt8], sourceId: UInt8?, targetId: UInt8?) {
		self.flags = flags
		self.sourceId = sourceId
		self.targetId = targetId
		self.deviceId = deviceId
		self.commandId = commandId
		self.contents = contents
		self.sequenceNumber = sequenceNumber
	}

	var packet: Data {
		get {
			let sum = flags.rawValue + deviceId.rawValue + commandId.rawValue + sequenceNumber
		 	let checksum: UInt8 = (~sum) & 0xff
			let bytes: [UInt8] = [start, flags.rawValue, deviceId.rawValue, commandId.rawValue, sequenceNumber, checksum, end]

			return Data(bytes)
		}
	}
}
