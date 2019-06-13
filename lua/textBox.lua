local plainBox = require("lua.plainBox").box
local parsing  = require("lua.parsing")
local charType = parsing.charType


-- A class of text boxes with some options
local textBox = plainBox:new()
textBox.options = {}

function textBox:new(obj)
   obj         = obj         or {}
   obj.options = obj.options or {}
   setmetatable(obj.options, {__index = self.options})
   return plainBox.new(self,obj)
end

--Output: the current coordinate
function textBox:currentPosition()
   return self.initialX - self.blockWidth *(self.currentColumn + 1/2)
   ,      self.initialY - self.blockHeight*(self.currentRow    + 1/2)
end

function textBox:interpret(tokens)
   self.tokens = tokens
   if self.numberOfRows <= 0 then
      return ""
   end
   return plainBox.interpret(self,tokens)
end

-- Define textBox.functions[<type>] for every character type
local function enableOptions(typ)
   for _,subType in pairs(typ.children()) do
      enableOptions(subType)
   end
   textBox.functions[typ] = function(self,token,opt)
      opt = (self.options[typ] or "") .. "," .. (opt or "")
      if typ == charType then
	 return self.functions["put"](self,token,opt)
      else
	 return self.functions[typ.parent()](self,token,opt)
      end
   end
end
enableOptions(charType)

textBox.functions[charType.hangul] = function(self,token,opt)
   if not self.functions["getBlock"](self) then return nil end
   local block,tone = parsing.hangulToneSeparate(token)
   self.hangulMode = self.hangulMode or 1
   
   local hopt = (self.options[charType]             or "")
      ..","..   (self.options[charType.hangul]      or "")
   local topt = hopt
      ..","..   (self.options[charType.hangul.tone] or "")
   hopt = hopt..","..(opt or "")
   topt = topt..","..(opt or "")..[[,shift=($(T.west)-(B.west)$)]]

   local result = "\\node[%s](B) at (0,0){\\phantom{%s}};"
      ..          "\\node[%s](T) at (0,0){\\phantom{%s}};"
   result = result:format(hopt,block,hopt,token)

   if     self.hangulMode == 0 or tone == "" then
      return self.functions["put"](self,token,hopt) 
   elseif self.hangulMode == 1 then
      return result .. self.functions["put"](self,token,topt)
   elseif self.hangulMode == 2 then
      result = result .. self.functions["put"](self,block,hopt)
      self.functions["nextBlock"](self,"-1")
      token = "\\setScriptOption{"..tone.."}\\setScriptOption[Hangul]{\\phantom{"..block.."}}"
      return result .. self.functions["put"](self,token,topt)

   else -- unknown mode
      return self.functions["put"](self,token,hopt..",red")
   end
end

--[[textBox.functions[charType.hangul] = function(self,token,opt)
   if not self.functions["getBlock"](self) then
      return nil
   end
   
   self.hangulMode = self.hangulMode or 1
   opt = opt or ""
   local hopt = self.options[charType.hangul]      or ""
   local topt = self.options[charType.hangul.tone] or ""
   
   if self.hangulMode%2 == 1 then
      local token,tone = parsing.hangulToneSeparate(token)
      token  = "\\addfontfeature{Script=Hangul}"..token
      local  result =  self.functions[charType](self,token,hopt..","..opt)
      self.currentRow = self.currentRow - 1
      tone = "\\addfontfeature{Script=Default}"..tone
      return result .. self.functions[charType](self,tone ,topt..","..opt)
   else
      local _,tone = parsing.hangulToneSeparate(token)
      token  = "\\addfontfeature{Script=Hangul}"..token
      if tone == "" then
	 return self.functions[charType](self,token,hopt..           ","..opt)
      else
	 return self.functions[charType](self,token,hopt..","..topt..","..opt)
      end
   end
   end--]]


--Effect: indent
textBox.functions["indent"] = function(self,num)
   num = tonumber(num) or 1
   self.initialY = self.initialY - num*self.blockHeight
   self.numberOfRows = self.numberOfRows - num
   if self.currentRow ~= 0 then
      self.tokens.pushLeft("[newColumn]")
   end
   return ""
end


--Effect: express that the given tokens are uncertain
textBox.functions["?"] = function(self,tok)
   tok = tok or "？"
   tok = parsing.parsing(tok)
   while tok.notEmpty() do
      self.tokens.pushLeft("[putChar|"..tok.popRight().."|text=white]")
      self.tokens.pushLeft("[colorBox]")
   end
   return ""
end

-- A class of text boxes with only one column
local verticalBox = textBox:new()
function verticalBox:new(obj)
   obj = textBox.new(self,obj)
   obj.numberOfColumns = 1
   obj.numberOfRows    = 1/0
   obj.blockWidth      = obj.blockWidth or obj.blockHeight
   return obj
end

function verticalBox:currentPosition()
   local half = 1/2
   if self.fixedBottom then half = -half end
   
   return self.initialX - self.blockWidth *self.currentColumn
   ,      self.initialY - self.blockHeight*(self.currentRow + half)
end


function verticalBox:interpret(tokens)
   if type(tokens)=="string" then
      tokens = parsing.parsing(tokens)
   end
   self.currentColumn,self.currentRow = 0,0
   if self.fixedBottom then
      textBox.interpret(self,tokens.copy())
      self.initialY = self.initialY + self.blockHeight*(self.currentRow-1)
      self.currentColumn,self.currentRow = 0,0
      return textBox.interpret(self,tokens)
   else
      return textBox.interpret(self,tokens)
   end
end

-- A class of comment boxes
local commentBox = textBox:new()

--Output: the current coordinate
function commentBox:currentPosition()
   return self.initialX - self.blockWidth *(self.currentColumn
					       - self.numberOfColumns/2 + 1/2)
   ,      self.initialY - self.blockHeight*(self.currentRow + 1/2)
end

function commentBox:interpret(tokens)
   local tempTokens = tokens.copy()
   
   self.currentColumn,self.currentRow = 0,0
   local tempResult = textBox.interpret(self,tokens)
   local result
   repeat
      result = tempResult
      tokens = tempTokens.copy()
      self.numberOfRows = self.numberOfRows - 1
      
      self.currentColumn,self.currentRow = 0,0
      tempResult = textBox.interpret(self,tokens)
   until tokens.notEmpty()
   return result
end


return {
   plainBox    = plainBox,
   textBox     = textBox,
   commentBox  = commentBox,
   verticalBox = verticalBox,
}
