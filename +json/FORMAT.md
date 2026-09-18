# The `json.mdumps` wire format

## Why it exists

JSON has one array type; MATLAB has two (numeric and cell), plus a class and a
shape on every value. So `jsonencode`/`jsondecode` alone cannot round-trip a
MATLAB value: `[1 2 3]` and `{1,2,3}` both encode to `[1,2,3]`, a `2x3` matrix
comes back as `6x1`, `single` comes back as `double`, and `NaN`/`Inf` both
become `null`.

The fix is to carry a small sidecar of type and shape information next to
plain JSON data:

```json
{"fmt":2, "order":"F", "base":1, "vals": <data>, "info": [<entry>, ...]}
```

Two properties matter and are worth preserving in any future change:

1. **`vals` is plain, idiomatic JSON.** A reader in Python, R or Julia can
   `json.loads` it and use it directly, ignoring `info` completely. That is
   how most analysis code in the lab reads these rows and it must keep working.
2. **`info` is flat.** It is a list, not a tree mirroring `vals`. Rebuilding
   the exact MATLAB value is a loop over that list, not a recursive walk that
   has to reimplement MATLAB's cell semantics. This is what makes a faithful
   reader in a new language about 50 lines instead of a research project.

## Top level

| key     | meaning                                                          |
|---------|------------------------------------------------------------------|
| `fmt`   | format version. Always `2`. Format 1 payloads have no `fmt` key. |
| `order` | flattening order for array leaves. Always `"F"` (column-major).  |
| `base`  | index base used in `info` paths. Always `1`.                     |
| `vals`  | the data, as plain JSON.                                         |
| `info`  | flat list of per-node type/shape records, in pre-order.          |

## `vals` encoding

| MATLAB                    | JSON                                                        |
|---------------------------|-------------------------------------------------------------|
| numeric / logical array   | flat array of numbers (or `true`/`false`), column-major     |
| numeric scalar            | a bare number                                               |
| `NaN`, `Inf`, `-Inf`      | `null` (which one it was is recorded in `info`, see `nf`)    |
| `char`                    | one JSON string of the column-major-flattened characters    |
| `string` array            | array of JSON strings, column-major                         |
| `cell`                    | JSON array, elements in column-major order                  |
| scalar `struct`           | JSON object                                                 |
| `struct` array            | JSON array of JSON objects, column-major                    |
| any empty container/array | `[]` (`""` for empty char)                                  |

**`order` is not a formality.** Leaves are flattened column-major, because
that is MATLAB's own linear order. Julia and R are column-major too, so their
natural `reshape`/`array` calls are correct as-is. **NumPy is row-major**, so a
Python reader must pass `order='F'`:

```python
np.array(vals).reshape(dims, order='F')   # correct
np.array(vals).reshape(dims)              # SILENTLY TRANSPOSED
```

## `info` entries

One entry per node, in **pre-order depth-first** order: a node, then its
children left to right. A faithful reader can therefore just walk the list
with a cursor and never look at `p` at all; `p` is there so that other
languages can index straight to a node without rebuilding anything.

| key  | required | meaning                                                            |
|------|----------|--------------------------------------------------------------------|
| `p`  | yes      | path from the root, as a list of segments                          |
| `t`  | yes      | MATLAB class: `double`, `single`, `int8`...`uint64`, `logical`, `char`, `string`, `cell`, `struct` |
| `d`  | yes      | `size()` as a list of at least 2 dimensions                        |
| `f`  | structs  | field names, in order                                             |
| `nf` | sometimes| non-finite positions, `{"i":[...], "k":["NaN"\|"Inf"\|"-Inf"]}`     |
| `s`  | sometimes| exact decimal strings for 64-bit ints beyond 2^53                  |
| `as` | sometimes| `"struct"` when `t` is a classdef class stored as its struct contents |

`p` is the path you would use to index into `vals` in the raw JSON: a string
segment selects an object key, an integer segment selects a 1-based array
element. Segments are a list rather than a delimited string so that field
names never need escaping.

`f` is stored for every struct node. It pins field order, and it is the only
way to recover the field names of a `0x0` struct (whose `vals` is just `[]`).

`nf.i` holds 1-based linear indices into the column-major flattened leaf.
`jsonencode` writes `null` for `NaN`, `Inf` and `-Inf` alike, so without this
the three are indistinguishable. Note that `null` also appears where a reader
would naturally produce a NaN, so a reader that ignores `nf` still gets
sensible (if less precise) numbers.

