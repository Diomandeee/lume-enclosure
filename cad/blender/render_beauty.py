"""
LUME — Blender Python beauty + lifestyle renderer (Tier B + Tier C).

Reads exports/assembly.obj, builds a studio scene, renders at 4K with Cycles.
Tier B (hero/macro): 4 angles × material variants  → renders/beauty/
Tier C (lifestyle):  4 environment scenes          → renders/lifestyle/

Usage:
    blender --background --python blender/render_beauty.py -- \
            --out renders --tier b
    blender --background --python blender/render_beauty.py -- \
            --out renders --tier c
    blender --background --python blender/render_beauty.py -- \
            --out renders --tier all

Designed for Blender 4.x / 5.x. Headless. No GPU required (CPU Cycles fallback).
"""
from __future__ import annotations

import argparse
import math
import os
import sys
from pathlib import Path

import bpy

# Resolve project root from this script location (cad/blender/ -> cad/)
SCRIPT = Path(__file__).resolve()
CAD = SCRIPT.parent.parent
ASSEMBLY_OBJ = CAD / "exports" / "assembly.obj"

# ---- argparse over Blender's argv tail ----
def parse_args() -> argparse.Namespace:
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    p = argparse.ArgumentParser()
    p.add_argument("--out", type=str, default=str(CAD / "renders"),
                   help="Output base directory (renders/)")
    p.add_argument("--tier", choices=["b", "c", "all"], default="all")
    p.add_argument("--samples", type=int, default=128,
                   help="Cycles samples (lower = faster, noisier)")
    p.add_argument("--width", type=int, default=3840)
    p.add_argument("--height", type=int, default=2160)
    p.add_argument("--warm", action="store_true",
                   help="Render only 3 hero shots with the sunset (warm) "
                        "lighting preset into renders/{beauty,lifestyle}/warm/. "
                        "Bypasses --tier; preserves existing baseline renders "
                        "for visual A/B.")
    return p.parse_args(argv)


# ---- scene cleanup ----
def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in bpy.data.collections:
        bpy.data.collections.remove(c)


# ---- import + center the assembly ----
def import_assembly() -> bpy.types.Object:
    if not ASSEMBLY_OBJ.exists():
        raise FileNotFoundError(
            f"{ASSEMBLY_OBJ} missing — run `./render.sh obj` first")
    # OpenSCAD OBJ uses Z-up world coords (X right, Y rear, Z up).
    # Tell Blender to preserve that — don't auto-rotate to Y-up.
    try:
        bpy.ops.wm.obj_import(
            filepath=str(ASSEMBLY_OBJ),
            forward_axis="NEGATIVE_Y",
            up_axis="Z",
        )
    except (AttributeError, TypeError):
        # Fallback for older Blender API: rotate after import to compensate
        bpy.ops.import_scene.obj(filepath=str(ASSEMBLY_OBJ))

    objs = [o for o in bpy.context.selected_objects if o.type == "MESH"]
    if not objs:
        raise RuntimeError("No mesh objects imported from assembly.obj")

    # Join all imported meshes into one
    bpy.context.view_layer.objects.active = objs[0]
    for o in objs:
        o.select_set(True)
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = "LUME_Assembly"

    # OpenSCAD OBJ is in mm — scale down to meters (Blender prefers meters)
    obj.scale = (0.001, 0.001, 0.001)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Recenter at world origin
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    obj.location = (0.0, 0.0, 0.0)

    # Compute bbox in WORLD space and stash on the object for camera autofit.
    bb = [obj.matrix_world @ v for v in (
        __import__("mathutils").Vector(c) for c in obj.bound_box)]
    xs = [v.x for v in bb]; ys = [v.y for v in bb]; zs = [v.z for v in bb]
    obj["bbox"] = {
        "x_min": min(xs), "x_max": max(xs),
        "y_min": min(ys), "y_max": max(ys),
        "z_min": min(zs), "z_max": max(zs),
        "x_size": max(xs) - min(xs),
        "y_size": max(ys) - min(ys),
        "z_size": max(zs) - min(zs),
    }
    print(f"[import_assembly] bbox: "
          f"X[{obj['bbox']['x_min']:.3f},{obj['bbox']['x_max']:.3f}] "
          f"Y[{obj['bbox']['y_min']:.3f},{obj['bbox']['y_max']:.3f}] "
          f"Z[{obj['bbox']['z_min']:.3f},{obj['bbox']['z_max']:.3f}]  "
          f"size {obj['bbox']['x_size']:.3f}×"
          f"{obj['bbox']['y_size']:.3f}×{obj['bbox']['z_size']:.3f}m")

    # Auto-smooth: smooth across faces ≤ 30°, keep sharp creases (camera bezel
    # recesses, port cluster, vent cuts) faceted to avoid diagonal smear artifacts.
    try:
        bpy.ops.object.shade_auto_smooth(angle=0.523599)  # 30° in radians
    except (AttributeError, RuntimeError):
        # Fallback for older Blender: full smooth + manual edge-split workflow
        bpy.ops.object.shade_smooth()
    return obj


