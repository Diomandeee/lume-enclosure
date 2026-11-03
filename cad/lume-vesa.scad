// LUME — Wall mount plate
// Two modes:
//   "vesa"  - standard 100x100 VESA plate, bolts to rear shell, mates with any
//             VESA 100 wall bracket.
//   "cleat" - French cleat: bar-side receiver piece + wall-side cleat piece.
//             Lifts on/off without tools. Better for frequent demo moves.

include <lume-config.scad>
use <lume-primitives.scad>

// ---------- VESA 100x100 plate ----------

module vesa_plate() {
  plate_w = VESA_PITCH + 40;
  plate_h = VESA_PITCH + 40;
  difference() {
    rplate(plate_w, plate_h, VESA_PLATE_T, 6);
    // 4 VESA bolt holes (M4 clearance)
    for (x = [-VESA_PITCH/2, VESA_PITCH/2],
         z = [-VESA_PITCH/2, VESA_PITCH/2])
      translate([x, z, 0])
        cylinder(d=VESA_HOLE_D, h=VESA_PLATE_T*3, center=true);
    // 4 shell attachment holes (M3 into rear-shell heat-set inserts)
    for (x = [-plate_w/2 + 10, plate_w/2 - 10],
         z = [-plate_h/2 + 10, plate_h/2 - 10])
      translate([x, z, 0])
        bolt_m3_counterbore(len=VESA_PLATE_T + 1, cbore=2);
    // Lightening windows (reduce mass + save filament)
    for (dx = [-25, 25], dz = [-25, 25])
      translate([dx, dz, 0])
        cylinder(d=14, h=VESA_PLATE_T*3, center=true);
  }
}

// ---------- French cleat (bar side) ----------

CLEAT_W = 320;
CLEAT_H = 40;
CLEAT_T = 10;

// Cleat profile: 40mm tall, 10mm thick at base, 45° bevel on upper face.
// Back face (x=0) flush against wall/shell. Front bevel interlocks with mate.
// Points: (0,0) → (10,0) → (10,30) → (0,40) → back to (0,0). A trapezoid with
// a 45° chamfer on the top-front edge.

module cleat_bar_side() {
  difference() {
    linear_extrude(height=CLEAT_W, center=true, convexity=4)
      polygon([[0, 0],
               [CLEAT_T, 0],
               [CLEAT_T, CLEAT_H - CLEAT_T],
               [0, CLEAT_H]]);
    // Mount holes along bar (M3 into rear shell)
    for (y = [-CLEAT_W/2 + 30 : 70 : CLEAT_W/2 - 30])
      translate([CLEAT_T/2, CLEAT_H/2, y])
        rotate([0, 90, 0])
          bolt_m3_counterbore(len=CLEAT_T + 1, cbore=2);
  }
}

// Wall side: mirrored chamfer so the two pieces slot together.
module cleat_wall_side() {
  difference() {
    linear_extrude(height=CLEAT_W, center=true, convexity=4)
      polygon([[0, 0],
               [CLEAT_T, CLEAT_T],
               [CLEAT_T, CLEAT_H],
               [0, CLEAT_H]]);
    // Mount holes for drywall anchors (M5 clearance, 120mm pitch)
    for (y = [-CLEAT_W/2 + 30 : 120 : CLEAT_W/2 - 30])
      translate([CLEAT_T/2, CLEAT_H/2, y])
        rotate([0, 90, 0])
          cylinder(d=5.3, h=CLEAT_T + 2, center=true);
  }
}

// Preview toggle
MOUNT = "vesa";   // "vesa" | "cleat_bar" | "cleat_wall"

if (MOUNT == "vesa") vesa_plate();
else if (MOUNT == "cleat_bar") cleat_bar_side();
else if (MOUNT == "cleat_wall") cleat_wall_side();
