// LUME pod print-orientation wrappers.
//
// These do not change the pod geometry. They only emit STL variants already
// rotated into the intended print pose so OrcaSlicer does not have to transform
// the model during CLI validation.

use <lume-pod.scad>

PART = "pod_top_open_up"; // "pod_top_open_up" | "pod_bottom_open_up"

if (PART == "pod_top_open_up") {
  rotate([180, 0, 0]) pod_top();
} else if (PART == "pod_bottom_open_up") {
  pod_bottom();
}

