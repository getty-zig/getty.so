# Values

## Serialization

How a Zig value is represented within a data format is determined entirely by
whichever Getty serializer you use. Therefore, it's important that you check
how a serialization library is handling things before you start using it. As an
example, here's how the [Getty JSON](https://github.com/getty-zig/json/)
library does things:

```zig title="Shell session"
const a = {};                        // serialized as null
const b = "foobar";                  // serialized as "foobar"
const c = .foobar;                   // serialized as "foobar"
const d = .{ 1, 2, 3 };              // serialized as [1,2,3]
const e = .{ .x = 1, .y = 2 };       // serialized as {"x":1,"y":2}
const F = union(enum) { foo: i32 };
const f = U{ .foo = 1 };             // serialized as {"foo":1}
```
 
## Deserialization

Similarly, it is up to a Getty deserializer to determine how values within a
data format should be parsed and deserialized. For instance, the [Getty
JSON](https://github.com/getty-zig/json/) library has no issues converting the
JSON object `#!json {"foo":1}` into a tagged union. However, other
deserializers may expect something different from their input data when
deserializing into a union value.
