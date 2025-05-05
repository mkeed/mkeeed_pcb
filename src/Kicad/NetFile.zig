const std = @import("std");
const Sexp = @import("../Sexp.zig");
pub const Reference = []const u8;
pub const PinReference = []const u8;
pub const Export = struct {
    version: enum { E },
    design: Design,
    //components: []comp,
    //libpars: []LibPart,
    //libraries: []Library,
    nets: []Net,
};

pub const Net = struct {
    code: isize,
    name: String,
    nodes: []Node,
};

pub const Node = struct {
    ref: Reference,
    pin: PinReference,
    pinFunction: String,
    pinType: PinType,
};

pub const PinType = enum {
    input,
    output,
    bidirectional,
    tri_state,
    passive,
    free,
    unspecified,
    power_in,
    power_out,
    open_collector,
    open_emitter,
    unconnected,
};

pub const Sheet = struct {
    number: isize,
    name: String,
    tstamps: String,
};

pub const Design = struct {
    source: String,
    date: Date,
    tool: String,
    sheet: Sheet,
};

test {
    const file = @embedFile("../thumbboard.net");

    const net_file = try Sexp.decodeToMap(file, std.testing.allocator);
    defer net_file.deinit();

    try net_file.iter(.{ .idx = 0 }, &.{ "export", "design", "sheet", "title_block", "comment" });
}

pub const String = []const u8;
pub const Date = i64;
