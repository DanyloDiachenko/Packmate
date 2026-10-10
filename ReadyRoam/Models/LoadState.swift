import Foundation

public enum LoadState<Value>: Equatable where Value: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(message: String)

    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    public var value: Value? {
        if case .loaded(let val) = self {
            return val
        }
        return nil
    }

    public var errorMessage: String? {
        if case .failed(let msg) = self {
            return msg
        }
        return nil
    }
}
