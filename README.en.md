<p align="right">
  <a href="README.md">简体中文</a> · <strong>English</strong>
</p>

<h1 align="center">LevelUp</h1>

<p align="center">
  <strong>Level Up — “Daily quests, become a better you”</strong><br>
  A daily-quest app written with the <strong>native HarmonyOS NEXT</strong> stack (ArkTS + ArkUI), with every piece of data staying on this device.
</p>

<p align="center">
  <a href="https://github.com/montersy123/levelup-harmonyos/stargazers"><img src="https://img.shields.io/github/stars/montersy123/levelup-harmonyos?style=social" alt="GitHub stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/HarmonyOS%20NEXT-API%2012-1A1714?style=flat-square" alt="HarmonyOS NEXT API 12">
  <img src="https://img.shields.io/badge/ArkTS-ArkUI-E98425?style=flat-square" alt="ArkTS + ArkUI">
  <img src="https://img.shields.io/badge/build-passing-2F8F3C?style=flat-square" alt="build passing">
</p>

<p align="center">
  <img src="docs/screenshots/01-cover.png" width="44%" alt="Cover poster: a dark poster whose title shows “become a better you” in orange">
  <img src="docs/screenshots/02-today.png" width="44%" alt="Today's quests: greeting, streak, level ribbon and 6 quest cards">
</p>
<p align="center">
  <img src="docs/screenshots/03-detail.png" width="44%" alt="Quest detail: gradient hero, absolutely positioned XP stamp, micro-task checklist and CTA">
  <img src="docs/screenshots/04-stats.png" width="44%" alt="Statistics: week / month segments, XP bar chart and a floating detail tooltip">
</p>

`LevelUp` is a **purely local daily-quest / check-in app**: take on micro-tasks, accumulate XP, and watch your level and data trends.
It is written entirely with the **native HarmonyOS NEXT** stack — not a line of web code, no network, no uploads, no account.
Every color, font size, corner radius and motion curve lives in a named token, so components never hard-code them or fall back to the system's default theme color or font.

- **Four screens reproduced** — cover poster / today's quests / quest detail / statistics, plus “Library” and “Me” filled in from the same token set; all 5 slots in the bottom tab bar are tappable.
- **Check-ins and growth** — tick micro-tasks one by one, or complete a whole quest in one tap; XP accumulation, level conversion, an in-level progress bar, consecutive check-in days.
- **Statistics** — week / month segments, XP bar chart (press and hold or hover for a detail tooltip), weekly goal, three-cell grid, quest distribution — all **computed on the fly** from the real check-in records, with no derived values stored.
- **Data lives on this phone only** — stored in the app's private directory through `@kit.ArkData` Preferences: no network, no uploads, no account, no telemetry, no third-party SDK.
- **Token-driven visuals** — colors / font sizes / spacing / radii / motion are all frozen in [Theme.ets](entry/src/main/ets/common/Theme.ets), and components never hard-code color values.
- **Responsive** — phones fill proportionally, tablet / foldable content is capped at 680vp and centered, and the quest card grid switches between 2 / 3 / 4 columns.

## Quick start

### Requirements

| Item | Used by this project |
|---|---|
| DevEco Studio | 5.0 or later (this project syncs and compiles in DevEco Studio) |
| HarmonyOS SDK | API 26 (platformVersion 26.0.0.105) |
| hvigor | 6.26.8 (bundled with DevEco Studio) |
| Compile target | `compatibleSdkVersion: 5.0.0(12)`, `runtimeOS: HarmonyOS` |
| Target devices | Phone / foldable / tablet (`deviceTypes: phone, tablet, 2in1`) |
| Build artifact | `entry/build/default/outputs/default/entry-default-unsigned.hap` |

**Current build status**: `COMPILE RESULT` with no ERROR, `BUILD SUCCESSFUL`, an artifact of roughly 488 KB.
Only 1 informational warning is left (`getPreferences` in `Prefs.ets` may throw) — that call is already wrapped in
`try/catch` inside `AppStore.init`, which is the layer of guarantee a compiler cannot see across functions.

### Running it in DevEco Studio

