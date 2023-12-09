//
//  PeerConnection.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 26.11.23.
//

import Foundation

enum PeerConnectionCommand: UInt8 {
	case enablePeerConnectionEventNotification = 0x00
	case peerConnectionEvent = 0x01
	case getPeerConnectionState = 0x02
	case setBluetoothName = 0x03
	case getBluetoothName = 0x04
}
