  This is really advanced and goes beyond most CLI APIs, but it may also be nice
  to have input data from stdin (optionally mergeable with argv) auto-parsed to
  designated input `seq[T]` and also allow formatting controls for result echo
  of `seq[U]`.  Then procs which take `seq[T]` & return `seq[U]` could be auto-
  wrapped into cmds that read from auto-parsed data on stdin, compute, format
  data to stdout.  In real commands, such activity is often buffered rather than
  one-shot as the above description, though.  While we might be able to use an
  `iterator(): T` on the input side, there seems no way to buffer the output
  incrementally.  So, we would need to store `seq[U]`.  Automatic read-side
  buffered parsing could still be nice, though existing procs in the wild with
  `iterator(): T` input parameters must be far more rare than full buffered
  `(openArray|seq)[T]`.  Could also generalize text IO to binary/RPC marshaled
  fmts.  If output/input fmt are compatible/inverses this might allow elegant
  construction of a multi-command of pipelinable subcommands.

  `positionals = @[ "param1", "param1", "rest" ]` (or `string`-vs-`seq` literal
  check on the current `positional`) could resuscitate mandatory non-keyed-entry
  positional arguments.
