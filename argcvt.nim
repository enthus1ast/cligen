from parseutils import parseBiggestInt, parseBiggestUInt, parseBiggestFloat
from strutils   import `%`, join, split, wordWrap, repeat, strip, toLowerAscii
from terminal   import terminalWidth
from typetraits import `$`

proc nimEscape*(s: string): string =
  ## Until strutils gets a nimStringEscape that is not deprecated
  result = newStringOfCap(s.len + 2 + s.len shr 2)
  result.add('"')
  for c in s: result.addEscapedChar(c)
  result.add('"')

proc keys*(parNm: string, shrt: string, argSep="="): string =
  result = if len(shrt) > 0: "-$1$3, --$2$3" % [ shrt, parNm, argSep ]
           else            : "--" & parNm & argSep

var REQUIRED* = "REQUIRED"  # CLI-author can change, if desired.

template argRq*(rq: int, dv: string): string =
  ## argRq is a simple space-saving template to decide the argHelp dfl column
  (if rq != 0:
    REQUIRED
  else:
    dv)

template argRet*(code: int, msg: string) =
  ## argRet is a simple space-saving template to write msg and return a code.
  stderr.write(msg)                         # if code==0 send to stdout?
  return code

proc addPrefix*(prefix: string, multiline=""): string =
  result = ""
  var lines = multiline.split("\n")
  if len(lines) > 1:
    for line in lines[0 .. ^2]:
      result &= prefix & line & "\n"
  if len(lines) > 0:
    if len(lines[^1]) > 0:
      result &= prefix & lines[^1] & "\n"

type TextTab* = seq[seq[string]]

proc alignTable*(tab: TextTab, prefixLen=0, colGap=2, minLast=16, rowSep="",
                 cols = @[0,1]): string =
  result = ""
  proc nCols(): int =
    result = 0
    for row in tab: result = max(result, row.len)
  var wCol = newSeq[int](nCols())
  let last = cols[^1]
  for row in tab:
    for c in cols[0 .. ^2]: wCol[c] = max(wCol[c], row[c].len)
  var wTerm = terminalWidth() - prefixLen
  var leader = (cols.len - 1) * colGap
  for c in cols[0 .. ^2]: leader += wCol[c]
  wCol[last] = max(minLast, wTerm - leader)
  for row in tab:
    for c in cols[0 .. ^2]:
      result &= row[c] & repeat(" ", wCol[c] - row[c].len + colGap)
    var wrapped = wordWrap(row[last], maxLineWidth = wCol[last]).split("\n")
    result &= (if wrapped.len > 0: wrapped[0] else: "") & "\n"
    for j in 1 ..< len(wrapped):
      result &= repeat(" ", leader) & wrapped[j] & "\n"
    result &= rowSep

## argParse and argHelp are a pair of related overloaded template helpers for
## each supported Nim type of optional parameter.  You may define new ones for
## your own custom types as needed wherever convenient in-scope of dispatch().
## argParse determines how string arguments are interpreted into native types
## while argHelp explains this interpretation to a command-line user.

# bool
template argParse*(dst: bool, key: string, dfl: bool, val, help: string) =
  if len(val) > 0:
    case val.toLowerAscii   # Like `strutils.parseBool` but we also accept t&f
    of "t", "true", "yes", "y", "1", "on": dst = true
    of "f", "false", "no", "n",  "0", "off": dst = false
    else:
      argRet(1, "Bool option \"$1\" non-boolean argument (\"$2\")\n$3" %
             [ key, val, help ])
  else:               # No option arg => reverse of default (usually, ..
    dst = not dfl     #.. but not always this means false->true)

template argHelp*(ht: TextTab, dfl: bool; parNm, sh, parHelp: string, rq: int) =
  ht.add(@[ keys(parNm, sh, argSep=""), "bool", argRq(rq, $dfl), parHelp ])
  shortNoVal.incl(sh[0])            # bool must elide option arguments.
  longNoVal.add(parNm)              # So, add to *NoVal.

# string
template argParse*(dst: string, key: string, dfl: string, val, help: string) =
  if val == nil:
    argRet(1, "Bad value nil for string param \"$1\"\n$2" % [ key, help ])
  dst = val

template argHelp*(ht: TextTab, dfl: string; parNm, sh, parHelp: string, rq:int)=
  ht.add(@[keys(parNm, sh), "string", argRq(rq, nimEscape(dfl)), parHelp])

# cstring
template argParse*(dst: cstring, key: string, dfl: cstring, val, help: string) =
  if val == nil:
    argRet(1, "Bad value nil for string param \"$1\"\n$2" % [ key, help ])
  dst = val

template argHelp*(ht: TextTab, dfl: cstring; parNm, sh, parHelp: string,rq:int)=
  ht.add(@[keys(parNm, sh), "string", argRq(rq, nimEscape($dfl)), parHelp])

# char
template argParse*(dst: char, key: string, dfl: char, val, help: string) =
  if val == nil or len(val) > 1:
    argRet(1, "Bad value nil/multi-char for char param \"$1\"\n$2" %
           [ key , help ])
  dst = val[0]

template argHelp*(ht: TextTab, dfl: char; parNm, sh, parHelp: string, rq: int) =
  ht.add(@[ keys(parNm, sh), "char", repr(dfl), parHelp ])

# various numeric types
template argParseHelpNum(WideT: untyped, parse: untyped, T: untyped): untyped =

  template argParse*(dst: T, key: string, dfl: T, val: string, help: string) =
    block: # {.inject.} needed to get tmp typed, but block: prevents it leaking
      var tmp {.inject.}: WideT
      if val == nil or parse(strip(val), tmp) == 0:
        argRet(1, "Bad value: \"$1\" for option \"$2\"; expecting $3\n$4" %
               [ (if val == nil: "nil" else: val), key, $T, help ])
      else: dst = T(tmp)

  template argHelp*(ht: TextTab, dfl: T; parNm, sh, parHelp: string, rq: int) =
    ht.add(@[ keys(parNm, sh), $T, argRq(rq, $dfl), parHelp ])

argParseHelpNum(BiggestInt  , parseBiggestInt  , int    )  #ints
argParseHelpNum(BiggestInt  , parseBiggestInt  , int8   )
argParseHelpNum(BiggestInt  , parseBiggestInt  , int16  )
argParseHelpNum(BiggestInt  , parseBiggestInt  , int32  )
argParseHelpNum(BiggestInt  , parseBiggestInt  , int64  )
argParseHelpNum(BiggestUInt , parseBiggestUInt , uint   )  #uints
argParseHelpNum(BiggestUInt , parseBiggestUInt , uint8  )
argParseHelpNum(BiggestUInt , parseBiggestUInt , uint16 )
argParseHelpNum(BiggestUInt , parseBiggestUInt , uint32 )
argParseHelpNum(BiggestUInt , parseBiggestUInt , uint64 )
argParseHelpNum(BiggestFloat, parseBiggestFloat, float  )  #floats
argParseHelpNum(BiggestFloat, parseBiggestFloat, float32)
argParseHelpNum(BiggestFloat, parseBiggestFloat, float64)
