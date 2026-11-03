"""Blender Cycles 4K hero renders for the LUME T-form (Mega or Bolt SKU).

Loads the fused assembly STL, splits geometry into material zones (bar +
pod + camera-window cradle + wordmark paint-fill), sets up a 5-light
studio environment, renders 4 canonical angles at 4K Cycles 128 samples.

Run via:
  blender --background --python hardware/cad/blender/render_tform.py -- \
      --variant mega [--samples 128] [--out renders/cycles-mega/]

Output: 4 PNGs per variant — hero_3q, hero_front, hero_side, hero_macro.
"""

from __future__ import annotations
import sys
import os
from pathlib import Path

import bpy

# Make render_beauty importable for shared materials/lighting helpers.
THIS = Path(bpy.context.evaluated_depsgraph_get().scene.render.filepath \
            if False else __file__).resolve()
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))


# ---- args ------------------------------------------------------------
def parse_args():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    args = {"variant": "mega", "samples": 128,
            "out": None, "res_x": 3840, "res_y": 2400}
    i = 0
    while i < len(argv):
        if argv[i] == "--variant" and i + 1 < len(argv):
            args["variant"] = argv[i + 1]; i += 2
        elif argv[i] == "--samples" and i + 1 < len(argv):
            args["samples"] = int(argv[i + 1]); i += 2
        elif argv[i] == "--out" and i + 1 < len(argv):
            args["out"] = argv[i + 1]; i += 2
        elif argv[i] == "--res" and i + 1 < len(argv):
            x, y = argv[i + 1].split("x")
            args["res_x"] = int(x); args["res_y"] = int(y); i += 2
        else:
            i += 1
    if args["out"] is None:
        args["out"] = f"renders/cycles-{args['variant']}/"
    return args


ARGS = parse_args()
ROOT = HERE.parent  # hardware/cad/
ASSEMBLY_STL = ROOT / "exports" / f"assembly_tform_{ARGS['variant']}.stl"
OUT_DIR = ROOT / ARGS["out"]
OUT_DIR.mkdir(parents=True, exist_ok=True)


# ---- materials -------------------------------------------------------
def make_principled(name, base, roughness, metallic=0.0, ior=1.45):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    nt = m.node_tree
    # Blender 5.1.1 doesn't guarantee a default Principled BSDF in nodes by name —
    # clear the default tree and build it explicitly so the lookup never fails.
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (0, 0)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (300, 0)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if "IOR" in bsdf.inputs:
        bsdf.inputs["IOR"].default_value = ior
    return m


# Production palette — split bar / pod / cradle / wordmark.
PALETTE = {
    "bar":      ((0.045, 0.045, 0.05), 0.30, 0.0),    # satin charcoal
    "pod":      ((0.030, 0.030, 0.035), 0.40, 0.0),   # matte black
    "cradle":   ((0.012, 0.012, 0.015), 0.20, 0.0),   # gloss black (camera glass simulation)
    "wordmark": ((0.95, 0.95, 0.97), 0.45, 0.0),      # off-white paint fill
}


# ---- import + zoning -------------------------------------------------
def clean_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for c in (bpy.data.collections,):
        pass


def import_assembly():
    print(f"[render_tform] importing {ASSEMBLY_STL}")
    if not ASSEMBLY_STL.exists():
        raise SystemExit(f"missing {ASSEMBLY_STL} — run lume-assembly-tform.scad first")
    # Blender 5.x bundles wm.stl_import
    if hasattr(bpy.ops.wm, "stl_import"):
        bpy.ops.wm.stl_import(filepath=str(ASSEMBLY_STL))
    else:
        bpy.ops.import_mesh.stl(filepath=str(ASSEMBLY_STL))
    objs = [o for o in bpy.context.selected_objects if o.type == "MESH"]
    if not objs:
        raise SystemExit("no mesh imported")
    bpy.context.view_layer.objects.active = objs[0]
    for o in objs: o.select_set(True)
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = "LUME_TForm"
    # Convert mm → meters
    obj.scale = (0.001, 0.001, 0.001)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # Recenter
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    obj.location = (0.0, 0.0, 0.0)
    return obj


