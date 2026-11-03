// LUME — Exterior shell (front + rear halves)
// Soundbar form factor. Shell is split at Y = SPLIT_Y (centered).
// Front half:  3 camera recesses, LED diffuser pocket, wordmark, end grilles.
// Rear half:   VESA mount, port cluster cutout, exhaust vent, strain relief.
//
// Thermal airflow:
//   Intake  : passive slots on bottom face (cold air in)
//   Path    : across Jetson heatsink (left-rear hot zone)
//   Exhaust : Noctua NF-A8 pushes through rear vent grille (filtered)
//   Cold zone (right side): Femto Mega + UMA-8 mic disc, thermally baffled off Jetson

include <lume-config-bolt.scad>
use <lume-primitives.scad>

// ---------- Exterior volume ----------

module shell_solid() {
  rbox(LUME_WIDTH, LUME_HEIGHT, LUME_DEPTH, CORNER_R);
}

module shell_cavity() {
  rbox(LUME_WIDTH - 2*WALL, LUME_HEIGHT - 2*WALL, LUME_DEPTH - 2*WALL, INNER_R);
}

// ---------- Front-face features ----------

module front_face_cutouts() {
  // ---- Camera window — pill/stadium-shaped recessed cradle ----
  // 2026-04-26: replaces the previous 3 individual cam_recess cylinders.
  // Per Orbbec datasheet, the Mega's defining visual element is a unified
  // 111×40mm pill-shaped black-glass window. Bar provides a recessed
  // cradle (Mode B per design notes): the camera sits 1.5mm back from
  // the bar's front face creating a shadow-line reveal around the
  // camera's own black window — reads as deliberate industrial design.
  // The cradle opening matches camera body + 2.5mm bezel reveal.
  cam_w = CAM_WINDOW_W + CAM_WINDOW_REVEAL * 2;     // pill width incl. reveal
  cam_h = CAM_WINDOW_H + CAM_WINDOW_REVEAL * 2;     // pill height incl. reveal
  cam_r = CAM_WINDOW_R + CAM_WINDOW_REVEAL;         // pill end-cap radius
  // Stage 1 — recessed shadow line (1.5mm deep front-face inset, slightly
  // larger pill outline). This is what creates the visible step around
  // the camera.
  shadow_w = cam_w + 4;                              // 4mm wider for shadow band
  shadow_h = cam_h + 4;
  shadow_r = cam_r + 2;
  translate([0, -LUME_DEPTH/2 - 0.01, 0]) {
    rotate([-90, 0, 0])
      linear_extrude(height = CAM_WINDOW_RECESS + 0.01)
        offset(r = 0)
          stadium_2d(shadow_w, shadow_h, shadow_r);
  }
  // Stage 2 — pass-through opening (full wall depth). Camera's own glass
  // window sits flush in this opening.
  translate([0, -LUME_DEPTH/2 - 0.5, 0])
    rotate([-90, 0, 0])
      linear_extrude(height = WALL + 1)
        stadium_2d(cam_w, cam_h, cam_r);

  // LED diffuser window (simple through-aperture — diffuser flange seats behind)
  translate([LED_X, -LUME_DEPTH/2 - 0.5, LED_Z])
    rotate([-90, 0, 0])
      cylinder(d=LED_ID, h=WALL + 1);

  // Wordmark debossed into front face.
  // Geometry: rotate([90,0,0]) puts the extrusion in -Y; the slab Y range ends
  // up [ty - h, ty] where ty is the translate Y. To carve a recess of depth
  // WORDMARK_DEPTH into the front exterior face (at Y = -LUME_DEPTH/2):
  //   ty       = -LUME_DEPTH/2 + WORDMARK_DEPTH   (inner end of deboss)
  //   h        = WORDMARK_DEPTH + 0.5             (with 0.5mm overshoot)
  // The previous formula (+ WALL - WORDMARK_DEPTH) collapsed the deboss to
  // < 1mm and inverted the depth knob: bumping WORDMARK_DEPTH made it
  // SHALLOWER, not deeper, which is why the wordmark stayed invisible at
  // 3/4 angles after bumping 1.2 → 2.0 in the prior pass.
  // MIRROR_WORDMARK: pre-flip text on X for Blender export (see lume-config.scad).
  translate([0, -LUME_DEPTH/2 + WORDMARK_DEPTH, WORDMARK_Z])
    rotate([90, 0, 0])
      mirror([MIRROR_WORDMARK ? 1 : 0, 0, 0])
        linear_extrude(height=WORDMARK_DEPTH + 0.5)
          text(WORDMARK_TEXT, size=WORDMARK_H, font="Helvetica:style=Bold",
               halign="center", valign="center");

