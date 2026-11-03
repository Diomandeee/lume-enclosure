// LUME v2 — Bolt SKU configuration overrides.
//
// This file is INCLUDED INSTEAD OF lume-config.scad for the Bolt-bar build
// path. It defines every constant needed by lume-shell.scad / lume-pod.scad
// at Bolt-SKU values. To regenerate Bolt-bar STLs, set the OpenSCAD
// command-line `-D BOLT_SKU=true` and use lume-tform-bolt-assembly.scad as
// the entrypoint, OR pass per-variable `-D` overrides matching the values
// below.
//
// Rule: if a constant matters for the bar's external shape, the cradle, or
// the pod's K11 housing, override it here. Everything else (joinery, ribbing,
// LED, wordmark, render quality, feature toggles) inherits the v1 defaults
// from lume-config.scad which we're not redefining.
//
// ── 2026-04-27 caliper-verify checklist (when the Bolt arrives) ──
//   [ ] FEMTO_W              measured along the bar X-axis. Target 140 ±0.5.
//   [ ] FEMTO_D              measured along bar Y-axis (front-to-back). Target 39.
//   [ ] FEMTO_H              measured along bar Z-axis (top-to-bottom). Target 30.
//   [ ] FEMTO_MOUNT_PITCH_X  M3 mount-hole spacing along X. Currently 100, TBD.
//   [ ] FEMTO_MOUNT_PITCH_Z  M3 mount-hole spacing along Z. Currently 30, TBD.
//   [ ] USB-C port angle     side-exit vs rear-exit drives umbilical routing.
//   [ ] Tripod bushing       1/4-20 / M4 / nothing? affects optional cradle pin.
//   [ ] Mass with cable      drives torque rating on cradle clamp.
//   [ ] Lens recess depth    nudge CAM_RECESS_DEPTH if lens proud of pill window.
// After verification, re-export STLs:
//   openscad -D BOLT_SKU=true -o exports/sku1-bolt/<part>.stl <part>-source.scad
// then re-render hero shots via render_tform.py --variant bolt.

// ======== EXTERIOR (Bolt overrides) ========
LUME_WIDTH   = 500;     // UNCHANGED — same bar width as Mega SKU
LUME_HEIGHT  = 120;     // UNCHANGED — same bar height
LUME_DEPTH   = 60;      // ⭐ OVERRIDE: was 85. Bolt is 39mm deep, doesn't need 85
                        //   internal cavity becomes 60-6 = 54mm front-to-back
WALL         = 3.0;     // UNCHANGED
CORNER_R     = 8;       // UNCHANGED
INNER_R      = 5;       // UNCHANGED
CHAMFER      = 1.2;     // UNCHANGED

// ======== SPLIT PLANE ========
SPLIT_Y      = 0;       // UNCHANGED — centered split
SPLIT_X      = 80;      // UNCHANGED — keep seam-hide position from v1 fix
SPLIT_SHELL_X = true;
LIP_W        = 2.0;
LIP_H        = 3.0;
LIP_CLEAR    = 0.2;

// ======== COMPONENT FOOTPRINTS (Bolt camera) ========
JETSON_W = 110; JETSON_D = 110; JETSON_H = 72;   // legacy compat — unused in Bolt
JETSON_MOUNT_PITCH = 96;
FEMTO_W  = 140;         // ⭐ OVERRIDE: Bolt is 140mm wide along bar X-axis
FEMTO_D  = 39;          // ⭐ OVERRIDE: Bolt is 39mm deep
FEMTO_H  = 30;          // ⭐ OVERRIDE: Bolt is 30mm tall
FEMTO_MOUNT_PITCH_X = 100;  // ⚠ TBD — verify with caliper on Apr 27
FEMTO_MOUNT_PITCH_Z = 30;   // ⚠ TBD — verify with caliper on Apr 27

// ======== WORDMARK (Bolt SKU) ========
WORDMARK_TEXT  = "LUME";
WORDMARK_H     = 16;
WORDMARK_DEPTH = 1.5;
WORDMARK_Z     = 18;
MIRROR_WORDMARK = false;

// ======== LED diffuser (Bolt SKU — same) ========
LED_W = 460;
LED_H = 6;
LED_Z = -32;
LED_X = 0;
LED_DEPTH = 4;
LED_ID = 8;

// ======== Camera recesses ========
CAM_RECESS_DEPTH = 4;

// ======== End grilles ========
SHOW_END_GRILLES = false;
GRILLE_W = 60;
GRILLE_H = 30;
GRILLE_X_OFFSET = LUME_WIDTH/2 - GRILLE_W/2 - 22;

// ======== VESA on bar rear (Bolt SKU keeps as fallback) ========
VESA_PITCH = 100;
VESA_HOLE_D = 5.4;
VESA_PLATE_T = 4;

// ======== JOINERY ========
INSERT_OD = 4.5;
INSERT_DEPTH = 6;
INSERT_PITCH = 100;
COUNTERBORE_D = 6.0;
CORNER_BOLT_INSET = 14;

// ======== INTERNAL STRUCTURE ========
RIB_T = 2.0;
RIB_H = 8;
RIB_PITCH = 80;
CABLE_CHANNEL_W = 10;
CABLE_CHANNEL_H = 6;
BAFFLE_T = 2.5;
BAFFLE_X = -LUME_WIDTH/2 + 180;

// ======== T-FORM REAR POD (Bolt SKU — slimmer) ========
POD_ENABLED  = true;
// ⭐ VERIFIED K11 spec B0G12MD8RD (2026-04-26).
K11_W  = 131.83;     // was 142.6
K11_D  = 124.46;     // was 113 — drives POD_D bump
K11_H  =  57.91;     // was 49.5
K11_VESA_PITCH = 75;
K11_BOTTOM_FAN_INTAKE = true;
K11_TOP_FAN_EXHAUST   = true;
K11_BOTTOM_CLEAR_MIN  = 12;

POD_W        = 200;     // UNCHANGED
POD_H        = 130;     // ⭐ OVERRIDE: bar height + K11 fan-intake clearance
POD_D        = 165;     // ⭐ OVERRIDE — was 100 (and 130 in Mega config).
                        //   Verified K11_D = 124.5mm + 25 cable-bend + 10 airflow
                        //   rear gap = 159mm internal cavity needed → POD_D=165.
                        //   Bolt SKU has no Mega Jetson hump but still needs
                        //   space for the K11 itself — same constraint as Mega.
POD_X_OFF    = 0;
POD_WALL     = WALL;
POD_FILLET_R = 8;       // ⭐ OVERRIDE: was 12. Tighter visual line on slim bar.

POD_FLANGE_T   = 4;
POD_FLANGE_W   = 12;
POD_BOLT_INSET = 8;

POD_VESA_PITCH = 100;
POD_VESA_PLATE_T = VESA_PLATE_T;

POD_VENT_W = 40;
POD_VENT_H = 4;
POD_VENT_PITCH = 10;
POD_VENT_COUNT = 6;

POD_FEEDTHROUGH_W = 80;
POD_FEEDTHROUGH_H = 24;

// ======== RENDER QUALITY ========
$fa = 2;
$fs = 0.4;

// ======== FEATURE TOGGLES ========
SHOW_COMPONENTS = true;
SHOW_INTERNALS  = true;
EXPLODED        = false;
EXPLODE_DIST    = 60;
USE_JOINERY     = false;

USE_REAL_FEMTO = false;     // Bolt STEP not yet imported. Cube proxy for now.
USE_REAL_BOLT  = false;     // ⚠ flip to true once references/orbbec-femto-bolt.stl lands
