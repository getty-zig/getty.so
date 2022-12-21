# Data Models

A __data model__ represents a set of types supported by Getty. The types within
a data model are purely conceptual; they aren't actually Zig types. For
example, there is no `#!zig i32` or `#!zig u64` in either of Getty's data
models. Instead, they are both considered to the same type: _Integer_.

Getty maintains two data models: one for serialization and another for deserialization.

??? info "Data Models"

    === "Serialization"

        __Boolean__

        :  Represented by a `#!zig bool` value.

        __Enum__

        :  Represented by any `#!zig enum` value.

        __Float__

        :  Represented by any floating-point value (`#!zig comptime_float`, `#!zig f16`, `#!zig f32`, `#!zig f64`, `#!zig f80`, `#!zig f128`).

        __Integer__

        :  Represented by any integer value (`#!zig comptime_int`, `#!zig u0` – `#!zig u65535`, `#!zig i0` – `#!zig i65535`).

        __Map__

        :  Represented by a [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map) interface value.

        __Null__

        :  Represented by a `#!zig null` value.

        __Seq__

        :  Represented by a [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq) interface value.

        __Some__

        :  Represented by the payload of an optional value.

        __String__

        :  Represented by any string value as determined by [`std.meta.trait.isZigString`](https://ziglang.org/documentation/master/std/#root;meta.trait.isZigString).

        __Structure__

        :  Represented by a [`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure) interface value.

        __Void__

        :  Represented by a `#!zig void` value.

    === "Deserialization"

        __Boolean__

        :  Represented by a `#!zig bool` value.

        __Enum__

        :  Represented by any `#!zig enum` value.

        __Float__

        :  Represented by any floating-point value (`#!zig comptime_float`, `#!zig f16`, `#!zig f32`, `#!zig f64`, `#!zig f80`, `#!zig f128`).

        __Integer__

        :  Represented by any integer value (`#!zig comptime_int`, `#!zig u0` – `#!zig u65535`, `#!zig i0` – `#!zig i65535`).

        __Map__

        :  Represented by a [`getty.de.MapAccess`](https://docs.getty.so/#root;de.MapAccess) interface value.

        __Null__

        :  Represented by a `#!zig null` value.

        __Seq__

        :  Represented by a [`getty.de.SeqAccess`](https://docs.getty.so/#root;de.SeqAccess) interface value.

        __Some__

        :  Represented by the payload of an optional value.

        __String__

        :  Represented by any string value as determined by [`std.meta.trait.isZigString`](https://ziglang.org/documentation/master/std/#root;meta.trait.isZigString).

        __Union__

        :  Represented by a [`getty.de.UnionAccess`](https://docs.getty.so/#root;de.UnionAccess) interface value and a [`getty.de.VariantAccess`](https://docs.getty.so/#root;de.VariantAccess) interface value.

        __Void__

        :  Represented by a `#!zig void` value.

## Motivation

Getty's data models establish a generic baseline from which (de)serializers can
operate.

<figure markdown>

![Data Model](/assets/images/data-model-light.svg#only-light)
![Data Model](/assets/images/data-model-dark.svg#only-dark)

</figure>

??? info "Interactions"

    Notice how the (de)serializers never interact directly with Zig.

    - Serializers receive values from Getty's data model and serialize them into a data format.
    - Deserializers receive values from a data format and deserialize them into Getty's data model.

The data models simplify the job of a (de)serializer significantly. For
example, suppose you wanted to serialize `#!zig []i32`, `#!zig [100]i32`,
`#!zig std.ArrayList(i32)`, and `#!zig std.TailQueue(i32)` values. Since Zig
considers all of these types to be different, you'd have to write unique
serialization logic for all of them (and integers)!

In Getty, you don't have to do so much work. Getty considers all of the
aforementioned types to be the same: they are all _Sequences_. This means that
you only have to specify the serialization process for two types: _Integers_
and _Sequences_. And by doing so, you'll automatically be able to serialize
values of any of the aforementioned types, plus any other value whose type is
supported by Getty and is considered a _Sequence_, such as `std.BoundedArray`
and `std.SinglyLinkedList`.
