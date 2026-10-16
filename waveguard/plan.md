# WaveGuard Android Frontend Plan

## Current scope

Build the Flutter Android frontend for regional marine information in Lianga, Surigao del Sur. UI code lives under `lib/`; `web/index.html` is only the web entry point. The frontend displays forecasts and stored advisories. The Python prediction backend, model training/evaluation, and desktop Admin/MDRRMO dashboards are separate workstreams.

## Entry flow

Splash (logo and loading indicator) -> Get Started -> Login / Create account / Continue as guest -> Home.

Get Started introduces marine conditions, forecasts, beaches, cantil warnings, and emergency options before login. Completion is saved locally; returning users can go directly to login, and restored authenticated sessions enter the main app. SOS remains accessible before login. Authentication, onboarding, and splash are outside the main navigation shell.

## Persistent bottom navigation

**Home | Forecast | Map | Beaches | More**

Each tab retains its own navigation stack and state. Main detail screens open inside the shell so the bottom navigation stays visible. Android Back closes the current detail screen, then returns to Home from another tab. The five destinations replace the previous Advisory/Map/History/SOS navigation. SOS is available from the top action and More instead of occupying a bottom destination.

## Screen inventory

| Screen | Features |
| --- | --- |
| Splash | WaveGuard logo and loading indicator |
| Get Started | Feature introduction, wave artwork, Get Started action before login |
| Login and account forms | Email/password, visibility toggle, validation, loading, errors, registration, reset, guest access |
| Home | Regional advisory, source timestamp, current conditions behind the advisory, quick access to weather, forecasts, map, beaches, and safety tips |
| Current Marine Weather | Regional forecast point, wave height, direction, period, valid time, retrieved time, refresh |
| Hourly Forecast | Next 48 hours, chart tap/drag and accessible slider selection, height/direction/period filters, hourly table |
| Daily Forecast | Seven-day chart and table, daily maximum height/period and dominant direction |
| Map | Regional marine forecast point, beach markers, incident/hazard markers, beach/incident details, tile failure fallback |
| Beaches | Beach list and detail pages, descriptions, static cantil warnings, available regional advisory, past incidents |
| Safety Tips | General preparation reminders, posted-warning guidance, official PAGASA link; verified local guidance pending |
| Settings | Persisted metric/imperial units, local marine-alert preference, fixed regional location information |
| About | App details, Open-Meteo source, separation of forecast and advisory model, demo-data disclosure |
| SOS & Emergency Contacts | Confirmed dialer handoff when a verified contact is configured; visible/manual fallback; no simulated emergency delivery |
| Historical Incident Map | Incident markers, type filter, summaries, and associated beach details |
| Advisory History | 24/48/72-hour stored regional statuses, accessible from More |

## Visual direction

Use the supplied reference as the marine-blue direction: deep-blue navigation, pale blue/white surfaces, clear weather values, and calm wave artwork. Keep status labels and icons alongside color. Preserve readable contrast, touch targets, text scaling, small-screen scrolling, keyboard access, and reduced-motion behavior. Continuous wave animation is limited to the entry screens and pauses when hidden/inactive.

## Data architecture

- Provider manages public-data, marine-forecast, session, and preference state.
- Widgets call service/repository interfaces; the UI does not run a classification model.
- Public advisories, beaches, incidents, and history use the existing demo or Firestore repository.
- Marine forecasts use a separate demo or Open-Meteo repository. Enable live marine reads with `USE_LIVE_MARINE=true`; this does not enable Firebase or produce a safety classification.
- Open-Meteo requests the fixed Lianga regional point, current marine conditions, hourly values, and seven daily aggregations. Best Match selects the upstream marine model; the app does not claim a fixed model resolution or update schedule.
- Keep model valid time, retrieved time, and advisory source-update time distinct. Missing marine values remain unavailable rather than zero.
- Cache public and marine snapshots separately. Isolate live data from fictional demo data. Retain original source timestamps on restored snapshots.
- Save onboarding completion, unit choice, and alert preference locally. Notification delivery is not connected; saving a preference does not schedule or send notifications.
- No GPS tracking or location permissions. Location preferences stay within the regional Lianga scope until additional verified forecast areas are approved.

## Shared parts and states

Reusable brand, status chip/card, cantil warning, beach tile, data notices, loading indicator, empty/error/retry states, timestamp formatter, and attribution footer.

Support initial loading, fresh data, saved/outdated data, refresh failure, offline with saved data, offline without data, empty lists, and unavailable fields. Never infer Safe from missing data or interpret a missing cantil flag as a safety guarantee. Forecast charts show actual supplied values and leave missing values unfilled.

## Integration and open decisions

- Configure Firebase Email/Password and Firestore before using real accounts or public records. Privileged roles come from signed backend claims, with server-enforced access rules.
- Supply verified beach coordinates, descriptions, cantil flags, public incident summaries, and MDRRMO contacts. Demo entries remain visibly fictional.
- Agree on the advisory freshness threshold; the implementation default is 60 minutes.
- Confirm a map provider suitable for distribution and retain required attribution. The preview uses OpenStreetMap tiles.
- Confirm alert-delivery requirements and infrastructure before enabling actual notifications.
- Confirm any expanded location choices, beach-specific forecasts, and management-dashboard scope separately.
- The implemented emergency action opens the phone dialer after confirmation. It does not dispatch rescue, send SMS, send location, or submit a backend report.
- The Random Forest backend, training data, model evaluation, and official local safety content must be completed/validated separately.

## Proposed development timeline

This is a proposed 12-week schedule, not a confirmed research-chapter timeline. Actual duration depends on data availability, approved features, and model evaluation. It is not a claim that the following work is already complete.

| Phase | Weeks | Work |
| --- | --- | --- |
| Planning and analysis | 1-2 | Finalize requirements, marine source, verified beach locations, and roles |
| UI/UX design | 2-3 | Mobile flows, navigation, and separately scoped management dashboards |
| Core development | 4-6 | Open-Meteo, Firebase, and Python backend integration |
| Additional features | 7-9 | Beach/cantil information, incident records, SOS contacts |
| Testing and evaluation | 10-11 | Data validation, functional tests, Random Forest evaluation, UAT |
| Deployment and documentation | 12 | Prototype package, installation steps, thesis documentation |

## Verification and delivery

Run `flutter analyze` and focused tests for onboarding, authentication, cached/stale data, forecast parsing and null values, unit persistence, chart interaction, nested navigation, and SOS confirmation. Review phone-sized renders and text scaling. Real-device testing must cover lifecycle, Android Back, network loss/recovery, map tiles, Firebase sessions, and verified dialer handoff.

APK build and device verification remain pending from the earlier session: the build permission request was declined, no Android device was connected, and the inspected SDK lacked command-line tools with unknown license status. See `docs/frontend-setup.md` for configuration and current limitations. Update Chapter 3 and Figure 8 after final flow approval.
