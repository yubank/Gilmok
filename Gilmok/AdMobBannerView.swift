import GoogleMobileAds
import SwiftUI

private let bannerAdUnitID = "ca-app-pub-7604021418840473/2232436651"

struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = bannerAdUnitID
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {}
}
