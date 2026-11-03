// LUME — Internal mounts
// Jetson sled, Femto bracket, UMA-8 mic rail, LED diffuser pocket, thermal baffle,
// cable channels, port bracket anchor points, fan shroud.
//
// Layout (viewed from above, front = -Y):
//
//   [  hot zone (left 180mm)    ][  cold zone (right 320mm)                    ]
//   [  Jetson + Noctua + PSU     ][  Femto Mega + UMA-8 + SVPRO cams + LEDs    ]
//                              ^ BAFFLE_X thermal partition

include <lume-config.scad>
use <lume-primitives.scad>

// ---------- Jetson AGX Orin sled — DEPRECATED 2026-04-26 ----------
// LEGACY: this lived in the bar's hot zone when compute was Jetson AGX Orin.
// BOM pivoted 2026-04-25 to GMKtec NucBox K11, T-form pivoted 2026-04-26 to
// pod-mounted compute. Production compute now lives in `pod_compute_sled()`
// inside `lume-pod.scad`. This module is kept only for legacy STL parity —
// do NOT include it in new prints. It has been removed from
// `lume_internals_all()` and from `02_internals_batch.3mf`.

JETSON_ORIGIN_X = -LUME_WIDTH/2 + 80;  // left-biased
JETSON_ORIGIN_Y = 5;
JETSON_FLOOR_Z  = -LUME_HEIGHT/2 + WALL;

module jetson_sled() {
  translate([JETSON_ORIGIN_X, JETSON_ORIGIN_Y, JETSON_FLOOR_Z]) {
    // Base plate
    difference() {
      translate([-JETSON_W/2 - 6, -JETSON_D/2 - 6, 0])
        cchamfer(JETSON_W + 12, JETSON_D + 12, 3);
      // 4x M3 clearance holes matching Jetson carrier 96x96 pattern
      for (x = [-JETSON_MOUNT_PITCH/2, JETSON_MOUNT_PITCH/2],
           y = [-JETSON_MOUNT_PITCH/2, JETSON_MOUNT_PITCH/2])
        translate([x, y, -0.1])
          cylinder(d=BOLT_M3_CLEAR, h=5);
    }
    // Heat-set boss at each mount point (carrier screws down)
    for (x = [-JETSON_MOUNT_PITCH/2, JETSON_MOUNT_PITCH/2],
         y = [-JETSON_MOUNT_PITCH/2, JETSON_MOUNT_PITCH/2])
      translate([x, y, 3])
        insert_boss(h=8);
    // Cable management channel along one edge (for PoE + fan + USB to Femto)
    translate([0, JETSON_D/2 + 12, 3])
      rotate([0, 0, 90])
        cable_clip();
  }
}

// ---------- Noctua NF-A8 fan shroud ----------
// Mounted behind Jetson heatsink, exhausts through rear slot grille

FAN_ORIGIN_X = JETSON_ORIGIN_X;
FAN_ORIGIN_Y = LUME_DEPTH/2 - WALL - FAN_H/2 - 4;
FAN_ORIGIN_Z = VENT_Z;

module fan_shroud() {
  translate([FAN_ORIGIN_X, FAN_ORIGIN_Y, FAN_ORIGIN_Z])
    rotate([90, 0, 0])
      difference() {
        // Shroud body (funnels air from Jetson fins to rear vent)
        translate([-FAN_W/2 - 3, -FAN_W/2 - 3, -FAN_H/2])
          cube([FAN_W + 6, FAN_W + 6, FAN_H]);
        // 80mm fan cavity
        translate([0, 0, -FAN_H/2 - 0.1])
          cylinder(d=FAN_W - 2, h=FAN_H + 0.2);
        // 4 mount holes (71.5mm standard 80mm fan pattern)
        for (x = [-FAN_MOUNT_PITCH/2, FAN_MOUNT_PITCH/2],
             y = [-FAN_MOUNT_PITCH/2, FAN_MOUNT_PITCH/2])
          translate([x, y, -FAN_H/2 - 0.1])
            cylinder(d=BOLT_M3_CLEAR, h=FAN_H + 1);
      }
}

// ---------- Thermal baffle ----------
// Separates hot zone (Jetson) from cold zone (Femto + mic) — reduces thermal
// noise at Femto IR sensor and keeps UMA-8 away from fan turbulence.

