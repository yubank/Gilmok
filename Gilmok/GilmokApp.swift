import GoogleMobileAds
import SwiftUI

@main
struct GilmokApp: App {
    init() {
        Task { await MobileAds.shared.start() }
    }

    var body: some Scene {
        WindowGroup {
            DefenseScreen()
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}
