const std = @import("std");
const mkeed_pcb = @import("mkeed_pcb");

fn create(ctx: *mkeed_pcb.Context) !mkeed_pcb.Project {
    const project = ctx.new_project();
    const rows = project.new_bus("row");
    const cols = prokect.new_bus("col");
    for (0..9) |c| {
        for (0..9) |r| {
            const sw = project.new_symbol("sw_push");
            const d = project.new_symbol("diode");
            project.connect_net(&.{
                sw.pin("2"),
                d.pin("1"),
            });
            rows.wire(c).connect(sw.pin("1"));
            cols.wire(r).connect(d.pin("2"));
        }
    }
}
