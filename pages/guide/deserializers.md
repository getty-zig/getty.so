---
title: Deserializers
category: Guide
layout: default
permalink: /guide/deserializers/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Deserializers

Now let’s write ourselves a (simple) JSON deserializer.

## Deserialization

Before we start though, we need to go over how deserialization works in Getty.

<img alt="Architecture" src="/assets/images/deserialization.svg" class="figure" />

Basically, it goes like this:

1. A user passes a Zig type to Getty.
1. Based on the type, Getty selects and executes a Deserialization Block (DB).
1. The DB prompts a deserializer to deserialize its input data.
1. The deserializer deserializes its input data into Getty's Data Model.
1. The resulting Getty value is then passed to a visitor.
1. The visitor uses the Getty value to create a Zig value of the passed-in type.

As an example, say we want to deserialize into a `std.ArrayList(i32)` from a JSON array:

1. `std.ArrayList(i32)` is passed to Getty.
1. Getty selects and executes a DB for _Sequences_.
1. The DB calls the `deserializeSeq` method on a deserializer.
1. The deserializer parses an array from its input data and deserializes it into a _Sequence_.
1. The deserializer passes the _Sequence_ to a visitor (by calling `visitSeq` on the Visitor).
1. The visitor uses the _Sequence_ to create a `std.ArrayList(i32)` value.

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

    // E is the error set returned by getty.Deserializer's required methods
    // upon failure.
    //
    // A default error set, getty.de.Error, is provided by Getty. Every default
    // Visitor within Getty uses the default error set, which means that 9 times
    // out of 10, you will want to include getty.de.Error for this parameter.
    comptime E: type,

    // user_dbt and de_dbt are user- and deserializer- defined Deserialization
    // Blocks or Tuples (DBT), respectively.
    //
    // DBTs define Getty's deserialization behavior. If user- or deserializer-
    // defined customization is not supported or needed by your deserializer,
    // you can pass in null for these parameters.
    //
    // You can ignore these parameters for now. We'll come back to them later.
    comptime user_dbt: anytype,
    comptime ser_dbt: anytype,

    // methods contains every method that getty.Deserializer implementations can
    // implement.
    //
    // In this tutorial, we'll be providing implementations for all of
    // these methods. However, if you don't want to implement a specific
    // method, you can simply omit its corresponding field.
    comptime methods: struct {
        deserializeBool: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeEnum: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeFloat: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeInt: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeMap: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeOptional: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeSeq: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeString: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeStruct: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeUnion: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeVoid: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
    },
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
        null,
        null,
        .{},
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

Let's try deserializing some JSON data with it by calling `getty.deserialize`, which takes an optional allocator, a type to deserialize into, and a `getty.Deserializer` interface value.

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
        null,
        null,
        .{},
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }
};

