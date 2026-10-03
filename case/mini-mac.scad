// airInk mini Mac: a 3D-printable case for the SEN66, XIAO ESP32-C3 and
// 1.54" e-paper display, styled after the 1984 Macintosh.
//
// Units are millimetres. Axes: x = right (seen from the front),
// y = front face (0) to back, z = up.
//
// Printable parts (exported in print orientation):
//   openscad -D 'part="shell"'        -o shell.stl        mini-mac.scad
//   openscad -D 'part="bezel"'        -o bezel.stl        mini-mac.scad
//   openscad -D 'part="sensor_clamp"' -o sensor_clamp.stl mini-mac.scad
//   openscad -D 'part="display_clip"' -o display_clip.stl mini-mac.scad  (print 2)
//
// The SEN66 sits in the base with its inlet/outlet face against the back
// wall. The XIAO sits above a heat shelf, so its warmth rises away from the
// sensor (Sensirion SEN6x mechanical design guidelines, section 2.4).

/* [View] */
part = "assembly"; // [assembly, exploded, section, shell, bezel, sensor_clamp, display_clip]
section_x = 0;     // cut plane for the section view

/* [Case] */
W = 64;            // outer width
H = 86;            // outer height
D = 72;            // outer depth, bezel and shell together
bezel_d = 10;      // bezel depth: the front/back seam, like the original
wall = 2.4;
floor_t = 3;
r_edge = 4;        // vertical edge radius
foot_h = 2;        // recessed foot band at the bottom
foot_in = 1;
tol = 0.25;        // clearance between mating parts
lip_d = 4;         // bezel lip that slides into the shell
lip_t = 1.6;

/* [Display: Waveshare 1.54" module] */
mod_w = 48;        // module outline, mounted landscape
mod_h = 33;
mod_t = 3.2;       // panel + PCB
aa = 27.6;         // active area (square)
aa_from_left = 10.2; // module left edge to active area, seen from the front: measure yours
aa_from_top = 2.7;   // module top edge to active area: measure yours
win_z = 55;        // window centre height
win_margin = 0.6;  // window overlap beyond the active area, per side
recess = 40;       // outer size of the 45° screen recess

/* [SEN66] */
sen = [55.2, 25.6, 21.3]; // length, height, depth (datasheet fig. 11)
sen_rib = 1.0;     // sealing ribs between sensor face and back wall
shelf_z = 33;      // heat shelf: sensor below, XIAO above

/* [XIAO ESP32-C3] */
xiao_w = 17.8;
xiao_l = 21;
xiao_pcb = 1.2;
xiao_x = 14;       // centre, seen from the front
xiao_lift = 2.5;   // PCB underside above the shelf; use ~9 with downward pin headers

/* [Text] */
back_text = "airInk";
inside_text = "";  // engraved inside the back wall, e.g. your names

$fn = 48;

// ---------------------------------------------------------------- derived

iw = W - 2 * wall;
win = aa + 2 * win_margin;
rd = (recess - win) / 2;          // recess depth for 45° walls
screen_t = rd + 0.8;              // face thickness around the window
mcx = mod_w / 2 - aa_from_left - aa / 2;              // module centre x
mcz = win_z + aa_from_top + aa / 2 - mod_h / 2;        // module centre z

sen_top = floor_t + 1 + sen[1];   // sensor rests on 1 mm rails
sen_face_y = D - wall - sen_rib;  // inlet/outlet face, toward the back wall
sen_rear_y = sen_face_y - sen[2]; // connector face

// Sensor face features use datasheet coordinates: u along the length from
// the inlet end, v down from the top edge. The inlet end sits on the +x side.
function sx(u) = sen[0] / 2 - u;
function sz(v) = sen_top - v;
fan = [sx(42.4), sz(12.8)];
fan_d = 20.5;

xiao_pcb_z = shelf_z + wall + xiao_lift;
usb_z = xiao_pcb_z + xiao_pcb + 1.6;
xiao_y1 = D - wall - 0.6;         // USB-C receptacle overhangs the PCB edge
xiao_y0 = xiao_y1 - xiao_l;

shelf_y0 = bezel_d + lip_d + tol;

// ---------------------------------------------------------------- helpers

module rbox(w, d, h, r) {
    hull() for (x = [-w / 2 + r, w / 2 - r], y = [r, d - r])
        translate([x, y, 0]) cylinder(r = r, h = h);
}