  // End grilles — hidden by default to match hero render slab face.
  if (SHOW_END_GRILLES)
    for (side = [-1, 1])
      translate([side * GRILLE_X_OFFSET, -LUME_DEPTH/2 + WALL + 0.01, 0])
        hex_grille(GRILLE_W, GRILLE_H);
}

// ---------- Rear-face features ----------

module rear_face_cutouts() {
  // VESA 100x100 bolt pattern (rear center)
  for (x = [-VESA_PITCH/2, VESA_PITCH/2],
       z = [-VESA_PITCH/2, VESA_PITCH/2])
    translate([x, LUME_DEPTH/2 - WALL*2, z])
      rotate([-90, 0, 0])
        bolt_m4(WALL*3);

  // Port cluster window (detailed cutouts in port bracket — this is just the window)
  translate([PORT_CLUSTER_X - 35, LUME_DEPTH/2 - WALL*2, PORT_CLUSTER_Z - 15])
    cube([70, WALL*3, 30]);

  // Barrel jack
  translate([PORT_CLUSTER_X + 50, LUME_DEPTH/2 - WALL*2, PORT_CLUSTER_Z + 30])
    rotate([-90, 0, 0])
      cylinder(d=PORT_BARREL_D, h=WALL*3);

  // Rear exhaust vent (slotted louvers — directional airflow)
  translate([VENT_X, LUME_DEPTH/2 - WALL, VENT_Z])
    slot_grille(VENT_W, VENT_H);

  // Kensington lock slot (right-rear corner)
  translate([LUME_WIDTH/2 - 25, LUME_DEPTH/2 - WALL*2, -LUME_HEIGHT/2 + 12])
    cube([PORT_KENSING_W, WALL*3, PORT_KENSING_H]);
}

// ---------- Bottom-face features (intake vents) ----------

module bottom_face_cutouts() {
  for (x = [INTAKE_X_LEFT, INTAKE_X_RIGHT])
    translate([x, 0, -LUME_HEIGHT/2 + WALL/2 + 0.01])
      rotate([0, 90, 0])
        hex_grille(INTAKE_W, INTAKE_D, hole_d=3.2, pitch=5);
}

// ---------- Interior ribbing (print stiffness) ----------

module interior_ribs() {
  // Ribs along front wall (between speaker grilles and camera zone)
  rib_y = -LUME_DEPTH/2 + WALL + 0.1;
  for (x = [-LUME_WIDTH/2 + 60 : RIB_PITCH : LUME_WIDTH/2 - 60])
    if (abs(x) > 50 && abs(x - CAM_LEFT_X) > 25 && abs(x - CAM_RIGHT_X) > 25)
      translate([x, rib_y, 0])
        rotate([-90, 0, 0])
          rib(LUME_HEIGHT - 2*WALL - 10, h=RIB_H, t=RIB_T);

  // Ribs along rear wall (between VESA and port cluster)
  rib_y2 = LUME_DEPTH/2 - WALL - 0.1;
  for (x = [-LUME_WIDTH/2 + 60 : RIB_PITCH : LUME_WIDTH/2 - 60])
    if (abs(x - PORT_CLUSTER_X) > 40 && abs(x - VENT_X) > 70 && abs(x) > 60)
      translate([x, rib_y2 - RIB_H, 0])
        rotate([-90, 0, 0])
          rib(LUME_HEIGHT - 2*WALL - 10, h=RIB_H, t=RIB_T);
}

