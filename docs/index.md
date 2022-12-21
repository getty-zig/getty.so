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

The following example defines a JSON serializer that supports _Booleans_ and _Sequences_.

```zig title="Zig code"
const std = @import("std");
const getty = @import("getty");

const allocator = std.heap.page_allocator;

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Serializer,
        Ok,
        Error,
        null,
        null,
        null,
        Seq,
        null,
        .{
            .serializeBool = serializeBool,
            .serializeSeq = serializeSeq,
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: Serializer, value: bool) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: Serializer, _: ?usize) Error!Seq {
        std.debug.print("[", .{});
        return Seq{};
    }

    const Seq = struct {
        first: bool = true,

        pub usingnamespace getty.ser.Seq(
            *Seq,
            Ok,
            Error,
            .{
                .serializeElement = serializeElement,
                .end = end,
            },
        );

        fn serializeElement(self: *Seq, value: anytype) Error!void {
            switch (self.first) {
                true => self.first = false,
                false => std.debug.print(", ", .{}),
            }

            try getty.serialize(value, (Serializer{}).serializer());
        }

        fn end(_: *Seq) Error!Ok {
            std.debug.print("]\n", .{});
        }
    };
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    // Primitives
    try getty.serialize(.{ true, false }, s);
    try getty.serialize([_]bool{ true, false }, s);
    try getty.serialize(&&&[_]bool{ true, false }, s);
    try getty.serialize(@Vector(2, bool){ true, false }, s);

    // std.ArrayList
    var list = std.ArrayList(bool).init(allocator);
    defer list.deinit();
    try list.appendSlice(&.{ true, false });
    try getty.serialize(list, s);

    // std.BoundedArray
    var arr = try std.BoundedArray(bool, 2).fromSlice(&.{ true, false });
    try getty.serialize(arr, s);
}
```

```console title="Shell session"
$ zig build run
[true, false]
[true, false]
[true, false]
[true, false]
[true, false]
[true, false]
```