def assign_zoned_materials(obj):
    """Split polygons into 4 zones by world-space position:
       - cradle: front face polys inside the pill-window region
       - wordmark: front face polys at the wordmark Y-slab depth
       - pod: polys with Y > 0 (behind bar centerline)
       - bar: everything else
    """
    bar      = make_principled("LUME_bar",      *PALETTE["bar"])
    pod      = make_principled("LUME_pod",      *PALETTE["pod"])
    cradle   = make_principled("LUME_cradle",   *PALETTE["cradle"])
    wordmark = make_principled("LUME_wordmark", *PALETTE["wordmark"])

    obj.data.materials.clear()
    for m in (bar, pod, cradle, wordmark):
        obj.data.materials.append(m)
    SLOT_BAR, SLOT_POD, SLOT_CRADLE, SLOT_WORDMARK = 0, 1, 2, 3

    # Find shell front-face Y by histogramming -Y-normal area
    from collections import defaultdict
    mw = obj.matrix_world
    area_by_bin = defaultdict(float)
    for p in obj.data.polygons:
        wn = mw.to_3x3() @ p.normal
        if wn.y > -0.85: continue
        b = round((mw @ p.center).y * 1000)
        area_by_bin[b] += p.area
    # Pick most-negative bin with area >= 0.001 m² (filters Femto lens etc)
    candidates = [b for b, a in area_by_bin.items() if a >= 0.001]
    if candidates:
        front_y_mm = min(candidates)
    else:
        front_y_mm = -55  # fallback for Mega
    front_y = front_y_mm / 1000.0
    print(f"[render_tform] shell_front_y = {front_y_mm}mm")

    # Zone bounds (m)
    s = 0.001
    n_bar = n_pod = n_cradle = n_wm = 0
    for poly in obj.data.polygons:
        c = mw @ poly.center
        # Pod: behind bar's rear face (Y > positive threshold)
        if c.y > 0.030:  # 30mm = inside pod region for both SKUs
            poly.material_index = SLOT_POD; n_pod += 1; continue
        # Wordmark deboss: thin slab just inside front face
        if (front_y + 0.0001) < c.y < (front_y + 0.0025):
            poly.material_index = SLOT_WORDMARK; n_wm += 1; continue
        # Cradle: pill-region near front face — Z near WORDMARK area is below pill,
        # pill is at Z ≈ 0 (camera centerline). Detect by world-space Y close to
        # front_y (within recess depth) AND Z near 0 (camera centerline) AND
        # X near center (pill width).
        if (front_y - 0.0005) < c.y < (front_y + 0.002):
            if abs(c.z - 0) < 0.022 and abs(c.x) < 0.060:
                poly.material_index = SLOT_CRADLE; n_cradle += 1; continue
        poly.material_index = SLOT_BAR; n_bar += 1
    total = n_bar + n_pod + n_cradle + n_wm
    print(f"[render_tform] zones: bar={n_bar} pod={n_pod} cradle={n_cradle} wordmark={n_wm} total={total}")
    return obj


# ---- studio environment -----------------------------------------------
def setup_world():
    w = bpy.data.worlds.new("LUME_World") if "LUME_World" not in bpy.data.worlds else bpy.data.worlds["LUME_World"]
    bpy.context.scene.world = w
    w.use_nodes = True
    nt = w.node_tree
    nt.nodes.clear()
    bg = nt.nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.04, 0.045, 0.055, 1.0)
    # Strength dropped from 0.6 → 0.15: ambient was lifting dark albedos into mid-grey.
    bg.inputs["Strength"].default_value = 0.15
    out = nt.nodes.new("ShaderNodeOutputWorld")
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])


