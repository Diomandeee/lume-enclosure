// Additional cross-section views (Tier A4 — 3 new sections beyond the original 5).
// Usage:
//   openscad -o xsect_vertical_mid.png -D 'VIEW="vertical_mid"' lume-cross-section-extra.scad
//   openscad -o xsect_led_plane.png    -D 'VIEW="led_plane"'    lume-cross-section-extra.scad
//   openscad -o xsect_port_cluster.png -D 'VIEW="port_cluster"' lume-cross-section-extra.scad

include <lume-config.scad>
use <lume-shell.scad>
use <lume-internals.scad>
use <lume-components.scad>

VIEW = "vertical_mid";

SLICE_T = 6;  // visual slab thickness so the cut is visible in PNG

// Vertical slice at X=0: bisects the bar lengthwise, shows interior depth profile + LED + Femto axis
module view_vertical_mid() {
  intersection() {
    union() {
      lume_shell();
      lume_internals_all();
    }
    translate([-SLICE_T/2, -LUME_DEPTH, -LUME_HEIGHT])
      cube([SLICE_T, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

// Horizontal slice at Z=LED_Z: shows the LED indicator aperture passing through both halves
module view_led_plane() {
  intersection() {
    union() {
      lume_shell();
      lume_internals_all();
    }
    translate([-LUME_WIDTH, -LUME_DEPTH, LED_Z - SLICE_T/2])
      cube([LUME_WIDTH*2, LUME_DEPTH*2, SLICE_T]);
  }
}

// Vertical slice at X=PORT_CLUSTER_X: cuts straight through the port cluster anchors
module view_port_cluster() {
  intersection() {
    union() {
      lume_shell();
      lume_internals_all();
    }
    translate([PORT_CLUSTER_X - SLICE_T/2, -LUME_DEPTH, -LUME_HEIGHT])
      cube([SLICE_T, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

if      (VIEW == "vertical_mid") view_vertical_mid();
else if (VIEW == "led_plane")    view_led_plane();
else if (VIEW == "port_cluster") view_port_cluster();
else echo(str("unknown VIEW: ", VIEW));
