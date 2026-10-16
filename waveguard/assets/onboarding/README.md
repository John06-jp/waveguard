# WaveGuard onboarding PNG assets

24 separate PNG files created from the onboarding and asset-showcase references. Ocean photographs are illustrative scenery, not verified Lianga photographs.

Backgrounds, illustrations, the splash overlay, and cloud overlay were generated individually with the built-in imagegen tool. Logo, icon, button, indicator, and wave-divider assets were exported individually from Flutter code. The exact image-generation prompts are in `generation-prompts.json`.

Native Flutter buttons and text are used in the running onboarding flow for accessibility. The button PNGs are supplied as reusable design assets. The MP4 and Lottie examples were excluded because the selected scope was every PNG.

| Asset | Actual pixel size |
| --- | --- |
| [app/app_icon.png](app/app_icon.png) | 1024 x 1024 |
| [app/app_icon_dark.png](app/app_icon_dark.png) | 1024 x 1024 |
| [backgrounds/onboarding_bg1.png](backgrounds/onboarding_bg1.png) | 941 x 1672 |
| [backgrounds/onboarding_bg2.png](backgrounds/onboarding_bg2.png) | 941 x 1672 |
| [backgrounds/onboarding_bg3.png](backgrounds/onboarding_bg3.png) | 941 x 1672 |
| [backgrounds/onboarding_bg4.png](backgrounds/onboarding_bg4.png) | 941 x 1672 |
| [effects/clouds_overlay.png](effects/clouds_overlay.png) | 1672 x 941 |
| [effects/wave_ribbon.png](effects/wave_ribbon.png) | 1920 x 1080 |
| [effects/wave_splash.png](effects/wave_splash.png) | 1672 x 941 |
| [icons/icon_conditions.png](icons/icon_conditions.png) | 512 x 512 |
| [icons/icon_map.png](icons/icon_map.png) | 512 x 512 |
| [icons/icon_safety.png](icons/icon_safety.png) | 512 x 512 |
| [icons/icon_welcome.png](icons/icon_welcome.png) | 512 x 512 |
| [icons/wave_logo.png](icons/wave_logo.png) | 512 x 512 |
| [illustrations/illustration_map.png](illustrations/illustration_map.png) | 1254 x 1254 |
| [illustrations/illustration_safety.png](illustrations/illustration_safety.png) | 1254 x 1254 |
| [illustrations/illustration_wave.png](illustrations/illustration_wave.png) | 1024 x 1536 |
| [illustrations/illustration_weather.png](illustrations/illustration_weather.png) | 1254 x 1254 |
| [ui/btn_back.png](ui/btn_back.png) | 600 x 200 |
| [ui/btn_get_started.png](ui/btn_get_started.png) | 600 x 200 |
| [ui/btn_next.png](ui/btn_next.png) | 600 x 200 |
| [ui/btn_skip.png](ui/btn_skip.png) | 300 x 100 |
| [ui/card_wave.png](ui/card_wave.png) | 1080 x 300 |
| [ui/indicator_dots.png](ui/indicator_dots.png) | 400 x 80 |

## Re-export code assets

Run `flutter test tool/export_onboarding_assets_test.dart --dart-define=EXPORT_FONT_FILE=<Flutter-SDK>/bin/cache/artifacts/material_fonts/roboto-regular.ttf` from the project root. This re-exports the 14 deterministic logo/icon/UI assets; generated photographs and illustrations stay untouched.

The runtime flow is Welcome -> Monitor Marine Conditions -> Explore Coastal Areas -> Stay Informed/Stay Prepared -> Login. Skip completes onboarding immediately. Back and Next navigate slides, and completion is saved on the device.
