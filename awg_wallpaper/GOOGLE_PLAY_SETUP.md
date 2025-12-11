# Google Play Console Setup Guide

## Prerequisites
1. Google Play Developer account ($25 one-time fee)
2. App uploaded as an internal test or closed test

## Step 1: Create In-App Products

Go to: **Google Play Console > [Your App] > Monetize > Products > Subscriptions**

Create the following subscription products:

| Product ID | Name | Price | Billing Period |
|------------|------|-------|----------------|
| `awg_pro_weekly` | AWG Pro Weekly | $1.99 | Weekly |
| `awg_pro_monthly` | AWG Pro Monthly | $4.99 | Monthly |
| `awg_pro_yearly` | AWG Pro Yearly | $29.99 | Yearly |

For lifetime, create an **In-app product** (not subscription):

| Product ID | Name | Price | Type |
|------------|------|-------|------|
| `awg_pro_lifetime` | AWG Pro Lifetime | $49.99 | One-time |

## Step 2: Activate Products

1. Set status to **Active** for each product
2. Add descriptions and benefits

## Step 3: Set Up License Testing

Go to: **Settings > License testing**

1. Add your test email addresses
2. These can purchase without real payment during testing

## Step 4: Configure App Signing

1. Ensure app is signed with release key
2. Upload AAB to internal test track

## Step 5: Update Product IDs (if different)

Edit `lib/providers/subscription_provider.dart`:

```dart
class ProductIds {
  static const String weekly = 'your_weekly_product_id';
  static const String monthly = 'your_monthly_product_id';
  static const String yearly = 'your_yearly_product_id';
  static const String lifetime = 'your_lifetime_product_id';
  // ...
}
```

## Testing

1. Build release APK: `flutter build apk --release`
2. Install on test device
3. Sign in with license tester account
4. Products should load and purchases work without real payment