module thermal_baffle() {
  translate([BAFFLE_X, 0, 0])
    difference() {
      cube([BAFFLE_T,
            LUME_DEPTH - 2*WALL - 2,
            LUME_HEIGHT - 2*WALL - 2],
           center=true);
      // Cable pass-through cutout (one hole near floor for Femto USB + LED ribbon)
      translate([0, 0, -LUME_HEIGHT/2 + WALL + 15])
        rotate([0, 90, 0])
          cylinder(d=18, h=BAFFLE_T*2, center=true);
    }
}

// ---------- Femto Mega bottom/side cradle ----------
// Replaces the old front-wall bracket. The datasheet says the full camera is
// 115 x 40 x 145mm and warns not to obstruct the cooling channel between the
// front head and rear sleeve. This cradle supports the body from below/sides
// and deliberately leaves the full front black pill window unobstructed.

module femto_mount_local() {
  difference() {
    union() {
      // Bottom shelf.
      translate([0, 0, -FEMTO_CRADLE_T/2])
        cube([FEMTO_CRADLE_W, FEMTO_CRADLE_D, FEMTO_CRADLE_T], center=true);
      // Left/right low side rails; below sensor centerline, behind front face.
      for (x = [-FEMTO_CRADLE_W/2 + FEMTO_CRADLE_SIDE_T/2,
                 FEMTO_CRADLE_W/2 - FEMTO_CRADLE_SIDE_T/2])
        translate([x, 0, FEMTO_CRADLE_SIDE_H/2])
          cube([FEMTO_CRADLE_SIDE_T, FEMTO_CRADLE_D, FEMTO_CRADLE_SIDE_H],
               center=true);
      // Rear stop keeps the body from sliding back into the pod.
      translate([0, FEMTO_CRADLE_D/2 - FEMTO_CRADLE_REAR_STOP_T/2, FEMTO_CRADLE_SIDE_H/2])
        cube([FEMTO_CRADLE_W, FEMTO_CRADLE_REAR_STOP_T, FEMTO_CRADLE_SIDE_H],
             center=true);
    }
    // Bottom 1/4-20 access/clearance hole. Final screw position still needs
    // a caliper check against the actual unit.
    translate([0, -FEMTO_CRADLE_D * 0.12, -FEMTO_CRADLE_T])
      cylinder(d=FEMTO_TRIPOD_HOLE_D, h=FEMTO_CRADLE_T * 3, center=true);
    // Weight/cable relief slots.
    for (x = [-36, -18, 18, 36])
      translate([x, 12, -FEMTO_CRADLE_T])
        cube([8, 44, FEMTO_CRADLE_T * 3], center=true);
  }
}

module femto_mount() {
  // Camera front face aligns to Y=-LUME_DEPTH/2. Keep the cradle fully behind
  // the front wall with service clearance so it cannot collide with the shell
  // or mask the lens/depth sensors.
  translate([CAM_CENTER_X,
             -LUME_DEPTH/2 + WALL + 5 + FEMTO_CRADLE_D/2,
             -FEMTO_H/2 - FEMTO_CRADLE_T/2 - 1])
    femto_mount_local();
}

// ---------- SVPRO camera brackets (L + R) ----------

module svpro_bracket(x_pos) {
  translate([x_pos, -LUME_DEPTH/2 + WALL + SVPRO_D/2, 0])
    difference() {
      translate([-SVPRO_W/2 - 4, -SVPRO_D/2 - 2, -SVPRO_H/2 - 3])
        cube([SVPRO_W + 8, 3, SVPRO_H + 6]);
      // 2 mount holes (SVPRO has M3 tabs top + bottom)
      for (z = [-SVPRO_H/2 + 4, SVPRO_H/2 - 4])
        translate([0, -SVPRO_D/2 - 3, z])
          rotate([-90, 0, 0])
            cylinder(d=BOLT_M3_CLEAR, h=5);
    }
}

// ---------- Arducam IMX586 front-right mount ----------
// Print orientation: flat on bed. Assembly orientation rotates the plate so
// it sits just behind the front wall with the lens and mount holes aligned.

module arducam_mount_local() {
  plate_w = ARDUCAM_CASE_W + 12;
  plate_h = ARDUCAM_CASE_H + 12;
  difference() {
    rplate(plate_w, plate_h, ARDUCAM_MOUNT_T, 4);
    // Lens clearance through the printed plate.
    cylinder(d=ARDUCAM_LENS_HOLE_D + 2, h=ARDUCAM_MOUNT_T + 1, center=true);
    // Metal-case mounting holes.
    for (x = [-ARDUCAM_MOUNT_PITCH/2, ARDUCAM_MOUNT_PITCH/2],
         y = [-ARDUCAM_MOUNT_PITCH/2, ARDUCAM_MOUNT_PITCH/2])
      translate([x, y, 0])
        cylinder(d=ARDUCAM_MOUNT_HOLE_D, h=ARDUCAM_MOUNT_T + 1, center=true);
    // Bottom/rear Type-C cable notch.
    translate([0, -plate_h/2 + 4, 0])
      cube([ARDUCAM_CABLE_SLOT_W, ARDUCAM_CABLE_SLOT_H, ARDUCAM_MOUNT_T + 1],
           center=true);
  }
}