module rrect(w, h, r) {
    re = min(r, min(w, h) / 2 - 0.01);
    offset(re) square([w - 2 * re, h - 2 * re], center = true);
}

// Extrude 2D children (x right, y up as seen from the front) between
// the planes y0 and y0 + depth.
module front_cut(y0, depth) {
    translate([0, y0 + depth, 0]) rotate([90, 0, 0]) linear_extrude(depth) children();
}

// Outer body between y0 and y1, including the recessed foot band.
module body(y0, y1) {
    intersection() {
        union() {
            translate([0, 0, foot_h]) rbox(W, D, H - foot_h, r_edge);
            translate([0, foot_in, 0])
                rbox(W - 2 * foot_in, D - 2 * foot_in, foot_h + 0.01, r_edge - foot_in);
        }
        translate([-W, y0, -1]) cube([2 * W, y1 - y0, H + 2]);
    }
}

module cavity(y0, y1) {
    translate([-iw / 2, y0, floor_t]) cube([iw, y1 - y0, H - floor_t - wall]);
}

// Chueli, from images/chueli/happy.svg (PR #1). Ink becomes the engraving.
// Elements are layered in SVG order, so later white fills cover earlier ink.
chueli_horn_l = [[25.00, 14.00], [24.37, 13.32], [23.81, 12.61], [23.31, 11.88], [22.89, 11.11],
    [22.53, 10.32], [22.25, 9.50], [22.03, 8.65], [21.89, 7.78], [21.81, 6.88], [21.81, 5.94],
    [21.87, 4.99], [22.00, 4.00]];
chueli_horn_r = [for (p = chueli_horn_l) [72 - p[0], p[1]]];
chueli_spot_l = [[21.00, 26.00], [21.01, 23.65], [21.48, 21.59], [22.34, 19.83], [23.52, 18.37],
    [24.93, 17.22], [26.50, 16.38], [28.15, 15.84], [29.81, 15.63], [31.41, 15.73], [32.85, 16.16],
    [34.08, 16.92], [35.00, 18.00], [35.55, 19.29], [35.72, 20.62], [35.55, 21.97], [35.07, 23.30],
    [34.34, 24.57], [33.38, 25.75], [32.23, 26.81], [30.93, 27.70], [29.52, 28.41], [28.03, 28.88],
    [26.51, 29.09], [25.00, 29.00]];
chueli_spot_r = [[47.00, 16.00], [48.17, 16.12], [49.17, 16.45], [50.00, 16.97], [50.67, 17.63],
    [51.17, 18.40], [51.50, 19.25], [51.67, 20.14], [51.67, 21.04], [51.50, 21.91], [51.17, 22.71],
    [50.67, 23.42], [50.00, 24.00], [49.25, 24.13], [48.53, 24.03], [47.84, 23.73], [47.22, 23.26],
    [46.68, 22.63], [46.25, 21.88], [45.94, 21.01], [45.78, 20.07], [45.78, 19.08], [45.97, 18.05],
    [46.37, 17.02]];
chueli_smile = [[31.00, 50.00], [32.67, 50.83], [34.33, 51.33], [36.00, 51.50], [37.67, 51.33],
    [39.33, 50.83], [41.00, 50.00]];

module chueli_band(w) {
    difference() {
        offset(r = w / 2) children();
        offset(r = -w / 2) children();
    }
}

module chueli_line(pts, w) {
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i]) circle(d = w);
        translate(pts[i + 1]) circle(d = w);
    }
}

module chueli_ear(x, a) { translate([x, 27]) rotate(a) scale([9, 4.5]) circle(1); }
module chueli_bell() { polygon([[28, 56], [44, 56], [46.5, 66], [25.5, 66]]); }
module chueli_head() { translate([34, 28]) offset(r = 16) square([4, 8]); }
module chueli_muzzle() { translate([36, 46]) scale([15, 9.5]) circle(1); }