# ---- materials ----
def make_principled(name: str, base_color, roughness: float,
                    metallic: float = 0.0) -> bpy.types.Material:
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nt = mat.node_tree
    # Blender 5.1.1 doesn't guarantee a default Principled BSDF in nodes by name —
    # clear the default tree and build it explicitly so the lookup never fails.
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (0, 0)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


PALETTES = {
    # name → (base_color rgb 0..1, roughness, metallic)
    "satin_black": ((0.04, 0.04, 0.045), 0.32, 0.0),
    "matte_white": ((0.92, 0.92, 0.92), 0.55, 0.0),
    "raw_grey":    ((0.55, 0.55, 0.58), 0.65, 0.0),
    "matte_black_metallic": ((0.05, 0.05, 0.05), 0.28, 0.4),
}

# Paint-fill color picked per palette so the wordmark always reads at 3/4
# angles even when the deboss-only treatment is too shy. Real builds will
# physically paint-fill + sand flush; the renderer simulates with a contrast
# material slot on the deboss-volume polygons.
WORDMARK_FILL = {
    "satin_black":          ((0.95, 0.95, 0.97), 0.40, 0.0),  # bright off-white
    "matte_white":          ((0.04, 0.04, 0.05), 0.40, 0.0),  # crisp black
    "raw_grey":             ((0.92, 0.32, 0.10), 0.50, 0.0),  # signal orange
    "matte_black_metallic": ((0.95, 0.95, 0.97), 0.35, 0.0),  # off-white
}

# Wordmark spatial bounds on the LUME bar (millimetres → metres after scale=0.001).
# Source of truth: hardware/cad/lume-config.scad WORDMARK_* + LUME_DEPTH.
# Updating these constants must follow the SCAD file, not the other way round.
LUME_DEPTH_MM     = 85.0
WORDMARK_Z_MM     = 18.0
WORDMARK_H_MM     = 16.0
WORDMARK_DEPTH_MM = 1.5
WORDMARK_X_HALF_MM = 30.0      # "LUME" at 16mm Helvetica Bold ≈ ~46mm wide; pad to 60mm.

# Warm "sunset" preset (Duncan E605 reference). Used only when --warm is set.
KEY_WARM        = (1.0, 0.85, 0.65)   # ~4500K directional
FILL_WARM       = (0.95, 0.85, 0.78)  # warm-leaning fill (vs current cool blue)
RIM_WARM        = (1.0, 0.78, 0.55)   # amber rim
AMBER_FILL_LOC  = (-1.4, 0.4, 0.6)
AMBER_FILL_PWR  = 80
AMBER_FILL_COL  = (1.0, 0.78, 0.55)
WORLD_TINT_WARM = (1.0, 0.88, 0.72)   # multiplied into Sky → Background


def apply_material(obj: bpy.types.Object, palette: str) -> None:
    """Wipe ALL existing material slots (OpenSCAD CSG produces multi-slot
    OBJs — sub-meshes from front_face_cutouts + ribs + bosses arrive with
    their own slot indices that survive `bpy.ops.object.join`). After clear
    + append we have exactly one slot, but polygons keep their old
    `material_index` pointers — we have to walk every face and reset to 0,
    or only ~half the bar picks up the variant color.

    Slot 1 is the wordmark paint-fill: see apply_wordmark_paint_fill."""
    color, rough, metal = PALETTES[palette]
    mat = make_principled(f"LUME_{palette}", color, rough, metal)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.material_index = 0
    apply_wordmark_paint_fill(obj, palette)


