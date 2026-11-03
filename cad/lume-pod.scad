// LUME T-form rear pod — compute enclosure that mounts behind the bar.
//
// Splits horizontally into pod_top + pod_bottom (a Z-axis seam). Each half
// prints flat at 200×130×60mm — fits the Neptune 4 Max plate trivially.
// Joinery: pod halves bolt together via 4 M3 corner inserts (same pattern
// as the bar shell). Pod-to-bar joinery: flange on pod front overlaps bar
// rear shell, 6 M3 bolts through flange into heat-set inserts in the bar.
//
// VESA 100×100 sits on the pod's BACK face. The bar's existing rear-shell
// VESA pads stay (so the bar can still wall-mount standalone if you ever
// want to demo without the pod), but in the T-form the pod VESA is the
// load-bearing one.

include <lume-config.scad>
use <lume-primitives.scad>

// ---------- Pod exterior envelope ----------

// Pod cuboid with rounded vertical edges — visual continuity with the bar's
// CORNER_R.
module pod_envelope() {
  hull() {
    for (x = [-POD_W/2 + CORNER_R, POD_W/2 - CORNER_R],
         z = [-POD_H/2 + CORNER_R, POD_H/2 - CORNER_R]) {
      translate([x, POD_D/2, z])
        rotate([90, 0, 0])
          cylinder(r=CORNER_R, h=POD_D, center=true);
    }
  }
}

// Inner cavity (subtractive). Wall thickness is POD_WALL.
module pod_cavity() {
  hull() {
    for (x = [-POD_W/2 + CORNER_R + POD_WALL, POD_W/2 - CORNER_R - POD_WALL],
         z = [-POD_H/2 + CORNER_R + POD_WALL, POD_H/2 - CORNER_R - POD_WALL]) {
      translate([x, POD_D/2, z])
        rotate([90, 0, 0])
          cylinder(r=CORNER_R - POD_WALL/2,
                   h=POD_D - 2*POD_WALL,
                   center=true);
    }
  }
}

// ---------- Pod features ----------

// Vent slot pattern, applied to ±X side walls.
// Y-direction goes from front (Y=0) to back (Y=POD_D).
module pod_vents_side() {
  intake_y = POD_D * 0.25;
  exhaust_y = POD_D * 0.75;
  // Intake slots near the floor (cool air in)
  for (i = [0:POD_VENT_COUNT-1]) {
    y = intake_y - (POD_VENT_COUNT-1) * POD_VENT_PITCH/2 + i * POD_VENT_PITCH;
    translate([0, y, -POD_H/2 + 12])
      cube([POD_WALL*4, POD_VENT_W, POD_VENT_H], center=true);
  }
  // Exhaust slots near the ceiling (hot air out)
  for (i = [0:POD_VENT_COUNT-1]) {
    y = exhaust_y - (POD_VENT_COUNT-1) * POD_VENT_PITCH/2 + i * POD_VENT_PITCH;
    translate([0, y, POD_H/2 - 12])
      cube([POD_WALL*4, POD_VENT_W, POD_VENT_H], center=true);
  }
}

// ⭐ K11-aligned cooling — replaces side-wall vents as primary cooling path.
// K11 has BOTTOM intake fan + TOP exhaust fan per Amazon spec. Pod floor
// vents feed the bottom-fan intake; pod ceiling vents vent the top-fan
// exhaust. Aligned grids so airflow goes straight up through K11.
//
// Grid 120×80mm centered at Y=POD_D/2 (where the compute sled places K11).
// 6×4 = 24 slots, each 12×4mm = total intake area ~1150 mm² (per face).

// Bottom intake — pod floor (Z = -POD_H/2 face).
module pod_vents_bottom() {
  grid_w  = 120;
  grid_d  =  80;
  n_x     = 6;
  n_d     = 4;
  slot_w  = 12;
  slot_d  =  4;
  x_pitch = grid_w / (n_x - 1);
  d_pitch = grid_d / (n_d - 1);
  for (xi = [0 : n_x - 1])
    for (di = [0 : n_d - 1]) {
      x = -grid_w/2 + xi * x_pitch;
      y = POD_D/2 - grid_d/2 + di * d_pitch;
      translate([x, y, -POD_H/2])
        cube([slot_w, slot_d, POD_WALL*3], center=true);
    }
}

// Top exhaust — pod ceiling (Z = +POD_H/2 face). Same grid as bottom.
module pod_vents_top() {
  grid_w  = 120;
  grid_d  =  80;
  n_x     = 6;
  n_d     = 4;
  slot_w  = 12;
  slot_d  =  4;
  x_pitch = grid_w / (n_x - 1);
  d_pitch = grid_d / (n_d - 1);
  for (xi = [0 : n_x - 1])
    for (di = [0 : n_d - 1]) {
      x = -grid_w/2 + xi * x_pitch;
      y = POD_D/2 - grid_d/2 + di * d_pitch;
      translate([x, y, POD_H/2])
        cube([slot_w, slot_d, POD_WALL*3], center=true);
    }
}

