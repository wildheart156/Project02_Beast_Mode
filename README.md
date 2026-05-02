# Beast Mode Fitness

Beast Mode Fitness is a Flutter mobile app focused on workout tracking, feedback, and social accountability. Users can create an account, complete profile setup, log workouts, receive live summary feedback, review workout history, share progress to a social feed, and receive notification updates backed by Firebase.

## Overview

The app is built around a simple user flow:

1. Authenticate with Firebase Authentication.
2. Complete a user profile stored in Firestore.
3. Log workouts with manual entry or API-assisted exercise search.
4. Generate workout summaries with intensity, calorie estimates, and feedback.
5. Save workouts to Firestore and surface them in history and dashboard summaries.
6. Share workout results into a social feed with likes and comments.
7. Receive in-app and push notification updates through Firebase Messaging.

## Core Features

- Firebase email/password authentication
- First-run profile setup and editable user profile
- Dashboard with personalized greeting, goals, daily workout summary, and feed preview
- Workout builder with multiple exercises, sets, reps, weight, and notes
- Exercise search powered by the `wger` exercise API
- Live workout feedback based on calculated intensity and estimated calories
- Workout summary and history views
- Edit and delete saved workouts
- Social feed with workout shares, status posts, likes, comments, and post editing
- Notification center backed by Firestore and Firebase Cloud Messaging
- Light and dark theme support

## Tech Stack

- `Flutter`
- `Dart`
- `Firebase Authentication`
- `Cloud Firestore`
- `Firebase Cloud Messaging`
- `Firebase Cloud Functions`
- `HTTP` package for exercise search
- `Shared Preferences` for persisted theme mode

## Architecture

The project is organized around screen-level features with Firebase-backed repositories and services:

- `lib/app/`
  App bootstrap, Firebase initialization, navigation keys, and auth gating
- `lib/screens/`
  Auth, dashboard, workout, social, notifications, and profile UI
- `lib/services/`
  Firestore repositories, push notification handling, and external API integration
- `lib/models/`
  Workout, post, comment, and exercise data models
- `functions/`
  Firebase Cloud Function for sending push notifications from Firestore events

### Important flow

- `AuthGate` listens for authentication state and user profile state.
- `DashboardScreen` hosts the main tabbed experience.
- `WorkoutScreen` manages the workout feature lifecycle using internal view state:
  `builder -> summary -> history`
- `WorkoutRepository` persists workouts and creates notification documents.
- `SocialFeedRepository` handles posts, likes, comments, and workout-sharing.
- `PushNotificationService` registers FCM tokens and opens the notifications screen from incoming alerts.

## Firebase Data Model

### Top-level collections

- `Users`
- `Posts`

### User document shape

`Users/{userId}`

- `userId`
- `email`
- `username`
- `fitnessGoals`
- `personalStats`
- `profileImageURL`
- `createdAt`
- `updatedAt`

### User subcollections

`Users/{userId}/Workouts`

- stores completed workout sessions

`Users/{userId}/Notifications`

- stores in-app alert documents

`Users/{userId}/FcmTokens`

- stores device tokens for Firebase Cloud Messaging

### Social feed structure

`Posts/{postId}`

- author metadata
- caption
- optional workout-share fields
- like and comment counts
- timestamps

`Posts/{postId}/Likes`

- stores user likes

`Posts/{postId}/Comments`

- stores comment threads

## Project Structure

```text
lib/
  app/
  models/
  screens/
    auth/
    dashboard/
    social/
    workout/
  services/
  shared/
  theme/
functions/
test/
```

## Notable Files

- [lib/app/auth_gate.dart](./lib/app/auth_gate.dart)
  Controls auth-based routing into login, profile setup, or the dashboard.
- [lib/screens/dashboard/dashboard_screen.dart](./lib/screens/dashboard/dashboard_screen.dart)
  Hosts the main app tabs and global signed-in navigation.
- [lib/screens/workout_screen.dart](./lib/screens/workout_screen.dart)
  Core workout flow including builder, summary, history, editing, and sharing.
- [lib/screens/workout/workout_calculator.dart](./lib/screens/workout/workout_calculator.dart)
  Business logic for intensity, calorie estimates, and feedback messaging.
- [lib/services/workout_repository.dart](./lib/services/workout_repository.dart)
  Firestore persistence for workouts and workout-triggered notifications.
- [lib/services/social_feed_repository.dart](./lib/services/social_feed_repository.dart)
  Feed loading, post creation, likes, comments, and transactional updates.
- [lib/services/push_notification_service.dart](./lib/services/push_notification_service.dart)
  FCM token lifecycle and in-app notification handling.
- [functions/index.js](./functions/index.js)
  Cloud Function that sends push notifications when Firestore notification documents are created.

## Setup

### Prerequisites

- Flutter SDK
- Dart SDK
- A Firebase project
- Android Studio or Xcode for device/emulator support

### Firebase configuration

This project already contains Firebase configuration files for Android and generated FlutterFire options:

- `android/app/google-services.json`
- `lib/firebase_options.dart`

If you connect the app to a different Firebase project, re-run FlutterFire configuration and update the Android config file as needed.

### Install dependencies

```bash
flutter pub get
```

### Run the Flutter app

```bash
flutter run
```

### Run tests

```bash
flutter test
```

### Firebase Functions

Install functions dependencies:

```bash
cd functions
npm install
```

Deploy functions with the Firebase CLI when ready:

```bash
firebase deploy --only functions
```

## Testing

The project includes widget and model-oriented tests covering parts of the social feed and theme behavior.

Current test files include:

- `test/social_widgets_test.dart`
- `test/social_models_test.dart`
- `test/theme_controller_test.dart`
- `test/theme_toggle_button_test.dart`

## Known Scope Notes

- The social feed supports workout shares and status posts.
- Post image fields exist in the model, but image upload is not the strongest showcased path in the current build.
- Push notification support depends on valid Firebase Messaging configuration and deployed Cloud Functions.
- Exercise search depends on the external `wger` API being available.

## Team

- Ryan Pham
- Devin Major

## License

This project is for academic/course use unless otherwise specified by the authors.
