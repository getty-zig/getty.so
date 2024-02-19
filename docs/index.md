---
hide:
  - navigation
  - toc
---

# Getty

Getty is a framework for building __robust__, __optimal__, and __reusable__ (de)serializers in Zig.

<!--<br>-->

<!--<figure markdown>-->
  <!--![Getty](/assets/images/getty-solid.svg){ width=370 }-->
<!--</figure>-->

## Goals

- Simplify (de)serializer implementations.
- Enable granular customization of the (de)serialization process.
- Avoid as much performance overhead as possible.

## Features

- Compile-time (de)serialization.
- Out-of-the-box support for standard library types.
- Local customization of (de)serialization logic for existing and remote types.

## Quick Start

```zig title="Zig code"
const std = @import("std");
const json = @import("json");

const ally = std.heap.page_allocator;

pub fn main() !void {
    const Point = struct { x: i32, y: i32 };
    const point = Point{ .x = 1, .y = 2 };

    // Serialize a Point value into JSON.
    const slice = try json.toSlice(ally, point);
    defer ally.free(slice);

    // Deserialize JSON data into a Point.
    const result = try json.fromSlice(ally, Point, slice);
    defer result.deinit();

    // Print results.
    std.debug.print("{s}\n", .{slice});
    std.debug.print("{}\n", .{result.value});
}
```

```console title="Shell session"
$ zig build run
{"x":1,"y":2}
main.main.Point{ .x = 1, .y = 2 }
```