def setup_lights():
    # Light energies tuned for Blender 5.1.1 + Cycles + Filmic Medium-High Contrast.
    # Original tuning at 5x these values overlit dark albedos (0.04 RGB) to RGB(240,
    # 240, 240) — the "white render" symptom. These values land 0.04 albedo at
    # ~RGB(150) under the key, with cradle / pod still readably darker.
    # KEY (warm, large area)
    key = bpy.data.lights.new("Key", type="AREA"); ko = bpy.data.objects.new("KeyL", key)
    bpy.context.scene.collection.objects.link(ko)
    key.size = 1.6; key.energy = 110; key.color = (1.0, 0.93, 0.86)
    ko.location = (0.55, -0.7, 0.55); ko.rotation_euler = (0.7, 0, 0.6)
    # FILL (cool, soft)
    fill = bpy.data.lights.new("Fill", type="AREA"); fo = bpy.data.objects.new("FillL", fill)
    bpy.context.scene.collection.objects.link(fo)
    fill.size = 1.2; fill.energy = 32; fill.color = (0.85, 0.92, 1.0)
    fo.location = (-0.6, -0.45, 0.25); fo.rotation_euler = (0.55, 0, -0.6)
    # RIM (cold accent from behind/above)
    rim = bpy.data.lights.new("Rim", type="AREA"); ro = bpy.data.objects.new("RimL", rim)
    bpy.context.scene.collection.objects.link(ro)
    rim.size = 0.8; rim.energy = 60; rim.color = (0.7, 0.85, 1.0)
    ro.location = (0.0, 0.6, 0.5); ro.rotation_euler = (-0.6, 0, 0)
    # ACCENT (small, gold, picks out cradle)
    acc = bpy.data.lights.new("Acc", type="SPOT"); ao = bpy.data.objects.new("AccL", acc)
    bpy.context.scene.collection.objects.link(ao)
    acc.energy = 9; acc.color = (1.0, 0.8, 0.5); acc.spot_size = 0.6
    ao.location = (-0.15, -0.4, 0.05); ao.rotation_euler = (1.55, 0, 0.4)
    # FLOOR plate to catch shadows
    bpy.ops.mesh.primitive_plane_add(size=2.0, location=(0, 0, -0.07))
    floor = bpy.context.active_object
    floor.name = "Floor"
    fmat = make_principled("Floor_M", (0.025, 0.025, 0.03), 0.85, 0.0)
    floor.data.materials.append(fmat)


def setup_camera(loc, look_at=(0, 0, 0), lens=50):
    cam = bpy.data.cameras.new("Cam"); co = bpy.data.objects.new("Cam", cam)
    bpy.context.scene.collection.objects.link(co)
    bpy.context.scene.camera = co
    cam.lens = lens
    co.location = loc
    # point at look_at
    import mathutils
    direction = mathutils.Vector(look_at) - mathutils.Vector(loc)
    co.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    return co


def setup_render(samples, x, y):
    s = bpy.context.scene
    s.render.engine = "CYCLES"
    s.cycles.samples = samples
    s.cycles.use_denoising = True
    s.render.resolution_x = x
    s.render.resolution_y = y
    s.render.resolution_percentage = 100
    s.render.image_settings.file_format = "PNG"
    s.render.image_settings.compression = 15
    s.view_settings.view_transform = "Filmic"
    s.view_settings.look = "Medium High Contrast"


def render_to(path):
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print(f"[render_tform] wrote {path}")


# ---- main ------------------------------------------------------------
def main():
    print(f"\n=== render_tform: variant={ARGS['variant']} samples={ARGS['samples']} ===")
    clean_scene()
    obj = import_assembly()
    assign_zoned_materials(obj)
    setup_world()
    setup_lights()
    setup_render(ARGS["samples"], ARGS["res_x"], ARGS["res_y"])

    # Four canonical angles
    angles = [
        ("hero_3q",    ( 0.38, -0.35,  0.25),  (0,  0.02,   0), 50),
        ("hero_front", ( 0.00, -0.55,  0.00),  (0,  0,      0), 60),
        ("hero_side",  ( 0.55,  0.05,  0.00),  (0,  0,      0), 60),
        ("hero_macro", (-0.10, -0.28,  0.02),  (-0.04, -0.005, 0), 80),
    ]
    for name, loc, look, lens in angles:
        # Remove prior camera if any
        for c in [o for o in bpy.data.objects if o.type == "CAMERA"]:
            bpy.data.objects.remove(c, do_unlink=True)
        setup_camera(loc, look_at=look, lens=lens)
        render_to(OUT_DIR / f"{name}.png")
    print(f"\n=== done: {OUT_DIR} ===")


if __name__ == "__main__":
    main()