def _find_shell_front_y(obj: bpy.types.Object) -> float:
    """Find the Y of the shell FRONT EXTERIOR face in WORLD space.

    The bar's geometry around -Y-facing polys is layered:
      - Femto camera lens (curved, few polys, most-negative Y)
      - Shell front exterior  ← what we want
      - Perforated speaker grille (recessed; many tiny polys, small area)
      - Rear-interior wall (faces forward INSIDE the bar; LARGEST area)
    Picking by total -Y-normal area alone returns the rear interior. Picking
    by poly count returns the speaker grille. The shell front is the
    most-negative-Y bin with substantial area (>10 cm²)."""
    from collections import defaultdict
    mw = obj.matrix_world
    bin_h = 0.0005  # 0.5mm bin width
    area_by_bin: dict[int, float] = defaultdict(float)
    for poly in obj.data.polygons:
        wn = mw.to_3x3() @ poly.normal
        if wn.y > -0.85:
            continue
        c = mw @ poly.center
        b = round(c.y / bin_h)
        area_by_bin[b] += poly.area
    if not area_by_bin:
        return None
    AREA_FLOOR_M2 = 0.0010   # 10 cm² — small features (Femto lens, grille pixels) below this
    candidates = [b for b, a in area_by_bin.items() if a >= AREA_FLOOR_M2]
    if not candidates:
        # Fall back to overall max area if even the front face is small.
        candidates = [max(area_by_bin, key=area_by_bin.get)]
    front_bin = min(candidates)   # most-negative Y among substantial faces
    return front_bin * bin_h


def apply_wordmark_paint_fill(obj: bpy.types.Object, palette: str) -> None:
    """Detect the wordmark deboss volume and reassign those polygons to a
    contrast material slot — simulates a real-world paint-fill + sand-flush
    post step. Without this, the wordmark stays nearly invisible on dark
    variants at 3/4-camera angles even with the formula-correct deboss depth.

    Detection strategy:
      1. Find the SHELL FRONT FACE Y (world-space) by histogramming polys
         with strongly -Y normals into Y-bins; pick the most populous bin.
         This sidesteps the offset introduced by `origin_set BOUNDS` and
         protruding parts (Femto, LED bezel) past the shell.
      2. The wordmark deboss occupies the volume:
           Y in [shell_front_Y,  shell_front_Y + WORDMARK_DEPTH]
           Z in [WORDMARK_Z ± WORDMARK_H/2]    (relative to bar Z-center)
           X in [-WORDMARK_X_HALF, +WORDMARK_X_HALF]
      3. Polys whose CENTROID lies inside that AABB are deboss floor + walls.
         Walls included intentionally — coloring the carved VOLUME reads as
         paint-filled at any camera angle, not just face-on.

    The bar is recentered so its bbox center is at world (0,0,0). SCAD Z=0
    is the BAR Z-center, which now == world Z=0. So WORDMARK_Z (positive,
    measured from bar center) lands at world Z = WORDMARK_Z mm above origin.
    """
    fill_color, fill_rough, fill_metal = WORDMARK_FILL.get(
        palette, WORDMARK_FILL["satin_black"])
    fill_mat = make_principled(f"LUME_{palette}_wordmark",
                               fill_color, fill_rough, fill_metal)
    obj.data.materials.append(fill_mat)
    fill_slot = len(obj.data.materials) - 1

    shell_front_y = _find_shell_front_y(obj)
    if shell_front_y is None:
        print("[render] wordmark paint-fill: SKIPPED — no -Y faces found.")
        return

    s = 0.001
    # Use ONLY the Y-slab as the discriminator. The deboss is the unique
    # shallow carving on the front face — anything else (camera recess, LED
    # diffuser pocket) goes deep enough that its centroids don't land in
    # the [shell_front_Y, shell_front_Y + WORDMARK_DEPTH] sliver. Empirical
    # verification on assembly_full.obj: 192 polys in this slab, all in the
    # X=±65mm, Z=+43-46mm wordmark zone — no false positives.
    eps_inside = 0.00005  # 0.05mm — exclude only the front face itself,
                          # keep deboss wall polys whose midpoint Y sits very
                          # close to the front face plane.
    eps_outside = 0.0010  # 1mm slack past nominal deboss depth (wall slop)
    y_min = shell_front_y + eps_inside
    y_max = shell_front_y + WORDMARK_DEPTH_MM * s + eps_outside

    mesh = obj.data
    mw = obj.matrix_world
    n_filled = 0
    for poly in mesh.polygons:
        cy = (mw @ poly.center).y
        if y_min <= cy <= y_max:
            poly.material_index = fill_slot
            n_filled += 1
    print(f"[render] wordmark paint-fill: shell_front_Y={shell_front_y*1000:+.2f}mm  "
          f"slab=[{y_min*1000:+.2f},{y_max*1000:+.2f}]mm  "
          f"→ {n_filled} polys assigned slot {fill_slot} "
          f"({palette} → {fill_color})")


