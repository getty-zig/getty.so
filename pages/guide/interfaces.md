---
title: Interfaces
category: Guide
layout: default
permalink: /guide/interfaces/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Interfaces

Before we begin writing any code, let's quickly go over how interfaces work in Getty since they're a fairly important part of the framework.
For a more in-depth explanation on Getty interfaces, see [here](/interfaces).

## What is a Getty Interface?

A __Getty interface__ is just a function, and its constraints are specified as a parameter list. For example, the following interface requires three associated types and one method from its implementations:

{% label Zig code %}
{% highlight zig %}
// Interface
fn BoolSerializer(
    // Associated types
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,

    // Required methods
    comptime serializeBool: fn (Context, bool) Error!Ok,
) type
{% endhighlight %}
{% endlabel %}

The return value of a Getty interface is a `struct` namespace that contains two declarations: an __interface type__ and an __interface function__. A value of the interface type is known as an __interface value__.

{% label Zig code %}
{% highlight zig %}
fn BoolSerializer(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeBool: fn (Context, bool) Error!Ok,
) type
    // Namespace
    return struct {
        // Interface type
        pub const @"BoolSerializer" = struct {
            context: Context,

            pub const Ok = Ok;
            pub const Error = Error;

            pub fn serializeBool(self: @This(), value: bool) Error!Ok {
                return serializeBool(self.context, value);
            }
        };

        // Interface function
        pub fn boolSerializer(self: Context) @"BoolSerializer" {
            // Interface value
            return .{ .context = self };
        }
    };
}
{% endhighlight %}
{% endlabel %}

## How Do I Implement a Getty Interface?

To implement a Getty interface, simply call it and apply `usingnamespace` to the returned value. This will import an interface type and interface function into your implementation.

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

const UselessSerializer = struct {
    // Implements BoolSerializer for UselessSerializer.
    usingnamespace BoolSerializer(
        @This(),
        void,
        error{ Io, Syntax },
        undefined,
    );
};

const OppositeSerializer = struct {
    // Implements BoolSerializer for OppositeSerializer.
    usingnamespace BoolSerializer(
        @This(),
        Ok,
        Error,
        serializeBool,
    );

    const Ok = void;
    const Error = error{ Io, Syntax };

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("{}", .{!value});
    }
};
{% endhighlight %}
{% endlabel %}

## How Do I Use a Getty Interface Implementation?

To use a value of `OppositeSerializer` as an implementation of `BoolSerializer`:

{% label Zig code %}
{% highlight zig %}
fn main() anyerror!void {
    // Create a value of the implementing type.
    const os = OppositeSerializer{};

    // Create an interface value from it.
    const bs = os.boolSerializer();

    // Use the interface value!
    try bs.serializeBool(true);  // output: false
    try bs.serializeBool(false); // output: true
}
{% endhighlight %}
{% endlabel %}
