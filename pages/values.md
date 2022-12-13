---
title: Values
category: Concept
layout: default
permalink: /values/
SPDX-License-Identifier: LGPL-2.1-or-later
---

# Values

## Serialization

How a Zig value is represented within a data format is determined entirely by whichever Getty serializer you use. Therefore, it's important that you check how a serialization library is handling things before you start using it. As an example, here's how the [Getty JSON](https://github.com/getty-zig/json/) library does things:

{% label Zig code %}
{% highlight zig %}
const a = {};                        // void is represented as null
const b = .foobar;                   // enums are represented as "foobar"
const C = union(enum) { foo: i32 };
const c = U{ .foo = 1 };             // tagged unions are represented as {"foo":1}
const d = .{ 1, 2, 3 };              // tuples are represented as [1,2,3]
const e = .{ .x = 1, .y = 2 };       // structs are represented as {"x":1,"y":2}
{% endhighlight %}
{% endlabel %}
 
## Deserialization

Similarly, it is up to a Getty deserializer to determine how values within a data format should be parsed and deserialized into Getty's data model. For instance, the [Getty JSON](https://github.com/getty-zig/json/) library has no issues converting the JSON object `{"foo":1}` into a tagged union. However, other deserializers may expect something different from their input data when deserializing into a union value.