`s` exists because a JSON number is read back through a double by
`jsondecode`, which loses integers above 2^53. Python and Julia parse big
integer literals exactly, so their readers can use `vals` directly and treat
`s` as a cross-check; MATLAB needs it.

## Worked examples

A scalar:

```json
{"fmt":2,"order":"F","base":1,"vals":1,
 "info":[{"p":[],"t":"double","d":[1,1]}]}
```

A nested struct — note `vals` is exactly what you would have written by hand:

```json
{"fmt":2,"order":"F","base":1,
 "vals":{"foo":1,"bar":{"t":[1,2,3,4],"d":"a char array"},"nerf":[1,2,3]},
 "info":[{"p":[],"t":"struct","d":[1,1],"f":["foo","bar","nerf"]},
         {"p":["foo"],"t":"double","d":[1,1]},
         {"p":["bar"],"t":"struct","d":[1,1],"f":["t","d"]},
         {"p":["bar","t"],"t":"double","d":[2,2]},
         {"p":["bar","d"],"t":"char","d":[1,12]},
         {"p":["nerf"],"t":"double","d":[1,3]}]}
```

A cell of cells. In MATLAB `jsondecode` collapses `[[1,2],[3,4]]` into a 2x2
numeric block; in Python/R/Julia the parser hands you the nesting as written,
which is why the non-MATLAB readers are simpler:

```json
{"fmt":2,"order":"F","base":1,"vals":[[1,2],[3,4]],
 "info":[{"p":[],"t":"cell","d":[1,2]},
         {"p":[1],"t":"cell","d":[1,2]},
         {"p":[1,1],"t":"double","d":[1,1]},
         {"p":[1,2],"t":"double","d":[1,1]},
         {"p":[2],"t":"cell","d":[1,2]},
         {"p":[2,1],"t":"double","d":[1,1]},
         {"p":[2,2],"t":"double","d":[1,1]}]}
```

A struct array — a JSON array of objects, so element indices appear in `p`:

```json
{"fmt":2,"order":"F","base":1,"vals":[{"a":1,"b":"x"},{"a":2,"b":"yy"}],
 "info":[{"p":[],"t":"struct","d":[1,2],"f":["a","b"]},
         {"p":[1,"a"],"t":"double","d":[1,1]},
         {"p":[1,"b"],"t":"char","d":[1,1]},
         {"p":[2,"a"],"t":"double","d":[1,1]},
         {"p":[2,"b"],"t":"char","d":[1,2]}]}
```

Non-finite values:

```json
{"fmt":2,"order":"F","base":1,"vals":[1,null,null,null],
 "info":[{"p":[],"t":"double","d":[1,4],
          "nf":{"i":[2,3,4],"k":["NaN","Inf","-Inf"]}}]}
```

A 2-D char array, flattened column-major into one string:

```json
{"fmt":2,"order":"F","base":1,"vals":"adbecf",
 "info":[{"p":[],"t":"char","d":[2,3]}]}
```

## Not supported

These raise an error in `json.mdumps` rather than silently storing something
wrong: complex, sparse, `function_handle`, `datetime`, `duration`,
`categorical`, `table`, `timetable`, `containers.Map`, `dictionary`, and
`<missing>` string values. Other classdef objects are stored as their
`struct()` contents with the real class name in `t` and `as:"struct"`; they
come back as plain structs.

## Storing this in MariaDB

* A `TEXT` column holds 65,535 **bytes**. A `100x100` double is about 200 kB
  of JSON, so anything holding real matrices wants `MEDIUMTEXT`.
* Use `utf8mb4`, not MySQL's 3-byte `utf8`, or char data outside the BMP will
  be mangled.
* `json.mdumps(..., 'compress', true)` returns **bytes, not text**. Base64 it
  before putting it in a text column, or use a `BLOB`.

## Format 1 (legacy)

Format 1 payloads are `{"vals":..., "info":...}` with no `fmt` key, and an
`info` that is a *tree* mirroring `vals`, with `type__`/`dim__`/`cell__`
sentinels at the leaves. `json.mloads` detects and handles them via
`json.mloads_v1`, so old rows need no migration. Format 1 round-trips 57 of
the 89 cases in `test.json_cases`; among the things it gets wrong are
non-finite values, `single`, signed integers, 2-D char, cell-of-cell (raises),
and any struct with a field actually named `type__`. Do not write new format 1
data.

## Readers in other languages

`+json/readers/` has reference decoders for Python, Julia and R, each about
100 lines, plus the test scripts that check them against payloads generated by
MATLAB. They implement this document; if you change the format, change them
and `+json/readers/testdata.json` too.
