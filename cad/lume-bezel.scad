// LUME — Front bezel insert
// Separate printed part. Snaps into the front face of the shell and provides
// clean camera bezels + LED aperture + wordmark edge. Printed in same ASA as
// shell, or in a contrasting color for a two-tone look.
//
// Why separate? Camera cutouts on the main shell are loose clearance holes.
// The bezel gives a crisp visible edge, hides print seam around sensors, and
// makes it easy to swap out later (blank plug for right SVPRO in v1 demo rigs).

include <lume-config.scad>
use <lume-primitives.scad>

BEZEL_W = LUME_WIDTH - 12;   // slightly inset from shell edges
BEZEL_H = 80;                // only covers sensor band, not end grilles
BEZEL_T = 2.0;
BEZEL_FLANGE = 1.2;          // lip that sits behind front wall to locate bezel

module lume_bezel() {
  difference() {
    union() {
      // Main face plate (rounded corners)
      rplate(BEZEL_W, BEZEL_H, BEZEL_T, 4);
      // Locating flange (pushes into shell cavity, holds bezel flush)
      translate([0, 0, -BEZEL_FLANGE/2 - BEZEL_T/2])
        rplate(BEZEL_W - 4, BEZEL_H - 4, BEZEL_FLANGE, 3);
    }
    // Camera through-holes (generous — the camera lens protrudes through)
    for (x = [CAM_LEFT_X, CAM_CENTER_X, CAM_RIGHT_X])
      translate([x, 0, 0]) {
        // Through-hole
        cylinder(d=CAM_HOLE_D, h=BEZEL_T*3, center=true);
        // Countersunk bezel ring on face
        translate([0, 0, BEZEL_T/2 - 0.6])
          cylinder(d1=CAM_BEZEL_OD, d2=CAM_HOLE_D + 1, h=0.8);
      }
    // LED ring window (matches diffuser flange)
    translate([LED_X, LED_Z, 0])
      cylinder(d=LED_OD + 1, h=BEZEL_T*3, center=true);
    // Wordmark recess (mirrors shell wordmark if bezel is face-exposed)
    translate([0, WORDMARK_Z, BEZEL_T/2 - WORDMARK_DEPTH])
      linear_extrude(height=WORDMARK_DEPTH + 0.1)
        text(WORDMARK_TEXT, size=WORDMARK_H, font="Helvetica:style=Bold",
             halign="center", valign="center");
    // 4 snap-fit clip slots (bezel clicks in via the shell's interior ribs)
    for (x = [-BEZEL_W/2 + 20, BEZEL_W/2 - 20])
      for (z = [-BEZEL_H/2 + 8, BEZEL_H/2 - 8])
        translate([x, z, -BEZEL_T/2 - 0.1])
          cylinder(d=4, h=BEZEL_T + BEZEL_FLANGE + 0.5);
  }
}

// ---------- Blank plug (for v1 demo with only 2 cameras) ----------

module lume_cam_plug() {
  union() {
    // Body
    difference() {
      cylinder(d=CAM_HOLE_D - 0.3, h=WALL + 0.5);
      translate([0, 0, WALL - 0.3])
        cylinder(d=3, h=1.0);
    }
    // Bezel lip (sits on outside of shell)
    translate([0, 0, WALL + 0.5])
      cylinder(d=CAM_BEZEL_OD - 2, h=0.8);
  }
}

// Preview
PREVIEW_BEZEL = "bezel";  // "bezel" | "plug"

if (PREVIEW_BEZEL == "bezel") lume_bezel();
else if (PREVIEW_BEZEL == "plug") lume_cam_plug();
