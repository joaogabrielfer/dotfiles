if exists("b:current_syntax")
  finish
endif

syntax keyword slurKeyword fun call if else var into quit
syntax keyword slurFunction push pop drop dup swap splitb len rot over
syntax keyword slurOperator add sub mul div neg eq lt gt and or
syntax keyword slurBoolean true false
syntax match slurNumber "\v-?\d+"
syntax region slurString start=/"/ skip=/\\"/ end=/"/
syntax match slurComment ";;.*$"

highlight default link slurKeyword Keyword
highlight default link slurFunction Function
highlight default link slurOperator Operator
highlight default link slurBoolean Boolean
highlight default link slurNumber Number
highlight default link slurString String
highlight default link slurComment Comment

let b:current_syntax = "slur"
