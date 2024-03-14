//
//  DelayOperation.swift
//  SpheroBOLT-Godot
//
//  Created by Zhivko Bogdanov on 11.03.24.
//

import Foundation
import CoreBluetooth

/// Base for all peripheral operations.
class DelayOperation: SerialOperation {
	internal var completion: ((Result<Void, DeviceError>) -> Void)?
	internal let duration: Int

	fileprivate var operationCancelled = false

	override var isCancelled: Bool {
		return operationCancelled
	}

	init(_ duration: Float, completion: ((Result<Void, DeviceError>) -> Void)?) {
		self.duration = Int(1000.0 * duration)
		self.completion = completion

		super.init()
	}

	/// Called when the operation has been cancelled.
	override func cancel() {
		super.cancel()

		operationCancelled = true
	}

	override func main() {
		if (isCancelled) {
			return
		}

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(duration)) { [weak self] in
			guard let self = self else {
				return
			}
			
			guard isCancelled == false else {
				return
			}

			self.completion?(.success(()))

			self.finish()
		}

	}
}