// ---------- Corner bolt bosses (bonds front + rear halves) ----------

module corner_bolt_bosses() {
  inset = CORNER_BOLT_INSET;
  for (x = [-LUME_WIDTH/2 + inset, LUME_WIDTH/2 - inset],
       z = [-LUME_HEIGHT/2 + inset, LUME_HEIGHT/2 - inset])
    translate([x, -LUME_DEPTH/2 + WALL, z])
      rotate([-90, 0, 0])
        insert_boss_gusseted(h=LUME_DEPTH - 2*WALL - 2);
}

module corner_bolt_holes() {
  // Subtracted from rear half — clearance through for bolts coming from front
  inset = CORNER_BOLT_INSET;
  for (x = [-LUME_WIDTH/2 + inset, LUME_WIDTH/2 - inset],
       z = [-LUME_HEIGHT/2 + inset, LUME_HEIGHT/2 - inset])
    translate([x, LUME_DEPTH/2, z])
      rotate([90, 0, 0])
        bolt_m3_counterbore(len=LUME_DEPTH, cbore=5);
}

// ---------- Tongue-and-groove joinery ring at split plane ----------

module joinery_tongue_ring() {
  // Runs around the perimeter of the interior at Y = SPLIT_Y
  // Four straight segments (top, bottom, left, right)
  offset_interior = LUME_DEPTH/2 - WALL;
  // Top segment
  translate([0, SPLIT_Y, LUME_HEIGHT/2 - WALL - LIP_H])
    lip_tongue(LUME_WIDTH - 2*WALL - 2*CORNER_R);
  // Bottom segment
  translate([0, SPLIT_Y, -LUME_HEIGHT/2 + WALL])
    lip_tongue(LUME_WIDTH - 2*WALL - 2*CORNER_R);
  // Left + right segments
  for (side = [-1, 1])
    translate([side * (LUME_WIDTH/2 - WALL - LIP_H), SPLIT_Y, 0])
      rotate([0, 90, 0])
        lip_tongue(LUME_HEIGHT - 2*WALL - 2*CORNER_R);
}

module joinery_groove_ring() {
  translate([0, SPLIT_Y, LUME_HEIGHT/2 - WALL - LIP_H])
    lip_groove(LUME_WIDTH - 2*WALL - 2*CORNER_R);
  translate([0, SPLIT_Y, -LUME_HEIGHT/2 + WALL])
    lip_groove(LUME_WIDTH - 2*WALL - 2*CORNER_R);
  for (side = [-1, 1])
    translate([side * (LUME_WIDTH/2 - WALL - LIP_H), SPLIT_Y, 0])
      rotate([0, 90, 0])
        lip_groove(LUME_HEIGHT - 2*WALL - 2*CORNER_R);
}

// ---------- Complete assembled shell (preview) ----------

// ---------- X-seam splice pockets ----------
// Recesses on interior of front + rear walls that receive the splice plate
// alignment pegs. 1.5mm deep (keeps 1.5mm of 3mm wall), cylinder Ø = peg + clear.

SPLICE_POCKET_D  = 3.2;   // peg 3mm + 0.2mm clearance (matches LIP_CLEAR default)
SPLICE_POCKET_H  = 1.7;   // peg 1.5mm + 0.2mm bottom clearance
SPLICE_POCKET_DX = 30;    // X offset from seam (matches SPLICE_PEG_DX in internals)
SPLICE_POCKET_DZ = 20;

module splice_pockets() {
  // Four pockets on interior of FRONT wall, four on interior of REAR wall,
  // both straddling X=SPLIT_X. Pockets open toward shell interior.
  for (x = [SPLIT_X - SPLICE_POCKET_DX, SPLIT_X + SPLICE_POCKET_DX],
       z = [-SPLICE_POCKET_DZ, SPLICE_POCKET_DZ]) {
    // Front wall pockets: drill from inside toward front exterior (−Y direction)
    translate([x, -LUME_DEPTH/2 + WALL, z])
      rotate([-90, 0, 0])
        cylinder(d=SPLICE_POCKET_D, h=SPLICE_POCKET_H);
    // Rear wall pockets: drill from inside toward rear exterior (+Y direction)
    translate([x, LUME_DEPTH/2 - WALL, z])
      rotate([90, 0, 0])
        cylinder(d=SPLICE_POCKET_D, h=SPLICE_POCKET_H);
  }
}

