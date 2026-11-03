#!/usr/bin/env bash
# LUME CAD — headless render + export pipeline
# Usage:
#   ./render.sh preview     -> baseline PNG previews (assembly + exploded + shell)
#   ./render.sh stl         -> printable STLs (shell halves + bezel + diffuser + port bracket + VESA)
#   ./render.sh ortho       -> Tier A1: 6-view orthographic projections
#   ./render.sh parts       -> Tier A2: per-part beauty render for all 20 printed parts
#   ./render.sh exploded    -> Tier A3: annotated exploded view
#   ./render.sh xsect       -> Tier A4: cross-section grid (5 existing + 3 new)
#   ./render.sh wireframe   -> Tier A5: wireframe pass (axes/edges)
#   ./render.sh hero        -> Tier B (engineering-clean): 3/4 hero front/rear + macro
#   ./render.sh dim         -> Tier D1: dimensioned drawing
#   ./render.sh portmap     -> Tier D2: port pin-out diagram
#   ./render.sh cables      -> Tier D3: cable routing diagram
#   ./render.sh bom         -> Tier D4: BOM tear-down grid
#   ./render.sh tier-a      -> A1+A2+A3+A4+A5
#   ./render.sh tier-d      -> D1+D2+D3+D4
#   ./render.sh full        -> tier-a + tier-d + hero (everything OpenSCAD-driven)
#   ./render.sh all         -> preview + stl
#   ./render.sh clean       -> wipe exports/ + renders/

set -euo pipefail
cd "$(dirname "$0")"

OSCAD="${OPENSCAD:-openscad}"
OUT="exports"
RENDERS="renders"
mkdir -p "$OUT" "$RENDERS"

# ---- helpers --------------------------------------------------------------

render_png() {
  local src=$1 out=$2 extra=${3:-}
  echo "▶ PNG  $src → $out"
  # shellcheck disable=SC2086
  "$OSCAD" -o "$out" \
    --imgsize=1600,1000 \
    --colorscheme=Tomorrow \
    --camera=0,0,0,55,0,25,800 \
    $extra \
    "$src"
}

# Engineering ortho — projection=ortho, axis-aligned camera
render_ortho() {
  local src=$1 out=$2 cam=$3 extra=${4:-}
  echo "▶ ORTHO $src → $out  cam=$cam"
  # shellcheck disable=SC2086
  "$OSCAD" -o "$out" \
    --imgsize=1600,1600 \
    --colorscheme=Tomorrow \
    --camera="$cam" \
    --projection=ortho \
    --autocenter --viewall \
    $extra \
    "$src"
}

# Per-part beauty render — consistent 45° iso, larger image
render_part() {
  local src=$1 out=$2 part=$3
  echo "▶ PART  $part → $out"
  "$OSCAD" -o "$out" \
    --imgsize=1200,1200 \
    --colorscheme=Tomorrow \
    --autocenter --viewall \
    --camera=0,0,0,60,0,30,400 \
    --projection=perspective \
    -D "PART=\"$part\"" \
    "$src"
}

# Hero / 3-quarter beauty — perspective by default; pass --projection=ortho via extra to override
render_hero() {
  local src=$1 out=$2 cam=$3 extra=${4:-}
  echo "▶ HERO $src → $out"
  # shellcheck disable=SC2086
  "$OSCAD" -o "$out" \
    --imgsize=2400,1500 \
    --colorscheme=Tomorrow \
    --camera="$cam" \
    $extra \
    "$src"
}

render_stl() {
  local src=$1 out=$2 defines=${3:-}
  echo "▶ STL  $src ($defines) → $out"
  # shellcheck disable=SC2086
  "$OSCAD" -o "$OUT/$out" $defines "$src"
}

# ---- targets --------------------------------------------------------------

