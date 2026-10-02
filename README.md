# GuardOps Lite

A Flutter portfolio application demonstrating an operations dashboard, live geographic data, and simulated device statistics using MVVM, BLoC, GraphQL, and constructor-based dependency injection.

## Features

- Dashboard with geographic totals, a live continent distribution overview, and simulated device status counts.
- Country search, continent filtering, pull-to-refresh, and filters preserved after detail navigation.
- Country details fetched with a parameterized query: capital, currency, code, and continent.
- Loading, empty, error, and retry states; refresh failures retain previously loaded data.
- Material 3 layouts with automated small-screen, landscape, and enlarged-text coverage.

## Screenshots

Captured from the release APK on a Pixel 10 Pro Android 17 emulator with live Countries API data. Counts reflect the capture date. The Dashboard screenshot reflects the previous layout; replace it with a new capture after installing this update.

| Dashboard | Locations | Country details |
| --- | --- | --- |
| <img src="docs/screenshots/dashboard.png" alt="Dashboard with geographic totals and simulation disclaimer" width="250"> | <img src="docs/screenshots/locations.png" alt="Country list with search and continent filter" width="250"> | <img src="docs/screenshots/location-detail.png" alt="Germany details from the Countries API" width="250"> |

## Technology and architecture

Flutter 3.47.2 stable / Dart 3.13.2, `flutter_bloc`, `graphql_flutter`, Material 3, `flutter_test`, `bloc_test`, and GitHub Actions. Dependency versions are recorded in `pubspec.lock`.

MVVM is the primary architecture. BLoCs fulfill ViewModel responsibilities; there is no additional ChangeNotifier or domain/use-case layer.

| Responsibility | Implementation |
| --- | --- |
| Model and data access | Immutable models; `LocationRepository` abstracts geographic data; `GraphQLLocationRepository` maps API data and failures; `SimulatedOperationsRepository` computes repeatable local counts. |
| ViewModel | `OperationsBloc` coordinates loading, search, filters, refresh, and dashboard state. `LocationDetailBloc` loads the selected country and handles retries. |
| View | Screens render BLoC states and forward interactions. Widgets do not make GraphQL calls. |
| Composition | `AppDependencies` constructs the theme and repositories. Constructor injection supports network-free tests. |

```text
lib/
  core/
    di/            # Composition root
    graphql/       # Client and query documents
    theme/         # Material 3 theme
  models/          # Geographic models and operational totals
  repositories/    # GraphQL access and local simulation
  viewmodels/      # BLoCs, events, and presentation states
  views/           # Dashboard, locations, and detail screens
  app.dart         # App and route composition
  main.dart        # Entry point
test/
  helpers/         # Fake repository and fixtures
  repositories/    # Data mapping and failure tests
  viewmodels/      # State transitions and refresh regressions
  views/           # Screen states and responsive navigation
.github/workflows/flutter.yml
docs/              # Public documentation and screenshots
```

## GraphQL integration

The public [Countries API](https://countries.trevorblades.com/) supplies countries and continents without an API key. List queries run concurrently. Details use `Country($code: ID!)` with a normalized two-letter code passed as a variable.

Queries and client configuration live in `lib/core/graphql/`. The repository maps typed models and distinguishes network, GraphQL, and invalid-response failures. Explicit loads use `FetchPolicy.noCache` and a 15-second request timeout. List data remains visible after refresh failure, but there is no persistent offline cache. Search and filtering operate locally on the loaded list.

## Setup and running

1. Install Flutter **3.47.2 stable** (Dart 3.13.2) and add Flutter to PATH.
2. Install Android Studio/SDK and a compatible JDK (CI uses Java 17). Start an emulator or connect a device with USB debugging.
3. From the project directory:

```bash
flutter doctor
flutter doctor --android-licenses
flutter pub get --enforce-lockfile
flutter devices
flutter run -d <device-id>
```

Internet access is required for geographic data. Android release builds include the INTERNET permission. The retained target platforms are Android and iOS. Android is the verified delivery target; iOS has not received equivalent release validation. Linux, macOS, Windows, and web runners are intentionally excluded.

## Verification

```bash
dart format lib test && flutter analyze && flutter test
```

CI checks formatting without modifying files:

```bash
dart format --output=none --set-exit-if-changed lib test
```

The 61 automated tests use injected fakes or mocked GraphQL links and do not call the live API. They cover repository mapping/errors, BLoC transitions, overlapping refresh callers, disposal during loading, filters, screen states, and navigation at three viewport sizes with text scales 1.0 and 2.0.

## Release APK

```bash
flutter build apk --release
flutter install --release -d <android-device-id>
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

The release build uses Android's local **debug signing key** for portfolio/demo installation. It is not configured for store distribution. No signing credentials are stored in the repository. Build output, local SDK paths, caches, and signing material are ignored by Git.

## CI/CD

[Flutter CI](.github/workflows/flutter.yml) runs on every push and pull request. It checks out source, sets up Java and pinned Flutter, installs locked dependencies, checks formatting, runs analysis and tests, builds a release APK, and uploads only that APK with a 14-day retention period. Download it from a successful run's **Artifacts** section.

The workflow uses read-only repository permissions and cancels superseded runs on the same ref. It does not publish GitHub releases or deploy to app stores. Workflow syntax and local build/check commands were validated; a hosted GitHub Actions run remains pending an approved push to a configured remote.

Configuration follows the official [Flutter action](https://github.com/subosito/flutter-action), [Java setup](https://github.com/actions/setup-java), [checkout](https://github.com/actions/checkout), and [artifact upload](https://github.com/actions/upload-artifact) documentation.

## Simulation disclaimer

**All operational/device statistics are simulated local demo data.** Country codes deterministically generate device counts. The application does not connect to security systems, sensors, enterprise infrastructure, or real devices. Geographic information comes from the Countries API. A listed country is not evidence of an operational deployment.
