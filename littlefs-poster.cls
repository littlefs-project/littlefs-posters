
% simple littlefs poster template

% based on a "Simple LaTex Conference Poster Template" by @klb2:
% https://github.com/klb2/scientific-poster-template
%
% desc: 2023/10/20 v1.2 class for designing conference posters based on
% tikzposter
% author: Karl-Ludwig Besser
%

\NeedsTeXFormat{LaTeX2e}%[1999/12/01]
\ProvidesClass{littlefs-poster}[2026/01/08 simple littlefs poster template]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{tikzposter}}
\ProcessOptions\relax
\LoadClass{tikzposter}
\tikzposterlatexaffectionproofoff

\usetikzlibrary{math,arrows,arrows.meta}

\RequirePackage{tabularx}
\RequirePackage{multirow}

% give ourselves a few more layers, requires some fudging with tikzposter
\RequirePackage{tikz-layers}
\pgfsetlayers{
    backgroundlayer, % tikzposter
    background, % tikz-layers
    behind, % tikz-layers
    main,
    above, % tikz-layers
    glass, % tikz-layers
    notelayer % tikzposter
}

\newcommand*{\affilmark}[1]{\raisebox{0pt}[0pt][0pt]{\textsuperscript{#1}}}




\definecolorstyle{littlefscolorstyle} {
    % bg/fg colors
    \definecolor{bg}{named}{white} % {HTML}{eeecde}
    \definecolor{bgi}{HTML}{e4bc7f}
    \definecolor{bgii}{HTML}{da8447}
    \definecolor{bgiii}{HTML}{bc5342}
    \definecolor{fgiii}{HTML}{bc5342}
    \definecolor{fgii}{HTML}{8c3549}
    \definecolor{fgi}{HTML}{552941}
    \definecolor{fg}{named}{black} % {HTML}{222222}
    % dark colors for use in poster
    \definecolor{fgdarkred}{HTML}{cd2222}
    \definecolor{fgdarkyellow}{HTML}{8c6b00}
    \definecolor{fgdarkgreen}{HTML}{008831}
    \definecolor{fgdarkcyan}{HTML}{007f8d}
    \definecolor{fgdarkblue}{HTML}{3d61e6}
    \definecolor{fgdarkpurple}{HTML}{ab34ac}
    % light colors for use in poster
    \definecolor{fglightred}{HTML}{ffafad}
    \definecolor{fglightyellow}{HTML}{f3be5a}
    \definecolor{fglightgreen}{HTML}{97dd8b}
    \definecolor{fglightcyan}{HTML}{36e1ea}
    \definecolor{fglightblue}{HTML}{a8c9ff}
    \definecolor{fglightpurple}{HTML}{eeabfc}
}{
    % Background Colors
    \colorlet{backgroundcolor}{bg}
    \colorlet{framecolor}{bg}
    % Title Colors
    \colorlet{titlefgcolor}{fg}
    \colorlet{titlebgcolor}{bgi}
    % Block Colors
    \colorlet{blocktitlebgcolor}{bgi}
    \colorlet{blocktitlefgcolor}{fg}
    \colorlet{blockbodybgcolor}{bg}
    \colorlet{blockbodyfgcolor}{fg}
    % Innerblock Colors
    \colorlet{innerblocktitlebgcolor}{fgi}
    \colorlet{innerblocktitlefgcolor}{bg}
    \colorlet{innerblockbodybgcolor}{fgii}
    \colorlet{innerblockbodyfgcolor}{bg}
    % Note colors
    \colorlet{notefgcolor}{bg}
    \colorlet{notebgcolor}{fgii}
    \colorlet{noteframecolor}{fgii}
}
\usecolorstyle{littlefscolorstyle}


\def\title#1{\gdef\@title{#1}}

\settitle{ \centering \vbox{
%\@titlegraphic \\[\TP@titlegraphictotitledistance] \centering
\color{titlefgcolor} {\bfseries \Huge \sc \@title \par}
%\vspace*{1em}
%{\huge \@author \par} \vspace*{1em} {\LARGE \@institute}
}}

\definetitlestyle{littlefstitlestyle}{
    %width=\TP@visibletextwidth,
    %width=\textwidth,
    width=\paperwidth,
    roundedcorners=0,
    linewidth=0pt,
    %innersep=40pt,
    %innersep=12pt,
    %innersep=48pt,
    innersep=60pt,
    %innersep=72pt,
    %titletotopverticalspace=25mm,
    %titletoblockverticalspace=15mm,
    titletoblockverticalspace=48pt,
    titletotopverticalspace=0mm,
    %titletoblockverticalspace=0mm,
    %titlegraphictotitledistance=-100pt,
    titletextscale=20,
}{
    \fill[
            %color=framecolor,
            fill=titlebgcolor,
            rounded corners=\titleroundedcorners]
        (\titleposleft,\titleposbottom)
        rectangle
        (\titleposright,\titlepostop);
}
\usetitlestyle{littlefstitlestyle}


\definebackgroundstyle{littlefsbackgroundstyle}{
    \fill[
            %color=framecolor,
            fill=titlebgcolor]
        (-0.5\paperwidth,-0.5\paperheight)
        rectangle
        %(0.5\paperwidth,-0.5\paperheight+120pt);
        (0.5\paperwidth,-0.5\paperheight+2*48pt);
}
\usebackgroundstyle{littlefsbackgroundstyle}


\defineblockstyle{littlefsblockstyle}{
    titlewidthscale=1,
    bodywidthscale=1,
    titleleft,
    titleoffsetx=0pt, titleoffsety=0pt,
    bodyoffsetx=0mm, bodyoffsety=0mm,
    bodyverticalshift=0mm,
    roundedcorners=0,
    linewidth=0pt,
    %titleinnersep=8mm,
    titleinnersep=24pt,
    %bodyinnersep=1cm
    bodyinnersep=24pt,
}{
    \fill[
            %color=framecolor,
            fill=blockbodybgcolor,
            rounded corners=\blockroundedcorners]
        (blockbody.south west) rectangle (blockbody.north east);
    \ifBlockHasTitle
        \fill[
                %color=framecolor,
                fill=blocktitlebgcolor,
                rounded corners=\blockroundedcorners]
            (blocktitle.south west) rectangle (blocktitle.north east);
    \fi
}
\useblockstyle{littlefsblockstyle}


\defineinnerblockstyle{littlefsinnerblockstyle}{
%    titlewidthscale=1,
%    bodywidthscale=1,
    titleleft,
    titleoffsetx=0pt, titleoffsety=0pt,
    bodyoffsetx=0mm, bodyoffsety=0mm,
    bodyverticalshift=0mm,
    roundedcorners=0,
    linewidth=0pt,
%    titleinnersep=8mm,
%    titleinnersep=24pt,
    %bodyinnersep=1cm
}{
    \fill[
            %color=framecolor,
            fill=innerblockbodybgcolor,
            rounded corners=\blockroundedcorners]
        (innerblockbody.south west) rectangle (innerblockbody.north east);
    \ifInnerblockHasTitle
        \fill[
                %color=framecolor,
                fill=innerblocktitlebgcolor,
                rounded corners=\blockroundedcorners]
            (innerblocktitle.south west) rectangle (innerblocktitle.north east);
    \fi
}
\useinnerblockstyle{littlefsinnerblockstyle}


\definenotestyle{littlefsnotestyle}{
    targetoffsetx=0pt,
    targetoffsety=0pt,
    angle=-45,
    radius=6cm,
    %width=6cm,
    connection=true,
    rotate=0,
    roundedcorners=0,
    linewidth=0pt,
    innersep=24pt,
}{
    \ifNoteHasConnection
        \draw[-{>[scale=2]},line width=2.4pt]
            (notecenter) -- (notetarget);
    \fi
    \fill[draw=notebgcolor,fill=notebgcolor,rotate=\noterotate]
        (notecenter.south west) rectangle (notecenter.north east);
}
\usenotestyle{littlefsnotestyle}



% \newdimen\TP@titlebackgroundheight
% \define@key{title}{titlebackgroundheight}{\TP@titlebackgroundheight=#1}
% \definetitlestyle{conferenceTitleStyle}{
%     width=\TP@visibletextwidth, roundedcorners=0, linewidth=2pt, innersep=40pt,
%     titletotopverticalspace=25mm, titletoblockverticalspace=15mm,
%     titlebackgroundheight=10cm,,
% %   titlegraphictotitledistance=-100pt,
% }{
% %    \draw[fill=blockbodybgcolor,draw=blockbodybgcolor] (-.5\paperwidth, .5\paperheight) rectangle (.5\paperwidth, 0.5\textheight-\TP@titlebackgroundheight);
% %    % Title node
% %    \node[fill=titlebgcolor, draw=none,%draw=blocktitlebgcolor,
% %          inner sep=\TP@titleinnersep,
% %          line width=\TP@titlelinewidth,
% %          minimum width=\TP@visibletextwidth-2\TP@titleinnersep,
% %          text width=\TP@visibletextwidth-2\TP@titleinnersep,
% %          %align=left,
% %          align=center,
% %          anchor=north] (titlenode) at (titleboxnorth) {\TP@maketitle};
% }
% \usetitlestyle{conferenceTitleStyle}
% %\usetitlestyle{VerticalShading}


% %\def\title#1{\gdef\@title{\scalebox{\TP@titletextscale}{\parbox{\TP@visibletextwidth-2\TP@titleinnersep}{#1}}}}
%\def\title#1{\gdef\@title{#1}}
% 
% \gdef\TP@maketitle{%
%     \color{titlefgcolor}
%     {\fontsize{85pt}{110pt}\bfseries\selectfont
%     \@title\par
%     \vspace*{.75em}
%     }
%     {\huge\bfseries\@author\par
%     \vspace*{.5em}
%     }
%     {\Large \@institute\par}
% }
%\renewcommand\maketitle[1][]{  % #1 keys
%    \normalsize
%    \setkeys{title}{#1}
%    
%    % Background node
%    \draw[fill=blockbodybgcolor,draw=blockbodybgcolor] (-.5\paperwidth, .5\paperheight) rectangle (.5\paperwidth, 0.5\textheight-\TP@titlebackgroundheight);
%    
%    \node[anchor=north west, inner sep=0pt] (logonode) at ($(-0.5\titlewidth, 0.5\textheight-\TP@titletotopverticalspace)$) {\@titlegraphic};
%    
%    \coordinate (titleboxnorth) at ($(0, 0 |- logonode.south) + (0, -\TP@titlegraphictotitledistance)$);
%    
%    % Title node
%    \node[fill=titlebgcolor, draw=none,%draw=blocktitlebgcolor,
%          inner sep=\TP@titleinnersep,
%          line width=\TP@titlelinewidth,
%          minimum width=\TP@visibletextwidth-2\TP@titleinnersep,
%          text width=\TP@visibletextwidth-2\TP@titleinnersep,
%          %align=left,
%          align=center,
%          anchor=north] (titlenode) at (titleboxnorth) {\TP@maketitle};
%    
%    \normalsize
%    \tikzmath{coordinate \titleboxsouth;
%        \titleboxsouth = (titlenode.south);
%        \distTitleSouth = abs(\titleboxsouthy);%veclen(\Cx, \Cy);
%    }
%    \setlength{\TP@blocktop}{\distTitleSouth pt - \TP@titletoblockverticalspace}
%%   \setlength{\TP@blocktop}{\titleposbottom-\TP@titletoblockverticalspace}
%}

