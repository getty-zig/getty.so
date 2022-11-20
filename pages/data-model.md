---
title: Data Models
category: Concept
layout: default
permalink: /data-models/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Data Models

A data model represents the set of types supported by Getty. The types within a
data model are purely conceptual; they aren't actually Zig types. For example,
there isn't an `i32` or `u64` in any of Getty's data models. Instead, `i32` and
`u64` are both considered to the same type: _Integer_.

By maintaining a data model, Getty establishes a generic baseline from which
(de)serializers operate. This often simplifies the job of a (de)serializer
significantly. For example, Zig considers `[]i32` and `std.ArrayList(i32)` to
be different types, meaning that you'd need to write unique serialization logic
for both. However, in Getty they are both considered to be the same type:
_Sequence_. This means that a Getty serializer only has to specify how to
serialize two types: _Integers_ and _Sequences_, and they'll automatically be
able to serialize `[]i32` values, `std.ArrayList(i32)` values, and values of
any other type that is supported by Getty and is considered to be a _Sequence_.

In other words, Getty's data models act as an interface between data formats and Zig.

<img alt="Data Model" src="/assets/images/data-model.svg" class="figure-small" />

## Serialization Data Model

Getty's serialization data model consists of the following types:

- Boolean
- Enum
- Float
- Integer
- Map
- Null
- Sequence
- Some
- String
- Structure
- Void


## Deserialization Data Model

Getty's deserialization data model consists of the following types:

- Boolean
- Enum
- Float
- Integer
- Map
- Optional
- Sequence
- String
- Structure
- Union
- Void

