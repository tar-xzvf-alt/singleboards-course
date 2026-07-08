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
    local style = "fontsize=\\footnotesize,breaklines=true,breakanywhere=true,tabsize=2,frame=leftline,framerule=3pt,framesep=8pt,rulecolor=\\color{bashframe},fillcolor=\\color{bashbg}"
    return pandoc.RawBlock("latex",
      "\\begin{Verbatim}[" .. style .. "]\n" .. text .. "\n\\end{Verbatim}")
  else
    local style = "fontsize=\\footnotesize,breaklines=true,breakanywhere=true,tabsize=2,frame=leftline,framerule=3pt,framesep=8pt,rulecolor=\\color{codeframe},fillcolor=\\color{codebg}"
    return pandoc.RawBlock("latex",
      "\\begin{Verbatim}[" .. style .. "]\n" .. text .. "\n\\end{Verbatim}")
  end
end
