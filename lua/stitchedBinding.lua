local box       = require("lua.textBox")
local parsing   = require("lua.parsing")
local drawing   = require("lua.drawing")
local deque     = require("lua.deque")
local charType  = parsing.charType
local tokenType = parsing.tokenType


-- A class of multiple boxes of the main body of an eastern classic
local stitchedBinding = box.textBox:new()
 
-- Default dimension of eastern classics
stitchedBinding.dimension = {
    marginTop         =  1.5,
    marginBottom      =  1,
    marginLeft        =  1,
    marginRight       =  1,
    marginInnerTop    =  0.1,
    marginInnerBottom =  0.1,
    marginInnerLeft   =  0,
    marginInnerRight  =  0,
    bodyHalfWidth     = 16,  
    bodyHeight        = 21,   
    centerWidth       =  1.5,
    numberOfColumns   =  8,  
    numberOfRows      = 15,
    
    lineThickness               =  0.05,     
    verticalLinesThickness      =  0.05,     
    horizontalLinesThickness    =  0.05,      
    tailNameUpper               = "firstTail",
    tailNameLower               = "firstTail",
    
    centerLineThicknessMultiple = 1/3 ,   
    centerLineUpperHeight       = 4.5 ,   
    centerLineLowerHeight       = 4.5 ,   
    chapterNameHeight           = 0.8125,
    pageNumberHeight            = 0.8125,
    commentBlockWidthMultiple   = 2/2.125,
    centerBlockHeight           = 1,      
}

stitchedBinding.boxes = {
   comment       = box.commentBox:new{
      numberOfColumns = 2
   },
   pronunciation = box.commentBox:new{
      numberOfColumns = 1,
   },
   
   center        = box.verticalBox:new{
      initialX     =   0},
   chapterName   = box.verticalBox:new{
      initialX     =   0},
   pageNumber    = box.verticalBox:new{
      initialX       = 0,
      fixedBottom    = true}
}

function stitchedBinding:new(obj)
   obj = obj  or {}
   
   obj.dimension = obj.dimension or {}
   obj.dimension.rectBoarder = obj.dimension.rectBoarder or deque.new()
   obj.dimension.sideBoarder = obj.dimension.sideBoarder or deque.new()
   setmetatable(obj.dimension,{__index = self.dimension})

   obj.boxes = {}
   for name,box in pairs(self.boxes) do
      obj.boxes[name] = box:new()
   end
   obj.boxes.main = obj

   obj.options = obj.options or {}
   setmetatable(obj.options,{__index = self.options})

   self.chapterName   = ""
   self.pageNumber    = nil
   obj = box.textBox.new(self,obj)
   return obj
end

stitchedBinding.functions["colorBox"] = function(self,color)
   if not self.functions["getBlock"](self) then
      return nil
   end
   color = color or "{rgb:red,6;magenta,2;white,4}"
   local x,y = self:currentPosition()
   local str =
      "\\fill[color=%s] (%f,%f) rectangle (%f,%f);\n"
   local ymin = y-self.blockHeight/2
   if self.currentRow >= self.numberOfRows-1 then
      ymin = -self.dimension.bodyHeight
   end
   local ymax = y+self.blockHeight/2
   if self.currentRow == 0 then
      ymax = 0
   end
   return str:format(color,x-self.blockWidth/2,ymin,x+self.blockWidth/2,ymax)
end


local function concatenateIf(original,flag,new)
   if flag then
      return original .. new
   else
      return orignal
   end
end

function stitchedBinding:onRightPage()
   return self.initialX > 0
end

function stitchedBinding:beginPage()
   self.currentColumn,self.currentRow = 0,0
   return "\\begin{newPage}\n\\begin{tikzpicture}\n"      
end

function stitchedBinding:middlePage()
   self.currentColumn,self.currentRow = 0,0
   self.initialX = self.initialX - self.pageDifferenceX
   return ""
