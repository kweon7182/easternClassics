\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{easternClassics}[2019/05/23 easternClassics class]
\LoadClass[multi=newPage]{standalone}
\RequirePackage{luacode,tikz}
\usetikzlibrary{backgrounds}
\usetikzlibrary{calc}

\input{tail/fishTail.tex}
\begin{luacode*}
  parsing = require("lua.parsing") 
  stitchedBinding = require("lua.stitchedBinding").stitchedBinding
  charType        = require("lua.types").charType

  binding = stitchedBinding:new()

  binding.boxes.pronunciation.options = binding.boxes.comment.options
  binding.boxes.chapterName.options   = binding.boxes.center.options
  binding.boxes.pageNumber.options    = binding.boxes.center.options
\end{luacode*}

\DeclareOption{fold}{\directlua{binding.foldPaper = true}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax


\newcommand{\rightToLeft}[1]
{{\textdir TRT \directlua{tex.print(require("lua.parsing").fixTokenDirection([==[#1]==]))}}}

\newcommand{\setScriptOption}[2][Default]{\unexpanded
  { \addfontfeature      {Script=#1}
    \addhangulfontfeature{Script=#1}#2}}

\newcommand{\currentLuaOutput}{}
\newcommand{\interpret}[2][function(tok) return tok end]{
  \renewcommand{\\}{[newColumn]}
  \directlua{
    preprocessor = #1
    tex.print(
    [[\string\renewcommand{\string\currentLuaOutput}{]] ..
      binding:interpret(preprocessor([====[#2]====])) .. "}")}
  \currentLuaOutput
}
\def\文{\interpret}

\newcommand{\setPageNumber}[1]{\文{[chapter||#1]}}
\def\張次{\setPageNumber}
\def\改行{\文{[newColumn]}}
\def\改面{\文{[newPage]}}
\def\改張{\文{[newPaper]}}

\newcommand{\setCharOption}[3]{
  \if&#1&%
    \if&#2&%
      \directlua{binding.options[charType]      = [====[#3]====]}
    \else
      \directlua{binding.options[charType.#2]   = [====[#3]====]}
    \fi
  \else
    \if&#2&%
      \directlua{binding.boxes.#1.options[charType]    = [====[#3]====]}
    \else
      \directlua{binding.boxes.#1.options[charType.#2] = [====[#3]====]}
    \fi
  \fi
}

\newcommand{\addCharOption}[3]{
  \if&#1&%
    \if&#2&%
      \directlua{binding.options[charType]      =
        (binding.options[charType]      or "")..","..[====[#3]====]}
    \else
      \directlua{binding.options[charType.#2]   =
        (binding.options[charType.#2]   or "")..","..[====[#3]====]}
    \fi
  \else
    \if&#2&%
      \directlua{binding.boxes.#1.options[charType]    =
        (binding.boxes.#1.options[charType]    or "")..","..[====[#3]====]}
    \else
      \directlua{binding.boxes.#1.options[charType.#2] =
        (binding.boxes.#1.options[charType.#2] or "")..","..[====[#3]====]}
    \fi
  \fi
}

\newcommand{\addBoarder}[2]{\directlua{
    binding.dimension.rectBoarder.pushRight({#1,#2})}}
\newcommand{\addSide}[3]{\directlua{
    binding.dimension.sideBoarder.pushRight({#1,#2,#3})}}

\newcommand{\setDimension}[2]{
  \if&#2&
  \else
    \directlua{_ENV = binding.dimension;#1 = #2}
  \fi}

\newcommand{\setHangulMode}[1]{\directlua{binding.hangulMode = #1}}
\newcommand{\rightAlignedPronunciation}{\directlua{
   binding.boxes.pronunciation.numberOfColumns = 2 }}


\newcommand{\setOutterMargin}[4]{
  \setDimension{marginTop   }{#1}
  \setDimension{marginBottom}{#2}
  \setDimension{marginRight }{#3}
  \setDimension{marginLeft  }{#4}}
\def\外餘白{\setOutterMargin}
\def\외여백{\setOutterMargin}

\newcommand{\setInnerMargin}[4]{
  \setDimension{marginInnerTop   }{#1}
  \setDimension{marginInnerBottom}{#2}
  \setDimension{marginInnerRight }{#3}
  \setDimension{marginInnerLeft  }{#4}}
\def\內餘白{\setInnerMargin}
\def\내여백{\setInnerMargin}

\newcommand{\doubleBorder}[3]{
  \addBoarder{0 }{#1}
  \addBoarder{#2}{#3}}
\def\四周雙邊{\doubleBorder}
\def\사주쌍변{\doubleBorder}

\newcommand{\singleBorder}[1]{
  \addBoarder{0 }{#1}}
\def\四周單邊{\singleBorder}
\def\사주단변{\singleBorder}
%左右雙邊 

\newcommand{\setBodySize}[2]{
  \setDimension{bodyHalfWidth}{#2}
  \setDimension{bodyHeight   }{#1}}
\def\半郭{\setBodySize}
\def\반곽{\setBodySize}

\newcommand{\setMatrixDimension}[2]{
  \setDimension{numberOfRows   }{#1}
  \setDimension{numberOfColumns}{#2}}
\def\行款{\setMatrixDimension}
\def\半葉{\setMatrixDimension}
\def\행관{\setMatrixDimension}
 
\newcommand{\setCenterWidth}[1]{
  \setDimension{centerWidth}{#1}}
\def\版心{\setCenterWidth}
\def\판심{\setCenterWidth}

\newcommand{\setFistTail}[2]{
  \setDimension{tailNameUpper}{"#1"}
  \setDimension{tailNameLower}{"#2"}}
\def\魚尾{\setFistTail}
\def\어미{\setFistTail}

\newcommand{\setCommentBlockWidth}[1]{
  \setDimension{commentBlockWidthMultiple}{#1}}
\def\細註行間比{\setCommentBlockWidth}
\def\세주행간비{\setCommentBlockWidth}

\newcommand{\setCenterBlockHeight}[1]{
  \setDimension{centerBlockHeight}{#1}}
\def\版心字間{\setCenterBlockHeight}
\def\판심자간{\setCenterBlockHeight}

\newcommand{\setNoVerticalLines}[1]{
  \setDimension{lineThickness}{#1}
  \setDimension{verticalLinesThickness}{0}}
\def\無界{\setNoVerticalLines}
\def\무계{\setNoVerticalLines}

\newcommand{\setVerticalLines}[1]{
  \setDimension{lineThickness}{#1}
  \setDimension{verticalLinesThickness}{#1}}
\def\有界{\setVerticalLines}
\def\유계{\setVerticalLines}

\newcommand{\setWhiteCenter}[2]{
  \setDimension{centerLineThicknessMultiple}{0}
  \setDimension{centerLineUpperHeight}{#1}
  \setDimension{centerLineLowerHeight}{#2}}
\def\白口{\setWhiteCenter}
\def\백구{\setWhiteCenter}

\newcommand{\setBlackCenter}[3]{
  \setDimension{centerLineThicknessMultiple}{#1}
  \setDimension{centerLineUpperHeight}{#2}
  \setDimension{centerLineLowerHeight}{#3}}
\def\黑口{\setBlackCenter}
\def\흑구{\setBlackCenter}

\newcommand{\setCenterChapterNameLocation}[1]{
  \setDimension{chapterNameHeight}{#1}}
\def\版心題位置{\setCenterChapterNameLocation}
\def\판심제위치{\setCenterChapterNameLocation}

\newcommand{\setPageNumberLocation}[1]{
  \setDimension{pageNumberHeight}{#1}
  \setDimension{chapterNameHeight}{#1}}
\def\張次位置{\setPageNumberLocation}
\def\장차위치{\setPageNumberLocation}


\addCharOption{main}   {ideograph.compatibility}{color=red}
\addCharOption{comment}{ideograph.compatibility}{color=red}
\addCharOption{center} {ideograph.compatibility}{color=red}

\newcommand{\setDimensions}{\directlua{binding:setDimensions()}}
\newcommand{\setDrawing}{\directlua{tex.print(binding:templateDrawing())}}

\newcommand{\paperBegin}{\directlua{tex.print(binding:beginPage())}}
\newcommand{\paperEnd}{\directlua{tex.print(binding:endPaper())}}

\newcommand{\newDimension}[1]{
  \paperEnd
  \tikzset{customTemplate/.pic={}}
  #1
  \setDimensions
  \setDrawing
  \paperBegin
}
  
\AtBeginDocument{
  \tikzset{customTemplate/.pic={}}
  \setDimensions
  \setDrawing
  \directlua{tex.print(binding:beginPage())
  }
}

\AtEndDocument{
  \directlua{tex.print(binding:endPaper())
  }
}
