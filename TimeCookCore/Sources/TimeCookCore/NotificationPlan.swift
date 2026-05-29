import Foundation

public struct CookingNotification: Identifiable, Equatable, Sendable {
    public enum Kind: String, Sendable { case startDish, finishAll }
    public let id: String
    public let fireOffset: TimeInterval
    public let title: String
    public let body: String
    public let kind: Kind

    public init(id: String, fireOffset: TimeInterval, title: String, body: String, kind: Kind) {
        self.id = id
        self.fireOffset = fireOffset
        self.title = title
        self.body = body
        self.kind = kind
    }
}

public enum NotificationPlanBuilder {
    public static let namespace = "timecook.cooking"

    public static func notifications(for plan: CookingPlan) -> [CookingNotification] {
        guard plan.totalDuration > 0 else { return [] }
        var result: [CookingNotification] = []
        for step in plan.steps where step.startOffset > 0 {
            result.append(CookingNotification(
                id: "\(namespace).start.\(step.dish.id.uuidString)",
                fireOffset: step.startOffset,
                title: "À ajouter maintenant",
                body: "Mets \(step.dish.name) à cuire pour que tout soit prêt en même temps.",
                kind: .startDish
            ))
        }
        result.append(CookingNotification(
            id: "\(namespace).finish",
            fireOffset: plan.totalDuration,
            title: "Cuisson terminée",
            body: "Tous tes plats sont prêts. Bon appétit !",
            kind: .finishAll
        ))
        return result.sorted { $0.fireOffset < $1.fireOffset }
    }
}
