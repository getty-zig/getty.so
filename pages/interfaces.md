---
title: Interfaces
category: Concepts
layout: default
permalink: /interfaces/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Interfaces

Whether you're building a serializer or deserializer, you'll eventually have to implement an interface.

Interfaces in Zig are a userspace thing, so everyone has their own way of doing things. Naturally, that means that before you start writing any code, it's important that you learn how Getty does interfaces.

## What is a Getty Interface?

A __Getty interface__ is just a function, and its constraints are specified as a parameter list. For instance, the following, example interface requires 3 associated types and 1 method from its implementations.

{% label Zig code %}
{% highlight zig %}
// 👋 Interface
fn BoolSerializer(
    // 👋 Associated types
    comptime Context: type,
    comptime O: type,
    comptime E: type,

    // 👋 Required methods
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
    },
) type
{% endhighlight %}
{% endlabel %}

The return value of a Getty interface is a `struct` namespace that contains two declarations: an __interface type__ and an __interface function__. A value of the interface type is known as an __interface value__.

{% label Zig code %}
{% highlight zig %}
fn BoolSerializer(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeBool: ?fn (Context, bool) E!O = null,
    },
) type {
    // 👋 Namespace
    return struct {
        // 👋 Interface type
        //
        //    Interface types generally have a single field to store an
        //    instance of an implementing type, a few declarations that may
        //    be useful to implementations, and wrapper methods that define the
        //    interface's behavior.
        pub const Interface = struct {
            context: Context,

            pub const Ok = O;
            pub const Error = E;

            pub fn serializeBool(self: @This(), value: bool) Error!Ok {
                if (methods.serializeBool) |f| {
                    return try f(self.context, value);
                }

                @compileError("serializeBool is unimplemented");
            }
        };

        // 👋 Interface function
        pub fn boolSerializer(self: Context) Interface {
            // 👋 Interface value
            return .{ .context = self };
        }
    };
}
{% endhighlight %}
{% endlabel %}

## How to Implement a Getty Interface?

To implement a Getty interface, call the interface and apply `usingnamespace` to its return value. This will import an interface type and interface function into your implementation.

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

const UselessSerializer = struct {
    // 👋 Implements BoolSerializer for UselessSerializer.
    usingnamespace BoolSerializer(
        @This(),
        void,
        error{},
        .{},
    );
};

const OppositeSerializer = struct {
    // 👋 Implements BoolSerializer for OppositeSerializer.
    usingnamespace BoolSerializer(
        @This(),
        Ok,
        Error,
        .{ .serializeBool = serializeBool },
    );

    const Ok = void;
    const Error = error{};

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{!value});
    }
};
{% endhighlight %}
{% endlabel %}

## How to Use a Getty Interface Implementation?

To use a value of, say `OppositeSerializer`, as an implementation of `BoolSerializer`:

{% label Zig code %}
{% highlight zig %}
pub fn main() anyerror!void {
    // 👋 Create a value of the implementing type.
    const os = OppositeSerializer{};

    // 👋 Create an interface value from it.
    const bs = os.boolSerializer();

    // 👋 Use the interface value!
    try bs.serializeBool(true);  // output: false
    try bs.serializeBool(false); // output: true
}
{% endhighlight %}
{% endlabel %}
