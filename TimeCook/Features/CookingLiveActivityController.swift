import Foundation
import TimeCookCore

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class CookingLiveActivityController {
    static let shared = CookingLiveActivityController()
    private init() {}

    #if canImport(ActivityKit)
    private var activity: Any?
    #endif

    func start(plan: CookingPlan, startDate: Date) async {
        guard let snapshot = CookingActivitySnapshot.make(plan: plan, startDate: startDate) else { return }
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            await end()
            let attributes = CookingActivityAttributes(title: snapshot.title, totalDishes: snapshot.totalDishes)
            let state = CookingActivityAttributes.ContentState(
                endsAt: snapshot.endsAt,
                nextDishName: snapshot.nextDishName,
                nextDishStartAt: snapshot.nextDishStartAt
            )
            do {
                let newActivity = try Activity<CookingActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: snapshot.endsAt.addingTimeInterval(60)),
                    pushType: nil
                )
                activity = newActivity
            } catch {
                print("Live Activity start failed: \(error.localizedDescription)")
            }
        }
        #endif
    }

    func end() async {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            for current in Activity<CookingActivityAttributes>.activities {
                await current.end(nil, dismissalPolicy: .immediate)
            }
            activity = nil
        }
        #endif
    }
}
