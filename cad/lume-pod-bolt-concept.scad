// LUME T-form concept — bar + rear pod
// 2026-04-26 — proposal: separate compute pod behind the bar so the bar keeps
// its slim Sonos profile and the K11 + Mega + cables get a proper volume.
//
// Render: openscad -o lume-pod-concept.stl lume-pod-concept.scad
// Or load in OpenSCAD GUI for live preview.

include <lume-config-bolt.scad>;

// --- Pod parameters (all editable here) ---
POD_W       = 200;   // pod width along bar X-axis
POD_H       = LUME_HEIGHT;  // match bar height for a clean side silhouette
POD_D       = 120;   // pod depth along bar Y-axis (extension behind bar)
POD_X_OFF   = 0;     // 0 = centered, negative = shift left
POD_VESA_PITCH = 100;  // VESA 100×100 on back of pod

// Whether to fillet the pod-bar transition for visual continuity.
POD_FILLET  = true;
POD_FILLET_R = 12;

// --- Front bar (current LUME shell) ---
module front_bar() {
    // Use a simple cube proxy — real bar is the existing shell halves
    color("#222831", 0.9)
    translate([-LUME_WIDTH/2, -LUME_DEPTH/2, -LUME_HEIGHT/2])
        cube([LUME_WIDTH, LUME_DEPTH, LUME_HEIGHT]);
}

// --- Rear pod (new compute enclosure) ---
module rear_pod() {
    color("#1a2027", 0.95)
    translate([POD_X_OFF - POD_W/2, LUME_DEPTH/2, -POD_H/2])
        cube([POD_W, POD_D, POD_H]);
}

// Optional fillet between bar back face and pod front face — gives the
// transition a soft chamfer instead of a hard 90° step.
module fillet_strip() {
    if (POD_FILLET) {
        color("#3a4252", 0.85)
        translate([POD_X_OFF - POD_W/2, LUME_DEPTH/2 - POD_FILLET_R/2,
                   -POD_H/2])
            // Triangular chamfer prism running the pod width.
            rotate([0, 0, 0])
                linear_extrude(height=POD_H)
                    polygon(points=[[0, 0],
                                    [POD_W, 0],
                                    [POD_W, POD_FILLET_R],
                                    [0, POD_FILLET_R]]);
    }
}

// --- Internal callouts (visualisation) ---
module k11_proxy() {
    // K11 published spec: 142.6 × 113 × 49.5mm — landscape flat
    K11_W = 142.6; K11_D = 113; K11_H = 49.5;
    color("#5a8a5a", 0.85)
    translate([POD_X_OFF - K11_W/2,
               LUME_DEPTH/2 + 10,                  // 10mm clearance from bar back
               -POD_H/2 + 8])                      // 8mm off pod floor for airflow
        cube([K11_W, K11_D, K11_H]);
}

module femto_proxy() {
    // Femto Mega: 127×65×38 with rear Jetson hump (extra 25mm in -Y direction)
    // Mounted in FRONT half of bar; hump extends back into pod.
    FM_W = 127; FM_D = 65; FM_H = 38;
    HUMP_D = 25;
    color("#a08020", 0.9)
    union() {
        // Main body in front bar
        translate([-FM_W/2, -LUME_DEPTH/2 + 3, -FM_H/2])
            cube([FM_W, FM_D, FM_H]);
        // Rear Jetson hump extending into pod
        translate([-FM_W/2 + 20, FM_D/2 - LUME_DEPTH/2 + 3, -FM_H/2 + 10])
            cube([FM_W - 40, HUMP_D, FM_H - 20]);
    }
}

module vesa_pad() {
    // VESA 100×100 mount pads on REAR face of pod (against wall)
    color("#888", 0.9)
    for (x = [-POD_VESA_PITCH/2, POD_VESA_PITCH/2],
         z = [-POD_VESA_PITCH/2, POD_VESA_PITCH/2]) {
        translate([POD_X_OFF + x - 4, LUME_DEPTH/2 + POD_D - 1, z - 4])
            cube([8, 2, 8]);
    }
}

// --- Assembly ---
module lume_t_form() {
    front_bar();
    rear_pod();
    fillet_strip();
    k11_proxy();
    femto_proxy();
    vesa_pad();
}

lume_t_form();
