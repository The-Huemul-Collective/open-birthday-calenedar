import WidgetKit
import SwiftUI

@main
struct BirthdayWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Birthday widgets
        SmallNextBirthdayWidget()
        SmallNextFavBirthdayWidget()
        MediumNextBirthdayWidget()
        MediumNextFavBirthdayWidget()
        // Event countdown widgets
        EventCountdownWidget()
        MultiCountdownWidget()
        LiveCountdownWidget()
        DashboardWidget()
    }
}