module chueli() {
    ink = 2.6;
    mirror([0, 1]) translate([-36, -36]) union() {
        difference() {
            union() {
                difference() {
                    union() {
                        difference() {
                            union() {
                                chueli_band(ink) chueli_ear(12, -20);
                                chueli_band(ink) chueli_ear(60, 20);
                                chueli_line(chueli_horn_l, 3.2);
                                chueli_line(chueli_horn_r, 3.2);
                            }
                            offset(r = ink / 2) chueli_bell();
                        }
                        chueli_band(ink) chueli_bell();
                        translate([36, 67.5]) circle(2);
                    }
                    offset(r = ink / 2) chueli_head();
                }
                chueli_band(ink) chueli_head();
                polygon(chueli_spot_l);
                polygon(chueli_spot_r);
            }
            offset(r = ink / 2) chueli_muzzle();
        }
        chueli_band(ink) chueli_muzzle();
        for (x = [31, 41]) translate([x, 44]) scale([1.8, 2.4]) circle(1);
        for (x = [28, 44]) translate([x, 33]) circle(2.4);
        chueli_line(chueli_smile, 2);
    }
}

// ---------------------------------------------------------------- bezel

module bezel() {
    difference() {
        union() {
            difference() {
                body(0, bezel_d);
                cavity(wall, bezel_d + 1);
            }
            // thicker face around the screen recess
            translate([-recess / 2 - 3, wall - 0.01, win_z - recess / 2 - 3])
                cube([recess + 6, screen_t - wall + 0.01, recess + 6]);
            translate([0, bezel_d - 0.01, 0]) lip();
            // heat shelf continues through the bezel
            translate([-iw / 2, wall - 0.01, shelf_z]) cube([iw, bezel_d + lip_d - wall, wall]);
            display_pocket();
            // screw tabs that rest on the shell floor
            for (s = [-1, 1])
                translate([s * 18 - 4, bezel_d - 2, floor_t + tol]) cube([8, 10, 3]);
        }
        // 45° screen recess and window
        hull() {
            front_cut(-0.01, 0.01) translate([0, win_z]) rrect(recess, recess, 3);
            front_cut(rd, 0.01) translate([0, win_z]) rrect(win, win, 0.5);
        }
        front_cut(rd - 0.01, screen_t - rd + 1) translate([0, win_z]) rrect(win, win, 0.5);
        // floppy slot, opening into the sensor chamber to equalise pressure
        front_cut(-0.01, wall + 0.02) translate([12, 22]) rrect(18, 2.2, 1.1);
        front_cut(-0.01, 0.61) translate([12, 22]) rrect(22, 5.4, 1.4);
        // Chueli badge where the original had its logo
        front_cut(-0.01, 0.61) translate([-18, 16]) scale(0.26) chueli();
        // screw pilot holes in the tabs
        for (s = [-1, 1]) translate([s * 18, bezel_d + 4, floor_t]) cylinder(d = 2.2, h = 4);
        // clip pilot holes
        for (s = [-1, 1])
            translate([mcx, screen_t + mod_t + 0.01, mcz + s * (mod_h / 2 + tol + 2.6)])
                rotate([90, 0, 0]) cylinder(d = 1.8, h = 5);
    }
}

module lip() {
    lx = iw / 2 - tol;
    z0 = floor_t + tol;
    z1 = H - wall - tol;
    difference() {
        translate([-lx, 0, z0]) cube([2 * lx, lip_d, z1 - z0]);
        translate([-lx + lip_t, -1, z0 + lip_t])
            cube([2 * (lx - lip_t), lip_d + 2, z1 - z0 - 2 * lip_t]);
    }
}

// Corner guides keep the module centred on the window. The middle of each
// edge stays open for the flex cable that wraps around one side.
module display_pocket() {
    px = mod_w / 2 + tol;
    pz = mod_h / 2 + tol;
    for (sx_ = [-1, 1], sz_ = [-1, 1])
        translate([mcx + sx_ * px, screen_t - 0.01, mcz + sz_ * pz])
            mirror([sx_ < 0 ? 1 : 0, 0, 0]) mirror([0, 0, sz_ < 0 ? 1 : 0]) {
                translate([0, 0, -6]) cube([1.6, mod_t, 7.6]);
                translate([-6, 0, 0]) cube([7.6, mod_t, 1.6]);
            }
    // bosses for the two clips above and below the module
    for (s = [-1, 1])
        translate([mcx, screen_t - 0.01, mcz + s * (pz + 2.6)])
            rotate([-90, 0, 0]) cylinder(d = 5, h = mod_t + 0.01);
}

// ---------------------------------------------------------------- shell

