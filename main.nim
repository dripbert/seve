const chars: string = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const numbers: string = "1234567890"
const seve_dir: string = expand_tilde("~/.seve.d/")

var buffer:    string = ""
var file_name: string = ""

const commands: seq[string] = @["draw-cow", "goto-line", "help", "open", "quit", "reload-conf", "save", "toggle-line-num"]
var ext_commands: seq[string] = @[]

proc get_command(p: string, w: int, h: int): string
proc curs_up(): void
proc render_text(text: string, cx: int, cy: int): void

proc exit_proc() {.noconv.} =
  illwill_deinit()
  show_cursor()
  echo "\n" & buffer
  echo "---------------"
  echo "DEBUG MESSAGE:"
  echo debug_msg
  quit(0)

proc iw_init(): void =
  illwill_init(fullscreen=true)
  set_control_c_hook(exit_proc)
  hide_cursor()

var width  = terminal_width()
var height = terminal_height()

tb = newTerminalBuffer(width, height)
var posx: int = 0
var posy: int = 0
var xshift: int = 2 # shift on osx for line numbers

proc panel_print(width: int, heigth: int): void =
  var txt: string = "seve 0.0.0 | L" & $posy & ", C" & $posx
  var txtlen: int = len(txt)
  tb.write(0, heigth - 1, bg_white, fg_black, txt & repeat(" ", width - txtlen))

proc panel_msg(offset: int, msg: string, w: int, h: int): void =
  tb.write(0 + offset, h - 1, bg_white, fg_black, msg & repeat(" ", w - len(msg) - offset))


proc get_eol(text: string, line: int): int =
  var lines = split(text, '\n')
  var i: int = 0
  for l in lines:
    if i == line:
      return len(l)
    i += 1

proc posy_to_posx(text: string, y: int): int =
  var i: int = 0
  var s: int = 0
  while i <= y:
    s += get_eol(text, i) + 1
    i += 1
  return s

proc clear_scr(): void =
  tb.write(0, 0, reset_style, bg_black, fg_white, "")
  tb.clear()

# doesn't work very well yet
proc line_delete(l: int): void =
  var l1: int = posy_to_posx(buffer, l) 
  var l2: int = get_eol(buffer, l)
  buffer = buffer[0..l1 - l2] & buffer[l1]
  posx = 0
  curs_up()
  render_text(buffer, posx, posy)

proc line_count_get(text: string): int =
  return len(split(text, '\n'))

proc line_numbers_toggle(): void =
  line_numbers_show = not line_numbers_show
  if line_numbers_show:
    xshift = len($(line_count_get(buffer))) + 1
  else:
    xshift = 0
  clear_scr()

proc line_clear(l: int): void =
  tb.write(0, l, reset_style, bg_black, fg_white, repeat(" ", width))

proc line_goto(l: int): void =
  if line_count_get(buffer) >= l and l > 0:
    if posx > get_eol(buffer, posy):
      posx = get_eol(buffer, posy)
    posy = l - 1

# This funcion cuts text according to y1, y2
proc text_to_scope(text: string, x1: int, y1: int, x2: int, y2: int): string =
  var p1: int = 0

  if y1 > 0:
    p1 = posy_to_posx(text, y1 - 1)

  var p2: int = posy_to_posx(text, y2)

  if p2 > len(text):
    p2 = len(text)

  var scope: string = text[p1..p2 - 1]
  return scope


