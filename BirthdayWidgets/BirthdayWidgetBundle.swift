import WidgetKit
import SwiftUI

@main
struct BirthdayWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallNextBirthdayWidget()
        SmallNextFavBirthdayWidget()
        MediumNextBirthdayWidget()
        MediumNextFavBirthdayWidget()
    }
}
