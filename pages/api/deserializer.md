---
title: Deserializer
category: API
layout: default
permalink: /api/Deserializer/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.Deserializer`

## Description

`getty.Deserializer` is an interface that specifies the behavior of a deserializer.

## Synopsis

{% label Zig code %}
{% highlight zig %}
const Allocator = @import("std").mem.Allocator;

fn Deserializer(
    comptime Context: type,
    comptime E: type,
    comptime user_dbt: anytype,
    comptime deserializer_dbt: anytype,
    comptime methods: struct {
        deserializeBool: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeEnum: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeFloat: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeInt: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeMap: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeOptional: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeSeq: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeString: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeStruct: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeUnion: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeVoid: ?fn (Context, ?Allocator, v: anytype) E!@TypeOf(v).Value = null,
    },
) type
{% endhighlight %}
{% endlabel %}

### Interface

- `@"getty.Deserializer"`: Interface type.
- `deserializer`: Interface function.

### Parameters

- `Context`: The namespace that owns the method implementations you provide in `methods`.

- `E`: The error set returned by `getty.Deserializer`'s methods upon failure.

- `user_dbt`: An optional user-defined [Deserialization Block or Tuple](/TODO).

- `deserializer_dbt`: An optional deserializer-defined [Deserialization Block or Tuple](/TODO).

- `methods`: A namespace containing every method that `getty.Deserializer` implementations can implement.

### Required Methods

- `deserializeBool`: Deserializes a deserializer's input data into a Getty Boolean.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeEnum`: Deserializes a deserializer's input data into a Getty Enum.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeFloat`: Deserializes a deserializer's input data into a Getty Float.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeInt`: Deserializes a deserializer's input data into a Getty Integer.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeMap`: Deserializes a deserializer's input data into a Getty Map.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeOptional`: Deserializes a deserializer's input data into a Getty Optional.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeSeq`: Deserializes a deserializer's input data into a Getty Sequence.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeString`: Deserializes a deserializer's input data into a Getty String.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeStruct`: Deserializes a deserializer's input data into a Getty Struct.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeUnion`: Deserializes a deserializer's input data into a Getty Union.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.

- `deserializeVoid`: Deserializes a deserializer's input data into a Getty Void.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `allocator`: An optional memory allocator.
        - `v`: A [`getty.de.Visitor`](/api/de/Visitor) interface value.
    - __Return__:
        - On success, a value produced by the visitor `v`.
        - On failure, an error in the error set `E`.
