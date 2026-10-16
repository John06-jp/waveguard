# Running the WaveGuard Android frontend

## Demo preview

```powershell
flutter pub get
flutter run
```

Choose an Android device or emulator. On first launch the app opens Splash, then **Get Started**, then Login. Select **Continue as guest** to explore **Home, Forecast, Map, Beaches, and More**. The bottom navigation remains visible while opening details inside these tabs. More includes Safety Tips, Settings, About, SOS & Emergency Contacts, Historical Incident Map, and Advisory History. The top SOS action is available throughout the main shell.

Get Started completion is saved on the device. Subsequent launches can go directly to login; restored authenticated sessions enter the main app. Account forms and the entry screens sit outside the bottom navigation.

## Marine forecasts and preferences

The default forecast is a visibly labeled fictional demo. Enable real Open-Meteo marine reads independently of Firebase:

```powershell
flutter run --dart-define=USE_LIVE_MARINE=true
```

You can also add `"USE_LIVE_MARINE": true` to the local configuration JSON. The app requests current wave height/direction/period, hourly values for the forecast, and seven daily marine aggregations at the regional Lianga point (8.6336 N, 126.0947 E). The API selects an appropriate sea grid; its returned coordinates may differ. Daily maximum height/period and dominant direction are labeled separately from hourly values. Live forecasting does not enable authentication or run the regional safety model.

Forecast values use [Open-Meteo's Marine API](https://open-meteo.com/en/docs/marine-weather-api) with Best Match selection. Model validity and retrieval timestamps are kept separate; no fixed model update frequency is claimed. Missing values display as unavailable and are not plotted as zero. Tap/drag the chart or use its slider to inspect values; hourly data is also available in a horizontally scrollable table.

Marine forecasts have a separate persistent cache with demo/live isolation. On refresh failure, cached information is marked saved/outdated. Settings persist metric/imperial units, onboarding completion, and an alert preference. Notification delivery is not connected; the preference does not schedule or send alerts. The location remains regional Lianga with no GPS access.

Without Firebase configuration, login, registration, and password reset display an explicit configuration message. There are no fake credentials or simulated successful logins. All demo statuses, beach names, coordinates, cantil flags, incidents, and history are fictional and visibly marked. Demo data is never a source of operational safety information.

The frontend uses Material 3, Provider, repository interfaces, and a persistent public snapshot cache. The prediction model remains outside the app. Cached snapshots retain the original source timestamp; fetching old data does not make it fresh. The default freshness threshold is 60 minutes and must be agreed with the model/backend team before live use.

## Firebase connection

1. Register the Android application (`com.example.waveguard`, unless changed) in your Firebase project.
2. Enable Email/Password in Firebase Authentication.
3. Create Firestore and prepare the public schema below. Deploy reviewed access rules before live use.
4. Copy `config/firebase.example.json` to a local `config/firebase.local.json` and fill in your project's Android app values. Use no service-account private keys in the client.
5. Run:

```powershell
flutter run --dart-define-from-file=config/firebase.local.json
```

`USE_FIREBASE=true` switches to live repositories. A startup failure shows unavailable services and does not silently substitute demo advisories. Firebase Auth restores authenticated sessions. Guests enter without creating an anonymous account. Live and demo caches use separate keys, and live keys are isolated by project ID.

Public registration creates an ordinary Firebase Auth user. Privileged roles must be set by a trusted backend using the signed `role` custom claim (`admin` or `mdrrmo`). The app never offers a privileged-role selector. These roles are displayed in the account sheet; this public Android frontend has no management tools. Server rules, rather than UI visibility, control actual access.

## Firestore public schema

The app only reads these records; ingestion and model output publishing belong to the backend. All fields below are required unless marked optional. Timestamps may be Firestore `Timestamp` values or ISO-8601 UTC strings, except `statusHistory.timestamp` must be a Firestore timestamp for the range query.

| Path | Fields |
| --- | --- |
| `public/current` | `status`: `safe`, `caution`, or `dangerous`; `recommendation`: string; `updatedAt`: timestamp; `waveHeight`: number (m); `windSpeed`: number (km/h); `wavePeriod`: number (s) |
| `beaches/{id}` | `name`, `description`: strings; `latitude`, `longitude`: numbers; `hasCantil`: boolean |
| `incidents/{id}` | `beachId`, `type`, `summary`: strings; `date`: timestamp; `latitude`, `longitude`: optional numbers |
| `statusHistory/{id}` | `status`: status enum string; `timestamp`: Firestore timestamp |

Incident reads are limited to the latest 100; history reads cover the last 72 hours with a maximum of 500 records. Screens offer 24/48/72-hour filters. Review these limits if backend publication frequency requires pagination. Document IDs are used for beaches and incidents. Only public summaries should be stored in these readable collections.

`firestore.rules` provides a public-read/client-write-denied baseline for this frontend. It is not automatically deployed. The backend can publish through trusted server credentials. Extend rules separately for any future management app. Do not store private incident details or account profiles in public collections.

## SOS configuration

The implemented action is **open the phone dialer after confirmation**. It does not automatically call, send SMS, report to a server, dispatch rescue, or transmit location.

Supply a verified Lianga MDRRMO contact using `MDRRMO_PHONE` in the local configuration file. With no valid configured number, the screen explains that emergency calling is unavailable and does not invent a number. When configured, the number is shown and selectable as a manual fallback. A failed dialer launch displays the number and an error.

No location or direct-call permission is requested. Test calling behavior with an approved test contact; do not place test calls to emergency services.

## Map and attribution

The preview uses `flutter_map` with OpenStreetMap standard raster tiles and visible contributor attribution. Markers come from the public repository, with no GPS access. Tile failure leaves the beach and incident lists usable and provides a map retry. No offline tile downloading or prefetching is implemented.

Review the [OpenStreetMap tile usage policy](https://operations.osmfoundation.org/policies/tiles/) before distribution. The tile URL, attribution text, and attribution URL can be changed using `MAP_TILE_URL`, `MAP_ATTRIBUTION`, and `MAP_ATTRIBUTION_URL`; use a provider appropriate for expected traffic. Change the tile user-agent package name if the Android application ID changes. Open-Meteo attribution is linked on advisory/account/detail/history views; the demo does not call Open-Meteo.

## Checks and builds

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Use a physical Android device to check keyboard scrolling, large fonts, map gestures, background/resume animation behavior, airplane-mode cache behavior, restored Firebase sessions, and dialer handoff. Firebase credentials and verified records are needed for live integration checks. Use your own release application ID and signing configuration before distribution; the starter release build still uses debug signing.

### Current environment limitations

The inspected workstation has no connected Android device. `flutter doctor` reports missing Android SDK command-line tools and an unknown Android license status. The APK build permission request was declined, so no APK or device smoke test was produced in this implementation session. Complete the local Android SDK setup and connect a device before running those checks.

Phone-sized UI previews can be generated by running `test/navigation_forecast_test.dart` with `--dart-define=CAPTURE_UI=true` and `--dart-define=QA_FONT_FILE=<path-to-Flutter-SDK>/bin/cache/artifacts/material_fonts/roboto-regular.ttf`. Images are saved under `build/qa/`. This checks rendered layout; it does not replace Android device testing.

References: [Firebase Auth for Flutter](https://firebase.google.com/docs/auth/flutter/start), [Firestore access rules](https://firebase.google.com/docs/firestore/security/rules-conditions), [flutter_map](https://pub.dev/packages/flutter_map), and [url_launcher](https://pub.dev/packages/url_launcher).