case "${1:-preview}" in
  preview)
    render_png lume-main.scad         "$OUT/assembly.png"     '-D VIEW="assembly" -D EXPLODED=false'
    render_png lume-main.scad         "$OUT/exploded.png"     '-D VIEW="assembly" -D EXPLODED=true'
    render_png lume-shell.scad        "$OUT/shell_full.png"   '-D PREVIEW="full"'
    render_png lume-shell.scad        "$OUT/shell_front.png"  '-D PREVIEW="front"'
    render_png lume-shell.scad        "$OUT/shell_rear.png"   '-D PREVIEW="rear"'
    render_png lume-bezel.scad        "$OUT/bezel.png"
    render_png lume-port-bracket.scad "$OUT/port_bracket.png"
    render_png lume-vesa.scad         "$OUT/vesa_plate.png"   '-D MOUNT="vesa"'
    ;;

  obj)
    # Two OBJ exports for Blender:
    #   assembly.obj      — exterior shell only (for beauty/lifestyle renders)
    #   assembly_full.obj — shell + internals + components (for engineering)
    # MIRROR_WORDMARK=true compensates for the OBJ→Blender 180° Z import flip
    # so "LUME" reads correctly in beauty renders (gotcha #1 / #12).
    echo "▶ OBJ  shell exterior → assembly.obj"
    "$OSCAD" -o "$OUT/assembly.obj" \
      -D 'PREVIEW="full"' -D 'MIRROR_WORDMARK=true' lume-shell.scad
    echo "▶ OBJ  full assembly  → assembly_full.obj"
    "$OSCAD" -o "$OUT/assembly_full.obj" \
      -D 'VIEW="assembly"' -D 'MIRROR_WORDMARK=true' lume-main.scad
    ;;

  stl)
    render_stl lume-shell.scad       shell_front.stl      '-D PREVIEW="front"'
    render_stl lume-shell.scad       shell_rear.stl       '-D PREVIEW="rear"'
    render_stl lume-shell.scad       shell_front_L.stl    '-D PREVIEW="front_L"'
    render_stl lume-shell.scad       shell_front_R.stl    '-D PREVIEW="front_R"'
    render_stl lume-shell.scad       shell_rear_L.stl     '-D PREVIEW="rear_L"'
    render_stl lume-shell.scad       shell_rear_R.stl     '-D PREVIEW="rear_R"'
    render_stl lume-bezel.scad       bezel.stl            '-D PREVIEW_BEZEL="bezel"'
    render_stl lume-bezel.scad       cam_plug.stl         '-D PREVIEW_BEZEL="plug"'
    render_stl lume-port-bracket.scad port_bracket.stl
    render_stl lume-vesa.scad        vesa_plate.stl       '-D MOUNT="vesa"'
    render_stl lume-vesa.scad        cleat_bar.stl        '-D MOUNT="cleat_bar"'
    render_stl lume-vesa.scad        cleat_wall.stl       '-D MOUNT="cleat_wall"'
    for part in jetson_sled fan_shroud thermal_baffle femto_mount svpro_L svpro_R mic_rail led_diffuser cable_backbone port_anchors splice_plate; do
      render_stl lume-internals.scad "${part}.stl" "-D PART=\"${part}\""
    done
    render_stl lume-joinery-coupon.scad coupon_tongues.stl       '-D PART="tongues"'
    render_stl lume-joinery-coupon.scad coupon_grooves.stl       '-D PART="grooves"'
    render_stl lume-joinery-coupon.scad splice_pegs.stl          '-D PART="splice_pegs"'
    render_stl lume-joinery-coupon.scad splice_pockets.stl       '-D PART="splice_pockets"'
    ;;

  # ---- Tier A: Engineering renders ----
  ortho)
    mkdir -p "$RENDERS/ortho"
    # Camera form: eye_x,y,z,center_x,y,z. Distance is implied by --autocenter --viewall.
    # Front: looking in +Y direction, eye at (0,-d,0), center at origin
    render_ortho lume-main.scad "$RENDERS/ortho/ortho_front.png"  "0,-2000,0,0,0,0"  '-D VIEW="assembly"'
    render_ortho lume-main.scad "$RENDERS/ortho/ortho_back.png"   "0,2000,0,0,0,0"   '-D VIEW="assembly"'
    render_ortho lume-main.scad "$RENDERS/ortho/ortho_left.png"   "-2000,0,0,0,0,0"  '-D VIEW="assembly"'
    render_ortho lume-main.scad "$RENDERS/ortho/ortho_right.png"  "2000,0,0,0,0,0"   '-D VIEW="assembly"'
    render_ortho lume-main.scad "$RENDERS/ortho/ortho_top.png"    "0,0,2000,0,0,0"   '-D VIEW="assembly"'
    render_ortho lume-main.scad "$RENDERS/ortho/ortho_bottom.png" "0,0,-2000,0,0,0"  '-D VIEW="assembly"'
    ;;

  parts)
    mkdir -p "$RENDERS/parts"
    # Internal parts (driven by PART= dispatch in lume-internals.scad)
    for part in jetson_sled fan_shroud thermal_baffle femto_mount \
                svpro_L svpro_R mic_rail led_diffuser \
                cable_backbone port_anchors splice_plate; do
      render_part lume-internals.scad "$RENDERS/parts/${part}.png" "$part"
    done
    # Shell halves — driven by PREVIEW= dispatch in lume-shell.scad
    for half in front_L front_R rear_L rear_R; do
      "$OSCAD" -o "$RENDERS/parts/shell_${half}.png" \
        --imgsize=1200,1200 --colorscheme=Tomorrow \
        --autocenter --viewall \
        --camera=0,0,0,60,0,30,500 \
        --projection=perspective \
        -D "PREVIEW=\"${half}\"" lume-shell.scad
    done
    # Standalone parts
    "$OSCAD" -o "$RENDERS/parts/bezel.png" \
      --imgsize=1200,1200 --colorscheme=Tomorrow --autocenter --viewall \
      --camera=0,0,0,60,0,30,400 lume-bezel.scad
    "$OSCAD" -o "$RENDERS/parts/port_bracket.png" \
      --imgsize=1200,1200 --colorscheme=Tomorrow --autocenter --viewall \
      --camera=0,0,0,60,0,30,400 lume-port-bracket.scad
    "$OSCAD" -o "$RENDERS/parts/vesa_plate.png" \
      --imgsize=1200,1200 --colorscheme=Tomorrow --autocenter --viewall \
      --camera=0,0,0,60,0,30,400 -D 'MOUNT="vesa"' lume-vesa.scad
    "$OSCAD" -o "$RENDERS/parts/cleat_bar.png" \
      --imgsize=1200,1200 --colorscheme=Tomorrow --autocenter --viewall \
      --camera=0,0,0,60,0,30,400 -D 'MOUNT="cleat_bar"' lume-vesa.scad
    "$OSCAD" -o "$RENDERS/parts/cleat_wall.png" \
      --imgsize=1200,1200 --colorscheme=Tomorrow --autocenter --viewall \
      --camera=0,0,0,60,0,30,400 -D 'MOUNT="cleat_wall"' lume-vesa.scad
    ;;

  exploded)
    mkdir -p "$RENDERS"
    # Clean exploded (no labels) — overwrites baseline exploded.png with a hero pose
    render_hero lume-main.scad "$RENDERS/exploded_clean.png" \
      "0,-1200,400,0,0,0" \
      '-D VIEW="assembly" -D EXPLODED=true -D EXPLODE_DIST=80'
    # Labeled exploded — uses annotation overlay (separate file, draws labels per part)
    render_hero lume-main.scad "$RENDERS/exploded_labeled.png" \
      "0,-1400,500,0,0,0" \
      '-D VIEW="assembly" -D EXPLODED=true -D EXPLODE_DIST=120'
    ;;

  xsect)
    mkdir -p "$RENDERS/xsect"
    # 5 existing
    render_png lume-cross-section.scad "$RENDERS/xsect/xsect_top.png"      '-D VIEW="top"'
    render_png lume-cross-section.scad "$RENDERS/xsect/xsect_mid.png"      '-D VIEW="mid"'
    render_png lume-cross-section.scad "$RENDERS/xsect/xsect_seam.png"     '-D VIEW="seam"'
    render_png lume-cross-section.scad "$RENDERS/xsect/xsect_front_L_iso.png" '-D VIEW="front_L_iso"'
    render_png lume-cross-section.scad "$RENDERS/xsect/xsect_rear_R_iso.png"  '-D VIEW="rear_R_iso"'
    # 3 new — vertical mid-X, horizontal at LED Z, horizontal at port cluster X
    render_png lume-cross-section-extra.scad "$RENDERS/xsect/xsect_vertical_mid.png"  '-D VIEW="vertical_mid"'
    render_png lume-cross-section-extra.scad "$RENDERS/xsect/xsect_led_plane.png"     '-D VIEW="led_plane"'
    render_png lume-cross-section-extra.scad "$RENDERS/xsect/xsect_port_cluster.png"  '-D VIEW="port_cluster"'
    ;;

  wireframe)
    mkdir -p "$RENDERS/wireframe"
    render_hero lume-main.scad "$RENDERS/wireframe/wireframe_iso.png" \
      "0,-900,400,0,0,0" \
      '-D VIEW="assembly" --view=edges,axes'
    render_hero lume-main.scad "$RENDERS/wireframe/wireframe_exploded.png" \
      "0,-1200,500,0,0,0" \
      '-D VIEW="assembly" -D EXPLODED=true --view=edges'
    ;;

  hero)
    mkdir -p "$RENDERS/hero"
    # B1: front 3/4
    render_hero lume-main.scad "$RENDERS/hero/hero_front_3q.png" \
      "300,-700,250,0,0,0" \
      '-D VIEW="assembly" -D SHOW_INTERNALS=false -D SHOW_COMPONENTS=true'
    # B2: rear 3/4
    render_hero lume-main.scad "$RENDERS/hero/hero_rear_3q.png" \
      "300,700,250,0,0,0" \
      '-D VIEW="assembly" -D SHOW_INTERNALS=false -D SHOW_COMPONENTS=true'
    # B3: macro on wordmark + LED — tight crop on front center
    render_hero lume-main.scad "$RENDERS/hero/hero_macro_wordmark.png" \
      "0,-180,40,0,-30,0" \
      '-D VIEW="assembly" -D SHOW_INTERNALS=false -D SHOW_COMPONENTS=false'
    ;;

  # ---- Tier D: Documentation ----
  dim)
    mkdir -p "$RENDERS/dim"
    render_hero lume-annotations.scad "$RENDERS/dim/dim_front.png" \
      "0,-1200,80,0,0,0" \
      '-D VIEW="dim_front"'
    render_hero lume-annotations.scad "$RENDERS/dim/dim_top.png" \
      "0,0,1500,0,0,0" \
      '-D VIEW="dim_top" --projection=ortho'
    ;;

  portmap)
    mkdir -p "$RENDERS/dim"
    render_hero lume-annotations.scad "$RENDERS/dim/portmap.png" \
      "120,800,80,120,0,0" \
      '-D VIEW="portmap"'
    ;;

  cables)
    mkdir -p "$RENDERS/dim"
    # Top-down ortho — cables traced along +Z exterior so they sit on a flat plane
    render_hero lume-annotations.scad "$RENDERS/dim/cables.png" \
      "0,0,1500,0,0,0" \
      '-D VIEW="cables" --projection=ortho'
    ;;

  bom)
    mkdir -p "$RENDERS"
    if [ ! -f "$RENDERS/parts/jetson_sled.png" ]; then
      echo "▶ BOM  parts not rendered yet; running parts target first"
      $0 parts
    fi
    echo "▶ BOM  composing tear-down grid via Pillow"
    python3 scripts/compose_bom.py
    ;;

  # ---- Tier B (Blender beauty) ----
  beauty)
    if [ ! -f "$OUT/assembly.obj" ]; then
      echo "▶ BEAUTY  building assembly.obj first"
      $0 obj
    fi
    blender --background --python blender/render_beauty.py -- \
      --out "$RENDERS" --tier b --samples "${SAMPLES:-128}" \
      --width "${WIDTH:-3840}" --height "${HEIGHT:-2160}"
    ;;

  # ---- Tier C (Blender lifestyle) ----
  lifestyle)
    if [ ! -f "$OUT/assembly.obj" ]; then
      echo "▶ LIFESTYLE  building assembly.obj first"
      $0 obj
    fi
    blender --background --python blender/render_beauty.py -- \
      --out "$RENDERS" --tier c --samples "${SAMPLES:-128}" \
      --width "${WIDTH:-3840}" --height "${HEIGHT:-2160}"
    ;;

  # Fast preview pass — 32 samples, half-res, for quick visual check
  beauty-quick)
    if [ ! -f "$OUT/assembly.obj" ]; then $0 obj; fi
    blender --background --python blender/render_beauty.py -- \
      --out "$RENDERS" --tier all --samples 32 --width 1920 --height 1080
    ;;

  # ---- Tier composites ----
  tier-a)
    $0 ortho
    $0 parts
    $0 exploded
    $0 xsect
    $0 wireframe
    ;;

  tier-d)
    $0 dim
    $0 portmap
    $0 cables
    $0 bom
    ;;

  full)
    $0 tier-a
    $0 tier-d
    $0 hero
    ;;

  all)
    $0 preview
    $0 stl
    ;;

  clean)
    rm -rf "$OUT" "$RENDERS"
    mkdir -p "$OUT" "$RENDERS"
    ;;

  *)
    echo "unknown target: $1" && exit 1 ;;
esac

echo "✔ done"