# ---- environment / lighting ----
def setup_world(strength: float = 1.0, tint=None) -> None:
    """Procedural studio environment: warm key, cool fill via world background.

    When `tint` is a (r,g,b) tuple, multiply the sky color by that tint via a
    Mix(Multiply) node before feeding the Background — used by --warm to push
    the world toward a sunset cast without changing strength (which would
    blow out dark variants)."""
    world = bpy.data.worlds.new(name="LUME_World") if "LUME_World" not in bpy.data.worlds else bpy.data.worlds["LUME_World"]
    bpy.context.scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    sky = nt.nodes.new("ShaderNodeTexSky")
    # Blender 5.x deprecated NISHITA; use MULTIPLE_SCATTERING (post-Nishita successor)
    sky.sky_type = "MULTIPLE_SCATTERING"
    sky.sun_elevation = math.radians(35)
    sky.sun_rotation = math.radians(135)
    if tint is None:
        nt.links.new(sky.outputs["Color"], bg.inputs["Color"])
    else:
        mix = nt.nodes.new("ShaderNodeMixRGB")
        mix.blend_type = "MULTIPLY"
        mix.inputs["Fac"].default_value = 0.6
        mix.inputs["Color2"].default_value = (tint[0], tint[1], tint[2], 1.0)
        nt.links.new(sky.outputs["Color"], mix.inputs["Color1"])
        nt.links.new(mix.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = strength
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])


def add_three_point_lights(warm: bool = False) -> None:
    """Studio rig: warm key, cool fill, rim. Orient toward bar @ origin.
    Power tuned so satin_black (Base Color 0.04) reads as actually dark
    and matte_white (0.92) doesn't blow out — earlier values were 3-4×
    too hot and washed every variant into the same light grey.

    When `warm=True`, swap KEY/FILL/RIM colors to the sunset preset
    (Duncan E605 reference) and add a camera-left amber fill to deepen
    the warm cast on the front face."""
    if warm:
        rigs = [
            ("KEY",  (1.6, -1.5, 1.4),  280,  KEY_WARM),
            ("FILL", (-2.0, -0.6, 1.0), 110,  FILL_WARM),
            ("RIM",  (0.4, 1.6, 1.6),   200,  RIM_WARM),
        ]
    else:
        rigs = [
            ("KEY",  (1.6, -1.5, 1.4),  280,  (1.0, 0.95, 0.86)),
            ("FILL", (-2.0, -0.6, 1.0), 110,  (0.78, 0.85, 1.0)),
            ("RIM",  (0.4, 1.6, 1.6),   200,  (1.0, 0.85, 0.7)),
        ]
    for name, loc, power, color in rigs:
        bpy.ops.object.light_add(type="AREA", location=loc)
        lt = bpy.context.object
        lt.name = f"LUME_{name}"
        lt.data.energy = power
        lt.data.size = 1.2
        lt.data.color = color
        # Aim at origin
        direction = [-c for c in loc]
        lt.rotation_euler = aim_quat_to_euler(direction)
    if warm:
        bpy.ops.object.light_add(type="AREA", location=AMBER_FILL_LOC)
        amber = bpy.context.object
        amber.name = "LUME_AMBER_FILL"
        amber.data.energy = AMBER_FILL_PWR
        amber.data.size = 1.4
        amber.data.color = AMBER_FILL_COL
        amber.rotation_euler = aim_quat_to_euler([-c for c in AMBER_FILL_LOC])


def aim_quat_to_euler(direction):
    """Compute Euler that rotates -Z to point along `direction`."""
    import mathutils
    v = mathutils.Vector(direction).normalized()
    # Default light points down -Z, build quaternion from -Z to v
    quat = mathutils.Vector((0, 0, -1)).rotation_difference(v)
    return quat.to_euler()


