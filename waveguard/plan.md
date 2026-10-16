# WaveGuard Android Frontend Plan

## Scope

Build the public-facing WaveGuard Android app in Flutter. Replace the starter counter app in `lib/main.dart`; implement screens and shared code under `lib/`. `web/index.html` is not part of this Android work.

The frontend displays stored regional advisories, beaches, and incidents. It does not run the prediction model or calculate safety classifications. Admin and MDRRMO editing tools are outside this frontend scope.

## Navigation and account flow

- Short splash screen, followed by the login screen when there is no restored session.
- Login leads to the main shell with four bottom tabs: Advisory, Map, History, and SOS.
- Advisory is the default tab. Preserve each tab's state when switching tabs.
- Beach tiles and beach markers open the same beach detail screen.
- Use normal Android back navigation for detail and account screens.

Proposed defaults, pending confirmation:

- Guests can view public advisories and the map.
- SOS is accessible before login, including from the login screen.
- Anyone can register a User account; privileged accounts are provisioned separately.
- Use Firebase Authentication with email/password and Firestore for profiles and stored data.
- Roles come from trusted backend data and enforced access rules, never a public role selector. Admin/MDRRMO destinations require a separate scope decision.

## Screens

### Splash and login

- WaveGuard name and logo with calm blue styling.
- Email and password fields, password visibility toggle, Login button, Create account, and Forgot password.
- Inline field validation, authentication errors, and connection errors.
- Loading spinner on Login; prevent duplicate submissions.
- Guest entry and pre-login SOS access if the proposed defaults are approved.
- Create-account and password-reset screens with validation, progress, success, and failure states.
- Open-Meteo attribution at the bottom where appropriate.
- Slow wave animation using two or three sine-wave layers in a `CustomPainter`, driven by one repeating `AnimationController`.
- Place the painter inside a `RepaintBoundary`; keep animation updates separate from form rebuilds.
- Pause animation when its route is hidden or the app is inactive, dispose the controller, and respect reduced-motion preferences.
- Optional later enhancement: briefly raise the wave after successful login.

### Advisory — home

- Large Safe, Caution, or Dangerous card using a label, icon, and color together.
- Source update timestamp, recommendation, and key conditions: wave height, wind, and wave period, with units.
- Explicit note that the advisory is regional and not a separate assessment for each beach.
- Outdated badge when cached data exceeds the agreed freshness threshold or refresh fails.
- Beach list with names and static cantil (sudden-drop) warning indicators.
- Open-Meteo attribution.
- Refresh action with progress and failure feedback.

### Beach detail

- Beach name, description, and cantil warning when flagged.
- Current regional advisory and its update time for context.
- Past incidents associated with the beach, including date and type.
- Empty state when no incident records are available.

### Map

- Map centered on Lianga with markers for configured beaches.
- Beach markers open beach details.
- Incident pins open date/type summaries.
- No GPS tracking, user-location marker, or location permission request.
- Handle map loading and failure; retain access to beach information if map tiles cannot load.
- Choose the map package, tile provider, and required attribution before implementation.

### History

- Past regional statuses with timestamps and shared status chips.
- Start with a readable list; add a chart only if it improves the agreed presentation.
- History window remains undecided: 24, 48, or 72 hours.
- Decide whether to include incident records here in addition to beach details and map pins.
- Support loading, empty, error, and cached-data states.

### SOS

- Large red emergency action with a confirmation step.
- Visible emergency contact numbers as fallback options.
- Explain what the action will do before confirmation.
- Final action remains undecided: open the phone dialer, compose an SMS, or submit a backend message.
- Use verified MDRRMO contact details supplied for the project; do not invent numbers.
- Do not display “sent,” “received,” or “help is coming” without evidence supporting that state.
- If an external phone/SMS app cannot open, show a clear error and the fallback contact details.
- A global floating SOS button is optional; the SOS tab is always available in the main shell.

## Shared components

- App theme, typography, spacing, and consistent blue branding.
- Advisory status card and reusable status chip.
- Beach tile and cantil warning component.
- Outdated badge/banner and offline message.
- Loading indicator or skeleton, empty state, and error panel with Retry.
- Timestamp formatting, condition values with units, and attribution footer.
- Emergency confirmation dialog.

