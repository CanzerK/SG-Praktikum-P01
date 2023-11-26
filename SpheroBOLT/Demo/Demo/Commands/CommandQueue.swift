//
//  Queue.swift
//  Demo
//
//  Created by Zhivko Bogdanov on 23.11.23.
//

import Foundation

struct CommandQueue {
	private var elements: [Command] = []

	var head: Command? {
		return elements.first
	}

	var tail: Command? {
		return elements.last
	}

	mutating func enqueue(_ value: Command) {
		elements.append(value)
	}

	mutating func dequeue() -> Command? {
		guard !elements.isEmpty else {
			return nil
		}

		return elements.removeFirst()
	}

	mutating func empty() {
		elements.removeAll()
	}
}
