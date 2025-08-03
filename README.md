# UKCPA Flutter Mobile Application

A Flutter mobile application for UK China Performing Arts, providing course booking, payment processing, and account management functionality.

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK
- iOS development setup (for iOS builds)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
```bash
git clone [repository-url]
cd ukcpa_flutter
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure environment
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── core/              # Core functionality, constants, theme
├── data/              # Data layer (API, models, repositories)
├── domain/            # Business logic layer
├── presentation/      # UI layer (screens, widgets, state)
└── main.dart         # App entry point
```

## Features

- **Authentication**: Email/password and Google Sign-In
- **Course Browsing**: Search and filter dance courses
- **Booking System**: Add courses to basket and checkout
- **Payment Processing**: Stripe integration
- **User Account**: Profile, order history, enrolled courses
- **Multi-language**: English and Chinese support

## Architecture

This project follows Clean Architecture principles with:
- **Presentation Layer**: Flutter widgets and state management
- **Domain Layer**: Business logic and entities
- **Data Layer**: API integration and data sources

State management is handled using Riverpod.

## Development

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Coverage report
flutter test --coverage
```

### Code Generation
```bash
# Generate GraphQL types
flutter pub run build_runner build --delete-conflicting-outputs
```

### Building

#### iOS
```bash
flutter build ios --release
```

#### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

## Configuration

### Environment Variables
Create a `.env` file with:
```
API_URL=https://api.ukchinaperformingarts.com/graphql
STRIPE_PUBLISHABLE_KEY=pk_test_...
GOOGLE_CLIENT_ID=...
```

### GraphQL Schema
Update GraphQL schema:
```bash
npm run generate-schema
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests
4. Submit a pull request

## License

Proprietary - UK China Performing Arts Ltd.