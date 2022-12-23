# Introduction

The goal of Getty is to make writing (de)serializers in Zig easier for you.

You can see some of that in the JSON serializer below, which supports scalar
and string values. At around 50 lines of code, `Serializer` is a fully
functional serializer capable of converting values of type `#!zig bool`, `#!zig
i32`, `#!zig enum{ foo }`, `#!zig []u8`, `#!zig *const [5]u8`, `#!zig ?void`,
and more into
JSON!

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
            .serializeEnum = serializeEnum,
            .serializeFloat = serializeNumber,
            .serializeInt = serializeNumber,
            .serializeNull = serializeNull,
            .serializeSome = serializeSome,
            .serializeString = serializeString,
            .serializeVoid = serializeNull,
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeEnum(s: @This(), value: anytype) Error!Ok {
        try s.serializeString(@tagName(value));
    }

    fn serializeNull(_: @This()) Error!Ok {
        std.debug.print("null\n", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeSome(s: @This(), value: anytype) Error!Ok {
        try getty.serialize(value, s.serializer());
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"\n", .{value});
    }
};

pub fn main() !void {
    const s = (Serializer{}).serializer();

    try getty.serialize("Getty", s);
}
```


```console title="Shell session"
$ zig build run
"Getty"
```

In this guide, we'll slowly build up to the above `Serializer` implementation
so that by the end of it all, you'll understand everything there is to know
about serialization in Getty. We'll also be extending `Serializer` to
support more complex types, such as `#!zig [5][5]i32`, `#!zig struct{ x: i32 }`
and `#!zig std.ArrayList(i32)`. And to cap things off, we'll write a JSON
deserializer and go over how custom (de)serialization works in Getty.

Let's get started!
