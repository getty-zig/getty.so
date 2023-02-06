# Tutorial

In short, Getty aims to reduce the amount of code needed to write
(de)serializers that are robust, customizable, performant, and able to support
a wide variety of data types.

As an example, the following code defines a JSON serializer that supports
scalar and string values. At around 60 lines, `Serializer` is a complete
serializer capable of converting values of type `bool`, `i32`, `f128`, `enum{
foo }`, `*const [3]u8`, `[]u8`, `?*void`, and more into JSON!

```zig title="Zig code"
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        null,
        null,
        null,
        .{
            .serializeBool = serializeBool,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNothing,
            .serializeString = serializeString,
            .serializeVoid = serializeNothing,
            .serializeEnum = serializeEnum,
            .serializeSome = serializeSome,
        },
    );

    const Ok = void;
    const Error = getty.ser.Error;

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeNothing(_: @This()) Error!Ok {
        std.debug.print("null\n", .{});
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"\n", .{value});
    }

    fn serializeEnum(s: @This(), value: anytype) Error!Ok {
        try s.serializeString(@tagName(value));
    }

    fn serializeSome(s: @This(), value: anytype) Error!Ok {
        try getty.serialize(null, value, s.serializer());
    }
};

pub fn main() !void {
    const s = (Serializer{}).serializer();

    try getty.serialize(null, "Getty", s);
}
```

```console title="Shell session"
$ zig build run
"Getty"
```

In this tutorial, we'll:

- Build up to the above `Serializer` implementation.
- Extend `Serializer` to support non-scalar types, such as `std.ArrayList(i32)`.
- Write a JSON deserializer.
- Explore how custom (de)serialization works in Getty.
