import Foundation

@MainActor
final class EnsembleService {
    static let shared = EnsembleService()
    private init() {}

    enum Mode { case bestOfN, sectionCompose }

    func chooseBest(of candidates: [(guidanceId: String, composite: Double)]) -> (String, [String: Any])? {
        guard let best = candidates.max(by: { $0.composite < $1.composite }) else { return nil }
        return (best.guidanceId, ["reason": "max composite"]) 
    }
}


