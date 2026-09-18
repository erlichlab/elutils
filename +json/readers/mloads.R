# mloads.R -- read MATLAB json.mdumps format-2 payloads in R.
#
# Reference implementation of the format in +json/FORMAT.md.
# Read-only: there is no R writer.
#
#   source("mloads.R")
#   obj <- mloads(row_text_from_mariadb)          # needs jsonlite
#   obj <- mloads_parsed(already_parsed)          # no dependency at all
#
# Type mapping
# ------------
#   scalar struct               named list
#   struct array                unnamed list of named lists, column-major
#   cell array                  unnamed list, column-major
#   numeric / logical array     array/matrix/vector with MATLAB's shape
#   numeric / logical scalar    length-1 vector
#   char (row vector, empty)    character(1)
#   char (2-D, >1 row)          character vector, one element per row
#   string array                character vector
#
# Multidimensional cell and struct arrays come back as column-major lists;
# mloads(x, with_meta = TRUE) also returns every node's MATLAB class and dims.
#
# Leaves are stored flattened column-major, which is R's own array order, so
# array() and dim() are correct as written and need no transposing.
#
# IMPORTANT: parse with simplifyVector = FALSE. jsonlite's default
# simplification collapses the nested arrays that carry cell structure, and
# turns nulls into different shapes depending on the data.

mloads <- function(text, with_meta = FALSE) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("mloads(): package 'jsonlite' is required to parse text; ",
         "use mloads_parsed() with your own parser instead.", call. = FALSE)
  }
  parsed <- jsonlite::fromJSON(text, simplifyVector = FALSE)
  mloads_parsed(parsed, with_meta = with_meta)
}

mloads_parsed <- function(obj, with_meta = FALSE) {
  if (!is.list(obj) || !all(c("vals", "info") %in% names(obj))) {
    stop("not a json.mdumps payload (no vals/info)", call. = FALSE)
  }

  if (!("fmt" %in% names(obj))) {
    warning("format-1 (legacy) payload: returning 'vals' as plain JSON without ",
            "restoring MATLAB types or shapes. Re-save it with the current ",
            "json.mdumps for a faithful decode.", call. = FALSE)
    return(if (with_meta) list(value = obj[["vals"]], meta = list()) else obj[["vals"]])
  }
  if (as.integer(obj[["fmt"]]) != 2L) {
    stop("unsupported format version ", obj[["fmt"]], call. = FALSE)
  }

  info <- obj[["info"]]
  if (!is.list(info)) stop("info must be a list", call. = FALSE)

  res <- .build(obj[["vals"]], info, 1L)
  if (res$i != length(info) + 1L) {
    warning("consumed ", res$i - 1L, " of ", length(info),
            " info entries; payload may be malformed", call. = FALSE)
  }

  if (!with_meta) return(res$value)

  meta <- lapply(info, function(e) {
    list(path = .aslist(e[["p"]]),
         class = e[["t"]],
         dims = as.integer(unlist(.aslist(e[["d"]]))))
  })
  list(value = res$value, meta = meta)
}

# --- internals -------------------------------------------------------------

.MATLAB_NUMERIC <- c("double", "single", "int8", "uint8", "int16", "uint16",
                     "int32", "uint32", "int64", "uint64", "logical")

# A JSON scalar stands in for a one-element array; normalise to a list.
.aslist <- function(x) {
  if (is.null(x)) return(list())
  if (is.list(x)) return(x)
  as.list(x)
}

# The n raw child blocks of a container.
.elements <- function(raw, n) {
  if (n == 0L) return(list())
  if (is.list(raw) && is.null(names(raw))) {
    if (length(raw) == n) return(raw)
    if (n == 1L) return(list(raw))
    stop("expected ", n, " container elements, found ", length(raw), call. = FALSE)
  }
  if (n == 1L) return(list(raw))
  if (is.null(raw)) return(rep(list(NULL), n))
  stop("expected ", n, " container elements, found a ", class(raw)[1], call. = FALSE)
}

