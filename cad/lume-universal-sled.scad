// LUME — Universal pod sled (#186)
//
// Hot-swap mounting for K11 (NucBox 8945HS) OR Mac mini M4 inside the
// pod. Same external footprint, same pod-floor fasteners, same
// ventilation. Compute-specific mounting moves to a swappable
// adapter plate that bolts to the base via a shared 100x100 hot-swap
// pattern.
//
// Three modules:
//   universal_sled_base()              base tray + pod mounts + intake vents
//   adapter_plate_k11()                K11 VESA75 + bottom-fan standoffs
//   adapter_plate_mac_mini_m4()        Mac mini M4 cradle (no VESA, bumpered)
//
// PART selector at the bottom. Render any single piece for printing or
// the full assembly for fit visualisation.
//
// Dimensions reference lume-config.scad for K11_*. Mac mini M4 numbers
// pinned from Apple spec sheet (caliper-verify on arrival).

include <lume-config.scad>

// ---- Mac mini M4 constants (caliper-verify on arrival) ----------------
MM_W = 127.0;   // width
MM_D = 127.0;   // depth
MM_H = 50.0;    // height
MM_FOOT_INSET = 12;     // rubber-foot pad inset from corner (Apple spec)
MM_FOOT_DIA   = 12;     // rubber-foot diameter
MM_REAR_PORT_CLEAR = 8; // mm cable bend radius behind rear port row

// ---- Hot-swap pattern (adapter -> base) -------------------------------
HOT_SWAP_PITCH = 100;   // bolt pattern square, mm
HOT_SWAP_BOLT_DIA = 4.4; // M4 clearance
HOT_SWAP_INSERT_DIA = 5.0; // heat-set insert ID for M4

// ---- Sled outer geometry ----------------------------------------------
// Pick the larger of K11 and Mac mini footprints, plus 4 mm clearance
// on each side, so either compute fits without sled-side adjustment.
US_W = max(K11_W, MM_W) + 8;          // 132+8 = 140; MM 127+8 = 135 -> takes max
US_D = max(K11_D, MM_D) + 8;
US_BASE_T = 4;                         // base plate thickness
US_RIM_H = 12;                         // retaining rim height
US_RIM_OPEN_BACK_FRAC = 0.6;           // fraction of back wall removed for cabling

// Pod-floor mount: corner clusters of M3 holes
US_POD_BOLT_DIA = 3.4;                 // M3 clearance
US_POD_BOLT_INSET = 8;                 // from sled corner

// Intake slots (live in the base plate)
US_INTAKE_SLOT_W = 8;
US_INTAKE_SLOT_D = 92;
US_INTAKE_SLOT_X_PITCH = 18;
US_INTAKE_SLOT_COUNT = 7;