end

function stitchedBinding:endPage()
      self.initialX = self.initialX + self.pageDifferenceX
   return self:centerText()
      .. self.template.paper
      .. "\\begin{scope}[on background layer]\n"
      .. "\\pic{boarderLines};\\pic{centerDrawinging};\\pic{customTemplate};"
      .. string.format("\\pic[xshift=%fcm]{verticalLines};\n"
		       ,-self.pageDifferenceX)
      .. "\\pic{verticalLines};\n\\end{scope}"
      .. "\\end{tikzpicture}\n\\end{newPage}"
end

function stitchedBinding:endPaper()
   if self:onRightPage() then
      return self:middlePage() .. self:endPage()
   else
      return self:endPage()
   end
end

function stitchedBinding:interpret(tokens)
   if type(tokens) == "string" then
      tokens = parsing.parsing(tokens)
   end

--   print("Send tokens to page "..tostring((self.pageNumber or 0)-1).." of "
--	    ..tostring(self.chapterName).." completed!")

   local result = box.textBox.interpret(self,tokens)
   if tokens:isEmpty() then
      return result
   elseif self:onRightPage() then
      return result..self:middlePage()               ..self:interpret(tokens)
   else
      return result..self:endPage()..self:beginPage()..self:interpret(tokens)
   end
  
   --[[   local result = ""
   
   print()-- only for dubegging
   while tokens:notEmpty() do
      self.centerDrawing,self.boarderDrawing = true,true   
      self.verticalDrawing = true
      self.currentColumn,self.currentRow = 0,0 --------------------------------------
      local rightText = box.textBox.interpret(self,tokens)
      if self.verticalDrawing then
	 rightText = rightText .. "\\pic{verticalLines};\n"
      end
      self.initialX = self.initialX - self.pageDifferenceX
      
      self.verticalDrawing = true
            self.currentColumn,self.currentRow = 0,0 --------------------------------------
      local leftText = box.textBox.interpret(self,tokens)
      if self.verticalDrawing then
	 leftText = leftText ..
	    string.format("\\pic[xshift=%fcm]{verticalLines};\n"
			  ,-self.pageDifferenceX)
      end
      self.initialX = self.initialX + self.pageDifferenceX

      if self.foldPaper then
	 result = result
	    .. "\\begin{newPage}\\begin{tikzpicture}\n" .. self.template.rightPaper
	 result = concatenateIf(result,self.boarderDrawing,"\\pic{boarderLines};" )
	 result = concatenateIf(result,self.centerDrawing, "\\pic{centerDrawinging};")
	 result = result .. self:centerText() .. rightText
         .. "\\end{tikzpicture}\\end{newPage}"
	 if self.pageNumber then
	    self.pageNumber = self.pageNumber - 1
	 end
	 result = result
	    .. "\\begin{newPage}\\begin{tikzpicture}\n" .. self.template.leftPaper
	 result = concatenateIf(result,self.boarderDrawing,"\\pic{boarderLines};" )
	 result = concatenateIf(result,self.centerDrawing, "\\pic{centerDrawinging};")
	 result = result .. self:centerText() .. leftText
         .. "\\end{tikzpicture}\\end{newPage}"
      else
	 result = result
	    .. "\\begin{newPage}\\begin{tikzpicture}\n" .. self.template.paper
	 result = concatenateIf(result,self.boarderDrawing,"\\pic{boarderLines};" )
	 result = concatenateIf(result,self.centerDrawing, "\\pic{centerDrawinging};")
	 result = result .. self:centerText() .. rightText .. leftText
         .. "\\end{tikzpicture}\\end{newPage}"
      end
   end
   self:print()--]]
end

