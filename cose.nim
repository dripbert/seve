type
  cose_type = enum
    ct_str, ct_int

proc exec_args(args: seq[string]): void

proc cose_error(msg: string): void =
  echo "Error: " & msg
  quit(1)

proc is_num(str: string): bool =
  for ch in str:
    if not contains("1234567890", ch):
      return false
  return true

proc plus(a1: (cose_type, string), a2: (cose_type, string)): (cose_type, string) =
  if a1[0] != ct_int or a2[0] != ct_int:
    cose_error("value in addition not of type int")
  return (ct_int, $(parse_int(a1[1]) + parse_int(a2[1])))
proc minus(a1: (cose_type, string), a2: (cose_type, string)): (cose_type, string) =
  if a1[0] != ct_int or a2[0] != ct_int:
    cose_error("value in addition not of type int")
  return (ct_int, $(parse_int(a2[1]) - parse_int(a1[1])))
proc mult(a1: (cose_type, string), a2: (cose_type, string)): (cose_type, string) =
  if a1[0] != ct_int or a2[0] != ct_int:
    cose_error("value in addition not of type int")
  return (ct_int, $(parse_int(a1[1]) * parse_int(a2[1])))
 
var opts: seq[(string, string)] = @[]
proc seve_export(opt: string, val: string): void =
  opts &= (opt, val)

proc loop_args(args: seq[string], i: int): void =
  var j: int = 0
  while j < i:
    exec_args(args)
    j += 1

var stack:  seq[(cose_type, string)] = @[]

proc check_stack_size(n: int): void =
  if len(stack) < n:
    cose_error("not enough elements on the stack")
  return
proc duup(arg1: (cose_type, string), arg2: (cose_type, string)): void =
  stack &= arg2
  stack &= arg1
  stack &= arg2
  stack &= arg1

var in_block: int = 0 
proc exec_args(args: seq[string]): void =
  var b_args: seq[string] = @[]

  for arg in args:
    if arg == ")":
      in_block -= 1 

    if in_block > 0:
      b_args &= arg
      continue

    case arg
    of "+":
      check_stack_size(2)
      stack &= plus(stack.pop(), stack.pop())
    of "-":
      check_stack_size(2)
      stack &= minus(stack.pop(), stack.pop())
    of "*":
      check_stack_size(2)
      stack &= mult(stack.pop(), stack.pop())
    of "dup":
      check_stack_size(1)
      stack &= repeat(stack.pop(), 2)
    of "duup":
      check_stack_size(2)
      duup(stack.pop(), stack.pop())
    of "print":
      check_stack_size(1)
      echo stack.pop()[1]
    of "stack":  echo stack
    of "export":
      check_stack_size(2)
      seve_export(stack.pop()[1], stack.pop()[1])
    of "exec":
      check_stack_size(2)
      exec_script_command(stack.pop()[1], stack.pop()[1])
    of "sleep":
      check_stack_size(1)
      sleep(parse_int(stack.pop()[1]))
    of "break":  break
    of "get_key": stack &= (ct_str, $get_key())
    of "current_day": stack &= (ct_str, $format(now(), "dddd"))
    of "=":
      if $stack.pop()[1] == $stack.pop()[1]: stack &= (ct_int, "1")
      else: stack &= (ct_int, "0")
    of "if":
      check_stack_size(1)
      if stack.pop()[1] == "1":
        exec_args(bargs)
      b_args = @[]
    of "loop":
      check_stack_size(1)
      loop_args(bargs, parse_int(stack.pop()[1]))
      b_args = @[]
    of "draw":
      check_stack_size(3)
      var dy: int = parse_int(stack.pop()[1])
      var dx: int = parse_int(stack.pop()[1])
      var dt: string = stack.pop()[1]
      tb.write(dx, dy, reset_style, bg_black, fg_white, dt)
      tb.display
    of "(": in_block += 1
    of ")": in_block -= 1 
    else:
      if is_num(arg):
        stack &= (ct_int, arg)
      elif arg[0] == ':':
        stack &= (ct_str, arg[1..^1])
      elif arg[0] == '#': continue
      else:
        cose_error("Unrecognized option `" & arg & "` ")

proc exec_script(path: string): void =
  var text: string = ""

  if file_exists(path):
    let f: File = open(path)
    text = read_all(f)
    close(f)

  var args:   seq[string] = split(multi_replace(text, ("\n", " ")), ' ')
  exec_args(args)

