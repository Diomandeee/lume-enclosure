// LUME v1 — Global Configuration
// All dimensions in mm. Edit here first; every module reads from this file.
// Coordinate system: X = width (left/right), Y = depth (front=-Y, rear=+Y), Z = height (up/down)

// ======== EXTERIOR ========
LUME_WIDTH   = 500;   // X axis — full bar width
LUME_HEIGHT  = 120;   // Z axis — bar height
LUME_DEPTH   = 85;    // Y axis — how far off wall
WALL         = 3.0;   // shell wall thickness
CORNER_R     = 8;     // exterior corner radius — Sonos-style soft curve
INNER_R      = 5;     // interior corner radius
CHAMFER      = 1.2;   // edge chamfer for visible print lines

// ======== SPLIT PLANE ========
// Shell splits front/rear at Y = SPLIT_Y (measured from bar center, front is -Y)
// Front half:  sensors + LED + speakers + front bezel insert
// Rear half:   compute, ports, VESA mount, airflow vents
SPLIT_Y      = 0;     // centered split
SPLIT_X      = 80;   // moved off-center to hide seam behind right speaker grille (was 0, bisected Femto+LED+wordmark)
SPLIT_SHELL_X = true; // cut each front/rear half at X=SPLIT_X so pieces fit 420x420 plate
LIP_W        = 2.0;   // tongue-and-groove joinery lip width
LIP_H        = 3.0;   // joinery lip height (depth into mating half)
LIP_CLEAR    = 0.2;   // print clearance between tongue + groove

// ======== COMPONENT FOOTPRINTS (measured, real parts) ========
JETSON_W = 110; JETSON_D = 110; JETSON_H = 72;   // AGX Orin Dev Kit incl. heatsink/fan
JETSON_MOUNT_PITCH = 96;                          // carrier board mount hole pattern
// Orbbec Femto Mega — corrected against official datasheet v1.1 (2026-04-26).
// Datasheet specs: W×H×D = 115×40×145mm, weight 560g.
// The 145mm depth is the TOTAL side profile including the rear sleeve that
// houses the Jetson Nano. The front "head" section (where the pill window
// + lens cluster lives) is shorter — front view shows 40.1mm height +
// 111.5mm width, side view shows 40.3mm head height + 115.6mm total depth
// = ~45mm head + ~70mm rear sleeve. Cooling channel BETWEEN head and
// sleeve must stay unobstructed (datasheet pg 6).
FEMTO_W      = 115;     // ⭐ was 127 — corrected per datasheet
FEMTO_H      = 40;      // ⭐ was 38 — corrected per datasheet
FEMTO_D      = 145;     // ⭐ was 65 — TOTAL depth incl. rear sleeve (was treating as head only)
FEMTO_HEAD_D = 45;      // front section depth (camera face + lens housing)
FEMTO_SLEEVE_D = 75;    // rear sleeve depth (Jetson Nano + ports + cooling)
FEMTO_SLEEVE_W = 75;    // narrower than head — rear sleeve is ~75mm wide
FEMTO_SLEEVE_H = 28;    // 27.9mm per datasheet side-view dim
FEMTO_COOLING_GAP = 25; // approx air gap between head and sleeve, must be vented
// Camera window — pill/stadium shape on front face, contains all lenses.
// Datasheet front-view shows 111.5mm wide × 40.1mm tall stadium with
// end-radius equal to half-height (20mm).
CAM_WINDOW_W = 111;     // pill width
CAM_WINDOW_H = 40;      // pill height
CAM_WINDOW_R = 20;      // end-cap radius (half of CAM_WINDOW_H)
CAM_WINDOW_REVEAL = 2.5; // mm bezel reveal margin around camera body in cradle
CAM_WINDOW_RECESS = 1.5; // mm front-face recess depth around window for shadow line
// Mount pattern — datasheet pg 3 says "Sides: 4 × M2.5". Side view drawing
// shows 50mm vertical pitch between visible bolt holes. Horizontal pitch
// (along camera depth) marked TBD in our SCAD until we measure the
// physical camera.
FEMTO_SIDE_MOUNT_HOLE_D = 2.7;  // M2.5 clearance
FEMTO_SIDE_MOUNT_PITCH_Z = 50;  // vertical pitch per datasheet side view
FEMTO_SIDE_MOUNT_PITCH_Y = 50;  // ⚠ horizontal pitch TBD — placeholder
FEMTO_TRIPOD_HOLE_D = 7.0;      // 1/4-20 UNC clearance, verify screw/head access
FEMTO_CRADLE_W = FEMTO_W + 14;
FEMTO_CRADLE_D = 96;
FEMTO_CRADLE_T = 4;
FEMTO_CRADLE_SIDE_T = 4;
FEMTO_CRADLE_SIDE_H = 18;
FEMTO_CRADLE_REAR_STOP_T = 4;
// Legacy compat — old code still references these names.
FEMTO_MOUNT_PITCH_X = 100;      // legacy; not used in v2 cradle
FEMTO_MOUNT_PITCH_Z = 30;       // legacy
UMA8_OD  = 90;  UMA8_H   = 18;                    // miniDSP UMA-8 v2 disc (USB out top)
FAN_W    = 80;  FAN_H    = 25;                    // Noctua NF-A8 PWM
FAN_MOUNT_PITCH = 71.5;                           // 80mm fan standard
SVPRO_LEGACY_ENABLED = false;                     // old dual-SVPRO placeholders are not in the current BOM
SVPRO_W  = 38;  SVPRO_D  = 38;  SVPRO_H  = 30;    // SVPRO IMX577 module, legacy optional
SVPRO_LENS_OD = 18;                               // lens barrel OD
LED_OD   = 66;  LED_RING_ID = 52;  LED_H = 8;    // legacy 24-LED NeoPixel ring (kept for internal diffuser mount geometry)