// 👇
pub fn main() anyerror!void {
    const s = "true";

    var d = Deserializer.init(s);
    const deserializer = d.deserializer();

    const v = try getty.deserialize(null, bool, deserializer);

    std.debug.print("{} ({})\n", .{ v, @TypeOf(v) });
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
[...] error:  deserializeBool is not implemented by type: *main.Deserializer
{% endhighlight %}
{% endlabel %}

Oh no, a compile error!

Looks like Getty can't deserialize into the `bool` type for us unless the `deserializeBool` method has been implemented. So, let's go ahead and do that.

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
        null,
        null,
        .{
            .deserializeBool = deserializeBool, // 👈
        },
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
    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        // 👋 Here's what we're doing:
        //
        //      1. Parse a token from the JSON data.
        //      2. Check to see if the token is a JSON Boolean.
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

    var d = Deserializer.init(s);
    const deserializer = d.deserializer();

    const v = try getty.deserialize(null, bool, deserializer);

    std.debug.print("{} ({})\n", .{ v, @TypeOf(v) });
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
        null,
        null,
        .{
            .deserializeBool = deserializeBool,
            .deserializeEnum = deserializeEnum,         // 👈
            .deserializeFloat = deserializeFloat,       // 👈
            .deserializeInt = deserializeInt,           // 👈
            .deserializeString = deserializeString,     // 👈
            .deserializeVoid = deserializeVoid,         // 👈
            .deserializeOptional = deserializeOptional, // 👈
        },
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }

    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeEnum(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
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
    fn deserializeFloat(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(allocator, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeInt(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
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
    fn deserializeString(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeVoid(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(allocator, De);
            }
        }

        return error.InvalidType;
    }

    // 👇
    fn deserializeOptional(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        // 👋 deserializeOptional is a bit different from the other methods.
        //    Instead of passing a Getty value to a visitor, you pass a
        //    deserializer to visitSome. The visitor will then restart the
        //    deserialization process using the optional's payload.
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

        var d = Deserializer.init(s);
        const deserializer = d.deserializer();

        const v = try getty.deserialize(allocator, T, deserializer);
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
main.main__enum_1317.foo (main.main__enum_1317)
null (?u8)
void (void)
{% endhighlight %}
{% endlabel %}

Not too shabby! 🤩

At this point, the only methods left to implement are those related to aggregate deserialization. However, before we move on, I want to point out something important about `Deserializer`.

When Getty calls the `deserializeBool` method we implemented earlier, it is _not_ telling `Deserializer` that it should parse and deserialize a JSON Boolean from its input data. Instead, __Getty is simply providing a _hint_ about the type that is being deserialized into__. That is, Getty is telling `Deserializer`, "_Hey, the type that the user is deserializing into can probably be made from a Getty Boolean._"

What this means is that we don't have to limit ourselves to parsing only JSON Booleans in `deserializeBool`. We could, for instance, have it support JSON numbers as well!


{% label Zig code %}
{% highlight zig %}
fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
    if (try self.tokens.next()) |token| {
        // JSON Booleans -> Getty Booleans
        if (token == .True or token == .False) {
            return try v.visitBool(allocator, De, token == .True);
        }

        // JSON Numbers -> Getty Booleans
        if (token == .Number) {
            const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

            if (token.Number.is_integer) {
                return try v.visitBool(allocator, De, try std.fmt.parseInt(i64, str, 10) != 0);
            }
        }
    }

    return error.InvalidType;
}
{% endhighlight %}
{% endlabel %}

## Aggregate Deserialization

Alright, let's move on to deserialization for aggregate types!

The only difference between scalar and aggregate deserialization is that the aggregate types within Getty's data model do not have any direct mapping to Zig types. That is, a Getty Boolean is just a `bool` and a Getty Integer is just any Zig integer type, but what's a Getty Sequence or a Getty Map?

Well, this is where the aggregate deserialization interfaces come in. There are three of them: `getty.de.SeqAccess`, `getty.de.MapAccess`, and `getty.de.UnionAccess`. We'll
start by implementing `deserializeSeq`, which will obviously use the `getty.de.SeqAccess` interface.

{% label Zig code %}
{% highlight zig %}
fn SeqAccess(
    comptime Context: type,
    comptime E: type,
    comptime methods: struct {
        nextElementSeed: ?fn (Context, ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value = null,
    },
) type
{% endhighlight %}
{% endlabel %}


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
        null,
        null,
        .{
            .deserializeBool = deserializeBool,
            .deserializeEnum = deserializeEnum,
            .deserializeFloat = deserializeFloat,
            .deserializeInt = deserializeInt,
            .deserializeString = deserializeString,
            .deserializeVoid = deserializeVoid,
            .deserializeOptional = deserializeOptional,
            .deserializeSeq = deserializeSeq, // 👈
        },
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }

    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    fn deserializeEnum(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, str);
            }
        }

        return error.InvalidType;
    }

    fn deserializeFloat(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(allocator, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeInt(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
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

    fn deserializeString(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeVoid(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(allocator, De);
            }
        }

        return error.InvalidType;
    }

    fn deserializeOptional(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
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

    // 👇
    fn deserializeSeq(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .ArrayBegin) {
                // 👋 Note that we pass in the interface value of SeqAccess to
                //    the visitor, and not the implementation itself.
                var sa = SeqAccess{ .de = self };
                return try v.visitSeq(allocator, De, sa.seqAccess());
            }
        }

        return error.InvalidType;
    }
};

// 👇
const SeqAccess = struct {
    de: *Deserializer,

    pub usingnamespace getty.de.SeqAccess(
        *@This(),
        Deserializer.Error,
        .{ .nextElementSeed = nextElementSeed },
    );

    fn nextElementSeed(self: *@This(), allocator: ?Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        // 👋 You can ignore the parsing details here. All we're doing is
        //    telling Getty to perform deserialization again (by calling
        //    seed.deserialize) so that we can deserialize an element from
        //    the sequence. If there are no elements left (i.e., if ']' was
        //    encountered) then null is returned. Otherwise, the deserialized
        //    element is returned.
        const element = seed.deserialize(allocator, self.de.deserializer()) catch |err| {
            if (self.de.tokens.i - 1 >= self.de.tokens.slice.len) {
                return err;
            }

            return switch (self.de.tokens.slice[self.de.tokens.i - 1]) {
                ']' => null,
                else => err,
            };
        };

        return element;
    }
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    // 👇
    var d = Deserializer.init("[1,2,3]");
    const deserializer = d.deserializer();

    const v = try getty.deserialize(allocator, std.ArrayList(i32), deserializer);
    defer getty.de.free(allocator, v);

    std.debug.print("{any} ({})\n", .{ v.items, @TypeOf(v) });
}
{% endhighlight %}
{% endlabel %}

{% label Shell session %}
{% highlight console %}
$ zig build run
{ 1, 2, 3 } (array_list.ArrayListAligned(i32,null))
{% endhighlight %}
{% endlabel %}

Hooray!