module arducam_mount(cam_x=ARDUCAM_X) {
  translate([cam_x, -LUME_DEPTH/2 + WALL + ARDUCAM_MOUNT_T/2 + 0.5, ARDUCAM_Z])
    rotate([90, 0, 0])
      arducam_mount_local();
}

// ---------- UMA-8 microphone rail ----------
// Disc sits flat along top interior; USB exits top-rear.

module mic_rail() {
  translate([100, 0, LUME_HEIGHT/2 - WALL - UMA8_H - 4])
    difference() {
      // Recessed cradle plate
      cylinder(d=UMA8_OD + 12, h=4);
      // Disc seat (slightly oversized for easy drop-in)
      translate([0, 0, 1])
        cylinder(d=UMA8_OD + 0.6, h=UMA8_H + 5);
      // 3 mount screw holes (UMA-8 has 3 M2.5 tabs at 120°)
      for (a = [0, 120, 240])
        rotate([0, 0, a])
          translate([UMA8_OD/2 + 3, 0, -0.1])
            cylinder(d=2.7, h=6);
    }
  // USB cable exit clip
  translate([100, UMA8_OD/2 + 8, LUME_HEIGHT/2 - WALL - 8])
    cable_clip(w=6, h=4);
}

// ---------- LED diffuser (clear PETG, printed separately) ----------
// Prints as a ring with a flange that seats into the front-shell recess.

module led_diffuser() {
  translate([LED_X, -LUME_DEPTH/2 + WALL - 0.2, LED_Z])
    rotate([-90, 0, 0])
      difference() {
        union() {
          // Flange (sits inside shell recess)
          cylinder(d=LED_OD + 4, h=1.5);
          // Diffuser ring (light-pipe wall)
          translate([0, 0, 1.5])
            cylinder(d=LED_OD + 1.0, h=LED_H - 1.5);
          // Inner wall (hides LED backs from outside view)
          translate([0, 0, 1.5])
            cylinder(d=LED_RING_ID - 2, h=LED_H - 1.5);
        }
        // Hollow center — LED ring sits inside
        translate([0, 0, 1.5 - 0.1])
          difference() {
            cylinder(d=LED_OD - 2, h=LED_H);
            cylinder(d=LED_RING_ID + 2, h=LED_H*2, center=true);
          }
        // Through-light window (exit aperture — sized to single-disc indicator)
        translate([0, 0, -0.1])
          cylinder(d1=LED_OD_INDICATOR - 4, d2=LED_OD_INDICATOR - 2, h=1.6);
      }
}

// ---------- Cable routing backbone ----------
// Horizontal channel along bottom-interior — routes everything from left (Jetson)
// to right (Femto/mic/LED). Baffle has a pass-through hole that aligns with this.

module cable_backbone() {
  backbone_z = -LUME_HEIGHT/2 + WALL + 4;
  // Channel clips every 80mm
  for (x = [-LUME_WIDTH/2 + 60 : 80 : LUME_WIDTH/2 - 60])
    translate([x, 0, backbone_z])
      rotate([0, 0, 90])
        cable_clip(w=SENSOR_CABLE_BUNDLE_W, h=SENSOR_CABLE_BUNDLE_H);
}

// ---------- Port bracket anchor posts ----------
// The actual port bracket is a separate printed part (lume-port-bracket.scad)
// These posts hold it in place on the rear wall interior.

module port_bracket_anchors() {
  for (x = [PORT_CLUSTER_X - 35, PORT_CLUSTER_X + 35])
    translate([x, LUME_DEPTH/2 - WALL - 10, PORT_CLUSTER_Z - 15])
      insert_boss(h=8);
  for (x = [PORT_CLUSTER_X - 35, PORT_CLUSTER_X + 35])
    translate([x, LUME_DEPTH/2 - WALL - 10, PORT_CLUSTER_Z + 15])
      insert_boss(h=8);
}

