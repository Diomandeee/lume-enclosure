// LUME — Annotated views (D1 dimensioned, D2 port pin-out, D3 cable routing)
// Pure OpenSCAD text() callouts overlaid on geometry. No external editor.
//
// Usage:
//   openscad -o dim_front.png -D 'VIEW="dim_front"' lume-annotations.scad
//   openscad -o dim_top.png   -D 'VIEW="dim_top"'   lume-annotations.scad
//   openscad -o portmap.png   -D 'VIEW="portmap"'   lume-annotations.scad
//   openscad -o cables.png    -D 'VIEW="cables"'    lume-annotations.scad

include <lume-config.scad>
use <lume-shell.scad>
use <lume-internals.scad>
use <lume-components.scad>

VIEW = "dim_front";

// Text helpers
TEXT_SIZE  = 8;
LINE_T     = 0.6;   // dimension line thickness
ARROW_R    = 1.4;   // arrowhead size
TEXT_DEPTH = 0.4;   // make text a 3D solid so it renders in PNG

module label(t, size=TEXT_SIZE) {
  color("#1a1a1a")
    linear_extrude(TEXT_DEPTH)
      text(t, size=size, halign="center", valign="center", font="Helvetica:style=Bold");
}

module dim_line(x1, x2, y, z, lbl) {
  // line
  color("#cc2030") {
    hull() {
      translate([x1, y, z]) sphere(LINE_T);
      translate([x2, y, z]) sphere(LINE_T);
    }
    // arrowheads
    translate([x1, y, z]) sphere(ARROW_R);
    translate([x2, y, z]) sphere(ARROW_R);
    // tick marks at endpoints
    for (x = [x1, x2])
      translate([x, y, z]) cylinder(d=LINE_T*2, h=4, center=true);
  }
  // label above the line
  translate([(x1+x2)/2, y, z + 6])
    rotate([90, 0, 0])
      label(lbl);
}

module dim_line_z(z1, z2, x, y, lbl) {
  color("#cc2030") {
    hull() {
      translate([x, y, z1]) sphere(LINE_T);
      translate([x, y, z2]) sphere(LINE_T);
    }
    translate([x, y, z1]) sphere(ARROW_R);
    translate([x, y, z2]) sphere(ARROW_R);
  }
  translate([x + 8, y, (z1+z2)/2])
    rotate([90, 0, 0])
      label(lbl);
}

// ============================================================
// D1: Dimensioned drawing — front face
// ============================================================
module view_dim_front() {
  // Shell (ghosted)
  %lume_shell();

  // Width dimension at top
  dim_line(-LUME_WIDTH/2, LUME_WIDTH/2,
           -LUME_DEPTH/2 - 8,
           LUME_HEIGHT/2 + 18,
           str(LUME_WIDTH, "mm"));
  // Height dimension on left
  dim_line_z(-LUME_HEIGHT/2, LUME_HEIGHT/2,
             -LUME_WIDTH/2 - 18,
             -LUME_DEPTH/2 - 8,
             str(LUME_HEIGHT, "mm"));

  // Cam centerline labels
  for (cx = [[CAM_LEFT_X, "SVPRO L"],
             [CAM_CENTER_X, "Femto Mega"],
             [CAM_RIGHT_X, "SVPRO R"]])
    translate([cx[0], -LUME_DEPTH/2 - 6, LUME_HEIGHT/2 + 4])
      rotate([90, 0, 0])
        label(cx[1], size=5);

  // LED indicator label
  translate([LED_X, -LUME_DEPTH/2 - 6, LED_Z - 8])
    rotate([90, 0, 0])
      label(str("LED Ø", LED_OD_INDICATOR), size=5);

  // Wordmark label
  translate([0, -LUME_DEPTH/2 - 6, WORDMARK_Z + 14])
    rotate([90, 0, 0])
      label("LUME wordmark — debossed", size=4);
}

