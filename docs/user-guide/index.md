# User Guide

If you've ever written a Zig (de)serializer before, you probably wrote a
function that took a value, switched on its type, and (de)serialized based on
the resulting type information. You might have even called it
[`std.json`](https://ziglang.org/documentation/master/std/#root;json), as
that's exactly how the module works! Unfortunately, this approach is quite
brittle, inflexible, and usually ends up being a lot of unnecessary work.

The goal of Getty is to help you avoid all of that and reduce the amount of
code you need to write a (de)serializer that is customizable, performant, and
able to support a wide variety of data types!

## Architecture

At a high-level, Getty consists of two flows: one for serialization and another for deserialization.

=== "Serialization"

    1. A Zig value is passed to Getty.
    2. Based on the value's type, a [serialization block](/user-guide/design/blocks-and-tuples) is selected and executed by Getty.
    3. The block serializes the passed-in value into Getty's [data model](/user-guide/design/data-models).
    4. The resulting value is passed to a [Serializer](https://docs.getty.so/#root;Serializer), which serializes it into an output data format.

=== "Deserialization"

    1. A Zig type is passed to Getty.
    2. Based on the type, a [deserialization block](/user-guide/design/blocks-and-tuples) is selected and executed by Getty.
    3. The block prompts a [Deserializer](https://docs.getty.so/#root;Deserializer) to deserialize its input data into Getty's [data model](/user-guide/design/data-models).
    4. The resulting value is passed to a [Visitor](https://docs.getty.so/#root;de.Visitor), which converts it into a Zig value of the initial type.

<figure markdown>

![Architecture](/assets/images/architecture-light.svg#only-light)
![Architecture](/assets/images/architecture-dark.svg#only-dark)

</figure>
