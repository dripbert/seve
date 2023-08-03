import times
import illwill
import os, strutils, sequtils
include util

var debug_msg: string = ""

var line_numbers_show: bool = true
var line_num_bg_col: BackgroundColor = bg_black
var line_num_fg_col: ForegroundColor = fg_white
var cursor_bg_col: BackgroundColor = bg_white
var text_fg_col: ForegroundColor = fg_white
var text_bg_col: BackgroundColor = bg_black
var tb: TerminalBuffer

proc load_conf_vars(): void
proc exec_script_command(cmd: string, val: string): void

include cose
include main 

proc resolve_flags(): void =
  for i in countup(1, param_count()):
    debug_msg = param_str(i)
    case param_str(i):
      of "--cose_script":
        exec_script(param_str(i + 1))
        quit(0)
      of "-cs":
        exec_script(param_str(i + 1))
        quit(0)
      else:
        discard
         

get_external_commands()

proc exec_script_command(cmd: string, val: string): void =
  case cmd
  of "goto-line": line_goto(parse_int(val))
  of "set-cursor-pos": posx = parse_int(val)
  of "msg": panel_msg(0, ">> " & val, width, height)
  of "delete-line": line_delete(parse_int(val))
  of "open": file_open(val)
  elif contains(ext_commands & commands, cmd):
    exec_command(cmd)
  else:
    panel_msg(0, "command not found: " & val , width, height)
  render_text(buffer, posx, posy)
  tb.display()

proc load_conf_vars(): void =
  exec_script(seve_dir & "seve.cos")
  for opt in opts:
    case opt[0]
    of "line-nums":
      if   opt[1] == "false":
        line_numbers_show = false
      elif opt[1] == "true":
        line_numbers_show = true
    of "line-num-bg":
      line_num_bg_col = string_to_bg_col(opt[1])
    of "line-num-fg":
      line_num_fg_col = string_to_fg_col(opt[1])
    of "cursor-bg":
      cursor_bg_col = string_to_bg_col(opt[1])
    of "text-col-fg":
      text_fg_col = string_to_fg_col(opt[1])
    of "text-col-bg":
      text_bg_col = string_to_bg_col(opt[1])
    else: 
      discard

resolve_flags()

iw_init()
load_conf_vars()
main_loop()
