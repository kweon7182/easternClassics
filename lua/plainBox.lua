local parsing   = require("lua.parsing")
local tokenType = parsing.tokenType
local charType  = parsing.charType


-- A class of text boxes
local box = {
   -- initialX,initialY,
   -- blockWidth,blockHeight,
   -- numberOfColumns,numberOfRows
   functions     = {},
}

--Output: a new box object
function box:new(obj)
   obj           = obj           or {}
   obj.functions = obj.functions or {}
   setmetatable(obj,           {__index = self})
   setmetatable(obj.functions, {__index = self.functions})
   return obj
end

--Output: the current coordinate
function box:currentPosition()
   return self.initialX - self.blockWidth *self.currentColumn
   ,      self.initialY - self.blockHeight*self.currentRow
end


function box:interpret(tokens)
   local result = ""

   while not tokens:isEmpty() do
      -- Get a new token 'tok', and it's super type 'typ'
      local tok = tokens:popLeft()
      local typ = parsing.type(tok)

      -- Get a new TeX output, which is 'nil' if invalid
      local newTexPrint
      while typ do
	 if self.functions[typ] then
	    newTexPrint = self.functions[typ](self,tok)
	    break
	 else
	    typ = typ.parent()
	 end
      end

      -- Append the output to the result if succeeded
      if newTexPrint then
	 result = result .. newTexPrint
      else
	 tokens.pushLeft(tok)
	 break
      end
   end
   return result
end


--[[ Here is the definition of commands ]]--

--Effect: do nothing
box.functions["none"] = function(self)
   return ""
end

--Effect: "end of a column" means "go to the next column"
--        "end of the page" means "return nil"
--Note:   you must run this command before write a new block
box.functions["getColumn"] = function(self)
   if self.currentColumn >= self.numberOfColumns then
      return nil
   else
      return ""
   end
end

box.functions["nextColumn"] = function(self,num)
   num = tonumber(num) or 1
   self.currentColumn = self.currentColumn + num
   self.currentRow    = 0
   return ""
end

--Effect: go to the next column
box.functions["newColumn"] = function(self)
   if not self.functions["getColumn"](self) then
      return nil
   end
   return box.functions["nextColumn"](self)
end

--Effect: "end of a column" means "go to the next column"
--        "end of the page" means "return nil"
--Note:   you must run this command before write a new block
box.functions["getBlock"] = function(self)
   if self.currentRow >= self.numberOfRows then
      box.functions["nextColumn"](self)
   end
   return self.functions["getColumn"](self)
end


box.functions["nextBlock"] = function(self,num)
   num = tonumber(num) or 1
   self.currentRow = self.currentRow + num
   return ""
end


--Effect: go to the next block
box.functions["newBlock"] = function(self)
   if not self.functions["getBlock"](self) then
      return nil
   end
   return self.functions["nextBlock"](self)
end

--Effect: go to the next page
box.functions["newPage"] = function(self)
   self.currentColumn = self.numberOfColumns
   self.currentRow    = 0
   return ""
end

--[[box.functions["popSapces"] = function(self)
   while not self.tokens.isEmpty()
   and parsing.type(self.tokens[1]).ofType(tokenType.space) do
      self.tokens.popLeft()
   end
   return ""
   end--]]

box.functions["changeVariable"] = function(self,var,val)
   self[var] = tonumber(val) or val
   return ""
end

--Input:  a character <token> and options in a string <opt>
--Output: write the given character with the option
--Effect: go to the next row
box.functions["put"] = function(self,token,opt)
   if not self.functions["getBlock"](self) then return nil end
   
   local curX, curY = self:currentPosition()
   local result = ""
   if token:len() > 0 then
      result = result .. string.format("\\node[%s] at (%f,%f){%s};\n",
				       opt or "",curX,curY,token)
   end
   self.functions["nextBlock"](self)
   return result
end

box.functions["cursor"] = function(self,name)
   name = name or "cursor"
   local curX, curY = self:currentPosition()
   return string.format("\\coordinate(%s) at (%f,%f);\n",
			name,curX,curY)
end

box.functions["putChar"] = function(self,char,opt,typeChar,nodeName)
   typeChar = char or ""
   opt      = opt  or ""
   return self.functions[parsing.type(typeChar)](self,char,opt)
end

--[[box.functions["putCommand"] = function(self,com,...)
   local tok = '\\'..com
   for _,arg in ipairs({...}) do
      tok = tok .. '{' .. arg .. '}'
   end
   return self.functions["put"](self,tok,opt)
   end--]]


box.functions["colorBox"] = function(self,color)
   if not self.functions["getBlock"](self) then
      return nil
   end
   color = color or "{rgb:red,6;magenta,2;white,4}"
   local x,y = self:currentPosition()
   local str =
      "\\fill[color=%s] (%f,%f) rectangle (%f,%f);\n"
   return str:format(color
		     ,x-self.blockWidth/2,y-self.blockHeight/2
		     ,x+self.blockWidth/2,y+self.blockHeight/2)
end

--Output: write the given character
--Effect: go to the next row
box.functions[charType] = function(self,token,option)
   return self.functions["put"](self,token,option)
end

--Input:  a token [fun|arg1|arg2|...]
--Effect: run a command fun(arg1,arg2,...)
box.functions[tokenType.command] = function(self,tok)
   local sep = tok:find("|")
   if sep then
      return self.functions[tok:sub(2,sep-1)]
            (self,parsing.separateArguments(tok,sep+1,tok:len()-1))
   else
      return self.functions[tok:sub(2,tok:len()-1)](self)
   end
end

--Effect: spaces are ignored
box.functions[tokenType.space] = function(self,tok)
   return ""
end

return {box = box}
