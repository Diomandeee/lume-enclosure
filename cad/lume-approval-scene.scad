// LUME approval scene — source CAD view for the current real BOM.
// Shows the K11 T-form, top ZHAOCAILIN display, and Arducam front camera
// without relying on stale exported STLs.

include <lume-config.scad>
use <lume-shell.scad>
use <lume-pod.scad>
use <lume-components.scad>
use <lume-internals.scad>

VIEW = "hero"; // "hero" | "front" | "top" | "ghost" | "exploded"

module display_in_place() {
  if (DISPLAY_ENABLED && DISPLAY_MOUNT_MODE == "top_cradle")
    translate([DISPLAY_X_OFF, 0,
               LUME_HEIGHT/2 + DISPLAY_CRADLE_RAIL_H + DISPLAY_THICK/2])
      proxy_top_display();
}

module arducam_in_place() {
  if (ARDUCAM_ENABLED)
    for (cam_x = ARDUCAM_XS)
      translate([cam_x, -LUME_DEPTH/2 + WALL + ARDUCAM_CASE_D/2 + 1, ARDUCAM_Z])
        proxy_arducam();
}

module femto_in_place() {
  // Align the camera's front face to the shell opening; the 145mm body then
  // passes through the bar rear and into the K11 pod volume.
  translate([CAM_CENTER_X, -LUME_DEPTH/2 + FEMTO_D/2, 0])
    proxy_femto();
}

module pod_in_place(exploded=0) {
  translate([0, LUME_DEPTH/2 + exploded, 0]) {
    color("#18202a") {
      pod_top();
      pod_bottom();
    }
    translate([0, POD_D/2, -POD_H/2 + POD_WALL]) {
      color("#31363b") pod_compute_sled();
      translate([0, 0, SLED_T + SLED_FLOOR_CLEAR + K11_H/2])
        proxy_k11();
    }
    translate([0, POD_D - 1, 0])
      color("#7d858b")
        rotate([90, 0, 0])
          pod_vesa_plate();
  }
}

module camera_usb_paths() {
  if (ARDUCAM_ENABLED) {
    cable_y = -LUME_DEPTH/2 + WALL + 10;
    cable_z = -LUME_HEIGHT/2 + WALL + 8;
    for (cam_x = ARDUCAM_XS) {
      color(cam_x < 0 ? "#34d399" : "#60a5fa") {
        // Down from each camera to the bottom cable backbone.
        translate([cam_x, cable_y, (ARDUCAM_Z + cable_z)/2])
          cube([5, 5, abs(ARDUCAM_Z - cable_z)], center=true);
        // Across the bar to the center pod feedthrough.
        translate([cam_x/2, cable_y, cable_z])
          cube([abs(cam_x), 5, 5], center=true);
        // Rearward into the K11 pod.
        translate([0, (cable_y + LUME_DEPTH/2 + 35)/2, cable_z])
          cube([7, abs(LUME_DEPTH/2 + 35 - cable_y), 5], center=true);
      }
    }
  }
}

module source_bar(alpha=1) {
  color("#232a31", alpha) lume_shell();
}

module approval_scene(exploded=0, ghost=false) {
  if (ghost) {
    %source_bar(0.25);
    %pod_in_place(exploded);
    color("#0d1117") display_in_place();
    color("#111111") femto_in_place();
    arducam_in_place();
    lume_internals_all();
    camera_usb_paths();
  } else {
    source_bar();
    pod_in_place(exploded);
    display_in_place();
    femto_in_place();
    arducam_in_place();
    camera_usb_paths();
  }
}

if (VIEW == "hero") approval_scene();
else if (VIEW == "front") approval_scene();
else if (VIEW == "top") approval_scene();
else if (VIEW == "ghost") approval_scene(ghost=true);
else if (VIEW == "exploded") approval_scene(exploded=90);
