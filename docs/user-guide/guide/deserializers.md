# Deserializers

Let's write a simple (albeit slightly naive) JSON deserializer.

!!! warning "Prerequisites"

    This page assumes you understand how Getty interfaces work. If not, take a
    few minutes to learn about them [here](/user-guide/concepts/interfaces/).

## Prologue

To begin, we'll go over how deserialization works in Getty.

<figure markdown>

![Deserialization](/assets/images/deserialization-light.svg#only-light)
![Deserialization](/assets/images/deserialization-dark.svg#only-dark)

</figure>

1. A Zig type is passed to Getty.
2. Based on the type, a [deserialization block](/user-guide/concepts/blocks-and-tuples) is
   selected and executed by Getty.
3. The DB prompts a [Deserializer](https://docs.getty.so/#root;Deserializer)
   to deserialize its input data into Getty's [data
   model](/user-guide/concepts/data-models).

    - This is done by calling one of the deserializer's methods (e.g., `deserializeBool`).

4. The resulting value is passed to a
   [Visitor](https://docs.getty.so/#root;de.Visitor), which converts it into a
   Zig value of the initial type.

    - This is done by calling one of the visitor's methods (e.g., `visitBool`).

??? example

    Here's how deserializing a `#!zig std.ArrayList(i32)` works:

    1. `#!zig std.ArrayList(i32)` is passed to Getty.
    2. Getty selects and executes the
       [`getty.de.blocks.ArrayList`](https://github.com/getty-zig/getty/blob/main/src/de/blocks/array_list.zig)
       deserialization block.
    3. The DB prompts a [Deserializer](https://docs.getty.so/#root;Deserializer) to deserialize its input data into a _Sequence_.
    4. The resulting _Sequence_ is passed to a [Visitor](https://docs.getty.so/#root;de.Visitor), which converts it into a `#!zig std.ArrayList(i32)`.

!!! warning "TL;DR"

    - _Deserializers_ deserialize from a __data format__ into Getty's __data model__.
    - _Visitors_ deserialize from Getty's __data model__ into __Zig__.

## Scalar Deserialization

Every Getty deserializer must implement the
[`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) interface,
shown below.

```zig title="Zig code"
// (1)!
fn Deserializer(
    comptime Context: type, // (2)!
    comptime E: type, // (3)!

    // (4)!
    comptime user_dbt: anytype,
    comptime deserializer_dbt: anytype,

    // (5)!
    comptime methods: struct {
        // (6)!
        deserializeAny: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeBool: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeEnum: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeFloat: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeIgnored: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeInt: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeMap: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeOptional: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeSeq: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeString: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeStruct: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeUnion: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeVoid: ?fn (Context, ?std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
    },
) type
```

1.  A [`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) deserializes
    values from a data format into Getty's data model.

2.  `Context` is the namespace that owns the method implementations passed to
    the `methods` parameter.

    Usually, this is the type implementing
    [`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) or a
    pointer to it if mutability is required.

3.  `E` is the error set returned by
    [`getty.Deserializer`](https://docs.getty.so/#root;Deserializer)'s methods upon
    failure.

    The value of `E` must contain
    [`getty.de.Error`](https://docs.getty.so/#root;de.Error), a base error set
    defined by Getty.

4.  `user_dbt` and `deserializer_dbt` are optional user- and deserializer-defined
    derialization blocks or tuples, respectively.

    They allow users and deserializers to customize Getty's deserialization
    behavior. If user- or deserializer-defined customization isn't supported,
    `null` can be passed in for these parameters.

5.  `methods` contains all of the methods that implementations of
    [`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) must
    provide or can override.

6.  These methods are responsible for deserializing into a specific type in
    Getty's data model from a data format.

    The `v` parameter in these methods is a
    [`getty.de.Visitor`](https://docs.getty.so/#root;de.Visitor) interface value.

    The `deserializeAny` and `deserializeIgnored` methods are pretty niche, so
    we'll just ignore them for this tutorial.

Quite the parameter list!

Luckily, most of the parameters have default values we can use. So, let's
start with the following:

```zig title="<code>src/main.zig</code>"
const std = @import("std");
const getty = @import("getty");

const Deserializer = struct {
    tokens: std.json.TokenStream, // (1)!

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        null,
        null,
        .{},
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer"; // (2)!

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }
};
```

1.  A JSON parser provided by the standard library.

2.  A convenient alias for our [`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) interface type.

Bit of a useless deserializer, but let's try deserializing a value with it
anyways. We can do so by calling
[`getty.deserialize`](https://docs.getty.so/#root;deserialize), which takes an
optional allocator, a type to deserialize into, and a
[`getty.Deserializer`](https://docs.getty.so/#root;Deserializer) interface
value.

```zig title="<code>src/main.zig</code>" hl_lines="29-38"
const std = @import("std");
const getty = @import("getty");

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        null,
        null,
        .{},
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }
};

pub fn main() anyerror!void {
    const s = "true";

    var d = Deserializer.init(s);
    const deserializer = d.deserializer();

    const v = try getty.deserialize(null, bool, deserializer);

    std.debug.print("{} ({})\n", .{ v, @TypeOf(v) });
}
```

```console title="Shell session"
$ zig build run
[...] error:  deserializeBool is not implemented by type: *main.Deserializer
```

Oh no, a compile error!

Looks like Getty can't deserialize into the `#!zig bool` type for us unless
the `deserializeBool` method is implemented. So, let's implement it real quick.

```zig title="<code>src/main.zig</code>" hl_lines="4 17 33-41"
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        null,
        null,
        .{
            .deserializeBool = deserializeBool,
        },
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }

    // (1)!
    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }
};

pub fn main() anyerror!void {
    const s = "true";

    var d = Deserializer.init(s);
    const deserializer = d.deserializer();

    const v = try getty.deserialize(null, bool, deserializer);

    std.debug.print("{} ({})\n", .{ v, @TypeOf(v) });
}
```

1.  All we're doing in this function is:

    1. Parsing a token from the JSON data.
    2. Checking to see if the token is a JSON Boolean.
    3. Deserializing the token into a _Boolean_ (`token == .True`).
    4. Passing the _Boolean_ to the visitor, `v`.


```console title="Shell session"
$ zig build run
true (bool)
```

Success!

<!--With that in mind, let's talk about deserializeBool. This method serves-->
<!--as a *hint* to our deserializer that the Visitor v will (most likely)-->
<!--produce a Boolean value.-->

<!--Using this hint, our deserializeBool implementation will try to parse-->
<!--a Boolean from the deserializer's input. After all, if the visitor is-->
<!--trying to make a Boolean value, it doesn't make sense to parse a float-->
<!--or string.-->

Now let's do the same thing for `deserializeEnum`, `deserializeFloat`, `deserializeInt`, `deserializeOptional`, `deserializeString`, and `deserializeVoid`.

```zig title="<code>src/main.zig</code>" linenums="1" hl_lines="18-23 48-123 127-141"
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        null,
        null,
        .{
            .deserializeBool = deserializeBool,
            .deserializeEnum = deserializeEnum,
            .deserializeFloat = deserializeFloat,
            .deserializeInt = deserializeInt,
            .deserializeString = deserializeString,
            .deserializeVoid = deserializeVoid,
            .deserializeOptional = deserializeOptional,
        },
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }

    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    // (1)!
    fn deserializeEnum(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, str);
            }
        }

        return error.InvalidType;
    }

    fn deserializeFloat(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(allocator, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeInt(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

                if (token.Number.is_integer) {
                    return try switch (str[0]) {
                        '-' => v.visitInt(allocator, De, try std.fmt.parseInt(i64, str, 10)),
                        else => v.visitInt(allocator, De, try std.fmt.parseInt(u64, str, 10)),
                    };
                }
            }
        }

        return error.InvalidType;
    }

    fn deserializeString(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeVoid(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(allocator, De);
            }
        }

        return error.InvalidType;
    }

    // (2)!
    fn deserializeOptional(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        const backup = self.tokens;

        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitNull(allocator, De);
            }

            self.tokens = backup;
            return try v.visitSome(allocator, self.deserializer());
        }

        return error.InvalidType;
    }
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;
    const types = .{ i32, f32, []u8, enum { foo }, ?u8, void };
    const jsons = .{ "10", "10.0", "\"ABC\"", "\"foo\"", "null", "null" };

    inline for (jsons) |s, i| {
        const T = types[i];

        var d = Deserializer.init(s);
        const deserializer = d.deserializer();

        const v = try getty.deserialize(allocator, T, deserializer);
        defer getty.de.free(allocator, v);

        std.debug.print("{any} ({})\n", .{ v, @TypeOf(v) });
    }
}
```

1.  Just like in `deserializeBool`, all we're doing here is parsing tokens,
    turning them into Getty values, and passing those values to a visitor.

    By the way, you'll see `token.X.slice` come up pretty often in our
    deserializer. All it's doing is getting the string that corresponds to our
    token from the JSON data.

2.  `deserializeOptional` is a bit different from the other methods. Instead of
    passing a Getty value to a visitor, you pass a deserializer to `visitSome`.
    The visitor will then restart the deserialization process using the
    optional's payload.

    In other words, you can think of this method as a place to do some
    pre-processing before deserializing an actual payload value.

```console title="Shell session"
$ zig build run
10 (i32)
1.0e+01 (f32)
{ 65, 66, 67 } ([]u8)
main.main__enum_1315.foo (main.main__enum_1315)
null (?u8)
void (void)
```

Not too shabby! 🤩

??? info "The `deserialize*` methods"

    When Getty calls `deserializeBool`, it is _not_ telling `Deserializer` that
    it should parse and deserialize a JSON Boolean from its input data.
    Instead, Getty is simply providing a __hint__ about the type that is being
    deserialized into. 

    In other words, Getty is telling `Deserializer`, "_Hey, the type that the
    user is deserializing into can probably be constructed from a Getty
    Boolean, so you should probably deserialize your input data into one_."

    What this means is that you don't have to limit yourself to parsing only
    JSON Booleans in `deserializeBool`. We could, for instance, have it support
    JSON numbers as well.

    ```zig title="Zig code"
    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            // JSON Booleans -> Getty Booleans
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }

            // JSON Numbers -> Getty Booleans
            if (token == .Number) {
                if (token.Number.is_integer) {
                    const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                    return try v.visitBool(allocator, De, try std.fmt.parseInt(i64, str, 10) != 0);
                }
            }
        }

        return error.InvalidType;
    }
    ```

## Aggregate Deserialization

Alright, now let's take a look at deserialization for aggregate types.

The difference between scalar and aggregate deserialization is that the
aggregate types in Getty's data model do not directly map to any particular Zig
type (or set of Zig types). That is, while _Booleans_ are represented by `#!zig
bool`s and _Integers_ are represented by any Zig integer type, there's no
native data type in Zig that is able to generically represent _Sequences_ or _Maps_.

This is where the aggregate deserialization interfaces come in. They represent
the aggregate types in Getty's data model. There are four of them in total:

!!! info ""

    [`getty.de.SeqAccess`](https://docs.getty.so/#root;de.SeqAccess)

    :  Represents a _Sequence_.

    [`getty.de.MapAccess`](https://docs.getty.so/#root;de.MapAccess)

    :  Represents a _Map_.

    [`getty.de.UnionAccess`](https://docs.getty.so/#root;de.UnionAccess), [`getty.de.VariantAccess`](https://docs.getty.so/#root;de.VariantAccess)

    :  Represents a _Union_.

Let's start by implementing `deserializeSeq`, which uses the
[`getty.de.SeqAccess`](https://docs.getty.so/#root;de.SeqAccess) interface.

??? info "getty.de.SeqAccess"

    ```zig title="Zig code"
    fn SeqAccess(
        comptime Context: type,
        comptime E: type,
        comptime methods: struct {
            nextElementSeed: ?fn (Context, ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value = null,
        },
    ) type
    ```

```zig title="<code>src/main.zig</code>" linenums="1" hl_lines="24 124-133 136-160 165-169"
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;

const Deserializer = struct {
    tokens: std.json.TokenStream,

    const Self = @This();

    pub usingnamespace getty.Deserializer(
        *Self,
        Error,
        null,
        null,
        .{
            .deserializeBool = deserializeBool,
            .deserializeEnum = deserializeEnum,
            .deserializeFloat = deserializeFloat,
            .deserializeInt = deserializeInt,
            .deserializeString = deserializeString,
            .deserializeVoid = deserializeVoid,
            .deserializeOptional = deserializeOptional,
            .deserializeSeq = deserializeSeq,
        },
    );

    const Error = getty.de.Error ||
        std.json.TokenStream.Error ||
        std.fmt.ParseIntError ||
        std.fmt.ParseFloatError;

    const De = Self.@"getty.Deserializer";

    pub fn init(json: []const u8) Self {
        return .{ .tokens = std.json.TokenStream.init(json) };
    }

    fn deserializeBool(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(allocator, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    fn deserializeEnum(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, str);
            }
        }

        return error.InvalidType;
    }

    fn deserializeFloat(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(allocator, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeInt(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

                if (token.Number.is_integer) {
                    return try switch (str[0]) {
                        '-' => v.visitInt(allocator, De, try std.fmt.parseInt(i64, str, 10)),
                        else => v.visitInt(allocator, De, try std.fmt.parseInt(u64, str, 10)),
                    };
                }
            }
        }

        return error.InvalidType;
    }

    fn deserializeString(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(allocator, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeVoid(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(allocator, De);
            }
        }

        return error.InvalidType;
    }

    fn deserializeOptional(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        const backup = self.tokens;

        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitNull(allocator, De);
            }

            self.tokens = backup;
            return try v.visitSome(allocator, self.deserializer());
        }

        return error.InvalidType;
    }

    fn deserializeSeq(self: *Self, allocator: ?Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .ArrayBegin) {
                var sa = SeqAccess{ .de = self };
                return try v.visitSeq(allocator, De, sa.seqAccess());
            }
        }

        return error.InvalidType;
    }
};

const SeqAccess = struct {
    de: *Deserializer,

    pub usingnamespace getty.de.SeqAccess(
        *@This(),
        Deserializer.Error,
        .{ .nextElementSeed = nextElementSeed },
    );

    // (1)!
    fn nextElementSeed(self: *@This(), allocator: ?Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        const element = seed.deserialize(allocator, self.de.deserializer()) catch |err| {
            if (self.de.tokens.i - 1 >= self.de.tokens.slice.len) {
                return err;
            }

            return switch (self.de.tokens.slice[self.de.tokens.i - 1]) {
                ']' => null,
                else => err,
            };
        };

        return element;
    }
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var d = Deserializer.init("[1,2,3]");
    const deserializer = d.deserializer();

    const v = try getty.deserialize(allocator, std.ArrayList(i32), deserializer);
    defer getty.de.free(allocator, v);

    std.debug.print("{any} ({})\n", .{ v.items, @TypeOf(v) });
}
```

1.  You can ignore all of the parsing-related code in this function.

    All we're doing is telling Getty to perform deserialization again (by
    calling `seed.deserialize`) so that we can deserialize an element from the
    deserializer's input data.

    If there are no elements left (i.e., if `]` was encountered) then `null` is
    returned. Otherwise, the deserialized element is.

```console title="Shell session"
$ zig build run
{ 1, 2, 3 } (array_list.ArrayListAligned(i32,null))
```

Hooray!

*[DB]: Deserialization Block
*[DBTs]: Deserialization Blocks or Tuples