.build <- function(raw, info, i) {
  if (i > length(info)) stop("ran out of info entries", call. = FALSE)
  e <- info[[i]]
  i <- i + 1L

  dims <- as.integer(unlist(.aslist(e[["d"]])))
  n <- prod(dims)
  t <- e[["t"]]
  if (identical(e[["as"]], "struct")) t <- "struct"

  if (identical(t, "cell")) {
    kids <- .elements(raw, n)
    out <- vector("list", n)
    for (k in seq_len(n)) {
      r <- .build(kids[[k]], info, i)
      out[[k]] <- r$value
      i <- r$i
    }
    return(list(value = out, i = i))
  }

  if (identical(t, "struct")) {
    fields <- unlist(.aslist(e[["f"]]))
    if (n == 1L) {
      src <- if (is.list(raw)) raw else list()
      out <- list()
      for (nm in fields) {
        r <- .build(src[[nm]], info, i)
        out[[nm]] <- r$value
        i <- r$i
      }
      return(list(value = out, i = i))
    }
    kids <- .elements(raw, n)
    out <- vector("list", n)
    for (k in seq_len(n)) {
      src <- if (is.list(kids[[k]])) kids[[k]] else list()
      elem <- list()
      for (nm in fields) {
        r <- .build(src[[nm]], info, i)
        elem[[nm]] <- r$value
        i <- r$i
      }
      out[[k]] <- elem
    }
    return(list(value = out, i = i))
  }

  if (identical(t, "char")) {
    s <- if (is.character(raw) && length(raw) == 1L) raw else ""
    if (length(dims) == 2L && dims[1] > 1L) {
      rows <- dims[1]; cols <- dims[2]
      ch <- strsplit(s, "", fixed = TRUE)[[1]]
      if (length(ch) < rows * cols) ch <- c(ch, rep(" ", rows * cols - length(ch)))
      # stored column-major: element (r, c) sits at r + rows * (c - 1)
      rowstr <- vapply(seq_len(rows), function(r) {
        paste(ch[r + rows * (seq_len(cols) - 1L)], collapse = "")
      }, character(1))
      return(list(value = rowstr, i = i))
    }
    return(list(value = s, i = i))
  }

  if (identical(t, "string")) {
    items <- vapply(.aslist(raw), function(x) {
      if (is.character(x) && length(x) == 1L) x else ""
    }, character(1))
    if (length(items) < n) items <- c(items, rep("", n - length(items)))
    return(list(value = items[seq_len(n)], i = i))
  }

  if (!(t %in% .MATLAB_NUMERIC)) {
    stop('unknown MATLAB class "', t, '" in info', call. = FALSE)
  }

  flat <- .numeric_leaf(raw, e, n, t)
  if (n == 1L && all(dims == 1L)) return(list(value = flat, i = i))
  # R arrays are column-major, matching the stored order, so no permuting.
  return(list(value = array(flat, dim = dims), i = i))
}

.numeric_leaf <- function(raw, e, n, t) {
  logical_leaf <- identical(t, "logical")

  if (!is.null(e[["s"]]) && length(.aslist(e[["s"]])) > 0L) {
    # Exact decimal strings for 64-bit ints beyond 2^53. R has no native int64,
    # so these come back as doubles and lose precision above 2^53. Use the
    # bit64 package on the strings if you need them exactly.
    strs <- vapply(.aslist(e[["s"]]), as.character, character(1))
    if (n > 0L && length(strs) >= n) {
      warning("64-bit integers beyond 2^53 are returned as doubles and lose ",
              "precision; the exact values are in info$s", call. = FALSE)
      return(as.numeric(strs[seq_len(n)]))
    }
  }

  vals <- .aslist(raw)
  filler <- if (logical_leaf) NA else NA_real_
  flat <- rep(filler, max(n, 0L))
  for (k in seq_len(min(n, length(vals)))) {
    v <- vals[[k]]
    if (!is.null(v)) {
      flat[k] <- if (logical_leaf) as.logical(v) else as.numeric(v)
    }
  }

  nf <- e[["nf"]]
  if (!is.null(nf) && !logical_leaf) {
    idxs <- as.integer(unlist(.aslist(nf[["i"]])))
    kinds <- vapply(.aslist(nf[["k"]]), as.character, character(1))
    for (q in seq_along(idxs)) {
      j <- idxs[q]
      if (is.na(j) || j < 1L || j > n) next
      flat[j] <- switch(kinds[q], "NaN" = NaN, "Inf" = Inf, "-Inf" = -Inf, flat[j])
    }
  }

  if (logical_leaf) as.logical(flat) else flat
}
