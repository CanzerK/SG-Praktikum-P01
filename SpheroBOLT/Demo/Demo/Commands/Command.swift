//
//  Packet.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation

enum DataError: Error {
	case unableToParseResponse
}

struct PacketFlags: OptionSet {
	let rawValue: UInt8

	static let response = PacketFlags(rawValue: 0x01)
	static let requestsResponse = PacketFlags(rawValue: 0x02)
	static let requestsOnlyErrorResponse = PacketFlags(rawValue: 0x04)
	static let resetsInactivityTimeout = PacketFlags(rawValue: 0x08)
	static let commandHasTargetId = PacketFlags(rawValue: 0x10)
	static let commandHasSourceId = PacketFlags(rawValue: 0x20)
}

typealias CommandRepresentable = RawRepresentable<UInt8>

protocol CommandDataConvertible {
	var packet: Array<UInt8> { get }
}

protocol DataInitializable {
	init(fromData data: Data) throws
}

struct Payload {
	var data = Array<UInt8>()
	let checksum: UInt8

	init(_ flags: UInt8,
		 deviceId: UInt8,
		 commandId: UInt8,
		 sequenceNumber: UInt8,
		 contents: Array<UInt8>?,
		 sourceId: UInt8?,
		 targetId: UInt8?) {
		var sum: UInt8 = 0

		data.append(flags)
		sum &+= flags

		if let targetId = targetId {
			data.append(targetId)
			sum &+= targetId
		}

		if let sourceId = sourceId {
			data.append(sourceId)
			sum &+= sourceId
		}

		data.append(deviceId)
		sum &+= deviceId

		data.append(commandId)
		sum &+= commandId

		data.append(sequenceNumber)
		sum &+= sequenceNumber

		if let contents = contents {
			data.append(contentsOf: contents)

			sum &+= data.reduce(0, { partialResult, value in
				return partialResult &+ value
			})
		}

		checksum = (~sum) & 0xff
	}
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
	static let start: UInt8 = 0x8d
	static let end: UInt8 = 0xd8

	let payload: Payload

	init(_ flags: UInt8, deviceId: UInt8, commandId: UInt8, sequenceNumber: UInt8, contents: Array<UInt8>?, sourceId: UInt8?, targetId: UInt8?) {
		self.payload = Payload(flags, deviceId: deviceId, commandId: commandId, sequenceNumber: sequenceNumber, contents: contents, sourceId: sourceId, targetId: targetId)
	}

	var packet: Data {
		get {
			var bytes = Array<UInt8>()
			bytes.append(Command.start)
			bytes.append(contentsOf: payload.data)
			bytes.append(payload.checksum)
			bytes.append(Command.end)

			return Data(bytes)
		}
	}
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

extension Data {
	var bytes: [UInt8] {
		return [UInt8](self)
	}
}

class Response {
	var escaped = false
	var packet = Array<UInt8>()
	var sum: UInt8 = 0

	init(_ data: Data) throws {
		let bytes = data.bytes

		for byte in bytes {
			switch byte {
			case CommandResponse.startOfPacket.rawValue:
				packet.append(byte)

				break
			case CommandResponse.endOfPacket.rawValue:
				guard let lastByte = packet.last else { throw DataError.unableToParseResponse }

				sum -= lastByte

				if (packet.count < 6) {
					throw DataError.unableToParseResponse
				}

				let checksum: UInt8 = (~sum) & 0xff

				if (lastByte != checksum) {
					throw DataError.unableToParseResponse
				}

				packet.append(byte)
				decode(packet)


			case CommandResponse.escape.rawValue:
				escaped = true
				break
			case CommandResponse.escapedEscape.rawValue: fallthrough
			case CommandResponse.escapedStartOfPacket.rawValue: fallthrough
			case CommandResponse.escapedEndOfPacket.rawValue:
				if (escaped) {
					let escapedByte = byte | CommandResponse.escapeMask.rawValue
					packet.append(escapedByte)
					sum += escapedByte

					escaped = false
				} else {
					packet.append(byte)
					sum += byte
				}

				break
			default:
				if (escaped) {
					throw DataError.unableToParseResponse
				} else {
					packet.append(byte)
					sum += byte
				}

				break
			}
		}
	}

	func decode(_ data: Array<UInt8>) {

	}
}
