//
//  UserIO.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 22.11.23.
//

import Foundation
import CoreGraphics
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
	case setHeadlights = 0x13
	case setTaillights = 0x14
	case playTestTone = 0x18
	case startIdleLED = 0x19
	case toyCommands = 0x20
	case toyEvents = 0x21
	case setUserProfile = 0x22
	case getUserProfile = 0x23
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

public struct Pixel {
	let x: UInt8
	let y: UInt8

	init(_ x: UInt8, _ y: UInt8) {
		self.x = x
		self.y = y
	}
}

extension CGColor: CommandDataConvertible {
	var packet: Array<UInt8> {
		let red: UInt8 = UInt8(round(components![0] / 1.0) * 255)
		let green: UInt8 = UInt8(round(components![1] / 1.0) * 255)
		let blue: UInt8 = UInt8(round(components![2] / 1.0) * 255)

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
	public func setAllLEDColors(front: CGColor, 
								back: CGColor,
								completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setAllLED8BitMask,
					   data: [LED.all().rawValue.packet, front.packet, back.packet],
					   sourceId: nil,
					   targetId: nil,
					   completion: completion)
	}

	/**
	 * Sets the main LED color.
	 */
	public func setMainLEDColor(_ color: CGColor, 
								completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setAllLED8BitMask,
					   data: [[0x07], color.packet],
					   completion: completion)
	}

	/**
	 * Sets the back LED color.
	 */
	public func setBackLEDColor(_ color: CGColor, 
								completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setAllLED8BitMask,
					   data: [[0x38], color.packet],
					   completion: completion)
	}

	/**
	 * Sets a single color.
	 */
	public func setOneColor(_ color: CGColor,
							completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setLEDMatrixOneColor,
					   data: color,
					   sourceId: nil,
					   targetId: 0x12,
					   completion: completion)
	}

	/**
	 * Sets a single pixel to a color.
	 */
	public func setPixelColor(_ color: CGColor, 
							  pixel: Pixel,
							  completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setLEDMatrixPixel,
					   data: [pixel.packet, color.packet],
					   sourceId: nil,
					   targetId: 0x12,
					   completion: completion)
	}

	/**
	 * Sets the audio volume.
	 */
	public func setAudioVolume(_ value: UInt8,
							   completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setAudioVolume,
					   data: [value],
					   completion: completion)
	}

	/**
	 * Sets the matrix to display a single character.
	 */
	public func setLEDMatrixCharacter(_ character: Character, 
									  color: CGColor,
									  completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setLEDMatrixSingleCharacter,
					   data: [color.packet, [character].byteArray.packet],
					   sourceId: nil,
					   targetId: 0x12,
					   completion: completion)
	}

	/**
	 * Sets the matrix to display an entire string of text.
	 */
	public func setLEDMatrixTextScrolling(_ text: String, 
										  color: CGColor, 
										  speed: UInt8 = 0x10,
										  rep: Bool = true,
										  completion: ((Result<Void, DeviceError>) -> Void)? = nil) {
		enqueueCommand(deviceId: .userIO,
					   commandId: UserIOCommandId.setLEDMatrixTextScrolling,
					   data: [color.packet, (speed % 0x1e).packet, rep.packet, text.byteArray.packet, [0x00]],
					   sourceId: nil,
					   targetId: 0x12,
					   completion: completion)
	}
}
