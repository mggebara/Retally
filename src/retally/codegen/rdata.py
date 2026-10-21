"""What an R data file (``.RData`` / ``.rda`` / ``.rds``) contains, without R.

The generation prompt lists each data file's columns so the model does
not have to guess variable names (``_describe_dataset_files`` in
``generator.py``).  For R data files that means the objects the file
defines and, for each data frame, its row count and column names.

:func:`read_r_objects` gets them by walking R's serialization format
(``serialize()`` / ``save()``, XDR flavour, versions 2 and 3): object
names, ``class`` and ``names`` attributes and the ``row.names`` row count
are read; vector contents are skipped, never materialised, so a 27 MB
``.RData`` costs a single decompression pass and almost no memory.  It
also reports objects other than data frames (lists, model objects) by
name and R class, which ``pyreadr`` (librdata) silently drops, and it
handles files ``pyreadr`` refuses to read at all: Bisbee & Honig's
``replication_data.RData`` fails ``pyreadr.read_r`` with "matrix, array
or table object with more than one vector!" because a column carries a
``dim`` attribute.  When the walker cannot parse a file (ASCII or native
binary serialization, a construct it does not know), ``pyreadr``'s
``list_objects`` -- which reads names and columns, not rows -- is the
fallback.  Every failure ends in a short note, never an exception.
"""

from __future__ import annotations

import bz2
import gzip
import lzma
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Any, BinaryIO, cast

R_DATA_SUFFIXES = frozenset({".rdata", ".rda", ".rds"})

# Files larger than this (on disk, compressed) are not opened: the
# listing says "too large to inspect" instead.
R_MAX_INSPECT_BYTES = 200 * 1024 * 1024
_REASON_CHARS = 80


@dataclass(frozen=True)
class RObject:
    """One object stored in an R data file."""

    name: str  # "" for the single object of an .rds file
    r_class: str  # first element of class(), else the base type ("list", "numeric", ...)
    is_data_frame: bool
    rows: int | None = None  # data frames only; None when unknown
    columns: tuple[str, ...] = ()  # data frames only


@dataclass(frozen=True)
class RDataContents:
    """Objects of an R data file, or why they could not be listed."""

    objects: tuple[RObject, ...] = ()
    note: str = ""  # "too large to inspect" / "unreadable: <reason>"; "" when read


_CACHE: dict[tuple[str, int, int], RDataContents] = {}


def read_r_objects(path: Path) -> RDataContents:
    """The objects in ``path`` (an ``.RData`` / ``.rda`` / ``.rds`` file).

    Cached per path, modification time and size within the process.
    Never raises.
    """
    try:
        st = path.stat()
    except OSError as exc:
        return RDataContents(note=f"unreadable: {_short(exc)}")
    key = (str(path.resolve()), st.st_mtime_ns, st.st_size)
    if key not in _CACHE:
        _CACHE[key] = _read_uncached(path, st.st_size)
    return _CACHE[key]


def _read_uncached(path: Path, size: int) -> RDataContents:
    if size > R_MAX_INSPECT_BYTES:
        return RDataContents(note="too large to inspect")
    try:
        with _open_decompressed(path) as f:
            return RDataContents(objects=tuple(_Walker(f).objects()))
    except Exception as exc:  # any parse failure falls back to pyreadr
        reason = _short(exc)
    try:
        return RDataContents(objects=_pyreadr_objects(path))
    except Exception:
        return RDataContents(note=f"unreadable: {reason}")


def _short(exc: BaseException) -> str:
    text = " ".join(str(exc).split()) or type(exc).__name__
    return text if len(text) <= _REASON_CHARS else text[:_REASON_CHARS] + "…"


def _pyreadr_objects(path: Path) -> tuple[RObject, ...]:
    """Data frames via librdata: names and columns, or a full read if that fails.

    ``list_objects`` reads no data but raises on data frames with
    explicit row names (pyreadr 0.5: ``'ListObjectsParser' object has no
    attribute 'handle_row_name'``); ``read_r`` then loads the frames,
    which also gives their row counts.
    """
    import pyreadr

    try:
        listed = pyreadr.list_objects(str(path))
    except Exception:
        return tuple(
            RObject(
                name=str(name or ""),
                r_class="data.frame",
                is_data_frame=True,
                rows=len(frame),
                columns=tuple(str(c) for c in frame.columns),
            )
            for name, frame in pyreadr.read_r(str(path)).items()
        )
    return tuple(
        RObject(
            name=str(o.get("object_name") or ""),
            r_class="data.frame",
            is_data_frame=True,
            columns=tuple(str(c) for c in (o.get("columns") or [])),
        )
        for o in listed
    )


