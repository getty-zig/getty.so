---
title: Interfaces
category: Guide
layout: default
permalink: /guide/interfaces/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Interfaces

Most of your interactions with Getty will consist of you implementing various
interfaces defined by Getty. As such, it's important to understand how
Getty interfaces work and how to implement them.

__Getty interfaces__ are just regular functions and their constraints are
specified as a parameter list.

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

The return value of a Getty interface is a `struct` namespace that contains two
public declarations: an __interface type__ and an __interface function__.

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

Interface types are `struct`s that have a field to store a value of an
implementing type, declarations for the interface's associated types, and
wrapper functions for the interface’s required methods. The purpose of an
interface type is to work around some issues regarding how Zig handles
generics. In short, you can't use a value of a type that implements a generic
interface as an implementation of that interface. Instead, you must use a
value of an interface type, also known as an __interface value__.

For example, the `std.io.getStdOut` function returns a `File` value that
implements the `std.io.Writer` interface (which is similar to a Getty
interface). But as I've mentioned, you can't use the returned `File` value as a
`std.io.Writer` implementation. That is, if you called the `writeByte` method
(which is provided by `std.io.Writer`) on the `File` value, you'll end up with
a compile error. Instead, you must first call the `stdout` method
of the `File` value to obtain a `std.io.Writer` interface value, which you can
then call `writeByte` on.

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

pub fn main() anyerror!void {
    var out = std.io.getStdOut();

    try out.writer().writeByte(123);  // ✔️ Correct
    try out.writeByte(123);           // ❌ Compile error
}
{% endhighlight %}
{% endlabel %}

To implement a Getty interface, all you need to do is provide some way to
obtain an interface value for the interface you're implementing. This is where
interface functions come in. They're convenient ways to obtain interface
values. And if you'll recall, all Getty interfaces return a namespace
containing an interface function, which means you can implement any Getty
interface just by calling it and then applying `usingnamespace` to its return
value!

{% label Zig code %}
{% highlight zig %}
const std = @import("std");

const Serializer = struct {
    pub usingnamespace Serializer(
        @This(),
        Ok,
        Error,
        serializeBool,
    );

    const Ok = void;
    const Error = error { Io, Syntax };

    fn serializeBool(_: @This(), value: bool) Error!Ok {
        std.debug.print("the one {} ring\n", .{value});
    }
};
{% endhighlight %}
{% endlabel %}
