local deque     = require("lua.deque")
local types     = require("lua.types")
local tokenType = types.tokenType
local charType  = types.charType


--Input:  a utf-8 string,     str
--        the starting index, left (=1)
--        the ending index,   right(=len(str))
--Output: the index of the next character
local function nextChar(str,left,right)
   left  = left  or 1
   right = right or str:len()
   if right < left then -- if str in [left,right] is empty
      return left
   elseif str:byte(left) < 0x80 then
      return left + 1
   else
      left = left + 1
      while str:byte(left) ~=  nil and
            str:byte(left) >= 0x80 and
            str:byte(left) <  0xc0  do
	 left = left + 1
      end
      return math.min(left,right+1)
   end
end

--Input:  a utf-8 string,     str
--        the starting index, left (=1)
--        the ending index,   right(=len(str))
--Assert: the string is < 8 bytes
--Output: convert the string to a number
local function byte(str,left,right)
   left  = left  or 1
   right = right or str:len()
   local tot = 0
   for i = left, right do
      tot = 0x0100 * tot + str:byte(i)
   end
   return tot   
end

--[[To-Do: we need to classify more]]--
--Input:  a utf-8 string,     str
--        the starting index, left (=1)
--        the ending index,   right(=len(str))
--Output: the type of the first character of the input
local function type(str,left,right)
   left  = left  or 1
   right = right or str:len()
   right = math.min(right,nextChar(str,left,right)-1)

   local code = byte(str,left,right)
   local function cmp(min,max)
      return byte(min) <= code and code <= byte(max)
   end

   if left > right then
      return tokenType.empty
   elseif cmp("[","[") then
      return tokenType.command
   elseif cmp(" "," ") or cmp("\n","\n") or cmp("\t","\t") then
      return tokenType.space
      
   elseif cmp("ᄀ","ᅟ") or cmp("ꥠ","ꥼ") then
      return charType.hangul.initial
   elseif cmp("ᅠ","ᆧ") or cmp("ힰ","ퟆ") then
      return charType.hangul.middle
   elseif cmp("ᆨ","ᇿ") or cmp("ퟋ","ퟻ") then
      return charType.hangul.final
   elseif cmp("〮","〯") then
      return charType.hangul.tone
   elseif cmp("가","힣") then
      return charType.hangul.syllable
   elseif cmp("ㄱ","ㆎ") then
      return charType.hangul.compatibility

   elseif cmp("一","鿯") or cmp("㐀","䶵") or cmp("𠀀","𪛖") or
          cmp("𪜀","𫜴") or cmp("𫝀","𫠝") or cmp("𫠠","𬺡") or
          cmp("𬺰","𮯠") then
      return charType.ideograph.character
   elseif cmp("豈","龎") or cmp("丽","𪘀") then
      return charType.ideograph.compatibility

   else
      return charType
   end
end

--Input:  a utf-8 character,  str
--        the starting index, left (=1)
--        the ending index,   right(=len(str))
--Assert: str starts from a hangul
--Output: the index of the next block
local function hangulBlock(str,left,right)
   left  = left  or 1         -- only for
   right = right or str:len() -- debugging

   if type(str,left,right) == charType.hangul.syllable    then
      left = nextChar(str,left,right)
      goto Tone
   elseif type(str,left,right) == charType.hangul.initial then
      left = nextChar(str,left,right) -- combination continued
   else
      return nextChar(str,left,right) -- no initial found
   end

   if type(str,left,right) == charType.hangul.middle      then
      left = nextChar(str,left,right) -- combination continued
   else
      return left -- when initial only
   end

   if type(str,left,right) == charType.hangul.final       then
      left = nextChar(str,left,right)
   end
 
   :: Tone ::
   if type(str,left,right) == charType.hangul.tone        then
      left = nextChar(str,left,right)
   end
   return left
end

local function rightBraketIndex(str,leftIndex,rightIndex,left,right)
   left   = left   or '['
   right  = right  or ']'
   leftIndex  = leftIndex  or 1
   rightIndex = rightIndex or str:len()
   local counter = 0
   local ind = leftIndex
   while ind <= rightIndex do
      if     str:sub(ind,ind) == left then
	 counter = counter + 1
      elseif str:sub(ind,ind) == right then
	 counter = counter - 1
      end
      if counter == 0 then
	 break
      end
      ind = ind + 1
   end
   return ind
end

local function separateArguments(str,leftIndex,rightIndex,left,right,middle)
   left   = left   or '['
   right  = right  or ']'
   middle = middle or '|'
   leftIndex  = leftIndex  or 1
   rightIndex = rightIndex or str:len()
   local counter = 0
   local ind = leftIndex
   while ind <= rightIndex do
      if     str:sub(ind,ind) == left   then
	 counter = counter + 1
      elseif str:sub(ind,ind) == right  then
	 counter = counter - 1
      elseif str:sub(ind,ind) == middle
      and    counter == 0               then
	 return str:sub(leftIndex,ind-1)
	 , separateArguments(str,ind+1,rightIndex,left,right,middle)
      end
      ind = ind + 1 
   end
   return str:sub(leftIndex,rightIndex)
