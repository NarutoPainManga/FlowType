# FlowType App Store Connect Submission Pack

Last updated: April 24, 2026

This document turns FlowType's launch materials into a field-by-field App Store Connect checklist.

## Current status

- App name candidate: `FlowType`
- Bundle identifier detected from the built app: `Kr3-Precision-Creations.FlowType`
- Privacy Policy URL: publish from `docs/privacy.html`
- Terms URL: publish from `docs/terms.html`
- Support URL: publish from `docs/support.html`
- Seeded screenshots generated locally in `marketing/screenshots`

## App information

Use these values unless you decide to rebrand before submission.

- Name: `FlowType`
- Subtitle: `Turn speech into polished writing`
- Category: `Productivity`
- Secondary category: leave blank unless you want `Business`
- Content rights: confirm you own the branding and app assets

Apple limits the app name to 30 characters and the subtitle to 30 characters.

## Promotional text

`Record a thought, review the result, and turn it into clear writing for email, Slack, notes, and task lists.`

## Keywords

`dictation,voice notes,transcription,writing,productivity,email,notes,slack`

## Description

FlowType helps you turn rough voice notes into clean, send-ready writing.

Speak naturally, then review polished text before you copy or share it anywhere on your iPhone. FlowType is built for busy workdays when you need to capture a thought quickly and turn it into something clear.

Use FlowType to:

- turn meeting follow-ups into polished messages
- clean up Slack updates before sending
- draft emails from speech instead of typing
- capture task lists and notes while you are on the move
- quickly rewrite text to be shorter, friendlier, more professional, or formatted as bullets

Why people use FlowType:

- fast capture without typing first
- review before sending
- simple copy and share flow
- recent drafts saved on device

FlowType only records when you tap Start Dictation. Your voice is processed securely in the cloud to create polished text.

## Review notes

Paste this into the App Review notes field:

`FlowType records audio only after the user taps Start Dictation. Audio is sent securely to our backend for transcription and text polishing, then returned for review before the user copies or shares it. Anonymous authentication is created automatically for app functionality. Users can delete their anonymous account in Help & Status > Delete Anonymous Account.`

## URLs

Use public hosted URLs, not local files.

Recommended GitHub Pages URLs after publishing:

- Privacy Policy: `https://narutopainmanga.github.io/FlowType/privacy.html`
- Terms of Service: `https://narutopainmanga.github.io/FlowType/terms.html`
- Support: `https://narutopainmanga.github.io/FlowType/support.html`

Before submission, replace placeholder contact text in the docs pages with a real public support email or website.

## Screenshots

Current raw screenshots live in:

- `marketing/screenshots/onboarding.png`
- `marketing/screenshots/home.png`
- `marketing/screenshots/review.png`
- `marketing/screenshots/help.png`

Current captured size:

- `1206 x 2622`

Recommended use:

- Keep these as source captures.
- Add App Store marketing text in a design tool before submission.
- Generate additional sizes if Apple requires another device family for your target rollout.

## App privacy draft

This section is an informed recommendation based on the current codebase and deployed backend. You should confirm it against your real retention and logging practices before publishing.

### Tracking

- Recommended answer: `No, we do not use data for tracking.`

### Data types likely to disclose

Recommended conservative disclosure:

- `Audio Data`
  - Purpose: `App Functionality`
  - Linked to user: `Yes`
- `Other User Content`
  - Purpose: `App Functionality`
  - Linked to user: `Yes`
- `User ID`
  - Purpose: `App Functionality`
  - Linked to user: `Yes`

Why:

- FlowType transmits voice recordings for processing.
- FlowType transmits transcript/polished-text content for processing.
- FlowType creates anonymous accounts and usage records tied to an account identifier.

### Data types that may be optional or unnecessary to disclose

These depend on actual retention:

- `Product Interaction`
- `Diagnostics`
- `Other Usage Data`

If the backend does not retain this information in readable form longer than needed to service the request, Apple’s privacy guidance suggests it may not count as collected.

### Important confirmation point

If your services or third-party partners retain audio, transcript text, or request logs beyond real-time servicing, disclose them conservatively.

## Account deletion

Apple requires in-app account deletion for apps that create accounts, including automatically created guest or anonymous accounts.

FlowType now supports this through:

- in-app delete control in `Help & Status`
- deployed Supabase `account` Edge Function

## Accessibility

Apple now supports App Accessibility labels in App Store Connect. These appear on supported Apple OS versions and are worth filling out even if still voluntary.

Likely FlowType answers worth evaluating:

- Supports VoiceOver: verify manually before claiming
- Supports Larger Text: likely yes if standard SwiftUI text scales acceptably
- Supports Sufficient Contrast: verify manually
- Supports Reduced Motion: likely not applicable unless you add motion-heavy UI later

Do not claim accessibility support you have not tested on device.

## Common rejection risks for FlowType

- Placeholder support or privacy contact info left in public pages
- Metadata claiming keyboard-like or system-wide behavior the app does not have
- Broken external links in the app or App Store listing
- Account deletion not behaving clearly during review
- Privacy answers that under-disclose cloud processing
- Screenshots that look unfinished or inconsistent with the real product

## Submission order

1. Publish GitHub Pages for the `docs/` folder.
2. Replace placeholder contact text with a real public contact method.
3. Upload polished screenshots.
4. Enter App Privacy responses.
5. Fill App Accessibility labels only for features you have verified.
6. Upload build to TestFlight.
7. Test on a real iPhone once more.
8. Submit with the review notes above.
