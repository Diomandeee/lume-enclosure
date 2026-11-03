// Cross-section views for interior verification.
// Usage: openscad -o xsect_top.png -D 'VIEW="top"'  lume-cross-section.scad
//        openscad -o xsect_mid.png -D 'VIEW="mid"'  lume-cross-section.scad
//        openscad -o xsect_seam.png -D 'VIEW="seam"' lume-cross-section.scad

include <lume-config.scad>
use <lume-shell.scad>

VIEW = "top";  // top | mid | seam | front_L_interior | rear_R_interior

// Top-down slice at Z=0: see LED window, cameras, wordmark debossed, VESA
module view_top() {
  intersection() {
    lume_shell_front();
    translate([-LUME_WIDTH, -LUME_DEPTH, -2])
      cube([LUME_WIDTH*2, LUME_DEPTH*2, 4]);
  }
  intersection() {
    lume_shell_rear();
    translate([-LUME_WIDTH, -LUME_DEPTH, -2])
      cube([LUME_WIDTH*2, LUME_DEPTH*2, 4]);
  }
}

// Mid-horizontal slice at Z=10 (through camera axis): see camera hole rings
module view_mid() {
  intersection() {
    union() { lume_shell_front(); lume_shell_rear(); }
    translate([-LUME_WIDTH, -LUME_DEPTH, 8])
      cube([LUME_WIDTH*2, LUME_DEPTH*2, 4]);
  }
}

// Vertical slice at X=SPLIT_X+0.5: see what the R-half interior looks like right at the seam
module view_seam() {
  intersection() {
    union() { lume_shell_front(); lume_shell_rear(); }
    translate([SPLIT_X, -LUME_DEPTH, -LUME_HEIGHT])
      cube([2, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

// Interior iso of just front_L half — see splice pockets + cam_left hole + half LED + half wordmark
module view_front_L_interior() {
  lume_shell_front();
  translate([-LUME_WIDTH, -LUME_DEPTH, -LUME_HEIGHT])
    cube([LUME_WIDTH, LUME_DEPTH*2, LUME_HEIGHT*2]);
}

// Interior iso of just rear_R half — see splice pockets + VESA + port cluster + Kensington
module view_rear_R_interior() {
  intersection() {
    lume_shell_rear();
    translate([0, -LUME_DEPTH, -LUME_HEIGHT])
      cube([LUME_WIDTH, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

if (VIEW == "top")                view_top();
else if (VIEW == "mid")           view_mid();
else if (VIEW == "seam")          view_seam();
else if (VIEW == "front_L_iso")   view_front_L_interior();
else if (VIEW == "rear_R_iso")    view_rear_R_interior();
