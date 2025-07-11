# Stripe Payment Integration Setup Guide

This guide explains how to set up Stripe payment gateway integration for the Digital Certificate Repository app.

## Prerequisites

1. A Stripe account (sign up at https://stripe.com)
2. Flutter development environment
3. Backend server (Node.js, Python, etc.) for handling payment intents

## Step 1: Stripe Account Setup

1. **Create a Stripe Account**

   - Go to https://stripe.com and sign up
   - Complete your account verification
   - Switch to test mode for development

2. **Get Your API Keys**
   - In your Stripe Dashboard, go to Developers > API keys
   - Copy your **Publishable key** (starts with `pk_test_` or `pk_live_`)
   - Copy your **Secret key** (starts with `sk_test_` or `sk_live_`)

## Step 2: Flutter Dependencies

The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_stripe: ^10.0.0
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

Run `flutter pub get` to install the dependencies.

## Step 3: Configure Stripe Keys

### Update the Donation Screen

In `lib/screens/donation_screen.dart`, replace the placeholder key:

```dart
// Replace this line:
static const String _stripePublishableKey = 'pk_test_your_stripe_publishable_key_here';

// With your actual publishable key:
static const String _stripePublishableKey = 'pk_test_51ABC123...';
```

### Update the Donation Service

In `lib/services/donation_service.dart`, update the backend URL and secret key:

```dart
// Replace with your actual backend URL
static const String _backendUrl = 'https://your-backend-url.com';

// Replace with your actual secret key (keep this secure on your backend)
static const String _stripeSecretKey = 'sk_test_51ABC123...';
```

## Step 4: Backend Setup

You need a backend server to create payment intents securely. Here's an example using Node.js:

### Install Dependencies

```bash
npm init -y
npm install express stripe cors dotenv
```

### Create Server (server.js)

```javascript
const express = require("express");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
const cors = require("cors");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency, email } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in cents
      currency: currency,
      receipt_email: email,
      metadata: {
        donation_type: "digital_certificate_repository",
        platform: "flutter_app",
      },
    });

    res.json({
      client_secret: paymentIntent.client_secret,
      id: paymentIntent.id,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Environment Variables (.env)

```
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
PORT=3000
```

## Step 5: Platform-Specific Configuration

### Android Setup

1. **Update android/app/build.gradle.kts**:

```kotlin
android {
    defaultConfig {
        // ... other config
        minSdkVersion 21 // Required for Stripe
    }
}
```

2. **Add permissions to android/app/src/main/AndroidManifest.xml**:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS Setup

1. **Update ios/Runner/Info.plist**:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan payment cards</string>
```

2. **Update minimum iOS version in ios/Podfile**:

```ruby
platform :ios, '12.0'
```

## Step 6: Testing

### Test Cards

Use these test card numbers in Stripe test mode:

- **Visa**: 4242424242424242
- **Mastercard**: 5555555555554444
- **American Express**: 378282246310005
- **Declined**: 4000000000000002

### Test Amounts

- Use small amounts like RM 1.00 for testing
- Test both successful and failed payments
- Verify webhook notifications (if implemented)

## Step 7: Production Deployment

### Security Considerations

1. **Never expose secret keys in client-side code**
2. **Use environment variables for sensitive data**
3. **Implement proper error handling**
4. **Add webhook verification for production**

### Environment Variables

```bash
# Development
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# Production
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
```

## Step 8: Webhook Setup (Optional)

For production, set up webhooks to handle payment events:

```javascript
app.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];
    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.WEBHOOK_SECRET
      );
    } catch (err) {
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    switch (event.type) {
      case "payment_intent.succeeded":
        const paymentIntent = event.data.object;
        console.log("Payment succeeded:", paymentIntent.id);
        break;
      case "payment_intent.payment_failed":
        const failedPayment = event.data.object;
        console.log("Payment failed:", failedPayment.id);
        break;
    }

    res.json({ received: true });
  }
);
```

## Troubleshooting

### Common Issues

1. **"No such module 'Stripe'" error on iOS**

   - Run `cd ios && pod install && cd ..`
   - Clean and rebuild: `flutter clean && flutter pub get`

2. **Payment sheet not appearing**

   - Check internet connection
   - Verify publishable key is correct
   - Ensure backend is running and accessible

3. **Payment intent creation fails**
   - Check secret key in backend
   - Verify amount is in cents
   - Check Stripe dashboard for errors

### Debug Mode

Enable debug logging:

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Stripe debug mode
  Stripe.instance.applySettings();

  runApp(const MyApp());
}
```

## Support

- [Stripe Documentation](https://stripe.com/docs)
- [Flutter Stripe Plugin](https://pub.dev/packages/flutter_stripe)
- [Stripe Support](https://support.stripe.com)

## Demo Mode

The current implementation includes a demo mode that simulates payments without actual Stripe integration. To enable real payments:

1. Replace mock implementations with actual Stripe calls
2. Set up a backend server
3. Configure real Stripe keys
4. Test thoroughly before going live

## Bonus Features

Consider implementing these additional features:

- **Recurring donations** using Stripe Subscriptions
- **Multiple currencies** support
- **Donation goals and progress tracking**
- **Email receipts** for donors
- **Donor recognition wall**
- **Tax deduction certificates**
