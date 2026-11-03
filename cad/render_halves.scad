// Renders a single half-shell STL with rotation controlled by ROT.
// ROT: 0 = exterior front-facing, 1 = interior facing camera (flipped 180° Y).
FILE = "exports/shell_front_L.stl";
ROT  = 0;

rotate([0, ROT*180, 0]) import(FILE);
