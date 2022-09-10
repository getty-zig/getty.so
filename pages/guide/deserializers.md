---
title: Deserializers
category: Guide
layout: default
permalink: /guide/deserializers/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Deserializers

We will now write a simple, but complete, JSON deserializer.

## Deserialization

But first, we need to go over how deserialization works in Getty.

<img alt="Architecture" src="/assets/images/deserialization.svg" class="figure" />

Basically, it works like this:

1. A user passes a Zig type to Getty.
1. Based on the type, Getty selects and executes a Deserialization Block (DB).
1. The DB prompts a deserializer to deserialize its input data.
1. The deserializer deserializes its input data into Getty's Data Model.
1. The resulting Getty value is then passed to a visitor.
1. The visitor uses the Getty value to create a Zig value of the passed-in type.

For example, say we want to deserialize into an `std.ArrayList(i32)` from a JSON array:

1. `std.ArrayList(i32)` is passed to Getty.
1. Getty selects and executes a DB for sequences.
1. The DB calls the `deserializeSeq` method on a deserializer.
1. The deserializer parses an array from its input data and deserializes it into a Getty Sequence.
1. The deserializer passes the Getty Sequence to a visitor (by calling `visitSeq` on the Visitor).
1. The visitor uses the Getty Sequence to create a `std.ArrayList(i32)` value.

The important thing to understand here is that deserializers and visitors are different:

- Deserializers deserialize from a data format into Getty's Data Model.
- Visitors deserialize from Getty's Data Model into Zig.

<br>

__It's _very_ important that you understand this difference!__ So be sure you got it down before moving on.

<br>

## Let's Write a Deserializer!

Every Getty deserializer must implement the `getty.Deserializer` interface, shown below.

{% label Zig code %}
{% highlight zig %}
// getty.Deserializer specifies the behavior of a deserializer, and must be
// implemented by all Getty deserializers.
fn Deserializer(
    // Context is the namespace that owns the method implementations you want
    // to use to implement getty.Deserializer.
    //
    // Usually, this is whatever type is implementing getty.Deserializer (or a
    // pointer to it if mutability is required in your method implementations).
    comptime Context: type,

    // Error is the error set returned by getty.Deserializer's required methods
    // upon failure.
    //
    // A default error set, getty.de.Error, is provided by Getty. Every default
    // Visitor within Getty uses the default error set, which means that 9 times
    // out of 10, you will want to include getty.de.Error in your Error type.
    comptime Error: type,

    // user_dbt and de_dbt are user- and deserializer- defined Deserialization
    // Blocks or Tuples (DBT), respectively.
    //
    // DBTs define Getty's deserialization behavior. The default deserialization
    // behavior of Getty is defined as getty.default_dt and should be set for
    // user_dbt or de_dbt if user- or deserializer-defined customization is not
    // supported or needed.
    comptime user_dbt: anytype,
    comptime ser_dbt: anytype,

    // These are methods that getty.Deserializer implementations must provide.
    //
    // For this tutorial, we'll be providing implementations for all of
    // these methods. However, you can always set any of the required methods
    // to `undefined` if you don't want to support a specific behavior.
    comptime deserializeBool: Fn(Context, Error),
    comptime deserializeEnum: Fn(Context, Error),
    comptime deserializeFloat: Fn(Context, Error),
    comptime deserializeInt: Fn(Context, Error),
    comptime deserializeMap: Fn(Context, Error),
    comptime deserializeOptional: Fn(Context, Error),
    comptime deserializeSeq: Fn(Context, Error),
    comptime deserializeString: Fn(Context, Error),
    comptime deserializeStruct: Fn(Context, Error),
    comptime deserializeUnion: Fn(Context, Error),
    comptime deserializeVoid: Fn(Context, Error),
) type
{% endhighlight %}
{% endlabel %}

Similar to `getty.Serializer`, most of `getty.Deserializer`'s parameters have default values that we can use. So let's start with the following `getty.Deserializer` implementation:

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

const Deserializer = struct {
    tokens: std.json.TokenStream, // 👋 A JSON parser provided by the standard library.

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        getty.default_dt,
        getty.default_dt,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer"; // 👋 Alias for our interface type.

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }
};
{% endhighlight %}
{% endlabel %}

Congratulations! You've just written your first Getty deserializer!

Now let's try to deserialize some JSON input by calling `getty.deserialize`, which takes an optional allocator, a type to deserialize into, and a `getty.Deserializer` interface value:

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        getty.default_dt,
        getty.default_dt,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }
};

