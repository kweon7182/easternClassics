--Output:  a node with the given name and an optional parent
--Warning: do not directly assign methods or fields
local function newChild(name,parent)   
   local self = {}
   if parent then
      parent.children()[name] = self
   end
   local children = {}

   --Effect: append a new child node with the given name
   --Output: the child node
   function self.newChild(name)
      local child = newChild(name,self)
      return child
   end

   function self.children()
      return children
   end

   --Output: the parent
   function self.parent()
      return parent
   end

   function self.allToString(depth)
      depth = depth or 0
      local result = string.rep(" ",4*depth)..name.."\n"
      for key, val in pairs(children) do
	 result = result .. val.allToString(depth+1)
      end
      return result
   end

   --Input:  a node
   --Output: true if and only if the node is an ancestor
   function self.ofType(node)
      if self == node then
	 return true
      elseif not parent then
	 return false
      else
	 return parent.ofType(node)
      end
   end

   ---- Metatable ----
   local mt = {}
   function mt.__tostring(table)
      if parent then
	 return tostring(parent).."."..name
      else
	 return name
      end
   end
   setmetatable(self, mt)

   function mt.__index(table,key)
      return children[key]
   end
   return self
end

--Description:  a constructor of a class of trees
local function new(name)
   return newChild(name)
end


--Define types of unicode characters
local tokenType = new("token")
tokenType.newChild("command")
tokenType.newChild("space")
tokenType.newChild("empty")

local charType  = tokenType.newChild("character")
charType.newChild("roman")
charType.newChild("numeral")

charType.newChild("hangul")
charType.hangul.newChild("initial")
charType.hangul.newChild("middle")
charType.hangul.newChild("final")
charType.hangul.newChild("tone")
charType.hangul.newChild("syllable")
charType.hangul.newChild("compatibility")

charType.newChild("ideograph")
charType.ideograph.newChild("character")
charType.ideograph.newChild("tone")
charType.ideograph.newChild("description")
charType.ideograph.newChild("radical")
charType.ideograph.newChild("stroke")
charType.ideograph.newChild("compatibility")


return {
   tokenType = tokenType,
   charType  = charType,
}
