# Tutorial

Most Zig (de)serializers are functions that take a value, switch on its type,
and (de)serialize based on the resulting type information.
[`std.json`](https://ziglang.org/documentation/master/std/#A;std:json) works
like this, and it's generally a nice way to show off the capabilities of Zig as
a programming language. Unfortunately, it's also quite brittle, inflexible, and
usually ends up being a lot of unnecessary work.

The goal of Getty is to help you avoid all of that and reduce the amount of
code you need to make a (de)serializer that is customizable, performant, and
able to support a wide variety of data types!

As an example, the following code defines a JSON serializer that supports
scalar and string values. At around 60 lines, `Serializer` is a fully
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

In this tutorial, we'll slowly build up to above implementation so that by the
end of it all you'll understand everything there is to know about it. We'll
also be extending `Serializer` to support non-scalar types, such as `struct{ x:
i32 }` and `std.ArrayList(i32)`. And to cap things off, we'll write ourselves a
JSON deserializer and go over how custom (de)serialization works in Getty.

Let's get started!