//


import Foundation

/**
	Syncer enables you to define a closure (task) to be executed synchronously, blocking the main thread. See '.waitFor' static method for more.
*/
public class Syncer<Value> {
	public typealias Task = (Semaphore) -> Void
	
	private(set) var value: Value?
	private(set) var task: Task
	private let dispatchSemaphore = DispatchSemaphore(value: 0)
	private var started = false
	
	private init(task: @escaping Task) {
		self.task = task
	}
	
	/// Starts the task
	private func start() {
		guard
			!started else { return }
		let semaphore = Semaphore(parent: self)
		DispatchQueue.global(qos: .userInitiated).async {
			self.task(semaphore)
		}
	}
	
	/// Starts the task, waits synchronously and then returns it.
	public func startWaitReturn(timeout: Double?) -> Value? {
		start()
		if let timeout = timeout {
			_ = dispatchSemaphore.wait(timeout: .now() + timeout)
		} else {
			dispatchSemaphore.wait()
		}
		return value
	}
	
	/// Sets the semaphore to green with value and continues execution. Should be only executed inside the task closure, after the semaphore has been started already.
	public func signal(_ value: Value? = nil) {
		self.value = value
		dispatchSemaphore.signal()
	}
	
	/// Returns a value from passed 'task' closure synchronously. ⚠️ You have to call $0.signal(value:) inside the closure! Otherwise the system would wait indefinitely!
	public static func waitFor(timeout: Double?, task: @escaping (Semaphore) -> Void) -> Value! {
		return Syncer<Value>(task: task).startWaitReturn(timeout: timeout)
	}
}

public extension Syncer {
	
	class Semaphore {
		
		private var parent: Syncer<Value>
		
		init(parent: Syncer<Value>) {
			self.parent = parent
		}
		
		public func signal(_ value: Value? = nil) {
			parent.signal(value)
		}
	}
}

fileprivate extension Bool {
	
	/// Toggles bool to 'true' and returns true (success) only if it was not true already.
	mutating func toggleOnFirstTime() -> Bool {
		if self == true { return false }
		toggle()
		return true
	}
}
