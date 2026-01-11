# Idea Weaver AI

AI-powered mind mapping application for brainstorming and idea generation.

## Features

### Mind Mapping
- Interactive canvas with zoom, pan, and drag-drop support
- Create, edit, and organize nodes with parent-child relationships
- Custom node colors and styling
- Auto-layout functionality for organized mind maps
- Undo/redo support for all editing operations

### AI-Powered Suggestions
- AI-generated suggestions based on selected nodes
- Multiple suggestion categories: Related, Opposite, Questions, Expansion
- One-tap addition of suggestions to your mind map
- AI-generated summaries of your entire mind map

### Real-time Collaboration
- Share mind maps with collaborators
- Real-time sync of edits across all participants
- Live cursor tracking to see collaborators' positions
- Collaborative editing with instant updates

### Export Options
- PNG image export with customizable quality
- PDF document export with structured outline
- Markdown format for documentation
- OPML format for compatibility with other apps

### Voice Input
- Speech-to-text for hands-free node creation
- Support for multiple languages (Japanese, English, etc.)
- Real-time transcription display

### Freemium Model
- **Free Plan**: 3 mind maps, 10 AI uses per month
- **Pro Plan (800 yen/month)**: Unlimited maps, unlimited AI, all export formats

## Getting Started

### Prerequisites
- Flutter SDK ^3.10.7
- Dart SDK ^3.10.7
- Firebase project with:
  - Authentication enabled
  - Cloud Firestore configured
  - Storage configured (optional, for assets)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd idea_weaver_ai
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Email/Password and Google Sign-In authentication
   - Create a Cloud Firestore database
   - Download the configuration files:
     - `google-services.json` for Android -> `android/app/`
     - `GoogleService-Info.plist` for iOS -> `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
  main.dart                           # App entry point
  firebase_options.dart               # Firebase configuration
  src/
    common_widgets/                   # Reusable UI components
      primary_button.dart
      social_login_button.dart
    domain/
      models/                         # Data models
        app_user.dart
        mind_map.dart
    features/
      auth/                           # Authentication feature
        presentation/
          login_screen.dart
          register_screen.dart
        providers/
          auth_provider.dart
        services/
          auth_service.dart
      editor/                         # Mind map editor
        presentation/
          editor_screen.dart
          widgets/
            ai_suggestion_panel.dart
            mind_map_canvas.dart
        providers/
          editor_provider.dart
      export/                         # Export feature
        presentation/
          export_screen.dart
      home/                           # Home screen
        presentation/
          home_screen.dart
          widgets/
            mind_map_card.dart
        providers/
          mind_map_provider.dart
      settings/                       # Settings
        presentation/
          settings_screen.dart
    routing/
      app_router.dart                 # Navigation configuration
    services/
      ai_service.dart                 # AI suggestions service
      collaboration_service.dart      # Real-time collaboration
      export_service.dart             # Export functionality
      firestore_service.dart          # Firestore persistence
      subscription_service.dart       # Freemium management
      voice_input_service.dart        # Voice input
```

## Technology Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod 3.x
- **Navigation**: go_router
- **Backend**: Firebase (Auth, Firestore, Storage)
- **AI**: Mock service (ready for integration with OpenAI, Claude, etc.)
- **Voice**: speech_to_text package
- **Export**: pdf package, share_plus

## Configuration

### Firebase Rules (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /mind_maps/{mapId} {
      allow read: if request.auth != null &&
        (resource.data.ownerId == request.auth.uid ||
         request.auth.uid in resource.data.collaboratorIds);
      allow write: if request.auth != null &&
        (resource.data.ownerId == request.auth.uid ||
         request.auth.uid in resource.data.collaboratorIds);
      allow create: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Testing

Run unit and widget tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

## Acknowledgments

- Flutter team for the amazing framework
- Riverpod for elegant state management
- Firebase for backend services
