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

local function has_class(div, class)
  for _, value in ipairs(div.classes) do
    if value == class then
      return true
    end
  end
  return false
end

local function wrap_div(div, environment)
  local blocks = {
    pandoc.RawBlock("latex", "\\begin{" .. environment .. "}")
  }
  for _, block in ipairs(div.content) do
    table.insert(blocks, block)
  end
  table.insert(blocks,
    pandoc.RawBlock("latex", "\\end{" .. environment .. "}"))
  return blocks
end

function Div(div)
  if not FORMAT:match("latex") then
    return nil
  end
  if has_class(div, "attention") then
    return wrap_div(div, "attentionbox")
  end
  if has_class(div, "additional") then
    return wrap_div(div, "additionalbox")
  end
end