1. **File → Open** and select this directory (the level that contains `oh-package.json5`).
2. Wait for **Sync Now** to finish.
3. **File → Project Structure → Signing Configs**, tick **Automatically generate signature** (requires signing in to a Huawei account).
   - The command line can already produce an **unsigned** HAP; installing on a real device still requires signing.
   - `products[0].signingConfig` in `build-profile.json5` points at a signing config named `default`;
     if yours uses a different name, change that line, or delete it and let DevEco Studio take over automatically.
4. Connect a real device or start an emulator, then click **Run**.

### Command-line build

```powershell
# Change these two lines to match the installation paths on your machine
$env:DEVECO_SDK_HOME = 'D:\Program Files\Huawei\DevEco Studio\sdk'
$node = 'D:\Program Files\Huawei\DevEco Studio\tools\node\node.exe'
$w    = 'D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js'

# Build
& $node $w --mode module -p product=default -p module=entry@default assembleHap --no-daemon

# Clean
& $node $w clean --no-daemon
```

`local.properties` records this machine's `sdk.dir` and `nodejs.dir`, and is already ignored in `.gitignore`;
on another machine, change it to your own paths, or simply delete it and let DevEco Studio regenerate it.

### Static self-check (no DevEco Studio needed)

```powershell
node tools/validate.js
```

Zero dependencies, run directly with Node. It checks 6 things: whether JSON / JSON5 parses, whether the resources
referenced by `$r()` all exist, whether imports between `.ets` files resolve and the symbols really are exported,
whether theme tokens are misspelled, **whether anything calls a static member that does not exist**, and whether the
files declared in `module.json5` / `main_pages.json` actually exist. Current result: **0 errors, 0 warnings**.

> Item 5 was added specifically for this project: in an environment without a compiler,
> “a method was deleted but something elsewhere still calls it” is the most insidious class of error. It cross-checks 198 static members across every `.ets` file.

## Pages and components

Every page and reusable component, and where it lives:

| Page / component | Implementation | Notes |
|---|---|---|
| Cover poster | [CoverView.ets](entry/src/main/ets/view/CoverView.ets) | Dark poster; the entry point into today's quests |
| Today's quests | [HomeView.ets](entry/src/main/ets/view/HomeView.ets) | Greeting + streak + level ribbon + 6 quest cards |
| Level ribbon | [LevelRibbon.ets](entry/src/main/ets/view/LevelRibbon.ets) | Progress bar computed from real XP, with a `fillbar` growth animation |
| Quest card / grid | [QuestGrid.ets](entry/src/main/ets/view/QuestGrid.ets) / [QuestCard.ets](entry/src/main/ets/view/QuestCard.ets) | Card background and icon background map one-to-one onto `--tile-*` |
| Quest detail | [DetailView.ets](entry/src/main/ets/view/DetailView.ets) | Gradient hero, absolutely positioned XP stamp, micro-task checklist, CTA |
| Statistics | [StatsView.ets](entry/src/main/ets/view/StatsView.ets) | Week / month segments, summary, goal card, three-cell grid, quest distribution |
| XP chart | [XpChart.ets](entry/src/main/ets/view/XpChart.ets) | Bar heights normalized to the highest value of the period; `getRectangleById` reads the real layout to compute the tooltip position, with edge clamping and a `.below` flip |
| Library / Me | [LibraryView.ets](entry/src/main/ets/view/LibraryView.ets) / [MeView.ets](entry/src/main/ets/view/MeView.ets) | Full quest catalogue and local-storage notes; identity block, level, lifetime XP, data management |
| Bottom tab bar | [TabBar.ets](entry/src/main/ets/view/TabBar.ets) | 5 slots: Today / Library / + / Stats / Me |
| Theme tokens | [Theme.ets](entry/src/main/ets/common/Theme.ets) | Colors / font sizes / spacing / radii / motion all named; components never hard-code color values |

### The extra pages: Library and Me

Library and Me share the same token set as the other pages, and all 5 tab bar slots are tappable and error-free:

