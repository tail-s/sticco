/// The four built-in themes, written in the same theme.json format user themes use.
enum BuiltinThemes {
    static let json: [String] = [standard, glass, paper, ink, pop]

    /// Opaque, calm, system-like. The app default.
    static let standard = #"""
    {
      "id": "default", "version": 1,
      "name": { "en": "Default", "ko": "기본", "ja": "デフォルト" },
      "defaultFontTheme": "system",
      "note": { "cornerRadius": 12, "material": "solid", "shadow": "soft", "titlebar": "compact",
                "stage": "pill", "checkbox": "round", "bullet": "•", "titleSize": 17, "bodySize": 14 },
      "light": {
        "notes": {
          "yellow": { "bg": "#FFF3B0", "ink": "#1F1A05" }, "peach": { "bg": "#FFDCCB", "ink": "#2A1208" },
          "mint": { "bg": "#D2F2E0", "ink": "#0B2416" }, "sky": { "bg": "#D6E8FF", "ink": "#0A1E33" },
          "lilac": { "bg": "#E7DDFF", "ink": "#1E1236" }, "graphite": { "bg": "#E6E6EA", "ink": "#1C1C1F" }
        },
        "stages": { "todo": "#5E5F66", "doing": "#1F63D0", "done": "#1A7D45", "custom": "#7E3DB8" },
        "chrome": { "window": "#F6F6F8", "sidebar": "#ECECF0", "card": "#FFFFFF", "text": "#1D1D1F",
                    "secondary": "#5E5E66", "accent": "#1F63D0", "separator": "#D8D8DE", "selection": "#DCE8FB" }
      },
      "dark": {
        "notes": {
          "yellow": { "bg": "#4D4419", "ink": "#FFF6CF" }, "peach": { "bg": "#4F2E22", "ink": "#FFE6DA" },
          "mint": { "bg": "#1D4231", "ink": "#DAF7E7" }, "sky": { "bg": "#1C3552", "ink": "#DCEBFF" },
          "lilac": { "bg": "#372A52", "ink": "#ECE3FF" }, "graphite": { "bg": "#36363C", "ink": "#F0F0F3" }
        },
        "stages": { "todo": "#A9AAB2", "doing": "#6AACFF", "done": "#5CD08E", "custom": "#C796F2" },
        "chrome": { "window": "#1E1E22", "sidebar": "#26262B", "card": "#2C2C31", "text": "#F2F2F5",
                    "secondary": "#A9A9B2", "accent": "#6AACFF", "separator": "#3A3A40", "selection": "#23406E" }
      }
    }
    """#

    /// Real translucency: the desktop shows through (Liquid Glass on macOS 26+).
    static let glass = #"""
    {
      "id": "glass", "version": 1,
      "name": { "en": "Glass", "ko": "글래스", "ja": "グラス" },
      "defaultFontTheme": "system",
      "note": { "cornerRadius": 16, "material": "glass", "shadow": "soft", "titlebar": "compact",
                "stage": "pill", "checkbox": "round", "bullet": "•", "titleSize": 17, "bodySize": 14 },
      "light": {
        "notes": {
          "yellow": { "bg": "#FFF1A66B", "ink": "#1F1A05" }, "peach": { "bg": "#FFD6C46B", "ink": "#2A1208" },
          "mint": { "bg": "#C9F2DC6B", "ink": "#0B2416" }, "sky": { "bg": "#CFE4FF6B", "ink": "#0A1E33" },
          "lilac": { "bg": "#E3D8FF6B", "ink": "#1E1236" }, "graphite": { "bg": "#E2E2E76B", "ink": "#1C1C1F" }
        },
        "stages": { "todo": "#5E5F66", "doing": "#1F63D0", "done": "#1A7D45", "custom": "#7E3DB8" },
        "chrome": { "window": "#F6F6F8", "sidebar": "#ECECF0", "card": "#FFFFFF", "text": "#1D1D1F",
                    "secondary": "#5E5E66", "accent": "#1F63D0", "separator": "#D8D8DE", "selection": "#DCE8FB" }
      },
      "dark": {
        "notes": {
          "yellow": { "bg": "#5A4E1A8C", "ink": "#FFF6CF" }, "peach": { "bg": "#5C33248C", "ink": "#FFE6DA" },
          "mint": { "bg": "#1F4A358C", "ink": "#DAF7E7" }, "sky": { "bg": "#1E3A5C8C", "ink": "#DCEBFF" },
          "lilac": { "bg": "#3D2E5C8C", "ink": "#ECE3FF" }, "graphite": { "bg": "#3A3A408C", "ink": "#F0F0F3" }
        },
        "stages": { "todo": "#A9AAB2", "doing": "#6AACFF", "done": "#5CD08E", "custom": "#C796F2" },
        "chrome": { "window": "#1E1E22", "sidebar": "#26262B", "card": "#2C2C31", "text": "#F2F2F5",
                    "secondary": "#A9A9B2", "accent": "#6AACFF", "separator": "#3A3A40", "selection": "#23406E" }
      }
    }
    """#

    static let paper = #"""
    {
      "id": "paper", "version": 1,
      "name": { "en": "Paper", "ko": "페이퍼", "ja": "ペーパー" },
      "defaultFontTheme": "hand",
      "note": { "cornerRadius": 3, "material": "solid", "shadow": "soft", "titlebar": "strip",
                "stage": "stamp", "checkbox": "inked", "bullet": "–", "titleSize": 20, "bodySize": 15 },
      "light": {
        "notes": {
          "yellow": { "bg": "#FFF1A8", "ink": "#2B2610" }, "peach": { "bg": "#FFD96B", "ink": "#3A1E10" },
          "mint": { "bg": "#CFEFD9", "ink": "#14301F" }, "sky": { "bg": "#CFE6F7", "ink": "#122838" },
          "lilac": { "bg": "#E3D7F5", "ink": "#2A1C40" }, "graphite": { "bg": "#D9D4CA", "ink": "#26231E" }
        },
        "stages": { "todo": "#4F5F73", "doing": "#A5481A", "done": "#2E7350", "custom": "#6F4596" },
        "chrome": { "window": "#FAF5EA", "sidebar": "#EFE5CF", "card": "#FFFBF2", "text": "#2D271F",
                    "secondary": "#665B4B", "accent": "#A5481A", "separator": "#DDD2BC", "selection": "#F2E2B8" }
      },
      "dark": {
        "notes": {
          "yellow": { "bg": "#4A4120", "ink": "#FBF3D0" }, "peach": { "bg": "#4D3022", "ink": "#FBE3D5" },
          "mint": { "bg": "#22402F", "ink": "#D8F3E2" }, "sky": { "bg": "#213A4D", "ink": "#D6EAF8" },
          "lilac": { "bg": "#3A2E4F", "ink": "#E9DFF8" }, "graphite": { "bg": "#3A3631", "ink": "#EDE8DF" }
        },
        "stages": { "todo": "#A9B6C6", "doing": "#F0A070", "done": "#84C9A2", "custom": "#C3A3E6" },
        "chrome": { "window": "#2A2520", "sidebar": "#221E1A", "card": "#332D27", "text": "#F1E9DA",
                    "secondary": "#BDB09A", "accent": "#F0A070", "separator": "#463E35", "selection": "#4A3F2E" }
      }
    }
    """#

    static let ink = #"""
    {
      "id": "ink", "version": 1,
      "name": { "en": "Ink", "ko": "잉크", "ja": "インク" },
      "defaultFontTheme": "mono",
      "note": { "cornerRadius": 0, "borderWidth": 1.5, "material": "solid", "shadow": "hard", "titlebar": "bar",
                "stage": "bracket", "checkbox": "bracket", "bullet": "–", "lineNumbers": true, "titleSize": 16, "bodySize": 13.5 },
      "light": {
        "notes": {
          "yellow": { "bg": "#FBF6DC", "ink": "#171613", "swatch": "#E0B83A" }, "peach": { "bg": "#FBEDE4", "ink": "#171613", "swatch": "#E07F57" },
          "mint": { "bg": "#E8F4EC", "ink": "#171613", "swatch": "#3F9A6C" }, "sky": { "bg": "#E6F0F8", "ink": "#171613", "swatch": "#3F84C8" },
          "lilac": { "bg": "#EFEAF7", "ink": "#171613", "swatch": "#8463C8" }, "graphite": { "bg": "#EEEDEA", "ink": "#171613", "swatch": "#6B6964" }
        },
        "stages": { "todo": "#575550", "doing": "#C43D12", "done": "#171613", "custom": "#575550" },
        "chrome": { "window": "#FBFAF7", "sidebar": "#F2F1EC", "card": "#FBFAF7", "text": "#171613",
                    "secondary": "#575550", "accent": "#C43D12", "separator": "#D3D1CB", "selection": "#F6E3DA" }
      },
      "dark": {
        "notes": {
          "yellow": { "bg": "#1A1917", "ink": "#F2F1ED", "swatch": "#E8C547" }, "peach": { "bg": "#1A1917", "ink": "#F2F1ED", "swatch": "#F09070" },
          "mint": { "bg": "#1A1917", "ink": "#F2F1ED", "swatch": "#5CC08C" }, "sky": { "bg": "#1A1917", "ink": "#F2F1ED", "swatch": "#5FA2E6" },
          "lilac": { "bg": "#1A1917", "ink": "#F2F1ED", "swatch": "#A68AE6" }, "graphite": { "bg": "#1A1917", "ink": "#F2F1ED", "swatch": "#9C9A94" }
        },
        "stages": { "todo": "#A8A59E", "doing": "#FF6A3D", "done": "#F2F1ED", "custom": "#BDBAB2" },
        "chrome": { "window": "#121211", "sidebar": "#1A1917", "card": "#1A1917", "text": "#F2F1ED",
                    "secondary": "#A8A59E", "accent": "#FF6A3D", "separator": "#34322E", "selection": "#3A2219" }
      }
    }
    """#

    static let pop = #"""
    {
      "id": "pop", "version": 1,
      "name": { "en": "Pop", "ko": "팝", "ja": "ポップ" },
      "defaultFontTheme": "rounded",
      "note": { "cornerRadius": 22, "material": "solid", "shadow": "lip", "titlebar": "floating",
                "stage": "stepper", "checkbox": "chunky", "bullet": "●", "progressBar": true, "titleSize": 19, "bodySize": 15 },
      "light": {
        "notes": {
          "yellow": { "bg": "#FFD84D", "ink": "#2A2000" }, "peach": { "bg": "#FFAC90", "ink": "#33140A" },
          "mint": { "bg": "#8DE5BD", "ink": "#0C2B1D" }, "sky": { "bg": "#93D2FF", "ink": "#0A2238" },
          "lilac": { "bg": "#B9A3FA", "ink": "#1C0F3D" }, "graphite": { "bg": "#34334A", "ink": "#F4F3FF" }
        },
        "stages": { "todo": "#34334A", "doing": "#3D50D6", "done": "#137A4A", "custom": "#B8245A" },
        "chrome": { "window": "#FFF7E8", "sidebar": "#FFEFD2", "card": "#FFFFFF", "text": "#1E1C2E",
                    "secondary": "#55526B", "accent": "#3D50D6", "separator": "#EADFC8", "selection": "#FFE7A3" }
      },
      "dark": {
        "notes": {
          "yellow": { "bg": "#E6BE2E", "ink": "#231A00" }, "peach": { "bg": "#E8896D", "ink": "#2A0F06" },
          "mint": { "bg": "#5FC99A", "ink": "#08241A" }, "sky": { "bg": "#5FB0EB", "ink": "#071B2E" },
          "lilac": { "bg": "#9479E8", "ink": "#150A30" }, "graphite": { "bg": "#4A4966", "ink": "#F4F3FF" }
        },
        "stages": { "todo": "#C9C7E0", "doing": "#8E9BFF", "done": "#4FD597", "custom": "#FF7AA8" },
        "chrome": { "window": "#1B1A33", "sidebar": "#232244", "card": "#2B2A4D", "text": "#F4F3FF",
                    "secondary": "#B8B5D6", "accent": "#8E9BFF", "separator": "#3A3960", "selection": "#3A3A7A" }
      }
    }
    """#
}
