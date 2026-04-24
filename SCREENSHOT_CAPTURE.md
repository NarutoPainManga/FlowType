# FlowType Screenshot Capture

FlowType now supports seeded screenshot scenes so App Store screenshots can be generated without burning API credits.

## Supported scenes

- `onboarding`
- `home`
- `review`
- `help`

## One-command capture

Run:

```bash
zsh /Users/pain/Documents/flowtype/FlowType/scripts/capture_app_store_screenshots.sh
```

By default, screenshots are saved to:

`/Users/pain/Documents/flowtype/FlowType/marketing/screenshots`

## Change the simulator

Set `DEVICE_NAME` before running:

```bash
DEVICE_NAME="iPhone 17 Pro Max" zsh /Users/pain/Documents/flowtype/FlowType/scripts/capture_app_store_screenshots.sh
```

## Notes

- The script uses mock services and seeded app state.
- It resets local app state before each capture.
- It captures clean product-marketing screens instead of real user content.
- If you want App Store sizes for multiple devices, run the script once per simulator size.
