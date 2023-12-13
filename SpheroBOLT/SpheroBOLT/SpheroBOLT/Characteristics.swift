//
//  Characteristics.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 11.11.23.
//

import Foundation

enum Characteristic: UInt16 {
	case deviceName = 0x2a00
	case clientCharacteristicConfiguration = 0x2902
	case peripheralPreferredConnectionParameters = 0x2a04
}
