# Tutorial

Getty's goal is to help you write (de)serializers that are robust,
customizable, and performant.

To give you an example, the following JSON serializer supports string values
and any _Getty Sequence_ value, which includes arrays, slices, `std.ArrayList`,
`std.TailQueue`, and more.

```zig title="Zig code"
const std = @import("std");
const getty = @import("getty");

const ally = std.heap.page_allocator;

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        Context,
        Ok,
        Error,
        null,
        null,
        null,
        Seq,
        null,
        .{
            .serializeString = serializeString,
            .serializeSeq = serializeSeq,
        },
    );

    const Context = @This();
    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeString(_: Context, value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeSeq(_: Context, _: ?usize) Error!Seq {
        std.debug.print("[", .{});
        return Seq{};
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        Context,
        Ok,
        Error,
        .{
            .serializeElement = serializeElement,
            .end = end,
        },
    );

    const Context = *@This();
    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeElement(c: Context, value: anytype) Error!void {
        switch (c.first) {
            true => c.first = false,
            false => std.debug.print(",", .{}),
        }

        const s = (Serializer{}).serializer();
        try getty.serialize(null, value, s);
    }

    fn end(_: Context) Error!Ok {
        std.debug.print("]", .{});
    }
};

pub fn main() !void {
    var list = std.ArrayList([]const u8).init(ally);
    defer list.deinit();

    try list.append("a");
    try list.append("b");
    try list.append("c");

    const s = (Serializer{}).serializer();
    try getty.serialize(null, list, s);
}
```

```console title="Shell session"
$ zig build run
["a","b","c"]
```

In this tutorial, we'll:

- Build up to and extend the `Serializer` implementation above.
- Write a JSON deserializer.
- Learn how to customize the (de)serialization process in Getty.