proc render_text(text: string, cx: int, cy: int): void =
  var x: int = 0
  var y: int = 0
  var ln_offset: int = 0 # line number offset
  var sc: int = cy # curser position on the scope in contrast to cy, which is on the buffer

  var sbuffer: string = text
  if cy - ln_offset > height - 2: 
    ln_offset = (cy div (height - 1)) * (height - 1)
    sc = cy - ln_offset
    sbuffer = text_to_scope(text, 0, ln_offset, 0, ln_offset + height) # sbuffer is the part of the buffer, that is within the scope
  
  var lines = split(sbuffer, '\n')
  apply(lines, proc(x: var string) = x &= " ")
  for ln in lines:
    # display line numbers
    if line_numbers_show:
      if cy == y + ln_offset:
        tb.write(0, y, style_italic, line_num_bg_col, line_num_fg_col, repeat(" ", xshift - len($(y + 1 + ln_offset))) & $(y + 1 + ln_offset) & " ")
      else:
        tb.write(0, y, style_dim, line_num_bg_col, line_num_fg_col, repeat(" ", xshift - len($(y + 1 +  ln_offset))) & $(y + 1 + ln_offset) & " ")
    for ch in ln:
      if y == sc and x == cx: # if this is where cursor is
        tb.write(x + xshift, y, reset_style, cursor_bg_col, fg_black, $ch)
      else:
        tb.write(x + xshift, y, reset_style, text_bg_col, text_fg_col, $ch)
      x += 1

    y += 1
    x = 0

  panel_print(width, height)

proc curs_left(): void =
  if posx > 0 or posy > 0:
    posx -= 1

proc curs_rigth(): void =
  if posx < len(buffer) or posy < line_count_get(buffer):
    posx += 1

proc curs_up(): void =
  if posy > 0:
    posy -= 1
    if get_eol(buffer, posy) < posx:
      posx = get_eol(buffer, posy)
proc curs_down(): void =
  if line_count_get(buffer) > posy + 1:
    if posx > get_eol(buffer, posy + 1):
      posx = get_eol(buffer, posy + 1)
    posy += 1

proc file_open(fstr: string): void =
  if not file_exists(fstr):
    write_file(fstr, "")
  let f: File = open(fstr, fm_read) 
  file_name = fstr
  buffer = read_all(f)
  posx = 0
  posy = 0
  close(f)

proc file_write(fstr: string): void =
  write_file(fstr, buffer) 


proc exec_command(c: string): void =
  case c
  of "draw-cow":
    tb.write(10, 10, reset_style, bg_black, fg_white, "^oo^")
    tb.write(10, 11, reset_style, bg_black, fg_white, "(..)______-_.")
    tb.write(10, 12, reset_style, bg_black, fg_white, "  | |   ||")
    panel_msg(0, "cow drawn", width, height)
  of "save":
    if file_name == "":
      file_name = get_command("Save as: ", width, height)
    file_write(file_name)
  of "help":
    file_open(seve_dir & "doc/help.txt")
  of "open":
    file_open(get_command("File: ", width, height))
  of "quit":
    exit_proc()
  of "goto-line":
    line_goto(parse_int(get_command("Line: ", width, height)))
  of "toggle-line-num":
    line_numbers_toggle()
  of "reload-conf":
    load_conf_vars()
  else:
    if contains(ext_commands, c):
      exec_script(seve_dir & "commands/" & c)
    else:
      panel_msg(0, "command not found " & c, width, height)
  tb.display()


proc get_command(p: string, w: int, h: int): string =
  var txt: string = p & "_"
  var command: string = ""
  while true:
    var key = get_key()
    var keystr: string = $key
    case keystr
    of "Minus":
      command &= "-"
    of "Backspace":
      if len(command) > 0:
        command = command[0..^2]
    of "Slash":
      command &= "/"
    of "Dot":
      command &= "."
    of "Enter":
      line_clear(height - 2)
      return command
    of "Tab":
      var w: int = width
      var i: int = 1
      var o: int = 0
      var cs: seq[string] = commands & ext_commands
      for s in cs:
        if len(command) > len(s):
          continue
        if s[0..len(command) - 1] == command:
          if len(s) < w:
            panel_msg(o, s & ",", width, height - i)
            w -= len(s) + 2
            o += len(s) + 2
          else:
            i += 1
            w = width
            o = 0
            panel_msg(o, s, width, height - i)
    else:
      if contains(chars, keystr):
        command &= strutils.to_lower_ascii(keystr)
      elif contains(numbers, to_number(keystr)):
        command &= to_number(keystr)
    if keystr != "None":
      txt = p & command & "_"
    sleep(40)

    tb.write(0, height - 1, bg_white, fg_black, txt & repeat(" ", width - len(txt) + 2))

    tb.display()
    width  = terminal_width()
    height = terminal_height()

