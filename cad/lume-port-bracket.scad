// LUME — Rear port bracket
// Separate printed part. Screws into the interior rear wall via two heat-set
// insert bosses on each side. Provides labeled cutouts for Jetson Dev Kit IO:
// HDMI, USB-A x2, Ethernet (RJ-45), and Kensington lock. Barrel jack and
// exhaust vent live in the main shell.

include <lume-config.scad>
use <lume-primitives.scad>

BRACKET_W = 90;
BRACKET_H = 40;
BRACKET_T = 3.0;
PORT_LABEL_SIZE = 2.8;
PORT_LABEL_DEPTH = 0.6;

// Port layout (center-referenced within bracket). HDMI left, USB-A middle x2, ETH right.
PORT_HDMI_DX  = -32;
PORT_USB1_DX  = -10;
PORT_USB2_DX  =  10;
PORT_ETH_DX   =  32;

module lume_port_bracket() {
  difference() {
    // Plate body with rounded corners
    rplate(BRACKET_W, BRACKET_H, BRACKET_T, 2);

    // HDMI cutout (15.8 x 7.2, Type A full-size)
    translate([PORT_HDMI_DX, -3, 0])
      cube([PORT_HDMI_W, PORT_HDMI_H, BRACKET_T*2], center=true);
    // HDMI label
    translate([PORT_HDMI_DX, 8, BRACKET_T/2 - PORT_LABEL_DEPTH])
      linear_extrude(height=PORT_LABEL_DEPTH + 0.1)
        text("HDMI", size=PORT_LABEL_SIZE, halign="center", valign="center",
             font="Helvetica:style=Bold");

    // USB-A x2
    for (dx = [PORT_USB1_DX, PORT_USB2_DX]) {
      translate([dx, -3, 0])
        cube([PORT_USB_W, PORT_USB_H, BRACKET_T*2], center=true);
      translate([dx, 8, BRACKET_T/2 - PORT_LABEL_DEPTH])
        linear_extrude(height=PORT_LABEL_DEPTH + 0.1)
          text("USB", size=PORT_LABEL_SIZE, halign="center", valign="center",
               font="Helvetica:style=Bold");
    }

    // Ethernet (RJ-45)
    translate([PORT_ETH_DX, -3, 0])
      cube([PORT_ETH_W, PORT_ETH_H, BRACKET_T*2], center=true);
    translate([PORT_ETH_DX, 14, BRACKET_T/2 - PORT_LABEL_DEPTH])
      linear_extrude(height=PORT_LABEL_DEPTH + 0.1)
        text("LAN", size=PORT_LABEL_SIZE, halign="center", valign="center",
             font="Helvetica:style=Bold");

    // Mounting holes — 4 corners, clearance for M3 screws into heat-set bosses
    for (x = [-BRACKET_W/2 + 5, BRACKET_W/2 - 5],
         z = [-BRACKET_H/2 + 5, BRACKET_H/2 - 5])
      translate([x, z, 0])
        bolt_m3_counterbore(len=BRACKET_T + 1, cbore=1.6);
  }
}

lume_port_bracket();