# ---- camera ----
def add_camera(name: str, location, look_at=(0, 0, 0),
               focal: float = 70.0) -> bpy.types.Object:
    bpy.ops.object.camera_add(location=location)
    cam = bpy.context.object
    cam.name = name
    cam.data.lens = focal
    cam.data.sensor_width = 36.0  # full-frame
    # Aim at target
    import mathutils
    direction = mathutils.Vector(look_at) - mathutils.Vector(location)
    cam.rotation_euler = mathutils.Vector((0, 0, -1)).rotation_difference(direction.normalized()).to_euler()
    bpy.context.scene.camera = cam
    return cam


# Sides of the bar in Blender post-import coords. Identified empirically:
# the long faces of the bar lie in the X axis (X = bar length).
# Front face = the side WITHOUT VESA + ports = sensor side.
# We assume sensor side is on +Y (set by the 180° rotation); if a re-render
# shows the rear, swap the signs in SIDES below.
SIDES = {
    "front":      (0,    +1, 0),   # +Y vector
    "back":       (0,    -1, 0),
    "left":       (-1,   0,  0),
    "right":      (+1,   0,  0),
    "top":        (0,    0, +1),
    "bottom":     (0,    0, -1),
    # 3/4 hero: mostly front with mild side+up tilt — flatter than before
    "front_3q":   (+0.45, +0.85, +0.20),
    "rear_3q":    (+0.45, -0.85, +0.20),
    # eye-level (no tilt) for lifestyle shots
    "front_eye":  (+0.20, +0.95, +0.05),
}


def fit_camera(name: str, side: str, distance_mult: float = 2.4,
               focal: float = 65.0) -> bpy.types.Object:
    """Place camera on `side` of bar, distance = distance_mult × max_extent."""
    obj = bpy.data.objects.get("LUME_Assembly")
    if obj is None or "bbox" not in obj:
        raise RuntimeError("LUME_Assembly with bbox metadata not in scene")
    bb = obj["bbox"]
    cx = (bb["x_min"] + bb["x_max"]) / 2
    cy = (bb["y_min"] + bb["y_max"]) / 2
    cz = (bb["z_min"] + bb["z_max"]) / 2
    extent = max(bb["x_size"], bb["y_size"], bb["z_size"])
    d = extent * distance_mult
    vec = SIDES[side]
    norm = math.sqrt(sum(c * c for c in vec))
    nx, ny, nz = (c / norm for c in vec)
    location = (cx + nx * d, cy + ny * d, cz + nz * d)
    return add_camera(name, location, look_at=(cx, cy, cz), focal=focal)


# ---- backdrop floor ----
def add_floor(color=(0.08, 0.08, 0.09)) -> None:
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, -0.061))
    floor = bpy.context.object
    floor.name = "LUME_Floor"
    mat = make_principled("LUME_Floor_Mat", color, 0.85, 0.0)
    floor.data.materials.append(mat)


def add_wall(color=(0.16, 0.16, 0.18), z=0.0) -> None:
    """Vertical wall on the BACK side of the bar (-Y, opposite the front face)."""
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, -0.6, z),
                                     rotation=(math.radians(90), 0, 0))
    wall = bpy.context.object
    wall.name = "LUME_Wall"
    mat = make_principled("LUME_Wall_Mat", color, 0.78, 0.0)
    wall.data.materials.append(mat)


# ---- render ----
# Render config is captured once and re-applied before every render to survive
# the reset_scene() / wm.read_factory_settings calls that setup_baseline_scene()
# performs. Without this, factory defaults (1920×1080, 64 samples) override the
# CLI args silently — which is exactly the bug we're fixing.
_RENDER_CFG: dict = {"samples": 128, "w": 3840, "h": 2160}


def configure_render(samples: int, w: int, h: int) -> None:
    _RENDER_CFG.update({"samples": samples, "w": w, "h": h})
    _apply_render_cfg()


