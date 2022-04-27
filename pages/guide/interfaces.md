---
title: Interfaces
category: Guide
layout: default
permalink: /guide/interfaces/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Interfaces

In short, working with Getty means implementing various interfaces defined by the framework.
Therefore, it's important to understand how __Getty interfaces__ work and how to implement them.

A Getty interface is just a normal function whose parameter list specifies the interface's constraints.
If you've seen `std.io.Reader` or `std.io.Writer` before, then this should look familiar to you.

{% label Zig code %}
{% highlight zig %}
// Interface
fn Serializer(
    // Associated types
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,

    // Required methods
    comptime serializeBool: fn (Context, bool) Error!Ok,
) type
{% endhighlight %}
{% endlabel %}


Unlike `std.io.Reader` and `std.io.Writer` however, the return value of a Getty interface is a `struct` namespace that contains two declarations: an __interface type__ and an __interface function__.

{% label Zig code %}
{% highlight zig %}
fn Serializer(
    comptime Context: type,
    comptime Ok: type,
    comptime Error: type,
    comptime serializeBool: fn (Context, bool) Error!Ok,
) type
    // Namespace
    return struct {
        // Interface type
        //
        // In Getty, the name of an interface type is always @"<name>", where
        // <name> is the interface's import path. For example, the interface
        // type for the getty.Serializer interface is @"getty.Serializer".
        pub const @"Serializer" = struct {
            context: Context,

            pub const Ok = Ok;
            pub const Error = Error;

            pub fn serializeBool(self: @This(), value: bool) Error!Ok {
                return serializeBool(self.context, value);
            }
        };

        // Interface function
        //
        // In Getty, interface functions are always a method of the
        // implementing type and their names are always the same as their
        // interface, but in camelCase. For example, the interface function
        // for the getty.Serializer interface is called serializer.
        pub fn serializer(self: Context) @"Serializer" {
            return .{ .context = self };
        }
    };
}
{% endhighlight %}
{% endlabel %}

Interface types are `struct`s that have a field to store a value of an implementing type, declarations for the interface's associated types, and wrapper functions for the interface’s required methods. The purpose of an interface type is to work around some issues regarding how Zig handles generics. Basically, you can't use a value of a type that implements a Getty interface as an implementation of that interface. Instead, you must use a value of an interface type, known as an __interface value__.

For example, the `std.io.getStdOut` function returns a `File` value that implements the `std.io.Writer` interface, which behaves very similar to a Getty interface. But as I've mentioned, you can't use the returned `File` value as a `std.io.Writer` implementation. That is, if you try to call the `writeByte` method (which is provided by `std.io.Writer`) on the `File` value, you'll simply get a compile error. Instead, you must first use the `File.stdout` method to obtain a `std.io.Writer` interface value, which you can then call `writeByte` on.

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

pub fn main() anyerror!void {
    var out = std.io.getStdOut();

    try out.writer().writeByte('A');  // ✔️ Correct
    try out.writeByte('A');           // ❌ Compile error
}
{% endhighlight %}
{% endlabel %}

And with that, I can finally talk about how to implement Getty interfaces! All you need to do is provide a way to obtain an interface value for the interface you're implementing. This is where interface functions come in. They're convenient ways to obtain interface values.

For interfaces such as `std.io.Reader` or `std.io.Writer`, an implementing type (e.g., `File`) would have to manually write their own interface function (e.g., `File.stdout`). However, if you'll recall, Getty interfaces return a namespace _containing_ an interface function, which means you can implement any Getty interface just by calling it and applying `usingnamespace` to its return value!

{% label Zig code %}
{% highlight zig %}
const Serializer = struct {
    pub usingnamespace Serializer(
        @This(),
        void,
        error{ Io, Syntax },
        undefined,
    );
};
{% endhighlight %}
{% endlabel %}

That's everything you need to know about Getty interfaces! In the next section, we'll use what we've learned to implement our first Getty interface: `getty.Serializer`. Get ready to write some code!
