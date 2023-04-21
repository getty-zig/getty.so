# Getty

Getty is a framework for building __robust__, __optimal__, and __reusable__ (de)serializers in Zig.

<br>

<figure markdown>
  ![Getty](/assets/images/getty-solid.svg){ width=370 }
</figure>

## Goals

- Simplify (de)serializer implementations.
- Enable granular customization of the (de)serialization process.
- Avoid as much performance overhead as possible.

## Features

- Compile-time (de)serialization.
- Out-of-the-box support for a wide variety of standard library types.
- Local customization of (de)serialization logic for existing _and_ remote types.

## Quick Start

The following code uses the [Getty JSON](https://github.com/getty-zig/json) library to demonstrate how (de)serialization works.

```zig title="Zig code"
const std = @import("std");
const json = @import("json");

const allocator = std.heap.page_allocator;

const Point = struct {
    x: i32,
    y: i32,
};

pub fn main() !void {
    const value = Point{ .x = 1, .y = 2 };

    // Serialize a Point value into JSON.
    const serialized = try json.toSlice(allocator, value);
    defer allocator.free(serialized);

    // Deserialize JSON data into a Point.
    const deserialized = try json.fromSlice(null, Point, serialized);

    // Print results.
    std.debug.print("{s}\n", .{serialized});
    std.debug.print("{}\n", .{deserialized});
}
```

```console title="Shell session"
$ zig build run
{"x":1,"y":2}
main.Point{ .x = 1, .y = 2 }
```
