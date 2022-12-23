# Data Models

A __data model__ represents a set of types supported by Getty. The types within
a data model are purely conceptual; they aren't actually Zig types. For
example, there is no `i32` or `u64` in either of Getty's data
models. Instead, they are both considered to the same type: _Integer_.

## Models

Getty maintains two data models: one for serialization and another for deserialization.

!!! info ""

    === "Serialization"

        __Boolean__

        :  Represented by a `bool` value.

        __Enum__

        :  Represented by any `enum` value.

        __Float__

        :  Represented by any floating-point value (`comptime_float`, `f16`, `f32`, `f64`, `f80`, `f128`).

        __Integer__

        :  Represented by any integer value (`comptime_int`, `u0` – `u65535`, `i0` – `i65535`).

        __Map__

        :  Represented by a [`getty.ser.Map`](https://docs.getty.so/#root;ser.Map) interface value.

        __Null__

        :  Represented by a `null` value.

        __Seq__

        :  Represented by a [`getty.ser.Seq`](https://docs.getty.so/#root;ser.Seq) interface value.

        __Some__

        :  Represented by the payload of an optional value.

        __String__

        :  Represented by any string value as determined by [`std.meta.trait.isZigString`](https://ziglang.org/documentation/master/std/#root;meta.trait.isZigString).

        __Structure__

        :  Represented by a [`getty.ser.Structure`](https://docs.getty.so/#root;ser.Structure) interface value.

        __Void__

        :  Represented by a `void` value.

    === "Deserialization"

        __Boolean__

        :  Represented by a `bool` value.

        __Enum__

        :  Represented by any `enum` value.

        __Float__

        :  Represented by any floating-point value (`comptime_float`, `f16`, `f32`, `f64`, `f80`, `f128`).

        __Integer__

        :  Represented by any integer value (`comptime_int`, `u0` – `u65535`, `i0` – `i65535`).

        __Map__

        :  Represented by a [`getty.de.MapAccess`](https://docs.getty.so/#root;de.MapAccess) interface value.

        __Null__

        :  Represented by a `null` value.

        __Seq__

        :  Represented by a [`getty.de.SeqAccess`](https://docs.getty.so/#root;de.SeqAccess) interface value.

        __Some__

        :  Represented by the payload of an optional value.

        __String__

        :  Represented by any string value as determined by [`std.meta.trait.isZigString`](https://ziglang.org/documentation/master/std/#root;meta.trait.isZigString).

        __Union__

        :  Represented by a [`getty.de.UnionAccess`](https://docs.getty.so/#root;de.UnionAccess) interface value and a [`getty.de.VariantAccess`](https://docs.getty.so/#root;de.VariantAccess) interface value.

        __Void__

        :  Represented by a `void` value.

## Motivation

Getty's data models establish a generic baseline from which (de)serializers can
operate.

<figure markdown>

![Data Model](/assets/images/data-model-light.svg#only-light)
![Data Model](/assets/images/data-model-dark.svg#only-dark)

</figure>

??? info "Interactions"

    Notice how the (de)serializers never interact directly with Zig.

    - Serializers receive values from Getty's __data model__ and serialize them
      into a __data format__.
    - Deserializers receive values from a __data format__ and deserialize them
      into Getty's __data model__.

This design often simplifies the job of a (de)serializer significantly. For
example, suppose you wanted to serialize `[]i32`, `[100]i32`,
`std.ArrayList(i32)`, and `std.TailQueue(i32)` values. Since Zig
considers all of these types to be different, you'd have to write unique
serialization logic for all of them (plus integers)!

In Getty, you don't have to do nearly as much work. Getty considers all of the
aforementioned types to be the same: they are all _Sequences_. This means that
you only have to specify the serialization process for two types: _Integers_
and _Sequences_. And by doing so, you'll automatically be able to serialize
values of any of the aforementioned types, plus any other value whose type is
supported by Getty and is considered a _Sequence_, such as `std.SinglyLinkedList`
and `std.BoundedArray`.
