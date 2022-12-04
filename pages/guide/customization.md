---
title: Customization
category: Guide
layout: default
permalink: /guide/customization/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Customization

So far, Getty has taken care of all of the little (de)serialization details for us behind the scenes. But sometimes, you just need to do things yourself. That's where Getty's customization features come in.

Getty allows both users and (de)serializers to customize the (de)serialization process for types that you've defined yourself, as well as types that you didn't define (such as those in the standard library). Moreover, the customization enabled by Getty can be used in a local manner. That is, you can serialize a `bool` value as a _String_ in one function and as an _Integer_ in another, all without having to convert the value to a new or intermediate type.

## Overview

Customization in Getty revolves around [Blocks and Tuples (BT)](/blocks-and-tuples). I encourage you to take a few minutes to read up on them before continuing on. In any case, once you've defined a BT, you can pass it on to Getty via the [`getty.Serializer`](https://docs.getty.so/#root;Serializer) or [`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) interfaces.

### Out-of-Band Customization

Here, we define and use a block that serializes `bool` values as Getty Integers.

{% label Zig code %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

const block = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    pub fn serialize(value: anytype, serializer: anytype) !@TypeOf(serializer).Ok {
        const v: i32 = if (value) 1 else 0;
        return try serializer.serializeInt(v);
    }
};

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        block,
        null,
        null,
        null,
        null,
        .{ .serializeInt = serializeInt },
    );

    const Ok = void;
    const Error = error{};

    fn serializeInt(_: @This(), value: anytype) Error!Ok {
        std.debug.print("{}", .{value});
    }
};

pub fn main() anyerror!void {
    const s = (Serializer{}).serializer();

    try getty.serialize(true, s);
    std.debug.print("\n", .{});

    try getty.serialize(false, s);
    std.debug.print("\n", .{});
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
1
0
{% endhighlight %}
{% endlabel %}

And here, we make `Serializer` generic over a BT to make customization even easier for us.

{% label Zig code %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

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
            std.debug.print("{}", .{value});
        }

        fn serializeString(_: @This(), value: anytype) Error!Ok {
            std.debug.print("\"{s}\"", .{value});
        }
    };
}

pub fn main() anyerror!void {
    try getty.serialize(true, (Serializer(int_block){}).serializer());
    std.debug.print("\n", .{});

    try getty.serialize(true, (Serializer(string_block){}).serializer());
    std.debug.print("\n", .{});
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
1
"true"
{% endhighlight %}
{% endlabel %}

### In-Band Customization

Out-of-band customization has its uses, such as when you want to customize a type that you didn't define. However, there's a more convenient way to do things for `struct`, `enum`, and `union` types that you did define yourself.

If you define a BT within a `struct`, `enum`, or `union`, Getty will automatically process it without you having to pass it in directly through a (de)serializer. Just make sure the BT is public and named either `@"getty.sbt"` or `@"getty.dbt"` (former for serialization, latter for deserialization).

For example, the following code defines a serialization block for `Point` within the actual type itself.

{% label src/main.zig %}
{% highlight zig %}
{% raw %}
const std = @import("std");
const getty = @import("getty");

const Point = struct {
    x: i32,
    y: i32,

    pub const @"getty.sbt" = struct {
        pub fn is(comptime T: type) bool {
            return T == Point;
        }

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
        try getty.serialize(key, (Serializer{}).serializer());

        // Serialize value.
        std.debug.print(": ", .{});
        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) Error!Ok {
        std.debug.print("}}", .{});
    }
};

pub fn main() anyerror!void {
    const v = Point{ .x = 1, .y = 2 };
    const s = (Serializer{}).serializer();

    try getty.serialize(v, s);
    std.debug.print("\n", .{});
}
{% endraw %}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
{"X": 1}
{% endhighlight %}
{% endlabel %}
