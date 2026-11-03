// LUME — Component proxy volumes
// Non-printable reference bodies used as negative space inside the shell.
// Replace with real vendor STEP files once downloaded.

include <lume-config.scad>

// Jetson AGX Orin Dev Kit (carrier + heatsink + fan) — LEGACY / DEPRECATED.
// BOM pivoted 2026-04-25: K11. T-form pivoted 2026-04-26: K11 lives in pod.
// Use `proxy_k11()` below instead. This stub is retained ONLY so legacy
// scenes (lume-main.scad, lume-annotations.scad) don't error out on import,
// and so the legacy `internal_jetson_sled.stl` keeps a callable reference.
// DO NOT add new call sites.
module proxy_jetson() {
  color("#303040")
    translate([-JETSON_W/2, -JETSON_D/2, 0])
      cube([JETSON_W, JETSON_D, JETSON_H]);
}

// GMKtec NucBox K11 (production compute, lives in rear pod when POD_ENABLED).
// Lays flat with K11_W along bar X, K11_D along pod Y, and K11_H vertical.
// Origin at K11 centroid for easy positioning by callers.
module proxy_k11() {
  color("#5a8a5a")
    translate([-K11_W/2, -K11_D/2, -K11_H/2])
      cube([K11_W, K11_D, K11_H]);
}

// Orbbec Femto Mega — real STEP available
// references/orbbec-femto-mega.stp (official, github.com/orbbec/OrbbecHardware)
// OpenSCAD can't import STEP directly. Convert once:
//   FreeCAD → open .stp → export as STL → references/orbbec-femto-mega.stl
// Then flip USE_REAL_FEMTO=true in lume-config.scad.
USE_REAL_FEMTO = true;
module proxy_femto() {
  if (USE_REAL_FEMTO) {
    // STL bbox probed: X[-0.6,114.6] Y[-6.4,145.2] Z[-39.6,0.6]; centroid [57.0, 69.4, -19.5]
    color("#202030")
      translate([-57.0, -69.4, 19.5])
        import("references/orbbec-femto-mega.stl", convexity=10);
  } else {
    color("#202030")
      translate([-FEMTO_W/2, -FEMTO_D/2, -FEMTO_H/2])
        cube([FEMTO_W, FEMTO_D, FEMTO_H]);
  }
}

// miniDSP UMA-8 v2 (7-mic disc)
module proxy_uma8() {
  color("#101010")
    cylinder(d=UMA8_OD, h=UMA8_H);
}

// Noctua NF-A8 fan
module proxy_fan() {
  color("#5C3A21")
    translate([-FAN_W/2, -FAN_W/2, 0])
      cube([FAN_W, FAN_W, FAN_H]);
}

// SVPRO IMX577 camera module
module proxy_svpro() {
  color("#202020") {
    translate([-SVPRO_W/2, -SVPRO_D/2, 0])
      cube([SVPRO_W, SVPRO_D, SVPRO_H-10]);
    translate([0, 0, SVPRO_H-10])
      cylinder(d=18, h=10);   // lens barrel
  }
}

// Arducam B0478/B0478C IMX586 USB camera module.
// Body is oriented with its lens facing front (-Y) and Type-C exiting rear.
module proxy_arducam() {
  color("#181818")
    translate([-ARDUCAM_CASE_W/2, -ARDUCAM_CASE_D/2, -ARDUCAM_CASE_H/2])
      cube([ARDUCAM_CASE_W, ARDUCAM_CASE_D, ARDUCAM_CASE_H]);
  color("#050505")
    translate([0, -ARDUCAM_CASE_D/2 - 3, 0])
      rotate([90, 0, 0])
        cylinder(d=ARDUCAM_LENS_HOLE_D - 2, h=6);
  color("#333333")
    translate([0, ARDUCAM_CASE_D/2 + 0.5, -ARDUCAM_CASE_H/2 + 7])
      cube([ARDUCAM_CABLE_SLOT_W, 2, ARDUCAM_CABLE_SLOT_H], center=true);
}

// ZHAOCAILIN 11.3" cased bar display, modeled as a top-mounted object.
module proxy_top_display() {
  color("#111318")
    translate([-DISPLAY_W/2, -DISPLAY_H/2, -DISPLAY_THICK/2])
      cube([DISPLAY_W, DISPLAY_H, DISPLAY_THICK]);
  color("#05070a")
    translate([-DISPLAY_W/2 + 5, -DISPLAY_H/2 + 5, DISPLAY_THICK/2 + 0.05])
      cube([DISPLAY_W - 10, DISPLAY_H - 10, 0.4]);
}

// NeoPixel 24 LED ring
module proxy_led_ring() {
  color("#E0E0E0")
    difference() {
      cylinder(d=LED_OD, h=LED_H);
      translate([0, 0, -0.1])
        cylinder(d=LED_ID, h=LED_H+0.2);
    }
}
