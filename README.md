# SafePass - 2FA Authenticator App

SafePass is a secure and easy-to-use authenticator app built with Flutter. It generates time-based one-time passwords (TOTP) for two-factor authentication (2FA) and helps you secure your online accounts. The app is similar to Google Authenticator but with a simple and minimal UI design.

## Features

- Generate Time-Based One-Time Passwords (TOTP) for 2FA.
- Add accounts using QR code or manually entering the key.
- Dynamic refresh of OTP codes every 30 seconds.
- Copy OTP to clipboard with a single tap.
- Beautiful list of accounts with slidable actions (delete, etc.).
- Responsive and customizable UI.

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- A text editor like VSCode or Android Studio.

### Installation

1. Clone this repository:

```bash
git clone https://github.com/your-username/safepass-authenticator.git
cd safepass-authenticator
```

2. Install dependencies

```bash
flutter pub get
```

3. Run the app

```bash
flutter run
```

  or (for release version)

```bash
flutter run --release
```

### How to Use

- Account Type & Account Name can provided by the user without restriction.
- Secret Key provided manually must be a valid Base32 String
- QR Scanner successfully scans QR Codes with contents in the format below
```bash
format: <Account Type>/<Account Name>/<Secret Key>
example: GitHub/@naumshaz/KRSXG4F3V5MC6F6T
```

### Dependencies

- flutter: Flutter framework
- otp: Library for generating OTP codes
- flutter_slidable: Slidable actions for list items
- shared_preferences: For local storage of accounts
- flutter_barcode_scanner: To scan QR codes
- base32: For handling base32 secret keys

### Contributing
Contributions are welcome! If you have ideas or find bugs, feel free to open an issue or submit a pull request.

## Contact
For any inquiries or questions, feel free to reach out:

[Email](mailto:naum.shaz@gmail.com) / 
[GitHub](https://github.com/naumshaz/) / 
[LinkedIn](https://www.linkedin.com/in/naumshaz/)
