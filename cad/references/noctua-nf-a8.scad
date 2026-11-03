// Noctua NF-A8 PWM — parametric reference model for clearance checking.
//
// Source: Noctua NF-A8 PWM infosheet (cdn.noctua.at/media/noctua_nf_a8_pwm_infosheet_en_web.pdf)
// and published specification page (noctua.at/en/nf-a8-pwm/specification).
//
// NOTE: Noctua does NOT publish an official STEP file for the NF-A8 as of 2026-04.
// GrabCAD community models exist but consistently have the wrong 70x70 mount pitch.
// This model uses the verified 71.5 mm pitch from the Noctua datasheet.
//
// Geometry is conservative (envelope + hub + blade disc + anti-vibration pads)
// — accurate enough for enclosure clearance checking, not for CFD.

$fn = 96;

W = 80;        // width
H = 80;        // height
D = 25;        // depth (thickness)
R_CORNER = 4;  // frame corner fillet
MOUNT_PITCH = 71.5;     // Noctua verified spec
MOUNT_HOLE_D = 4.5;     // M4 clearance
HUB_D = 34;             // motor hub diameter
HUB_THICK = 18;         // hub cylinder depth (centered in frame)
BLADE_DISC_D = 77;      // blade-swept disc diameter (just inside 80mm frame)
PAD_SIZE = 10;          // anti-vibration corner pad footprint
PAD_THICK = 1.5;        // pad protrusion beyond frame on each face

module rounded_square(w, h, r) {
    hull() {
        translate([ r,  r]) circle(r);
        translate([w-r, r]) circle(r);
        translate([w-r,h-r]) circle(r);
        translate([ r, h-r]) circle(r);
    }
}

module frame() {
    difference() {
        linear_extrude(D) rounded_square(W, H, R_CORNER);
        // Blade bore through frame
        translate([W/2, H/2, -0.1])
            cylinder(d = BLADE_DISC_D, h = D + 0.2);
        // Mount holes at corners, pitch centered on frame
        off = (W - MOUNT_PITCH) / 2;
        for (x = [off, W - off], y = [off, H - off])
            translate([x, y, -0.1])
                cylinder(d = MOUNT_HOLE_D, h = D + 0.2);
    }
}

module hub_and_blades() {
    // Central hub (motor)
    translate([W/2, H/2, (D - HUB_THICK)/2])
        cylinder(d = HUB_D, h = HUB_THICK);
    // Blade disc (solid disc for envelope; protects against CFD-grade detail)
    translate([W/2, H/2, D/2 - 1])
        cylinder(d = BLADE_DISC_D - 0.5, h = 2);
}

module anti_vibration_pads() {
    // 1.5 mm silicone pads on both intake and exhaust faces at each corner
    off = R_CORNER;
    for (x = [off, W - off - PAD_SIZE],
         y = [off, H - off - PAD_SIZE],
         z = [-PAD_THICK, D]) {
        translate([x, y, z])
            cube([PAD_SIZE, PAD_SIZE, PAD_THICK]);
    }
}

module noctua_nf_a8() {
    frame();
    hub_and_blades();
    anti_vibration_pads();
}

noctua_nf_a8();