// Arducam B0478/B0478C IMX586 48MP USB 3.0 camera module.
// User BOM update 2026-04-30: "Arducam USB 3.0 Camera, 120fps,
// IMX586 48MP, 78°(D), motorized focus lens, metal case".
// Arducam datasheet B0478 lists 34×34mm board, Type-C connector,
// and 28×28mm mounting-hole pitch. With enclosure, use this as the
// right-side auxiliary RGB camera bay rather than the old SVPRO_R.
ARDUCAM_ENABLED = true;
ARDUCAM_LAYOUT = "single_right"; // "single_right" | "dual"
ARDUCAM_X = 180;          // right-side auxiliary bay; mirrors CAM_RIGHT_X below
ARDUCAM_XS = ARDUCAM_LAYOUT == "dual" ? [-180, 180] : [ARDUCAM_X];
ARDUCAM_Z = 0;
ARDUCAM_CASE_W = 34;
ARDUCAM_CASE_H = 34;
ARDUCAM_CASE_D = 16.2;       // datasheet side-view stack, caliper case when in hand
ARDUCAM_MOUNT_PITCH = 28;
ARDUCAM_MOUNT_HOLE_D = 2.7;  // M2.5 clearance; verify against the metal case
ARDUCAM_LENS_HOLE_D = 20;
ARDUCAM_RECESS = 1.2;
ARDUCAM_MOUNT_T = 4;
ARDUCAM_CABLE_SLOT_W = 14;
ARDUCAM_CABLE_SLOT_H = 8;

// ======== FRONT-FACE LAYOUT ========
CAM_LEFT_X   = -180;  // left SVPRO camera
CAM_CENTER_X = 0;     // center Femto Mega (ToF depth + RGB)
CAM_RIGHT_X  = 180;   // right SVPRO camera (or blank plug)
CAM_BEZEL_OD = 28;    // visible bezel ring OD around each lens
CAM_HOLE_D   = 22;    // clearance through-hole for lens barrel

// LED indicator (single large diffused dot per Gemini hero render, not a ring).
// Optically centered below wordmark + between the 3 cameras.
LED_X = 0;
LED_Z = -32;
LED_OD_INDICATOR = 42;   // visible front aperture (the glowing disc)
LED_ID = LED_OD_INDICATOR; // compat with existing shell cutout var
LED_DIFFUSER_THICK = 2.0; // clear PETG diffuser disc

// End grilles — render reference shows a clean slab, no perforated ends.
// Keep variables for backwards compat, but zero-out the X offset so front
// face has no grille cutouts. Re-enable by setting SHOW_END_GRILLES=true.
SHOW_END_GRILLES = false;
GRILLE_W = 70;
GRILLE_H = 70;
GRILLE_X_OFFSET = LUME_WIDTH/2 - GRILLE_W/2 - 22;
GRILLE_HOLE_D = 2.8;
GRILLE_PITCH  = 4.5;

