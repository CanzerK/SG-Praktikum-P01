//
//  UserIO.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 22.11.23.
//

import Foundation

struct LED: OptionSet {
	let rawValue: UInt8

	static let frontRed = LED(rawValue: 0x01)
	static let frontGreen = LED(rawValue: 0x02)
	static let frontBlue = LED(rawValue: 0x04)
	static let backRed = LED(rawValue: 0x08)
	static let backGreen = LED(rawValue: 0x10)
	static let backBlue = LED(rawValue: 0x20)

	static func all() -> Self {
		return LED(rawValue: frontRed.rawValue | frontGreen.rawValue | frontBlue.rawValue | backRed.rawValue | backGreen.rawValue | backBlue.rawValue)
	}
}

struct Color {
	let r: Float
	let g: Float
	let b: Float
}

extension Color: CommandDataConvertible {
	var packet: AnySequence<UInt8>? {
		let red: UInt8 = UInt8(round(r / 1.0) * 255)
		let green: UInt8 = UInt8(round(g / 1.0) * 255)
		let blue: UInt8 = UInt8(round(b / 1.0) * 255)

		return AnySequence([red & 0xff, green & 0xff, blue & 0xff])
	}
}


