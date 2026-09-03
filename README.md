# Userscript Browser for iOS

A tiny iOS browser that can import `.js` / `.user.js` files and inject them into matching webpages.

## Features
- Import any JavaScript/userscript file using the iOS Files picker.
- Parses `@name`, `@match`, and `@include`.
- Enable/disable scripts individually.
- Persists imported scripts.
- Runs matching scripts after each page finishes loading.
- Includes basic compatibility shims for:
  - `GM_addStyle`
  - `GM_getValue`
  - `GM_setValue`
  - `GM_deleteValue`
  - `GM_listValues`
  - `GM_openInTab`
  - promise-style `GM.*` versions for common value/style APIs

## Limitations
This is not a full Tampermonkey clone. Scripts that depend on advanced Tampermonkey APIs such as
`GM_xmlhttpRequest`, menu commands, downloads, notifications, cookie APIs, or privileged cross-origin
requests will need additional native bridges.

## Build
1. Open `UserScriptBrowser.xcodeproj` in Xcode on macOS.
2. Select the app target.
3. Under Signing & Capabilities, choose your Apple Developer team.
4. Change the bundle identifier if Xcode says it is already taken.
5. Build to your iPhone, or Archive and export an IPA.

The IPA must be signed with your own Apple signing credentials before installation.
