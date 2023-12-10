//
//  CommandDataTypes.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 05.12.23.
//

import Foundation
import Combine

extension UInt8: CommandDataConvertible {
	var packet: Array<UInt8> {
		return [self]
	}
}

extension Array: CommandDataConvertible where Element: CommandDataConvertible {
	var packet: Array<UInt8> {
		return Array<UInt8>(map { $0.packet }.joined())
	}
}

extension Array where Element == Character {
	var byteArray: Array<UInt8> {
		return String(self).utf8.map { UInt8($0) }
	}
}

extension String {
	var byteArray: Array<UInt8> {
		let maxCharacters = min(6, count)
		let dropCharacters = count - maxCharacters

		return utf8.map { UInt8($0) }.dropLast(dropCharacters).packet
	}
}

extension Bool: CommandDataConvertible {
	var packet: Array<UInt8> {
		return self == true ? [0x01] : [0x00]
	}
}

extension UInt16 {
	var packet: Array<UInt8> {
		var value = bigEndian
		let count = MemoryLayout<UInt16>.size
		let bytePtr = withUnsafePointer(to: &value) {
			$0.withMemoryRebound(to: UInt8.self, capacity: count) {
				UnsafeBufferPointer(start: $0, count: count)
			}
		}

		return Array(bytePtr)
	}
}

func combineBits(part1: UInt8, part2: UInt8) -> UInt16 {
	return UInt16(part1) << 8 + UInt16(part2)
}

struct BatteryLevel: DataInitializable {
	init(fromData data: Data) throws {

	}
}

extension Float: DataInitializable {
	init(fromData data: Data) throws {
		self.init()
	}
}

extension Int: DataInitializable {
	init(fromData data: Data) throws {
		self.init()
	}
}

typealias CommandResponseType<R> = AnyPublisher<R, DeviceError>