// Wordmark (debossed LUME, paint-fill in post)
WORDMARK_TEXT  = "LUME";
WORDMARK_H     = 16;
WORDMARK_DEPTH = 1.5;  // 1.5mm carved from outer face, leaves 1.5mm wall behind (printable)
WORDMARK_Z     = 18;
// Pre-mirror the wordmark text in X. The OpenSCAD→Blender OBJ import path
// applies an effective 180° Z rotation (front face -Y → +Y, X also flips),
// which makes "LUME" read mirrored from the Blender hero camera. Set to true
// only when exporting OBJ for Blender; keeps OpenSCAD direct renders correct.
MIRROR_WORDMARK = false;

// ======== REAR-FACE LAYOUT ========
// VESA 100x100 mount + optional French-cleat slot
VESA_PITCH = 100;
VESA_HOLE_D = 4.2;    // M4 clearance
VESA_PLATE_T = 4;     // mount plate thickness
CLEAT_ANGLE = 45;     // French cleat bevel

// Port cluster (right side of rear, matches Jetson Dev Kit IO)
// Labeled cutouts: HDMI, USB-A x2, Ethernet, Kensington, barrel jack
PORT_CLUSTER_X = 130;  // center of port zone
PORT_CLUSTER_Z = -10;
PORT_HDMI_W   = 15.8; PORT_HDMI_H   = 7.2;
PORT_USB_W    = 14.8; PORT_USB_H    = 7.2;
PORT_ETH_W    = 16.2; PORT_ETH_H    = 14.2;
PORT_BARREL_D = 8;
PORT_KENSING_W = 8;   PORT_KENSING_H = 4;

// Rear airflow vents (exhaust path from Jetson fan)
VENT_W = 120;
VENT_H = 60;
VENT_X = -100;   // left-rear, opposite port cluster
VENT_Z = 5;

// Intake vents (bottom face, passive)
INTAKE_W = 80;
INTAKE_D = 40;
INTAKE_X_LEFT  = -120;
INTAKE_X_RIGHT = 120;

// ======== FASTENERS ========
// M3 heat-set inserts used throughout (corners + component mounts)
INSERT_OD     = 4.5;    // insert outer diameter (knurled body)
INSERT_DEPTH  = 6;      // how deep insert sits in boss
INSERT_BOSS_OD = 6.5;   // boss OD around insert (for strength)
BOLT_M3_CLEAR  = 3.4;   // M3 clearance hole
BOLT_M4_CLEAR  = 4.4;
COUNTERBORE_D  = 6.0;   // M3 socket-head counterbore

// Corner bolt pattern (bonds front + rear halves)
CORNER_BOLT_INSET = 14;  // from exterior edges

// ======== INTERNAL STRUCTURE ========
// Ribbing for shell stiffness (prevents thin-wall bow during ASA print)
RIB_T = 2.0;   // rib thickness
RIB_H = 8;     // rib height off interior wall
RIB_PITCH = 80;  // spacing along bar length

// Cable channel (LED ribbon + fan + mic USB routing)
CABLE_CHANNEL_W = 10;
CABLE_CHANNEL_H = 6;
SENSOR_CABLE_BUNDLE_W = ARDUCAM_LAYOUT == "dual" ? 22 : 14;
SENSOR_CABLE_BUNDLE_H = 8;

// Thermal baffle — separates hot zone (Jetson) from cold zone (Femto + mic)
BAFFLE_T = 2.5;
BAFFLE_X = -LUME_WIDTH/2 + 180;  // isolates left 180mm as hot zone
LEGACY_BAR_COMPUTE_PARTS_ENABLED = false; // fan shroud, Jetson port anchors, and baffle are not mandatory with K11 pod

// ======== T-FORM REAR POD (compute enclosure) ========
// LUME v1.5 pivot 2026-04-26: K11 mini-PC won't fit inside the 85mm-deep bar
// in any orientation. Solution: T-form factor — front bar stays as the slim
// visual element, a perpendicular pod extends back from the bar centre to
// hold the K11 + Mega's Jetson-Nano hump + cables + VESA.
//
// Set POD_ENABLED=false to render the pre-pod single-bar form (legacy demo).
POD_ENABLED  = true;

