local draw = {}

--Input:  a point (x,y), a content, and options in string
--Output: the desired node
function draw.node(x,y,content,options)
   content = content or ""
   options = options or ""
   return string.format(
      "\\node at (%f,%f)[%s]{%s};\n"
      ,x,y,options,content)
end


--Input:  two vertices (x0,y0) and (x1,y1), thickness of lines, and options
--Output: the desired rectangle
function draw.rectangle(x0,y0,x1,y1,thickness,options)
   if thickness <= 0 then
      return ""
   end
   options = options or ""
   return string.format(
      "\\draw[line width=%scm,%s] (%f,%f) rectangle (%f,%f);\n"
      ,thickness,options
      ,x0+thickness/2,y0+thickness/2
      ,x1-thickness/2,y1-thickness/2)
end

--Input:  two vertices (x0,y0) and (x1,y1) thickness of lines, and options
--Output: the desired line
function draw.line(x0,y0,x1,y1,thickness,options)
   if thickness <= 0 then
      return ""
   end
   options = options or ""
   return string.format(
      "\\draw[line width=%scm,%s] (%f,%f) -- (%f,%f);\n"
      ,thickness,options,x0,y0,x1,y1)
end

return draw