// =======================================================================
// universal_sled_base()
// =======================================================================
module universal_sled_base() {
  difference() {
    union() {
      // Base plate
      translate([-US_W/2, -US_D/2, 0])
        cube([US_W, US_D, US_BASE_T]);

      // Three-sided retaining rim (back open for compute port access).
      translate([-US_W/2, -US_D/2, US_BASE_T])
        difference() {
          cube([US_W, US_D, US_RIM_H]);
          // Hollow inside
          translate([POD_WALL, POD_WALL, -1])
            cube([US_W - POD_WALL*2,
                  US_D - POD_WALL*2,
                  US_RIM_H + 2]);
          // Cut the back wall (where cables emerge)
          back_w = US_W * US_RIM_OPEN_BACK_FRAC;
          translate([-back_w/2 + US_W/2, US_D - POD_WALL - 1, -1])
            cube([back_w, POD_WALL + 2, US_RIM_H + 2]);
        }
    }

    // Bottom intake slots (CPU bottom-fan friendly: K11 needs them, Mac mini
    // doesn't but they don't hurt and improve passive convection).
    intake_x_start = -((US_INTAKE_SLOT_COUNT - 1) * US_INTAKE_SLOT_X_PITCH) / 2;
    for (i = [0 : US_INTAKE_SLOT_COUNT - 1])
      translate([intake_x_start + i * US_INTAKE_SLOT_X_PITCH, 0, -1])
        cube([US_INTAKE_SLOT_W, US_INTAKE_SLOT_D, US_BASE_T + 2], center=true);

    // Hot-swap bolt pattern: 100x100 square, M4 clearance through base.
    // Adapter plate bolts down INTO the sled via these holes.
    for (x = [-HOT_SWAP_PITCH/2, HOT_SWAP_PITCH/2],
         y = [-HOT_SWAP_PITCH/2, HOT_SWAP_PITCH/2])
      translate([x, y, -1])
        cylinder(d=HOT_SWAP_BOLT_DIA, h=US_BASE_T + 2, $fn=24);

    // 4 corner pod-floor mount holes (M3 into heat-set inserts in the pod
    // floor). Same 4-corner pattern as the legacy K11-only sled so a swap
    // doesn't require new pod inserts.
    for (x = [-US_W/2 + US_POD_BOLT_INSET, US_W/2 - US_POD_BOLT_INSET],
         y = [-US_D/2 + US_POD_BOLT_INSET, US_D/2 - US_POD_BOLT_INSET])
      translate([x, y, -1])
        cylinder(d=US_POD_BOLT_DIA, h=US_BASE_T + 2, $fn=18);
  }
}

// =======================================================================
// adapter_plate_k11()
// =======================================================================
// Bolts down to universal_sled_base via 100x100 hot-swap pattern.
// Provides K11 VESA75 bolt pattern + 12 mm bottom-fan standoffs.
module adapter_plate_k11() {
  ap_w = HOT_SWAP_PITCH + 24;
  ap_d = HOT_SWAP_PITCH + 24;
  ap_t = 4;
  standoff_h = K11_BOTTOM_CLEAR_MIN;

  difference() {
    union() {
      // Plate
      translate([-ap_w/2, -ap_d/2, 0])
        cube([ap_w, ap_d, ap_t]);

      // K11 VESA75 standoffs (cylinders rising above the plate)
      for (x = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2],
           y = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2])
        translate([x, y, ap_t])
          cylinder(d=10, h=standoff_h, $fn=32);
    }

    // K11 VESA75 bolt pass-throughs (M4 clearance) all the way through
    for (x = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2],
         y = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2])
      translate([x, y, -1])
        cylinder(d=4.4, h=ap_t + standoff_h + 2, $fn=24);

    // Hot-swap bolt holes (M4 clearance) — 100x100
    for (x = [-HOT_SWAP_PITCH/2, HOT_SWAP_PITCH/2],
         y = [-HOT_SWAP_PITCH/2, HOT_SWAP_PITCH/2])
      translate([x, y, -1])
        cylinder(d=HOT_SWAP_BOLT_DIA, h=ap_t + 2, $fn=24);

    // Inner relief slot — keeps the K11 bottom fan unblocked even at the
    // standoff perimeter.
    translate([0, 0, -1])
      cube([K11_VESA_PITCH - 16, K11_VESA_PITCH - 16, ap_t + 2], center=true);
  }
}

// =======================================================================
// adapter_plate_mac_mini_m4()
// =======================================================================
// Bolts down to universal_sled_base via the same 100x100 hot-swap pattern.
// Mac mini M4 has NO VESA — gravity sits on a bumper-pad floor with two
// soft-rubber side rails preventing slide. Cable strain relief at the rear.
module adapter_plate_mac_mini_m4() {
  ap_w = HOT_SWAP_PITCH + 24;
  ap_d = HOT_SWAP_PITCH + 24;
  ap_t = 4;
  // Cradle wall: short bumpers along the LEFT and RIGHT sides only,
  // leaving FRONT and REAR open for ports + cable bend radius.
  bumper_h = 6;       // mm above plate
  bumper_w = 4;       // wall thickness
  bumper_d = MM_D * 0.7;