// Cable feedthrough on pod FRONT face (Y=0 plane).
module pod_feedthrough() {
  translate([0, 0, 0])
    cube([POD_FEEDTHROUGH_W, POD_WALL*3, POD_FEEDTHROUGH_H], center=true);
}

// Rear service opening exposes the K11's native port bank for bench use.
module pod_rear_service_window() {
  translate([0, POD_D - POD_WALL/2, POD_REAR_SERVICE_Z])
    cube([POD_REAR_SERVICE_W, POD_WALL*3, POD_REAR_SERVICE_H], center=true);
}

// Side service slot for panel-mount USB extension, Bluetooth transmitter
// pigtail, or temporary cable exit when rear ports face a wall.
module pod_side_service_slot() {
  side = POD_SIDE_SERVICE_SLOT_SIDE;
  translate([side * (POD_W/2 - POD_WALL/2),
             POD_SIDE_SERVICE_SLOT_Y,
             POD_SIDE_SERVICE_SLOT_Z])
    cube([POD_WALL*3, POD_SIDE_SERVICE_SLOT_D, POD_SIDE_SERVICE_SLOT_H], center=true);
}

// VESA bolt holes on pod BACK face (Y=POD_D plane), looking down -Y.
module pod_vesa_holes() {
  for (x = [-POD_VESA_PITCH/2, POD_VESA_PITCH/2],
       z = [-POD_VESA_PITCH/2, POD_VESA_PITCH/2]) {
    translate([x, POD_D - POD_WALL/2 + 0.1, z])
      rotate([-90, 0, 0])
        cylinder(d=VESA_HOLE_D, h=POD_WALL*2, center=true);
  }
}

// Heat-set insert pockets on pod-pod horizontal seam (top half ↔ bottom half).
// 4 corner positions inside the front and back walls.
module pod_seam_inserts() {
  for (x = [-POD_W/2 + 18, POD_W/2 - 18],
       y = [POD_WALL + 6, POD_D - POD_WALL - 6]) {
    translate([x, y, 0])
      cylinder(d=4.5, h=10, center=true);
  }
}

// ---------- Joinery flange (pod-to-bar) ----------

// A 4mm-thick lip extending past the pod opening on the front face,
// overlapping the bar rear shell. 6 bolt holes through the flange.
module pod_bar_flange() {
  flange_w = POD_W + POD_FLANGE_W*2;
  flange_h = POD_H + POD_FLANGE_W*2;
  difference() {
    translate([0, POD_FLANGE_T/2, 0])
      hull() {
        for (x = [-flange_w/2 + CORNER_R, flange_w/2 - CORNER_R],
             z = [-flange_h/2 + CORNER_R, flange_h/2 - CORNER_R])
          translate([x, 0, z])
            cylinder(r=CORNER_R, h=POD_FLANGE_T, center=true);
      }
    // Subtract pod opening (so the flange is just the rim around it)
    pod_envelope();
    // 6 M3 bolt holes aligned to the rear bar shell, inside the 120mm bar height.
    bolt_x = POD_W/2 - 18;
    bolt_z = LUME_HEIGHT/2 - 18;
    for (x = [-bolt_x, 0, bolt_x],
         z = [-bolt_z, bolt_z])
      translate([x, POD_FLANGE_T/2, z])
        rotate([90, 0, 0])
          cylinder(d=3.4, h=POD_FLANGE_T*3, center=true);
  }
}

// ---------- Pod halves (printable) ----------

// Top half — Z >= 0 portion of pod_envelope minus cavity, vents, etc.
module pod_top() {
  difference() {
    union() {
      pod_envelope();
      pod_bar_flange();
    }
    pod_cavity();
    pod_vents_top();          // K11 top-fan exhaust (ceiling grille)
    pod_feedthrough();
    pod_rear_service_window();
    pod_side_service_slot();
    pod_vesa_holes();
    pod_seam_inserts();
    // Cut at Z=0 for the seam — keep top half
    translate([-POD_W, -POD_W, -POD_H])
      cube([POD_W*3, POD_W*3, POD_H], center=false);
  }
}

// Bottom half — Z <= 0 portion. Symmetric to top.
module pod_bottom() {
  difference() {
    union() {
      pod_envelope();
      pod_bar_flange();
    }
    pod_cavity();
    pod_vents_bottom();       // K11 bottom-fan intake (floor grille)
    pod_feedthrough();
    pod_rear_service_window();
    pod_side_service_slot();
    pod_vesa_holes();
    pod_seam_inserts();
    // Cut at Z=0 for the seam — keep bottom half
    translate([-POD_W, -POD_W, 0])
      cube([POD_W*3, POD_W*3, POD_H], center=false);
  }
}

