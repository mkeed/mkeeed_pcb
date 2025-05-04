const std = @import("std");

const SymbolIter = struct {
    data: []const u8,
    idx: usize = 0,
    pub const Symbol = union(enum) {
        startObject: []const u8,
        closeObject: void,
        value: []const u8,
        pub fn format(self: Symbol, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            switch (self) {
                .startObject => |o| try std.fmt.format(writer, "[open:{s}]", .{o}),
                .closeObject => try std.fmt.format(writer, "[close]", .{}),
                .value => |o| try std.fmt.format(writer, "({s})", .{o}),
            }
        }
    };
    fn nextCh(self: *SymbolIter) ?u8 {
        if (self.idx >= self.data.len) return null;
        defer self.idx += 1;
        return self.data[self.idx];
    }
    fn peekCh(self: *SymbolIter) ?u8 {
        if (self.idx >= self.data.len) return null;
        return self.data[self.idx];
    }
    pub fn next(self: *SymbolIter) !?Symbol {
        errdefer std.log.err("next[{s}]", .{self.data[self.idx..][0..50]});
        while (self.nextCh()) |ch| {
            switch (ch) {
                '(' => {
                    const start = self.idx;
                    while (self.peekCh()) |c| {
                        switch (c) {
                            'a'...'z', 'A'...'Z', '_' => {
                                _ = self.nextCh();
                            },
                            ' ', '\t', '\n' => {
                                _ = self.nextCh();
                                break;
                            },
                            ')' => break,
                            else => {
                                std.log.err("badCh:[{c}:{}]", .{ c, c });
                                return error.UnkownError;
                            },
                        }
                    }
                    return .{ .startObject = self.data[start .. self.idx - 1] };
                },
                ')' => return .closeObject,
                ' ', '\t', '\n' => {},
                '"' => {
                    const start = self.idx;
                    while (self.nextCh()) |c| {
                        switch (c) {
                            '\\' => {
                                if (self.peekCh()) |p| {
                                    if (p == '"') _ = self.nextCh();
                                } else {
                                    return error.UnexpectedEnd;
                                }
                            },
                            '"' => break,
                            else => {},
                        }
                    }
                    return .{ .value = self.data[start .. self.idx - 1] };
                },
                else => return error.UnkownError,
            }
        }
        return null;
    }
};

const ValMap = struct {
    alloc: std.mem.Allocator,
    objects: std.ArrayList(Object),
    pub const Object = struct {
        parent: ?ObjectIdx,
        name: []const u8,
        children: std.ArrayList(Child),
    };
    pub const ObjectIdx = struct { idx: usize };
    pub const ValueIdx = struct { idx: usize };
    pub const Child = union(enum) {
        value: []const u8,
        object: ObjectIdx,
    };
    pub fn init(alloc: std.mem.Allocator) ValMap {
        return .{
            .alloc = alloc,
            .objects = std.ArrayList(Object).init(alloc),
        };
    }
    pub fn deinit(self: ValMap) void {
        for (self.objects.items) |item| item.children.deinit();
        self.objects.deinit();
    }

    pub fn create(self: *ValMap, name: []const u8, parent: ?ObjectIdx) !ObjectIdx {
        const ret = ObjectIdx{ .idx = self.objects.items.len };
        const object = Object{ .parent = parent, .name = name, .children = std.ArrayList(Child).init(self.alloc) };
        try self.objects.append(object);

        return ret;
    }
    pub fn get_parent(self: ValMap, obj: ObjectIdx) ?ObjectIdx {
        if (obj.idx >= self.objects.items.len) return null;
        return self.objects.items[obj.idx].parent;
    }
    pub fn get(self: ValMap, obj: ObjectIdx) !Object {
        if (obj.idx >= self.objects.items.len) return error.BadObject;
        return self.objects.items[obj.idx];
    }
    pub fn children(self: ValMap, obj: ObjectIdx) ![]const Child {
        return (try self.get(obj)).children.items;
    }
    pub fn addValue(self: *ValMap, obj: ObjectIdx, val: []const u8) !void {
        if (obj.idx >= self.objects.items.len) return;
        try self.objects.items[obj.idx].children.append(.{ .value = val });
    }
    pub fn addObject(self: *ValMap, obj: ObjectIdx, child: ObjectIdx) !void {
        if (obj.idx >= self.objects.items.len) return;
        try self.objects.items[obj.idx].children.append(.{ .object = child });
    }

    pub fn iter(self: ValMap, obj: ObjectIdx, items: []const []const u8) !void {
        if (items.len == 0) return;
        //std.log.err("check: {s}", .{items[0]});
        for (try self.children(obj)) |child| {
            //std.log.err("{}", .{child});
            switch (child) {
                .value => {},
                .object => |s_obj| {
                    const o = try self.get(s_obj);
                    //std.log.err("check:{s} == {s}", .{ items[0], o.name });
                    if (std.mem.eql(u8, items[0], o.name)) {
                        //std.log.err("found:{s}", .{items[0]});
                        if (items.len == 1) {
                            //std.log.err("{s}", .{o.name});
                        } else {
                            try self.iter(s_obj, items[1..]);
                        }
                    }
                },
            }
        }
    }
    pub fn print(self: ValMap, obj: ObjectIdx, count: usize, writer: anytype) !void {
        if (count == 5) return;
        const object = try self.get(obj);
        try writer.writeByteNTimes(' ', count);
        try std.fmt.format(writer, "({s})\n", .{object.name});
        for (try self.children(obj)) |child| {
            switch (child) {
                .value => |v| {
                    try writer.writeByteNTimes(' ', count);
                    try std.fmt.format(writer, "-{s}\n", .{v});
                },
                .object => |o| {
                    try self.print(o, count + 1, writer);
                },
            }
        }
    }
    pub fn format(self: ValMap, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try self.print(.{ .idx = 0 }, 0, writer);
    }
};

pub fn decodeToMap(data: []const u8, alloc: std.mem.Allocator) !ValMap {
    var ret = ValMap.init(alloc);
    errdefer ret.deinit();
    var iter = SymbolIter{ .data = data };
    var cur = try ret.create("root", null);
    var count: usize = 0;
    while (try iter.next()) |n| {
        defer count += 1;
        switch (n) {
            .startObject => |o| {
                const obj = try ret.create(o, cur);
                try ret.addObject(cur, obj);
                cur = obj;
            },
            .closeObject => {
                if (ret.get_parent(cur)) |p| {
                    cur = p;
                } else {
                    return error.TooManyCloses;
                }
            },
            .value => |v| try ret.addValue(cur, v),
        }
    }

    return ret;
}

test {
    const file = @embedFile("thumbboard.net");

    const net_file = try decodeToMap(file, std.testing.allocator);
    defer net_file.deinit();

    try net_file.iter(.{ .idx = 0 }, &.{ "export", "design", "sheet", "title_block", "comment" });
    //std.log.err("{}", .{net_file});
}
