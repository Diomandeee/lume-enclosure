// LUME — Joinery calibration coupon
// 3 tongue + 3 groove samples at LIP_CLEAR = 0.1 / 0.2 / 0.3mm.
// Coupons are paired by Y-position: tongue[i] mates with groove[i].
// Numbers (1/2/3) are debossed into the top face so you can identify each
// after print. 1 = 0.10mm, 2 = 0.20mm, 3 = 0.30mm.

include <lume-config.scad>

L        = 50;   // coupon length (X)
W        = 20;   // coupon width (Y)
T        = 6;    // body thickness (Z)
LIP_LEN  = 40;   // length of tongue/groove along X
GAP      = 10;   // spacing between stacked coupons in Y

CLEARANCES = [0.10, 0.20, 0.30];

module body() { cube([L, W, T]); }

module number_deboss(n) {
  translate([L/2, W/2, T - 0.6 + 0.01])
    linear_extrude(height=0.8)
      text(str(n), size=5, halign="center", valign="center",
           font="Helvetica:style=Bold");
}

module tongue_coupon(clear, n) {
  difference() {
    union() {
      body();
      // Tongue: sits flush on top face, centered in Y, runs along X
      translate([(L - LIP_LEN)/2, (W - LIP_W)/2, T])
        cube([LIP_LEN, LIP_W, LIP_H]);
    }
    number_deboss(n);
  }
}

module groove_coupon(clear, n) {
  difference() {
    body();
    // Groove: cut into top, centered, with clearance added all around
    translate([(L - LIP_LEN)/2 - clear,
               (W - LIP_W)/2 - clear,
               T - LIP_H])
      cube([LIP_LEN + 2*clear,
            LIP_W + 2*clear,
            LIP_H + 0.5]);
    number_deboss(n);
  }
}

module tongues_plate() {
  for (i = [0 : len(CLEARANCES) - 1])
    translate([0, i * (W + GAP), 0])
      tongue_coupon(CLEARANCES[i], i + 1);
}

module grooves_plate() {
  for (i = [0 : len(CLEARANCES) - 1])
    translate([0, i * (W + GAP), 0])
      groove_coupon(CLEARANCES[i], i + 1);
}

// ---------- X-seam splice peg-fit coupons ----------
// Tests whether splice-plate alignment pegs (3mm Ø) seat into shell-interior
// pockets at 3 clearance values. Butt face has glue surface; pegs do alignment only.
//
// Peg coupon: slab with 4 pegs on one face (mimics splice plate bond face).
// Pocket coupon: slab with 4 matching pockets (mimics shell interior pocket).

PEG_D      = 3;
PEG_H      = 1.5;
SLAB_W     = 50;
SLAB_H     = 30;
SLAB_T     = 4;
PEG_DX     = 15;
PEG_DZ     = 8;

module peg_coupon(n) {
  difference() {
    union() {
      cube([SLAB_W, SLAB_H, SLAB_T]);
      for (x = [SLAB_W/2 - PEG_DX, SLAB_W/2 + PEG_DX],
           y = [SLAB_H/2 - PEG_DZ, SLAB_H/2 + PEG_DZ])
        translate([x, y, SLAB_T])
          cylinder(d1=PEG_D, d2=PEG_D - 0.4, h=PEG_H);
    }
    translate([SLAB_W/2, SLAB_H/2, SLAB_T - 0.6 + 0.01])
      linear_extrude(height=0.8)
        text(str(n), size=5, halign="center", valign="center",
             font="Helvetica:style=Bold");
  }
}

module pocket_coupon(clear, n) {
  difference() {
    cube([SLAB_W, SLAB_H, SLAB_T]);
    for (x = [SLAB_W/2 - PEG_DX, SLAB_W/2 + PEG_DX],
         y = [SLAB_H/2 - PEG_DZ, SLAB_H/2 + PEG_DZ])
      translate([x, y, SLAB_T - PEG_H])
        cylinder(d=PEG_D + 2*clear, h=PEG_H + 0.3);
    translate([SLAB_W/2, SLAB_H/2, SLAB_T - 0.6 + 0.01])
      linear_extrude(height=0.8)
        text(str(n), size=5, halign="center", valign="center",
             font="Helvetica:style=Bold");
  }
}

module splice_pegs_plate() {
  // One peg coupon (pegs are identical across clearances — fit variance lives in pocket)
  peg_coupon(0);
}

module splice_pockets_plate() {
  for (i = [0 : len(CLEARANCES) - 1])
    translate([0, i * (SLAB_H + GAP), 0])
      pocket_coupon(CLEARANCES[i], i + 1);
}

PART = "both";

if (PART == "tongues")          tongues_plate();
else if (PART == "grooves")     grooves_plate();
else if (PART == "splice_pegs") splice_pegs_plate();
else if (PART == "splice_pockets") splice_pockets_plate();
else {
  tongues_plate();
  translate([L + 20, 0, 0]) grooves_plate();
  translate([0, 3 * (W + GAP) + 10, 0]) splice_pegs_plate();
  translate([SLAB_W + 20, 3 * (W + GAP) + 10, 0]) splice_pockets_plate();
}