// 👇
pub fn main() anyerror!void {
    const s = "true";
    const d = Deserializer.init(s).deserializer();
    const v = try getty.deserialize(null, bool, d);

    std.debug.print("{} ({s})\n", .{v, @TypeOf(v)});
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
[...] error: use of undefined value here causes undefined behavior
  return try deserializeBool(self.context, allocator, visitor);
             ^
{% endhighlight %}
{% endlabel %}

A compile error!

What happened was that Getty saw we were trying to deserialize into a `bool` and so it called the `deserializeBool` method of the interface value we passed in. That method then tried to call the `deserializeBool` parameter of the `getty.Deserializer` interface. However, since we set all of the required methods to `undefined` in our call to the interface, the compiler kindly reminded us about the dangers of using undefined values.

To fix this, all we have to do is provide a method implementation for `deserializeBool`.

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

// 👇
const Allocator = std.mem.Allocator;

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        getty.default_dt,
        getty.default_dt,
        deserializeBool, // 👈
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }

    // 👇
    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        // 👋 Here's what we're doing:
        //
        //      1. Parse a token from the JSON data.
        //      2. Check to see if the token is a Boolean.
        //      3. Deserialize the token into a Getty Boolean (token == .True).
        //      4. Pass the Getty Boolean to the visitor, v.
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

};

pub fn main() anyerror!void {
    const s = "true";
    const d = Deserializer.init(s).deserializer();
    const v = try getty.deserialize(null, bool, d);

    std.debug.print("{} ({s})\n", .{v, @TypeOf(v)});
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
true (bool)
{% endhighlight %}
{% endlabel %}

Success!

<!--With that in mind, let's talk about deserializeBool. This method serves-->
<!--as a *hint* to our deserializer that the Visitor v will (most likely)-->
<!--produce a Boolean value.-->

<!--Using this hint, our deserializeBool implementation will try to parse-->
<!--a Boolean from the deserializer's input. After all, if the visitor is-->
<!--trying to make a Boolean value, it doesn't make sense to parse a float-->
<!--or string.-->

Now let's do the same thing for `deserializeEnum`, `deserializeFloat`, `deserializeInt`, `deserializeOptional`, `deserializeString`, and `deserializeVoid`.

{% label src/main.zig %}
{% highlight zig %}
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        getty.default_dt,
        getty.default_dt,
        deserializeBool,
        deserializeEnum,
        deserializeFloat,
        deserializeInt,
        undefined,
        deserializeOptional,
        undefined,
        deserializeString,
        undefined,
        undefined,
        deserializeVoid,
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }

    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeEnum(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        // 👋 Again, all we're doing is parsing tokens, turning them
        //    into Getty values, and passing those values to a visitor.
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                // 👋 By the way, you'll see token.X.slice pretty often in our
                //    deserializer. All it's doing is getting the string that
                //    corresponds to our token from the JSON data.
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, str);
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeFloat(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(allocator, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeInt(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

                if (token.Number.is_integer) {
                    return try switch (str[0]) {
                        '-' => v.visitInt(allocator, De, try std.fmt.parseInt(i64, str, 10)),
                        else => v.visitInt(allocator, De, try std.fmt.parseInt(u64, str, 10)),
                    };
                }
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeString(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeVoid(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(allocator, De);
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeOptional(self: *Self, allocator: ?Allocator, v: anytype) !@TypeOf(v).Value {
        // 👋 deserializeOptional is a bit different from the other methods.
        //    Instead of passing a Getty value to a visitor, you pass a
        //    deserializer to visitSome. The visitor will then restart the
        //    deserialization process using the optional's payload type.
        //
        //    In other words, you can think of this method as a place to do
        //    some pre-processing before deserializing an actual payload value.
        const backup = self.tokens;

        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitNull(allocator, De);
            }

            self.tokens = backup;
            return try v.visitSome(allocator, self.deserializer());
        }

        return error.InvalidType;
    }
};

pub fn main() anyerror!void {
    // 👇
    const allocator = std.heap.page_allocator;
    const types = .{ i32, f32, []u8, enum { foo }, ?u8, void };
    const jsons = .{ "10", "10.0", "\"ABC\"", "\"foo\"", "null", "null" };

    // 👇
    inline for (jsons) |s, i| {
        const T = types[i];
        const d = Deserializer.init(s).deserializer();
        const v = try getty.deserialize(allocator, T, d);
        defer getty.de.free(allocator, v);

        std.debug.print("{any} ({})\n", .{ v, @TypeOf(v) });
    }
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
10 (i32)
1.0e+01 (f32)
{ 65, 66, 67 } ([]u8)
types.foo (types)
null (?u8)
void (void)
{% endhighlight %}
{% endlabel %}

Not too shabby! 🤩

But wait a second! With type reflection, we could've just written a simple function to do what we did. What benefit is there in doing all of these extra steps?
