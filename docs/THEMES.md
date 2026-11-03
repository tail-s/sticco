# Writing a theme

A Sticco theme is a single `theme.json`. The five built-in themes (Default, Glass, Paper, Ink, Pop) use exactly the same
format — see [`BuiltinThemes.swift`](../Sources/Sticco/Theme/BuiltinThemes.swift) for complete examples.

## Install

1. Settings → Appearance → **Open Themes Folder** (`~/Library/Application Support/Sticco/Themes`).
2. Add a folder containing your `theme.json`, e.g. `Themes/forest/theme.json`.
3. Reopen Settings. A theme whose `id` matches a built-in replaces it.

## Format

```jsonc
{
  "id": "forest",                       // unique, lowercase
  "name": { "en": "Forest", "ko": "숲", "ja": "フォレスト" },
  "defaultFontTheme": "serif",          // system | plex | rounded | hand | serif | mono
  "note": {
    "cornerRadius": 12,
    "titlebar": "compact",              // strip | compact | bar | floating
    "stage": "pill",                    // stamp | pill | bracket | stepper
    "checkbox": "round",                // inked | round | bracket | chunky
    // optional ↓ (defaults shown)
    "material": "solid",                // solid | glass (translucent, blurs the desktop)
    "shadow": "soft",                   // soft | hard (offset ink) | lip (toy-block bottom) | none
    "borderWidth": 0,
    "bullet": "•",
    "lineNumbers": false,
    "progressBar": false,
    "titleSize": 17,
    "bodySize": 14
  },
  "light": {
    "notes": {                          // yellow, peach, mint, sky, lilac, graphite
      "yellow": { "bg": "#FFF1A8", "ink": "#2B2610", "swatch": "#E0B83A" }   // swatch optional
    },
    "stages": { "todo": "#4F5F73", "doing": "#A5481A", "done": "#2E7350", "custom": "#6F4596" },
    "chrome": { "window": "#FAF5EA", "sidebar": "#EFE5CF", "card": "#FFFBF2", "text": "#2D271F",
                "secondary": "#665B4B", "accent": "#A5481A", "separator": "#DDD2BC", "selection": "#F2E2B8" }
  },
  "dark": { /* same shape as light */ }
}
```

Colors are `#RRGGBB` or `#RRGGBBAA`. Keep text (`ink`, `text`, `secondary`) at a 4.5:1 contrast ratio against its background.

## Font themes

Font themes are separate from themes (users can mix them). Each maps Latin, Korean and Japanese to a list of candidate
families; the first one installed wins. Bundled fonts live in `Resources/Fonts` (run `scripts/fetch-fonts.sh`), and
users can drop extra fonts into `~/Library/Application Support/Sticco/Fonts`.
