<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Oscar Levin, Andrew Rechnitzer, Steven Clontz, Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>
<xsl:import href="./pretext-latex.xsl" />

<xsl:output method="text" indent="no" encoding="UTF-8"/>

<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to Beamer presentations/slideshows is experimental and needs improvements&#xa;Requests for additional specific constructions welcome&#xa;Additional PreTeXt elements are subject to change</xsl:with-param>
      </xsl:call-template>
  <xsl:apply-templates select="pretext"/>
</xsl:template>

<xsl:template match="/pretext">
  <xsl:apply-templates select="slideshow" />
</xsl:template>

<xsl:template match="slideshow">
  <xsl:call-template name="preamble" />
  <xsl:call-template name="body" />
</xsl:template>

<xsl:template name="preamble">
  <xsl:text>\documentclass[11pt, compress]{beamer}&#xa;</xsl:text>
  <xsl:if test="$latex.preamble.early != ''">
    <xsl:text>%% Custom Preamble Entries, early (use latex.preamble.early)&#xa;</xsl:text>
    <xsl:value-of select="$latex.preamble.early" />
    <xsl:text>&#xa;</xsl:text>
  </xsl:if>
  <xsl:text>\usepackage{amsmath}&#xa;</xsl:text>

  <xsl:text>\usetheme{Boadilla}&#xa;</xsl:text>
  <xsl:text>\usefonttheme[onlymath]{serif}&#xa;</xsl:text>
  <xsl:text>%get rid of navigation:&#xa;\setbeamertemplate{navigation symbols}{}&#xa;</xsl:text>
  <xsl:text>&#xa;&#xa; %%%% Start PreTeXt generated preamble: %%%%% &#xa;&#xa;</xsl:text>
  <xsl:text>%% Some aspects of the preamble are conditional,&#xa;</xsl:text>
  <xsl:text>%% the LaTeX engine is one such determinant&#xa;</xsl:text>
  <xsl:text>\usepackage{ifthen}&#xa;</xsl:text>
  <xsl:text>\newcommand{\tabularfont}{}&#xa;</xsl:text>
  <xsl:text>\usepackage[xparse, raster]{tcolorbox}&#xa;</xsl:text>
  <xsl:text>\tcbset{colback=white, colframe=white}&#xa;</xsl:text>
  <xsl:text>\NewTColorBox{image}{mmm}{boxrule=0.25pt, colframe=gray, left skip=#1\linewidth,width=#2\linewidth}&#xa;</xsl:text>
  <xsl:text>\RenewTColorBox{definition}{m}{colback=teal!30!white, colbacktitle=teal!30!white, coltitle=black, colframe=gray, boxrule=0.5pt, sharp corners=downhill, titlerule = 0.25pt, title={#1}}&#xa;</xsl:text>
  <xsl:text>\RenewTColorBox{theorem}{m}{colback=pink!30!white, colbacktitle=pink!30!white, coltitle=black, colframe=gray, boxrule=0.5pt, sharp corners=downhill, titlerule = 0.25pt, title={#1}}&#xa;</xsl:text>
  <xsl:text>\RenewTColorBox{proof}{}{boxrule=0.25pt, colframe=gray, colback=white, before upper={Proof:}, after upper={\qed}}&#xa;</xsl:text>
       <xsl:if test="$b-has-program or $b-has-console or $b-has-sage">
        <xsl:text>%% Program listing support: for listings, programs, consoles, and Sage code&#xa;</xsl:text>
        <!-- NB: the "listingsutf8" package is not a panacea, as it only       -->
        <!-- cooperates with UTF-8 characters when code snippets are read      -->
        <!-- in from external files.  We do condition on the LaTeX engines     -->
        <!-- since (a) it is easy and (b) the tcolorbox documentation warns    -->
        <!-- about not being careful.  NB: LuaTeX is not tested nor supported. -->
        <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}%&#xa;</xsl:text>
        <xsl:text>  {\tcbuselibrary{listings}}%&#xa;</xsl:text>
        <xsl:text>  {\tcbuselibrary{listingsutf8}}%&#xa;</xsl:text>
        <xsl:text>%% We define the listings font style to be the default "ttfamily"&#xa;</xsl:text>
        <xsl:text>%% To fix hyphens/dashes rendered in PDF as fancy minus signs by listing&#xa;</xsl:text>
        <xsl:text>%% http://tex.stackexchange.com/questions/33185/listings-package-changes-hyphens-to-minus-signs&#xa;</xsl:text>
        <xsl:text>\makeatletter&#xa;</xsl:text>
        <xsl:text>\lst@CCPutMacro\lst@ProcessOther {"2D}{\lst@ttfamily{-{}}{-{}}}&#xa;</xsl:text>
        <xsl:text>\@empty\z@\@empty&#xa;</xsl:text>
        <xsl:text>\makeatother&#xa;</xsl:text>
        <xsl:text>%% We define a null language, free of any formatting or style&#xa;</xsl:text>
        <xsl:text>%% for use when a language is not supported, or pseudo-code, or consoles&#xa;</xsl:text>
        <xsl:text>%% Not necessary for Sage code, so in limited cases included unnecessarily&#xa;</xsl:text>
        <xsl:text>\lstdefinelanguage{none}{identifierstyle=,commentstyle=,stringstyle=,keywordstyle=}&#xa;</xsl:text>
        <xsl:text>\ifthenelse{\boolean{xetex}}{}{%&#xa;</xsl:text>
        <xsl:text>%% begin: pdflatex-specific listings configuration&#xa;</xsl:text>
        <xsl:text>%% translate U+0080 - U+00F0 to their textmode LaTeX equivalents&#xa;</xsl:text>
        <xsl:text>%% Data originally from https://www.w3.org/Math/characters/unicode.xml, 2016-07-23&#xa;</xsl:text>
        <xsl:text>%% Lines marked in XSL with "$" were converted from mathmode to textmode&#xa;</xsl:text>
        <!-- encoding, etc: http://tex.stackexchange.com/questions/24528/ -->
        <!-- Format: {Unicode}{TeX}{rendered-length} Unicode name (in numerical order) -->
        <xsl:text>\lstset{extendedchars=true}&#xa;</xsl:text>
        <xsl:text>\lstset{literate=</xsl:text>
        <xsl:text>{&#x00A0;}{{~}}{1}</xsl:text>    <!--NO-BREAK SPACE-->
        <xsl:text>{&#x00A1;}{{\textexclamdown }}{1}</xsl:text>    <!--INVERTED EXCLAMATION MARK-->
        <xsl:text>{&#x00A2;}{{\textcent }}{1}</xsl:text>    <!--CENT SIGN-->
        <xsl:text>{&#x00A3;}{{\textsterling }}{1}</xsl:text>    <!--POUND SIGN-->
        <xsl:text>{&#x00A4;}{{\textcurrency }}{1}</xsl:text>    <!--CURRENCY SIGN-->
        <xsl:text>{&#x00A5;}{{\textyen }}{1}</xsl:text>    <!--YEN SIGN-->
        <xsl:text>{&#x00A6;}{{\textbrokenbar }}{1}</xsl:text>    <!--BROKEN BAR-->
        <xsl:text>{&#x00A7;}{{\textsection }}{1}</xsl:text>    <!--SECTION SIGN-->
        <xsl:text>{&#x00A8;}{{\textasciidieresis }}{1}</xsl:text>    <!--DIAERESIS-->
        <xsl:text>{&#x00A9;}{{\textcopyright }}{1}</xsl:text>    <!--COPYRIGHT SIGN-->
        <xsl:text>{&#x00AA;}{{\textordfeminine }}{1}</xsl:text>    <!--FEMININE ORDINAL INDICATOR-->
        <xsl:text>{&#x00AB;}{{\guillemotleft }}{1}</xsl:text>    <!--LEFT-POINTING DOUBLE ANGLE QUOTATION MARK-->
        <xsl:text>{&#x00AC;}{{\textlnot }}{1}</xsl:text>    <!--NOT SIGN-->  <!-- $ -->
        <xsl:text>{&#x00AD;}{{\-}}{1}</xsl:text>    <!--SOFT HYPHEN-->
        <xsl:text>{&#x00AE;}{{\textregistered }}{1}</xsl:text>    <!--REGISTERED SIGN-->
        <xsl:text>{&#x00AF;}{{\textasciimacron }}{1}</xsl:text>    <!--MACRON-->
        <xsl:text>{&#x00B0;}{{\textdegree }}{1}</xsl:text>    <!--DEGREE SIGN-->
        <xsl:text>{&#x00B1;}{{\textpm }}{1}</xsl:text>    <!--PLUS-MINUS SIGN-->  <!-- $ -->
        <xsl:text>{&#x00B2;}{{\texttwosuperior }}{1}</xsl:text>    <!--SUPERSCRIPT TWO-->  <!-- $ -->
        <xsl:text>{&#x00B3;}{{\textthreesuperior }}{1}</xsl:text>    <!--SUPERSCRIPT THREE-->   <!-- $ -->
        <xsl:text>{&#x00B4;}{{\textasciiacute }}{1}</xsl:text>    <!--ACUTE ACCENT-->
        <xsl:text>{&#x00B5;}{{\textmu }}{1}</xsl:text>    <!--MICRO SIGN-->  <!-- $ -->
        <xsl:text>{&#x00B6;}{{\textparagraph }}{1}</xsl:text>    <!--PILCROW SIGN-->
        <xsl:text>{&#x00B7;}{{\textperiodcentered }}{1}</xsl:text>    <!--MIDDLE DOT-->  <!-- $ -->
        <xsl:text>{&#x00B8;}{{\c{}}}{1}</xsl:text>    <!--CEDILLA-->
        <xsl:text>{&#x00B9;}{{\textonesuperior }}{1}</xsl:text>    <!--SUPERSCRIPT ONE-->  <!-- $ -->
        <xsl:text>{&#x00BA;}{{\textordmasculine }}{1}</xsl:text>    <!--MASCULINE ORDINAL INDICATOR-->
        <xsl:text>{&#x00BB;}{{\guillemotright }}{1}</xsl:text>    <!--RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK-->
        <xsl:text>{&#x00BC;}{{\textonequarter }}{1}</xsl:text>    <!--VULGAR FRACTION ONE QUARTER-->
        <xsl:text>{&#x00BD;}{{\textonehalf }}{1}</xsl:text>    <!--VULGAR FRACTION ONE HALF-->
        <xsl:text>{&#x00BE;}{{\textthreequarters }}{1}</xsl:text>    <!--VULGAR FRACTION THREE QUARTERS-->
        <xsl:text>{&#x00BF;}{{\textquestiondown }}{1}</xsl:text>    <!--INVERTED QUESTION MARK-->
        <xsl:text>{&#x00C0;}{{\`{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH GRAVE-->
        <xsl:text>{&#x00C1;}{{\'{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH ACUTE-->
        <xsl:text>{&#x00C2;}{{\^{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH CIRCUMFLEX-->
        <xsl:text>{&#x00C3;}{{\~{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH TILDE-->
        <xsl:text>{&#x00C4;}{{\"{A}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH DIAERESIS-->
        <xsl:text>{&#x00C5;}{{\AA }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER A WITH RING ABOVE-->
        <xsl:text>{&#x00C6;}{{\AE }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER AE-->
        <xsl:text>{&#x00C7;}{{\c{C}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER C WITH CEDILLA-->
        <xsl:text>{&#x00C8;}{{\`{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH GRAVE-->
        <xsl:text>{&#x00C9;}{{\'{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH ACUTE-->
        <xsl:text>{&#x00CA;}{{\^{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH CIRCUMFLEX-->
        <xsl:text>{&#x00CB;}{{\"{E}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER E WITH DIAERESIS-->
        <xsl:text>{&#x00CC;}{{\`{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH GRAVE-->
        <xsl:text>{&#x00CD;}{{\'{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH ACUTE-->
        <xsl:text>{&#x00CE;}{{\^{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH CIRCUMFLEX-->
        <xsl:text>{&#x00CF;}{{\"{I}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER I WITH DIAERESIS-->
        <xsl:text>{&#x00D0;}{{\DH }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER ETH-->
        <xsl:text>{&#x00D1;}{{\~{N}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER N WITH TILDE-->
        <xsl:text>{&#x00D2;}{{\`{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH GRAVE-->
        <xsl:text>{&#x00D3;}{{\'{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH ACUTE-->
        <xsl:text>{&#x00D4;}{{\^{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH CIRCUMFLEX-->
        <xsl:text>{&#x00D5;}{{\~{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH TILDE-->
        <xsl:text>{&#x00D6;}{{\"{O}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH DIAERESIS-->
        <xsl:text>{&#x00D7;}{{\texttimes }}{1}</xsl:text>    <!--MULTIPLICATION SIGN-->
        <xsl:text>{&#x00D8;}{{\O }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER O WITH STROKE-->
        <xsl:text>{&#x00D9;}{{\`{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH GRAVE-->
        <xsl:text>{&#x00DA;}{{\'{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH ACUTE-->
        <xsl:text>{&#x00DB;}{{\^{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH CIRCUMFLEX-->
        <xsl:text>{&#x00DC;}{{\"{U}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER U WITH DIAERESIS-->
        <xsl:text>{&#x00DD;}{{\'{Y}}}{1}</xsl:text>    <!--LATIN CAPITAL LETTER Y WITH ACUTE-->
        <xsl:text>{&#x00DE;}{{\TH }}{1}</xsl:text>    <!--LATIN CAPITAL LETTER THORN-->
        <xsl:text>{&#x00DF;}{{\ss }}{1}</xsl:text>    <!--LATIN SMALL LETTER SHARP S-->
        <xsl:text>{&#x00E0;}{{\`{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH GRAVE-->
        <xsl:text>{&#x00E1;}{{\'{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH ACUTE-->
        <xsl:text>{&#x00E2;}{{\^{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH CIRCUMFLEX-->
        <xsl:text>{&#x00E3;}{{\~{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH TILDE-->
        <xsl:text>{&#x00E4;}{{\"{a}}}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH DIAERESIS-->
        <xsl:text>{&#x00E5;}{{\aa }}{1}</xsl:text>    <!--LATIN SMALL LETTER A WITH RING ABOVE-->
        <xsl:text>{&#x00E6;}{{\ae }}{1}</xsl:text>    <!--LATIN SMALL LETTER AE-->
        <xsl:text>{&#x00E7;}{{\c{c}}}{1}</xsl:text>    <!--LATIN SMALL LETTER C WITH CEDILLA-->
        <xsl:text>{&#x00E8;}{{\`{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH GRAVE-->
        <xsl:text>{&#x00E9;}{{\'{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH ACUTE-->
        <xsl:text>{&#x00EA;}{{\^{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH CIRCUMFLEX-->
        <xsl:text>{&#x00EB;}{{\"{e}}}{1}</xsl:text>    <!--LATIN SMALL LETTER E WITH DIAERESIS-->
        <xsl:text>{&#x00EC;}{{\`{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH GRAVE-->
        <xsl:text>{&#x00ED;}{{\'{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH ACUTE-->
        <xsl:text>{&#x00EE;}{{\^{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH CIRCUMFLEX-->
        <xsl:text>{&#x00EF;}{{\"{\i}}}{1}</xsl:text>    <!--LATIN SMALL LETTER I WITH DIAERESIS-->
        <xsl:text>{&#x00F0;}{{\dh }}{1}</xsl:text>    <!--LATIN SMALL LETTER ETH-->
        <xsl:text>{&#x00F1;}{{\~{n}}}{1}</xsl:text>    <!--LATIN SMALL LETTER N WITH TILDE-->
        <xsl:text>{&#x00F2;}{{\`{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH GRAVE-->
        <xsl:text>{&#x00F3;}{{\'{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH ACUTE-->
        <xsl:text>{&#x00F4;}{{\^{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH CIRCUMFLEX-->
        <xsl:text>{&#x00F5;}{{\~{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH TILDE-->
        <xsl:text>{&#x00F6;}{{\"{o}}}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH DIAERESIS-->
        <xsl:text>{&#x00F7;}{{\textdiv }}{1}</xsl:text>    <!--DIVISION SIGN-->  <!-- $ -->
        <xsl:text>{&#x00F8;}{{\o }}{1}</xsl:text>    <!--LATIN SMALL LETTER O WITH STROKE-->
        <xsl:text>{&#x00F9;}{{\`{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH GRAVE-->
        <xsl:text>{&#x00FA;}{{\'{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH ACUTE-->
        <xsl:text>{&#x00FB;}{{\^{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH CIRCUMFLEX-->
        <xsl:text>{&#x00FC;}{{\"{u}}}{1}</xsl:text>    <!--LATIN SMALL LETTER U WITH DIAERESIS-->
        <xsl:text>{&#x00FD;}{{\'{y}}}{1}</xsl:text>    <!--LATIN SMALL LETTER Y WITH ACUTE-->
        <xsl:text>{&#x00FE;}{{\th }}{1}</xsl:text>    <!--LATIN SMALL LETTER THORN-->
        <xsl:text>{&#x00FF;}{{\"{y}}}{1}</xsl:text>    <!--LATIN SMALL LETTER Y WITH DIAERESIS-->
        <xsl:text>}&#xa;</xsl:text> <!-- end of literate set -->
        <xsl:text>%% end: pdflatex-specific listings configuration&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>%% End of generic listing adjustments&#xa;</xsl:text>
        <xsl:if test="$b-has-program">
            <xsl:text>%% Program listings via new tcblisting environment&#xa;</xsl:text>
            <xsl:text>%% First a universal color scheme for parts of any language&#xa;</xsl:text>
            <xsl:if test="$latex.print='no'" >
                <xsl:text>%% Colors match a subset of Google prettify "Default" style&#xa;</xsl:text>
                <xsl:text>%% Set latex.print='yes' to get all black&#xa;</xsl:text>
                <xsl:text>%% http://code.google.com/p/google-code-prettify/source/browse/trunk/src/prettify.css&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0.375,0,0.375}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0.5,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0.5,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0.5}&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="$latex.print='yes'" >
                <xsl:text>%% All-black colors&#xa;</xsl:text>
                <xsl:text>%% Set latex.print='no' to get actual colors&#xa;</xsl:text>
                <xsl:text>\definecolor{identifiers}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{comments}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{strings}{rgb}{0,0,0}&#xa;</xsl:text>
                <xsl:text>\definecolor{keywords}{rgb}{0,0,0}&#xa;</xsl:text>
            </xsl:if>
            <xsl:text>%% Options passed to the listings package via tcolorbox&#xa;</xsl:text>
            <xsl:text>\lstdefinestyle{programcodestyle}{identifierstyle=\color{identifiers},commentstyle=\color{comments},stringstyle=\color{strings},keywordstyle=\color{keywords}, breaklines=true, breakatwhitespace=true, columns=fixed, extendedchars=true, aboveskip=0pt, belowskip=0pt}&#xa;</xsl:text>
            <!-- We want a "program" to be able to break across pages    -->
            <!-- Trying "enforce breakable" for a long listing inside of -->
            <!-- a "listing" just led to a "mess of shattered boxes" so  -->
            <!-- simply advise that a "listing" is not breakable.        -->
            <!-- NB: rules "at break" need to come after "boxrule"       -->
            <xsl:text>\tcbset{ programboxstyle/.style={left=3ex, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt, boxsep=0pt, &#xa;</xsl:text>
            <xsl:text>listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>colback=white, sharp corners, boxrule=-0.3pt, leftrule=0.5pt,&#xa;</xsl:text>
            <xsl:text>parbox=false,&#xa;</xsl:text>
            <xsl:text>} }&#xa;</xsl:text>
            <!--  -->
            <xsl:text>\newtcblisting{program}[1]{programboxstyle, listing options={language=#1, style=programcodestyle}}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//console">
            <xsl:text>%% Console session with prompt, input, output&#xa;</xsl:text>
            <xsl:text>%% listings allows for escape sequences to enable LateX,&#xa;</xsl:text>
            <xsl:text>%% so we bold the input commands via the following macro&#xa;</xsl:text>
            <xsl:text>\newcommand{\consoleinput}[1]{\textbf{#1}}&#xa;</xsl:text>
            <!-- https://tex.stackexchange.com/questions/299401/bold-just-one-line-inside-of-lstlisting/299406 -->
            <!-- Syntax highlighting is not so great for "language=bash" -->
            <!-- Line-breaking off to match old behavior, prebreak option fails inside LaTeX for input -->
            <xsl:text>\lstdefinestyle{consolecodestyle}{language=none, escapeinside={(*}{*)}, identifierstyle=, commentstyle=, stringstyle=, keywordstyle=, breaklines=false, breakatwhitespace=false, columns=fixed, extendedchars=true, aboveskip=0pt, belowskip=0pt}&#xa;</xsl:text>
            <!--  -->
            <xsl:text>\tcbset{ consoleboxstyle/.style={left=0pt, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt, boxsep=0pt,&#xa;</xsl:text>
            <xsl:text>listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>colback=white, boxrule=-0.3pt,&#xa;</xsl:text>
            <xsl:text>parbox=false,&#xa;</xsl:text>
            <xsl:text>} }&#xa;</xsl:text>
            <!--  -->
            <xsl:text>\newtcblisting{console}{consoleboxstyle, listing options={style=consolecodestyle}}&#xa;</xsl:text>
       </xsl:if>
        <xsl:if test="$b-has-sage">
            <xsl:text>%% The listings package as tcolorbox for Sage code&#xa;</xsl:text>
            <xsl:text>%% We do as much styling as possible with tcolorbox, not listings&#xa;</xsl:text>
            <xsl:text>%% Sage's blue is 50%, we go way lighter (blue!05 would also work)&#xa;</xsl:text>
            <xsl:text>%% Note that we defuse listings' default "aboveskip" and "belowskip"&#xa;</xsl:text>
            <!-- NB: tcblisting "forgets" its colors as it breaks across pages, -->
            <!-- and "frame empty" on the output is not sufficient.  So we set  -->
            <!-- the frame color to white.                                      -->
            <!-- See: https://tex.stackexchange.com/questions/240246/           -->
            <!-- problem-with-tcblisting-at-page-break                          -->
            <!-- TODO: integrate into the LaTeX styling schemes -->
            <xsl:text>\definecolor{sageblue}{rgb}{0.95,0.95,1}&#xa;</xsl:text>
            <xsl:text>\tcbset{ sagestyle/.style={left=0pt, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt,&#xa;</xsl:text>
            <xsl:text>boxsep=4pt, listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>parbox=false, &#xa;</xsl:text>
            <xsl:text>listing options={language=Python,breaklines=true,breakatwhitespace=true, extendedchars=true, aboveskip=0pt, belowskip=0pt}} }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageinput}{sagestyle, colback=sageblue, sharp corners, boxrule=0.5pt, }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageoutput}{sagestyle, colback=white, colframe=white, frame empty, before skip=0pt, after skip=0pt, }&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
  <xsl:if test="$document-root//sidebyside">
    <!-- "minimal" is no border or spacing at all -->
    <!-- set on $sbsdebug to "tight" with some background    -->
    <!-- From the tcolorbox manual, "center" vs. "flush center":      -->
    <!-- "The differences between the flush and non-flush version     -->
    <!-- are explained in detail in the TikZ manual. The short story  -->
    <!-- is that the non-flush versions will often look more balanced -->
    <!-- but with more hyphenations."                                 -->
    <xsl:choose>
      <xsl:when test="$sbsdebug">
        <xsl:text>%% tcolorbox styles for *DEBUGGING* sidebyside layout&#xa;</xsl:text>
        <xsl:text>%% "tight" -> 0.4pt border, pink background&#xa;</xsl:text>
        <xsl:text>\tcbset{ sbsstyle/.style={raster equal height=rows,raster force size=false} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ sbspanelstyle/.style={size=tight,colback=pink} }&#xa;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>%% tcolorbox styles for sidebyside layout&#xa;</xsl:text>
        <!-- "frame empty" is needed to counteract very faint outlines in some PDF viewers -->
        <!-- framecol=white is inadvisable, "frame hidden" is ineffective for default skin -->
        <xsl:text>\tcbset{ bwminimalstyle/.style={size=minimal, boxrule=-0.3pt, frame empty,&#xa;</xsl:text>
        <xsl:text>colback=white, colbacktitle=white, coltitle=black, opacityfill=0.0} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ sbsstyle/.style={raster before skip=2.0ex, raster equal height=rows, raster force size=false} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ sbspanelstyle/.style={bwminimalstyle} }&#xa;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>%% Enviroments for side-by-side and components&#xa;</xsl:text>
    <xsl:text>%% Necessary to use \NewTColorBox for boxes of the panels&#xa;</xsl:text>
    <xsl:text>%% "newfloat" environment to squash page-breaks within a single sidebyside&#xa;</xsl:text>
    <!-- Main side-by-side environment, given by xparse            -->
    <!-- raster equal height: boxes of same *row* have same height -->
    <!-- raster force size: false lets us control width            -->
    <!-- We do not try here to keep captions attached (when not    -->
    <!-- in a "figure"), unfortunately, this is an un-semantic     -->
    <!-- command inbetween the list of panels and the captions     -->
    <xsl:text>%% "xparse" environment for entire sidebyside&#xa;</xsl:text>
    <xsl:text>\NewDocumentEnvironment{sidebyside}{mmmm}&#xa;</xsl:text>
    <xsl:text>  {\begin{tcbraster}&#xa;</xsl:text>
    <xsl:text>    [sbsstyle,raster columns=#1,&#xa;</xsl:text>
    <xsl:text>    raster left skip=#2\linewidth,raster right skip=#3\linewidth,raster column skip=#4\linewidth]}&#xa;</xsl:text>
    <xsl:text>  {\end{tcbraster}}&#xa;</xsl:text>
    <xsl:text>%% "tcolorbox" environment for a panel of sidebyside&#xa;</xsl:text>
    <xsl:text>\NewTColorBox{sbspanel}{mO{top}}{sbspanelstyle,width=#1\linewidth,valign=#2}&#xa;</xsl:text>
  </xsl:if>

  <xsl:if test="$document-root//tabular">
    <xsl:text>%% For improved tables&#xa;</xsl:text>
    <xsl:text>\usepackage{array}&#xa;</xsl:text>
    <xsl:text>%% Some extra height on each row is desirable, especially with horizontal rules&#xa;</xsl:text>
    <xsl:text>%% Increment determined experimentally&#xa;</xsl:text>
    <xsl:text>\setlength{\extrarowheight}{0.2ex}&#xa;</xsl:text>
    <xsl:text>%% Define variable thickness horizontal rules, full and partial&#xa;</xsl:text>
    <xsl:text>%% Thicknesses are 0.03, 0.05, 0.08 in the  booktabs  package&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/119153/table-with-different-rule-widths -->
    <xsl:text>\newcommand{\hrulethin}  {\noalign{\hrule height 0.04em}}&#xa;</xsl:text>
    <xsl:text>\newcommand{\hrulemedium}{\noalign{\hrule height 0.07em}}&#xa;</xsl:text>
    <xsl:text>\newcommand{\hrulethick} {\noalign{\hrule height 0.11em}}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/24549/horizontal-rule-with-adjustable-height-behaving-like-clinen-m -->
    <!-- Could preserve/restore \arrayrulewidth on entry/exit to tabular -->
    <!-- But we'll get cleaner source with this built into macros        -->
    <!-- Could condition \setlength debacle on the use of extpfeil       -->
    <!-- arrows (see discussion below)                                   -->
    <xsl:text>%% We preserve a copy of the \setlength package before other&#xa;</xsl:text>
    <xsl:text>%% packages (extpfeil) get a chance to load packages that redefine it&#xa;</xsl:text>
    <xsl:text>\let\oldsetlength\setlength&#xa;</xsl:text>
    <xsl:text>\newlength{\Oldarrayrulewidth}&#xa;</xsl:text>
    <xsl:text>\newcommand{\crulethin}[1]%&#xa;</xsl:text>
    <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
    <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.04em}}\cline{#1}%&#xa;</xsl:text>
    <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\crulemedium}[1]%&#xa;</xsl:text>
    <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
    <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.07em}}\cline{#1}%&#xa;</xsl:text>
    <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}&#xa;</xsl:text>
    <xsl:text>\newcommand{\crulethick}[1]%&#xa;</xsl:text>
    <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
    <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.11em}}\cline{#1}%&#xa;</xsl:text>
    <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/119153/table-with-different-rule-widths -->
    <xsl:text>%% Single letter column specifiers defined via array package&#xa;</xsl:text>
    <xsl:text>\newcolumntype{A}{!{\vrule width 0.04em}}&#xa;</xsl:text>
    <xsl:text>\newcolumntype{B}{!{\vrule width 0.07em}}&#xa;</xsl:text>
    <xsl:text>\newcolumntype{C}{!{\vrule width 0.11em}}&#xa;</xsl:text>
  </xsl:if>
  <xsl:if test="$document-root//cell/line">
    <xsl:text>\newcommand{\tablecelllines}[3]%&#xa;</xsl:text>
    <xsl:text>{\begin{tabular}[#2]{@{}#1@{}}#3\end{tabular}}&#xa;</xsl:text>
  </xsl:if>

  <xsl:text>\newcommand{\lt}{&lt;}&#xa;</xsl:text>
  <xsl:text>\newcommand{\gt}{&gt;}&#xa;</xsl:text>
  <xsl:text>\newcommand{\amp}{&amp;}&#xa;&#xa;</xsl:text>
  <!-- ############### -->
  <!-- Semantic Macros -->
  <!-- ############### -->
  <xsl:text>%% Begin: Semantic Macros&#xa;</xsl:text>
  <xsl:text>%% To preserve meaning in a LaTeX file&#xa;</xsl:text>
  <xsl:text>%%&#xa;</xsl:text>
  <xsl:text>%% \mono macro for content of "c", "cd", "tag", etc elements&#xa;</xsl:text>
  <xsl:text>%% Also used automatically in other constructions&#xa;</xsl:text>
  <xsl:text>%% Simply an alias for \texttt&#xa;</xsl:text>
  <xsl:text>%% Always defined, even if there is no need, or if a specific tt font is not loaded&#xa;</xsl:text>
  <xsl:text>\newcommand{\mono}[1]{\texttt{#1}}&#xa;</xsl:text>
  <xsl:text>%%&#xa;</xsl:text>
  <xsl:text>%% Following semantic macros are only defined here if their&#xa;</xsl:text>
  <xsl:text>%% use is required only in this specific document&#xa;</xsl:text>
  <xsl:text>%%&#xa;</xsl:text>
  <xsl:variable name="one-line-reps" select="
        ($document-root//abbr)[1]|
        ($document-root//acro)[1]|
        ($document-root//init)[1]"/>
  <!-- (after fillin before swung-dash) -->
  <!-- Eventually move explanation of section to condition  -->
  <xsl:for-each select="$one-line-reps">
    <xsl:apply-templates select="." mode="tex-macro"/>
  </xsl:for-each>
  <xsl:if test="$document-root//alert">
    <xsl:text>%% Used for warnings, typically bold and italic&#xa;</xsl:text>
    <xsl:text>\newcommand{\alert}[1]{\textbf{\textit{#1}}}&#xa;</xsl:text>
  </xsl:if>
  <xsl:if test="$document-root//term">
    <xsl:text>%% Used for inline definitions of terms&#xa;</xsl:text>
    <xsl:text>\newcommand{\terminology}[1]{\textbf{#1}}&#xa;</xsl:text>
  </xsl:if>
  <!-- 2018-02-05: "booktitle" deprecated -->
  <xsl:if test="$document-root//pubtitle|$document-root//booktitle">
    <xsl:text>%% Titles of longer works (e.g. books, versus articles)&#xa;</xsl:text>
    <xsl:text>\newcommand{\pubtitle}[1]{\textsl{#1}}&#xa;</xsl:text>
  </xsl:if>
  <!-- http://tex.stackexchange.com/questions/23711/strikethrough-text -->
  <!-- http://tex.stackexchange.com/questions/287599/thickness-for-sout-strikethrough-command-from-ulem-package -->
  <xsl:if test="$document-root//insert|$document-root//delete|$document-root//stale">
    <xsl:text>%% Edits (insert, delete), stale (irrelevant, obsolete)&#xa;</xsl:text>
    <xsl:text>%% Package: underlines and strikethroughs, no change to \emph{}&#xa;</xsl:text>
    <xsl:text>\usepackage[normalem]{ulem}&#xa;</xsl:text>
    <xsl:text>%% Rules in this package reset proportional to fontsize&#xa;</xsl:text>
    <xsl:text>%% NB: *never* reset to package default (0.4pt?) after use&#xa;</xsl:text>
    <xsl:text>%% Macros will use colors if latex.print='no'  (the default)&#xa;</xsl:text>
    <xsl:if test="$document-root//insert">
      <xsl:text>%% Used for an edit that is an addition&#xa;</xsl:text>
      <xsl:text>\newcommand{\insertthick}{.1ex}&#xa;</xsl:text>
      <xsl:choose>
        <xsl:when test="$latex.print='yes'">
          <xsl:text>\newcommand{\inserted}[1]{\renewcommand{\ULthickness}{\insertthick}\uline{#1}}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>\newcommand{\inserted}[1]{\renewcommand{\ULthickness}{\insertthick}\textcolor{green}{\uline{#1}}}&#xa;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$document-root//delete">
      <xsl:text>%% Used for an edit that is a deletion&#xa;</xsl:text>
      <xsl:text>\newcommand{\deletethick}{.25ex}&#xa;</xsl:text>
      <xsl:choose>
        <xsl:when test="$latex.print='yes'">
          <xsl:text>\newcommand{\deleted}[1]{\renewcommand{\ULthickness}{\deletethick}\sout{#1}}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>\newcommand{\deleted}[1]{\renewcommand{\ULthickness}{\deletethick}\textcolor{red}{\sout{#1}}}&#xa;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$document-root//stale">
      <xsl:text>%% Used for inline irrelevant or obsolete text&#xa;</xsl:text>
      <xsl:text>\newcommand{\stalethick}{.1ex}&#xa;</xsl:text>
      <xsl:text>\newcommand{\stale}[1]{\renewcommand{\ULthickness}{\stalethick}\sout{#1}}&#xa;</xsl:text>
    </xsl:if>
  </xsl:if>
  <!-- 2020-05-28: this "if" was edited in xsl/pretext-latex and is no longer in-sync -->
  <xsl:if test="$document-root//fillin">
    <xsl:text>%% Used for fillin answer blank&#xa;</xsl:text>
    <xsl:text>%% Argument is length in em&#xa;</xsl:text>
    <xsl:text>%% Length may compress for output to fit in one line&#xa;</xsl:text>
    <xsl:choose>
      <xsl:when test="$latex.fillin.style='underline'">
        <xsl:text>\newcommand{\fillin}[1]{\leavevmode\leaders\vrule height -1.2pt depth 1.5pt \hskip #1em minus #1em \null}&#xa;</xsl:text>
      </xsl:when>
      <xsl:when test="$latex.fillin.style='box'">
        <xsl:text>% Do not indent lines of this macro definition&#xa;</xsl:text>
        <xsl:text>\newcommand{\fillin}[1]{%&#xa;</xsl:text>
        <xsl:text>\leavevmode\rule[-0.3\baselineskip]{0.4pt}{\dimexpr 0.8pt+1.3\baselineskip\relax}% Left edge&#xa;</xsl:text>
        <xsl:text>\nobreak\leaders\vbox{\hrule \vskip 1.3\baselineskip \hrule width .4pt \vskip -0.3\baselineskip}% Top and bottom edges&#xa;</xsl:text>
        <xsl:text>\hskip #1em minus #1em% Maximum box width and shrinkage&#xa;</xsl:text>
        <xsl:text>\nobreak\hbox{\rule[-0.3\baselineskip]{0.4pt}{\dimexpr 0.8pt+1.3\baselineskip\relax}}% Right edge&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">MBX:ERROR: invalid value <xsl:value-of select="$latex.fillin.style" />
 for latex.fillin.style stringparam. Should be 'underline' or 'box'.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
  <!-- http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/ -->
  <xsl:if test="$document-root//swungdash">
    <xsl:text>%% A character like a tilde, but different&#xa;</xsl:text>
    <xsl:text>\newcommand{\swungdash}{\raisebox{-2.25ex}{\scalebox{2}{\~{}}}}&#xa;</xsl:text>
  </xsl:if>
  <xsl:if test="$document-root//quantity">
    <xsl:text>%% Used for units and number formatting&#xa;</xsl:text>
    <xsl:text>\usepackage[per-mode=fraction]{siunitx}&#xa;</xsl:text>
    <xsl:text>\sisetup{inter-unit-product=\cdot}&#xa;</xsl:text>
    <xsl:text>\ifxetex\sisetup{math-micro=\text{µ},text-micro=µ}\fi</xsl:text>
    <xsl:text>\ifluatex\sisetup{math-micro=\text{µ},text-micro=µ}\fi</xsl:text>
    <xsl:text>%% Common non-SI units&#xa;</xsl:text>
    <xsl:for-each select="document('pretext-units.xsl')//base[@siunitx]">
      <xsl:text>\DeclareSIUnit\</xsl:text>
      <xsl:value-of select="@full" />
      <xsl:text>{</xsl:text>
      <xsl:choose>
        <xsl:when test="@siunitx='none'">
          <xsl:value-of select="@short" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@siunitx" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>}&#xa;</xsl:text>
    </xsl:for-each>
  </xsl:if>
  <xsl:if test="$document-root//case[@direction]">
    <!-- Perhaps customize these via something like tex-macro-style      -->
    <!-- And/or move these closer to the environment where they are used -->
    <xsl:text>%% Arrows for iff proofs, with trailing space&#xa;</xsl:text>
    <xsl:text>\newcommand{\forwardimplication}{($\Rightarrow$)}&#xa;</xsl:text>
    <xsl:text>\newcommand{\backwardimplication}{($\Leftarrow$)}&#xa;</xsl:text>
  </xsl:if>
  <xsl:if test="$document-root//ol/li/title|$document-root//ul/li/title">
    <!-- Styling: expose this macro to easier overriding for style work -->
    <xsl:text>%% Style of a title on a list item, for ordered and unordered lists&#xa;</xsl:text>
    <xsl:text>\newcommand{\lititle}[1]{{\slshape#1}}&#xa;</xsl:text>
  </xsl:if>
  <xsl:text>%% End: Semantic Macros&#xa;</xsl:text>
  <xsl:if test="$latex.preamble.late != ''">
    <xsl:text>%% Custom Preamble Entries, late (use latex.preamble.late)&#xa;</xsl:text>
    <xsl:value-of select="$latex.preamble.late" />
    <xsl:text>&#xa;</xsl:text>
  </xsl:if>

  <xsl:apply-templates select="/pretext/docinfo/macros"/>
  <xsl:if test="$docinfo/latex-image-preamble">
    <xsl:text>%% Graphics Preamble Entries&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
      <xsl:with-param name="text" select="$docinfo/latex-image-preamble" />
    </xsl:call-template>
  </xsl:if>
  <xsl:text>&#xa;&#xa;%%%% End of PreTeXt generated preamble %%%%% &#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="pretext/docinfo/macros">
    <xsl:value-of select="."/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template name="body">
  <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="/pretext/slideshow" mode="title-full" />
  <xsl:text>}&#xa;</xsl:text>
  <xsl:if test="/pretext/slideshow/subtitle">
  <xsl:text>\subtitle{</xsl:text>
    <xsl:apply-templates select="." mode="subtitle" />
  <xsl:text>}&#xa;</xsl:text>
  </xsl:if>
  <xsl:text>\author{</xsl:text>
    <xsl:apply-templates select="author|frontmatter/titlepage/author" mode="article-info"/>
  <xsl:text>}&#xa;</xsl:text>
  <xsl:text>\date[</xsl:text>
  <xsl:if test="frontmatter/titlepage/date">
    <xsl:apply-templates select="frontmatter/titlepage/date"/>
  </xsl:if>
  <xsl:if test="date">
    <xsl:apply-templates select="date"/>
  </xsl:if>
  <xsl:text>]{</xsl:text>
  <xsl:if test="frontmatter/titlepage/event">
    <xsl:apply-templates select="frontmatter/titlepage/event"/>
  </xsl:if>
  <xsl:if test="event">
    <xsl:apply-templates select="event"/>
  </xsl:if>
  <xsl:text>}&#xa;&#xa;</xsl:text>
  <xsl:text>\begin{document}&#xa;</xsl:text>
  <xsl:call-template name="titlepage"/>
  <xsl:call-template name="beamertoc"/>

  <xsl:apply-templates select="section|slide"/>
  <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="titlepage">
  <xsl:text>\begin{frame}&#xa;</xsl:text>
  <xsl:text>\maketitle &#xa;</xsl:text>
  <xsl:text>\end{frame}&#xa; &#xa;</xsl:text>
</xsl:template>

<xsl:template name="beamertoc">
  <xsl:text>\begin{frame}&#xa;</xsl:text>
  <xsl:text>\frametitle{Overview}&#xa;</xsl:text>
  <xsl:text>\tableofcontents &#xa;</xsl:text>
  <xsl:text>\end{frame}&#xa; &#xa;</xsl:text>
</xsl:template>

<xsl:template match="section">
  <xsl:text>&#xa;\section{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
  <xsl:text>}&#xa;</xsl:text>
  <xsl:apply-templates select="slide"/>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="slide">
  <xsl:text>\begin{frame}&#xa;</xsl:text>
    <xsl:text>\frametitle{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates/>
  <xsl:text>\end{frame}&#xa; &#xa;</xsl:text>
</xsl:template>


<xsl:template match="p">
    <xsl:if test="@pause = 'yes'">
        <xsl:text>&#xa;\pause \vfill &#xa;&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul">
  <xsl:if test="@pause = 'yes'">
    <xsl:text>&#xa;\pause &#xa;&#xa;</xsl:text>
  </xsl:if>
  <xsl:text>\begin{itemize}</xsl:text>
  <xsl:if test="@pause = 'yes'">
    <xsl:text>[&lt;+-&gt;]</xsl:text>
  </xsl:if>
  <xsl:apply-templates/>
  <xsl:text>\end{itemize}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ol">
  <xsl:if test="@pause = 'yes'">
    <xsl:text>&#xa;\pause &#xa;&#xa;</xsl:text>
  </xsl:if>
  <xsl:text>\begin{enumerate}</xsl:text>
  <xsl:if test="@pause = 'yes'">
    <xsl:text>[&lt;+-&gt;]</xsl:text>
  </xsl:if>
  <xsl:apply-templates/>
  <xsl:text>\end{enumerate}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="li">
  <xsl:text>&#xa;\item{} </xsl:text>
  <xsl:apply-templates/>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- 
<xsl:template match="sidebyside">
  <xsl:text>\begin{tcbraster}[arc=0pt, raster columns=</xsl:text>
  <xsl:value-of select="count(*)"/>
  <xsl:text>, raster equal height=rows, raster force size=false, raster column skip=0ex] &#xa;</xsl:text>

  <xsl:variable name="columnCount" select="count(*)"/>
  <xsl:variable name="widthFraction" select="1 div $columnCount"/>

  <xsl:for-each select="*">
    <xsl:if test="parent::*/@pause = 'yes'">
      <xsl:text>&#xa;\pause &#xa;&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{tcolorbox}[valign=top, width=</xsl:text>
      <xsl:value-of select="$widthFraction" />
    <xsl:text>\textwidth]&#xa;</xsl:text>
      <xsl:apply-templates select="."/>
    <xsl:text>\end{tcolorbox}&#xa; </xsl:text>
  </xsl:for-each>
  <xsl:text>\end{tcbraster} &#xa;</xsl:text>
</xsl:template> -->

<xsl:template match="proof">
  <xsl:text>\begin{proof}</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>\end{proof}</xsl:text>
</xsl:template>

<xsl:template match="xref">
  [REF=TODO]
<!--  Look up this in some xsl files -->
<!-- <xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="content" />

    <xsl:copy-of select="$content"/>
</xsl:template> -->
</xsl:template>



<xsl:template match="example">
  <xsl:text>\begin{example}[</xsl:text>
  <xsl:if test="@source-number">
    <xsl:value-of select="@source-number"/>
  </xsl:if>
  <xsl:apply-templates select="." mode="title-full" />
<xsl:text>]</xsl:text>
    <xsl:apply-templates/>
<xsl:text>\end{example}&#xa;</xsl:text>
</xsl:template>


<xsl:template match="definition" mode="type-name">
  <xsl:text>Definition</xsl:text>
</xsl:template>
<xsl:template match="definition">
  <xsl:text>\begin{definition}{</xsl:text>
  <xsl:apply-templates select="." mode="type-name" />
  <xsl:choose>
  <xsl:when test="@source-number">
    (<xsl:value-of select="@source-number"/>)
  </xsl:when>
</xsl:choose>
<xsl:text>: </xsl:text>
  <xsl:apply-templates select="." mode="title-full" />
<xsl:text>}</xsl:text>
    <xsl:apply-templates/>
<xsl:text>\end{definition}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="theorem" mode="type-name">
  <xsl:text>Theorem</xsl:text>
</xsl:template>
<xsl:template match="corollary" mode="type-name">
  <xsl:text>Corollary</xsl:text>
</xsl:template>
<xsl:template match="theorem|corollary">
  <xsl:text>\begin{theorem}{</xsl:text>
  <xsl:apply-templates select="." mode="type-name" />
  <xsl:choose>
  <xsl:when test="@source-number">
     (<xsl:value-of select="@source-number"/>)
  </xsl:when>
</xsl:choose>
<xsl:text>: </xsl:text>
  <xsl:apply-templates select="." mode="title-full" />
<xsl:text>}</xsl:text>
    <xsl:apply-templates select="statement"/>
<xsl:text>\end{theorem}&#xa;</xsl:text>
<xsl:apply-templates select="proof"/>
</xsl:template>

</xsl:stylesheet>
