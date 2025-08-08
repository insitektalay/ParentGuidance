import Foundation

extension Array where Element == Double {
    func average() -> Double {
        guard !self.isEmpty else { return 0.0 }
        let total = self.reduce(0.0, +)
        return total / Double(self.count)
    }
}


