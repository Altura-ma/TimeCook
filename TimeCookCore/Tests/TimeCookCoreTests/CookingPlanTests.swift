import XCTest
@testable import TimeCookCore

final class CookingPlanTests: XCTestCase {
    func testPlanStartsLongestDishFirstAndOffsetsShorterDishes() {
        let pasta = Dish(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Pâtes", duration: 600)
        let eggs = Dish(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Œufs", duration: 360)
        let steak = Dish(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Steak", duration: 180)

        let plan = CookingPlan(dishes: [eggs, steak, pasta])

        XCTAssertEqual(plan.totalDuration, 600)
        XCTAssertEqual(plan.steps.map { $0.dish.name }, ["Pâtes", "Œufs", "Steak"])
        XCTAssertEqual(plan.steps.map { $0.startOffset }, [0, 240, 420])
    }

    func testNotificationPlanSchedulesStartRemindersAndFinalAlert() {
        let long = Dish(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, name: "Riz", duration: 900)
        let short = Dish(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, name: "Poisson", duration: 300)
        let plan = CookingPlan(dishes: [long, short])

        let notifications = NotificationPlanBuilder.notifications(for: plan)

        XCTAssertEqual(notifications.count, 2)
        XCTAssertEqual(notifications[0].kind, .startDish)
        XCTAssertEqual(notifications[0].fireOffset, 600)
        XCTAssertTrue(notifications[0].body.contains("Poisson"))
        XCTAssertEqual(notifications[1].kind, .finishAll)
        XCTAssertEqual(notifications[1].fireOffset, 900)
    }

    func testActivitySnapshotComputesDates() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let plan = CookingPlan(dishes: [Dish(name: "Poulet", duration: 1200), Dish(name: "Légumes", duration: 300)])
        let snapshot = try XCTUnwrap(CookingActivitySnapshot.make(plan: plan, startDate: start))

        XCTAssertEqual(snapshot.endsAt, start.addingTimeInterval(1200))
        XCTAssertEqual(snapshot.nextDishName, "Légumes")
        XCTAssertEqual(snapshot.nextDishStartAt, start.addingTimeInterval(900))
        XCTAssertEqual(snapshot.totalDishes, 2)
    }
}
