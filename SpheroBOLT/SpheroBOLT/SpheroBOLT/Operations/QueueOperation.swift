//
//  QueueOperation.swift
//  SpheroBOLT
//
//  Created by Zhivko Bogdanov on 04.12.23.
//

import Foundation
import CoreBluetooth

@propertyWrapper
public class Atomic<T> {
	private var _wrappedValue: T
	private var lock = NSLock()

	public var wrappedValue: T {
		get { lock.synchronized { _wrappedValue } }
		set { lock.synchronized { _wrappedValue = newValue } }
	}

	public init(wrappedValue: T) {
		_wrappedValue = wrappedValue
	}
}

extension NSLocking {
	func synchronized<T>(block: () throws -> T) rethrows -> T {
		lock()
		defer { unlock() }
		return try block()
	}
}

private extension SerialOperation {
	/// State for this operation.
	@objc enum OperationState: Int {
		case ready
		case executing
		case finished
	}
}

class SerialOperation: Operation {
	@Atomic @objc private dynamic var state: OperationState = .ready

	// MARK: - Various `Operation` properties

	open override var isReady: Bool {
		state == .ready && super.isReady
	}

	public final override var isExecuting: Bool {
		state == .executing
	}

	public final override var isFinished: Bool {
		state == .finished
	}

	public final override var isAsynchronous: Bool {
		true
	}

	public final override var isConcurrent: Bool {
		return false
	}

	// KVO for dependent properties

	open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
		if [#keyPath(isReady), #keyPath(isFinished), #keyPath(isExecuting)].contains(key) {
			return [#keyPath(state)]
		}

		return super.keyPathsForValuesAffectingValue(forKey: key)
	}

	public final override func start() {
		if isCancelled {
			state = .finished

			return
		}

		state = .executing

		main()
	}

	/// Subclasses must implement this to perform their work and they must not call `super`. The default implementation of this function throws an exception.
	open override func main() {
		fatalError("Subclasses must implement `main`.")
	}

	/// Call this function to finish an operation that is currently executing
	public final func finish() {
		if !isFinished {
			state = .finished
		}
	}
}
