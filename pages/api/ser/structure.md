---
title: Structure
category: api
layout: default
permalink: /api/ser/Structure/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# `getty.ser.Structure`

## Description

`getty.ser.Structure` is an interface that specifies how to serialize Getty Structures.

## Synopsis

{% label Zig code %}
{% highlight zig %}
fn Structure(
    comptime Context: type,
    comptime O: type,
    comptime E: type,
    comptime methods: struct {
        serializeField: ?fn (Context, comptime []constu8, anytype) E!void = null,
        end: ?fn (Context) E!O = null,
    },
) type
{% endhighlight %}
{% endlabel %}

### Interface

- `@"getty.ser.Structure"`: Interface type.
- `structure`: Interface function.

### Parameters

- `Context`: The namespace that owns the method implementations you provide in `methods`.

- `O`: The return type for `getty.ser.Structure`'s `end` method.

- `E`: The error set returned by `getty.ser.Structure`'s methods upon failure.

- `methods`: A namespace containing every method that `getty.ser.Structure` implementations can implement.

### Required Methods

- `serializeField`: Serializes a field in a Getty Structure.

    - __Parameters__:
        - `context`: A value of type `Context`.
        - `name`: A name for the field being serialized.
        - `value`: A field to serialize.
    - __Return__:
        - On success, `void`.
        - On failure, an error in the error set `E`.

- `end`: Ends the serialization process for a Getty Structure.

    - __Parameters__:
        - `context`: A value of type `Context`.
    - __Return__:
        - On success, a value of type `O`.
        - On failure, an error in the error set `E`.
