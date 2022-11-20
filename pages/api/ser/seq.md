---
title: Seq
category: api
layout: default
permalink: /api/ser/Seq/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.ser.Seq`

## Description

`getty.ser.Seq` is an interface that specifies how to serialize Getty Sequences.

## Synopsis

{% label Zig code %}
{% highlight zig %}
fn Seq(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeElement: ?fn (Context, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type
{% endhighlight %}
{% endlabel %}

### Parameters

- `Context`: The namespace that owns the method implementations you provide in `methods`.

- `O`: The return type for `getty.ser.Seq`'s `end` method.

- `E`: The error set returned by `getty.ser.Seq`'s methods upon failure.

- `methods`: A namespace containing every method that `getty.ser.Seq` implementations can implement.

### Required Methods

- `serializeElement`: Serializes an element in a Getty Sequence.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `value`: An element to serialize.
    - __Return__:
        - On success, `void`.
        - On failure, an error in the error set `E`.

- `end`: Ends the serialization process for a Getty Sequence.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.
