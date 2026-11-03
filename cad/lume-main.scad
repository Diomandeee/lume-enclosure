// LUME — Top-level assembly preview
// Combines shell + internals + component proxies + separately-printed parts
// (bezel, LED diffuser, port bracket, VESA plate).
//
// VIEW modes:
//   "assembly"   — everything, shell ghosted, internals + proxies solid
//   "exploded"   — same as assembly but with parts offset along Y for docs
//   "shell_only" — just the assembled shell
//   "print_front"- isolate front half for slicer
//   "print_rear" - isolate rear half for slicer

include <lume-config.scad>
use <lume-shell.scad>
use <lume-components.scad>
use <lume-internals.scad>
use <lume-bezel.scad>
use <lume-port-bracket.scad>
use <lume-vesa.scad>

VIEW = "assembly";

// Explode offset helper — returns 0 if not exploded
function ex(factor=1) = EXPLODED ? EXPLODE_DIST * factor : 0;

module assembly() {
  // Transparent shell
  %lume_shell();

  if (SHOW_INTERNALS) {
    lume_internals_all();
  }

  // LED diffuser in front face recess
  translate([0, -ex(0.3), 0]) led_diffuser();

  // Front bezel insert (offset in Y for exploded view)
  translate([0, -LUME_DEPTH/2 + WALL/2 - ex(0.6), 0])
    rotate([90, 0, 0])
      lume_bezel();

  // Port bracket (inside rear wall, offset for exploded)
  translate([PORT_CLUSTER_X, LUME_DEPTH/2 - WALL - 1 + ex(0.4), PORT_CLUSTER_Z])
    rotate([90, 0, 0])
      lume_port_bracket();

  // VESA plate on rear
  translate([0, LUME_DEPTH/2 + 1 + ex(0.8), 0])
    rotate([90, 0, 0])
      vesa_plate();

  if (SHOW_COMPONENTS) {
    if (LEGACY_BAR_COMPUTE_PARTS_ENABLED)
      translate([-LUME_WIDTH/2 + 80, LUME_DEPTH/2 - WALL - FAN_H/2 - 4, VENT_Z])
        rotate([90, 0, 0])
          proxy_fan();
    // Femto centered on front
    translate([CAM_CENTER_X, -LUME_DEPTH/2 + WALL + FEMTO_D/2, 0])
      proxy_femto();
    // UMA-8 on top rail
    translate([100, 0, LUME_HEIGHT/2 - WALL - UMA8_H - 2])
      proxy_uma8();
    if (SVPRO_LEGACY_ENABLED) {
      translate([CAM_LEFT_X, -LUME_DEPTH/2 + WALL + SVPRO_D/2, 0])
        rotate([-90, 0, 0]) proxy_svpro();
      translate([CAM_RIGHT_X, -LUME_DEPTH/2 + WALL + SVPRO_D/2, 0])
        rotate([-90, 0, 0]) proxy_svpro();
    }
    if (ARDUCAM_ENABLED)
      for (cam_x = ARDUCAM_XS)
        translate([cam_x, -LUME_DEPTH/2 + WALL + ARDUCAM_CASE_D/2 + 1, ARDUCAM_Z])
          proxy_arducam();
    if (DISPLAY_ENABLED && DISPLAY_MOUNT_MODE == "top_cradle")
      translate([DISPLAY_X_OFF, 0,
                 LUME_HEIGHT/2 + DISPLAY_CRADLE_RAIL_H + DISPLAY_THICK/2])
        proxy_top_display();
    // LED ring behind diffuser
    translate([LED_X, -LUME_DEPTH/2 + WALL + 2, LED_Z])
      rotate([-90, 0, 0])
        proxy_led_ring();
  }
}

// Note: to render exploded, invoke with `-D VIEW=\"assembly\" -D EXPLODED=true`
if (VIEW == "assembly")         assembly();
else if (VIEW == "shell_only")  lume_shell();
else if (VIEW == "print_front") lume_shell_front();
else if (VIEW == "print_rear")  lume_shell_rear();
