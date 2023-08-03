proc string_to_bg_col(color: string): BackgroundColor =
  case color
  of "black":   return bg_black
  of "red":     return bg_red
  of "green":   return bg_green
  of "yellow":  return bg_yellow
  of "blue":    return bg_blue
  of "magenta": return bg_magenta
  of "cyan":    return bg_cyan
  of "white":   return bg_white
  else:         return bg_black

proc string_to_fg_col(color: string): ForegroundColor =
  case color
  of "black":   return fg_black
  of "red":     return fg_red
  of "green":   return fg_green
  of "yellow":  return fg_yellow
  of "blue":    return fg_blue
  of "magenta": return fg_magenta
  of "cyan":    return fg_cyan
  of "white":   return fg_white
  else:         return fg_black
  
proc to_number(s: string): string =
  case s
  of "One":   return "1"
  of "Two":   return "2"
  of "Three": return "3"
  of "Four":  return "4"
  of "Five":  return "5"
  of "Six":   return "6"
  of "Seven": return "7"
  of "Eight": return "8"
  of "Nine":  return "9"
  of "Zero":  return "0"
  else: return "nan"
