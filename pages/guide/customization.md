---
title: Customization
category: Guide
layout: default
permalink: /guide/customization/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Customization

So far, Getty has taken care of all of the little (de)serialization details for us behind the scenes. But sometimes, you just need to do things yourself. That's where Getty's customization features come in.

Getty allows both users and (de)serializers to customize the (de)serialization process for types that you've defined yourself, as well as types that you didn't define (such as those in the standard library). Moreover, the customization enabled by Getty can be used in a local manner. That is, you can serialize a `bool` value as a _String_ in one function and as an _Integer_ in another, all without having to define any new or intermediate types.

There are two ways to do customization in Getty: manually or with attributes. Both methods use something called a __Block or Tuple (BT)__, so let's start there.

## Blocks and Tuples

### Definitions

- A __Block__ is a `struct` namespace that is responsible for two things:

    1. Determining what types should be (de)serialized by the block
    2. Specifying how to (de)serialize those types.

- A __Tuple__ is, well, a tuple of blocks.

### Blocks

Every block requires a few specific declarations. What and how many declarations a block requires depends on whether you're serializing or deserializing, and what customization method you're using.

If you'll recall, the `getty.Serializer` and `getty.Deserializer` interfaces had parameters such as `user_sbt`, `serializer_sbt`, `user_dbt` and `deserializer_dbt`. These are where you'd pass in your blocks and tuples in order to customize Getty's behavior.

Okay, let's now take a look at all the different kinds of blocks you can write.

## Attribute Blocks (AB)

As mentioned earlier, one of the ways you can customize Getty's behavior is through __attributes__.
Attributes let you to customize the (de)serialization process for `struct`s, `enum`s, and `union`s.

Every AB is defined the same whether you're serializing or deserializing, so every AB will look like this:

{% label Zig code %}
{% highlight zig %}
const Point = struct {
    x: i32,
    y: i32,
};

const block = struct {
    // 👋 Specifies what types should be serialized by this block.
    pub fn is(comptime T: type) bool {
        return T == Point;
    }

    // 👋 Specifies serialization properties for values relevant to this block.
    //
    //    As you can see, attributes are defined as an anonymous struct literal.
    //
    //    Every field name in attributes must match either the fields or
    //    variants in your struct/enum/union, or to the word "Container". The
    //    former are known as field/variant attributes, while the latter are
    //    known as container attributes.
    //
    //    A field's value in an attribute map is also an anonymous struct
    //    literal. The fields in this struct literal depend on what kind of
    //    attribute you're specifying.
    pub const attributes = .{
        .x = .{ .rename = "X" },
        .y = .{ .skip = true },
    };
};
{% endhighlight %}
{% endlabel %}

For a list of all of the attributes you can specify, see [here](/attributes).

Try modifying the serializer we wrote earlier in this guide to pass in this `block` declaration for the `user_sbt` parameter in the call to `getty.Serializer`. Then, try to serialize a `Point` value. You should see something like `{"X":1}` instead of `{"x":1,"y":2}`.

## Serialization Blocks (SB)

In cases where attributes aren't sufficient, you can manually customize the serialization process by simply replacing the `attributes` declaration we just wrote with a `serialize` function:

{% label Zig code %}
{% highlight zig %}
const block = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // 👋 Specifies how to serialize values relevant to this block.
    //
    //    Here, we're telling Getty to serialize bool values as Integers!
    pub fn serialize(value: anytype, serializer: anytype) @TypeOf(serializer).Error!@TypeOf(serializer).Ok {
        const v: i32 = if (value) 1 else 0;
        return try serializer.serializeInt(v);
    }
};
{% endhighlight %}
{% endlabel %}

If you update `Serializer` to pass in `block` for the `user_sbt` parameter in the call to `getty.Serializer`, you should see that `bool` values are now serialized as either `1` or `0`.

## Deserialization Blocks (DB)

Of course, you can also manually customize the deserialization process with a Deserialization Block.

DBs are very similar to SBs in that they have an `is` and a `deserialize`
function. However, DBs also require a `Visitor` function, which returns an
implementation of the `getty.de.Visitor` interface.

