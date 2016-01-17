var foo=2.0

proc demo(args: seq[int], alpha=1, beta=foo, verb=false, item=""): int =
  ## demo entry point with varied, meaningless parameters.  A Nim invocation
  ## might be: demo(alpha=2, @[ "hi", "ho" ]) corresponding to the command
  ## invocation "demo --alpha=2 hi ho" (assuming executable gets named demo).
  echo "alpha:", alpha, " beta:", beta, " verb:", verb, " item:", repr(item)
  for i, arg in args: echo "positional[", i, "]: ", repr(arg)
  return 42

when isMainModule:
  import cligen
  dispatch(demo)
