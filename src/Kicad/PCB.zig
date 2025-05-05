const std = @import("std");
const Sexp = @import("../Sexp.zig");

fn List(comptime T: type) type {
    return []const T;
}
const String = List(u8);
const YesNo = bool;
const MicroMeter = i32;
const Point = struct { x: MicroMeter, y: MicroMeter }; //
const UUID = struct { data: [16]u8 };
pub const PCB = struct {
    version: String,
    paper: enum { A0, A1, A2, A3, A4, A5, A6 },
    layers: List(Layer),
    options: PCBOptions,
    nets: List(Net),
    footprints: List(Footprint),
};

pub const Layer = struct {
    idx: u16,
    name: String,
    layerType: enum { signal, power, mixed, jumper, user },
    userName: String,
};

pub const PCBOptions = struct {
    pad_to_mask_clearance: i32,
    allow_soldermask_bridges_in_footprints: YesNo,
    grid_origin: Point,
    //More TODO
};

pub const Net = struct {
    id: u64,
    name: String,
};

pub const Footprint = struct {
    layer: String,
    uuid: UUID,
    pos: Point,
    descr: String,
    tags: List(String),
    properties: List(Property),
    attr: enum { through_hole, smd },
    pads: List(Pad),
    draw: List(Draw),
    vias: List(Via),
    segment: List(Segment),
    pub const Draw = union(enum) {
        line: struct {},
        text: struct {},
    };
    pub const Property = struct {};
    pub const Pad = struct {
        id: String,
        pos: Point,
        size: Point,
        drill: ?MicroMeter,
        layers: List(String),
        remove_unused_layers: YesNo,
        net: Net,
    };
    pub const Via = struct {
        pos: Point,
        size: MicroMeter,
        drill: Point,
        layers: List(Layer),
        net: Net,
        uuid: UUID,
    };
    pub const Segment = struct {
        start: Point,
        end: Point,
        width: MicroMeter,
        net: Net,
        uuid: UUID,
    };
};

test {
    const test_file = @embedFile("../KeyBoard.kicad_pcb");
    const file = try Sexp.decodeToMap(test_file, std.testing.allocator);
    defer file.deinit();
}