- **Library**: the full quest catalogue + a note about local storage.
- **Me**: identity block, level, lifetime XP, per-category totals, data management (clear / restore demo data).
- **+ (the middle button)**: opens a “New quest” bottom sheet — because that feature is deliberately not built, the sheet says so explicitly.

## Directory structure

```
LevelUp/
├─ AppScope/
│  ├─ app.json5                    App-level config (bundleName / version / icon / name)
│  └─ resources/base/element/      App-level strings
├─ entry/                          Main module
│  ├─ build-profile.json5          Module build config
│  ├─ src/main/
│  │  ├─ module.json5              Module and EntryAbility declarations
│  │  ├─ resources/base/
│  │  │  ├─ element/               Strings, colors
│  │  │  ├─ media/                 Icons (tintable SVG + layered icon PNG)
│  │  │  └─ profile/main_pages.json
│  │  └─ ets/
│  │     ├─ entryability/EntryAbility.ets   Startup, immersive mode, local storage init
│  │     ├─ pages/Index.ets                 The single @Entry: routing + new-quest sheet
│  │     ├─ common/
│  │     │  ├─ Theme.ets          ★ Visual tokens (color/size/spacing/radius/motion/layout)
│  │     │  ├─ Prefs.ets          ★ Local storage wrapper (Preferences)
│  │     │  └─ Format.ets         Pure helpers such as thousands separators
│  │     ├─ model/Quest.ets       Domain model and enums
│  │     ├─ data/Data.ets         Quest catalogue + demo data
│  │     ├─ store/AppStore.ets    ★ State hub + derived metrics + persistence
│  │     └─ view/
│  │        ├─ CoverView.ets      Screen 1 · cover poster
│  │        ├─ HomeView.ets       Screen 2 · today's quests
│  │        ├─ DetailView.ets     Screen 3 · quest detail
│  │        ├─ StatsView.ets      Screen 4 · statistics
│  │        ├─ LibraryView.ets    Extra page · Library
│  │        ├─ MeView.ets         Extra page · Me
│  │        ├─ LevelRibbon.ets    Level ribbon (reusable component)
│  │        ├─ QuestCard.ets      Quest card (reusable component)
│  │        ├─ QuestGrid.ets      Quest card grid (2/3/4 columns, adaptive)
│  │        ├─ XpChart.ets        XP bar chart + floating detail tooltip
│  │        ├─ TabBar.ets         Bottom 5-slot tab bar
│  │        └─ Chip.ets           Pill chip
│  └─ src/ohosTest/                Test module skeleton
├─ docs/
│  ├─ design-full.png              Source image for the screen crops
│  └─ screenshots/                 The four cropped screen images
└─ tools/
   ├─ validate.js                  Project static validation
   ├─ design_shot_geom.py          Derive per-screen crop coordinates
   ├─ crop_design_shots.py         Crop single screens out of the full-page render
   ├─ gen_ui_icons.py              Generate UI icons
   └─ gen_icons.py                 Generate app icons
```

## Data and local storage

All state is stored in the app's private directory using **Preferences** from `@kit.ArkData`, with the keys below:

| Key | Type | Meaning |
|---|---|---|
| `totalXp` | number | Lifetime XP; the level is derived back from it |
| `streak` | number | Consecutive check-in days |
| `streakDate` | string | The last date that scored the streak, guaranteeing at most +1 per day |
| `days` | string (JSON) | `{"2026-02-18": {"steps": ["body-1", ...]}}`, completion records archived by date |
| `unlocked` | boolean | Whether the cover has been seen (decides which page a cold start lands on) |
| `seedDay` / `version` | number | First-install seeding marker, data version number |

To wipe everything, use “Me → Clear all local data”, or uninstall the app — there is no second copy of the data, and it never leaves this device.

### AppStorage holds immutable values only (important)

The UI refreshes by observing `AppStorage` through `@StorageLink`. **ArkUI cannot observe deep changes to nested objects**,
so check-in records are kept as a **JSON string** under `AppStore.K_DAYS_JSON`,
and every change produces a new string, which is what makes the components subscribed to it redraw.

Early versions stored `days` as an object and then mutated its fields in place; the result was that
**ticking a micro-task produced no reaction in the UI at all, and the checked state only appeared after leaving the page and coming back**.

