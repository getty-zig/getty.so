# Deserializers

Every Getty deserializer implements the [`getty.Deserializer`](https://docs.getty.so/#A;getty:Deserializer) interface, shown below.

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
        deserializeAny: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeBool: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeEnum: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeFloat: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeIgnored: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeInt: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeMap: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeOptional: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeSeq: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeString: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeStruct: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeUnion: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
        deserializeVoid: ?fn (Context, std.mem.Allocator, v: anytype) E!@TypeOf(v).Value = null,
    },
) type
```

1.  A [`getty.Deserializer`](https://docs.getty.so/#A;getty:Deserializer) deserializes
    values from a __data format__ into Getty's __data model__.

2.  `Context` is a namespace that owns the method implementations passed to the
    `methods` parameter.

    Usually, this is the type implementing
    [`getty.Deserializer`](https://docs.getty.so/#A;getty:Deserializer) or a
    pointer to it if mutability is required.

3.  `E` is the error set returned by
    [`getty.Deserializer`](https://docs.getty.so/#A;getty:Deserializer)'s methods upon
    failure.

    The value of `E` must contain
    [`getty.de.Error`](https://docs.getty.so/#A;getty:de.Error), a base error set
    defined by Getty.

4.  `user_dbt` and `deserializer_dbt` are optional user- and deserializer-defined
    derialization blocks or tuples, respectively.

    They allow users and deserializers to customize Getty's deserialization
    behavior. If user- or deserializer-defined customization isn't supported,
    `null` can be passed in for these parameters.

5.  `methods` lists every method that a `Deserializer` must
    provide or can override.

6.  These methods are responsible for deserializing into a specific type in
    Getty's data model from a data format.

    The `v` parameter in these methods is a
    [`getty.de.Visitor`](https://docs.getty.so/#A;getty:de.Visitor) interface value.

    The `deserializeAny` and `deserializeIgnored` methods are pretty niche, so
    we can ignore them for this tutorial.

Quite the parameter list!

Luckily, most of the parameters have default values we can use. So let's kick
things off with the following implementation:

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

2.  A convenient alias for our [`getty.Deserializer`](https://docs.getty.so/#A;getty:Deserializer) interface type.

## Scalar Deserialization

To deserialize a value with our brand new `Deserializer`, we can call
[`getty.deserialize`](https://docs.getty.so/#A;getty:deserialize), which takes an
optional allocator, a type to deserialize into, and a
[`getty.Deserializer`](https://docs.getty.so/#A;getty:Deserializer) interface
value.

```zig title="<code>src/main.zig</code>" hl_lines="4 31-40"
const std = @import("std");
const getty = @import("getty");

const ally = std.heap.page_allocator;

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

pub fn main() !void {
    var d = Deserializer.init("true");
    const dd = d.deserializer();

    const result = try getty.deserialize(ally, bool, dd);
    defer result.deinit();
    const value = result.value;

    std.debug.print("{} ({})\n", .{ value, @TypeOf(value) });
}
```

```console title="Shell session"
$ zig build run
[...] error: deserializeBool is not implemented by type: *main.Deserializer
```

A compile error!

Looks like Getty can't deserialize into the `bool` type unless
`deserializeBool` is implemented. Let's fix that.

```zig title="<code>src/main.zig</code>" hl_lines="4 18 33-42"
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;
const ally = std.heap.page_allocator;

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
    fn deserializeBool(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(arena, De, token == .True);
            }
        }

        return error.InvalidType;
    }
};

pub fn main() !void {
    var d = Deserializer.init("true");
    const dd = d.deserializer();

    const result = try getty.deserialize(ally, bool, dd);
    defer result.deinit();
    const value = result.value;

    std.debug.print("{} ({})\n", .{ value, @TypeOf(value) });
}
```

1.  What we're doing in this function is:

    1. Parsing a token from the JSON data.
    2. Checking to see if the token is a JSON Boolean.
    3. Deserializing the token into a _Boolean_ (`token == .True`).
    4. Passing the _Boolean_ to the visitor, `v`.


```console title="Shell session"
$ zig build run
true (bool)
```

Success!

Now let's do the same thing for the other scalar types.

```zig title="<code>src/main.zig</code>" hl_lines="19-24 49-124 128-140"
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;
const ally = std.heap.page_allocator;

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

    fn deserializeBool(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(arena, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    // (1)!
    fn deserializeEnum(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(arena, De, str);
            }
        }

        return error.InvalidType;
    }

    fn deserializeFloat(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(arena, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeInt(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

                if (token.Number.is_integer) {
                    return try switch (str[0]) {
                        '-' => v.visitInt(arena, De, try std.fmt.parseInt(i64, str, 10)),
                        else => v.visitInt(arena, De, try std.fmt.parseInt(u64, str, 10)),
                    };
                }
            }
        }

        return error.InvalidType;
    }

    fn deserializeString(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(arena, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeVoid(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(arena, De);
            }
        }

        return error.InvalidType;
    }

    // (2)!
    fn deserializeOptional(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        const backup = self.tokens;

        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitNull(arena, De);
            }

            self.tokens = backup;
            return try v.visitSome(arena, self.deserializer());
        }

        return error.InvalidType;
    }
};

