//
//  Command.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation

enum DeviceId: UInt8 {
	case apiProcessor = 0x10
	case systemInfo = 0x11
	case systemModes = 0x12
	case power = 0x13
	case driving = 0x16
	case animatronics = 0x17
	case sensors = 0x18
	case peerConnection = 0x19
	case userIO = 0x1a
	case storageCommand = 0x1b
	case secondaryMCUFirmwareUpdateCommand = 0x1d
	case wifiCommand = 0x1e
	case factoryTest = 0x1f
	case macroSystem = 0x20
	case proto = 0xfe
}

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