def _open_decompressed(path: Path) -> BinaryIO:
    with path.open("rb") as raw:
        magic = raw.read(6)
    if magic[:2] == b"\x1f\x8b":
        return cast(BinaryIO, gzip.open(path, "rb"))
    if magic[:3] == b"BZh":
        return cast(BinaryIO, bz2.open(path, "rb"))
    if magic == b"\xfd7zXZ\x00":
        return cast(BinaryIO, lzma.open(path, "rb"))
    return path.open("rb")


class _Malformed(ValueError):
    pass


# SEXP type codes (R's serialize.c / Rinternals.h).
_NILSXP, _SYMSXP, _LISTSXP, _CLOSXP, _ENVSXP, _PROMSXP, _LANGSXP = 0, 1, 2, 3, 4, 5, 6
_SPECIALSXP, _BUILTINSXP, _CHARSXP, _LGLSXP, _INTSXP, _REALSXP = 7, 8, 9, 10, 13, 14
_CPLXSXP, _STRSXP, _DOTSXP, _VECSXP, _EXPRSXP, _BCODESXP = 15, 16, 17, 19, 20, 21
_EXTPTRSXP, _WEAKREFSXP, _RAWSXP, _S4SXP = 22, 23, 24, 25
_REFSXP, _NILVALUE_SXP, _PERSISTSXP, _PACKAGESXP, _NAMESPACESXP = 255, 254, 247, 248, 249
_ALTREP_SXP, _ATTRLISTSXP, _ATTRLANGSXP, _BCREPREF, _BCREPDEF = 238, 239, 240, 243, 244
_SINGLETONS = frozenset({242, 241, 253, 252, 251, 250, _NILVALUE_SXP})  # empty/base/global env, ...
_PAIRLIST_TYPES = frozenset({_LISTSXP, _LANGSXP, _CLOSXP, _PROMSXP, _DOTSXP})
_WIDTH = {_LGLSXP: 4, _INTSXP: 4, _REALSXP: 8, _CPLXSXP: 16, _RAWSXP: 1}
_TYPE_NAMES = {
    _NILSXP: "NULL",
    _NILVALUE_SXP: "NULL",
    _SYMSXP: "name",
    _LISTSXP: "pairlist",
    _CLOSXP: "function",
    _ENVSXP: "environment",
    _LANGSXP: "call",
    _LGLSXP: "logical",
    _INTSXP: "integer",
    _REALSXP: "numeric",
    _CPLXSXP: "complex",
    _STRSXP: "character",
    _VECSXP: "list",
    _EXPRSXP: "expression",
    _RAWSXP: "raw",
    _S4SXP: "S4",
}
_NA_INTEGER = -(2**31)
_CAPTURE_MAX = 100_000  # longest vector whose values are kept when captured
_CHUNK = 1 << 20
_INT = struct.Struct(">i")
_TWO_INTS = struct.Struct(">ii")
_DOUBLE = struct.Struct(">d")


@dataclass
class _Item:
    """What the walker keeps of one serialized R object."""

    type: int
    length: int | None = None
    values: list[Any] | None = None  # captured vector values / symbol or string text
    attrs: dict[str, _Item] | None = None
    entries: list[tuple[str | None, _Item]] | None = None  # captured pairlist nodes


