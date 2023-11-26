//
//  UserIO.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 22.11.23.
//

import Foundation

enum LED: UInt8 {
	case frontRed = 0x01
	case frontGreen = 0x02
	case frontBlue = 0x04
	case backRed = 0x08
	case backGreen = 0x10
	case backBlue = 0x20

	static func all() -> Self.RawValue {
		return frontRed.rawValue ^ frontGreen.rawValue ^ frontBlue.rawValue ^ backRed.rawValue ^ backGreen.rawValue ^ backBlue.rawValue
	}
}