// ---------- X-seam splice plate ----------
// Bonds shell_{front,rear}_L to shell_{front,rear}_R across the X=SPLIT_X seam.
// Two per assembly: one CA-glued to interior of front wall, one to rear wall.
// Corner bolts (front↔rear) + splice plates (L↔R) together form the full bond.
//
// Geometry: 80mm (X) × 60mm (Z) × 3mm (Y), rounded corners.
// Alignment pegs (3mm Ø × 1.5mm tall) on bond face — drop into matching pockets
// in the shell interior (Phase 1 Track B adds those pockets).

SPLICE_W       = 80;   // X span, 40mm each side of seam
SPLICE_H       = 60;   // Z height (interior is 114mm, half-height leaves room for ribs)
SPLICE_T       = 3;    // Y thickness (matches WALL)
SPLICE_R       = 4;    // corner radius
SPLICE_PEG_D   = 3;    // alignment peg diameter
SPLICE_PEG_H   = 1.5;  // peg height above bond face
SPLICE_PEG_DX  = 30;   // peg X offset from seam center
SPLICE_PEG_DZ  = 20;   // peg Z offset from plate center

// Plate lives in XY (80 × 60), thickness along Z (3mm). Pegs on +Z bond face.
module splice_plate() {
  union() {
    rplate(SPLICE_W, SPLICE_H, SPLICE_T, SPLICE_R);
    for (x = [-SPLICE_PEG_DX, SPLICE_PEG_DX],
         z = [-SPLICE_PEG_DZ, SPLICE_PEG_DZ])
      translate([x, z, SPLICE_T/2])
        cylinder(d1=SPLICE_PEG_D, d2=SPLICE_PEG_D - 0.4, h=SPLICE_PEG_H);
  }
}

// Assembled: rotate plate so its 80×60 face lies against shell inner wall (XZ plane).
// Bond face (+Z of local plate) rotates to face +Y (front splice) or -Y (rear splice).
module splice_plate_front() {
  translate([SPLIT_X, -LUME_DEPTH/2 + WALL + SPLICE_T/2, 0])
    rotate([-90, 0, 0])
      splice_plate();
}

module splice_plate_rear() {
  translate([SPLIT_X, LUME_DEPTH/2 - WALL - SPLICE_T/2, 0])
    rotate([90, 0, 0])
      splice_plate();
}

// Print-oriented: plate flat on bed, pegs up. Two copies side-by-side on plate.
module splice_plate_print() {
  for (dx = [-SPLICE_W/2 - 8, SPLICE_W/2 + 8])
    translate([dx, 0, SPLICE_T/2])
      splice_plate();
}

// ---------- Master call: all internals ----------

module lume_internals_all() {
  // jetson_sled() removed 2026-04-26 — compute lives in pod (see lume-pod.scad).
  if (LEGACY_BAR_COMPUTE_PARTS_ENABLED) {
    fan_shroud();
    thermal_baffle();
  }
  femto_mount();
  if (SVPRO_LEGACY_ENABLED) {
    svpro_bracket(CAM_LEFT_X);
    svpro_bracket(CAM_RIGHT_X);
  }
  if (ARDUCAM_ENABLED)
    for (cam_x = ARDUCAM_XS)
      arducam_mount(cam_x);
  mic_rail();
  cable_backbone();
  if (!POD_ENABLED) port_bracket_anchors();
  splice_plate_front();
  splice_plate_rear();
}

// ---------- Per-part dispatcher for STL export ----------
// Invoke with: openscad -o part.stl -D 'PART="jetson_sled"' lume-internals.scad
// Each branch lifts the part to Z=0 with a flat base so it prints directly.

PART = "all";  // override at CLI

if      (PART == "all")             lume_internals_all();
else if (PART == "jetson_sled")     translate([0, 0, -(-LUME_HEIGHT/2 + WALL + 2)]) jetson_sled();
else if (PART == "fan_shroud")      translate([0, 0, -(-LUME_HEIGHT/2 + WALL + 2)]) fan_shroud();
else if (PART == "thermal_baffle")  thermal_baffle();
else if (PART == "femto_mount")     femto_mount_local();
else if (PART == "svpro_L")         svpro_bracket(CAM_LEFT_X);
else if (PART == "svpro_R")         svpro_bracket(CAM_RIGHT_X);
else if (PART == "arducam_mount")   arducam_mount_local();
else if (PART == "mic_rail")        mic_rail();
else if (PART == "led_diffuser")    led_diffuser();
else if (PART == "cable_backbone")  cable_backbone();
else if (PART == "port_anchors")    port_bracket_anchors();
else if (PART == "splice_plate")    splice_plate_print();