// ============================================================
// D1: Dimensioned drawing — top view
// ============================================================
module view_dim_top() {
  %lume_shell();

  // Depth dimension
  dim_line(-LUME_DEPTH/2, LUME_DEPTH/2,
           -LUME_WIDTH/2 - 18,
           0,
           str(LUME_DEPTH, "mm")) ;

  // Internal landmarks at top: BAFFLE_X, SPLIT_X
  translate([BAFFLE_X, 0, LUME_HEIGHT/2 + 8])
    rotate([0, 0, 90])
      label(str("BAFFLE_X = ", BAFFLE_X), size=5);

  translate([SPLIT_X, -LUME_DEPTH/2 - 12, LUME_HEIGHT/2 + 4])
    rotate([0, 0, 90])
      label(str("SPLIT_X = ", SPLIT_X), size=5);

  // Wall thickness callout
  translate([-LUME_WIDTH/2 + 30, LUME_DEPTH/2 + 14, LUME_HEIGHT/2 + 4])
    label(str("WALL = ", WALL, "mm"), size=5);

  // Corner radius
  translate([-LUME_WIDTH/2 + 4, -LUME_DEPTH/2 - 14, LUME_HEIGHT/2 + 4])
    label(str("R", CORNER_R), size=5);
}

// ============================================================
// D2: Port pin-out diagram (rear face with port labels)
// Camera is on +Y side (rear), so text must face +Y → rotate [90, 0, 180]
// ============================================================
module view_portmap() {
  %lume_shell();

  // Port labels around the cluster at PORT_CLUSTER_X
  px = PORT_CLUSTER_X;
  pz = PORT_CLUSTER_Z;
  py = LUME_DEPTH/2 + 4;

  // Heading
  translate([px, py + 2, LUME_HEIGHT/2 + 14])
    rotate([90, 0, 180])
      label("PORT CLUSTER", size=6);

  // Six labels stacked vertically with arrows pointing into the cluster
  ports = [
    ["HDMI 2.1",          16],
    ["USB-A 3.0",         8],
    ["USB-A 3.0",         0],
    ["Gigabit Ethernet", -8],
    ["Kensington lock", -16],
    ["12V DC barrel",   -24]
  ];
  // labels on the LEFT of the cluster as viewed from rear (negative-X side
  // of the cluster center). For a +Y camera, +X in world is on its left.
  for (i = [0:len(ports)-1])
    translate([px - 50, py + 1, pz + ports[i][1]])
      rotate([90, 0, 180])
        label(ports[i][0], size=4);

  // VESA label
  translate([0, py + 1, LUME_HEIGHT/2 - 8])
    rotate([90, 0, 180])
      label(str("VESA ", VESA_PITCH, "x", VESA_PITCH), size=5);

  // Vent label
  translate([VENT_X, py + 1, VENT_Z + VENT_H/2 + 6])
    rotate([90, 0, 180])
      label("Rear exhaust vent", size=4);
}

// ============================================================
// D3: Cable routing diagram (interior view)
// ============================================================
module cable_path(p1, p2, label_text) {
  // Top-down friendly: route the wire as XY arc at fixed Z (z=top), label
  // ABOVE the bar (out the +Z direction) so a top-down camera always sees it.
  z_run = LUME_HEIGHT/2 + 2;  // route along top exterior so it's always visible
  color("#1ea7ff") {
    hull() {
      translate([p1[0], p1[1], z_run]) sphere(2.5);
      translate([p2[0], p2[1], z_run]) sphere(2.5);
    }
    // endpoint markers (anchor to component face)
    translate([p1[0], p1[1], z_run]) sphere(5);
    translate([p2[0], p2[1], z_run]) sphere(5);
  }
  midx = (p1[0]+p2[0])/2;
  midy = (p1[1]+p2[1])/2;
  // Top-down: text on XY plane facing +Z (no rotation needed)
  translate([midx, midy + 8, z_run + 2])
    color("#003070") label(label_text, size=6);
}

