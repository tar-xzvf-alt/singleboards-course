-- Lua-фильтр pandoc: выделяет bash-команды и исходный код разными цветами
-- Bash (или без языка): голубовато-серый фон
-- C/Python/Arduino: светло-серый фон

local function is_bash(lang)
  lang = lang or ""
  return lang == "" or lang == "bash" or lang == "sh" or lang == "shell"
end

function CodeBlock(block)
  local lang = block.classes[1] or ""
  local text = block.text
  
  if is_bash(lang) then
    local style = "language=bash,backgroundcolor=\\color{bashbg},frame=leftline,framerule=3pt,rulecolor=\\color{bashframe}"
    return pandoc.RawBlock("latex",
      "\\begin{lstlisting}[" .. style .. "]\n" .. text .. "\n\\end{lstlisting}")
  else
    local style = "backgroundcolor=\\color{codebg},frame=leftline,framerule=3pt,rulecolor=\\color{codeframe}"
    return pandoc.RawBlock("latex",
      "\\begin{lstlisting}[" .. style .. "]\n" .. text .. "\n\\end{lstlisting}")
  end
end
