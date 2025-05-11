const std = @import("std");

fn List(comptime T: type) type {
    return struct { items: []const T };
}

const String = List(u8);
const Name = String;

pub const Import = struct {
    name: String,
};

pub const Symbol = struct {};

pub const Net = union(enum) {
    wire: Wire,
    bus: Bus,
};

pub const Bus = struct {
    name: Name,
    wires: List(Wire),
};

pub const Wire = struct {
    name: Name,
};

pub const Schematic = struct {
    symbols: List(Symbol),
    nets: List(Net),
};

pub const Layout = struct {};

pub const Project = struct {
    schematic: Schematic,
    layout: Layout,
    imports: List(Import),
};

test {
    _ = Project;
}