pub fn main() !void {
    const types = .{ i32, f32, []u8, enum { foo }, ?u8, void };
    const jsons = .{ "10", "10.0", "\"ABC\"", "\"foo\"", "null", "null" };

    inline for (jsons, 0..) |data, i| {
        var d = Deserializer.init(data);
        const dd = d.deserializer();

        const result = try getty.deserialize(ally, types[i], dd);
        defer result.deinit();
        const value = result.value;

        std.debug.print("{any} ({})\n", .{ value, @TypeOf(value) });
    }
}
```

1.  Just like in `deserializeBool`, all we're doing in these functions is
    parsing tokens, turning them into Getty values, and passing those values to
    a visitor.

    By the way, you'll see `token.X.slice` come up pretty often in our
    deserializer. All it's doing is getting the string that corresponds to our
    token from the JSON data.

2.  `deserializeOptional` is a bit different from the other methods. Instead of
    passing a Getty value to a visitor, you pass a deserializer to `visitSome`.
    The visitor will then restart the deserialization process using the
    optional's payload.

    You can think of this method as a place to do some pre-processing before
    deserializing an actual payload value.

```console title="Shell session"
$ zig build run
10 (i32)
1.0e+01 (f32)
{ 65, 66, 67 } ([]u8)
main.main__enum_1315.foo (main.main__enum_1315)
null (?u8)
void (void)
```

Easy peasy! :tada:

??? info "The `deserialize*` methods"

    When Getty calls `deserializeBool`, it is _not_ telling `Deserializer` that
    it should parse and deserialize a JSON Boolean from its input data.
    Instead, Getty is simply providing a __hint__ about the type that is being
    deserialized into. 

    That is, Getty is telling `Deserializer`, "_Hey, the type that the user is
    deserializing into can most likely be constructed from a Getty Boolean, so you
    should probably deserialize your input data into one_."

    What this means is that we don't have to limit ourselves to parsing only
    JSON Booleans in `deserializeBool`. We could, for instance, have
    `deserializeBool` support JSON numbers as well.

    ```zig title="Zig code"
    fn deserializeBool(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            // JSON Booleans -> Getty Booleans
            if (token == .True or token == .False) {
                return try v.visitBool(arena, De, token == .True);
            }

            // JSON Numbers -> Getty Booleans
            if (token == .Number) {
                if (token.Number.is_integer) {
                    const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                    const int = try std.fmt.parseInt(i64, str, 10);
                    return try v.visitBool(arena, De, int != 0);
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
type (or set of Zig types). That is, while _Booleans_ are represented by `bool`s
and _Integers_ are represented by any Zig integer type, there is no native data
type in Zig that can generically represent _Sequences_ or _Maps_.

This is where the aggregate deserialization interfaces come in. They represent
the aggregate types within Getty's data model (from a deserialization
perspective). There are four of them:

!!! info ""

    [`getty.de.SeqAccess`](https://docs.getty.so/#A;getty:de.SeqAccess)

    :  Represents a _Sequence_.

    [`getty.de.MapAccess`](https://docs.getty.so/#A;getty:de.MapAccess)

    :  Represents a _Map_.

    [`getty.de.UnionAccess`](https://docs.getty.so/#A;getty:de.UnionAccess), [`getty.de.VariantAccess`](https://docs.getty.so/#A;getty:de.VariantAccess)

    :  Represents a _Union_.

Let's start by implementing `deserializeSeq`, which uses the
[`getty.de.SeqAccess`](https://docs.getty.so/#A;getty:de.SeqAccess) interface.

??? info "getty.de.SeqAccess"

    ```zig title="Zig code"
    // (1)!
    fn SeqAccess(
        comptime Context: type,
        comptime E: type,
        comptime methods: struct {
            // (2)!
            nextElementSeed: ?fn (Context, ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value = null,
        },
    ) type
    ```

    1. A [`getty.de.SeqAccess`]() is responsible for deserializing elements of a _Sequence_ into Zig.

    1.  The `seed` parameter of `nextElementSeed` is a [`getty.de.Seed`](https://docs.getty.so/#A;getty:de.Seed)
        interface value, which allows for stateful deserialization.

        By default, Getty passes in
        [`getty.de.DefaultSeed`](https://docs.getty.so/#A;getty:de.DefaultSeed)
        `seed`. The default seed just calls
        [`getty.deserialize`](https://docs.getty.so/#A;getty:deserialize) and can
        therefore be used for stateless deserialization.

```zig title="<code>src/main.zig</code>" hl_lines="25 125-134 137-162 165-173"
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;
const ally = std.heap.page_allocator;

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

    fn deserializeBool(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(arena, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    fn deserializeEnum(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(arena, De, str);
            }
        }

        return error.InvalidType;
    }

    fn deserializeFloat(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(arena, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeInt(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

                if (token.Number.is_integer) {
                    return try switch (str[0]) {
                        '-' => v.visitInt(arena, De, try std.fmt.parseInt(i64, str, 10)),
                        else => v.visitInt(arena, De, try std.fmt.parseInt(u64, str, 10)),
                    };
                }
            }
        }

        return error.InvalidType;
    }

    fn deserializeString(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(arena, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeVoid(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(arena, De);
            }
        }

        return error.InvalidType;
    }

    fn deserializeOptional(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        const backup = self.tokens;

        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitNull(arena, De);
            }

            self.tokens = backup;
            return try v.visitSome(arena, self.deserializer());
        }

        return error.InvalidType;
    }

    fn deserializeSeq(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .ArrayBegin) {
                var sa = SeqAccess{ .de = self };
                return try v.visitSeq(arena, De, sa.seqAccess());
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

    fn nextElementSeed(self: *@This(), arena: Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        // Deserialize element.
        const element = seed.deserialize(arena, self.de.deserializer()) catch |err| {
            // End of input was encountered early.
            if (self.de.tokens.i - 1 >= self.de.tokens.slice.len) {
                return err;
            }

            return switch (self.de.tokens.slice[self.de.tokens.i - 1]) {
                ']' => null, // End of sequence was encountered.
                else => err, // Unexpected token was encountered.
            };
        };

        return element;
    }
};

pub fn main() !void {
    var d = Deserializer.init("[1,2,3]");
    const dd = d.deserializer();

    const result = try getty.deserialize(ally, std.ArrayList(i32), dd);
    defer result.deinit();
    const value = result.value;
    defer value.deinit();

    std.debug.print("{any} ({})\n", .{ value.items, @TypeOf(value) });
}
```

```console title="Shell session"
$ zig build run
{ 1, 2, 3 } (array_list.ArrayListAligned(i32,null))
```

Hooray!

Just like before, notice how we didn't have to write any iteration- or
access-related code specific to `std.ArrayList` or any other Zig type. We just
had to specify how JSON sequences (arrays) should be deserialized and
Getty took care of the rest!

Okay, that leaves us with `deserializeMap` and `deserializeUnion`. Let's
implement the former, which uses the
[`getty.de.MapAccess`](https://docs.getty.so/#A;getty:de.MapAccess) interface.

??? info "getty.de.MapAccess"

    ```zig title="Zig code"
    // (1)!
    fn MapAccess(
        comptime Context: type,
        comptime E: type,
        comptime methods: struct {
            nextKeySeed: ?fn (Context, ?std.mem.Allocator, seed: anytype) E!?@TypeOf(seed).Value = null,
            nextValueSeed: ?fn (Context, ?std.mem.Allocator, seed: anytype) E!@TypeOf(seed).Value = null,
        },
    ) type
    ```

    1. A [`getty.de.MapAccess`]() is responsible for deserializing entries of a _Map_ into Zig.

```zig title="<code>src/main.zig</code>" hl_lines="26 137-146 175-212 215-222"
const std = @import("std");
const getty = @import("getty");

const Allocator = std.mem.Allocator;
const ally = std.heap.page_allocator;

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
            .deserializeMap = deserializeMap,
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

    fn deserializeBool(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .True or token == .False) {
                return try v.visitBool(arena, De, token == .True);
            }
        }

        return error.InvalidType;
    }

    fn deserializeEnum(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(arena, De, str);
            }
        }

        return error.InvalidType;
    }

    fn deserializeFloat(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitFloat(arena, De, try std.fmt.parseFloat(f64, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeInt(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Number) {
                const str = token.Number.slice(self.tokens.slice, self.tokens.i - 1);

                if (token.Number.is_integer) {
                    return try switch (str[0]) {
                        '-' => v.visitInt(arena, De, try std.fmt.parseInt(i64, str, 10)),
                        else => v.visitInt(arena, De, try std.fmt.parseInt(u64, str, 10)),
                    };
                }
            }
        }

        return error.InvalidType;
    }

    fn deserializeString(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .String) {
                const str = token.String.slice(self.tokens.slice, self.tokens.i - 1);
                return try v.visitString(arena, De, try allocator.?.dupe(u8, str));
            }
        }

        return error.InvalidType;
    }

    fn deserializeVoid(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitVoid(arena, De);
            }
        }

        return error.InvalidType;
    }

    fn deserializeOptional(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        const backup = self.tokens;

        if (try self.tokens.next()) |token| {
            if (token == .Null) {
                return try v.visitNull(arena, De);
            }

            self.tokens = backup;
            return try v.visitSome(arena, self.deserializer());
        }

        return error.InvalidType;
    }

    fn deserializeSeq(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .ArrayBegin) {
                var sa = SeqAccess{ .de = self };
                return try v.visitSeq(arena, De, sa.seqAccess());
            }
        }

        return error.InvalidType;
    }

    fn deserializeMap(self: *Self, arena: Allocator, v: anytype) Error!@TypeOf(v).Value {
        if (try self.tokens.next()) |token| {
            if (token == .ObjectBegin) {
                var ma = MapAccess{ .de = self };
                return try v.visitMap(arena, De, ma.mapAccess());
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

    fn nextElementSeed(self: *@This(), arena: Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        const element = seed.deserialize(arena, self.de.deserializer()) catch |err| {
            // End of input was encountered early.
            if (self.de.tokens.i - 1 >= self.de.tokens.slice.len) {
                return err;
            }

            return switch (self.de.tokens.slice[self.de.tokens.i - 1]) {
                ']' => null, // End of sequence was encountered.
                else => err, // Unexpected token was encountered.
            };
        };

        return element;
    }
};

const MapAccess = struct {
    de: *Deserializer,

    pub usingnamespace getty.de.MapAccess(
        *@This(),
        Deserializer.Error,
        .{
            .nextKeySeed = nextKeySeed,
            .nextValueSeed = nextValueSeed,
        },
    );

    fn nextKeySeed(self: *@This(), arena: Allocator, seed: anytype) Deserializer.Error!?@TypeOf(seed).Value {
        const tokens = self.d.tokens;

        if (try self.d.tokens.next()) |token| {
            // End of map was encountered.
            if (token == .ObjectEnd) {
                return null;
            }

            // Key was encountered.
            if (token == .String) {
                // Restore key.
                self.de.tokens = tokens;

                // Deserialize key.
                return try seed.deserialize(arena, self.de.deserializer());
            }
        }

        return error.InvalidType;
    }

    fn nextValueSeed(self: *@This(), arena: Allocator, seed: anytype) Deserializer.Error!@TypeOf(seed).Value {
        return try seed.deserialize(arena, self.d.deserializer());
    }
};

pub fn main() !void {
    var d = Deserializer.init("\"x\":1,\"y\":2");
    const dd = d.deserializer();

    const result = try getty.deserialize(ally, struct{ x: i32, y: i32 }, dd);
    defer result.deinit();
    const value = result.value;

    std.debug.print("{any} ({})\n", .{ value, @TypeOf(value) });
}
```

1.  What we're doing here is telling Getty to perform deserialization again (by
    calling `seed.deserialize`) so that we can deserialize an element from the
    deserializer's input data.

    If there are no elements left (i.e., if `]` was encountered) then `null` is
    returned. Otherwise, the deserialized element is.

    The `seed` parameter of `nextElementSeed` is a [`getty.de.Seed`](https://docs.getty.so/#A;getty:de.Seed)
    interface value, which allows for stateful deserialization. We don't
    really need that for this tutorial, but we can still use `seed` since
    the default seed of Getty just calls [`getty.deserialize`](https://docs.getty.so/#A;getty:deserialize).

```console title="Shell session"
$ zig build run
{ 1, 2, 3 } (array_list.ArrayListAligned(i32,null))
```