To avoid this problem entirely, **every kind of state the UI needs to display also gets its own string mirror**;
views subscribe only to the mirrors, while the business methods still read and write the original values:

| Mirror key | Contents | Used by |
|---|---|---|
| `doneSteps` | ids of the steps completed today, comma-separated | detail page, quest cards, library |
| `earnedXpStr` / `readyXpStr` | XP earned today / XP still available today | detail page, home subtitle |
| `totalXpStr` | Lifetime XP | “Me” page |
| `streakStr` | Consecutive check-in days | page header badge, “Me” page |
| `loggedDays` | Number of days with check-in records | “Me” page |

Any action that changes visible state must end by calling `AppStore.refreshMirrors()` — it is already included in
`commit()` / `clearAll()` / `restoreSeed()` / `init()` / `bind()`.

### UI refresh mechanism (learned the hard way — read this first)

This area went through several revisions, and the final conclusion is:

> **In this project, `@State` local redraws are reliable; cross-component AppStorage change notifications are not.**

The pitfalls, in chronological order:

1. `days` was stored in `AppStorage` as a **nested object** and then mutated in place.
   ArkUI cannot observe deep changes → **ticking a micro-task produced no UI reaction at all, and it only showed after leaving and re-entering**.
   → Changed to a JSON string (a new value every time).
2. Still no good → **string mirrors** were added for every displayed state (`doneSteps`, `earnedXpStr`…),
   and views subscribe only to the mirrors.
3. Still no good (after clearing data you had to switch pages and come back) → a **data revision number** `dataRev` was added,
   subscribed to by the root component and passed down to each page, so that a parent redraw drags the whole subtree along,
   and the route branches were even made to depend on it in order to **force-rebuild** the entire page.
4. **The final working approach (current implementation)**:
   - Values are **read fresh**: `AppStore.persistedXp()` / `persistedStreak()` read local storage directly,
     bypassing `AppStorage` and avoiding reading a stale mirror you wrote yourself.
   - Actions that change data (clear / restore) simply increment a pure `@State` counter `refreshTick`;
     and `refreshTick` **appears directly in the `build` conditions**, guaranteeing it is on the dependency chain.
   - `LevelRibbon` is a standalone component that does not redraw with its parent, so it takes a `tick` parameter
     of its own and syncs the progress bar in `onDidBuild`.

In one sentence: **“tap a local state → the whole page recomputes”, with no cross-component channel in between.**

The retained string mirrors (`doneSteps` and friends) are still in use: the detail page, quest cards and library subscribe to them
to render check state — that path works (and the live check-in feedback is good too).

### Data rules

- **Store raw data only; always compute derived metrics on the fly.** Today's progress, the level progress bar, week / month statistics and
  the quest distribution percentages are all computed by `AppStore` from `days` + the quest catalogue,
  so a single check-in refreshes the home page, the detail page and the stats page together, and the data can never disagree.
- **XP only goes up, never down**: points are added the first time something goes from incomplete to complete; unticking does not take them back,
  which avoids negative balances and repeated farming.
- **Numbers stay self-consistent**: the starter values (level 14 / 1648 / 2480) are left untouched;
  the stats page treats the built-in weekly data as “the baseline before today”, so **today's bar =
  the 310 XP baseline + what you actually earned today**. That keeps the first-screen weekly total at 1,480,
  while check-ins still push the bar and the summary up in real time, so the two numbers always agree.
- **Day rollover**: `onForeground` refreshes the “today” date key, so the app still lands on the correct day after sitting in the background overnight.
- **Version migration**: a change in `version` resets only the check-in records (`days`) and
  **never touches the XP the user has already accumulated** — this was written incorrectly in an early implementation and has been fixed.
- The first launch writes the initial values; “Me → Restore demo data” can bring them back at any time.

## Visual implementation notes

### Fonts: one system family throughout