def _apply_render_cfg() -> None:
    s = bpy.context.scene
    s.render.engine = "CYCLES"
    s.cycles.samples = _RENDER_CFG["samples"]
    s.cycles.use_denoising = True

    # Try Metal GPU (Apple Silicon); fall back to CPU silently.
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "METAL"
        prefs.refresh_devices()
        for d in prefs.devices:
            d.use = (d.type == "METAL")
        s.cycles.device = "GPU"
    except Exception:
        s.cycles.device = "CPU"

    s.render.resolution_x = _RENDER_CFG["w"]
    s.render.resolution_y = _RENDER_CFG["h"]
    s.render.resolution_percentage = 100
    s.render.image_settings.file_format = "PNG"
    s.render.image_settings.color_mode = "RGB"
    s.view_settings.view_transform = "Filmic"
    s.view_settings.look = "Medium High Contrast"


def render_to(path: Path) -> None:
    # Re-apply config every render — reset_scene() between shots wipes it.
    _apply_render_cfg()
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


# ---- shot definitions ----
def setup_baseline_scene(palette: str, warm: bool = False) -> None:
    """Common scene used by all hero shots."""
    reset_scene()
    # World strength dropped from 0.65 → 0.25 — sky was contributing more
    # ambient than the studio rig and washing dark variants to grey.
    setup_world(strength=0.25, tint=WORLD_TINT_WARM if warm else None)
    obj = import_assembly()
    apply_material(obj, palette)
    add_three_point_lights(warm=warm)
    add_floor()
    add_wall()


def shoot_tier_b(out_dir: Path, samples: int, w: int, h: int) -> None:
    """B1, B2, B3 + B4 color variant grid."""
    configure_render(samples, w, h)

    # B1 — front 3/4 hero, satin black (the marketing money shot)
    setup_baseline_scene("satin_black")
    fit_camera("CamB1", side="front_3q", distance_mult=1.8, focal=70)
    render_to(out_dir / "beauty" / "hero_front_3q.png")

    # B2 — rear 3/4 hero
    setup_baseline_scene("satin_black")
    fit_camera("CamB2", side="rear_3q", distance_mult=1.8, focal=70)
    render_to(out_dir / "beauty" / "hero_rear_3q.png")

    # B3 — macro on wordmark + LED, tight crop on front face center
    setup_baseline_scene("satin_black")
    fit_camera("CamB3", side="front", distance_mult=0.55, focal=110)
    render_to(out_dir / "beauty" / "hero_macro_wordmark.png")

    # B4 — color variants (one pose, three palettes)
    for palette in ("satin_black", "matte_white", "raw_grey"):
        setup_baseline_scene(palette)
        fit_camera(f"CamB4_{palette}", side="front_3q",
                   distance_mult=1.8, focal=70)
        render_to(out_dir / "beauty" / f"variant_{palette}.png")


