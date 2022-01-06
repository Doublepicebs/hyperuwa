local KEYWORDS = {
  "and", "does", "die", "end", "else", "elsif", "false", "function", "for", "if", "in", "length", "not", "of", "or", "set", "to", "true", "then", "while"
}

function lex(src)
  
  local cur = 1
  local c = src:sub(cur,cur)
  local ln = 1
  local col = 1
  local tokens = {}
  
  local atend = function(offset)
    offset = offset or 0
    return (cur + offset > #src) or c == "EOF"
  end
  
  local advance = function()
    if atend(1) then
      c = "EOF"
      cur = cur + 1
    else
      cur = cur + 1
      c = src:sub(cur,cur)
      return c
    end
  end
  
  local add = function(token, kind)
    kind = kind or "SYMBOL"
    local tk = {
      token = token,
      kind = kind,
      position = {
        column = col,
        line = ln
      }
    }
    table.insert(tokens, tk)
  end
  
  local peek = function(offset)
    offset = offset or 1
    if atend() then return "EOF"
    else return src:sub(cur+offset,cur+offset)
    end
  end
  
  local iskeyword = function(val)
    for index, value in ipairs(KEYWORDS) do
        if value == val then
            return true
        end
    end
    return false
  end
  
  local isalpha = function(c)
    return not (string.match(c, "[%A]"))
  end
  
  local isnumber = function(c)
    return not (string.match(c, "[%D]"))
  end
  
  while (not atend()) or c ~= "EOF"  do
    
    if c == ' ' or c == "\t" then
      do end -- nothing
     -- NEWLINE
    elseif c == "\n" then
      add("NEWLINE", "ESCAPE")
      ln = ln + 1
    elseif c == '-' then
      -- COMMENTS
      if peek() == '-' then
        while (not atend()) do
          if c == "\n" then break end
          advance()
        end
      -- MINUS
      else
        add("MINUS")
      end
     -- GREATER THAN
    elseif c == '>' then
      if peek() == '=' then
        advance()
        add("GT_EQ")
      else
        add("GT")
      end
     -- LESS THAN
    elseif c == '<' then
      if peek() == '=' then
        advance()
        add("LT_EQ")
      else
        add("LT")
      end
     -- PLUS
    elseif c == '+' then
      add("PLUS")
     -- STAR
    elseif c == '*' then
      add("STAR")
     -- SLASH
    elseif c == '/' then
      add("SLASH")
     -- RBRACE
    elseif c == '}' then
      add("RBRACE")
     -- LBRACE
    elseif c == '{' then
      add("LBRACE")
     -- RPAREN
    elseif c == ')' then
      add("RPAREN")
     -- LPAREN
    elseif c == '(' then
      add("LPAREN")
    
     -- KEYWORD/IDENT
    elseif isalpha(c) then
      local v = ""
      while isalpha(c) or isnumber(c) do
        v = v..c
        advance()
      end
      if iskeyword(v) then
        add(v, "KEYWORD")
      else
        add(v, "IDENT")
      end
      goto continue

     -- STRINGS
    elseif c == '"' then
      local original_col = col
      local original_ln = ln
      local v = ""
      advance()
      while c ~= '"' do
        v = v..c
        advance()
        if atend() or c == "EOF" then
          Error.err("unterminated string", original_ln, original_col)
        end
      end
      add(v, "STRING")
    
     -- NUMBERS
    elseif isnumber(c) then
      local v = ""
      while isnumber(c) do 
        v = v..c
        advance()
      end 
      if c == '.' and isnumber(peek()) then 
        v = v..c
        advance()
        while isnumber(c) do 
          v = v..c
          advance()
        end
      end
      add(tonumber(v), "NUMBER")
    
    else
      add(c)
    end



    advance()
    ::continue::
  end
  
  return tokens
end