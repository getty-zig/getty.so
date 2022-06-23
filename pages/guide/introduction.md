---
title: Introduction
category: Guide
layout: default
permalink: /guide/introduction/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Introduction

Getty is a framework for building serializers and deserializers in Zig.

For example, the following code shows a JSON serializer that only supports scalar and string values. At around 50 lines of code, `Serializer` is a fully functional serializer capable of converting values of type `bool`, `i32`, `f64`, `enum{ foo, bar }`, `[]u8`, `*const [5]u8`, `?void`, and more!

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
        serializeBool,
        serializeEnum,
        serializeNumber,
        serializeNumber,
        undefined,
        serializeNull,
        undefined,
        serializeSome,
        serializeString,
        undefined,
        serializeNull,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) !Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeEnum(self: @This(), value: anytype) !Ok {
        try self.serializeString(@tagName(value));
    }

    fn serializeNull(_: @This()) !Ok {
        std.debug.print("null\n", .{});
    }

    fn serializeNumber(_: @This(), value: anytype) !Ok {
        std.debug.print("{}\n", .{value});
    }

    fn serializeSome(self: @This(), value: anytype) !Ok {
        try getty.serialize(value, self.serializer());
    }

    fn serializeString(_: @This(), value: anytype) !Ok {
        std.debug.print("\"{s}\"\n", .{value});
    }
};
{% endhighlight %}
{% endlabel %}

Don't worry if you're confused about the code you just saw.

In this guide, we'll slowly build up to the above `Serializer` implementation and by the end of it all you'll understand everything there is to know about it. Additionally, we'll extend `Serializer` to support more complex types such as `struct{ x: i32 }` and `std.ArrayList(i32)`. We'll also make a JSON deserializer afterwards and go over how custom (de)serialization works in Getty.

So, without further ado, let's get started!
