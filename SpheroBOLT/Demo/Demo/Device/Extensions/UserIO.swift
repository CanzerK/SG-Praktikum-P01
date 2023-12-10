//
//  UserIO.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 22.11.23.
//

import Foundation
import Combine

enum UserIOCommandId: UInt8 {
	case enableGestureEventNotification = 0x00
	case gestureEvent = 0x01
	case enableButtonEventNotification = 0x02
	case buttonEvent = 0x03
	case setLED = 0x04
	case releaseLED = 0x05
	case playHapticPattern = 0x06
	case playAudioFile = 0x07
	case setAudioVolume = 0x08
	case getAudioVolume = 0x09
	case stopAllAudio = 0x0a
	case capTouchEnable = 0x0b
	case ambientLightSensorEnable = 0x0c
	case enableIR = 0x0d
	case setAllLED = 0x0e
	case setBacklightIntensity = 0x0f
	case capTouchIndication = 0x10
	case enableDebugData = 0x11
	case assertLCDResetPIN = 0x12
	case setHeadlights = 0x13
	case setTaillights = 0x14
	case playTestTone = 0x18
	case startIdleLED = 0x19
	case toyCommands = 0x20
	case toyEvents = 0x21
	case setUserProfile = 0x22
	case getUserProfile = 0x23
	case setAllLED32BitMask = 0x1a
	case setAllLED64BitMask = 0x1b
	case setAllLED8BitMask = 0x1c
	case setLEDMatrixPixel = 0x2d
	case setLEDMatrixOneColor = 0x2f
	case setLEDMatrixFrameRotation = 0x3a
	case setLEDMatrixTextScrolling = 0x3b
	case setLEDMatrixTextScrollingNotify = 0x3c
	case setLEDMatrixSingleCharacter = 0x42
}

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

struct Pixel {
	let x: UInt8
	let y: UInt8

	init(_ x: UInt8, _ y: UInt8) {
		self.x = x
		self.y = y
	}
}

struct Color {
	let r: Float
	let g: Float
	let b: Float

	init(_ r: Float, _ g: Float, _ b: Float) {
		self.r = r
		self.g = g
		self.b = b
	}
}

extension Color: CommandDataConvertible {
	var packet: Array<UInt8> {
		let red: UInt8 = UInt8(round(r / 1.0) * 255)
		let green: UInt8 = UInt8(round(g / 1.0) * 255)
		let blue: UInt8 = UInt8(round(b / 1.0) * 255)

		return [red, green, blue]
	}
}

extension Pixel: CommandDataConvertible {
	var packet: Array<UInt8> {
		return [x & 0x07, y & 0x07]
	}
}

/// UserIO extensions to the device object.
extension Device {
	/**
	 * Sets the color of the main matrix.
	 */
	func setAllLEDColors(front: Color, back: Color) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO,
							  commandId: UserIOCommandId.setAllLED8BitMask,
							  data: [LED.all().rawValue.packet, front.packet, back.packet],
							  sourceId: nil,
							  targetId: nil)
	}

	/**
	 * Sets the main LED color.
	 */
	func setMainLEDColor(_ color: Color) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO,
							  commandId: UserIOCommandId.setAllLED8BitMask,
							  data: [[0x07], color.packet])
	}

	/**
	 * Sets the back LED color.
	 */
	func setBackLEDColor(_ color: Color) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO,
							  commandId: UserIOCommandId.setAllLED8BitMask,
							  data: [[0x38], color.packet])
	}

	/**
	 * Sets a single color.
	 */
	func setOneColor(_ color: Color) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO,
							  commandId: UserIOCommandId.setLEDMatrixOneColor,
							  data: color, 
							  sourceId: nil,
							  targetId: 0x12)
	}

	/**
	 * Sets a single pixel to a color.
	 */
	func setPixelColor(_ color: Color, pixel: Pixel) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO,
							  commandId: UserIOCommandId.setLEDMatrixPixel,
							  data: [pixel.packet, color.packet],
							  sourceId: nil,
							  targetId: 0x12)
	}

	/**
	 * Sets the audio volume.
	 */
	func setAudioVolume(_ value: UInt8) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO, commandId: UserIOCommandId.setAudioVolume, data: [value])
	}

	/**
	 * Sets the matrix to display a single character.
	 */
	func setLEDMatrixCharacter(_ character: Character, color: Color) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO,
							  commandId: UserIOCommandId.setLEDMatrixSingleCharacter,
							  data: [color.packet, [character].byteArray.packet],
							  sourceId: nil,
							  targetId: 0x12)
	}

	func setLEDMatrixTextScrolling(_ text: String, color: Color, speed: UInt8 = 0x10, rep: Bool = true) -> CommandResponseType<Void> {
		return enqueueCommand(deviceId: .userIO,
							  commandId: UserIOCommandId.setLEDMatrixTextScrolling,
							  data: [color.packet, (speed % 0x1e).packet, rep.packet, text.byteArray.packet, [0x00]],
							  sourceId: nil,
							  targetId: 0x12)
	}
}
