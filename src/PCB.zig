const std = @import("std");

const Colour = []const u8;

const DrawInfo = struct {
    layers: []LayerDrawInfo,
    const LayerDrawInfo = struct {
        name: []const u8,
        id: u32,
        colour: Colour,
    };
};

pub const Segment = union(enum) {
    trace: Trace,
    via: Via,
};