Use readable contrast, semantic labels, comfortable touch targets, and layouts that work with Android text scaling, small screens, and the keyboard.

## Data and state

Use a service/repository layer for reads and Provider-based state management as the proposed approach. Widgets render state and dispatch actions; they do not access Firestore directly.

Suggested models:

- `RegionalAdvisory`: status, recommendation, measured conditions, units, and source timestamp.
- `Beach`: ID, name, description, coordinates, and cantil flag.
- `Incident`: ID, beach association, coordinates when available, date, type, and public summary.
- `StatusHistoryEntry`: regional status and timestamp.
- `UserProfile`: authenticated user ID and trusted role.

Track these states explicitly:

| State | Display |
| --- | --- |
| First load | Loading UI; do not default to Safe |
| Fresh | Current stored advisory and source timestamp |
| Stale | Last saved advisory with Outdated badge and reason |
| Offline with cache | Cached information, source timestamp, and no-connection message |
| Offline without cache | Unavailable state with Retry; no fabricated advisory |
| Empty | Specific message for missing beaches, history, or incidents |
| Error | Clear failure message and retry action; retain prior data when available |

Persist the last successful public data snapshot for offline use. Keep source update time distinct from fetch time. Agree on the freshness threshold with the backend/model workflow. A successful fetch of old data must not mark it fresh.

Start with clearly labeled mock data behind repository interfaces, then connect the approved backend. Mock authentication must not be presented as a working account system.

## Suggested file structure

```text
lib/
  main.dart
  app.dart
  models/
  services/
  repositories/
  providers/
  screens/
    splash/
    auth/
    advisory/
    beach_detail/
    map/
    history/
    sos/
  widgets/
  theme/
```

## Implementation phases

1. Foundation: replace the starter screen, define theme and models, create repository interfaces and mock fixtures, and build the four-tab shell.
2. Advisory and beach detail: build reusable status/warning components and fresh, empty, error, stale, and offline presentations.
3. Login: implement the animated form, registration/reset flows, session handling, and approved guest behavior.
4. Map and History: add the chosen map integration, beach/incident interactions, and agreed history range.
5. SOS: implement the approved emergency action, confirmation, verified contacts, and failure handling.
6. Integration: connect authentication and public data services, add caching, and enforce role-based routing using backend-authorized roles.
7. Android verification: validate on an emulator and physical device, then prepare a reviewable build.

## Decisions to resolve

- Confirm guest permissions and which tabs/features require an account.
- Confirm pre-login SOS access and whether a floating SOS button is needed.
- Select the SOS delivery method and verify emergency contacts.
- Confirm email/password authentication, public registration, and privileged-account provisioning.
- Choose the Admin/MDRRMO interface and destinations separately.
- Select the history window and whether incidents also appear in History.
- Agree on source timestamps, refresh behavior, and the stale-data threshold.
- Choose the map provider and confirm beach coordinates, cantil flags, incident records, and attribution requirements.

Unresolved integrations can use clearly labeled prototypes, but must not imply working emergency delivery or authentication.

## Completion checks

- All four tabs and beach-detail navigation work with Android back behavior.
- Login validation, password visibility, progress, reset, and connection failures behave correctly.
- Guest entry and role routing match the confirmed policy.
- Advisory status always includes text and an icon; missing data never appears Safe.
- Fresh, stale, offline-with-cache, offline-without-cache, empty, and retry states are verified.
- Regional scope and cantil warnings remain clear across screens.
- Map interactions work without requesting location access.
- SOS confirmation, cancellation, approved action, and failure fallback are verified.
- Wave animation pauses when hidden/inactive and respects reduced motion.
- Small screens, text scaling, keyboard interaction, and touch targets are checked.
- Run `flutter analyze` and focused widget/state tests for navigation, freshness, authentication states, and SOS confirmation.
- Build and smoke-test the Android app. Update Chapter 3 and Figure 8 separately after the flow is finalized.
