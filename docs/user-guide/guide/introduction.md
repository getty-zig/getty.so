# Introduction

The goal of Getty is to make writing (de)serializers in Zig easier for you.

As an example, the following code defines a JSON serializer that supports
scalar and string values. At around 50 lines, `Serializer` is a fully
functional serializer capable of converting values of type `bool`, `i32`,
`enum{ foo }`, `[]u8`, `*const [5]u8`, `?void`, and more into JSON!

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

In this guide, we'll slowly build up to `Serializer` so that by the end of it
all you'll understand everything there is to know about it. We'll also be
extending the serializer to support non-scalar types, such as `[5][5]i32`,
`struct{ x: i32 }` and `std.ArrayList(i32)`. And, to cap things off, we'll
write ourselves a JSON deserializer and cover how custom (de)serialization
works in Getty.

Let's get started!
