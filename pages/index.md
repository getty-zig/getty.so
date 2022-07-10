---
layout: default
permalink: /
SPDX-License-Identifier: LGPL-2.1-or-later
---

Getty is a framework for building __robust__, __optimal__, and __reusable__ (de)serializers in Zig.

## Goals

- Minimize the amount of code required for (de)serializer implementations.
- Enable granular customization of the (de)serialization process.
- Avoid as much performance overhead as possible.

## Features

- Compile-time (de)serialization.
- Out-of-the-box support for a variety of `std` types.
- Local customization of (de)serialization logic for both existing and remote types.
- Data model abstractions that serve as simple and generic baselines for (de)serializers.

---

# Introduction

- [Guide](/guide)
- [Design](/design)
- [Examples](https://github.com/getty-zig/getty/tree/main/examples)

# Concepts

- [Data Models](/data-models)
- [Serializers](/serializers)
- [Deserializers](/deserializers)
- [Visitors](/visitors)
- [Blocks & Tuples](blocks-and-tuples)

# Contributing

- [Contributing](/contributing)
- [Style Guide](/style-guide)
- [Repository Structure](/repository-structure)

# Project

- [GitHub](https://github.com/getty-zig/getty)
- [Releases](https://github.com/getty-zig/getty/releases)

---

{% label Zig code %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

// Serializer is a JSON serializer that supports:
//
//  - Integers
//  - Arrays
//  - Slices
//  - Tuples
//  - Vectors
//  - std.ArrayList
//  - std.TailQueue
//  - std.SinglyLinkedList
//  - std.BoundedArray
//  - Pointers for the above types
//  - Optionals for the above types
//  - and more!
const Serializer = struct {
    pub usingnamespace getty.Serializer(
        @This(),
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        getty.TODO,
        Seq,
        getty.TODO,
        undefined,
        undefined,
        undefined,
        serializeInt,
        undefined,
        undefined,
        serializeSeq,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeInt(_: @This(), value: anytype) !Ok {
        std.debug.print("{}", .{value});
    }

    fn serializeSeq(_: @This(), _: ?usize) !Seq {
        std.debug.print("[", .{});
        return Seq{};
    }
};

const Seq = struct {
    first: bool = true,

    pub usingnamespace getty.ser.Seq(
        *@This(),
        Serializer.Ok,
        Serializer.Error,
        serializeElement,
        end,
    );

    fn serializeElement(s: *@This(), value: anytype) !void {
        switch (s.first) {
            true => s.first = false,
            false => std.debug.print(", ", .{}),
        }
        try getty.serialize(value, (Serializer{}).serializer());
    }

    fn end(_: *@This()) !Serializer.Ok {
        std.debug.print("]", .{});
    }
};
{% endhighlight %}
{% endlabel %}
