#!/usr/bin/env bash
# Generates .colorset folders inside Assets.xcassets
# Run from repo root: bash scripts/gen_colors.sh

ASSETS="BirthdayCalendar/Resources/Assets.xcassets"

make_color() {
  local name="$1"
  local light_r="$2" light_g="$3" light_b="$4"
  local dark_r="$5"  dark_g="$6"  dark_b="$7"
  local alpha="${8:-1.0}"

  local dir="$ASSETS/$name.colorset"
  mkdir -p "$dir"
  cat > "$dir/Contents.json" <<EOF
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": { "alpha": "$alpha", "red": "$light_r", "green": "$light_g", "blue": "$light_b" }
      },
      "idiom": "universal"
    },
    {
      "appearances": [{ "appearance": "luminosity", "value": "dark" }],
      "color": {
        "color-space": "srgb",
        "components": { "alpha": "$alpha", "red": "$dark_r", "green": "$dark_g", "blue": "$dark_b" }
      },
      "idiom": "universal"
    }
  ],
  "info": { "author": "xcode", "version": 1 }
}
EOF
}

# ─── GRADIENT THEME ─────────────────────────────────────────────────────────
# Logo palette: hot-pink #FF5CAD → purple #7B3FBE
# Accent: orange #FF8C1A, secondary: teal #25C281, fav: gold #FFD140
make_color GradBgTop          "1.00" "0.36" "0.68"   "0.86" "0.22" "0.54"   # hot pink
make_color GradBgBottom       "0.48" "0.25" "0.75"   "0.36" "0.15" "0.62"   # purple
make_color GradSurface        "0.55" "0.28" "0.80"   "0.42" "0.18" "0.68"
make_color GradCardTop        "1.00" "1.00" "1.00"   "1.00" "1.00" "1.00"   # white overlay
make_color GradCardBottom     "0.92" "0.88" "1.00"   "0.90" "0.85" "1.00"   # soft lavender
make_color GradNavBar         "0.90" "0.28" "0.60"   "0.76" "0.18" "0.48"
make_color GradTextPrimary    "1.00" "1.00" "1.00"   "1.00" "1.00" "1.00"
make_color GradTextSecondary  "1.00" "0.88" "0.95"   "1.00" "0.82" "0.92"
make_color GradTextTertiary   "1.00" "0.70" "0.85"   "1.00" "0.64" "0.80"
make_color GradAccent         "1.00" "0.55" "0.10"   "1.00" "0.60" "0.18"   # orange
make_color GradAccentSecondary "0.15" "0.76" "0.51"  "0.18" "0.82" "0.56"   # teal
make_color GradFav            "1.00" "0.82" "0.25"   "1.00" "0.87" "0.30"   # gold

# ─── LIQUID GLASS THEME ───────────────────────────────────────────────────────
make_color GlassBgTop         "0.55" "0.72" "0.95"   "0.05" "0.10" "0.22"
make_color GlassBgBottom      "0.72" "0.88" "1.00"   "0.08" "0.15" "0.32"
make_color GlassTextPrimary   "0.05" "0.05" "0.10"   "0.95" "0.95" "1.00"
make_color GlassTextSecondary "0.25" "0.25" "0.35"   "0.70" "0.70" "0.82"
make_color GlassTextTertiary  "0.45" "0.45" "0.58"   "0.50" "0.50" "0.62"
make_color GlassAccent        "0.20" "0.45" "0.90"   "0.40" "0.65" "1.00"
make_color GlassAccentSecondary "0.45" "0.75" "0.95" "0.55" "0.82" "1.00"
make_color GlassFav           "0.90" "0.65" "0.10"   "1.00" "0.80" "0.20"

# ─── MID CENTURY THEME ────────────────────────────────────────────────────────
make_color MCBg               "0.96" "0.92" "0.84"   "0.15" "0.12" "0.10"
make_color MCSurface          "0.91" "0.86" "0.76"   "0.20" "0.16" "0.13"
make_color MCCard             "0.98" "0.95" "0.88"   "0.22" "0.18" "0.15"
make_color MCNavBar           "0.94" "0.88" "0.78"   "0.14" "0.11" "0.09"
make_color MCTextPrimary      "0.15" "0.10" "0.08"   "0.95" "0.90" "0.82"
make_color MCTextSecondary    "0.38" "0.28" "0.22"   "0.72" "0.65" "0.58"
make_color MCTextTertiary     "0.58" "0.48" "0.40"   "0.52" "0.45" "0.38"
make_color MCAccent           "0.78" "0.32" "0.18"   "0.88" "0.42" "0.25"   # terracotta
make_color MCAccentSecondary  "0.82" "0.65" "0.10"   "0.90" "0.74" "0.18"   # mustard
make_color MCFav              "0.15" "0.45" "0.42"   "0.22" "0.58" "0.55"   # deep teal

echo "✅ Color assets generated."
