# LexIndia-AI --- UI/UX Specification

## Design direction

Professional Legal. Light mode default, with dark and system modes.
Reading comfort is the highest priority. Users include law students/exam
aspirants and the general public.

## Colors

-   Legal navy `#14253F`: identity, headings, selected controls.
-   Ivory `#F8F5EE`: main reading background.
-   Antique gold `#B58B3B`: restrained accents and primary actions.
-   White `#FFFFFF`: cards/surfaces.
-   Body text `#354153`.
-   Divider `#E4E8E4`. Define equivalent dark-theme colors with adequate
    contrast. Gold should not be used for large text backgrounds.

## Typography and spacing

Use a readable Latin font and a Telugu-capable font such as Noto Sans
Telugu. Define styles for screen titles, section headings, body text,
metadata, and controls. Respect system font scaling. Use consistent
spacing based on an 8-point rhythm, restrained borders/radii, and
accessible tap targets. Avoid dense paragraphs and decorative
typography.

## Navigation

Primary destinations: Home, Browse, Saved, Settings. Section Details is
a secondary route. Preserve search query/page on back navigation and
keep bookmark state synchronized.

## Home

1.  Compact app identity.
2.  Short introduction.
3.  Prominent search.
4.  Browse BNS shortcut.
5.  Recent sections.
6.  Saved-sections shortcut/preview.
7.  BNS collection label. Do not fetch all full legal text for the home
    screen.

## Browse/search

Show title, search field, clear action, result count, section cards,
pagination/load-more, loading/empty/error/retry states. Use server-side
pagination. Debounce search, reset page for new queries, prevent stale
results, and preserve search state on return. Numeric queries follow
exact-number backend behavior.

## Section Details

Show back control, section number, heading, English/Telugu selector,
bookmark, copy/share actions, full legal text, and source/status notice
when available. Use the actual detail and language endpoints. Show
progress during switching, preserve reading position where practical,
and explain missing Telugu. Never show English under a Telugu label or
claim legal verification without evidence. Long text must not overflow
or freeze.

## Saved

List bookmarked section numbers/headings; allow open/remove; provide
empty state; persist locally; keep items when server requests
temporarily fail.

## Settings

Default language, Light/Dark/System, About, legal disclaimer,
source/translation limitations, app version. Persist preferences
locally.

## Shared states

-   Loading: progress/skeleton; avoid indefinite spinner.
-   Empty search: explain no matches and offer clear.
-   Network failure: explain and offer retry.
-   Missing section: clear not-found state.
-   Missing Telugu: explain and offer explicit English switch.
-   Empty Saved: explain bookmarking.
-   Copy/share: confirm only after success.
-   Offline: local preferences/bookmarks remain available; server
    content is clearly unavailable.

## API integration UX

Configured centrally via `AppConfig` (`frontend/lib/core/config/app_config.dart`):
- Local web/desktop default: `http://127.0.0.1:8000`
- Android emulator default: `http://10.0.2.2:8000`
- Custom/Production builds: `flutter build web --dart-define=API_BASE_URL=https://<domain>`
- Physical device testing: Pass host LAN IP via `--dart-define=API_BASE_URL=http://<host-ip>:8000`

## Accessibility & Responsive Verification

- **Viewports**: Tested cleanly at 320px (compact mobile), 390px (standard phone), 768px (tablet), and 1200px (desktop wide).
- **Text Scaling**: Tested under 1.5x accessibility scaling with zero `RenderFlex` overflow errors.
- **Touch Targets**: All interactive buttons meet or exceed 48dp height/width.
- **Semantics**: Clear tooltips and semantic labels on all icon-only buttons (Bookmarks, Previous/Next navigation, Clear search, Copy).
- **Color Contrast**: Legal navy `#14253F` on Ivory `#F8F5EE` meets WCAG AAA standards for body text; Dark theme surfaces maintain high contrast.

## Visual quality bar

Calm, readable, consistent, legal-reference oriented. Avoid generic
dashboard layouts, excessive decoration, flashy gradients, and inert
placeholder controls. All controls are wired to functional handlers or truthful status dialogs.
