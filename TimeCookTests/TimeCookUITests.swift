import XCTest
import TimeCookCore

final class TimeCookUITests: XCTestCase {
    func testNotificationIdentifiersUseStableNamespace() {
        let dish = Dish(id: UUID(uuidString: "00000000-0000-0000-0000-000000000099")!, name: "Test", duration: 60)
        let notifications = NotificationPlanBuilder.notifications(for: CookingPlan(dishes: [dish]))
        XCTAssertEqual(notifications.map(\.id), ["timecook.cooking.finish"])
    }
}
