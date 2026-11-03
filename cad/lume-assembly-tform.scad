// Fused T-form assembly for Blender Cycles render_beauty.py.
// Unions the 4 bar shell halves + 4 pod parts into a single mesh, exported
// as OBJ for Blender import.
//
// Usage:
//   openscad --backend=Manifold -o exports/assembly_tform_mega.obj \
//     -D 'SKU="mega"' lume-assembly-tform.scad
//   openscad --backend=Manifold -o exports/assembly_tform_bolt.obj \
//     -D 'SKU="bolt"' lume-assembly-tform.scad

SKU = "mega";  // "mega" or "bolt"

if (SKU == "mega") {
    // Mega-config bar shells + pod
    color("#1f242a") {
        import("exports/sku0-dev/shell_front_L.stl", convexity=10);
        import("exports/sku0-dev/shell_front_R.stl", convexity=10);
        import("exports/sku0-dev/shell_rear_L.stl",  convexity=10);
        import("exports/sku0-dev/shell_rear_R.stl",  convexity=10);
    }
    // Pod placed flush against bar's rear face — pod modules are origin
    // at front-face Y=0 internally so we translate to Y=+85/2 = +42.5
    translate([0, 42.5, 0]) {
        color("#1a2027") {
            import("exports/pod_top.stl",       convexity=10);
            import("exports/pod_bottom.stl",    convexity=10);
        }
    }
}
else if (SKU == "bolt") {
    // Bolt-config (slim 60mm-deep bar + 100mm-deep pod)
    color("#1f242a") {
        import("exports/sku1-bolt/shell_front_L.stl", convexity=10);
        import("exports/sku1-bolt/shell_front_R.stl", convexity=10);
        import("exports/sku1-bolt/shell_rear_L.stl",  convexity=10);
        import("exports/sku1-bolt/shell_rear_R.stl",  convexity=10);
    }
    // Bolt bar is 60mm deep so pod attaches at Y=+30
    translate([0, 30, 0]) {
        color("#1a2027") {
            import("exports/sku1-bolt/pod_top.stl",       convexity=10);
            import("exports/sku1-bolt/pod_bottom.stl",    convexity=10);
        }
    }
}
