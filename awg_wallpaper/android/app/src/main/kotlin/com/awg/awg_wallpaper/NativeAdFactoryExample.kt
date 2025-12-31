package com.webinessdesign.softskywallpaper

import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

/**
 * Native Ad Factory for custom native ad layouts
 * This allows full customization of how native ads appear in the app
 */
class NativeAdFactoryExample(
    private val layoutInflater: LayoutInflater
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        // Inflate the native ad layout
        val adView = layoutInflater.inflate(
            R.layout.native_ad_layout, null
        ) as NativeAdView

        // Set native ad assets
        with(adView) {
            // Headline
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            headlineView.text = nativeAd.headline
            this.headlineView = headlineView

            // Body
            nativeAd.body?.let { body ->
                val bodyView = findViewById<TextView>(R.id.ad_body)
                bodyView.text = body
                this.bodyView = bodyView
            }

            // Call to action
            nativeAd.callToAction?.let { cta ->
                val ctaView = findViewById<Button>(R.id.ad_call_to_action)
                ctaView.text = cta
                this.callToActionView = ctaView
            }

            // Icon
            nativeAd.icon?.let { icon ->
                val iconView = findViewById<ImageView>(R.id.ad_app_icon)
                iconView.setImageDrawable(icon.drawable)
                this.iconView = iconView
            }

            // Star rating
            nativeAd.starRating?.let { rating ->
                val ratingBar = findViewById<RatingBar>(R.id.ad_stars)
                ratingBar.rating = rating.toFloat()
                this.starRatingView = ratingBar
            }

            // Advertiser
            nativeAd.advertiser?.let { advertiser ->
                val advertiserView = findViewById<TextView>(R.id.ad_advertiser)
                advertiserView.text = advertiser
                this.advertiserView = advertiserView
            }

            // Set the native ad
            setNativeAd(nativeAd)
        }

        return adView
    }
}
