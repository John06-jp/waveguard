# Reference-aligned screen enhancement

The latest supplied screen sheet is the visual reference. This refresh keeps the existing screens and five-tab navigation while matching its compact blue headers, coastal splash and Home, location strip, white quick-access tiles, current-weather panel, forecast charts/tables, beach thumbnails, icon-led settings, and emergency-contact rows. Get Started still precedes login on first launch.

The background is illustrative, not a verified photograph of Lianga. Beach thumbnails are labeled Illustration. The wave logo is drawn in Flutter code. Demo values remain marked as samples. The map uses actual configured tiles and data markers rather than a fabricated weather heatmap. Model source information remains Best Match when appropriate, and Safe is never inferred from a wave-height reading.

Emergency contacts use verified configured numbers only. Additional optional build defines are `COAST_GUARD_PHONE`, `PNP_PHONE`, and `HEALTH_UNIT_PHONE`, alongside `MDRRMO_PHONE`. Missing contacts display Verified contact pending and cannot place calls. All configured calls require confirmation and open the external dialer.

## Generated background asset

- Tool: built-in `image_gen.imagegen`, generation mode.
- Project asset: `assets/images/coastal-background.png`.
- Final prompt:

> Create one photorealistic tropical Philippine coastline photograph as a background asset for a marine weather mobile application. Wide landscape 3:2 composition. A lush green headland and palms along the left and far middle horizon, a curved pale beach receding into the distance, rich deep blue ocean in foreground bottom, turquoise water near shore, bright blue sky with soft clouds in upper third. Slight elevated shoreline viewpoint, realistic calm small surf, natural clear daylight, sharp but not oversaturated. No people, boats, buildings, text, logos, maps, UI, watermarks, borders, or collage. This is illustrative scenery and must not claim to depict a specific real beach. Useful for cropping as a tall splash background and a wide home banner.

Phone preview PNGs are generated under `build/qa/` by the opt-in capture workflow described in `docs/frontend-setup.md`. These render checks supplement the widget tests; Android device verification remains pending.
