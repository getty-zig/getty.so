# Getty

Getty is a framework for building __robust__, __optimal__, and __reusable__ (de)serializers in Zig.

## Goals

- Minimize the amount of code required for (de)serializer implementations.
- Enable granular customization of the (de)serialization process.
- Avoid as much performance overhead as possible.

## Features

- Compile-time (de)serialization.
- Out-of-the-box support for a wide variety of standard library types.
- Local customization of (de)serialization logic for both existing and remote types.
- Data model abstractions that serve as simple and generic baselines for (de)serializers.

## Quick Start

!!! info ""

    The following example uses the [Getty
    JSON](https://github.com/getty-zig/json) library for (de)serialization.

```zig title="Zig code"
const std = @import("std");
const json = @import("json");

const allocator = std.heap.page_allocator;

const Point = struct {
    x: i32,
    y: i32,
};

pub fn main() anyerror!void {
    const serialized = try json.toSlice(allocator, Point{ .x = 1, .y = 2 });
    defer allocator.free(serialized);

    const deserialized = try json.fromSlice(null, Point, serialized);

    std.debug.print("{s}\n", .{serialized});
    std.debug.print("{}\n", .{deserialized});
}
```

```console title="Shell session"
$ zig build run
{"x":1,"y":2}
main.Point{ .x = 1, .y = 2 }
```