module view_cables() {
  // We use a TOP-DOWN view of the bar interior — camera looks straight down at +Z.
  // Skip shell entirely so wires + components are clearly visible.
  // Outline of shell footprint as a thin frame:
  color("#777777")
    difference() {
      translate([-LUME_WIDTH/2, -LUME_DEPTH/2, -LUME_HEIGHT/2 + WALL])
        cube([LUME_WIDTH, LUME_DEPTH, 1]);
      translate([-LUME_WIDTH/2 + 4, -LUME_DEPTH/2 + 4, -LUME_HEIGHT/2 + WALL - 0.1])
        cube([LUME_WIDTH - 8, LUME_DEPTH - 8, 1.2]);
    }
  // Component proxies (no internals — would obscure cables)
  translate([JETSON_ORIGIN_X, JETSON_ORIGIN_Y, -LUME_HEIGHT/2 + WALL + 2])
    proxy_jetson();
  translate([CAM_CENTER_X, -LUME_DEPTH/2 + WALL + FEMTO_D/2, 0])
    proxy_femto();
  translate([100, 0, LUME_HEIGHT/2 - WALL - UMA8_H - 2])
    proxy_uma8();
  translate([CAM_LEFT_X, -LUME_DEPTH/2 + WALL + SVPRO_D/2, 0])
    rotate([-90, 0, 0]) proxy_svpro();
  translate([CAM_RIGHT_X, -LUME_DEPTH/2 + WALL + SVPRO_D/2, 0])
    rotate([-90, 0, 0]) proxy_svpro();

  // Cable runs (component-edge → Jetson)
  cable_path([CAM_CENTER_X, -LUME_DEPTH/2 + WALL + 30, 0],
             [JETSON_ORIGIN_X + 40, JETSON_ORIGIN_Y, JETSON_FLOOR_Z + 40],
             "Femto USB-C");
  cable_path([100, 0, LUME_HEIGHT/2 - WALL - 8],
             [JETSON_ORIGIN_X + 40, JETSON_ORIGIN_Y + 30, JETSON_FLOOR_Z + 50],
             "UMA-8 USB");
  cable_path([CAM_LEFT_X, -LUME_DEPTH/2 + WALL + 20, 0],
             [JETSON_ORIGIN_X + 30, JETSON_ORIGIN_Y - 20, JETSON_FLOOR_Z + 30],
             "SVPRO L");
  cable_path([CAM_RIGHT_X, -LUME_DEPTH/2 + WALL + 20, 0],
             [JETSON_ORIGIN_X + 50, JETSON_ORIGIN_Y - 30, JETSON_FLOOR_Z + 30],
             "SVPRO R");
  cable_path([LED_X, -LUME_DEPTH/2 + WALL + 4, LED_Z],
             [JETSON_ORIGIN_X + 20, JETSON_ORIGIN_Y - 40, JETSON_FLOOR_Z + 20],
             "LED data");
  cable_path([JETSON_ORIGIN_X, LUME_DEPTH/2 - WALL - FAN_H, VENT_Z],
             [JETSON_ORIGIN_X, JETSON_ORIGIN_Y, JETSON_FLOOR_Z + 60],
             "Fan PWM");
  cable_path([PORT_CLUSTER_X, LUME_DEPTH/2 - WALL - 4, PORT_CLUSTER_Z],
             [JETSON_ORIGIN_X + 50, JETSON_ORIGIN_Y, JETSON_FLOOR_Z + 50],
             "Port cluster");
}

// ============================================================
if      (VIEW == "dim_front")  view_dim_front();
else if (VIEW == "dim_top")    view_dim_top();
else if (VIEW == "portmap")    view_portmap();
else if (VIEW == "cables")     view_cables();
else echo(str("unknown VIEW: ", VIEW));
