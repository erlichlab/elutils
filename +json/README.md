# Why does this exist?

`mdumps` and `mloads` create an augmented JSON format that is still valid JSON,
but carries enough extra information that MATLAB can rebuild the *identical*
value it started with:

```matlab
A.foo = 1
A.bar.t = rand(10)
A.bar.d = 'a char array'
A.nerf = 1:10
s = json.mdumps(A)   % s is valid json
B = json.mloads(s)

isequaln(A, B)       % true
```

This is not possible with plain `jsonencode`/`jsondecode`, because JSON has one
array type and MATLAB has two (numeric and cell), plus a class and a shape on
every value. `[1 2 3]` and `{1,2,3}` both encode to `[1,2,3]`; a `2x3` matrix
comes back `6x1`; `single` comes back `double`; `NaN` and `Inf` both become
`null`.

So the payload keeps the data and the type information side by side:

```json
{"fmt":2, "order":"F", "base":1, "vals": <plain JSON>, "info": [<type/shape records>]}
```

**`vals` is ordinary, idiomatic JSON.** Analysis code in Python, R or Julia can
`json.loads` a row and use it directly, ignoring `info` completely — that is the
point of the split, and it should survive any future change to the format.
`info` is a *flat* list of `{path, class, dims}` records, so a faithful reader
in a new language is a loop, not a recursive walk that has to reimplement
MATLAB's cell semantics.

`+json/FORMAT.md` is the full specification. Read it before changing anything.

## Reading these rows from other languages

`+json/readers/` has reference decoders, each about 100 lines:

| file | needs | entry point | run its tests with |
|------|-------|-------------|--------------------|
| `mloads.py` | numpy (optional) | `mloads(text_or_parsed)` | `python3 test_mloads.py` or `pytest` |
| `mloads.jl` | a JSON parser, `OrderedCollections` | `mloads(parsed)` | `julia test_mloads.jl` |
| `mloads.R`  | `jsonlite` | `mloads(text)` / `mloads_parsed(parsed)` | `Rscript test_mloads.R` |

The entry points differ because the languages do: Python takes either text or a
parsed value, Julia is parser-agnostic and takes only a parsed value (pass
`JSON.parse(text)` or `JSON3.read(text, Any)`), and R splits the two. All three
preserve struct field order, return column-major shapes, and refuse a payload
whose declared `order`/`base` they do not implement.

They are tested against `readers/testdata.json`, which MATLAB generates:

```matlab
>> test.gen_reader_testdata     % re-run after any format change
```

**One trap worth knowing even if you never use these readers:** array leaves are
stored flattened **column-major**. Julia and R are column-major too, so their
`reshape`/`array` are right as written. NumPy is row-major, so it needs
`order='F'` — reshaping with the default silently transposes your matrix.

## Storing these in MariaDB

* `TEXT` holds 65,535 **bytes**; a `100x100` double is ~200 kB of JSON. Use
  `MEDIUMTEXT` for anything holding real matrices.
* Use `utf8mb4`, not MySQL's 3-byte `utf8`.
* `json.mdumps(..., 'compress', true)` returns **bytes, not text** — base64 it
  before putting it in a text column, or use a `BLOB`.

## Legacy payloads

Rows written before 2026 are format 1 (`{"vals":..., "info":...}` with no
`fmt`). `json.mloads` detects them and routes them to `json.mloads_v1`, so
**nothing in the database needs migrating**. Format 1 round-trips 57 of the 89
cases in `test.json_cases`; it loses non-finite values, `single` and the signed
integer types, mangles 2-D char, raises on cell-of-cell, and breaks on a struct
with a field actually named `type__`. Don't write new format 1 data.

## Tests

```matlab
>> test.test_json                       % curated cases + fuzz + legacy replay
>> test.test_json('nseeds', 3000, 'depth', 4)   % harder property-based run
```

`test.test_json` checks `isequaln`, but also a strict class/size/field-order
comparison — `isequaln` alone equates `1` with `true` and `int8(1)` with `1`, so
it cannot see the very type bugs this format exists to prevent.

## The mex files

`fromjson.mex*`, `tojson.mex*` and `setjsonfield.mex*` are compiled binaries
from [christianpanton/matlab-json](https://github.com/christianpanton/matlab-json.git),
with supporting libraries in `jsonlibs` built from
[json-c/json-c](https://github.com/json-c/json-c). They existed because MATLAB
had no JSON support at all before R2016b.

**Nothing in this package calls them any more.** `json.mloads` and
`json.mdumps` use `jsondecode`/`jsonencode` exclusively. They are kept only so
that any outside code still calling `json.tojson` or `json.fromjson` directly
keeps working, and they are candidates for deletion.

Two reasons not to rely on them:

* There is no `mexmaca64` build — only `mexa64` (Linux x86), `mexmaci64`
  (Intel Mac) and the Windows ones — so on Apple Silicon these functions do
  not resolve at all.
* They need their json-c libraries copied somewhere the loader will find them
  (`jsonlibs/maci64` → `/usr/local/lib`, `jsonlibs/amd64` → `/usr/lib`).

`jsondecode` reads everything these ever wrote, including the non-standard
bare `NaN`/`Infinity` literals, so there is no payload in the database that
needs them.
