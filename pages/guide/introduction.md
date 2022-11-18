---
title: Introduction
category: Guide
layout: default
permalink: /guide/introduction/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Introduction

Getty is a framework for building serializers and deserializers in Zig.

As an example, the following code shows a JSON serializer that supports scalar and string values. At around 50 lines of code, `Serializer` is a fully functional serializer capable of converting values of type `bool`, `i32`, `f64`, `enum{ foo }`, `[]u8`, `*const [5]u8`, `?void`, and more into JSON!

{% label Zig code %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        getty.TODO,
        getty.TODO,
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

    try getty.serialize("Getty!", s);
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight sh %}
$ zig build run
"Getty!"
{% endhighlight %}
{% endlabel %}

In this guide, we'll slowly build up to the above `Serializer` implementation so that by the end of it, you'll understand all there is to know about Getty serializers. Additionally, we'll extend `Serializer` to support more complex types such as `struct{ x: i32 }` and `std.ArrayList(i32)`. We'll also make a JSON deserializer afterwards and go over how custom (de)serialization works in Getty.

So, without further ado, let's get started!
