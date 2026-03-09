# FYSS — F🤬🤬k YouTube Share Sheet

FYSS is a minimal iOS utility app that hijacks YouTube's terrible custom share sheet and sends video links to the app of your choice. It's a personal project, not something to share with the world or publish to the App Store.

## The problem

Apple built a perfectly good share sheet. YouTube decided to replace it with their own. Don't be evil my...

YouTube's custom share sheet limits sharing to a handful of hand-picked apps — the ones that signed whatever deal, or whose URL schemes YouTube bothered to hardcode. The app checks which of its VIPs are installed via `canOpenURL`, shows their icons, and largely ignores the rest of iOS's sharing infrastructure. Getting a video link to any other app requires tapping through multiple steps and menus, which is such a great experience and it shows so much respect for Users, I can't even.

YouTube's Telegram button, specifically, opens a `tg://` URL. If Telegram is not installed, the YouTube doesn't find a registered handler and does not show that button. _But what if "Telegram" was there?_

## The solution

FYSS pretends to be Telegram. Or Reddit.

By registering itself as a handler for `tg://`, FYSS intercepts YouTube's share action, extracts the video URL from the incoming link, and forwards it to whatever app you actually want to use — via a configurable target URL scheme. Zero extra taps once set up.

## Using FYSS with Unwatched

[Unwatched](https://github.com/fer0n/Unwatched) is a native iOS and visionOS YouTube client. It's great. It also has nothing to do with this, this is me hating YT for their b.s. share sheet. FYSS was originally built to feed videos to Unwatched.

Unwatched supports a direct URL scheme for adding videos to the queue — no Shortcut required:

```
unwatched://queue?url={url}
```

To add the video to the top of the queue instead of the end, append `&next=true`:

```
unwatched://queue?url={url}&next=true
```

Open FYSS and tap **Show me how to use FYSS with Unwatched** to configure either option automatically in one tap.

Again, FYSS is not affiliated with Unwatched.

## Using FYSS with any other app

Set the target URL using `{url}` as a placeholder for the video link:

```
myapp://open?url={url}
```

FYSS replaces `{url}` with the percent-encoded YouTube URL and opens the result. You can append any extra parameters after the placeholder:

```
myapp://open?url={url}&autoplay=true
```

If the target URL contains no `{url}` placeholder, FYSS falls back to appending the link at the end (legacy behaviour, for backwards compatibility).

## What if I have Telegram installed?

If Telegram is installed, iOS will route `tg://` URLs to Telegram and FYSS will never see them.

In that case, pick a different YouTube VIP whose app you don't have installed. Reddit is another one we know of (`reddit://`). To swap the intercepted scheme, open `FYSS/Info.plist` in Xcode and replace `tg` with your chosen scheme under `CFBundleURLSchemes`.

We are only aware of `tg://` and `reddit://` as YouTube's chosen few. It is entirely possible that Google has extended further privileges to other apps. If you find one, open an issue.

## Origin

This app was conceived by someone who hates when companies mess with system defaults, and implemented entirely by [Claude Code](https://claude.ai/claude-code) (Anthropic) in a little more than one hour _(tweaking this readme took longer than prompting it into existence)_.

Oh, the wonderful icon, that's human made and it shows.

FYSS is not affiliated with YouTube (shocker, I know)), Telegram, or Unwatched. It exists because YouTube wanted to replace iOS's native share sheet, and someone thought for many, many years that was a bad evil stupid idea, and AI makes building funny things on a Sunday night trivial.

## Requirements

- A recent Xcode
- An Apple Developer account (free tier is sufficient)
- An iPhone or iPad running iOS 18 or later
- Developer Mode enabled on the device (Settings → Privacy & Security → Developer Mode)

## Building and installing

FYSS is not distributed on the App Store. Don't do that. You build and install it directly from Xcode onto your own device.

1. Clone or download this repository
2. Open `FYSS.xcodeproj` in Xcode
3. Select the **FYSS** target → **Signing & Capabilities**:
   - Set **Team** to your personal Apple Developer account
   - Change **Bundle Identifier** from `com.yourteam.FYSS` to something unique (e.g. `com.yourname.FYSS`)
4. Connect your device and press **⌘R**

## License

Public domain. Do whatever you want with it. See [LICENSE](LICENSE) for the legalese ([The Unlicense](https://unlicense.org)).

## URL schemes registered

| Scheme   | Purpose                                              |
|----------|------------------------------------------------------|
| `tg://`  | Intercepts YouTube's Telegram share action           |
| `fyss://`| FYSS's own scheme, reserved to avoid conflicts       |