{% label Zig code %}
{% highlight zig %}
const Allocator = @import("std").mem.Allocator;

// getty.de.Visitor specifies how to deserialize from Getty's data model to Zig.
fn Visitor(
    // Ctx is the namespace that owns the method implementations you want to
    // use to implement getty.de.Visitor.
    //
    // Usually, this is whatever type is implementing getty.de.Visitor (or a
    // pointer to it if mutability is required in your method implementations).
    comptime Ctx: type,

    // V is the value produced by the visitor. In other words, it is the return
    // type of getty.de.Visitor's methods.
    comptime V: type,

    // methods contains every method that getty.de.Visitor implementations can
    // implement.
    //
    // The D parameter in these methods is a getty.Deserializer interface type.
    // You generally don't need it though unless you're doing pointer
    // deserialization.
    //
    // The input parameter is the Getty value that is passed to the visitor. The
    // job of these methods is to turn those Getty values into a value of type
    // Value.
    //
    // The map, seq, ua, and va parameters are 
    comptime methods: struct {
        visitBool: ?fn (Ctx, ?Allocator, comptime D: type, input: bool) D.Error!V = null,
        visitEnum: ?fn (Ctx, ?Allocator, comptime D: type, input: anytype) D.Error!V = null,
        visitFloat: ?fn (Ctx, ?Allocator, comptime D: type, input: anytype) D.Error!V = null,
        visitInt: ?fn (Ctx, ?Allocator, comptime D: type, input: anytype) D.Error!V = null,
        visitMap: ?fn (Ctx, ?Allocator, comptime D: type, map: anytype) D.Error!V = null,
        visitNull: ?fn (Ctx, ?Allocator, comptime D: type) D.Error!V = null,
        visitSeq: ?fn (Ctx, ?Allocator, comptime D: type, seq: anytype) D.Error!V = null,
        visitSome: ?fn (Ctx, ?Allocator, deserializer: anytype) @TypeOf(deserializer).Error!V = null,
        visitString: ?fn (Ctx, ?Allocator, comptime D: type, input: anytype) D.Error!V = null,
        visitUnion: ?fn (Ctx, ?Allocator, comptime D: type, ua: anytype, va: anytype) D.Error!V = null,
        visitVoid: ?fn (Ctx, ?Allocator, comptime D: type) D.Error!V = null,
    },
) type
{% endhighlight %}
{% endlabel %}

{% label Zig code %}
{% highlight zig %}
const block = struct {
    pub fn is(comptime T: type) bool {
        return T == bool;
    }

    // 👋 Specifies how to deserialize into types relevant to this block.
    //
    //    Here, we're telling Getty to hint to the deserializer that they
    //    should deserialize their input data into a Getty Integer. This'll
    //    let us deserialize JSON Numbers into bool values!
    //
    //    The second parameter here is the current type being deserialized
    //    into. Generally, you don't need it unless you're doing pointer
    //    deserialization or something.
    pub fn deserialize(
        allocator: ?std.mem.Allocator,
        comptime _: type,
        deserializer: anytype,
        visitor: anytype,
    ) @TypeOf(deserializer).Error!@TypeOf(visitor).Value {
        return try deserializer.deserializeInt(allocator, visitor);
    }

    // 👋 Visitors specify how to deserialize from Getty's data model into Zig.
    //
    //    Here, we've made a visitor that knows how to deserialize Getty
    //    Integers into bool values.
    pub fn Visitor(comptime Value: type) type {
        return struct {
            pub usingnamespace getty.de.Visitor(
                @This(),
                Value,
                .{ .visitInt = visitInt },
            );

            pub fn visitInt(
                _: @This(),
                allocator: ?std.mem.Allocator,
                comptime Deserializer: type,
                input: anytype,
            ) Deserializer.Error!Value {
                return switch (input) {
                    0 => false,
                    1 => true,
                    else => error.InvalidType,
                };
            }
        };
    }
};
{% endhighlight %}
{% endlabel %}
