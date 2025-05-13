const std = @import("std");
const zap = @import("zap");

fn formatTimestamp(allocator: std.mem.Allocator, timestamp: i64) ![]u8 {
    const epoch = std.time.epoch.EpochSeconds{ .secs = @intCast(timestamp) };
    const day = epoch.getDaySeconds();
    const epoch_day = epoch.getEpochDay();
    const year_and_day = epoch_day.calculateYearDay();
    const month_and_day = year_and_day.calculateMonthDay();

    const hours = day.getHoursIntoDay();
    const minutes = day.getMinutesIntoHour();
    const seconds = day.getSecondsIntoMinute();

    return std.fmt.allocPrint(
        allocator,
        "Request Time: {d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}",
        .{
            year_and_day.year,
            @intFromEnum(month_and_day.month) + 1, 
	    month_and_day.day_index + 1,    
            hours,
            minutes,
            seconds,
        }
    );
}


fn on_request_verbose(r: zap.Request) void {
    const user_agent = r.getHeader("user-agent") orelse "Unknown Device";

    const now = std.time.timestamp();

    const datetime = formatTimestamp(std.heap.page_allocator, now) catch "Failed to format time";


    defer std.heap.page_allocator.free(datetime);


    const html_body = std.fmt.allocPrint(
        std.heap.page_allocator,
        "<html><body><h1>hello hello, yes thats Zig!</h1><br>" ++
        "<a href='https://ziglang.org/'>Ziglang</a> | " ++
        "<a href='https://github.com/zigzap/zap'>Zap</a>" ++
        "<hr>" ++
        "<footer>" ++
        "<p>Device Info: {s}</p>" ++
        "<p>{s}</p>" ++
        "</footer></body></html>",
        .{user_agent, datetime}
    ) catch "<html><body><h1>Error generating page</h1></body></html>";

    defer std.heap.page_allocator.free(html_body);

    // HTML javobini yuborish
    r.sendBody(html_body) catch |err| {
        std.debug.print("Error sending body: {}\n", .{err});
    };


}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request_verbose, 
        .log = true,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
