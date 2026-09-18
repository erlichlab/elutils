"""
mloads.py -- read MATLAB ``json.mdumps`` format-2 payloads in Python.

Reference implementation of the format described in ``+json/FORMAT.md``.
Read-only: there is no Python writer.

    from mloads import mloads
    obj = mloads(row_text_from_mariadb)

Type mapping
------------
============================  ==========================================
MATLAB                        Python
============================  ==========================================
scalar struct                 ``dict``
struct array                  ``list`` of ``dict``, column-major order
cell array                    ``list``, column-major order
numeric / logical array       ``numpy.ndarray`` with MATLAB's shape
numeric / logical scalar      ``float`` / ``int`` / ``bool``
char (row vector or empty)    ``str``
char (2-D, >1 row)            ``list`` of ``str``, one per row
string array                  ``list`` of ``str`` (``str`` if scalar)
============================  ==========================================

Multidimensional cell and struct arrays are flattened to column-major lists;
their MATLAB shape is available through ``with_meta=True`` if you need it.

If NumPy is not installed, array leaves come back as flat column-major lists.

Note on shape: array leaves are stored flattened **column-major**, which is
why reshaping uses ``order='F'``. Reshaping with NumPy's default C order
silently transposes the data.
"""

import json
import math
import warnings

try:
    import numpy as _np
except ImportError:  # pragma: no cover
    _np = None

__all__ = ["mloads", "MLoadsError"]

_DTYPE = {
    "double": "float64",
    "single": "float32",
    "int8": "int8",
    "uint8": "uint8",
    "int16": "int16",
    "uint16": "uint16",
    "int32": "int32",
    "uint32": "uint32",
    "int64": "int64",
    "uint64": "uint64",
    "logical": "bool",
}

_NONFINITE = {"NaN": math.nan, "Inf": math.inf, "-Inf": -math.inf}


class MLoadsError(ValueError):
    """The payload is not something mloads can decode."""


def mloads(src, with_meta=False):
    """Decode a ``json.mdumps`` payload.

    ``src`` may be JSON text (``str``/``bytes``) or an already-parsed object.
    With ``with_meta=True`` returns ``(value, meta)`` where ``meta`` maps a
    path tuple to ``(matlab_class, dims)`` for every node.
    """
    if isinstance(src, (str, bytes, bytearray)):
        obj = json.loads(src)
    else:
        obj = src

    if not isinstance(obj, dict) or "vals" not in obj or "info" not in obj:
        raise MLoadsError(
            "not a json.mdumps payload (no vals/info); use json.loads for plain JSON"
        )

    if "fmt" not in obj:
        warnings.warn(
            "format-1 (legacy) payload: returning 'vals' as plain JSON without "
            "restoring MATLAB types or shapes. Re-save it with the current "
            "json.mdumps to get a faithful decode.",
            stacklevel=2,
        )
        return (obj["vals"], {}) if with_meta else obj["vals"]

    if int(obj["fmt"]) != 2:
        raise MLoadsError("unsupported format version %r" % (obj["fmt"],))

    info = obj["info"]
    if not isinstance(info, list):
        raise MLoadsError("info must be a list")

    value, idx = _build(obj["vals"], info, 0)
    if idx != len(info):
        warnings.warn(
            "consumed %d of %d info entries; payload may be malformed"
            % (idx, len(info)),
            stacklevel=2,
        )

    if with_meta:
        meta = {
            tuple(_aslist(e.get("p", []))): (e["t"], tuple(int(x) for x in e["d"]))
            for e in info
        }
        return value, meta
    return value


# ---------------------------------------------------------------------------
def _aslist(x):
    """JSON scalars stand in for one-element arrays; normalise to a list."""
    if x is None:
        return []
    if isinstance(x, list):
        return x
    return [x]


def _elements(raw, n):
    """The n raw child blocks of a container.

    Unlike MATLAB's jsondecode, a Python JSON parser preserves the structure
    exactly, so this is nearly trivial.
    """
    if n == 0:
        return []
    if isinstance(raw, list):
        if len(raw) == n:
            return raw
        if n == 1:
            return [raw]
        raise MLoadsError("expected %d container elements, found %d" % (n, len(raw)))
    if n == 1:
        return [raw]
    if raw is None:
        return [None] * n
    raise MLoadsError("expected %d container elements, found a %s" % (n, type(raw).__name__))


def _build(raw, info, i):
    if i >= len(info):
        raise MLoadsError("ran out of info entries")
    e = info[i]
    i += 1

    dims = [int(x) for x in _aslist(e["d"])]
    n = 1
    for x in dims:
        n *= x

    t = e["t"]
    if e.get("as") == "struct":
        t = "struct"

    if t == "cell":
        kids = _elements(raw, n)
        out = []
        for k in range(n):
            v, i = _build(kids[k], info, i)
            out.append(v)
        return out, i

    if t == "struct":
        fields = _aslist(e.get("f", []))
        if n == 1:
            src = raw if isinstance(raw, dict) else {}
            out = {}
            for name in fields:
                v, i = _build(src.get(name), info, i)
                out[name] = v
            return out, i
        kids = _elements(raw, n)
        out = []
        for k in range(n):
            src = kids[k] if isinstance(kids[k], dict) else {}
            elem = {}
            for name in fields:
                v, i = _build(src.get(name), info, i)
                elem[name] = v
            out.append(elem)
        return out, i

    if t == "char":
        s = raw if isinstance(raw, str) else ""
        if len(dims) == 2 and dims[0] > 1:
            rows, cols = dims[0], dims[1]
            if len(s) < rows * cols:
                s = s + " " * (rows * cols - len(s))
            # stored column-major, so element (r, c) is at r + rows * c
            return [
                "".join(s[r + rows * c] for c in range(cols)) for r in range(rows)
            ], i
        return s, i

    if t == "string":
        items = [x if isinstance(x, str) else "" for x in _aslist(raw)]
        while len(items) < n:
            items.append("")
        items = items[:n]
        if n == 1:
            return items[0], i
        return items, i

    if t not in _DTYPE:
        raise MLoadsError("unknown MATLAB class %r in info" % (t,))

    flat = _numeric_leaf(raw, e, n, t)

    if n == 1 and all(x == 1 for x in dims):
        return _scalar(flat[0], t), i

    if _np is None:
        return flat, i
    return _np.array(flat, dtype=_DTYPE[t]).reshape(dims, order="F"), i


def _numeric_leaf(raw, e, n, t):
    """Flat column-major values for one array leaf, with nulls resolved."""
    if e.get("s"):
        # exact decimal strings for 64-bit ints beyond 2**53
        flat = [int(x) for x in _aslist(e["s"])]
        while len(flat) < n:
            flat.append(0)
        return flat[:n]

    flat = [math.nan if x is None else x for x in _aslist(raw)]

    # Pad before applying nf: an all-non-finite leaf encodes as bare nulls, and
    # a scalar null decodes to no elements at all, so the nf indices below can
    # point past whatever the parser gave us.
    filler = math.nan if t in ("double", "single") else 0
    while len(flat) < n:
        flat.append(filler)
    flat = flat[:n]

    nf = e.get("nf") or {}
    for pos, kind in zip(_aslist(nf.get("i", [])), _aslist(nf.get("k", []))):
        j = int(pos) - 1
        if 0 <= j < n and kind in _NONFINITE:
            flat[j] = _NONFINITE[kind]
    return flat


def _scalar(x, t):
    if t == "logical":
        return bool(x)
    if t in ("double", "single"):
        return float(x)
    return int(x)