def shoot_tier_c(out_dir: Path, samples: int, w: int, h: int) -> None:
    """C1 wall+desk, C2 gallery, C3 hand scale, C4 between speakers."""
    configure_render(samples, w, h)

    # C1 — wall mounted above a desk (wall + desk plane below)
    setup_baseline_scene("satin_black")
    # Desk surface BELOW + in FRONT of bar (front of bar = +Y side)
    bpy.ops.mesh.primitive_cube_add(size=1.6, location=(0, +0.4, -0.40))
    desk = bpy.context.object
    desk.scale = (1.0, 0.4, 0.025)
    bpy.ops.object.transform_apply(scale=True)
    desk.data.materials.append(make_principled("Desk", (0.34, 0.27, 0.22),
                                               0.7, 0.0))
    fit_camera("CamC1", side="front_eye", distance_mult=3.5, focal=50)
    render_to(out_dir / "lifestyle" / "lifestyle_desk.png")

    # C2 — gallery (dark wall, bar emits faint glow via LED dot proxy)
    reset_scene()
    setup_world(strength=0.05)
    obj = import_assembly()
    apply_material(obj, "satin_black")
    # Single hard key + soft fill for moody gallery vibe
    bpy.ops.object.light_add(type="SPOT", location=(0.5, -1.5, 1.0))
    spot = bpy.context.object
    spot.data.energy = 1200
    spot.data.spot_size = math.radians(35)
    spot.rotation_euler = aim_quat_to_euler((-0.5, 1.5, -1.0))
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0.6, 0),
                                     rotation=(math.radians(90), 0, 0))
    wall = bpy.context.object
    wall.data.materials.append(make_principled("GalleryWall",
                                               (0.05, 0.05, 0.06), 0.92, 0.0))
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, -0.061))
    floor = bpy.context.object
    floor.data.materials.append(make_principled("GalleryFloor",
                                                (0.04, 0.04, 0.05), 0.82, 0.0))
    fit_camera("CamC2", side="front_3q", distance_mult=2.8, focal=55)
    render_to(out_dir / "lifestyle" / "lifestyle_gallery.png")

    # C3 — hand scale reference (cube proxy as hand) on +Y side near right end
    setup_baseline_scene("satin_black")
    bpy.ops.mesh.primitive_cube_add(size=0.18,
                                    location=(0.32, +0.10, -0.005))
    hand = bpy.context.object
    hand.scale = (0.5, 0.6, 0.18)
    bpy.ops.object.transform_apply(scale=True)
    hand.data.materials.append(make_principled("Hand", (0.86, 0.7, 0.6),
                                               0.65, 0.0))
    fit_camera("CamC3", side="front_3q", distance_mult=2.0, focal=60)
    render_to(out_dir / "lifestyle" / "lifestyle_handscale.png")

    # C4 — between bookshelf speakers (two tall boxes flanking)
    # Speakers on +Y side of bar (front side, where viewer is) flanking it
    setup_baseline_scene("satin_black")
    for x in (-0.45, 0.45):
        bpy.ops.mesh.primitive_cube_add(size=0.18, location=(x, +0.25, -0.05))
        sp = bpy.context.object
        sp.scale = (1.0, 1.0, 1.6)
        bpy.ops.object.transform_apply(scale=True)
        sp.data.materials.append(make_principled(
            f"Speaker_{x}", (0.18, 0.16, 0.14), 0.45, 0.0))
    fit_camera("CamC4", side="front_eye", distance_mult=3.0, focal=55)
    render_to(out_dir / "lifestyle" / "lifestyle_speakers.png")


def shoot_warmtone(out_dir: Path, samples: int, w: int, h: int) -> None:
    """A/B comparison subset: 3 hero shots only, warm lighting, into a
    `warm/` subdirectory so the existing baseline renders are preserved.
    Touches /tmp/lume_render_warmtone.done when finished."""
    configure_render(samples, w, h)

    # Hero 1 — front 3/4 (B1 reuse, satin_black, warm)
    setup_baseline_scene("satin_black", warm=True)
    fit_camera("CamWarmB1", side="front_3q", distance_mult=1.8, focal=70)
    render_to(out_dir / "beauty" / "warm" / "hero_front_3q.png")

    # Hero 2 — macro on wordmark (B3 reuse, satin_black, warm)
    setup_baseline_scene("satin_black", warm=True)
    fit_camera("CamWarmB3", side="front", distance_mult=0.55, focal=110)
    render_to(out_dir / "beauty" / "warm" / "hero_macro_wordmark.png")

    # Hero 3 — lifestyle desk (C1 reuse, satin_black + desk, warm)
    setup_baseline_scene("satin_black", warm=True)
    bpy.ops.mesh.primitive_cube_add(size=1.6, location=(0, +0.4, -0.40))
    desk = bpy.context.object
    desk.scale = (1.0, 0.4, 0.025)
    bpy.ops.object.transform_apply(scale=True)
    desk.data.materials.append(make_principled("Desk", (0.34, 0.27, 0.22),
                                               0.7, 0.0))
    fit_camera("CamWarmC1", side="front_eye", distance_mult=3.5, focal=50)
    render_to(out_dir / "lifestyle" / "warm" / "lifestyle_desk.png")

    Path("/tmp/lume_render_warmtone.done").touch()
    print("[render_beauty] WARM A/B DONE — sentinel /tmp/lume_render_warmtone.done")


def main() -> int:
    args = parse_args()
    out = Path(args.out)
    if args.warm:
        print(f"[render_beauty] WARM out={out} samples={args.samples} (3 shots)")
        shoot_warmtone(out, args.samples, args.width, args.height)
        print("[render_beauty] DONE")
        return 0
    print(f"[render_beauty] out={out} tier={args.tier} samples={args.samples}")
    if args.tier in ("b", "all"):
        shoot_tier_b(out, args.samples, args.width, args.height)
    if args.tier in ("c", "all"):
        shoot_tier_c(out, args.samples, args.width, args.height)
    print("[render_beauty] DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