// GMKtec NucBox K11 — verified against GMKtec product spec, 2026-04-30.
// Official dimensions: 132 × 125 × 58 mm (W × D × H).
// Cooling: "Upgraded Top and Bottom Large Cooling Fans" — dual fan (bottom intake,
// top exhaust). Pod must provide floor intake + top exhaust paths.
// Power: 54W typical, AMD Ryzen 9 8945HS + Radeon 780M 2.8GHz.
// Ports: 6× USB total, HDMI 2.1, DP 2.1, 2× USB4-C, 2× 2.5G NIC (i226V), Oculink.
// Includes: VESA mount + screws (pattern TBD, caliper-verify on arrival).
// Was previously placeholder 142.6 × 113 × 49.5 (Amazon image estimate, all 3 axes
// off). Pod cavity needs to accommodate K11_D = 125mm plus cable bend.

// ⭐ VERIFIED K11 dimensions per GMKtec spec (2026-04-30).
// Previous placeholders (142.6 × 113 × 49.5) were wrong on all 3 axes.
K11_W  = 132;  // along bar X-axis when laid flat in pod (was 142.6)
K11_D  = 125;  // along bar Y-axis pod-depth (was 113 — drives POD_D bump)
K11_H  =  58;  // along bar Z-axis bar-height (was 49.5)
K11_VESA_PITCH = 75;            // bundled mount pattern — caliper-verify on arrival
K11_BOTTOM_FAN_INTAKE = true;   // K11 has BOTTOM fan; pod floor needs intake vents
K11_TOP_FAN_EXHAUST   = true;   // K11 has TOP fan; pod top needs exhaust vents
K11_BOTTOM_CLEAR_MIN  = 12;     // mm air-gap floor below K11 for bottom-fan intake

// K11 sled inside rear pod. The tray prints flat, but standoffs lift the K11
// above the tray so the bottom intake can breathe through the slotted base.
SLED_T = 4;
SLED_RIM_H = 12;
SLED_FLOOR_CLEAR = K11_BOTTOM_CLEAR_MIN;
SLED_K11_STANDOFF_D = 10;
SLED_INTAKE_SLOT_W = 8;
SLED_INTAKE_SLOT_D = 92;

// Pod exterior. Width covers ~40% of bar width centered, height matches the
// bar so the side silhouette is a clean Γ. Depth gives K11 + cable bend
// radius + Mega Jetson hump (25mm extending back from Mega body) + airflow.
POD_W        = 200;
POD_H        = 130;             // ⭐ was 120 (LUME_HEIGHT). Bumped to give actual
                                //   K11_H 58mm + bottom-fan intake clearance
                                //   (12mm) + top-fan exhaust clearance (~50mm) =
                                //   needs internal Z >= 120mm, so POD_H >= 126.
POD_D        = 165;             // ⭐ was 130. Verified K11_D = 125mm needs
                                //   internal cavity 125 + 25 cable bend + 10
                                //   airflow rear gap = 159mm internal → POD_D=165
                                //   for 3mm walls. Old 130 left K11 0.5mm short.
POD_X_OFF    = 0;               // 0 = centered. -50 shifts left for asymmetry.
POD_WALL     = WALL;            // reuse 3mm wall thickness for visual continuity
POD_FILLET_R = 12;              // chamfer transition between bar back + pod front

// Pod-bar joinery — separate prints, joined post-print via M3 corner bolts
// through a flange on the pod's front face into heat-set inserts in the
// bar's rear shell.
POD_FLANGE_T   = 4;     // flange thickness (the lip that overlaps the bar)
POD_FLANGE_W   = 12;    // how far the flange extends past the pod opening
POD_BOLT_INSET = 8;     // from flange edge to bolt centre

// VESA on pod back face (replaces VESA on bar rear shell when POD_ENABLED).
POD_VESA_PITCH = 100;       // standard VESA 100×100
POD_VESA_PLATE_T = VESA_PLATE_T;  // 4mm — same as bar VESA plate

// Pod airflow vents — slots on side walls, intake near floor, exhaust near top.
POD_VENT_W = 40;
POD_VENT_H = 4;
POD_VENT_PITCH = 10;
POD_VENT_COUNT = 6;     // 6 slots per side wall × 2 sides = 12 total