// Hollow shell with cutouts, no internal structure. Used as base for split halves.
module lume_shell_hollow() {
  difference() {
    shell_solid();
    shell_cavity();
    front_face_cutouts();
    rear_face_cutouts();
    bottom_face_cutouts();
    corner_bolt_holes();
    if (SPLIT_SHELL_X) splice_pockets();
  }
}

module lume_shell() {
  lume_shell_hollow();
  if (SHOW_INTERNALS) {
    interior_ribs();
    corner_bolt_bosses();
  }
}

// ---------- Split halves (for printing) ----------

// Split halves print without internal bosses — bosses are printed as separate
// insert-receiver tubes and glued/screwed in post-print (keeps shell manifold
// and avoids vertical overhangs during printing).
module lume_shell_front() {
  difference() {
    intersection() {
      render() lume_shell_hollow();
      translate([-LUME_WIDTH, -LUME_DEPTH, -LUME_HEIGHT])
        cube([LUME_WIDTH*2, LUME_DEPTH + SPLIT_Y, LUME_HEIGHT*2]);
    }
    if (USE_JOINERY) joinery_groove_ring();
  }
}

module lume_shell_rear() {
  union() {
    intersection() {
      render() lume_shell_hollow();
      translate([-LUME_WIDTH, SPLIT_Y, -LUME_HEIGHT])
        cube([LUME_WIDTH*2, LUME_DEPTH, LUME_HEIGHT*2]);
    }
    if (USE_JOINERY) joinery_tongue_ring();
  }
}

// ---------- L/R sub-split (print-volume fit: Neptune 4 Max 420mm X) ----------
// Each front/rear half is further cut at X = SPLIT_X so no single piece exceeds
// ~250mm on any axis. Seam runs vertically through the shell at X=SPLIT_X.
// Mating at the X-seam: flat butt joint + CA glue + internal splice plate
// (printed separately via lume-joinery-coupon.scad). Corner bolts still bond
// front/rear halves; X-seam relies on glue + splice, no bolts.

module lume_shell_front_L() {
  intersection() {
    render() lume_shell_front();
    translate([-LUME_WIDTH, -LUME_DEPTH, -LUME_HEIGHT])
      cube([LUME_WIDTH + SPLIT_X, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

module lume_shell_front_R() {
  intersection() {
    render() lume_shell_front();
    translate([SPLIT_X, -LUME_DEPTH, -LUME_HEIGHT])
      cube([LUME_WIDTH, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

module lume_shell_rear_L() {
  intersection() {
    render() lume_shell_rear();
    translate([-LUME_WIDTH, -LUME_DEPTH, -LUME_HEIGHT])
      cube([LUME_WIDTH + SPLIT_X, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

module lume_shell_rear_R() {
  intersection() {
    render() lume_shell_rear();
    translate([SPLIT_X, -LUME_DEPTH, -LUME_HEIGHT])
      cube([LUME_WIDTH, LUME_DEPTH*2, LUME_HEIGHT*2]);
  }
}

// ---------- Preview toggle ----------
PREVIEW = "full";  // "full" | "front" | "rear" | "front_L" | "front_R" | "rear_L" | "rear_R"

if (PREVIEW == "full")          lume_shell();
else if (PREVIEW == "front")    lume_shell_front();
else if (PREVIEW == "rear")     lume_shell_rear();
else if (PREVIEW == "front_L")  lume_shell_front_L();
else if (PREVIEW == "front_R")  lume_shell_front_R();
else if (PREVIEW == "rear_L")   lume_shell_rear_L();
else if (PREVIEW == "rear_R")   lume_shell_rear_R();