end
  

--Input:  a utf-8 character,  str
--        the starting index, left (=1)
--        the ending index,   right(=len(str))
--Output: the index of the next block
local function nextToken(str,left,right)
   left  = left  or 1
   right = right or str:len()

   tp = type(str,left,right)
   if     tp.parent() == charType.hangul   then
      return hangulBlock(str,left,right)
   elseif tp          == tokenType.space   then
      while type(str,left,right) == tokenType.space do
	 left = nextChar(str,left,right)
      end
      return left
   elseif tp          == tokenType.command then
      return rightBraketIndex(str,left) + 1
   else
      return nextChar(str,left,right)
   end
end

--Input:  a utf-8 character,  str
--        the starting index, left (=1)
--        the ending index,   right(=len(str))
--Output: the tokens of str in a deque
local function parsing(str,left,right)
   left  = left  or 1         -- only for
   right = right or str:len() -- debugging
   local result = deque.new()

   local mid
   while left <= right do
      mid = nextToken(str,left,right)
      result.pushRight(str:sub(left,mid-1))
      left = mid
   end
   return result
end

local function diacriticsSeparation(...)
   args = {...}
   local function separation(str,left,right)
      left  = left  or 1
      right = right or str:len()
      local midLeft
      for _,tone in ipairs(args) do
	 if midLeft and str:find(tone,left,right) then
	    midLeft = math.min(midLeft, str:find(tone,left,right))
	 else
	    midLeft = midLeft or str:find(tone,left,right)
	 end
      end
      midLeft = midLeft or right+1
      local midRight = nextChar(str,midLeft)
      
      return str:sub(left,midLeft-1)..str:sub(midRight,right)
      ,      str:sub(midLeft,midRight-1)
   end
   return separation
end

--Input:  a utf-8 character,  str
--        the starting index, left (=1)
--        the ending index,   right(=len(str))
--Assert: str is a hangul syllable
--Output: <syllable>,<tone>
local hangulToneSeparate = diacriticsSeparation("〮","〯")


--Input:  an integer
--Output: the number in classical Chinese
local function numberInChinese(num)
   local small  = {"零","一","二","三","四","五","六","七","八","九"}
   local large  = {"十","百","千","萬","億","兆","京"}
   if     num <  0 then
      return "負"..numberInChinese(-num)
   elseif num < 10 then
      return small[num+1]
   end
   local digit = 10
   for i = 1,3 do
      if num < 10*digit then
	 l,m,r = numberInChinese(num//digit),large[i],numberInChinese(num%digit)
	 if l=="一" then l="" end
	 if r=="零" then r="" end
	 return l..m..r
      end
      digit = 10*digit
   end
   for i = 4,7 do
      if num < 10000*digit then
	 l,m,r = numberInChinese(num//digit),large[i],numberInChinese(num%digit)
	 if l=="一" and i==4 then l="" end
	 if r=="零"          then r="" end
	 return l..m..r
      end
      digit = 10000*digit
   end
end

local function fixTokenDirection(text)
   text = parsing(text)
   local reversedText = ""
   for _,tok in ipairs(text) do
	 if type(tok).ofType(charType.hangul) then
	    tok = "{\\textdir" .. " TLT " .. tok .. "}"
	 end
	 reversedText = reversedText .. tok
   end
   return reversedText
end

local function popSpaces(tokens)
   while tokens.notEmpty()
   and   type(tokens[1]).ofType(tokenType.space) do
      tokens.popLeft()
   end
end

-- ideographMode, 
local function assistOnce(tokens,mode)
   local pronunciation,postposition = "",""
   popSpaces(tokens)
   if mode%2 == 1 and tokens.notEmpty()
   and not type(tokens[1]).ofType(charType.ideograph) then
      pronunciation = tokens.popLeft()
   end
   
   if mode//2%2 == 1 then
      while tokens.notEmpty() do
	 popSpaces(tokens)
	 if not type(tokens[1]).ofType(charType.ideograph) then
	    postposition = postposition .. tokens.popLeft()
	 else
	    break
	 end
      end
   end
   if postposition ~= "" then
      tokens.pushLeft("[postposition|" .. postposition .. "]")
   end
   if pronunciation ~= "" then
      tokens.pushLeft("[pronunciation|" .. pronunciation .. "]")
   end
end

local function assistIdeograph(mode)
   local function preprocessor(str)
      mode = mode or 3
      tokens = parsing(str)
      
      result = deque.new()
      while tokens.notEmpty() do
	 result.pushRight(tokens.popLeft())
	 if type(result[#result]).ofType(charType.ideograph) then
	    assistOnce(tokens,mode)
	 end
      end
      return result.join()
   end
   return preprocessor
end

return {
   tokenType            = tokenType,
   charType             = charType,
   parsing              = parsing,
   type                 = type,
   nextChar             = nextChar,
   
   separateArguments    = separateArguments,
   numberInChinese      = numberInChinese,
   assistIdeograph      = assistIdeograph,

   fixTokenDirection    = fixTokenDirection,
   diacriticsSeparation = diacriticsSeparation,
   hangulToneSeparate   = hangulToneSeparate,
}
