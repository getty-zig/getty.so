---
title: Data Models
category: Concept
layout: default
permalink: /data-models/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Data Models

Getty defines two data models: one for serialization and one for deserialization.

A data model represents the set of types supported by Getty. The types within a
data model are purely conceptual; they aren't actually Zig types. For example,
there isn't an `i32` or `u64` in either of Getty's data models. Instead, `i32` and
`u64` are both considered to the same type: _Integer_.

By maintaining a data model, Getty establishes a generic baseline from which
(de)serializers operate. This often simplifies the job of a (de)serializer
significantly. For example, Zig considers `[]i32` and `std.ArrayList(i32)` to
be different types, meaning that you'd need to write unique serialization logic
for slices, `std.ArrayList`s, and integers. In contrast, Getty considers both
types to be the same: they are both _Sequences_. This means that a Getty
serializer only has to specify how to serialize two types: _Integers_ and
_Sequences_. By doing so, they'll automatically be able to serialize `[]i32`
and `std.ArrayList(i32)` values, as well as any other value whose type is
supported by Getty and is considered a _Sequence_, including `[5]u128`,
`std.BoundedArray`, `std.TailQueue`, and more!

In other words, Getty's data models act as an interface between data formats and Zig:

- Serializers receive values from Getty's data model and serialize them into a data format.
- Deserializers receive values from a data format and deserialize them into Getty's data model.

<img alt="Data Model" src="/assets/images/data-model.svg" class="figure-small" />

## Serialization Data Model

Getty's serialization data model consists of the following types:

- **Boolean**
- **Enum**
- **Float**
- **Integer**
- **Map**
- **Null**
- **Sequence**
- **Some**
- **String**
- **Structure**
- **Void**

## Deserialization Data Model

Getty's deserialization data model consists of the following types:

- **Boolean**
- **Enum**
- **Float**
- **Integer**
- **Map**
- **Optional**
- **Sequence**
- **String**
- **Structure**
- **Union**
- **Void**
