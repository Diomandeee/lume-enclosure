// LUME T-form master assembly — bar (real shell halves imported as STL) + pod
// + cleat. Used for hero renders showing the production form factor.
//
// Render via:
//   openscad --backend=Manifold -o /tmp/tform_3q.png \
//     --imgsize=2400,1500 --camera=400,-350,250,0,0,0 \
//     lume-tform-assembly.scad
//
// VIEW selector:
//   "hero"     — full T-form, materials coloured, against neutral plate
//   "exploded" — bar + pod separated along Y for documentation
//   "ghost"    — translucent shells, internals visible

include <lume-config.scad>
use <lume-pod.scad>
use <lume-components.scad>

VIEW = "hero";

// Real bar halves — import the canonical sliced STLs
module bar_real() {
    color("#1f242a", 1.0) {
        import("exports/shell_front_L.stl", convexity=10);
        import("exports/shell_front_R.stl", convexity=10);
        import("exports/shell_rear_L.stl",  convexity=10);
        import("exports/shell_rear_R.stl",  convexity=10);
    }
}

// Pod placed centered behind the bar at Y=POD_FRONT (= LUME_DEPTH/2)
module pod_in_place(exploded=0) {
    // Pod extension is along +Y. The pod modules already place themselves
    // with their front face at Y=0 — we translate them to Y=LUME_DEPTH/2
    // so they land flush against the bar's rear face.
    translate([0, LUME_DEPTH/2 + exploded, 0]) {
        color("#1a2027", 1.0) {
            pod_top();
            pod_bottom();
        }
        // Optional VESA plate stuck on the back
        translate([0, POD_D - 1, 0])
            color("#888888", 0.95) {
                rotate([90, 0, 0])
                    pod_vesa_plate();
            }
        // K11 sled + K11 inside
        translate([0, POD_D/2, -POD_H/2 + 8 + 4]) {
            color("#404040", 0.95) pod_compute_sled();
            translate([0, 0, 14]) {
                rotate([90, 0, 0]) proxy_k11();
            }
        }
    }
}

// Front-of-bar Femto Mega
module femto_in_place() {
    color("#202030") {
        FM_W = 127; FM_D = 65; FM_H = 38;
        translate([0, -LUME_DEPTH/2 + 3 + FM_D/2, 0])
            translate([-FM_W/2, -FM_D/2, -FM_H/2])
                cube([FM_W, FM_D, FM_H]);
        // Rear Jetson hump extending back into the bar (and through to pod)
        HUMP_W = 90; HUMP_D = 25; HUMP_H = 20;
        translate([-HUMP_W/2, -LUME_DEPTH/2 + 3 + FM_D - 5, -HUMP_H/2 + 5])
            cube([HUMP_W, HUMP_D, HUMP_H]);
    }
}

// Floor plate for hero shot
module hero_plate() {
    color("#0a0d12", 0.4)
    translate([-450, -350, -LUME_HEIGHT/2 - 1])
        cube([900, 700, 1]);
}

// ---------- VIEW dispatch ----------

if (VIEW == "hero") {
    bar_real();
    pod_in_place();
    femto_in_place();
    hero_plate();
}
else if (VIEW == "exploded") {
    bar_real();
    pod_in_place(exploded=80);
    femto_in_place();
}
else if (VIEW == "ghost") {
    %bar_real();
    %pod_in_place();
    color("#bb8844") femto_in_place();
}