-- only for dubegging
function stitchedBinding:print()
   print("---- Variables "..string.rep("-",24))
   local set = {}
   for _,box in pairs({self,stitchedBinding,box.textBox,box.plainBox}) do
      for key,_ in pairs(box) do
	 set[key] = true
      end
   end
   local array = {}
   for key,_ in pairs(set) do
      table.insert(array,key)
   end
   table.sort(array)
   for _,tp in ipairs{"boolean", "number", "string", "table", "function"} do
      for _,key in ipairs(array) do
	 if type(self[key]) == tp then
	    print(key..string.rep(" ",30-#key)..type(self[key]))
	 end
      end
   end
   print("---- functions ----"..string.rep("-",24))
   local set = {}
   for _,box in pairs({self,stitchedBinding,box.textBox,box.plainBox}) do
      for key,_ in pairs(box.functions) do
	 set[key] = true
      end
   end
   local array = {}
   for key,_ in pairs(set) do
      table.insert(array,tostring(key))
   end
   table.sort(array)
   for _,key in ipairs(array) do
      print(key)
   end
   print("---- end ----------"..string.rep("-",24))
end

function stitchedBinding:templateDrawing()
   self:setTemplate()
   return
      "  \\tikzset{clipPaper/.pic={\n"..
         self.template.paper..
      "}}\\tikzset{boarderLines/.pic={\n"..
         self.template.boarder..
      "}}\\tikzset{centerDrawinging/.pic={\n"..
         self.template.center ..
      "}}\\tikzset{verticalLines/.pic={\n"..
         self.template.vertical..
      "}}"
end

function stitchedBinding:centerText()
   local result = ""
   local dim = self.dimension

   local box = self.boxes.pageNumber
   box.initialY    = dim.centerLineLowerHeight - dim.bodyHeight
      + dim.pageNumberHeight * dim.centerWidth
   box.blockWidth  = dim.centerWidth
   box.blockHeight = dim.centerBlockHeight or 1
   if self.pageNumber then
      result = result .. box:interpret(parsing.numberInChinese(self.pageNumber))
      self.pageNumber = self.pageNumber + 1
   end

   local box = self.boxes.chapterName
   box.initialY    = - dim.centerLineUpperHeight
      - dim.chapterNameHeight * dim.centerWidth
   box.blockWidth  = dim.centerWidth
   box.blockHeight = dim.centerBlockHeight or 1
   result = result .. box:interpret(self.chapterName)

   return result
end

function stitchedBinding:setTemplate()
   local dim = self.dimension
   self.template = {}   
   self.template.paper =
      string.format("\\clip(%f,%f) rectangle (%f,%f);\n"
		    , dim.bodyHalfWidth+dim.marginRight
		    , dim.marginTop
		    ,-dim.bodyHalfWidth-dim.marginLeft
		    ,-dim.bodyHeight   -dim.marginBottom)
   self.template.rightPaper =
      string.format("\\clip(%f,%f) rectangle (%f,%f);\n"
		    , dim.bodyHalfWidth+dim.marginRight
		    , dim.marginTop
		    , 0
		    ,-dim.bodyHeight   -dim.marginBottom)
   self.template.leftPaper =
      string.format("\\clip(%f,%f) rectangle (%f,%f);\n"
		    , 0
		    , dim.marginTop
		    ,-dim.bodyHalfWidth-dim.marginLeft
		    ,-dim.bodyHeight   -dim.marginBottom)
   
   self.template.boarder = ""

   for _,nums in ipairs(dim.rectBoarder) do
      self.template.boarder = self.template.boarder ..
	 drawing.rectangle(
              dim.bodyHalfWidth-dim.verticalLinesThickness/2+nums[1]
	    ,                                                nums[1]
	    ,-dim.bodyHalfWidth+dim.verticalLinesThickness/2-nums[1]
	    ,-dim.bodyHeight                                -nums[1]
	    , nums[2])
   end
   for _,nums in ipairs(dim.sideBoarder) do
      self.template.boarder = self.template.boarder ..
	 drawing.line(
              dim.bodyHalfWidth-dim.verticalLinesThickness/2+nums[1]+nums[3]/2
	    ,                                                nums[2]
	    , dim.bodyHalfWidth+dim.verticalLinesThickness/2+nums[1]+nums[3]/2
	    ,-dim.bodyHeight                                -nums[2]
	    , nums[3]) ..
	 drawing.line(
             -dim.bodyHalfWidth-dim.verticalLinesThickness/2-nums[1]-nums[3]/2
	    ,                                                nums[2]
	    ,-dim.bodyHalfWidth+dim.verticalLinesThickness/2-nums[1]-nums[3]/2
	    ,-dim.bodyHeight                                -nums[2]
	    , nums[3])
   end
   
   self.template.center =
      drawing.line(-dim.centerWidth/2,0,-dim.centerWidth/2,-dim.bodyHeight,
		 dim.lineThickness)                                        ..
      drawing.line( dim.centerWidth/2,0, dim.centerWidth/2,-dim.bodyHeight,
		 dim.lineThickness)                                       ..
      drawing.line(0,0,0,-dim.centerLineUpperHeight,
		dim.centerWidth*dim.centerLineThicknessMultiple)          ..
      drawing.line(0,-dim.bodyHeight,
		0,-dim.bodyHeight+dim.centerLineLowerHeight,
		dim.centerWidth*dim.centerLineThicknessMultiple)          ..
      string.format("\\pic[yshift=%fcm,yscale=-1,scale=%f]{%s};\n"
		    ,-dim.centerLineUpperHeight
		    ,dim.centerWidth-dim.verticalLinesThickness
		    ,dim.tailNameUpper)                                       ..
      string.format("\\pic[yshift=%fcm,scale=%f]{%s};\n"
		    ,-dim.bodyHeight+dim.centerLineLowerHeight
		    ,dim.centerWidth-dim.verticalLinesThickness
		    ,dim.tailNameLower)                        

   self.template.vertical = ""
   for i = 1,self.numberOfColumns-1 do
      local x = dim.centerWidth/2 + dim.marginInnerLeft + i*self.blockWidth
      local y = dim.centerWidth/2 + dim.marginInnerLeft + i*self.blockWidth
      self.template.vertical = self.template.vertical ..
	 drawing.line(x,0,x,-dim.bodyHeight,dim.verticalLinesThickness)
   end
end

stitchedBinding.functions["newPaper"] = function(self)
   if self:onRightPage() then
      return nil
   else
      return self.functions["newPage"](self)
   end
   
end

stitchedBinding.functions["chapter"] = function(self,chapter,page)
   if self.currentRow == 0 and self.currentColumn == 0 and self.initialX > 0 then
      self.chapterName = chapter
      if page == "" or page == "noNumber" then
	 self.pageNumber = nil
      else
	 self.pageNumber        = tonumber(page) or 1
      end
      return ""
   else
      return nil
   end
end

stitchedBinding.functions["postposition"] = function(self,tokens)
   return self.functions["comment"](self,tokens)
end

stitchedBinding.functions["subboxInterpret"] = function(self)
   if not self.functions["getBlock"](self) then
      return nil
   end
   
   self.subbox.initialX, self.subbox.initialY
                            = self:currentPosition()
   self.subbox.initialY     = self.subbox.initialY + self.blockHeight/2
   self.subbox.numberOfRows = 1*(self.numberOfRows - self.currentRow)
    
   local result = self.subbox:interpret(self.subtokens)
   
   self.currentRow = self.currentRow + self.subbox.numberOfRows + 1
   if self.subtokens.notEmpty() then
      self.tokens.pushLeft("[subboxInterpret]")
   else
      self.subtokens  = nil
      self.subbox     = nil
   end
   return result
end

-- Implemented
stitchedBinding.functions["comment"] = function(self,tokens)
   self.subtokens = parsing.parsing(tokens)
   
   self.subbox = self.boxes.comment
   self.subbox.blockWidth  = self.blockWidth/2
      *self.dimension.commentBlockWidthMultiple
   self.subbox.blockHeight = self.blockHeight
   self.subbox.hangulMode  = self.hangulMode
   
   self.tokens.pushLeft("[subboxInterpret]")
   return ""
end

stitchedBinding.functions["pronunciation"] = function(self,tokens)
   if not self.functions["getBlock"](self) then
      return nil
   end
   
   local box = self.boxes.pronunciation
   box.initialX,box.initialY = self:currentPosition()
   box.initialY     = box.initialY + self.blockHeight/2
   box.numberOfRows = 1
   if     box.numberOfColumns == 1 then
      box.blockWidth   = self.blockWidth
   elseif box.numberOfColumns == 2 then
      box.blockWidth = self.blockWidth/2
	 * self.dimension.commentBlockWidthMultiple
   end
   box.blockHeight = self.blockHeight
   box.hangulMode  = self.hangulMode

   local result = box:interpret(parsing.parsing(tokens))
   self.currentRow = self.currentRow + 1
   return result
end

stitchedBinding.functions["headnote"] = function(self,token,opt)
   if not self.functions["getBlock"](self) then return nil end
   
   local curX, curY = self:currentPosition(), 0
   if #self.dimension.rectBoarder > 0 then
      curY = self.dimension.rectBoarder[#self.dimension.rectBoarder][2]
   end
   return string.format("\\node[%s,anchor=south] at (%f,%f){%s};\n",
				opt or "",curX,curY,token)
end

--[[ ideographMode, 
stitchedBinding.functions[charType.ideograph] = function(self,token,option)
   local pronunciation,postposition = "",""
   self.functions["popSapces"](self)
   self.ideographMode = self.ideographMode or 0

   local function isSupplementaryToken(tok)
      return parsing.type(tok).ofType(charType.hangul)
	 or (parsing.type(tok).ofType(tokenType.command) and tok:find("?"))
   end
   
   if self.ideographMode %2 == 1 and self.tokens.notEmpty()
   and isSupplementaryToken(self.tokens[1]) then
      pronunciation = self.tokens.popLeft()
   end
   if self.ideographMode//2%2 == 1 then
      while self.tokens.notEmpty() do
	 self.functions["popSapces"](self)
	 if isSupplementaryToken(self.tokens[1]) then
	    postposition = postposition .. self.tokens.popLeft()
	 else
	    break
	 end
      end
   end
   if postposition ~= "" then
      self.tokens.pushLeft("[postposition|" .. postposition .. "]")
   end
   if pronunciation ~= "" then
      self.tokens.pushLeft("[pronunciation|" .. pronunciation .. "]")
   end
   return box.textBox.functions[charType.ideograph](self,token,option)
   end--]]

function stitchedBinding:writeCenter()
   local result = ""
   return result
end

function stitchedBinding:setDimensions()
   local dim = self.dimension
   self.blockWidth =
      (dim.bodyHalfWidth - dim.centerWidth/2
	  - dim.marginInnerLeft - dim.marginInnerRight )
      /dim.numberOfColumns
   self.blockHeight     =
      (dim.bodyHeight - dim.marginInnerTop - dim.marginInnerBottom)
      /dim.numberOfRows
   self.initialX        =   dim.bodyHalfWidth
                          - dim.marginInnerRight
   self.initialY        = - dim.marginInnerTop  
   self.numberOfColumns = dim.numberOfColumns
   self.numberOfRows    = dim.numberOfRows
   
   self.pageDifferenceX = dim.bodyHalfWidth + dim.centerWidth/2
      - dim.marginInnerRight + dim.marginInnerLeft
end

return {
   stitchedBinding = stitchedBinding,
   textBox         = box.textBox,
   parsing         = parsing,
   charType        = charType,
   TokenType       = TokenType,}