// Cable/feedthrough between bar and pod. This must pass the Femto Mega rear
// sleeve as well as cables. Datasheet side view shows sleeve height 27.9mm;
// keep generous clearance so the cooling channel is not pinched.
POD_FEEDTHROUGH_W = max(80, FEMTO_SLEEVE_W + 12);
POD_FEEDTHROUGH_H = max(34, FEMTO_SLEEVE_H + 10);

// Service access strategy:
// - Bar-to-pod feedthrough is the single internal umbilical between sensor bar
//   and compute pod.
// - Rear service window exposes the K11's native ports while bench-mounted.
// - Right-side service slot is for a panel-mount USB extension, Bluetooth
//   transmitter/dongle pigtail, or emergency cable exit when wall-mounted.
POD_REAR_SERVICE_W = 150;
POD_REAR_SERVICE_H = 64;
POD_REAR_SERVICE_Z = 0;
POD_SIDE_SERVICE_SLOT_D = 44;       // along pod depth/Y
POD_SIDE_SERVICE_SLOT_H = 18;       // vertical opening
POD_SIDE_SERVICE_SLOT_Y = POD_D - 42;
POD_SIDE_SERVICE_SLOT_Z = -16;
POD_SIDE_SERVICE_SLOT_SIDE = 1;     // 1 = right side, -1 = left side

// ======== BAR DISPLAY (ZHAOCAILIN 11.3" 1920×440) ========
// User BOM update 2026-04-30: ZHAOCAILIN 11.3" mini monitor, 1920×440,
// IPS, 60Hz, 500 nits, mini HDMI + USB-C power. Public listings show
// 12" × 3.15" × 2.36" (305×80×60mm) for the cased monitor, but also
// warn dimensions are inconsistently described. Treat 305×80mm as the
// visible face footprint. The 60mm listing depth is captured below as
// vendor data, but the current top-cradle visual thickness remains a
// conservative 12mm until the screen orientation/case profile is approved.
//
// Important: this is a cased monitor, not a bare LCD panel. It should sit
// on a top cradle with a cable pass-through. Do NOT cut a 322×84mm hole
// through the 85mm-deep shell; that leaves no front/rear wall margin.
DISPLAY_ENABLED = true;
DISPLAY_MOUNT_MODE = "top_cradle"; // "top_cradle" | "flush_cutout" legacy
DISPLAY_W = 305;        // cased monitor face width, caliper-verify
DISPLAY_H = 80;         // cased monitor face height/depth on top, caliper-verify
DISPLAY_LISTING_DEPTH = 60; // vendor-listed D dimension; may include rear case/stand
DISPLAY_BEZEL = 0;      // cased unit already has bezel
DISPLAY_THICK = 12;     // placeholder visual thickness; caliper actual case
DISPLAY_RECESS = 0;     // not used in top-cradle mode
DISPLAY_CUTOUT_W = DISPLAY_W + 2 * DISPLAY_BEZEL + 2;  // +2mm clearance
DISPLAY_CUTOUT_H = DISPLAY_H + 2 * DISPLAY_BEZEL + 2;
DISPLAY_X_OFF = 0;      // centered on bar X axis
DISPLAY_CRADLE_CLEAR = 2;
DISPLAY_CRADLE_RAIL_T = 4;
DISPLAY_CRADLE_RAIL_H = 4;
DISPLAY_CABLE_SLOT_X = 125; // right/rear service slot for mini HDMI + USB-C
DISPLAY_CABLE_SLOT_Y = DISPLAY_H/2 - 8;
DISPLAY_CABLE_SLOT_W = 46;
DISPLAY_CABLE_SLOT_D = 18;
// Cable routing: mini HDMI from K11 pod → bar interior → display.
// USB-C for power from K11 USB port.
DISPLAY_CABLE_CHANNEL_W = 15;
DISPLAY_CABLE_CHANNEL_H = 8;

// ======== RENDER QUALITY ========
$fa = 2;
$fs = 0.4;

// ======== FEATURE TOGGLES ========
SHOW_COMPONENTS = true;    // proxy volumes in assembly view
SHOW_INTERNALS  = true;    // internal mounts + ribs
EXPLODED        = false;   // exploded view (offsets all parts along Y)
EXPLODE_DIST    = 60;      // exploded offset magnitude
USE_JOINERY     = false;   // tongue-and-groove at split plane (off by default —
                           // corner bolts alone are sufficient, and joinery
                           // requires careful clearance tuning per-printer)
