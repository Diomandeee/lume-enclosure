// LUME — Primitive helpers
// Rounded boxes, grilles, fastener features, ribs, cable clips, chamfers.

include <lume-config.scad>

// ---------- Solids ----------

// Rounded box centered at origin, uniform corner radius
module rbox(w, h, d, r) {
  hull()
    for (x = [-w/2+r, w/2-r], y = [-d/2+r, d/2-r], z = [-h/2+r, h/2-r])
      translate([x, y, z]) sphere(r=r);
}

// Rounded plate (2D square with rounded corners, linear-extruded, centered on Z)
module rplate(w, h, thick, r) {
  translate([0, 0, -thick/2])
    linear_extrude(height=thick)
      offset(r=r) offset(r=-r)
        square([w, h], center=true);
}

// Chamfered cube (flat-top, chamfered edges — cleaner print lines than cube)
module cchamfer(w, h, d, c=CHAMFER) {
  hull() {
    cube([w-2*c, h, d-2*c], center=true);
    cube([w, h-2*c, d-2*c], center=true);
    cube([w-2*c, h-2*c, d], center=true);
  }
}

// ---------- Perforated grilles ----------

// Hex-perforated grille (panel oriented in XZ plane, thickness along Y)
module hex_grille(w, h, hole_d=GRILLE_HOLE_D, pitch=GRILLE_PITCH, thick=WALL*2) {
  difference() {
    cube([w, thick, h], center=true);
    for (col = [-w/2 : pitch : w/2])
      for (row = [-h/2 : pitch*0.866 : h/2]) {
        stagger = (floor((row + h/2)/(pitch*0.866)) % 2) * pitch/2;
        translate([col + stagger, 0, row])
          rotate([90, 0, 0])
            cylinder(d=hole_d, h=thick*2, center=true);
      }
  }
}

// Slot grille (horizontal louvers — used for rear vent, more directional than hex)
module slot_grille(w, h, slot_h=3, gap=2, thick=WALL*2) {
  difference() {
    cube([w, thick, h], center=true);
    for (z = [-h/2 + slot_h : slot_h + gap : h/2 - slot_h])
      translate([0, 0, z])
        cube([w - 8, thick*2, slot_h], center=true);
  }
}

// ---------- Camera / lens features ----------

// Camera lens cutout: clearance hole + shallow bezel recess on outer face
// Thickness is wall thickness (distance from outer face inward)
module lens_cutout(bezel_od=CAM_BEZEL_OD, lens_id=CAM_HOLE_D, thick=WALL) {
  // Through-hole clearance
  cylinder(d=lens_id, h=thick*3, center=true);
  // Outer bezel recess (0.8mm deep)
  translate([0, 0, thick/2 - 0.8])
    cylinder(d=bezel_od, h=1.0);
}

// ---------- Fasteners ----------

// Heat-set insert boss: prints as cylinder with pocket sized for M3 knurled insert
module insert_boss(h=8) {
  difference() {
    cylinder(d=INSERT_BOSS_OD, h=h);
    translate([0, 0, -0.01])
      cylinder(d=INSERT_OD, h=INSERT_DEPTH + 0.01);
  }
}

// Reinforced insert boss with gusset webs (for high-stress mounts)
module insert_boss_gusseted(h=10, wing=6) {
  insert_boss(h=h);
  for (a = [0, 90, 180, 270])
    rotate([0, 0, a])
      translate([INSERT_BOSS_OD/2 - 0.1, 0, 0])
        rotate([90, 0, 90])
          linear_extrude(height=1.2, center=true)
            polygon([[0, 0], [wing, 0], [0, h]]);
}

// M3 counterbored clearance hole (for socket-head screws)
module bolt_m3_counterbore(len=20, cbore=4) {
  cylinder(d=BOLT_M3_CLEAR, h=len+0.1);
  cylinder(d=COUNTERBORE_D, h=cbore);
}

// M4 clearance (VESA)
module bolt_m4(len=20) {
  cylinder(d=BOLT_M4_CLEAR, h=len+0.1);
}

// ---------- Structural ----------

// Interior rib (stiffens flat shell walls during ASA print)
module rib(length, h=RIB_H, t=RIB_T) {
  translate([-length/2, -t/2, 0])
    cube([length, t, h]);
}

// Cable channel clip (snaps over a routed cable)
module cable_clip(w=CABLE_CHANNEL_W, h=CABLE_CHANNEL_H, t=1.6) {
  difference() {
    translate([-w/2 - t, 0, 0])
      cube([w + 2*t, 6, h + t]);
    translate([-w/2, -0.1, t])
      cube([w, 6.2, h]);
    translate([-w/2 + 1, -0.1, h + t - 0.5])
      cube([w - 2, 6.2, 2]);  // opening at top
  }
}

// Strain relief grommet (pass-through for USB/power cable with flex zone)
module strain_relief(cable_d=5, body_od=12, h=14) {
  difference() {
    union() {
      cylinder(d=body_od, h=h);
      translate([0, 0, h]) cylinder(d1=body_od, d2=body_od-3, h=4);
    }
    translate([0, 0, -0.1]) cylinder(d=cable_d, h=h+5);
    // 4 flex slits
    for (a = [0, 90, 180, 270])
      rotate([0, 0, a])
        translate([-0.4, 0, h - 6])
          cube([0.8, body_od/2 + 1, 7]);
  }
}

// ---------- Joinery ----------

// Tongue-and-groove lip for shell split (positive = tongue)
module lip_tongue(length, w=LIP_W, h=LIP_H) {
  translate([-length/2, -w/2, 0])
    cube([length, w, h]);
}

// Groove (negative — subtract from mating half) with print clearance
module lip_groove(length, w=LIP_W, h=LIP_H, clear=LIP_CLEAR) {
  translate([-length/2, -(w+2*clear)/2, -0.01])
    cube([length, w + 2*clear, h + clear + 0.01]);
}

// ---------- Stadium / pill / discorectangle 2D shape ----------
// Used for the Mega's camera window cutout — rectangle with semicircular ends.
// Total dimensions w × h, end-cap radius r (typically r = h/2 for clean pill).
module stadium_2d(w, h, r) {
  hull() {
    translate([-(w/2 - r), 0]) circle(r=r);
    translate([ (w/2 - r), 0]) circle(r=r);
  }
}