The UI uses a serif, a sans-serif and a monospace family. HarmonyOS devices do not ship `Noto Serif SC` / `Noto Sans SC` /
`IBM Plex Mono`, and an offline app should not depend on online fonts, so the `Font` class in
[Theme.ets](entry/src/main/ets/common/Theme.ets) points all three families at the built-in
**HarmonyOS Sans**, keeping the common font names as fallbacks:

```
serif: HarmonyOS Sans SC, Noto Serif SC, serif
sans : HarmonyOS Sans SC, Noto Sans SC, sans-serif
mono : HarmonyOS Sans SC, IBM Plex Mono, monospace
```

If you would rather use a serif / monospace family, put the `.ttf` files for those three fonts into
`entry/src/main/resources/rawfile/`, register them with `font.registerFont()` in
`EntryAbility.onWindowStageCreate`, and then change the names in `Font` to the registered names.

### Visual tokens

- **Colors**: `--stage #0e0d0c`, `--ink #1a1714`, `--accent #e98425`, `--accent-2 #ff6b3d`,
  `--tile-1…6`, `--line #ebe6dd`, `--muted #6c6660` and so on each land in the `Color` class.
- **Font sizes**: `54/42/30/18/15/14.5/14/13.5/12.5/11/10.5/10/9.5` are all collected in `FontSize`.
- **Spacing**: `2…40` is collected in `Space`; the card outer margin is 14 and the page padding 22.
- **Corner radii**: quest card / chart card 18, hero 24, ribbon 18, pill 999 and so on are collected in `Radius`.
- **Motion**: `fillbar .7s`, `grow .6s`, `transition .15s`, tooltip `.16s` are collected in `Motion`,
  implemented with `animateTo`; when the system turns on “reduce motion”, ArkUI shortens the durations automatically.
- **States**: hover (`HoverEffect`), pressed, focus, empty state and tooltip are all covered;
  loading / error states cannot occur with purely local data, so they were not faked.
- **Copy and values**: the greeting, the quest titles and subtitles, the micro-task steps and their XP, the Monday-to-Sunday XP bar values
  (180/240/310/160/270/200/120), the weekly goal 1480/2000 and the three-cell figures are all built in as demo data.

### Responsive

Nine viewport steps, starting at 360, all have a corresponding behaviour. Rather than building multiple layouts, the implementation:

- fills proportionally on phones (≤680vp);
- caps content at 680vp and centers it on tablets / unfolded foldables (`constraintSize({ maxWidth })`);
- switches the quest card grid between **2 / 3 / 4 columns** by width;
- shrinks the heading from 54 to 46 on wide screens (the equivalent of a 1200px breakpoint).

## Roadmap

**Done (UI + local data)**

- All 4 main pages implemented as native pages, with all 5 tab bar entries usable
- Micro-task ticking, one-tap completion of a whole quest, unticking
- XP accumulation, level conversion, in-level progress bar
- Consecutive check-in days
- Stats page: week / month switch, XP trend chart, touch / hover detail tooltip, weekly goal, three-cell grid, quest distribution (computed from real data)
- Local persistence + cold-start restore + day rollover
- Data management: clear local data, restore demo data (“Me” page)

**Not done (deliberately left open)**

- Creating / editing / deleting custom quests (the middle + button is currently an explanatory sheet)
- Quest reminders, notifications, system calendar integration
- Accounts, cloud sync, multiple devices
- Precise month-view data (currently a single demo step scaled proportionally from the weekly data)
- Home-screen cards / service cards (not in this release)

Issues and PRs on any of the above are welcome — especially custom quests, where `AppStore` and `Data.ets` already reserve the data structures.

## Acceptance checklist

Once it runs in DevEco Studio, walk through it in this order:

1. **First screen**: a fresh install → a dark cover poster, with “become a better you” in orange in the title.
2. **Enter today**: tap “Enter today's quests” at the bottom → the page transitions smoothly.
3. **Level ribbon**: level 14, `1648 / 2480`, progress bar at about 66%.
4. **Quest cards**: 6 cards, 2 columns, each with a different background (fitness orange-red / reading beige / listening light purple / diet light green / meditation pink / watching light blue).
5. **Check-in**: tap any card to open the detail → tick a step; the tick circle turns orange with a checkmark, the text gets a strikethrough, and the right side becomes “Completed”.
6. **XP**: go back to the home page and the ribbon's `1648` has increased; open the “Stats” page and today's bar and the summary have changed with it.
7. **Tooltip**: press and hold / hover any bar on the stats page and a dark detail card appears; tap the leftmost and rightmost bars and the card stays inside the card bounds.
8. **Week / month switch**: switch to “Month”; the bar count becomes 4 and the goal becomes 8000, with a smooth progress bar transition.
9. **Persistence**: fully kill the app and open it again; it **should go straight to “Today”** with the check-in records still there.
10. **Day rollover**: set the system date to tomorrow and open it; today's progress is zero and yesterday's records are kept.
11. **Empty state**: “Me” → Clear all local data → the level goes back to 1, progress is zero, and you return to the cover.
12. **Different sizes**: on an unfolded foldable / tablet, content is centered with a maximum width, the quest cards become 3–4 columns, and there is no horizontal scrolling.
13. **Fonts**: Chinese renders in HarmonyOS Sans (not Songti / not the default serif), and digits look monospaced.

## Regenerating icons and screenshots

All three are script-generated and repeatable, and require **Python 3 + Pillow** (`pip install pillow`):

```powershell
# 1) UI icons (tab bar / back / checkmark / trend / 6 category icons)
python tools/gen_ui_icons.py
# Once generated, tools/icon_check/contact-sheet.png shows every icon at a glance

# 2) App icons (app_icon / background / foreground / startIcon)
python tools/gen_icons.py

# 3) Screen images: crop the four single screens out of the full-page source image (reads docs/design-full.png)
python tools/crop_design_shots.py
python tools/crop_design_shots.py <another full-page render>   # use a different source image
```

The crop script emits two images per screen: `01-cover.png` (the version kept in the repository and used by this
README) and `01-cover-full.png` (not kept; ignored through `.gitignore`).

Paths inside the scripts are all relative to the repository root, so they run straight after cloning on any machine.

### Why the icons are PNG and not SVG

This is a pitfall this project ran into, written down to save future rework:

**HarmonyOS's `Image.fillColor` changes only the “fill color” and has no effect on stroke-based SVG.**
For icons written with `fill="none" + stroke="…"` (line art such as rings, plus signs and arrows),
`fillColor` does not color the stroke — it **floods the whole shape**:
a ring turns into a solid disc, a plus sign smears into a blob, and the “+” in the middle of the bottom tab bar becomes a black pie.

Because the icons are only 24px and only a fixed handful of colors are needed,
the least troublesome and most reliable approach is to **draw them directly as PNGs in Python in the colors required**,
which removes every use of `fillColor` (there is no `fillColor` call left anywhere in the project).

Each icon is drawn at 4× size and downscaled with LANCZOS, so the edges are smooth;
the palette is `#1a1714` (ink), `#6c6660` (muted) and `#e98425` (accent).

The tab bar's selected state is not colored with `fillColor` either; instead there are two sets, `*_on.png` (orange)
and `*.png` (gray), switched by selection state.

> When changing the palette, edit the color constants at the top of `tools/gen_ui_icons.py` and run it again.

## Contributing

Issues and PRs are welcome. Before submitting, at minimum:

1. `node tools/validate.js` passes (0 errors, 0 warnings).
2. It reaches `BUILD SUCCESSFUL` in DevEco Studio, and you have walked through the affected items in the acceptance checklist above.
3. **Do not hard-code color values / font sizes / spacing in new UI** — always add them to the tokens in [Theme.ets](entry/src/main/ets/common/Theme.ets) and use them from there;
   this is what keeps the UI visually consistent.
4. When changing visible state, mind the “UI refresh mechanism” section above: go through `AppStore`'s write entry points, and do not bypass the mirrors and `refreshTick`.
5. For documentation changes, please **update both `README.md` and [README.en.md](README.en.md)** so that the two stay consistent.

## License

[MIT](LICENSE) © 2026 montersy123

The code and documentation in this repository are open source under the MIT license: you are free to use, modify and distribute them, including commercially, as long as you keep the copyright and license notice.
