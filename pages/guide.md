---
title: Guide
category: Introduction
layout: default
permalink: /guide/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Guide

Welcome to Getty! This is the official guide for the Getty framework, and is designed to serve as both:

- An introduction to writing serializers and deserializers with Getty.
- A reference for more experienced Getty developers.

## Contents

- [Introduction](#introduction)
- [Interfaces](#interfaces)
- [Serializer](#serializer)
- [Deserializer](#deserializer)
- [Customization](#customization)
- [Attributes](#attributes)

---

## Interfaces

Before we begin writing any code, let's first take a look at how interfaces
work in Zig, as you'll be using them quite often when working with Getty.

### Generic Interfaces

Generic interfaces in Zig are just functions. The constraints of a generic
interface are specified as a parameter list.

{% lang Zig code %}
{% highlight zig %}
// Interface
fn Writer(
    // Associated types
    comptime Context: type,
    comptime Error: type,

    // Required methods
    comptime writeFn: fn (Context, []const u8) Error!usize,
) type
{% endhighlight %}
{% endlang %}

All of the generic interfaces within the standard library return a `type`, just
like our `Writer` interface does. This returned type is known as an __interface
type__, and it's typically just a `struct` with one field to store a value of an
implementing type and wrappers for the interface's required methods.

{% lang Zig code %}
{% highlight zig %}
fn Writer(
    comptime Context: type,
    comptime Error: type,
    comptime writeFn: fn (Context, []const u8) Error!usize,
) type {
    // Interface type
    return struct {
        // Value of implementing type
        context: Context,

        // Wrapper for required method: `writeFn`
        pub fn write(self: @This(), bytes: []const u8) Error!usize {
            return writeFn(self.context, bytes);
        }
    };
}
{% endhighlight %}
{% endlang %}

The reason generic interfaces return an interface type has to do with how Zig
handles generics, but the short of it is you can't use a value of a type that
implements a generic interface as an implementation of that interface. You have
to use a value of the interface type (i.e., an __interface value__) instead.

For example, the `std.io.getStdOut` function returns a `File` value that
implements the `std.io.Writer` generic interface. However, as I mentioned
before, you can't use the returned value as a `std.io.Writer` implementation.
That is, if you called the `writeByte` method (which is provided by
`std.io.Writer`) on the `File` value, you will simply get a compile error.
Instead, you must first call the `stdout` method on the `File` value to obtain
a `std.io.Writer` _interface value_, which you can then call `writeByte` on.

```zig
const std = @import("std");

pub fn main() anyerror!void {
    var stdout = std.io.getStdOut();

    stdout.writeByte(123);          // incorrect
    stdout.writer().writeByte(123); // correct
}
```

As you can see in the previous code example, implementations of generic
interfaces will often provide a function, called an __interface function__,
that creates interface values for you.

```zig
// Implementing type
const MyWriter = struct {
    // Interface type
    const Writer = std.io.Writer(MyWriter, error{Io}, write);

    // Interface function
    pub fn writer(self: MyWriter) Writer {
        return .{ .context = self };
    }

    fn write(_: MyWriter, bytes: []const u8) !usize {
        std.debug.print("{s}", .{bytes});
        return bytes.len;
    }
};
```

Alright! Now I can tell you how to actually implement a generic interface. All
you need to do is provide some way to obtain an interface value. And that's it!
Most implementations (e.g., `MyWriter`, `File`) use an interface function, but
it's up to you.

### Getty Interfaces

So, that's how generic interfaces work. We'll finish up by going over Getty
interfaces, which are a tiny bit different.

In fact, there's just one difference between Getty and generic interfaces, and
that is the fact that Getty interfaces do not return an interface type, but
rather a `struct` namespace containing an interface type and an interface
function.

```zig
fn Writer(
    comptime Context: type,
    comptime Error: type,
    comptime writeFn: fn (Context, []const u8) Error!usize,
) type {
    // Namespace
    return struct {
        // Interface type
        //
        // In Getty, the name of an interface type will always @"<name>", where
        // <name> is the interface's import path. For example, the interface
        // type for the `getty.Serializer` interface is @"getty.Serializer"
        // and the interface type for the `getty.ser.Map` interface is
        // @"getty.ser.Map".
        pub const @"Writer" = struct {
            context: Context,

            pub fn write(self: @This(), bytes: []const u8) Error!usize {
                return writeFn(self.context, bytes);
            }
        };

        // Interface function
        //
        // In Getty, interface functions are always a method of the
        // implementing type and their names are always the same as their
        // interface, but in `camelCase`. For example, the interface function
        // for `getty.Serializer` is called `serializer` and the interface
        // function for `getty.ser.Map` is called `map`.
        pub fn writer(self: Context) @"Writer" {
            return .{ .context = self };
        }

    };
}
```

That means you can implement a Getty interface by simply calling it and then applying `usingnamespace` to its return value.

```zig
const MyWriter = struct {
    pub usingnamespace Writer(MyWriter, error{Io}, write);

    fn write(_: MyWriter, bytes: []const u8) !usize {
        std.debug.print("{s}", .{bytes});
        return bytes.len;
    }
};
```

Alright, that's enough about interfaces. Let's start writing a serializer and
deserializer!