module shell() {
    difference() {
        union() {
            difference() {
                body(bezel_d, D);
                cavity(bezel_d - 1, D - wall);
            }
            shelf();
            sensor_seat();
            seal_ribs();
            xiao_support();
            // block under the handle groove
            translate([-21.5, 56.5, H - wall - 4.2]) cube([43, D - wall - 56.5 + 0.01, 4.21]);
        }
        sensor_vents();
        // intake for the upper chamber; warm air leaves through the handle groove
        front_cut(D - wall - 0.01, wall + 0.02)
            for (x = [-25 : 3.2 : -5]) translate([x, 49]) rrect(1.6, 18, 0.8);
        // USB-C, with a recess for the plug overmould
        front_cut(D - wall - 0.01, wall + 0.02) translate([xiao_x, usb_z]) rrect(10, 4.6, 2);
        front_cut(D - 1.2, 1.21) translate([xiao_x, usb_z]) rrect(12.5, 7.5, 3);
        // handle groove with exhaust slots
        translate([0, 62, H]) rotate([0, 90, 0]) cylinder(r = 4, h = 40, center = true);
        for (x = [-16 : 3.2 : 16]) translate([x - 0.8, 60, H - 7.5]) cube([1.6, 4, 5]);
        // bezel screws
        for (s = [-1, 1]) translate([s * 18, bezel_d + 4, 0]) countersunk_slot(0);
        // sensor clamp screws, slotted to take up sensor tolerance
        for (s = [-1, 1]) translate([s * 16, sen_rear_y - 2, 0]) countersunk_slot(1.5);
        // rubber feet
        for (x = [-24, 24], y = [20, 62]) translate([x, y, -0.01]) cylinder(d = 8.4, h = 0.8);
        front_cut(D - 0.6, 0.61) translate([0, 66]) mirror([1, 0])
            text(back_text, size = 5, halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
        if (inside_text != "")
            front_cut(D - wall - 0.01, 0.51) translate([0, 70])
                text(inside_text, size = 3, halign = "center", valign = "center",
                     font = "Liberation Sans");
    }
}

module countersunk_slot(len) {
    hull() for (dy = [-len, len]) translate([0, dy, -1]) cylinder(d = 2.8, h = floor_t + 2);
    hull() for (dy = [-len, len]) translate([0, dy, -0.01]) cylinder(d1 = 5.6, d2 = 2.8, h = 1.4);
}

module shelf() {
    difference() {
        translate([-iw / 2, shelf_y0, shelf_z]) cube([iw, D - wall - shelf_y0 + 0.01, wall]);
        // cable pass-through from the sensor chamber; plug the gap with foam
        translate([-6, shelf_y0 - 1, shelf_z - 1]) cube([12, 7, wall + 2]);
    }
}

module sensor_seat() {
    // 1 mm rails under the sensor
    for (y = [sen_rear_y + 3, sen_face_y - 3])
        translate([-sen[0] / 2 + 2, y - 1, floor_t - 0.01]) cube([sen[0] - 4, 2, 1.01]);
    // side guides
    for (s = [-1, 1]) {
        x0 = s > 0 ? sen[0] / 2 + tol : -iw / 2;
        translate([x0, sen_rear_y, floor_t - 0.01])
            cube([iw / 2 - sen[0] / 2 - tol, sen[2] + sen_rib + 0.01, 12]);
    }
}

// Ribs press against the sensor face so the outlet cannot feed the inlets.
module seal_ribs() {
    front_cut(sen_face_y - 0.01, sen_rib + 0.02) {
        translate([sx(12.6), sz(23.1)]) difference() {
            square([12, 22.3]);
            translate([1.2, 1.2]) square([9.6, 19.9]);
        }
        translate(fan) difference() {
            circle(r = 11.8);
            circle(r = 10.6);
        }
    }
}

// Inlets: about 89 mm² (≥ 56 mm²). Outlet: about 190 mm² (≥ 148 mm²).
module sensor_vents() {
    front_cut(D - wall - 0.01, wall + 0.02) {
        for (u = [3.6, 6.6, 9.6]) translate([sx(u), sz(11.35)]) rrect(1.6, 18.5, 0.8);
        intersection() {
            translate(fan) circle(r = 10.2);
            for (i = [-3 : 3]) translate([fan.x + i * 3, fan.y]) square([1.8, 30], center = true);
        }
    }
}

// The XIAO rests on a rib between its two pin rows and is located by the
// USB-C hole. Fix it to the rib with a strip of double-sided foam tape.
module xiao_support() {
    translate([xiao_x - 4, xiao_y0 + 2, shelf_z + wall - 0.01]) cube([8, xiao_l - 4, xiao_lift + 0.01]);
}

// ---------------------------------------------------------------- small parts

module sensor_clamp() {
    difference() {
        translate([-23, 0, 0]) cube([46, 4, 10]);
        for (s = [-1, 1]) translate([s * 16, 2, -0.01]) cylinder(d = 2.2, h = 7);
    }
}

module display_clip() {
    difference() {
        cube([12, 8, 2]);
        translate([6, 5, -1]) cylinder(d = 2.3, h = 4);
    }
}

// ---------------------------------------------------------------- reference models

module sen66_model() {
    color("#2b2b2b") translate([-sen[0] / 2, sen_rear_y, floor_t + 1]) cube([sen[0], sen[2], sen[1]]);
    color("#5a5a5a") translate([fan.x, sen_face_y - 0.4, fan.y]) rotate([-90, 0, 0])
        cylinder(d = fan_d, h = 0.5);
    color("#9a9a9a") translate([sx(10.2), sen_face_y - 0.4, sz(9.8)]) cube([7, 0.5, 7]);
    color("#e0e0e0") translate([sx(6.7), sen_face_y - 0.4, sz(18.2)]) rotate([-90, 0, 0])
        cylinder(d = 6, h = 0.5);
}

module xiao_model() {
    color("#2257b8") translate([xiao_x - xiao_w / 2, xiao_y0, xiao_pcb_z]) cube([xiao_w, xiao_l, xiao_pcb]);
    color("silver") {
        translate([xiao_x - 4.45, xiao_y1 - 6.8, xiao_pcb_z + xiao_pcb]) cube([8.9, 7.4, 3.2]);
        translate([xiao_x - 6.5, xiao_y0 + 2, xiao_pcb_z + xiao_pcb]) cube([13, 10, 2.2]);
    }
}

module display_model() {
    color("#2e7d32") translate([mcx - mod_w / 2, screen_t + 1.05, mcz - mod_h / 2])
        cube([mod_w, 1.6, mod_h]);
    color("#ebe9e2") translate([-aa / 2 - 2.1, screen_t, win_z - 15.9]) cube([37.32, 1.05, 31.8]);
    // a sketch of the dashboard on the active area
    color("#151515") front_cut(screen_t - 0.05, 0.06) translate([-aa / 2, win_z - aa / 2]) {
        translate([5.5, 21.5]) scale(0.085) chueli();
        translate([13, 19.5]) square([12.5, 5.5]);
        translate([1, 17.2]) square([25.6, 0.4]);
        translate([1.5, 11]) square([10, 5]);
        translate([15.5, 11]) square([10, 5]);
        translate([1, 10.4]) square([25.6, 0.4]);
        translate([1, 5.5]) square([25.6, 4]);
        translate([1.5, 1.2]) square([5, 1.6]);
        translate([9, 1.2]) square([6, 1.6]);
        translate([21, 1.2]) square([5, 1.6]);
    }
}

// ---------------------------------------------------------------- layouts

ivory = "#efe8d8";

module assembly(ex = 0) {
    color(ivory) shell();
    color(ivory) translate([0, -ex * 40, 0]) bezel();
    translate([0, -ex * 22, 0]) display_model();
    // clips lie on the module back, their holes over the bosses
    color("#c9c2b0") for (s = [-1, 1])
        translate([mcx - 6, screen_t + mod_t - ex * 16, mcz + s * (mod_h / 2 + tol + 2.6) - s * 5])
            multmatrix([[1, 0, 0, 0], [0, 0, 1, 0], [0, s, 0, 0]]) display_clip();
    translate([0, -ex * 30, 0]) sen66_model();
    color("#c9c2b0") translate([0, sen_rear_y - 4 - ex * 36, floor_t]) sensor_clamp();
    translate([0, -ex * 12, ex * 12]) xiao_model();
}

if (part == "assembly") assembly();
else if (part == "exploded") assembly(1);
else if (part == "section") intersection() {
    assembly();
    translate([-W + section_x, -10, -10]) cube([W, D + 20, H + 20]);
}
else if (part == "shell") translate([0, 0, D]) rotate([-90, 0, 0]) shell();
else if (part == "bezel") rotate([90, 0, 0]) bezel();
else if (part == "sensor_clamp") sensor_clamp();
else if (part == "display_clip") display_clip();
