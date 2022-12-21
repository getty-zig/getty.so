# Getting Started

Getty is a framework that helps you build (de)serializers in Zig.

Typically, Zig (de)serializers are written as functions that take a value, switch on its type, and (de)serialize based on the resulting type information. In fact, this is exactly what `std.json` does. Unfortunately, this approach is quite brittle, inflexible, and ends up being a lot of unnecessary work.

The goal of Getty is to help you avoid all of that and reduce the amount of code you need to write a (de)serializer that is customizable, performant, and able to support a wide variety of data types out of the box!

## Architecture

At a high-level, Getty consists of two flows: a __serialization flow__ and a __deserialization flow__.

In the serialization flow, a Zig value is passed to Getty and, based on its type, a [Serialization Block](/blocks-and-tuples) is selected and executed by Getty, serializing the passed-in value into Getty's serialization [data model](/data-models). The resulting Getty value is then passed to a serializer, which serializes it into an output data format.

In the deserialization flow, a Zig type is passed to Getty and, based on the type, a [Deserialization Block](/blocks-and-tuples) is selected and executed by Getty, prompting a deserializer to deserialize its input data into Getty's deserialization [data model](/data-models). The resulting Getty value is then passed to a Visitor, where it is converted into a Zig value of the initial type.

<figure markdown>

![Architecture](/assets/images/architecture-light.svg#only-light)
![Architecture](/assets/images/architecture-dark.svg#only-dark)

</figure>