proc get_external_commands(): void =
  for kind, path in walk_dir(seve_dir & "commands/"):
    if kind == pc_file:
      ext_commands &= last_path_part(path)

proc inp(): void =
  let key = get_key()
  var keystr: string = $key
  var upper: bool = false
  var fstr: string = ""
  var wrt: bool = true

  if keystr[0..^2] == "Shift":
    upper = true
    keystr = $keystr[^1]

  if contains(chars, keystr):
    if not upper:
      fstr = strutils.to_lower_ascii(keystr)
    else:
      fstr = keystr
  else:
    case keystr
    of "None": return
    of "Ampersand": fstr = "&"
    of "Asterisk": fstr = "*"
    of "At": fstr = "@"
    of "Caret": fstr = "^"
    of "Colon": fstr = ":"
    of "Comma": fstr = ","
    of "Dollar": fstr = "$"
    of "Space": fstr = " "
    of "Tilde": fstr = "~"
    of "QuestionMark": fstr = "?"
    of "ExclamationMark": fstr = "!"
    of "LeftParen": fstr = "("
    of "RightParen": fstr = ")"
    of "LeftBrace": fstr = "{"
    of "RightBrace": fstr = "}"
    of "LeftBracket": fstr = "["
    of "RightBracket": fstr = "]"
    of "Hash": fstr = "#"
    of "Percent": fstr = "%"
    of "Enter":
      clear_scr()
      var x: int = posy_to_posx(buffer, posy) - (get_eol(buffer, posy) - posx)
      buffer = buffer[0..x - 2] & "\n" & buffer[x - 1..^1]
      posx = 0
      posy += 1
      if line_numbers_show:
        xshift = len($(line_count_get(buffer))) + 1 # set xshift to length of the longest line number
    of "CtrlN": exec_command(get_command("CtrlN ", width, height))
    of "Backspace":
      var x: int = posy_to_posx(buffer, posy) - (get_eol(buffer, posy) - posx) - 1
      if x < 1: return
      if x < len(buffer):
        buffer = buffer[0..x - 2] & buffer[x..^1]
      else:
        buffer = buffer[0..^2]
      var eol: int = get_eol(buffer, posy)
      tb.write(eol, posy, bg_black, fg_white, repeat(" ", width - eol))
      curs_left()
      if line_numbers_show:
        xshift = len($(line_count_get(buffer))) + 1 # set xshift to length of the longest line number
      wrt = false
      tb.write(0, 0, reset_style, bg_black, fg_white, "")
      tb.clear()
    of "Left":
      curs_left()
      wrt = false
    of "Right":
      curs_rigth()
      wrt = false
    of "Up":
      curs_up()
      wrt = false
    of "Down":
      curs_down()
      wrt = false
    else:
      fstr = keystr
    
  if wrt:
    var x: int = posy_to_posx(buffer, posy) - (get_eol(buffer, posy) - posx)
    buffer = buffer[0..x - 2] & fstr & buffer[x - 1..^1]
    posx += 1

  if posx < 0:
    posy -= 1
    posx = get_eol(buffer, posy)
  elif posx > get_eol(buffer, posy):
    if line_count_get(buffer) > posy + 1:
      posy += 1
      posx = 0
    else:
      posx = posx - 1

proc main_loop(): void =
  while true:
    var t = cpu_time()
    inp()
    render_text(buffer, posx, posy)

    tb.display()
    width  = terminal_width()
    height = terminal_height()

    #debug_msg = $(cpu_time() - t)
    if (cpu_time() - t) * 1000 > 40: continue
    sleep(40 - (int)((cpu_time() - t) * 1000))

# Beware of off-by-one-errors! They're everywhere.

# TODO: when backspacing across a line break, don't move curser to end of line
# TODO: add support for multiple buffers
# TODO: handle upper case letters for the command prompt
# TODO: fix white stuff after quitting
# TODO: replace string with rope for buffer
