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
	static let start: UInt8 = 0x8d
	static let end: UInt8 = 0xd8
	static let escape: UInt8 = 0xab
	static let escapeMask: UInt8 = 0x88

	static let escapedStart = start & ~escapeMask
	static let escapedEnd = end & ~escapeMask
	static let escapedEscape = escape & ~escapeMask

	static let escapedBytes: Array<UInt8> = [escapedStart, escapedEnd, escapedEscape]
	static let badBytes: Array<UInt8> = [start, end, escape]

	var data = Array<UInt8>()
	let checksum: UInt8

	init(_ flags: UInt8,
		 deviceId: UInt8,
		 commandId: UInt8,
		 sequenceNumber: UInt8,
		 contents: Array<UInt8>?,
		 sourceId: UInt8?,
		 targetId: UInt8?) {
		var sum: UInt32 = 0

		data.append(flags)
		sum += UInt32(flags)

		if let targetId = targetId {
			data.append(targetId)
			sum += UInt32(targetId)
		}

		if let sourceId = sourceId {
			data.append(sourceId)
			sum += UInt32(sourceId)
		}

		data.append(deviceId)
		sum += UInt32(deviceId)

		data.append(commandId)
		sum += UInt32(commandId)

		data.append(sequenceNumber)
		sum += UInt32(sequenceNumber)

		if let contents = contents {
			data.append(contentsOf: contents)

			let dataSum = contents.reduce(0, { partialResult, value in
				return partialResult + UInt32(value)
			})

			sum += dataSum
		}

		let lastByte = withUnsafeBytes(of: sum.bigEndian) { Array($0) }.last!
		checksum = ~lastByte

		data.append(checksum)
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
	let payload: Payload

	init(_ flags: UInt8, deviceId: UInt8, commandId: UInt8, sequenceNumber: UInt8, contents: Array<UInt8>?, sourceId: UInt8?, targetId: UInt8?) {
		self.payload = Payload(flags, deviceId: deviceId, commandId: commandId, sequenceNumber: sequenceNumber, contents: contents, sourceId: sourceId, targetId: targetId)
	}

	var packet: Data {
		get {
			var escapedData = Array<UInt8>()
			payload.data.forEach { value in
				if Payload.badBytes.contains(value) {
					escapedData.append(Payload.escape)
					escapedData.append(value & ~Payload.escapeMask)
				} else {
					escapedData.append(value)
				}
			}

			var bytes = Array<UInt8>()
			bytes.append(Payload.start)
			bytes.append(contentsOf: escapedData)
			bytes.append(Payload.end)

			return Data(bytes)
		}
	}
}

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
			case Payload.start:
				packet.append(byte)

				break
			case Payload.end:
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


			case Payload.escape:
				escaped = true
				break
			case Payload.escapedEscape: fallthrough
			case Payload.start: fallthrough
			case Payload.end:
				if (escaped) {
					let escapedByte = byte | Payload.escapeMask
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
