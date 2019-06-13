--Description:  a constructor of a class of double-ended queues
--Warning:      do not directly assign methods or fields
local function new(entry)
   entry = entry or {}
   local self = {}
   local left, right = 1, #entry

   --appendLeft, appendRight, map

   --Output: the copy
   function self.copy()
      local obj = new()
      for i = 1, #self do
	 obj.pushRight(self[i])
      end
      return obj
   end

   --Output: true if the queue is empty, and false if not
   function self.isEmpty()
      return right < left
   end

   --Output: true if the queue is not empty, and false if not
   function self.notEmpty()
      return right >= left
   end

   --Input:  an element <elem>
   --Effect: push <elem> element to the left
   function self.pushLeft(elem)
      left = left - 1
      entry[left] = elem
   end

   --Input:  an element <elem>
   --Effect: push <elem> to the right
   function self.pushRight(elem)
      right = right + 1
      entry[right] = elem
   end

   --Output: the leftmost element
   --Effect: pop the lefttmost element
   function self.popLeft()
      if left > right then
	 error("Underflow!")
      end
      local result = entry[left]
      entry[left] = nil
      left = left + 1
      return result
   end

   --Output: the rightmost element
   --Effect: pop the rightmost element
   function self.popRight()
      if left > right then
	 error("Underflow!")
      end
      local result = entry[right]
      entry[right] = nil
      right = right - 1
      return result
   end

   --Output: the converted table array
   function self.toArray()
      local result = {}
      for i = left, right do
	 result[i-left+1] = entry[i]
      end
      return result
   end

   function self.join(sep)
      sep = sep or ""
      if left >= right then
	 return ""
      else
	 local result = self[1]
	 for i = left+1,right do
	    result = result .. sep .. entry[i]
	 end
	 return result
      end
   end

   --Output: the unpacked entries
   function self.unpack(l,r)
      return table.unpack(self.toArray(),l,r)
   end

   --Return: the converted string
   function self.sort(comp)
      entry = self.toArray()
      table.sort(entry,comp)
      left,right = 1,#entry
   end
   
   ---- Metatable ----
   local mt =  {}
   
   -- We can use table[key] like a tipical array
   function mt.__index(table,key)
      if type(key)=="number" then
	 return entry[left+key-1]
      end
   end
   
   -- We can use table[key]=value like a tipical array
   function mt.__newindex(table,key,value)
      if type(key)=="number" and key > 0 and key <= right-left+1 then
	 entry[left+key-1] = value
      end
   end
   
   --Output: the length of the queue
   function mt.__len()
      return right - left + 1
   end

   --Output: the iterator of the methods
   function mt.__pairs()
      return next,self
   end

   --Output: the iterator of the entries
   function mt.__ipairs()
      local function next(_,i)
	 i = i + 1
	 if i <= mt.__len() then
	    return i,self[i]
	 end
      end
      return next, nil, 0
   end
   
   --Output: the converted string
   function mt.__tostring(self,left,mid,right)
      left  = left  or '['
      mid   = mid   or '|'
      right = right or ']'
      local result = self.toArray()
      for i = 1,#self do
	 result[i] = tostring(result[i])
      end
      return left..table.concat(result,mid)..right
   end

   function self.print(left,mid,right)
      print(mt.__tostring(self,left,mid,right))
   end
   
   setmetatable(self, mt)
   return self
end

--Output: the deque with the corresponding arguments
local function pack(...)
   return new{...}
end

return {
   new  = new,
   pack = pack,
}
