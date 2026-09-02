-- Lua-фильтр pandoc: оформляет код и семантические блоки для PDF.

local function is_bash(lang)
  lang = lang or ""
  return lang == "" or lang == "bash" or lang == "sh" or lang == "shell"
end

function CodeBlock(block)
  if not FORMAT:match("latex") then
    return nil
  end

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

local alert_environments = {
  note = "notebox",
  tip = "tipbox",
  warning = "warningbox",
  caution = "cautionbox"
}

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

local function wrap_blocks(blocks, environment)
  local result = {
    pandoc.RawBlock("latex", "\\begin{" .. environment .. "}")
  }
  for _, block in ipairs(blocks) do
    table.insert(result, block)
  end
  table.insert(result,
    pandoc.RawBlock("latex", "\\end{" .. environment .. "}"))
  return result
end

local function alert_from_blockquote(quote)
  local first = quote.content[1]
  if not first or (first.t ~= "Para" and first.t ~= "Plain") then
    return nil
  end

  local marker = first.content[1]
  if not marker or marker.t ~= "Str" then
    return nil
  end

  local kind = marker.text:match("^%[!(%u+)%]$")
  if not kind then
    return nil
  end

  local environment = alert_environments[kind:lower()]
  if not environment then
    return nil
  end

  table.remove(first.content, 1)
  if first.content[1] and
      (first.content[1].t == "SoftBreak" or first.content[1].t == "Space") then
    table.remove(first.content, 1)
  end
  if #first.content == 0 then
    table.remove(quote.content, 1)
  end

  return wrap_blocks(quote.content, environment)
end

function BlockQuote(quote)
  if not FORMAT:match("latex") then
    return nil
  end
  return alert_from_blockquote(quote)
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
  for class, environment in pairs(alert_environments) do
    if has_class(div, class) then
      if div.content[1] and has_class(div.content[1], "title") then
        table.remove(div.content, 1)
      end
      return wrap_div(div, environment)
    end
  end
end