// ---------- VESA plate (separate, screws onto pod back) ----------
// Pod back has VESA holes already — but a thicker dedicated plate spreads
// the wall-mount load across more pod surface. Optional.
module pod_vesa_plate() {
  plate_w = max(POD_VESA_PITCH + 40, POD_REAR_SERVICE_W + 30);
  plate_h = max(POD_VESA_PITCH + 40, POD_REAR_SERVICE_H + 50);
  difference() {
    rplate(plate_w, plate_h, POD_VESA_PLATE_T, 6);
    cube([POD_REAR_SERVICE_W, POD_REAR_SERVICE_H, POD_VESA_PLATE_T*3], center=true);
    for (x = [-POD_VESA_PITCH/2, POD_VESA_PITCH/2],
         z = [-POD_VESA_PITCH/2, POD_VESA_PITCH/2])
      translate([x, z, 0])
        cylinder(d=VESA_HOLE_D, h=POD_VESA_PLATE_T*3, center=true);
    // Pod-attachment holes — 4 corners, pass through to pod back wall
    for (x = [-plate_w/2 + 10, plate_w/2 - 10],
         z = [-plate_h/2 + 10, plate_h/2 - 10])
      translate([x, z, 0])
        bolt_m3_counterbore(len=POD_VESA_PLATE_T + 1, cbore=2);
  }
}

// ---------- Compute sled (K11 mount inside pod) ----------
// Flat tray with VESA75 bolt holes for the K11's bottom mount, plus rim
// to keep the K11 from sliding. Sits on the pod's interior floor with 12mm
// fan clearance from the floor.
module pod_compute_sled() {
  sled_w = K11_W + 8;     // 4mm clearance per side
  sled_d = K11_D + 8;
  difference() {
    union() {
      // Base plate
      translate([-sled_w/2, -sled_d/2, 0])
        cube([sled_w, sled_d, SLED_T]);
      // Retaining rim (3 sides — open back for cable access)
      translate([-sled_w/2, -sled_d/2, SLED_T])
        difference() {
          cube([sled_w, sled_d, SLED_RIM_H]);
          translate([POD_WALL, POD_WALL, -1])
            cube([sled_w - POD_WALL*2, sled_d - POD_WALL*2, SLED_RIM_H + 2]);
          // Open the back (for K11 ports to face out)
          translate([sled_w*0.2, sled_d - POD_WALL - 1, -1])
            cube([sled_w*0.6, POD_WALL + 2, SLED_RIM_H + 2]);
        }
      // K11 standoffs: raise the bottom intake above the tray surface.
      for (x = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2],
           y = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2])
        translate([x, y, SLED_T])
          cylinder(d=SLED_K11_STANDOFF_D, h=SLED_FLOOR_CLEAR);
    }
    // Intake slots through tray floor so the K11 bottom fan is not starved.
    for (x = [-48, -30, -12, 12, 30, 48])
      translate([x, 0, -1])
        cube([SLED_INTAKE_SLOT_W, SLED_INTAKE_SLOT_D, SLED_T + 2], center=true);
    // K11 VESA75 bottom mount — 4 holes
    for (x = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2],
         y = [-K11_VESA_PITCH/2, K11_VESA_PITCH/2])
      translate([x, y, -1])
        cylinder(d=4.4, h=SLED_T + SLED_FLOOR_CLEAR + 2);
    // 4 corner mount holes for sled-to-pod-floor (M3 into heat-set inserts)
    for (x = [-sled_w/2 + 8, sled_w/2 - 8],
         y = [-sled_d/2 + 8, sled_d/2 - 8])
      translate([x, y, -1])
        cylinder(d=3.4, h=SLED_T + 2);
  }
}

// ---------- Preview / export selector ----------
PART = "all";  // "all" | "pod_top" | "pod_bottom" | "pod_vesa_plate" | "pod_compute_sled" | "assembly"

if (PART == "pod_top")           pod_top();
else if (PART == "pod_bottom")   pod_bottom();
else if (PART == "pod_vesa_plate") pod_vesa_plate();
else if (PART == "pod_compute_sled") pod_compute_sled();
else if (PART == "assembly") {
  pod_top();
  pod_bottom();
  translate([0, POD_D/2, -POD_H/2 + POD_WALL])
    pod_compute_sled();
} else {
  // "all" → exploded layout for visual inspection
  translate([0, 0, POD_H/2 + 30]) pod_top();
  translate([0, 0, -POD_H/2 - 30]) pod_bottom();
  translate([POD_W + 60, POD_D/2, 0]) pod_vesa_plate();
  translate([-POD_W - 60, 0, 0]) pod_compute_sled();
}
