import WidgetKit
import SwiftUI

@main
struct TimeCookLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            TimeCookLiveActivityWidget()
        }
    }
}
