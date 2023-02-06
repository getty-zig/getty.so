
# Customization

So far, Getty has taken care of all of the little (de)serialization details for
us behind the scenes. But sometimes, you need more control. That's
where Getty's customization features come in.

Getty allows both users and (de)serializers to customize the (de)serialization
process for types that you've defined yourself, as well as for types that you
didn't define such as those in the standard library. Moreover, the
customization enabled by Getty can be used in a local manner. That is, you can
serialize a `bool` value as a _String_ in one function and as an
_Integer_ in another, all without having to convert the value to a new or
intermediate type.

Customization in Getty revolves around [Blocks and
Tuples](/user-guide/design/blocks-and-tuples), which can be passed to
Getty via the `*_sbt` and `*_dbt` parameters of the
[`getty.Serializer`](https://docs.getty.so/#A;std:Serializer) or
[`getty.Deserializer`](https://docs.getty.so/#A;std:Deserializer) interfaces.

### Out-of-Band Customization

Here, we define a serialization block that serializes `bool` values as
_Integers_.

```zig title="Zig code"
const std = @import("std");
const getty = @import("getty");

// (1)!
const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        block, // (2)!
        null,
        null,
        null,
        null,
        .{ .serializeInt = serializeInt },
    );

    const Ok = void;
    const Error = error{};

    fn serializeInt(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}\n", .{value});
    }
};

const block = struct {
    // (3)!
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // (4)!
    pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
        const v: i32 = if (value) 1 else 0;
        return try serializer.serializeInt(v);
    }
};

pub fn main() !void {
    const s = (Serializer{}).serializer();

    try getty.serialize(null, true, s);
    try getty.serialize(null, false, s);
}
```

1.  This serializer only knows how to serialize _Integers_.

2.  With `block` being passed to Getty, `bool` values will now be
    serialized into Getty's data model as _Integers_, which, of course, is a
    type that `Serializer` knows how to serialize.

3.  `is` specifies which types `block` applies to.

4.  `serialize` specifies how to serialize values relevant to `block`.

    In this case, we serialize the incoming `bool` value as an _Integer_
    before passing it on to the serializer.

```console title="Shell session"
$ zig build run
1
0
```

We can also make `Serializer` generic over a BT to make customization even
easier for users.

```zig title="Zig code"
const std = @import("std");
const getty = @import("getty");

fn Serializer(comptime user_sbt: anytype) type {
    return struct {
        pub usingnamespace getty.Serializer(
            @This(),
            Ok,
            Error,
            user_sbt,
            null,
            null,
            null,
            null,
            .{
                .serializeInt = serializeInt,
                .serializeString = serializeString,
            },
        );

        const Ok = void;
        const Error = error{};

        fn serializeInt(_: @This(), value: anytype) Error!Ok {
            std.debug.print("{}\n", .{value});
        }

        fn serializeString(_: @This(), value: anytype) Error!Ok {
            std.debug.print("\"{s}\"\n", .{value});
        }
    };
}

const int_block = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
        const v: i32 = if (value) 1 else 0;
        return try serializer.serializeInt(v);
    }
};

const string_block = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
        const v = if (value) "true" else "false";
        return try serializer.serializeString(v);
    }
};

pub fn main() !void {
    // Integer
    {
        const s = (Serializer(int_block){}).serializer();

        try getty.serialize(null, true, s);
        try getty.serialize(null, false, s);
    }

    // String
    {
        const s = (Serializer(string_block){}).serializer();

        try getty.serialize(null, true, s);
        try getty.serialize(null, false, s);
    }
}
```

```console title="Shell session"
$ zig build run
1
0
"true"
"false"
```

### In-Band Customization

Out-of-band customization has its uses, such as when you want to customize a
type that you didn't define. However, there's a more convenient way to do
things for `struct` and `union` types that you did define yourself.

If you define a BT _within_ a `struct` or `union`, Getty will automatically
process it without you having to pass it in directly through a (de)serializer.
Just make sure the BT is public and named either `@"getty.sb"` or `@"getty.db"`
(`sb` for serialization, `db` for deserialization).

```zig title="<code>src/main.zig</code>"
const std = @import("std");
const getty = @import("getty");

const Point = struct {
    x: i32,
    y: i32,

    pub const @"getty.sb" = struct {
        pub const attributes = .{
            .x = .{ .rename = "X" },
            .y = .{ .skip = true },
        };
    };
};

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        null,
        null,
        null,
        null,
        Struct,
        .{
            .serializeInt = serializeInt,
            .serializeString = serializeString,
            .serializeStruct = serializeStruct,
        },
    );

    const Ok = void;
    const Error = error{};

    fn serializeInt(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeString(_: @This(), value: anytype) Error!Ok {
        std.debug.print("\"{s}\"", .{value});
    }

    fn serializeStruct(_: @This(), comptime _: []const u8, _: usize) Error!Struct {
        std.debug.print("{{", .{});

        return Struct{};
    }
};

const Struct = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Structure(
        *@This(),
        Ok,
        Error,
        .{
            .serializeField = serializeField,
            .end = end,
        },
    );

    const Ok = Serializer.Ok;
    const Error = Serializer.Error;

    fn serializeField(self: *@This(), comptime key: []const u8, value: anytype) Error!void {
        // Serialize key.
        switch (self.first) {
            true => self.first = false,
            false => std.debug.print(", ", .{}),
        }
        try getty.serialize(null, key, (Serializer{}).serializer());

        // Serialize value.
        std.debug.print(": ", .{});
        try getty.serialize(null, value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) Error!Ok {
        std.debug.print("}}\n", .{});
    }
};

pub fn main() !void {
    const v = Point{ .x = 1, .y = 2 };
    const s = (Serializer{}).serializer();

    try getty.serialize(null, v, s);
}
```

```console title="Shell session"
$ zig build run
{"X": 1}
```