class _Walker:
    """Reads R serialization (XDR) from a stream, skipping vector contents."""

    def __init__(self, f: BinaryIO) -> None:
        self._f = f
        self._buf = b""
        self._pos = 0
        self._refs: list[str | None] = []  # symbol names; None for other referenced objects

    # ── stream primitives ─────────────────────────────────────────────

    def _fill(self, n: int) -> None:
        avail = len(self._buf) - self._pos
        if avail >= n:
            return
        self._buf = self._buf[self._pos :] + self._f.read(max(n - avail, _CHUNK))
        self._pos = 0
        if len(self._buf) < n:
            raise _Malformed("truncated file")

    def _int(self) -> int:
        self._fill(4)
        (value,) = _INT.unpack_from(self._buf, self._pos)
        self._pos += 4
        return int(value)

    def _bytes(self, n: int) -> bytes:
        self._fill(n)
        out = self._buf[self._pos : self._pos + n]
        self._pos += n
        return out

    def _skip(self, n: int) -> None:
        avail = len(self._buf) - self._pos
        if n <= avail:
            self._pos += n
            return
        n -= avail
        self._buf, self._pos = b"", 0
        while n > 0:
            chunk = self._f.read(min(n, _CHUNK))
            if not chunk:
                raise _Malformed("truncated file")
            n -= len(chunk)

    def _length(self) -> int:
        n = self._int()
        if n == -1:  # long vector: upper and lower 32 bits
            upper, lower = self._int(), self._int()
            n = (upper << 32) + (lower & 0xFFFFFFFF)
        if n < 0:
            raise _Malformed("negative vector length")
        return n

    # ── file layout ───────────────────────────────────────────────────

    def objects(self) -> list[RObject]:
        head = self._bytes(2)
        saved = head == b"RD"  # save() writes "RDX2\n"/"RDX3\n" before the stream
        if saved:
            if self._bytes(3) not in (b"X2\n", b"X3\n"):
                raise _Malformed("not an XDR-format .RData file")
            head = self._bytes(2)
        if head != b"X\n":
            raise _Malformed("not an XDR-format R serialization")
        version = self._int()
        self._int()  # writer R version
        self._int()  # minimal reader R version
        if version == 3:
            self._skip(self._int())  # native encoding name
        elif version != 2:
            raise _Malformed(f"serialization version {version}")
        if not saved:  # saveRDS(): a single unnamed object
            return [_summarise("", self._item(self._int(), capture=True))]
        flags = self._int()
        out: list[RObject] = []
        while flags & 0xFF == _LISTSXP:  # save(): a pairlist tagged by object name
            if flags & 0x200:
                self._item(self._int())
            if not flags & 0x400:
                raise _Malformed("untagged object")
            name = self._symbol_name()
            out.append(_summarise(name, self._item(self._int(), capture=True)))
            flags = self._int()
        if flags & 0xFF != _NILVALUE_SXP:
            raise _Malformed("unexpected top-level object")
        return out

    def _symbol_name(self) -> str:
        item = self._item(self._int(), capture=True)
        if item.values and isinstance(item.values[0], str):
            return item.values[0]
        return ""

    # ── items ─────────────────────────────────────────────────────────

    def _item(self, flags: int, capture: bool = False) -> _Item:
        t = flags & 0xFF
        has_attr = bool(flags & 0x200)
        if t in _SINGLETONS:
            return _Item(t)
        if t == _REFSXP:
            index = (flags >> 8) or self._int()
            if not 1 <= index <= len(self._refs):
                raise _Malformed("bad reference")
            name = self._refs[index - 1]
            return _Item(_SYMSXP, values=[name]) if name is not None else _Item(t)
        if t in (_PERSISTSXP, _PACKAGESXP, _NAMESPACESXP):
            self._string_vec()
            self._refs.append(None)
            return _Item(t)
        if t == _SYMSXP:
            text = self._item(self._int(), capture=True).values
            name = text[0] if text else None
            self._refs.append(name if isinstance(name, str) else "")
            return _Item(t, values=[name])
        if t == _ENVSXP:
            self._refs.append(None)
            self._int()  # locked
            for _ in range(4):  # enclosure, frame, hash table, attributes
                self._item(self._int())
            return _Item(t)
        if t in _PAIRLIST_TYPES:
            return self._pairlist(flags, capture)
        item = self._vector_or_other(t, capture)
        if has_attr:
            item.attrs = self._attributes()
        return item

    def _pairlist(self, flags: int, capture: bool) -> _Item:
        """A chain of pairlist nodes, walked iteratively along the CDR."""
        first_type = flags & 0xFF
        entries: list[tuple[str | None, _Item]] = []
        attrs = None
        while flags & 0xFF in _PAIRLIST_TYPES:
            if flags & 0x200:
                node_attrs = self._attributes()
                attrs = attrs or node_attrs
            tag = self._symbol_name() if flags & 0x400 else None
            car = self._item(self._int(), capture=capture)
            if capture:
                entries.append((tag, car))
            flags = self._int()
        self._item(flags)  # the final CDR: usually NULL, a closure's body otherwise
        return _Item(first_type, length=len(entries), attrs=attrs, entries=entries if capture else None)

    def _attributes(self) -> dict[str, _Item]:
        attrs = self._item(self._int(), capture=True)
        return {tag: value for tag, value in attrs.entries or [] if tag}

    def _vector_or_other(self, t: int, capture: bool) -> _Item:
        if t in _WIDTH:
            n = self._length()
            if capture and n <= 3 and t in (_INTSXP, _LGLSXP, _REALSXP):
                values: list[Any] = []
                for _ in range(n):
                    if t == _REALSXP:
                        (v,) = _DOUBLE.unpack(self._bytes(8))
                        values.append(v)
                    else:
                        values.append(self._int())
                return _Item(t, length=n, values=values)
            self._skip(n * _WIDTH[t])
            return _Item(t, length=n)
        if t == _CHARSXP:
            n = self._int()
            if n == -1:
                return _Item(t, values=[None])
            if capture:
                return _Item(t, values=[self._bytes(n).decode("utf-8", "replace")])
            self._skip(n)
            return _Item(t)
        if t == _STRSXP:
            n = self._length()
            if capture and n <= _CAPTURE_MAX:
                texts = [self._item(self._int(), capture=True).values for _ in range(n)]
                return _Item(t, length=n, values=[v[0] if v else None for v in texts])
            self._skip_strings(n)
            return _Item(t, length=n)
        if t in (_VECSXP, _EXPRSXP):
            n = self._length()
            for _ in range(n):
                self._item(self._int())
            return _Item(t, length=n)
        if t == _S4SXP:
            return _Item(t)
        if t in (_SPECIALSXP, _BUILTINSXP):
            self._skip(self._int())
            return _Item(t)
        if t == _EXTPTRSXP:
            self._refs.append(None)
            self._item(self._int())  # protected value
            self._item(self._int())  # tag
            return _Item(t)
        if t == _WEAKREFSXP:
            self._refs.append(None)
            return _Item(t)
        if t == _BCODESXP:
            self._int()  # number of repeated-language slots
            self._bytecode()
            return _Item(t)
        if t == _ALTREP_SXP:
            return self._altrep()
        raise _Malformed(f"unsupported R object type {t}")

    def _skip_strings(self, n: int) -> None:
        """Skip ``n`` CHARSXP elements of a character vector (the hot path)."""
        for _ in range(n):
            self._fill(8)
            flags, length = _TWO_INTS.unpack_from(self._buf, self._pos)
            if flags & 0xFF != _CHARSXP:
                self._pos += 4
                self._item(flags)
                continue
            self._pos += 8
            if length > 0:
                self._skip(length)

    def _string_vec(self) -> None:
        if self._int() != 0:
            raise _Malformed("bad persistent string vector")
        for _ in range(self._int()):
            self._item(self._int())

    def _altrep(self) -> _Item:
        """An ALTREP object: (class, package, base type) info, state, attributes.

        Only compact integer/real sequences (``1:n``, e.g. as ``row.names``)
        get a length; other ALTREP classes keep their base type only.
        """
        info = self._item(self._int(), capture=True)
        state = self._item(self._int(), capture=True)
        attr_item = self._item(self._int(), capture=True)
        parts = [value.values[0] if value.values else None for _, value in info.entries or []]
        base_type = int(parts[2]) if len(parts) >= 3 and isinstance(parts[2], int) else _VECSXP
        length = None
        if parts and parts[0] in ("compact_intseq", "compact_realseq") and state.values:
            length = int(state.values[0])
        item = _Item(base_type, length=length)
        if attr_item.entries:
            item.attrs = {tag: value for tag, value in attr_item.entries if tag}
        return item

    def _bytecode(self) -> None:
        self._item(self._int())  # code
        for _ in range(self._int()):  # constants
            t = self._int()
            if t == _BCODESXP:
                self._bytecode()
            elif t in (_LANGSXP, _LISTSXP, _BCREPDEF, _BCREPREF, _ATTRLANGSXP, _ATTRLISTSXP):
                self._bytecode_lang(t)
            else:
                self._item(self._int())

    def _bytecode_lang(self, t: int) -> None:
        if t == _BCREPREF:
            self._int()
            return
        if t in (_BCREPDEF, _LANGSXP, _LISTSXP, _ATTRLANGSXP, _ATTRLISTSXP):
            if t == _BCREPDEF:
                self._int()  # position
                t = self._int()
            if t in (_ATTRLANGSXP, _ATTRLISTSXP):
                self._item(self._int())
            self._item(self._int())  # tag
            self._bytecode_lang(self._int())  # car
            self._bytecode_lang(self._int())  # cdr
            return
        self._item(self._int())


def _strings(item: _Item | None) -> list[str]:
    if item is None or item.type != _STRSXP or not item.values:
        return []
    return [v for v in item.values if isinstance(v, str)]


def _summarise(name: str, item: _Item) -> RObject:
    attrs = item.attrs or {}
    classes = _strings(attrs.get("class"))
    if "data.frame" in classes:
        row_names = attrs.get("row.names")
        rows = None
        if row_names is not None:
            values = row_names.values
            if row_names.type == _INTSXP and values and len(values) == 2 and values[0] == _NA_INTEGER:
                rows = abs(int(values[1]))  # compact form c(NA, -n)
            else:
                rows = row_names.length
        return RObject(
            name=name,
            r_class=classes[0],
            is_data_frame=True,
            rows=rows,
            columns=tuple(_strings(attrs.get("names"))),
        )
    if classes:
        r_class = classes[0]
    elif attrs.get("dim") is not None and attrs["dim"].length == 2:
        r_class = "matrix"
    else:
        r_class = _TYPE_NAMES.get(item.type, f"R type {item.type}")
    return RObject(name=name, r_class=r_class, is_data_frame=False)