  difference() {
    union() {
      // Plate
      translate([-ap_w/2, -ap_d/2, 0])
        cube([ap_w, ap_d, ap_t]);

      // Bumper rails (left, right). Inset slightly so Mac mini drops in
      // without scraping.
      cradle_inner_w = MM_W + 1.5;  // 0.75 mm clearance per side
      for (x_sign = [-1, 1])
        translate([x_sign * (cradle_inner_w/2 + bumper_w/2),
                   -bumper_d/2,
                   ap_t])
          cube([bumper_w, bumper_d, bumper_h], center=false);

      // 4 corner foot pads (rubber-foot-aligned bosses) — give the
      // Mac mini's rubber feet something firm to sit on.
      for (x_sign = [-1, 1], y_sign = [-1, 1])
        translate([x_sign * (MM_W/2 - MM_FOOT_INSET),
                   y_sign * (MM_D/2 - MM_FOOT_INSET),
                   ap_t])
          cylinder(d=MM_FOOT_DIA + 4, h=1.5, $fn=32);
    }

    // Hot-swap bolt holes (M4 clearance) — 100x100
    for (x = [-HOT_SWAP_PITCH/2, HOT_SWAP_PITCH/2],
         y = [-HOT_SWAP_PITCH/2, HOT_SWAP_PITCH/2])
      translate([x, y, -1])
        cylinder(d=HOT_SWAP_BOLT_DIA, h=ap_t + 2, $fn=24);

    // Air-flow window (Mac mini bottom is the intake on M-series; keep
    // air path open through the plate).
    translate([0, 0, -1])
      cube([MM_W - 30, MM_D - 30, ap_t + 2], center=true);
  }
}

// =======================================================================
// Render selector
// =======================================================================
PART = "assembly_k11";
//   "base"             - just the universal sled base
//   "adapter_k11"      - K11 adapter plate
//   "adapter_mac_mini" - Mac mini M4 adapter plate
//   "assembly_k11"     - sled + K11 adapter + K11 proxy (visual fit check)
//   "assembly_mac_mini"- sled + MM adapter + Mac mini proxy (visual fit check)
//   "all_print"        - 3 parts laid out for build-plate inspection

if (PART == "base")                  universal_sled_base();
else if (PART == "adapter_k11")      adapter_plate_k11();
else if (PART == "adapter_mac_mini") adapter_plate_mac_mini_m4();

else if (PART == "assembly_k11") {
  universal_sled_base();
  translate([0, 0, US_BASE_T]) adapter_plate_k11();
  // K11 proxy on top of standoffs
  translate([0, 0, US_BASE_T + 4 + K11_BOTTOM_CLEAR_MIN])
    color("#303040") cube([K11_W, K11_D, K11_H], center=true);
}
else if (PART == "assembly_mac_mini") {
  universal_sled_base();
  translate([0, 0, US_BASE_T]) adapter_plate_mac_mini_m4();
  // Mac mini proxy resting on cradle pads
  translate([0, 0, US_BASE_T + 4 + 1.5])
    color("#cccccc") cube([MM_W, MM_D, MM_H], center=true);
}
else if (PART == "all_print") {
  // 3 parts laid flat for build-plate review
  universal_sled_base();
  translate([US_W + 20, 0, 0]) adapter_plate_k11();
  translate([2 * (US_W + 20), 0, 0]) adapter_plate_mac_mini_m4();
}
else {
  // default: K11 assembly
  universal_sled_base();
  translate([0, 0, US_BASE_T]) adapter_plate_k11();
  translate([0, 0, US_BASE_T + 4 + K11_BOTTOM_CLEAR_MIN])
    color("#303040") cube([K11_W, K11_D, K11_H], center=true);
}
