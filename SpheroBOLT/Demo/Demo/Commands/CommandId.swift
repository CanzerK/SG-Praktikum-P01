//
//  Command.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation

enum CommandId: UInt8 {
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
