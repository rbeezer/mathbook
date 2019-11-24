<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2013 Robert A. Beezer

This file is part of MathBook XML.

MathBook XML is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

MathBook XML is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MathBook XML.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
>

<xsl:import href="./mathbook-common.xsl" />

<!-- Intend output for rendering by pdflatex -->
<xsl:output method="text" />

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!--  -->
<!-- LaTeX executable, "engine"                       -->
<!-- pdflatex is default, xelatex or lualatex for Unicode support -->
<!-- N.B. This has no effect, and may never.  xelatex and lualatex support is automatic -->
<xsl:param name="latex.engine" select="'pdflatex'" />
<!--  -->
<!-- Standard fontsizes: 10pt, 11pt, or 12pt       -->
<!-- extsizes package: 8pt, 9pt, 14pt, 17pt, 20pt  -->
<!-- memoir class offers more, but maybe other changes? -->
<xsl:param name="latex.font.size" select="'10pt'" />
<!--  -->
<!-- Geometry: page shape, margins, etc            -->
<!-- Pass a string with any of geometry's options  -->
<!-- Default is empty and thus ineffective         -->
<!-- Otherwise, happens early in preamble template -->
<xsl:param name="latex.geometry" select="''"/>
<!--  -->
<!-- PDF Watermarking                    -->
<!-- Non-empty string makes it happen    -->
<!-- Scale works well for "CONFIDENTIAL" -->
<!-- or  for "DRAFT YYYY/MM/DD"          -->
<!-- These are deprecated in favor of watermark.text and watermark.scale -->
<!-- which are now managed in common. These still "work" for now.        -->
<xsl:param name="latex.watermark" select="''"/>
<xsl:variable name="b-latex-watermark" select="not($latex.watermark = '')" />
<xsl:param name="latex.watermark.scale" select="''"/>
<xsl:variable name="latex-watermark-scale">
    <xsl:choose>
        <xsl:when test="not($latex.watermark.scale = '')">
            <xsl:value-of select="$latex.watermark.scale"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>2.0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<!--  -->
<!-- Author's Tools                                            -->
<!-- Set the author-tools parameter to 'yes'                   -->
<!-- (Documented in mathbook-common.xsl)                       -->
<!-- Installs some LaTeX-specific behavior                     -->
<!-- (1) Index entries in margin of the page                   -->
<!--      where defined, on single pass (no real index)        -->
<!-- (2) LaTeX labels near definition and use                  -->
<!--     N.B. Some are author-defined; others are internal,    -->
<!--     and CANNOT be used as xml:id's (will raise a warning) -->
<!--  -->
<!-- Draft Copies                                              -->
<!-- Various options for working copies for authors            -->
<!-- (1) LaTeX's draft mode                                    -->
<!-- (2) Crop marks on letter paper, centered                  -->
<!--     presuming geometry sets smaller page size             -->
<!--     with paperheight, paperwidth                          -->
<xsl:param name="latex.draft" select="'no'"/>
<!--  -->
<!-- Print Option                                         -->
<!-- For a non-electronic copy, inactive links in black   -->
<!-- Any color options go to black and white, as possible -->
<xsl:param name="latex.print" select="'no'"/>
<!--  -->
<!-- Page Numbers in cross-references -->
<xsl:param name="latex.pageref" select="''"/>
<!--  -->
<!-- Sidedness -->
<xsl:param name="latex.sides" select="''"/>
<!--  -->
<!-- Fillin Style Option                                  -->
<!-- Can be 'underline' or 'box'                          -->
<xsl:param name="latex.fillin.style" select="'underline'"/>
<!--  -->
<!-- Preamble insertions                    -->
<!-- Insert packages, options into preamble -->
<!-- early or late                          -->
<xsl:param name="latex.preamble.early" select="''" />
<xsl:param name="latex.preamble.late" select="''" />
<!--  -->
<!-- DEPRECATED: 2017-12-18, do not use, any value -->
<!-- besides an empty string will raise a warning  -->
<xsl:param name="latex.console.macro-char" select="''" />
<xsl:param name="latex.console.begin-char" select="''" />
<xsl:param name="latex.console.end-char" select="''" />


<!-- ############### -->
<!-- Source Analysis -->
<!-- ############### -->

<!-- We check certain aspects of the source and record the results   -->
<!-- in boolean ($b-has-*) variables or as particular nodes high     -->
<!-- up in the structure ($document-root).  Scans here in -latex     -->
<!-- should help streamline the construction of the preamble by      -->
<!-- computing properties that will be checked more than once.       -->
<!-- While technically generally part of constructing the preamble,  -->
<!-- there is no real harm in making these global variables.  Short, -->
<!-- simple, and universal properties are determined in -common.     -->
<!-- These may duplicate variables in disjoint conversions.          -->

<xsl:variable name="b-has-icon"         select="boolean($document-root//icon)" />
<xsl:variable name="b-has-webwork-reps" select="boolean($document-root//webwork-reps)" />
<xsl:variable name="b-has-program"      select="boolean($document-root//program)" />
<xsl:variable name="b-has-console"      select="boolean($document-root//console)" />
<xsl:variable name="b-has-sidebyside"   select="boolean($document-root//sidebyside)" />
<xsl:variable name="b-has-sage"         select="boolean($document-root//sage)" />
<xsl:variable name="b-has-sfrac"        select="boolean($document-root//m[contains(text(),'sfrac')] or $document-root//md[contains(text(),'sfrac')] or $document-root//me[contains(text(),'sfrac')] or $document-root//mrow[contains(text(),'sfrac')])" />


<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- Variables that affect LaTeX creation -->
<!-- More in the -common file             -->

<!-- LaTeX is handled natively, so we flip a  -->
<!-- switch here to signal the general text() -->
<!-- handler in xsl/mathbook-common.xsl to    -->
<!-- not dress-up clause-ending punctuation   -->
<xsl:variable name="latex-processing" select="'native'" />

<!-- Not a parameter, a variable to override deliberately within a conversion -->
<xsl:variable name="b-latex-hardcode-numbers" select="false()"/>

<!-- We allow publishers to choose one-sided or two-sided -->
<!-- "printing" though the default will vary with the     -->
<!-- electronic/print dichotomy                           -->
<xsl:variable name="latex-sides">
    <xsl:variable name="default-sides">
        <xsl:choose>
            <xsl:when test="$latex.print = 'yes'">
                <xsl:text>two</xsl:text>
            </xsl:when>
            <xsl:otherwise> <!-- electronic -->
                <xsl:text>one</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$latex.sides = ''">
            <xsl:value-of select="$default-sides"/>
        </xsl:when>
        <xsl:when test="$latex.sides = 'one'">
            <xsl:text>one</xsl:text>
        </xsl:when>
        <xsl:when test="$latex.sides = 'two'">
            <xsl:text>two</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$default-sides"/>
            <xsl:message>PTX:WARNING: the "latex.sides" stringparam should be "one" or "two", not "<xsl:value-of select="$latex.sides"/>", so assuming "<xsl:value-of select="$default-sides"/>"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- We generally want one large complete LaTeX file -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk.level != ''">
            <xsl:message terminate="yes">MBX:ERROR:   chunking of LaTeX output is deprecated as of 2016-06-10, remove the "chunk.level" stringparam</xsl:message>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>0</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- LaTeX always puts sections at level "1", while PTX         -->
<!-- has sections at level "2", so we provide adjusted,         -->
<!-- LaTeX-only variables for packages/macros that crudely      -->
<!-- expect these kinds of numbers (rather than division names) -->
<xsl:variable name="latex-toc-level">
    <xsl:call-template name="level-to-latex-level">
        <xsl:with-param name="level" select="$toc-level" />
    </xsl:call-template>
</xsl:variable>
<xsl:variable name="latex-numbering-maxlevel">
    <xsl:call-template name="level-to-latex-level">
        <xsl:with-param name="level" select="$numbering-maxlevel" />
    </xsl:call-template>
</xsl:variable>

<!-- We override the default ToC structure    -->
<!-- just to kill the ToC always for articles -->
<xsl:variable name="toc-level">
    <xsl:choose>
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <xsl:when test="$root/book/article">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- font-size also dictates document class for -->
<!-- those provided by extsizes, but we can get -->
<!-- these by just inserting the "ext" prefix   -->
<!-- We don't load the package, the classes     -->
<!-- are incorporated in the documentclass[]{}  -->
<!-- and only if we need the extreme values     -->

<!-- Default is 10pt above, this stupid template     -->
<!-- provides an error message and also sets a value -->
<!-- we can condition on for the extsizes package.   -->
<!-- In predicted order, sort of, so fall out early  -->

<!-- NB: Code using $font-size and latex.geometry is also -->
<!-- used in the latex-image extraction stylesheet. Until -->
<!-- we do a better job of ensuring they remain in-sync,  -->
<!-- please coordinate the two sets of templates by hand  -->

<xsl:variable name="font-size">
    <xsl:choose>
        <xsl:when test="$latex.font.size='10pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='12pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='11pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='8pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='9pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='14pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='17pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:when test="$latex.font.size='20pt'"><xsl:value-of select="$latex.font.size" /></xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">MBX:ERROR   the latex.font.size parameter must be 8pt, 9pt, 10pt, 11pt, 12pt, 14pt, 17pt, or 20pt, not "<xsl:value-of select="$latex.font.size" />"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- A convenient shortcut/hack that might need expansion later   -->
<!-- insert "ext" or nothing in front of "regular" document class -->
<xsl:variable name="document-class-prefix">
    <xsl:choose>
        <xsl:when test="$font-size='10pt'"></xsl:when>
        <xsl:when test="$font-size='12pt'"></xsl:when>
        <xsl:when test="$font-size='11pt'"></xsl:when>
        <xsl:otherwise>
            <xsl:text>ext</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Including page numbers in cross-references defaults to      -->
<!-- 'yes' for an electronic PDF and to 'no' for a print PDF,    -->
<!-- and of course can be switched away from the default at will -->
<!-- NB: upgrade the latex.print variable to something like this -->
<xsl:variable name="pagerefs-option">
    <xsl:choose>
        <!-- electronic PDF -->
        <xsl:when test="$latex.print = 'no'">
            <xsl:choose>
                <xsl:when test="$latex.pageref = 'yes'">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
                <xsl:when test="($latex.pageref = 'no') or ($latex.pageref = '')">
                    <xsl:text>no</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <!-- print PDF -->
        <xsl:when test="$latex.print = 'yes'">
            <xsl:choose>
                <xsl:when test="$latex.pageref = 'no'">
                    <xsl:text>no</xsl:text>
                </xsl:when>
                <xsl:when test="($latex.pageref = 'yes') or ($latex.pageref = '')">
                    <xsl:text>yes</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-pageref" select="$pagerefs-option = 'yes'"/>

<!-- Conversions, like creating a solutions manual, may need   -->
<!-- LaTeX styles for the solutions to exercises, even if the  -->
<!-- source never has a "solutions" element.  So this variable -->
<!-- is set to false here, and an importing stylesheet can     -->
<!-- override it to be true.                                   -->
<xsl:variable name="b-needs-solution-styles" select="false()"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings-latex" />
    <xsl:apply-templates />
</xsl:template>

<!-- We will have just one of the following -->
<!-- four types, and totally ignore docinfo -->
<xsl:template match="/mathbook|/pretext">
    <xsl:apply-templates select="article|book|letter|memo"/>
</xsl:template>

<!-- TODO: combine article, book, letter, templates -->
<!-- with abstract templates for latex classes, page sizes -->

<!-- An article, LaTeX structure -->
<!--     One page, full of sections (with abstract, references)                    -->
<!--     Or, one page, totally unstructured, just lots of paragraphs, widgets, etc -->
<xsl:template match="article">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <!-- parameterize preamble template with "page-geometry" template conditioned on self::article etc -->
    <xsl:call-template name="title-page-info-article" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <xsl:call-template name="front-cover"/>
    <!-- Target for xref to top-level element -->
    <!-- immediately, or first in ToC         -->
    <xsl:choose>
        <xsl:when test="$b-has-toc">
            <xsl:text>%% Target for xref to top-level element is ToC&#xa;</xsl:text>
            <xsl:text>\addtocontents{toc}{</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\protect\label{</xsl:text>
                <xsl:apply-templates select="." mode="latex-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\protect\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id" />
            <xsl:text>}{}</xsl:text>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%% Target for xref to top-level element is document start&#xa;</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\label{</xsl:text>
                <xsl:apply-templates select="." mode="latex-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id" />
            <xsl:text>}{}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- If no frontmatter/titlepage, then title is not printed       -->
    <!-- so we make sure it happens here, else triggered by titlepage -->
    <!-- If a title, we know it is page 1, so use empty style -->
    <xsl:if test="title and not(frontmatter/titlepage)">
        <xsl:text>\maketitle&#xa;</xsl:text>
        <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates />
    <xsl:call-template name="back-cover"/>
   <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A book, LaTeX structure -->
<!-- The ordering of the frontmatter is from             -->
<!-- "Bookmaking", 3rd Edition, Marshall Lee, Chapter 27 -->
<xsl:template match="book">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>book}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <xsl:apply-templates />
    <xsl:call-template name="back-cover"/>
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A letter, LaTeX structure -->
<xsl:template match="letter">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <xsl:apply-templates />
    <xsl:text>\end{document}</xsl:text>
</xsl:template>

<!-- A memo, LaTeX structure -->
<xsl:template match="memo">
    <xsl:call-template name="converter-blurb-latex" />
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size" />
    <xsl:text>,</xsl:text>
    <xsl:if test="$latex.draft='yes'" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$document-class-prefix" />
    <xsl:text>article}&#xa;</xsl:text>
    <xsl:call-template name="latex-preamble" />
    <xsl:text>\begin{document}&#xa;</xsl:text>
    <xsl:call-template name="text-alignment"/>
    <xsl:apply-templates />
    <xsl:text>\end{document}&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX preamble is common for both books, articles, memos and letters -->
<!-- Except: title info allows an "event" for an article (presentation)   -->
<xsl:template name="latex-preamble">
    <xsl:text>%% Custom Preamble Entries, early (use latex.preamble.early)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.early != ''">
        <xsl:value-of select="$latex.preamble.early" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <!-- Following need to be mature, robust, powerful, flexible, well-maintained -->
    <xsl:text>%% Default LaTeX packages&#xa;</xsl:text>
    <xsl:text>%%   1.  always employed (or nearly so) for some purpose, or&#xa;</xsl:text>
    <xsl:text>%%   2.  a stylewriter may assume their presence&#xa;</xsl:text>
    <xsl:text>\usepackage{geometry}&#xa;</xsl:text>
    <xsl:text>%% Some aspects of the preamble are conditional,&#xa;</xsl:text>
    <xsl:text>%% the LaTeX engine is one such determinant&#xa;</xsl:text>
    <xsl:text>\usepackage{ifthen}&#xa;</xsl:text>
    <xsl:text>%% etoolbox has a variety of modern conveniences&#xa;</xsl:text>
    <!-- e.g, \notblank -->
    <xsl:text>\usepackage{etoolbox}&#xa;</xsl:text>
    <xsl:text>\usepackage{ifxetex,ifluatex}&#xa;</xsl:text>
    <xsl:text>%% Raster graphics inclusion&#xa;</xsl:text>
    <xsl:text>\usepackage{graphicx}&#xa;</xsl:text>
    <xsl:text>%% Color support, xcolor package&#xa;</xsl:text>
    <xsl:text>%% Always loaded, for: add/delete text, author tools&#xa;</xsl:text>
    <xsl:text>%% Here, since tcolorbox loads tikz, and tikz loads xcolor&#xa;</xsl:text>
    <!-- Avoid option conflicts causing errors: -->
    <!-- http://tex.stackexchange.com/questions/57364/option-clash-for-package-xcolor -->
    <!-- svg later will clobber dvips?  See starred versions in xcolor documentation  -->
    <!-- TODO: usenames may be obsolete? -->
    <xsl:text>\PassOptionsToPackage{usenames,dvipsnames,svgnames,table}{xcolor}&#xa;</xsl:text>
    <xsl:text>\usepackage{xcolor}&#xa;</xsl:text>
    <xsl:text>%% Colored boxes, and much more, though mostly styling&#xa;</xsl:text>
    <xsl:text>%% skins library provides "enhanced" skin, employing tikzpicture&#xa;</xsl:text>
    <xsl:text>%% boxes may be configured as "breakable" or "unbreakable"&#xa;</xsl:text>
    <xsl:text>%% "raster" controls grids of boxes, aka side-by-side&#xa;</xsl:text>
    <xsl:text>\usepackage{tcolorbox}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{skins}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{breakable}&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{raster}&#xa;</xsl:text>
    <xsl:text>%% We load some "stock" tcolorbox styles that we use a lot&#xa;</xsl:text>
    <xsl:text>%% Placement here is provisional, there will be some color work also&#xa;</xsl:text>
    <xsl:text>%% First, black on white, no border, transparent, but no assumption about titles&#xa;</xsl:text>
    <xsl:text>\tcbset{ bwminimalstyle/.style={size=minimal, boxrule=-0.3pt, frame empty,&#xa;</xsl:text>
    <xsl:text>colback=white, colbacktitle=white, coltitle=black, opacityfill=0.0} }&#xa;</xsl:text>
    <xsl:text>%% Second, bold title, run-in to text/paragraph/heading&#xa;</xsl:text>
    <xsl:text>%% Space afterwards will be controlled by environment,&#xa;</xsl:text>
    <xsl:text>%% dependent of constructions of the tcb title&#xa;</xsl:text>
    <xsl:text>\tcbset{ runintitlestyle/.style={fonttitle=\normalfont\bfseries, attach title to upper} }&#xa;</xsl:text>
    <xsl:text>%% Spacing prior to each exercise, anywhere&#xa;</xsl:text>
    <xsl:text>\tcbset{ exercisespacingstyle/.style={before skip={1.5ex plus 0.5ex}} }&#xa;</xsl:text>
    <xsl:text>%% Spacing prior to each block&#xa;</xsl:text>
    <xsl:text>\tcbset{ blockspacingstyle/.style={before skip={2.0ex plus 0.5ex}} }&#xa;</xsl:text>
    <xsl:text>%% xparse allows the construction of more robust commands,&#xa;</xsl:text>
    <xsl:text>%% this is a necessity for isolating styling and behavior&#xa;</xsl:text>
    <xsl:text>%% The tcolorbox library of the same name loads the base library&#xa;</xsl:text>
    <xsl:text>\tcbuselibrary{xparse}&#xa;</xsl:text>
    <xsl:text>%% Hyperref should be here, but likes to be loaded late&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Inline math delimiters, \(, \), need to be robust&#xa;</xsl:text>
    <xsl:text>%% 2016-01-31:  latexrelease.sty  supersedes  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% If  latexrelease.sty  exists, bugfix is in kernel&#xa;</xsl:text>
    <xsl:text>%% If not, bugfix is in  fixltx2e.sty&#xa;</xsl:text>
    <xsl:text>%% See:  https://tug.org/TUGboat/tb36-3/tb114ltnews22.pdf&#xa;</xsl:text>
    <xsl:text>%% and read "Fewer fragile commands" in distribution's  latexchanges.pdf&#xa;</xsl:text>
    <xsl:text>\IfFileExists{latexrelease.sty}{}{\usepackage{fixltx2e}}&#xa;</xsl:text>
    <!-- could condition on "subfigure-reps" -->
    <xsl:if test="$b-has-sidebyside">
        <xsl:text>%% shorter subnumbers in some side-by-side require manipulations&#xa;</xsl:text>
        <xsl:text>\usepackage{xstring}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//fn or $document-root//part">
        <xsl:text>%% Footnote counters and part/chapter counters are manipulated&#xa;</xsl:text>
        <xsl:text>%% April 2018:  chngcntr  commands now integrated into the kernel,&#xa;</xsl:text>
        <xsl:text>%% but circa 2018/2019 the package would still try to redefine them,&#xa;</xsl:text>
        <xsl:text>%% so we need to do the work of loading conditionally for old kernels.&#xa;</xsl:text>
        <xsl:text>%% From version 1.1a,  chngcntr  should detect defintions made by LaTeX kernel.&#xa;</xsl:text>
        <xsl:text>\ifdefined\counterwithin&#xa;</xsl:text>
        <xsl:text>\else&#xa;</xsl:text>
        <xsl:text>    \usepackage{chngcntr}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
        <xsl:if test="$parts = 'structural'">  <!-- implies book/part -->
            <xsl:text>%% Structural chapter numbers reset within parts&#xa;</xsl:text>
            <xsl:text>%% Starred form will not prefix part number&#xa;</xsl:text>
            <xsl:text>\counterwithin*{chapter}{part}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- Determine height of text block, assumes US letterpaper (11in height) -->
    <!-- Could react to document type, paper, margin specs                    -->
    <xsl:variable name="text-height">
        <xsl:text>9.0in</xsl:text>
    </xsl:variable>
    <!-- Bringhurst: 30x => 66 chars, so 34x => 75 chars -->
    <xsl:variable name="text-width">
        <xsl:value-of select="34 * substring-before($font-size, 'pt')" />
        <xsl:text>pt</xsl:text>
    </xsl:variable>
    <xsl:text>%% Text height identically 9 inches, text width varies on point size&#xa;</xsl:text>
    <xsl:text>%% See Bringhurst 2.1.1 on measure for recommendations&#xa;</xsl:text>
    <xsl:text>%% 75 characters per line (count spaces, punctuation) is target&#xa;</xsl:text>
    <xsl:text>%% which is the upper limit of Bringhurst's recommendations&#xa;</xsl:text>
    <xsl:text>\geometry{letterpaper,total={</xsl:text>
    <xsl:value-of select="$text-width" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$text-height" />
    <xsl:text>}}&#xa;</xsl:text>
    <xsl:text>%% Custom Page Layout Adjustments (use latex.geometry)&#xa;</xsl:text>
    <xsl:if test="$latex.geometry != ''">
        <xsl:text>\geometry{</xsl:text>
        <xsl:value-of select="$latex.geometry" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($text-alignment = 'justify')">
        <xsl:text>%% better handing of text alignment&#xa;</xsl:text>
        <xsl:text>\usepackage{ragged2e}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% This LaTeX file may be compiled with pdflatex, xelatex, or lualatex executables&#xa;</xsl:text>
    <xsl:text>%% LuaTeX is not explicitly supported, but we do accept additions from knowledgeable users&#xa;</xsl:text>
    <xsl:text>%% The conditional below provides  pdflatex  specific configuration last&#xa;</xsl:text>
    <xsl:text>%% The following provides engine-specific capabilities&#xa;</xsl:text>
    <xsl:text>%% Generally, xelatex is necessary for non-Western fonts&#xa;</xsl:text>
    <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}{%&#xa;</xsl:text>
    <xsl:text>%% begin: xelatex and lualatex-specific configuration&#xa;</xsl:text>
    <xsl:text>\ifxetex\usepackage{xltxtra}\fi&#xa;</xsl:text>
    <xsl:text>%% realscripts is the only part of xltxtra relevant to lualatex &#xa;</xsl:text>
    <xsl:text>\ifluatex\usepackage{realscripts}\fi&#xa;</xsl:text>
    <xsl:text>%% fontspec package provides extensive control of system fonts,&#xa;</xsl:text>
    <xsl:text>%% meaning *.otf (OpenType), and apparently *.ttf (TrueType)&#xa;</xsl:text>
    <xsl:text>%% that live *outside* your TeX/MF tree, and are controlled by your *system*&#xa;</xsl:text>
    <xsl:text>%% (it is possible that a TeX distribution will place fonts in a system location)&#xa;</xsl:text>
    <xsl:text>\usepackage{fontspec}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/115321/how-to-optimize-latin-modern-font-with-xelatex -->
    <xsl:text>%% We use Latin Modern (lmodern) as the default font&#xa;</xsl:text>
    <xsl:text>%% So we check that it is available as a system font&#xa;</xsl:text>
    <xsl:call-template name="xelatex-font-check">
        <xsl:with-param name="font-name" select="'Latin Modern Roman'"/>
    </xsl:call-template>
    <xsl:text>%% We then define various font family commands using a vanilla version,&#xa;</xsl:text>
    <xsl:text>%% with the intention of letting a style override these choices&#xa;</xsl:text>
    <xsl:text>%% \setmainfont can be re-issued, and \renewfontfamily can redefine others&#xa;</xsl:text>
    <!-- We do not attempt bold small caps in division headings (nor ToC, nor page style) -->
    <xsl:text>\setmainfont{Latin Modern Roman}[SmallCapsFont={Latin Modern Roman Caps}, SlantedFont={Latin Modern Roman Slanted}]&#xa;</xsl:text>
    <xsl:text>\newfontfamily{\divisionfont}{Latin Modern Roman}&#xa;</xsl:text>
    <xsl:text>\newfontfamily{\contentsfont}{Latin Modern Roman}&#xa;</xsl:text>
    <xsl:text>\newfontfamily{\pagefont}{Latin Modern Roman}[SlantedFont={Latin Modern Roman Slanted}]&#xa;</xsl:text>
    <xsl:text>\newfontfamily{\tabularfont}{Latin Modern Roman}[SmallCapsFont={Latin Modern Roman Caps}]&#xa;</xsl:text>
    <xsl:text>%% begin: font information supplied by "font-xelatex-style" template&#xa;</xsl:text>
    <xsl:call-template name="font-xelatex-style"/>
    <xsl:text>%% end: font information supplied by "font-xelatex-style" template&#xa;</xsl:text>
    <xsl:if test="$b-has-icon">
        <xsl:text>%% Icons being used, so xelatex needs a system font&#xa;</xsl:text>
        <xsl:text>%% This can only be determined at compile-time&#xa;</xsl:text>
        <xsl:call-template name="xelatex-font-check">
            <xsl:with-param name="font-name" select="'FontAwesome'"/>
        </xsl:call-template>
    </xsl:if>
    <xsl:text>%% &#xa;</xsl:text>
    <!-- language tags appear in docinfo in renames, so be careful -->
    <xsl:text>%% Extensive support for other languages&#xa;</xsl:text>
    <xsl:text>\usepackage{polyglossia}&#xa;</xsl:text>
    <xsl:text>%% Set main/default language based on pretext/@xml:lang value&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$document-language = 'en-US'">
            <xsl:text>%% document language code is "en-US", US English&#xa;</xsl:text>
            <xsl:text>%% usmax variant has extra hypenation&#xa;</xsl:text>
            <xsl:text>\setmainlanguage[variant=usmax]{english}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'el'">
            <xsl:text>%% document language code is "el", Modern Greek (1453-)&#xa;</xsl:text>
            <xsl:text>\setmainlanguage[variant=monotonic]{greek}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'es-ES'">
            <xsl:text>%% document language code is "es-ES", Spanish&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{spanish}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'hu-HU'">
            <xsl:text>%% document language code is "hu-HU", Magyar (Hungarian)&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{magyar}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'ko-KR'">
            <xsl:text>%% document language code is "ko-KR", Korean&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{korean}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'ru-RU'">
            <xsl:text>%% document language code is "ru-RU", Russian&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{russian}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$document-language = 'vi-VN'">
            <xsl:text>%% document language code is "vi-VN", Vietnamese&#xa;</xsl:text>
            <xsl:text>\setmainlanguage{vietnamese}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>%% Enable secondary languages based on discovery of @xml:lang values&#xa;</xsl:text>
    <!-- secondary: so not already "main", and look just beyond $document-root (eg "book") -->
    <xsl:if test="not($document-language = 'en-US') and ($document-root/*//@xml:lang = 'en-US')">
        <xsl:text>%% document contains language code "en-US", US English&#xa;</xsl:text>
        <xsl:text>%% usmax variant has extra hypenation&#xa;</xsl:text>
        <xsl:text>\setotherlanguage[variant=usmax]{english}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($document-language = 'es-ES') and ($document-root/*//@xml:lang = 'es-ES')">
        <xsl:text>%% document contains language code "es-ES", Spanish&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{spanish}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($document-language = 'el') and ($document-root/*//@xml:lang = 'el')">
        <xsl:text>%% document contains language code "el", Modern Greek (1453-)&#xa;</xsl:text>
        <xsl:text>\setotherlanguage[variant=monotonic]{greek}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($document-language = 'hu-HU') and ($document-root/*//@xml:lang = 'hu-HU')">
        <xsl:text>%% document contains language code "hu-HU", Magyar (Hungarian)&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{magyar}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($document-language = 'ko-KR') and ($document-root/*//@xml:lang = 'ko-KR')">
        <xsl:text>%% document contains language code "ko-KR", Korean&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{korean}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($document-language = 'ru-RU') and ($document-root/*//@xml:lang = 'ru-RU')">
        <xsl:text>%% document contains language code "ru-RU", Russian&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{russian}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($document-language = 'vi-VN') and ($document-root/*//@xml:lang = 'vi-VN')">
        <xsl:text>%% document contains language code "vi-VN", Vietnamese&#xa;</xsl:text>
        <xsl:text>\setotherlanguage{vietnamese}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Enable fonts/scripts based on discovery of @xml:lang values&#xa;</xsl:text>
    <xsl:text>%% Western languages should be ably covered by Latin Modern Roman&#xa;</xsl:text>
    <xsl:if test="$document-root/*//@xml:lang='el'">
        <xsl:text>%% Font for Modern Greek&#xa;</xsl:text>
        <xsl:text>%% Font families: CMU Serif (Ubuntu fonts-cmu package), Linux Libertine O, GFS Artemisia&#xa;</xsl:text>
        <xsl:text>%% OTF Script needs to be enabled&#xa;</xsl:text>
        <xsl:text>\newfontfamily\greekfont[Script=Greek]{CMU Serif}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root/*//@xml:lang='ko-KR'">
        <xsl:text>%% Font for Hangul&#xa;</xsl:text>
        <xsl:text>%% Font families: alternate - UnBatang with [Script=Hangul]&#xa;</xsl:text>
        <xsl:text>%% Debian/Ubuntu "fonts-nanum" package&#xa;</xsl:text>
        <xsl:text>\newfontfamily\koreanfont{NanumMyeongjo}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root/*//@xml:lang='ru-RU'">
        <xsl:text>%% Font for Cyrillic&#xa;</xsl:text>
        <xsl:text>%% Font families: CMU Serif, Linux Libertine O&#xa;</xsl:text>
        <xsl:text>%% OTF Script needs to be enabled&#xa;</xsl:text>
        <xsl:text>\newfontfamily\russianfont[Script=Cyrillic]{CMU Serif}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% end: xelatex and lualatex-specific configuration&#xa;</xsl:text>
    <xsl:text>}{%&#xa;</xsl:text>
    <xsl:text>%% begin: pdflatex-specific configuration&#xa;</xsl:text>
    <xsl:text>\usepackage[utf8]{inputenc}&#xa;</xsl:text>
    <xsl:text>%% PreTeXt will create a UTF-8 encoded file&#xa;</xsl:text>
    <xsl:text>%% begin: font setup and configuration for use with pdflatex&#xa;</xsl:text>
    <xsl:text>%% Portions of a document, are, or may, be affected by font-changing commands&#xa;</xsl:text>
    <xsl:text>%% These are more robust when using  xelatex  but may be employed with  pdflatex&#xa;</xsl:text>
    <xsl:text>%% The following definitons are meant to be re-defined in a style with \renewcommand&#xa;</xsl:text>
    <xsl:text>\newcommand{\divisionfont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\contentsfont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\pagefont}{\relax}&#xa;</xsl:text>
    <xsl:text>\newcommand{\tabularfont}{\relax}&#xa;</xsl:text>
    <xsl:text>%% begin: font information supplied by "font-pdflatex-style" template&#xa;</xsl:text>
    <xsl:call-template name="font-pdflatex-style"/>
    <xsl:text>%% begin: font information supplied by "font-pdflatex-style" template&#xa;</xsl:text>
    <xsl:text>%% end: font setup and configuration for use with pdflatex&#xa;</xsl:text>
    <xsl:text>%% end: pdflatex-specific configuration&#xa;</xsl:text>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="$b-has-program or $b-has-sage or $b-has-console or $document-root//c or $document-root//cd or $document-root//pre or $document-root//tag or $document-root//tage or $document-root//attr">
        <xsl:text>%% Monospace font: Inconsolata (zi4)&#xa;</xsl:text>
        <xsl:text>%% Sponsored by TUG: http://levien.com/type/myfonts/inconsolata.html&#xa;</xsl:text>
        <xsl:text>%% Loaded for documents with intentional objects requiring monospace&#xa;</xsl:text>
        <xsl:text>%% See package documentation for excellent instructions&#xa;</xsl:text>
        <xsl:text>%% One caveat, seem to need full file name to locate OTF files&#xa;</xsl:text>
        <xsl:text>%% Loads the "upquote" package as needed, so we don't have to&#xa;</xsl:text>
        <xsl:text>%% Upright quotes might come from the  textcomp  package, which we also use&#xa;</xsl:text>
        <xsl:text>%% We employ the shapely \ell to match Google Font version&#xa;</xsl:text>
        <xsl:text>%% pdflatex: "varqu" option produces best upright quotes&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: add StylisticSet 1 for shapely \ell&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: add StylisticSet 2 for plain zero&#xa;</xsl:text>
        <xsl:text>%% xelatex,lualatex: we add StylisticSet 3 for upright quotes&#xa;</xsl:text>
        <xsl:text>%% &#xa;</xsl:text>
        <xsl:text>\ifthenelse{\boolean{xetex} \or \boolean{luatex}}{%&#xa;</xsl:text>
        <xsl:text>%% begin: xelatex and lualatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>\usepackage{zi4}&#xa;</xsl:text>
        <!-- Filenames will locate versions installed in texmf tree? -->
        <!-- Documentation suggests setting stylistic sets via fontname, which implies system fonts? -->
        <xsl:text>\setmonofont[BoldFont=Inconsolatazi4-Bold.otf,StylisticSet={1,3}]{Inconsolatazi4-Regular.otf}&#xa;</xsl:text>
        <!-- <xsl:text>%% Mono spacing with \texttt, no extra space after period&#xa;</xsl:text> -->
        <!-- <xsl:text>\usepackage[mono,extrasp=0em]{zi4}&#xa;</xsl:text> -->
        <!-- TODO: put a xelatex/lualatex monospace font package hook here? -->
        <xsl:text>%% end: xelatex and lualatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>}{%&#xa;</xsl:text>
        <xsl:text>%% begin: pdflatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>%% "varqu" option provides textcomp \textquotedbl glyph&#xa;</xsl:text>
        <xsl:text>%% "varl"  option provides shapely "ell"&#xa;</xsl:text>
        <xsl:text>\usepackage[varqu,varl]{zi4}&#xa;</xsl:text>
        <!-- \@ifpackagelater: https://tex.stackexchange.com/questions/33806/is-it-possible-to-abort-loading-a-package-if-its-too-old -->
        <!-- <xsl:text>%% Mono spacing with \texttt, no extra space after period&#xa;</xsl:text> -->
        <!-- <xsl:text>\usepackage[mono,extrasp=0em]{zi4}&#xa;</xsl:text> -->
        <xsl:text>%% end: pdflatex-specific monospace font&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Symbols, align environment, bracket-matrix&#xa;</xsl:text>
    <xsl:text>\usepackage{amsmath}&#xa;</xsl:text>
    <xsl:text>\usepackage{amssymb}&#xa;</xsl:text>
    <xsl:text>%% allow page breaks within display mathematics anywhere&#xa;</xsl:text>
    <xsl:text>%% level 4 is maximally permissive&#xa;</xsl:text>
    <xsl:text>%% this is exactly the opposite of AMSmath package philosophy&#xa;</xsl:text>
    <xsl:text>%% there are per-display, and per-equation options to control this&#xa;</xsl:text>
    <xsl:text>%% split, aligned, gathered, and alignedat are not affected&#xa;</xsl:text>
    <xsl:text>\allowdisplaybreaks[4]&#xa;</xsl:text>
    <xsl:text>%% allow more columns to a matrix&#xa;</xsl:text>
    <xsl:text>%% can make this even bigger by overriding with  latex.preamble.late  processing option&#xa;</xsl:text>
    <xsl:text>\setcounter{MaxMatrixCols}{30}&#xa;</xsl:text>
    <xsl:if test="$b-has-sfrac">
        <xsl:text>%% xfrac package for 'beveled fractions': http://tex.stackexchange.com/questions/3372/how-do-i-typeset-arbitrary-fractions-like-the-standard-symbol-for-5-%C2%BD&#xa;</xsl:text>
        <xsl:text>\usepackage{xfrac}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:if test="$docinfo/covers">
        <xsl:text>%% pdfpages package for front and back covers as PDFs&#xa;</xsl:text>
        <xsl:text>\usepackage[</xsl:text>
        <xsl:choose>
            <xsl:when test="$latex.draft ='yes'">
                <xsl:text>draft</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>final</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>]{pdfpages}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Division Titles, and Page Headers/Footers&#xa;</xsl:text>
    <!-- The final mandatory argument of the titlesec \titleformat  -->
    <!-- command is the "before-code", meaning before the text of   -->
    <!-- the title.  For greater flexibility, the text of the title -->
    <!-- can be referenced *explicitly* by macro parameter #1 in    -->
    <!-- whatever code is placed into this argument.  This is       -->
    <!-- accomplished with the "explicit" argument.                 -->
    <!-- In particular, the numberless, chapter-level "Index" and   -->
    <!-- "Contents" are generated semi-automatically with a macro,  -->
    <!-- so PTX never sees the title (but can use built-in LaTeX    -->
    <!-- facilities to change it to another language)               -->
    <!-- "pagestyles" option is equivalent to loading the           -->
    <!-- "titleps" package and have it execute cooperatively        -->
    <xsl:text>%% titlesec package, loading "titleps" package cooperatively&#xa;</xsl:text>
    <xsl:text>%% See code comments about the necessity and purpose of "explicit" option.&#xa;</xsl:text>
    <xsl:text>%% The "newparttoc" option causes a consistent entry for parts in the ToC &#xa;</xsl:text>
    <xsl:text>%% file, but it is only effective if there is a \titleformat for \part.&#xa;</xsl:text>
    <xsl:text>%% "pagestyles" loads the  titleps  package cooperatively.&#xa;</xsl:text>
    <xsl:text>\usepackage[explicit, newparttoc, pagestyles]{titlesec}&#xa;</xsl:text>
    <xsl:text>%% The companion titletoc package for the ToC.&#xa;</xsl:text>
    <xsl:text>\usepackage{titletoc}&#xa;</xsl:text>
    <!-- Necessary fix for chapter/appendix transition              -->
    <!-- From titleps package author, 2013 post                     -->
    <!-- https://tex.stackexchange.com/questions/117222/            -->
    <!-- issue-with-titlesec-page-styles-and-appendix-in-book-class -->
    <!-- Maybe this is a problem for an "article" as well?  Hints:  -->
    <!-- https://tex.stackexchange.com/questions/319581/   issue-   -->
    <!-- with-titlesec-section-styles-and-appendix-in-article-class -->
    <xsl:if test="$b-is-book">
        <xsl:text>%% Fixes a bug with transition from chapters to appendices in a "book"&#xa;</xsl:text>
        <xsl:text>%% See generating XSL code for more details about necessity&#xa;</xsl:text>
        <xsl:text>\newtitlemark{\chaptertitlename}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% begin: customizations of page styles via the modal "titleps-style" template&#xa;</xsl:text>
    <xsl:text>%% Designed to use commands from the LaTeX "titleps" package&#xa;</xsl:text>
    <xsl:apply-templates select="$document-root" mode="titleps-style"/>
    <xsl:text>%% end: customizations of page styles via the modal "titleps-style" template&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%% Create globally-available macros to be provided for style writers&#xa;</xsl:text>
    <xsl:text>%% These are redefined for each occurence of each division&#xa;</xsl:text>
    <xsl:text>\newcommand{\divisionnameptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\titleptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\subtitleptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\shortitleptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\authorsptx}{\relax}%&#xa;</xsl:text>
    <xsl:text>\newcommand{\epigraphptx}{\relax}%&#xa;</xsl:text>
    <!-- Create xparse enviroments for each PTX division.          -->
    <!-- The pervasive environments need qualification so          -->
    <!-- that the right LaTeX divisions are created.               -->
    <!-- These look like environments like "solutions-subsection"  -->
    <!-- We want one (and only one) of each type that is necessary -->
    <!-- For each line below think CAREFULLY about the level       -->
    <!-- created, it is one level below what it might appear       -->
    <xsl:variable name="division-reps" select="
        ($document-root//acknowledgement)[1]|
        ($document-root//foreword)[1]|
        ($document-root//preface)[1]|
        ($document-root//part)[1]|
        ($document-root//chapter)[1]|
        ($document-root//section)[1]|
        ($document-root//subsection)[1]|
        ($document-root//subsubsection)[1]|
        ($document-root//subsubsection)[1]|
        ($root/book/backmatter/appendix|$root/article/backmatter/appendix)[1]|
        ($document-root//index)[1]|
        ($document-root//chapter/exercises|$root/book/backmatter/appendix/exercises|$root/article/exercises)[1]|
        ($document-root//section/exercises|$root/article/backmatter/appendix/exercises)[1]|
        ($document-root//subsection/exercises)[1]|
        ($document-root//subsubsection/exercises)[1]|
        ($root/book/backmatter/solutions)[1]|
        ($document-root//chapter/solutions|$root/article/solutions|$root/article/backmatter/solutions)[1]|
        ($document-root//section/solutions)[1]|
        ($document-root//subsection/solutions)[1]|
        ($document-root//subsubsection/solutions)[1]|
        ($document-root//chapter/worksheet|$root/article/worksheet)[1]|
        ($document-root//section/worksheet)[1]|
        ($document-root//subsection/worksheet)[1]|
        ($document-root//subsubsection/worksheet)[1]|
        ($document-root//chapter/reading-questions|$root/article/reading-questions)[1]|
        ($document-root//section/reading-questions)[1]|
        ($document-root//subsection/reading-questions)[1]|
        ($document-root//subsubsection/reading-questions)[1]|
        ($root/book/backmatter/glossary)[1]|
        ($document-root//chapter/glossary|$root/article/backmatter/glossary|$root/book/backmatter/appendix/glossary)[1]|
        ($document-root//section/glossary|$root/article/backmatter/appendix/glossary)[1]|
        ($document-root//subsection/glossary)[1]|
        ($document-root//subsubsection/glossary)[1]|
        ($root/book/backmatter/references)[1]|
        ($document-root//chapter/references|$root/article/references|$root/article/backmatter/references|$root/book/backmatter/appendix/references)[1]|
        ($document-root//section/references|$root/article/backmatter/appendix/references)[1]|
        ($document-root//subsection/references)[1]|
        ($document-root//subsubsection/references)[1]"/>
    <xsl:text>%% Create environments for possible occurences of each division&#xa;</xsl:text>
    <xsl:for-each select="$division-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Styles for six traditional LaTeX divisions&#xa;</xsl:text>
    <!-- Create six title styles, part to paragraph     -->
    <!-- NB: paragraph is like a "subsubsubsection"     -->
    <!-- "titlesec" works on a level basis, so          -->
    <!-- we just build all six named styles             -->
    <!-- N.B.: we are using the LaTeX "subparagraph"    -->
    <!-- traditional division for a PTX "paragraphs",   -->
    <!-- but perhaps we can fake that with a tcolorbox, -->
    <!-- since we don't allow it to be styled.          -->
    <xsl:call-template name="titlesec-part-style"/>
    <xsl:call-template name="titlesec-chapter-style"/>
    <xsl:call-template name="titlesec-section-style"/>
    <xsl:call-template name="titlesec-subsection-style"/>
    <xsl:call-template name="titlesec-subsubsection-style"/>
    <xsl:call-template name="titlesec-paragraph-style"/>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Styles for five traditional LaTeX divisions&#xa;</xsl:text>
    <!-- Create five title styles, part to subsubsection -->
    <xsl:call-template name="titletoc-part-style"/>
    <xsl:call-template name="titletoc-chapter-style"/>
    <xsl:call-template name="titletoc-section-style"/>
    <xsl:call-template name="titletoc-subsection-style"/>
    <xsl:call-template name="titletoc-subsubsection-style"/>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% Semantic Macros&#xa;</xsl:text>
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
    <xsl:if test="$document-root//insert or $document-root//delete or $document-root//stale">
        <xsl:text>%% Edits (insert, delete), stale (irrelevant, obsolete)&#xa;</xsl:text>
        <xsl:text>%% Package: underlines and strikethroughs, no change to \emph{}&#xa;</xsl:text>
        <xsl:text>\usepackage[normalem]{ulem}&#xa;</xsl:text>
        <xsl:text>%% Rules in this package reset proportional to fontsize&#xa;</xsl:text>
        <xsl:text>%% NB: *never* reset to package default (0.4pt?) after use&#xa;</xsl:text>
        <xsl:text>%% Macros will use colors if  latex.print='no'  (the default)&#xa;</xsl:text>
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
                <xsl:message terminate="yes">MBX:ERROR: invalid value <xsl:value-of select="$latex.fillin.style" /> for latex.fillin.style stringparam. Should be 'underline' or 'box'.</xsl:message>
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
        <xsl:for-each select="document('mathbook-units.xsl')//base[@siunitx]">
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
    <xsl:text>%% Division Numbering: Chapters, Sections, Subsections, etc&#xa;</xsl:text>
    <xsl:text>%% Division numbers may be turned off at some level ("depth")&#xa;</xsl:text>
    <xsl:text>%% A section *always* has depth 1, contrary to us counting from the document root&#xa;</xsl:text>
    <xsl:text>%% The latex default is 3.  If a larger number is present here, then&#xa;</xsl:text>
    <xsl:text>%% removing this command may make some cross-references ambiguous&#xa;</xsl:text>
    <xsl:text>%% The precursor variable $numbering-maxlevel is checked for consistency in the common XSL file&#xa;</xsl:text>
    <xsl:text>\setcounter{secnumdepth}{</xsl:text>
        <xsl:value-of select="$latex-numbering-maxlevel" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% AMS "proof" environment is no longer used, but we leave previously&#xa;</xsl:text>
    <xsl:text>%% implemented \qedhere in place, should the LaTeX be recycled&#xa;</xsl:text>
    <xsl:text>\newcommand{\qedhere}{\relax}&#xa;</xsl:text>
    <!--  -->
    <xsl:text>%%&#xa;</xsl:text>
    <xsl:text>%% A faux tcolorbox whose only purpose is to provide common numbering&#xa;</xsl:text>
    <xsl:text>%% facilities for most blocks (possibly not projects, 2D displays)&#xa;</xsl:text>
    <xsl:text>%% Controlled by  numbering.theorems.level  processing parameter&#xa;</xsl:text>
    <xsl:text>\newtcolorbox[auto counter</xsl:text>
    <!-- control the levels of the numbering -->
    <!-- global (no periods) is the default  -->
    <xsl:if test="not($numbering-theorems = 0)">
        <xsl:text>, number within=</xsl:text>
        <xsl:call-template name="level-to-name">
            <xsl:with-param name="level" select="$numbering-theorems" />
        </xsl:call-template>
    </xsl:if>
    <xsl:text>]{block}{}&#xa;</xsl:text>
    <!-- should condition on $project-reps, but it is not defined yet -->
    <xsl:if test="$b-number-project-distinct">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% This document is set to number PROJECT-LIKE on a separate numbering scheme&#xa;</xsl:text>
        <xsl:text>%% So, a faux tcolorbox whose only purpose is to provide this numbering&#xa;</xsl:text>
        <xsl:text>%% Controlled by  numbering.projects.level  processing parameter&#xa;</xsl:text>
        <xsl:text>\newtcolorbox[auto counter</xsl:text>
        <!-- control the levels of the numbering -->
        <!-- global (no periods) is the default  -->
        <xsl:if test="not($numbering-projects = 0)">
            <xsl:text>, number within=</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-projects" />
            </xsl:call-template>
        </xsl:if>
        <xsl:text>]{project-distinct}{}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-number-exercise-distinct">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% This document is set to number inline exercises on a separate numbering scheme&#xa;</xsl:text>
        <xsl:text>%% So, a faux tcolorbox whose only purpose is to provide this numbering&#xa;</xsl:text>
        <xsl:text>\newtcolorbox[auto counter</xsl:text>
        <!-- control the levels of the numbering -->
        <!-- global (no periods) is the default  -->
        <xsl:if test="not($numbering-exercises = 0)">
            <xsl:text>, number within=</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-exercises" />
            </xsl:call-template>
        </xsl:if>
        <xsl:text>]{exercise-distinct}{}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-number-figure-distinct">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% This document is set to number figure, table, list, listing on a separate numbering scheme&#xa;</xsl:text>
        <xsl:text>%% So, a faux tcolorbox whose only purpose is to provide this numbering&#xa;</xsl:text>
        <xsl:text>\newtcolorbox[auto counter</xsl:text>
        <!-- control the levels of the numbering -->
        <!-- global (no periods) is the default  -->
        <xsl:if test="not($numbering-exercises = 0)">
            <xsl:text>, number within=</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-figures" />
            </xsl:call-template>
        </xsl:if>
        <xsl:text>]{figure-distinct}{}&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO: condition of figure/*/figure-like, or $subfigure-reps -->
    <xsl:text>%% A faux tcolorbox whose only purpose is to provide common numbering&#xa;</xsl:text>
    <xsl:text>%% facilities for 2D displays which are subnumbered as part of a "sidebyside"&#xa;</xsl:text>
    <xsl:text>\newtcolorbox[auto counter</xsl:text>
    <!-- control the levels of the numbering -->
    <!-- global (no periods) is the default  -->
    <xsl:text>, number within=</xsl:text>
    <xsl:choose>
        <xsl:when test="$b-number-figure-distinct">
            <xsl:text>tcb@cnt@figure-distinct</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>tcb@cnt@block</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, number freestyle={\noexpand\thetcb@cnt@block(\noexpand\alph{\tcbcounter})}</xsl:text>
    <xsl:text>]{subdisplay}{}&#xa;</xsl:text>
    <!-- Groups of environments/blocks -->
    <!-- Variables hold exactly one node of each type in use -->
    <!-- "environment" template constructs...environments -->
    <!-- THEOREM-LIKE -->
    <xsl:variable name="theorem-reps" select="
        ($document-root//theorem)[1]|
        ($document-root//lemma)[1]|
        ($document-root//corollary)[1]|
        ($document-root//algorithm)[1]|
        ($document-root//proposition)[1]|
        ($document-root//claim)[1]|
        ($document-root//fact)[1]|
        ($document-root//identity)[1]"/>
    <xsl:if test="$theorem-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for THEOREM-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$theorem-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- AXIOM-LIKE -->
    <xsl:variable name="axiom-reps" select="
        ($document-root//axiom)[1]|
        ($document-root//conjecture)[1]|
        ($document-root//principle)[1]|
        ($document-root//heuristic)[1]|
        ($document-root//hypothesis)[1]|
        ($document-root//assumption)[1]"/>
    <xsl:if test="$axiom-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for AXIOM-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$axiom-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- DEFINITION-LIKE -->
    <xsl:variable name="definition-reps" select="
        ($document-root//definition)[1]"/>
    <xsl:if test="$definition-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for DEFINITION-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$definition-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- REMARK-LIKE -->
    <!-- NB: a "note" in "biblio" is a (harmless?) false positive here -->
    <xsl:variable name="remark-reps" select="
        ($document-root//remark)[1]|
        ($document-root//convention)[1]|
        ($document-root//note)[1]|
        ($document-root//observation)[1]|
        ($document-root//warning)[1]|
        ($document-root//insight)[1]"/>
    <xsl:if test="$remark-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for REMARK-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$remark-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- COMPUTATION-LIKE -->
    <xsl:variable name="computation-reps" select="
        ($document-root//computation)[1]|
        ($document-root//technology)[1]"/>
    <xsl:if test="$computation-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for COMPUTATION-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$computation-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- EXAMPLE-LIKE -->
    <xsl:variable name="example-reps" select="
        ($document-root//example)[1]|
        ($document-root//question)[1]|
        ($document-root//problem)[1]"/>
    <xsl:if test="$example-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for EXAMPLE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$example-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- Inline Exercises -->
    <xsl:variable name="inlineexercise-reps" select="
        ($document-root//exercise[boolean(&INLINE-EXERCISE-FILTER;)])[1]"/>
    <xsl:if test="$inlineexercise-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for inline exercises&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$inlineexercise-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- PROJECT-LIKE -->
    <!-- Used three times, search on $project-reps -->
    <xsl:variable name="project-reps" select="
        ($document-root//project)[1]|
        ($document-root//activity)[1]|
        ($document-root//exploration)[1]|
        ($document-root//investigation)[1]"/>
    <xsl:if test="$project-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for PROJECT-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$project-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- GOAL-LIKE -->
    <xsl:variable name="goal-reps" select="
        ($document-root//objectives)[1]|
        ($document-root//outcomes)[1]"/>
    <xsl:if test="$goal-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for GOAL-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$goal-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- ASIDE-LIKE -->
    <xsl:variable name="aside-reps" select="
        ($document-root//aside)[1]|
        ($document-root//historical)[1]|
        ($document-root//biographical)[1]"/>
    <xsl:if test="$aside-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for ASIDE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$aside-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- FIGURE-LIKE -->
    <!-- subcaptioned are separate -->
    <xsl:variable name="figure-reps" select="
        ($document-root//figure)[1]|
        ($document-root//table)[1]|
        ($document-root//listing)[1]|
        ($document-root//list)[1]"/>
    <xsl:if test="$figure-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for FIGURE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$figure-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- (SUB)FIGURE-LIKE -->
    <!-- subcaptioned versions, if contained by overall figure -->
    <xsl:variable name="subfigure-reps" select="
        ($document-root//figure/sidebyside/figure|$document-root//figure/sbsgroup/sidebyside/figure)[1]|
        ($document-root//figure/sidebyside/table|$document-root//figure/sbsgroup/sidebyside/table)[1]|
        ($document-root//figure/sidebyside/listing|$document-root//figure/sbsgroup/sidebyside/listing)[1]|
        ($document-root//figure/sidebyside/list|$document-root//figure/sbsgroup/sidebyside/list)[1]"/>
    <xsl:if test="$subfigure-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for (SUB)FIGURE-LIKE&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$subfigure-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- INTRODUCTION, CONCLUSION (divisional) -->
    <xsl:variable name="introduction-reps" select="
        ($root/article/introduction|$document-root//chapter/introduction|$document-root//section/introduction|$document-root//subsection/introduction|$document-root//appendix/introduction|$document-root//exercises/introduction|$document-root//solutions/introduction|$document-root//worksheet/introduction|$document-root//reading-questions/introduction|$document-root//glossary/introduction|$document-root//references/introduction)[1]|
        ($root/article/conclusion|$document-root//chapter/conclusion|$document-root//section/conclusion|$document-root//subsection/conclusion|$document-root//appendix/conclusion|$document-root//exercises/conclusion|$document-root//solutions/conclusion|$document-root//worksheet/conclusion|$document-root//reading-questions/conclusion|$document-root//glossary/conclusion|$document-root//references/conclusion)[1]"/>
    <xsl:if test="$introduction-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% xparse environments for introductions and conclusions of divisions&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$introduction-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- MISCELLANEOUS -->
    <!-- "paragraphs" are partly like a division, -->
    <!-- but we include it here as a one-off      -->
    <xsl:variable name="miscellaneous-reps" select="
        ($document-root//defined-term)[1]|
        ($document-root//proof)[1]|
        ($document-root//case)[1]|
        ($document-root//assemblage)[1]|
        ($document-root//backmatter/colophon)[1]|
        ($document-root//paragraphs)[1]"/>
    <xsl:if test="$miscellaneous-reps">
        <xsl:text>%%&#xa;</xsl:text>
        <xsl:text>%% tcolorbox, with styles, for miscellaneous environments&#xa;</xsl:text>
        <xsl:text>%%&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$miscellaneous-reps">
        <xsl:apply-templates select="." mode="environment"/>
    </xsl:for-each>
    <!-- Commentary -->
    <!-- "commentary" is elective, with global switch set at startup -->
    <xsl:if test="$b-commentary">
        <xsl:variable name="instance" select="($document-root//commentary)[1]"/>
        <xsl:if test="$instance">
            <xsl:text>%%&#xa;</xsl:text>
            <xsl:text>%% tcolorbox, with style, for elected commentary&#xa;</xsl:text>
            <xsl:text>%%&#xa;</xsl:text>
            <xsl:apply-templates select="$instance" mode="environment"/>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//solutions or $b-needs-solution-styles">
        <xsl:text>%% begin: environments for duplicates in solutions divisions&#xa;</xsl:text>
        <!-- Solutions present, check for exercise types     -->
        <!-- This may have false positives, but no real harm -->
        <!--  -->
        <!-- solutions to inline exercises -->
        <xsl:if test="$document-root//exercise[boolean(&INLINE-EXERCISE-FILTER;)]">
        <xsl:text>%% Solutions to inline exercises, style and environment&#xa;</xsl:text>
            <xsl:text>\tcbset{ inlineexercisesolutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, parbox=false } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{inlineexercisesolution}[3]</xsl:text>
            <xsl:text>{inlineexercisesolutionstyle, title={\hyperref[#3]{</xsl:text>
            <!-- Hardcode "name" of an inline exercise in the environment -->
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'inlineexercise'" />
            </xsl:call-template>
            <xsl:text>~#1}\notblank{#2}{\space#2}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution -->
        <!-- Explicitly breakable, run-in title -->
        <xsl:if test="$document-root//exercises//exercise[not(ancestor::exercisegroup)]|$document-root//worksheet//exercise[not(ancestor::exercisegroup)]|$document-root//reading-questions//exercise[not(ancestor::exercisegroup)]">
            <xsl:text>%% Solutions to division exercises, not in exercise group&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, parbox=false } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolution}[3]</xsl:text>
            <xsl:text>{divisionsolutionstyle, title={\hyperlink{#3}{#1}.\notblank{#2}{\space#2}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution, Exercise Group -->
        <!-- Explicitly breakable, run-in title -->
        <xsl:if test="$document-root//exercisegroup[not(@cols)]">
            <xsl:text>%% Solutions to division exercises, in exercise group, no columns&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionegstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, left skip=\egindent, breakable, parbox=false } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolutioneg}[3]</xsl:text>
            <xsl:text>{divisionsolutionegstyle, title={\hyperlink{#3}{#1}.\notblank{#2}{\space#2}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- Division Solution, Exercise Group, Columnar -->
        <!-- Explicity unbreakable, to behave in multicolumn tcbraster -->
        <xsl:if test="$document-root//exercisegroup/@cols">
            <xsl:text>%% Solutions to division exercises, in exercise group with columns&#xa;</xsl:text>
            <xsl:text>\tcbset{ divisionsolutionegcolstyle/.style={bwminimalstyle, runintitlestyle,  exercisespacingstyle, after title={\space}, halign=flush left, unbreakable, parbox=false } }&#xa;</xsl:text>
            <xsl:text>\newtcolorbox{divisionsolutionegcol}[3]</xsl:text>
            <xsl:text>{divisionsolutionegcolstyle, title={\hyperlink{#3}{#1}.\notblank{#2}{\space#2}{}}}&#xa;</xsl:text>
        </xsl:if>
        <!-- solutions to PROJECT-LIKE -->
        <xsl:for-each select="$project-reps">
            <xsl:variable name="elt-name">
                <xsl:value-of select="local-name(.)"/>
            </xsl:variable>
            <xsl:variable name="type-name">
                <xsl:apply-templates select="." mode="type-name"/>
            </xsl:variable>
            <!-- set the style -->
            <xsl:text>\tcbset{ </xsl:text>
            <xsl:value-of select="$elt-name"/>
            <xsl:text>solutionstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, after title={\space}, breakable, parbox=false } }&#xa;</xsl:text>
            <!-- create the environment -->
            <xsl:text>\newtcolorbox{</xsl:text>
            <xsl:value-of select="$elt-name"/>
            <xsl:text>solution}[3]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$elt-name"/>
            <xsl:text>solutionstyle, title={\hyperref[#3]{</xsl:text>
            <!-- Hardcode "name" of "project" in the environment -->
            <xsl:value-of select="$type-name"/>
            <xsl:text>~#1}\notblank{#2}{\space#2}{}}}&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:if>
    <!-- Generic exercise lead-in -->
    <xsl:if test="$document-root//exercises//exercise|$document-root//worksheet//exercise|$document-root//reading-questions//exercise">
        <xsl:text>%% Divisional exercises (and worksheet) as LaTeX environments&#xa;</xsl:text>
        <xsl:text>%% Third argument is option for extra workspace in worksheets&#xa;</xsl:text>
        <xsl:text>%% Hanging indent occupies a 5ex width slot prior to left margin&#xa;</xsl:text>
        <xsl:text>%% Experimentally this seems just barely sufficient for a bold "888."&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise -->
    <!-- Numbered, styled with a hanging indent -->
    <xsl:if test="$document-root//exercises//exercise[not(ancestor::exercisegroup)]|$document-root//worksheet//exercise[not(ancestor::exercisegroup)]|$document-root//reading-questions//exercise[not(ancestor::exercisegroup)]">
        <xsl:text>%% Division exercises, not in exercise group&#xa;</xsl:text>
        <xsl:text>\tcbset{ divisionexercisestyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, breakable, parbox=false } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexercise}[4]</xsl:text>
        <xsl:text>{divisionexercisestyle, before title={\hspace{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after={\notblank{#3}{\newline\rule{\workspacestrutwidth}{#3\textheight}\newline}{}}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise, Exercise Group -->
    <!-- The exercise itself carries the indentation, hence we can use breakable -->
    <!-- boxes and get good page breaks (as these problems could be long)        -->
    <xsl:if test="$document-root//exercisegroup[not(@cols)]">
        <xsl:text>%% Division exercises, in exercise group, no columns&#xa;</xsl:text>
        <xsl:text>\tcbset{ divisionexerciseegstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, left skip=\egindent, breakable, parbox=false } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexerciseeg}[4]</xsl:text>
        <xsl:text>{divisionexerciseegstyle, before title={\hspace{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after={\notblank{#3}{\newline\rule{\workspacestrutwidth}{#3\textheight}\newline}{}}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Division Exercise, Exercise Group, Columnar -->
    <!-- Explicity unbreakable, to behave in multicolumn tcbraster -->
    <xsl:if test="$document-root//exercisegroup/@cols">
        <xsl:text>%% Division exercises, in exercise group with columns&#xa;</xsl:text>
        <xsl:text>\tcbset{ divisionexerciseegcolstyle/.style={bwminimalstyle, runintitlestyle, exercisespacingstyle, left=5ex, halign=flush left, unbreakable, parbox=false } }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{divisionexerciseegcol}[4]</xsl:text>
        <xsl:text>{divisionexerciseegcolstyle, before title={\hspace{-5ex}\makebox[5ex][l]{#1.}}, title={\notblank{#2}{#2\space}{}}, phantom={</xsl:text>
        <xsl:if test="$b-pageref">
            <xsl:text>\label{#4}</xsl:text>
        </xsl:if>
        <xsl:text>\hypertarget{#4}{}}, after={\notblank{#3}{\newline\rule{\workspacestrutwidth}{#3\textheight}\newline}{}}}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//exercise[@workspace]">
        <xsl:text>%% Worksheet exercises may have workspaces&#xa;</xsl:text>
        <xsl:text>\newlength{\workspacestrutwidth}&#xa;</xsl:text>
        <xsl:choose>
            <xsl:when test="$latex.draft ='yes'">
                <xsl:text>%% LaTeX draft mode, @workspace strut is visible&#xa;</xsl:text>
                <xsl:text>\setlength{\workspacestrutwidth}{2pt}&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>%% @workspace strut is invisible&#xa;</xsl:text>
                <xsl:text>\setlength{\workspacestrutwidth}{0pt}&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Localize various standard names in use         -->
    <!-- Many environments addressed upon creation above -->
    <!-- Index, table of contents done elsewhere        -->
    <!-- http://www.tex.ac.uk/FAQ-fixnam.html           -->
    <!-- http://tex.stackexchange.com/questions/62020/how-to-change-the-word-proof-in-the-proof-environment -->
    <xsl:text>%% Localize LaTeX supplied names (possibly none)&#xa;</xsl:text>
    <xsl:if test="//appendix">
        <xsl:text>\renewcommand*{\appendixname}{</xsl:text>
        <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'appendix'" /></xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$root/book">
        <xsl:if test="$document-root//part">
            <xsl:text>\renewcommand*{\partname}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'part'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//chapter">
            <xsl:text>\renewcommand*{\chaptername}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'chapter'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <!-- This code is correct, interface is temporary and will be redone with no notice -->
            <xsl:if test="not($debug.chapter.start = '')">
                <xsl:text>\setcounter{chapter}{</xsl:text>
                <xsl:value-of select="$debug.chapter.start - 1" />
                <xsl:text>}&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$root/article">
        <xsl:if test="//abstract">
            <xsl:text>\renewcommand*{\abstractname}{</xsl:text>
            <xsl:call-template name="type-name"><xsl:with-param name="string-id" select="'abstract'" /></xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- Numbering Equations -->
    <!-- See numbering-equations variable being set in mathbook-common.xsl         -->
    <!-- With number="yes|no" on mrow, we must allow for the possibility of an md  -->
    <!-- variant having numbers (we could be more careful, but it is not critical) -->
    <!-- NB: global numbering is level 0 and "level-to-name" is (a) incorrect,     -->
    <!-- and (b) not useful (\numberwithin will fail)                              -->
    <!-- NB: perhaps the chngcntr package should/could be used here                -->
    <xsl:if test="//men|//mdn|//md">
        <xsl:text>%% Equation Numbering&#xa;</xsl:text>
        <xsl:text>%% Controlled by  numbering.equations.level  processing parameter&#xa;</xsl:text>
        <xsl:text>%% No adjustment here implies document-wide numbering&#xa;</xsl:text>
        <xsl:if test="not($numbering-equations = 0)">
            <xsl:text>\numberwithin{equation}{</xsl:text>
            <xsl:call-template name="level-to-name">
                <xsl:with-param name="level" select="$numbering-equations" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//image">
        <xsl:text>%% "tcolorbox" environment for a single image, occupying entire \linewidth&#xa;</xsl:text>
        <xsl:text>%% arguments are left-margin, width, right-margin, as multiples of&#xa;</xsl:text>
        <xsl:text>%% \linewidth, and are guaranteed to be positive and sum to 1.0&#xa;</xsl:text>
        <xsl:text>\tcbset{ imagestyle/.style={bwminimalstyle} }&#xa;</xsl:text>
        <xsl:text>\NewTColorBox{image}{mmm}{imagestyle,left skip=#1\linewidth,width=#2\linewidth}&#xa;</xsl:text>
    </xsl:if>
    <!-- Tables -->
    <xsl:if test="//tabular">
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
    <!-- Numbering Footnotes -->
    <xsl:if test="$document-root//fn">
        <xsl:text>%% Footnote Numbering&#xa;</xsl:text>
        <xsl:text>%% Specified by numbering.footnotes.level&#xa;</xsl:text>
        <xsl:if test="$b-is-book">
            <xsl:text>%% Undo counter reset by chapter for a book&#xa;</xsl:text>
            <xsl:text>\counterwithout{footnote}{chapter}&#xa;</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$numbering-footnotes = 0">
                <xsl:text>%% Global numbering, since numbering.footnotes.level = 0&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\counterwithin*{footnote}{</xsl:text>
                <xsl:call-template name="level-to-name">
                    <xsl:with-param name="level" select="$numbering-footnotes" />
                </xsl:call-template>
                <xsl:text>}&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Interactives -->
    <xsl:if test="$document-root//audio|$document-root//video|$document-root//interactive">
        <xsl:text>%% QR Code Support&#xa;</xsl:text>
        <xsl:text>%% Videos and other interactives&#xa;</xsl:text>
        <xsl:text>\usepackage{qrcode}&#xa;</xsl:text>
        <xsl:text>\newlength{\qrsize}&#xa;</xsl:text>
        <xsl:text>\newlength{\previewwidth}&#xa;</xsl:text>
        <xsl:text>%% tcolorbox styles for interactive previews&#xa;</xsl:text>
        <xsl:text>%% changing size= and/or colback can aid in debugging&#xa;</xsl:text>
        <xsl:text>\tcbset{ previewstyle/.style={bwminimalstyle, halign=center} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ qrstyle/.style={bwminimalstyle, hbox} }&#xa;</xsl:text>
        <xsl:text>\tcbset{ captionstyle/.style={bwminimalstyle, left=1em, width=\linewidth} }&#xa;</xsl:text>
        <!-- Page: https://commons.wikimedia.org/wiki/File:YouTube_Play_Button.svg             -->
        <!-- File: https://upload.wikimedia.org/wikipedia/commons/d/d1/YouTube_Play_Button.svg -->
        <!-- License text:  This image only consists of simple geometric shapes or text.       -->
        <!-- It does not meet the threshold of originality needed for copyright protection,    -->
        <!-- and is therefore in the public domain.                                            -->
        <!-- Converted from HTML's SVG into tikZ code via  github.com/kjellmf/svg2tikz.git     -->
        <xsl:text>%% Generic red play button (from SVG)&#xa;</xsl:text>
        <xsl:text>%% tikz package should be loaded by now&#xa;</xsl:text>
        <xsl:text>\definecolor{playred}{RGB}{230,33,23}&#xa;</xsl:text>
        <xsl:text>\newcommand{\genericpreview}{
        \begin{tikzpicture}[y=0.80pt, x=0.80pt, yscale=-1.000000, xscale=1.000000, inner sep=0pt, outer sep=0pt]
        \path[fill=playred] (94.9800,28.8400) .. controls (94.9800,28.8400) and
        (94.0400,22.2400) .. (91.1700,19.3400) .. controls (87.5300,15.5300) and
        (83.4500,15.5100) .. (81.5800,15.2900) .. controls (68.1800,14.3200) and
        (48.0600,14.4400) .. (48.0600,14.4400) .. controls (48.0600,14.4400) and
        (27.9400,14.3200) .. (14.5400,15.2900) .. controls (12.6700,15.5100) and
        (8.5900,15.5300) .. (4.9500,19.3400) .. controls (2.0800,22.2400) and
        (1.1400,28.8400) .. (1.1400,28.8400) .. controls (1.1400,28.8400) and
        (0.1800,36.5800) .. (0.0000,44.3300) -- (0.0000,51.5900) .. controls
        (0.1800,59.3400) and (1.1400,67.0800) .. (1.1400,67.0800) .. controls
        (1.1400,67.0800) and (2.0700,73.6800) .. (4.9500,76.5800) .. controls
        (8.5900,80.3900) and (13.3800,80.2700) .. (15.5100,80.6700) .. controls
        (23.0400,81.3900) and (47.2100,81.5600) .. (48.0500,81.5700) .. controls
        (48.0600,81.5700) and (68.1900,81.6000) .. (81.5900,80.6300) .. controls
        (83.4600,80.4100) and (87.5400,80.3900) .. (91.1800,76.5800) .. controls
        (94.0500,73.6800) and (94.9900,67.0800) .. (94.9900,67.0800) .. controls
        (94.9900,67.0800) and (95.9500,59.3300) .. (96.0100,51.5900) --
        (96.0100,44.3300) .. controls (95.9400,36.5800) and (94.9800,28.8400) ..
        (94.9800,28.8400) -- cycle(38.2800,61.4100) -- (38.2800,34.4100) --
        (64.0200,47.9100) -- (38.2800,61.4100) -- cycle;
        \end{tikzpicture}
        }&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$b-has-icon">
        <xsl:text>%% Font Awesome icons in a LaTeX package&#xa;</xsl:text>
        <xsl:text>\usepackage{fontawesome}&#xa;</xsl:text>
    </xsl:if>
    <!-- Poetry -->
    <xsl:if test="//poem">
        <xsl:text>%% Poetry Support&#xa;</xsl:text>
        <xsl:text>\newenvironment{poem}{\setlength{\parindent}{0em}}{}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemTitle}[1]{\begin{center}\large\textbf{#1}\end{center}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemIndent}{\hspace{2 em}}&#xa;</xsl:text>
        <xsl:text>\newenvironment{stanza}{\vspace{0.25 em}\hangindent=4em}{\vspace{1 em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\stanzaTitle}[1]{{\centering\textbf{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemauthorleft}[1]{\vspace{-1em}\begin{flushleft}\textit{#1}\end{flushleft}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemauthorcenter}[1]{\vspace{-1em}\begin{center}\textit{#1}\end{center}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemauthorright}[1]{\vspace{-1em}\begin{flushright}\textit{#1}\end{flushright}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemlineleft}[1]{{\raggedright{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemlinecenter}[1]{{\centering{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\poemlineright}[1]{{\raggedleft{#1}\par}\vspace{-\parskip}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Music -->
    <xsl:if test="$document-root//flat | $document-root//doubleflat | $document-root//sharp | $document-root//doublesharp | $document-root//natural | $document-root//n | $document-root//scaledeg | $document-root//chord">
        <xsl:text>%% Musical Symbol Support&#xa;</xsl:text>
        <xsl:text>\ifthenelse{\boolean{xetex}}{&#xa;</xsl:text>
        <xsl:text>%% begin: xelatex-specific configuration&#xa;</xsl:text>
        <xsl:text>%% lilyglyphs.sty in Ubuntu/Debian texlive-music&#xa;</xsl:text>
        <xsl:text>\usepackage{lilyglyphs}&#xa;</xsl:text>
        <xsl:text>\lilyGlobalOptions{scale=0.8}&#xa;</xsl:text>
        <!-- Create alias to lilyglyphs command with common name -->
        <xsl:text>\newcommand*{\doubleflat}{\flatflat}&#xa;</xsl:text>
        <xsl:text>%% end: xelatex-specific configuration&#xa;</xsl:text>
        <xsl:text>}{&#xa;</xsl:text>
        <xsl:text>%% begin: pdflatex-specific configuration&#xa;</xsl:text>
        <!-- Pulling accidentals from "musixtex" font -->
        <!-- http://tex.stackexchange.com/questions/207261/how-do-i-produce-a-double-flat-symbol-edit -->
        <xsl:text>\DeclareFontFamily{U}{musix}{}%&#xa;</xsl:text>
        <xsl:text>\DeclareFontShape{U}{musix}{m}{n}{%&#xa;</xsl:text>
        <xsl:text>&lt;-12&gt;   musix11&#xa;</xsl:text>
        <xsl:text>&lt;12-15&gt; musix13&#xa;</xsl:text>
        <xsl:text>&lt;15-18&gt; musix16&#xa;</xsl:text>
        <xsl:text>&lt;18-23&gt; musix20&#xa;</xsl:text>
        <xsl:text>&lt;23-&gt;   musix29&#xa;</xsl:text>
        <xsl:text>}{}%&#xa;</xsl:text>
        <xsl:text>%% We grab all five accidentals from the musix font so they are usable in both math and text mode&#xa;</xsl:text>
        <xsl:text>\renewcommand*\flat{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{2}}}&#xa;</xsl:text>
        <xsl:text>\newcommand*\doubleflat{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{3}}}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\sharp{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{4}}}&#xa;</xsl:text>
        <xsl:text>\newcommand*\doublesharp{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{5}}}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\natural{\raisebox{0.5ex}{\usefont{U}{musix}{m}{n}\selectfont{6}}}&#xa;</xsl:text>
        <xsl:text>%% end: pdflatex-specific configuration&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <!-- Inconsolata font, sponsored by TUG: http://levien.com/type/myfonts/inconsolata.html            -->
    <!-- As seen on: http://tex.stackexchange.com/questions/50810/good-monospace-font-for-code-in-latex -->
    <!-- "Fonts for Displaying Program Code in LaTeX":  http://nepsweb.co.uk/docs%/progfonts.pdf        -->
    <!-- Fonts and xelatex:  http://tex.stackexchange.com/questions/102525/use-type-1-fonts-with-xelatex -->
    <!--   http://tex.stackexchange.com/questions/179448/beramono-in-xetex -->
    <!-- http://tex.stackexchange.com/questions/25249/how-do-i-use-a-particular-font-for-a-small-section-of-text-in-my-document -->
    <!-- Bitstream Vera Font names within: https://github.com/timfel/texmf/blob/master/fonts/map/vtex/bera.ali -->
    <!-- Coloring listings: http://tex.stackexchange.com/questions/18376/beautiful-listing-for-csharp -->
    <!-- Song and Dance for font changes: http://jevopi.blogspot.com/2010/03/nicely-formatted-listings-in-latex-with.html -->
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
            <xsl:text>colback=white, sharp corners, boxrule=-0.3pt, leftrule=0.5pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt,&#xa;</xsl:text>
            <xsl:text>breakable, parbox=false,&#xa;</xsl:text>
            <xsl:text>} }&#xa;</xsl:text>
            <!--  -->
            <xsl:text>\newtcblisting{program}[1]{programboxstyle, listing options={language=#1, style=programcodestyle}}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//console">
            <xsl:text>%% Console session with prompt, input, output&#xa;</xsl:text>
            <xsl:text>%% listings allows for escape sequences to enable LateX,&#xa;</xsl:text>
            <xsl:text>%% so we bold the input commands via teh following macro&#xa;</xsl:text>
            <xsl:text>\newcommand{\consoleinput}[1]{\textbf{#1}}&#xa;</xsl:text>
            <!-- https://tex.stackexchange.com/questions/299401/bold-just-one-line-inside-of-lstlisting/299406 -->
            <!-- Syntax highlighting is not so great for "language=bash" -->
            <!-- Line-breaking off to match old behavior, prebreak option fails inside LaTeX for input -->
            <xsl:text>\lstdefinestyle{consolecodestyle}{language=none, escapeinside={(*}{*)}, identifierstyle=, commentstyle=, stringstyle=, keywordstyle=, breaklines=false, breakatwhitespace=false, columns=fixed, extendedchars=true, aboveskip=0pt, belowskip=0pt}&#xa;</xsl:text>
            <!--  -->
            <xsl:text>\tcbset{ consoleboxstyle/.style={left=0pt, right=0pt, top=0ex, bottom=0ex, middle=0pt, toptitle=0pt, bottomtitle=0pt, boxsep=0pt,&#xa;</xsl:text>
            <xsl:text>listing only, fontupper=\small\ttfamily,&#xa;</xsl:text>
            <xsl:text>colback=white, boxrule=-0.3pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt,&#xa;</xsl:text>
            <xsl:text>breakable, parbox=false,&#xa;</xsl:text>
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
            <xsl:text>breakable, parbox=false, &#xa;</xsl:text>
            <xsl:text>listing options={language=Python,breaklines=true,breakatwhitespace=true, extendedchars=true, aboveskip=0pt, belowskip=0pt}} }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageinput}{sagestyle, colback=sageblue, sharp corners, boxrule=0.5pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt, }&#xa;</xsl:text>
            <xsl:text>\newtcblisting{sageoutput}{sagestyle, colback=white, colframe=white, frame empty, before skip=0pt, after skip=0pt, }&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//pre or $document-root//cd or $document-root//fragment">
        <xsl:text>%% Fancy Verbatim for consoles, preformatted, code display, literate programming&#xa;</xsl:text>
        <xsl:text>\usepackage{fancyvrb}&#xa;</xsl:text>
        <xsl:if test="//pre">
            <xsl:text>%% Pre-formatted text, a peer of paragraphs&#xa;</xsl:text>
            <xsl:text>\DefineVerbatimEnvironment{preformatted}{Verbatim}{}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//cd">
            <xsl:text>%% code display (cd), by analogy with math display (md)&#xa;</xsl:text>
            <xsl:text>%% savebox, lrbox, etc to achieve centering&#xa;</xsl:text>
            <!-- https://tex.stackexchange.com/questions/182476/how-do-i-center-a-boxed-verbatim -->
            <!-- trying "\centering" here was a disaster -->
            <xsl:text>\newsavebox{\codedisplaybox}&#xa;</xsl:text>
            <xsl:text>\newenvironment{codedisplay}&#xa;</xsl:text>
            <xsl:text>{\VerbatimEnvironment\begin{center}\begin{lrbox}{\codedisplaybox}\begin{BVerbatim}}&#xa;</xsl:text>
            <xsl:text>{\end{BVerbatim}\end{lrbox}\usebox{\codedisplaybox}\end{center}}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//tikz">
        <xsl:message>MBX:WARNING: the "tikz" element is deprecated (2015-10-16), use "latex-image-code" tag inside an "image" tag, and include the tikz package and relevant libraries in docinfo/latex-image-preamble</xsl:message>
        <xsl:text>%% Tikz graphics&#xa;</xsl:text>
        <xsl:text>\usepackage{tikz}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{backgrounds}&#xa;</xsl:text>
        <xsl:text>\usetikzlibrary{arrows,matrix}&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO:  \showidx package as part of a draft mode, prints entries in margin -->
     <xsl:if test="$document-root//ol[@cols] or $document-root//ul[@cols] or $document-root//dl[@cols] or $document-root//contributors">
        <xsl:text>%% Multiple column, column-major lists&#xa;</xsl:text>
        <xsl:text>\usepackage{multicol}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//ol or $document-root//ul or $document-root//dl or $document-root//task or $document-root//references or $b-has-webwork-reps">
        <xsl:text>%% More flexible list management, esp. for references&#xa;</xsl:text>
        <xsl:text>%% But also for specifying labels (i.e. custom order) on nested lists&#xa;</xsl:text>
        <xsl:text>\usepackage</xsl:text>
        <xsl:if test="$b-has-webwork-reps">
            <xsl:if test="//webwork-reps/static//statement//var[@form='checkboxes' or @form='popup']">
                <xsl:text>[inline]</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:text>{enumitem}&#xa;</xsl:text>
        <xsl:if test="$document-root//references">
            <xsl:text>%% Lists of references in their own section, maximum depth 1&#xa;</xsl:text>
            <xsl:text>\newlist{referencelist}{description}{4}&#xa;</xsl:text>
            <!-- labelindent defaults to 0, ! means computed -->
            <xsl:text>\setlist[referencelist]{leftmargin=!,labelwidth=!,labelsep=0ex,itemsep=1.0ex,topsep=1.0ex,partopsep=0pt,parsep=0pt}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root//exercisegroup">
        <xsl:text>%% Indented groups of "exercise" within an "exercises" division&#xa;</xsl:text>
        <xsl:text>%% Lengths control the indentation (always) and gaps (multi-column)&#xa;</xsl:text>
        <xsl:text>\newlength{\egindent}\setlength{\egindent}{0.05\linewidth}&#xa;</xsl:text>
        <xsl:text>\newlength{\exggap}\setlength{\exggap}{0.05\linewidth}&#xa;</xsl:text>
        <xsl:if test="$document-root//exercisegroup[not(@cols)]">
            <xsl:text>%% Thin "xparse" environments will represent the entire exercise&#xa;</xsl:text>
            <xsl:text>%% group, in the case when it does not hold multiple columns.&#xa;</xsl:text>
            <!-- DO NOT make this a tcolorbox, since we would want it -->
            <!-- to be breakable, and then the individual exercises   -->
            <!-- could not be breakable tcolorbox themselves          -->
            <!-- TODO: add some pre- spacing commands here -->
            <xsl:text>\NewDocumentEnvironment{exercisegroup}{}&#xa;</xsl:text>
            <xsl:text>{}{}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$document-root//exercisegroup/@cols">
            <xsl:text>%% An exercise group with multiple columns is a tcbraster.&#xa;</xsl:text>
            <xsl:text>%% If the contained exercises are explicitly unbreakable,&#xa;</xsl:text>
            <xsl:text>%% the raster should break at rows for page breaks.&#xa;</xsl:text>
            <xsl:text>%% The number of columns is a parameter, passed to tcbraster.&#xa;</xsl:text>
            <!-- raster equal height: boxes of same *row* have same height    -->
            <!-- raster left skip: indentation of all exercises               -->
            <!-- raster columns: controls layout, so no line separators, etc. -->
            <xsl:text>\tcbset{ exgroupcolstyle/.style={raster equal height=rows, raster left skip=\egindent, raster column skip=\exggap} }&#xa;</xsl:text>
            <xsl:text>\NewDocumentEnvironment{exercisegroupcol}{m}&#xa;</xsl:text>
            <xsl:text>{\begin{tcbraster}[exgroupcolstyle,raster columns=#1]}{\end{tcbraster}}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="$document-root/backmatter/index-part | $document-root//index-list">
        <!-- See http://tex.blogoverflow.com/2012/09/dont-forget-to-run-makeindex/ for "imakeidx" usage -->
        <xsl:text>%% Support for index creation&#xa;</xsl:text>
        <xsl:if test="$author-tools-new = 'no'">
            <xsl:text>%% imakeidx package does not require extra pass (as with makeidx)&#xa;</xsl:text>
            <xsl:text>%% Title of the "Index" section set via a keyword&#xa;</xsl:text>
            <xsl:text>%% Language support for the "see" and "see also" phrases&#xa;</xsl:text>
            <xsl:text>\usepackage{imakeidx}&#xa;</xsl:text>
            <xsl:text>\makeindex[title=</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'index'" />
            </xsl:call-template>
            <xsl:text>, intoc=true]&#xa;</xsl:text>
            <xsl:text>\renewcommand{\seename}{</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'see'" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>\renewcommand{\alsoname}{</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'also'" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$author-tools-new = 'yes'">
            <xsl:text>%% author-tools = 'yes' activates marginal notes about index&#xa;</xsl:text>
            <xsl:text>%% and supresses the actual creation of the index itself&#xa;</xsl:text>
            <xsl:text>\usepackage{showidx}&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
    <xsl:if test="//docinfo/logo">
        <xsl:text>%% Package for precise image placement (for logos on pages)&#xa;</xsl:text>
        <xsl:text>\usepackage{eso-pic}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="//notation or //list-of">
        <xsl:text>%% Package for tables spanning several pages&#xa;</xsl:text>
        <xsl:text>\usepackage{longtable}&#xa;</xsl:text>
    </xsl:if>
    <!-- This is the place to add part numbers to the numbering, which   -->
    <!-- is *not* the default LaTeX behavior.  The \p@section scheme     -->
    <!-- is complicated, leading to about ten constructions like         -->
    <!--                                                                 -->
    <!-- \ifdefined\p@namedlist\renewcommand{\p@namedlist}{\thepart.}\fi -->
    <!--                                                                 -->
    <!-- Advice is to redefine these *before* loading hyperref           -->
    <!-- https://tex.stackexchange.com/questions/172962                  -->
    <!-- (hyperref-include-part-number-for-cross-references-to-chapters) -->
    <!-- Easier is to just adjust the chapter number, which filters down -->
    <!-- into anything that uses the chapter, though perhaps per-part    -->
    <!-- numbering will still need something?                            -->
    <!--                                                                 -->
    <!-- \renewcommand{\thechapter}{\thepart.\arabic{chapter}}           -->
    <!--                                                                 -->
    <!-- http://tex.stackexchange.com/questions/106159/why-i-shouldnt-load-pdftex-option-with-hyperref -->
    <xsl:text>%% hyperref driver does not need to be specified, it will be detected&#xa;</xsl:text>
    <xsl:text>%% Footnote marks in tcolorbox have broken linking under&#xa;</xsl:text>
    <xsl:text>%% hyperref, so it is necessary to turn off all linking&#xa;</xsl:text>
    <xsl:text>%% It *must* be given as a package option, not with \hypersetup&#xa;</xsl:text>
    <xsl:text>\usepackage[hyperfootnotes=false]{hyperref}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/79051/how-to-style-text-in-hyperref-url -->
    <xsl:if test="//url">
    <xsl:text>%% configure hyperref's  \url  to match listings' inline verbatim&#xa;</xsl:text>
        <xsl:text>\renewcommand\UrlFont{\small\ttfamily}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex.print='no'">
        <xsl:text>%% Hyperlinking active in electronic PDFs, all links solid and blue&#xa;</xsl:text>
        <xsl:text>\hypersetup{hidelinks=false,colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$latex.print='yes'">
        <xsl:text>%% latex.print parameter set to 'yes', all hyperlinks "hidden", set to textcolor (but still active to preserve spacing)&#xa;</xsl:text>
        <xsl:text>\hypersetup{hidelinks=true,colorlinks=true,linkcolor=blue,citecolor=blue,filecolor=blue,urlcolor=blue}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\hypersetup{pdftitle={</xsl:text>
    <xsl:apply-templates select="." mode="title-short" />
    <xsl:text>}}&#xa;</xsl:text>
    <!-- http://tex.stackexchange.com/questions/44088/when-do-i-need-to-invoke-phantomsection -->
    <xsl:text>%% If you manually remove hyperref, leave in this next command&#xa;</xsl:text>
    <xsl:text>\providecommand\phantomsection{}&#xa;</xsl:text>
    <!-- The "xwatermark" package has way more options, including the -->
    <!-- possibility of putting the watermark onto the foreground     -->
    <!-- (above shaded/colored "tcolorbox").  But on 2018-10-24,      -->
    <!-- xwatermark was at v1.5.2d, 2012-10-23, and draftwatermark    -->
    <!-- was at v1.2, 2015-02-19.                                     -->
    <!-- latex.watermark and latex.watermark.scale are deprecated,    -->
    <!-- but effort is made here so they still work for now           -->
    <xsl:if test="$b-watermark or $b-latex-watermark">
        <xsl:text>\usepackage{draftwatermark}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkText{</xsl:text>
        <xsl:choose>
            <xsl:when test="$b-watermark">
                <xsl:value-of select="$watermark.text" />
            </xsl:when>
            <xsl:when test="$b-latex-watermark">
                <xsl:value-of select="$latex.watermark" />
            </xsl:when>
        </xsl:choose>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\SetWatermarkScale{</xsl:text>
        <xsl:choose>
            <xsl:when test="$b-watermark">
                <xsl:value-of select="$watermark.scale" />
            </xsl:when>
            <xsl:when test="$b-latex-watermark">
                <xsl:value-of select="$latex-watermark-scale" />
            </xsl:when>
        </xsl:choose>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:text>%% Collected author tools options (author-tools='yes')&#xa;</xsl:text>
        <xsl:text>%% others need to be elsewhere, these are simply package additions&#xa;</xsl:text>
        <xsl:text>\usepackage{showkeys}&#xa;</xsl:text>
        <xsl:text>\usepackage[letter,cam,center,pdflatex]{crop}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$docinfo/latex-image-preamble">
        <xsl:text>%% Graphics Preamble Entries&#xa;</xsl:text>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="$docinfo/latex-image-preamble" />
        </xsl:call-template>
    </xsl:if>
    <xsl:text>%% If tikz has been loaded, replace ampersand with \amp macro&#xa;</xsl:text>
    <xsl:if test="$document-root//latex-image-code|$document-root//latex-image">
        <xsl:text>\ifdefined\tikzset&#xa;</xsl:text>
        <xsl:text>    \tikzset{ampersand replacement = \amp}&#xa;</xsl:text>
        <xsl:text>\fi&#xa;</xsl:text>
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
    <!-- We could use contains() on the 5 types of arrows  -->
    <!-- to really defend against this problematic package -->
    <xsl:if test="//m or //md or //mrow">
        <xsl:text>%% extpfeil package for certain extensible arrows,&#xa;</xsl:text>
        <xsl:text>%% as also provided by MathJax extension of the same name&#xa;</xsl:text>
        <xsl:text>%% NB: this package loads mtools, which loads calc, which redefines&#xa;</xsl:text>
        <xsl:text>%%     \setlength, so it can be removed if it seems to be in the &#xa;</xsl:text>
        <xsl:text>%%     way and your math does not use:&#xa;</xsl:text>
        <xsl:text>%%     &#xa;</xsl:text>
        <xsl:text>%%     \xtwoheadrightarrow, \xtwoheadleftarrow, \xmapsto, \xlongequal, \xtofrom&#xa;</xsl:text>
        <xsl:text>%%     &#xa;</xsl:text>
        <xsl:text>%%     we have had to be extra careful with variable thickness&#xa;</xsl:text>
        <xsl:text>%%     lines in tables, and so also load this package late&#xa;</xsl:text>
        <xsl:text>\usepackage{extpfeil}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$document-root//kbd">
        <!-- https://github.com/tweh/menukeys/issues/41 -->
        <xsl:text>%% menukeys package says:&#xa;</xsl:text>
        <xsl:text>%%   Since menukeys uses catoptions, which does some heavy&#xa;</xsl:text>
        <xsl:text>%%   changes on key-value options, it is recommended to load&#xa;</xsl:text>
        <xsl:text>%%   menukeys as the last package (even after hyperref)!&#xa;</xsl:text>
        <xsl:text>\usepackage{menukeys}&#xa;</xsl:text>
        <!-- https://tex.stackexchange.com/questions/96300/how-to-change-the-style-of-menukeys -->
        <xsl:text>\renewmenumacro{\keys}{shadowedroundedkeys}&#xa;</xsl:text>
        <xsl:text>\newcommand{\kbd}[1]{\keys{#1}}&#xa;</xsl:text>
    </xsl:if>

    <xsl:text>%% Custom Preamble Entries, late (use latex.preamble.late)&#xa;</xsl:text>
    <xsl:if test="$latex.preamble.late != ''">
        <xsl:value-of select="$latex.preamble.late" />
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>%% Begin: Author-provided packages&#xa;</xsl:text>
    <xsl:text>%% (From  docinfo/latex-preamble/package  elements)&#xa;</xsl:text>
    <xsl:value-of select="$latex-packages" />
    <xsl:text>%% End: Author-provided packages&#xa;</xsl:text>
    <xsl:text>%% Begin: Author-provided macros&#xa;</xsl:text>
    <xsl:text>%% (From  docinfo/macros  element)&#xa;</xsl:text>
    <xsl:text>%% Plus three from MBX for XML characters&#xa;</xsl:text>
    <xsl:value-of select="$latex-macros" />
    <xsl:text>%% End: Author-provided macros&#xa;</xsl:text>

    <xsl:if test="$document-root//contributors">
        <xsl:text>%% Semantic macros for contributor list&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributor}[1]{\parbox{\linewidth}{#1}\par\bigskip}&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributorname}[1]{\textsc{#1}\\[0.25\baselineskip]}&#xa;</xsl:text>
        <xsl:text>\newcommand{\contributorinfo}[1]{\hspace*{0.05\linewidth}\parbox{0.95\linewidth}{\textsl{#1}}}&#xa;</xsl:text>
    </xsl:if>

</xsl:template>

<!-- Text Alignment -->
<!-- Overall alignment can be "justify" (the default) or      -->
<!-- "raggedright" (as implemented by the "ragged2e" package) -->
<xsl:template name="text-alignment">
    <xsl:if test="$text-alignment = 'raggedright'">
        <xsl:text>\RaggedRight&#xa;</xsl:text>
    </xsl:if>
    <!-- $text-alignment = 'justify' => default LaTeX -->
</xsl:template>

<!-- Sidedness -->
<!-- \documentclass option, no comma -->
<xsl:template name="sidedness">
    <xsl:choose>
        <xsl:when test="$latex-sides= 'one'">
            <xsl:text>oneside</xsl:text>
        </xsl:when>
        <xsl:when test="$latex-sides= 'two'">
            <xsl:text>twoside</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- For a "book" place *before* \frontmatter so  -->
<!-- as to not disrupt Roman numeral numbering -->
<xsl:template name="front-cover">
    <xsl:if test="$docinfo/covers[@front]">
        <xsl:text>%% Cover image, not numbered&#xa;</xsl:text>
        <xsl:text>\setcounter{page}{0}%&#xa;</xsl:text>
        <xsl:text>\includepdf[noautoscale=false]{</xsl:text>
        <xsl:value-of select="$docinfo/covers/@front"/>
        <xsl:text>}%&#xa;</xsl:text>
        <xsl:if test="$latex-sides= 'two'">
            <xsl:text>%% Blank obverse for 2-sided version&#xa;</xsl:text>
            <xsl:text>\thispagestyle{empty}\hbox{}\setcounter{page}{0}\cleardoublepage%&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<xsl:template name="back-cover">
    <xsl:if test="$docinfo/covers[@back]">
        <xsl:text>%% Back cover image, not numbered&#xa;</xsl:text>
        <xsl:text>\cleardoublepage%&#xa;</xsl:text>
        <xsl:if test="$latex-sides= 'two'">
            <xsl:text>%% 2-sided, and at end of even page, so add odd page&#xa;</xsl:text>
            <xsl:text>\thispagestyle{empty}\hbox{}\newpage%&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>\includepdf[noautoscale=false]{</xsl:text>
        <xsl:value-of select="$docinfo/covers/@back"/>
        <xsl:text>}%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- PTX Divisions to LaTeX Divisions -->

<!-- PTX has a variety of divisions not native to LaTeX, so normally -->
<!-- an author would have to engineer/design these themselves.  We   -->
<!-- do something similar and implement them using the stock LaTeX   -->
<!-- divisons.  This is the dictionary which maps PreTeXt division   -->
<!-- elements to stock LaTeX division environments.                  -->
<!-- NB: we formerly did this using the "level" template and the     -->
<!-- "level-to-name" templates, which we should consider obsoleting, -->
<!-- simplifying, or consolidating.                                  -->
<xsl:template match="part|chapter|section|subsection|subsubsection" mode="division-name">
    <xsl:value-of select="local-name(.)"/>
</xsl:template>

<!-- Front matter divisions are only in book, and always at chapter level -->
<xsl:template match="acknowledgement|foreword|preface" mode="division-name">
    <xsl:text>chapter</xsl:text>
</xsl:template>

<!-- Some divisions can appear at multiple levels (eg, exercises) -->
<!-- Divisions in the back matter vary between books and articles -->
<!--     Book:    children of backmatter -> chapter               -->
<!--     Article: children of backmatter -> section               -->
<xsl:template match="exercises|solutions|worksheet|reading-questions|references|glossary|appendix|index" mode="division-name">
    <xsl:choose>
        <xsl:when test="parent::article">
            <xsl:text>section</xsl:text>
        </xsl:when>
        <xsl:when test="parent::chapter">
            <xsl:text>section</xsl:text>
        </xsl:when>
        <xsl:when test="parent::section">
            <xsl:text>subsection</xsl:text>
        </xsl:when>
        <xsl:when test="parent::subsection">
            <xsl:text>subsubsection</xsl:text>
        </xsl:when>
        <xsl:when test="parent::subsubsection">
            <xsl:text>paragraph</xsl:text>
        </xsl:when>
        <!-- children of backmatter (appendix, solutions, reference, index) -->
        <!-- in book/article are at chapter/section level                   -->
        <xsl:when test="parent::backmatter">
            <xsl:choose>
                <xsl:when test="ancestor::book">
                    <xsl:text>chapter</xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::article">
                    <xsl:text>section</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <!-- appendix in book/article is at chapter/section level -->
        <!-- so descendants (exercises, solutions) down one level -->
        <xsl:when test="parent::appendix">
            <xsl:choose>
                <xsl:when test="ancestor::book">
                    <xsl:text>section</xsl:text>
                </xsl:when>
                <xsl:when test="ancestor::article">
                    <xsl:text>subsection</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="division-name">
    <xsl:message>MBX:BUG: Asking for the name of an element (<xsl:value-of select="local-name(.)" />) that is not a division</xsl:message>
</xsl:template>

<!-- ####################### -->
<!-- LaTeX Macro Definitions -->
<!-- ####################### -->

<!-- These are not yet meant for style writer use. -->

<!-- Abbreviations, Acronyms, Initialisms, -->
<!-- "abbr", "acro", "init"                -->
<!-- Body: \abbreviation{ABC}              -->
<!-- Titles: \abbreviationuntitle{ABC}     -->
<!-- PDF navigation panels has titles as simple strings,    -->
<!-- devoid of any formatting, so we just give up, as any   -->
<!-- attempt to use title-specific macros, \texorpdfstring, -->
<!-- \protect, \DeclareRobustCommand does not help get      -->
<!-- ToC, PDF navigation panel, text heading all correct    -->
<!-- Obstacle is that sc shape does not come in bold,       -->
<!-- http://tex.stackexchange.com/questions/17830/using-textsc-within-section -->
<xsl:template match="abbr" mode="tex-macro">
    <xsl:text>\newcommand{\abbreviation}[1]{</xsl:text>
    <xsl:text>%% Used to markup abbreviations, text or titles&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="tex-macro-style"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\DeclareRobustCommand{\abbreviationintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="acro" mode="tex-macro">
    <xsl:text>%% Used to markup acronyms, text or titles&#xa;</xsl:text>
    <xsl:text>\newcommand{\acronym}[1]{</xsl:text>
    <xsl:apply-templates select="." mode="tex-macro-style"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\DeclareRobustCommand{\acronymintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="init" mode="tex-macro">
    <xsl:text>%% Used to markup initialisms, text or titles&#xa;</xsl:text>
    <xsl:text>\newcommand{\initialism}[1]{</xsl:text>
    <xsl:apply-templates select="." mode="tex-macro-style"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\DeclareRobustCommand{\initialismintitle}[1]{\texorpdfstring{#1}{#1}}&#xa;</xsl:text>
</xsl:template>

<!-- ############################# -->
<!-- LaTeX Environment Definitions -->
<!-- ############################# -->

<!-- These are not yet meant for style writer use. -->

<!-- Notes: -->
<!-- *  Generally, all boxes should be "breakable"     -->
<!-- *  If the contents can be reasonably expected to  -->
<!--    be organized by paragraphs, then use the       -->
<!--    tcolorbox style option "parbox=false"          -->
<!-- *  The  etoolbox  package has some good tools     -->
<!-- *  Some items need a "phantom={\hypertarget{}{}}" -->
<!--    search on mode="xref-as-ref" for more          -->
<!-- *  Traditional LaTeX labels are implemented with  -->
<!--    tcolorbox "phantomlabel=" option               -->
<!-- *  tcolor box seem to begin in horizontal mode,   -->
<!--    and need to return to vertical mode once       -->
<!--    concluded (lest, e.g., consecutive boxes       -->
<!--    overlap). Use of "after={\par}" is the right   -->
<!--    fix.  See                                      -->
<!--    https://tex.stackexchange.com/questions/235848 -->
<!--    /how-to-leave-horizontal-mode                  -->

<!-- Style: -->
<!-- Provide some comments for the LaTeX source, to aid     -->
<!-- with standalone use or debugging.  Preface with "%% ". -->

<!-- We have lots of divisions, some traditional (chapters),      -->
<!-- some one-off (preface), some pervasive (exercises).  Many    -->
<!-- are always numbered (chapters), some are never numbered      -->
<!-- (prefaces), some go both ways (exercises).  All get their    -->
<!-- own environments, with two for the numbered/unnumbered.      -->
<!-- Traditional need a suffix 'ptx' to distinguish from the      -->
<!-- built-in LaTeX names, one-off get their own natural name,    -->
<!-- and pervasive get a suffix that indicates their level.       -->
<!--                                                              -->
<!-- These environments will be defined using the LaTeX macros    -->
<!-- which correspond to the traditional names, so as to leverage -->
<!-- LaTeX numbering, titlesec styling, and migration of titles   -->
<!-- to running heads via the cooperating titleps package.  But   -->
<!-- the environments will also be enhanced through the titlesec  -->
<!-- package to allow the seamless addition of authors and        -->
<!-- epigraphs, in addition to actual styling.                    -->

<!-- "introduction", "conclusion" -->
<!-- Body:  \begin{outcomes}{title}              -->
<!-- Divisional, want to obsolete title soon     -->
<!-- Simple, w/ temporary run-in title, no label -->
<!-- (so don't merge with other titled environments) -->

<!-- NB: Once upon a time, this was a breakable tcolorbox.  But then if   -->
<!-- the contents were too complicated, then a breakable tcolorbox might  -->
<!-- be contained (like a theorem, say).  That interior breakable         -->
<!-- tcolorbox would *automatically* be made unbreakable, and the result  -->
<!-- was really bad page breaks, or worse, the potential for the interior -->
<!-- box dribbling off the bottom of the page.                            -->
<xsl:template match="introduction|conclusion" mode="environment">
    <xsl:variable name="environment-name">
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: in a structured division&#xa;</xsl:text>
    <xsl:text>\NewDocumentEnvironment{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}{m}&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="self::introduction">
            <xsl:text>{\notblank{#1}{\noindent\textbf{#1}\space}{}}</xsl:text>
        </xsl:when>
        <xsl:when test="self::conclusion">
            <xsl:text>{\par\medskip\noindent\notblank{#1}{\textbf{#1}\space}{}}</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="self::introduction">
            <xsl:text>{\par\medskip}</xsl:text>
        </xsl:when>
        <xsl:when test="self::conclusion">
            <xsl:text>{}</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- A division has a PTX name via local-name() and a corresponding -->
<!-- LaTeX traditional division via the "division-name" template.   -->
<!-- The following templates build the names of the environments,   -->
<!-- so we can build and employ them consistently.                  -->

<!-- Traditional -->
<!-- Add suffix to avoid clashes (NB: \appendix, \index exists) -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|index" mode="division-environment-name">
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>ptx</xsl:text>
</xsl:template>

<!-- One-Off -->
<!-- Free here to use the PTX name, without clashing with LaTeX -->
<xsl:template match="acknowledgement|foreword|preface" mode="division-environment-name">
    <xsl:value-of select="local-name(.)"/>
</xsl:template>

<!-- Pervasive -->
<!-- Product of PTX name with LaTeX level/division -->
<xsl:template match="exercises|solutions|worksheet|reading-questions|glossary|references" mode="division-environment-name">
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>-</xsl:text>
    <xsl:apply-templates select="." mode="division-name"/>
</xsl:template>

<xsl:template match="*" mode="division-environment-name">
    <xsl:message>NO DIVISION ENVIRONMENT NAME for <xsl:value-of select="local-name(.)"/></xsl:message>
</xsl:template>


<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|index|exercises|solutions|worksheet|reading-questions|glossary|references" mode="environment">
    <!-- for specialized divisions we always make a numbered -->
    <!-- and unnumbered version, with the latter happening   -->
    <!-- on a second trip through the template               -->
    <xsl:param name="second-trip" select="false()"/>

    <xsl:variable name="elt-name" select="local-name(.)"/>
    <!-- the (traditional) LaTex name of this division -->
    <xsl:variable name="div-name">
        <xsl:apply-templates select="." mode="division-name"/>
    </xsl:variable>
    <!-- explanatory string in preamble -->
    <xsl:text>%% Environment for a PTX "</xsl:text>
    <xsl:value-of select="$elt-name"/>
    <xsl:text>" at the level of a LaTeX "</xsl:text>
    <xsl:value-of select="$div-name"/>
    <xsl:text>"&#xa;</xsl:text>
    <!-- Define implementation of a 5-argument environment          -->
    <!-- Template ensures consistency of definition and application -->
    <xsl:text>\NewDocumentEnvironment{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name"/>
    <!-- second trip through for a specialized -->
    <!-- division, build unnumbered version    -->
    <xsl:if test="$second-trip">
        <xsl:text>-numberless</xsl:text>
    </xsl:if>
    <xsl:text>}{mmmmmm}&#xa;</xsl:text>
    <xsl:text>{%&#xa;</xsl:text>
    <!-- load 6 macros with values, for style writer use -->
    <xsl:text>\renewcommand{\divisionnameptx}{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\titleptx}{#1}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\subtitleptx}{#2}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\shortitleptx}{#3}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\authorsptx}{#4}%&#xa;</xsl:text>
    <xsl:text>\renewcommand{\epigraphptx}{#5}%&#xa;</xsl:text>
    <!-- invoke the right LaTeX division, causes title format -->
    <!-- and spacing, along with setting running heads        -->
    <xsl:text>\</xsl:text>
    <xsl:value-of select="$div-name"/>
    <xsl:choose>
        <!-- Second trip through, building unnumbered version -->
        <!-- OR                                               -->
        <!-- Never numbered, always build a starred form      -->
        <!-- and manually add short version to ToC            -->
        <xsl:when test="$second-trip or boolean(self::acknowledgement|self::foreword|self::preface|self::index)">
            <xsl:text>*</xsl:text>
            <xsl:text>{#1}%&#xa;</xsl:text>
            <xsl:text>\addcontentsline{toc}{</xsl:text>
            <xsl:value-of select="$div-name"/>
            <xsl:text>}{#3}&#xa;</xsl:text>
        </xsl:when>
        <!-- optional short title, and the real title  -->
        <!-- NB: the short title (#3) needs a group to -->
        <!-- protect a right square bracket "]" from   -->
        <!-- prematurely ending the optional argument  -->
        <xsl:otherwise>
            <xsl:text>[{#3}]{#1}%&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\label{#6}%&#xa;</xsl:text>
    <!-- close the environment definition, no finish -->
    <xsl:text>}{}%&#xa;</xsl:text>
    <!-- send specialized division back through a second time -->
    <xsl:if test="not($second-trip) and boolean(self::exercises|self::solutions|self::worksheet|self::reading-questions|self::glossary|self::references)">
        <xsl:apply-templates select="." mode="environment">
            <xsl:with-param name="second-trip" select="true()"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- "commentary" -->
<!-- Body:  \begin{commentary}{title}      -->
<!-- Title comes with punctuation, always. -->
<xsl:template match="commentary" mode="environment">
    <xsl:text>%% commentary: elective, additional comments in an enhanced edition&#xa;</xsl:text>
    <xsl:text>\tcbset{ commentarystyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{commentary}[2]{title={#1}, phantomlabel={#2}, breakable, parbox=false, commentarystyle}&#xa;</xsl:text>
</xsl:template>

<!-- "proof" -->
<!-- Body:  \begin{proof}{title}{label}    -->
<!-- Title comes with punctuation, always. -->
<xsl:template match="proof" mode="environment">
    <xsl:text>%% proof: title is a replacement&#xa;</xsl:text>
    <xsl:text>\tcbset{ proofstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{proofptx}[2]{title={\notblank{#1}{#1}{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>.}}, phantom={</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#2}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#2}{}}, breakable, parbox=false, after={\par}, proofstyle }&#xa;</xsl:text>
</xsl:template>

<!-- "case" (of a proof) -->
<!-- Body:  \begin{proof}{directionarrow}{title}{label} -->
<!-- Title comes with punctuation, always.              -->
<!-- TODO: move implication definitions here, and       -->
<!-- pass semantic strings out of the construction      -->
<xsl:template match="case" mode="environment">
    <xsl:text>\NewDocumentEnvironment{case}{mmm}&#xa;</xsl:text>
    <xsl:text>{\par\medskip\noindent\notblank{#1}{#1\space{}}{}\textit{\notblank{#2}{#2\space{}}{}\notblank{#1#2}{}{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>.\space{}}}</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#3}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#3}{}}{}&#xa;</xsl:text>
</xsl:template>

<!-- "objectives" -->
<!-- Body:  \begin{objectives}{m:title}    -->
<!-- Title comes without new punctuation.  -->
<xsl:template match="objectives" mode="environment">
    <xsl:text>%% objectives: early in a subdivision, introduction/list/conclusion&#xa;</xsl:text>
    <xsl:text>\tcbset{ objectivesstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{objectives}[2]{title={#1}, phantomlabel={#2}, breakable, parbox=false, objectivesstyle}&#xa;</xsl:text>
</xsl:template>

<!-- "outcomes" -->
<!-- Body:  \begin{outcomes}{m:title}      -->
<!-- Title comes without new punctuation.  -->
<xsl:template match="outcomes" mode="environment">
    <xsl:text>%% outcomes: late in a subdivision, introduction/list/conclusion&#xa;</xsl:text>
    <xsl:text>\tcbset{ outcomesstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{outcomes}[2]{title={#1}, phantomlabel={#2}, breakable, parbox=false, outcomesstyle}&#xa;</xsl:text>
</xsl:template>

<!-- back "colophon" -->
<!-- Body:  \begin{backcolophon}{label} -->
<xsl:template match="backmatter/colophon" mode="environment">
    <xsl:text>%% back colophon, at the very end, typically on its own page&#xa;</xsl:text>
    <xsl:text>\tcbset{ backcolophonstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{backcolophon}[1]{title={</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}, phantom={</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#1}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#1}{}}, breakable, parbox=false, backcolophonstyle}&#xa;</xsl:text>
</xsl:template>

<!-- "assemblage" -->
<!-- Identical to ASIDE-LIKE, but we keep it distinct -->
<xsl:template match="assemblage" mode="environment">
    <!-- Names of various pieces use the element name -->
    <xsl:variable name="environment-name">
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: fairly simple un-numbered block/structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}[2]{title={\notblank{#1}{#1}{}}, </xsl:text>
    <xsl:text>phantomlabel={#2}, breakable, parbox=false, </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style}&#xa;</xsl:text>
</xsl:template>

<!-- "defined-term" -->
<!-- Body:  \begin{definedterm}{title}{label} -->
<xsl:template match="defined-term" mode="environment">
    <xsl:text>%% commentary: elective, additional comments in an enhanced edition&#xa;</xsl:text>
    <xsl:text>\tcbset{ definedtermstyle/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style" />
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{definedterm}[2]{title={#1\space}, phantomlabel={#2}, breakable, parbox=false, definedtermstyle}&#xa;</xsl:text>
</xsl:template>

<!-- "paragraphs" -->
<!-- Body:  \begin{paragraphs}{title}{label}   -->
<!-- "titlesec" package, Subsection 9.2 has LaTeX defaults -->
<!-- We drop the indentation, and we pass the title itself -->
<!-- explicity with macro parameter #1 since we do not save-->
<!-- off the title in a PTX macro.  None of this is meant  -->
<!-- to support customization in a style.                  -->
<!-- Once a tcolorbox, see warnings as part of divisional  -->
<!-- introductions and conclusions.                        -->
<xsl:template match="paragraphs" mode="environment">
    <xsl:text>%% paragraphs: the terminal, pseudo-division&#xa;</xsl:text>
    <xsl:text>%% We use the lowest LaTeX traditional division&#xa;</xsl:text>
    <xsl:text>\titleformat{\subparagraph}[runin]{\normalfont\normalsize\bfseries}{\thesubparagraph}{1em}{#1}&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\subparagraph}{0pt}{3.25ex plus 1ex minus .2ex}{1em}&#xa;</xsl:text>
    <xsl:text>\NewDocumentEnvironment{paragraphs}{mm}&#xa;</xsl:text>
    <xsl:text>{\subparagraph*{#1}</xsl:text>
    <xsl:if test="$b-pageref">
        <xsl:text>\label{#2}</xsl:text>
    </xsl:if>
    <xsl:text>\hypertarget{#2}{}}{}&#xa;</xsl:text>
</xsl:template>

<!-- ASIDE-LIKE: "aside", "historical", "biographical" -->
<!-- Note: do not integrate into others, as treatment may necessarily vary -->
<xsl:template match="&ASIDE-LIKE;" mode="environment">
    <!-- Names of various pieces use the element name -->
    <xsl:variable name="environment-name">
        <xsl:value-of select="local-name(.)"/>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: fairly simple un-numbered block/structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <xsl:text>\newtcolorbox{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}[2]{title={\notblank{#1}{#1}{}}, </xsl:text>
    <xsl:text>phantomlabel={#2}, breakable, parbox=false, </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style}&#xa;</xsl:text>
</xsl:template>


<!-- THEOREM-LIKE: "theorem", "corollary", "lemma",    -->
<!--               "algorithm", "proposition",         -->
<!--               "claim", "fact", "identity"         -->
<!-- AXIOM-LIKE: "axiom", "conjecture", "principle",   -->
<!--             "heuristic", "hypothesis",            -->
<!--             "assumption                           -->
<!-- DEFINITION-LIKE: "definition"                     -->
<!-- REMARK-LIKE: "remark", "convention", "note",      -->
<!--              "observation", "warning", "insight"  -->
<!-- COMPUTATION-LIKE: "computation", "technology"     -->
<!-- EXAMPLE-LIKE: "example", "question", "problem"    -->
<!-- PROJECT-LIKE: "activity", "exploration",          -->
<!--               "exploration", "investigation"      -->
<!-- Inline Exercises                                  -->
<!-- Body: \begin{example}{title}{label}, etc.         -->
<!--       \begin{inlineexercise}{title}{label}        -->
<!-- Type, number, optional title                      -->
<!-- Title comes without new punctuation.              -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="environment">
    <!-- Names of various pieces normally use the      -->
    <!-- element name, but "exercise" does triple duty -->
    <xsl:variable name="environment-name">
        <xsl:choose>
            <!-- TODO: filter is redundant, here and below, given match? -->
            <xsl:when test="self::exercise and boolean(&INLINE-EXERCISE-FILTER;)">
                <xsl:text>inlineexercise</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="local-name(.)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- projects and inline exercises sometimes run on their own counters -->
    <xsl:variable name="counter">
        <xsl:choose>
            <xsl:when test="(&PROJECT-FILTER;) and $b-number-project-distinct">
                <xsl:text>project-distinct</xsl:text>
            </xsl:when>
            <xsl:when test="self::exercise and boolean(&INLINE-EXERCISE-FILTER;) and $b-number-exercise-distinct">
                <xsl:text>exercise-distinct</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>block</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <!-- per-environment style -->
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: fairly simple numbered block/structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <!-- create and configure the environment/tcolorbox -->
    <xsl:text>\newtcolorbox</xsl:text>
    <!-- run on a common, default, faux counter -->
    <xsl:text>[</xsl:text>
    <xsl:text>use counter from=</xsl:text>
    <xsl:value-of select="$counter"/>
    <xsl:text>]</xsl:text>
    <!-- environment's tcolorbox name, pair -->
    <!-- with actual constructions in body  -->
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}</xsl:text>
    <!-- number of arguments -->
    <xsl:choose>
        <xsl:when test="&THEOREM-FILTER; or &AXIOM-FILTER;">
            <xsl:text>[3]</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[2]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- begin: options -->
    <xsl:text>{</xsl:text>
    <!-- begin: title construction -->
    <xsl:text>title={{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>~\thetcbcounter</xsl:text>
    <xsl:choose>
        <xsl:when test="&THEOREM-FILTER; or &AXIOM-FILTER;">
            <!-- first space of double space -->
            <xsl:text>\notblank{#1#2}{\space}{}</xsl:text>
            <xsl:text>\notblank{#1}{\space#1}{}</xsl:text>
            <xsl:text>\notblank{#2}{\space(#2)}{}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\notblank{#1}{\space\space#1}{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}}, </xsl:text>
    <!-- end: title construction -->
    <!-- label in argument 2 or argument 3 -->
    <xsl:choose>
        <xsl:when test="&THEOREM-FILTER; or &AXIOM-FILTER;">
            <xsl:text>phantomlabel={#3}, </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>phantomlabel={#2}, </xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- always breakable -->
    <xsl:text>breakable, parbox=false, after={\par}, </xsl:text>
    <!-- italic body (this should be set elsewhere) -->
    <xsl:if test="&THEOREM-FILTER; or &AXIOM-FILTER;">
        <xsl:text>fontupper=\itshape, </xsl:text>
    </xsl:if>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style, }&#xa;</xsl:text>
    <!-- end: options -->
</xsl:template>

<xsl:template match="figure|table|listing|list" mode="environment">
    <!-- could be more stringent, sidebyside in     -->
    <!-- slot 1, ancestor figure is in slot 2 or 3: -->
    <!--     figure/sidebyside/*                    -->
    <!--     figure/sbsgroup/sidebyside/*           -->
    <xsl:variable name="b-subcaptioned" select="boolean(ancestor::*[self::figure])"/>
    <xsl:variable name="environment-name">
        <xsl:apply-templates select="." mode="environment-name"/>
    </xsl:variable>
    <!-- counters may run as subcaptions, independently, or with blocks -->
    <xsl:variable name="counter">
        <xsl:choose>
            <xsl:when test="$b-subcaptioned">
                <xsl:text>subdisplay</xsl:text>
            </xsl:when>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:text>figure-distinct</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>block</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>%% </xsl:text>
    <!-- per-environment style -->
    <xsl:value-of select="$environment-name"/>
    <xsl:text>: 2-D display structure&#xa;</xsl:text>
    <xsl:text>\tcbset{ </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style/.style={</xsl:text>
    <xsl:apply-templates select="." mode="tcb-style"/>
    <xsl:text>} }&#xa;</xsl:text>
    <!-- create and configure the environment/tcolorbox -->
    <xsl:text>\newtcolorbox</xsl:text>
    <xsl:text>[</xsl:text>
    <xsl:text>use counter from=</xsl:text>
    <xsl:value-of select="$counter"/>
    <xsl:text>]</xsl:text>
    <!-- environment's tcolorbox name, pair -->
    <!-- with actual constructions in body  -->
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>}</xsl:text>
    <!-- number of arguments -->
    <xsl:text>[3]</xsl:text>
    <!-- begin: options -->
    <xsl:text>{</xsl:text>
    <!-- begin: title/caption construction -->
    <xsl:choose>
        <!-- Subcaptions of 2D displays within panels of a figure/sidebyside   -->
        <!-- \thetcbcounter comes from subdisplay, looks like 25.3(b),         -->
        <!-- and this is what will render in a cross-reference via \label/\ref -->
        <!-- The enclosing figure is numbered from block or figure-distinct.   -->
        <!-- We us the "xstring" package to strip out this number (e.g. 25.3)  -->
        <!-- and leave just the sub-numbering (e.g, (b)).                      -->
        <!-- NB: parameter #3 is a hardcoded number supplied by the -common    -->
        <!-- routines, since it gets massaged to (a), (b), (c), etc. and this  -->
        <!-- part is independent of the structure number, it will be right     -->
        <!-- even if the LaTeX source is a subset (we can't optionally include -->
        <!-- panels of a "sidebyside").  Short answer, we ignore #3 in this    -->
        <!-- case.  Always.                                                    -->
        <xsl:when test="$b-subcaptioned">
            <xsl:text>lower separated=false, </xsl:text>
            <xsl:text>before lower={{</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-number-figure-distinct">
                    <xsl:text>\textbf{\StrSubstitute{\thetcbcounter}{\thetcb@cnt@figure-distinct}{}}</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\textbf{\StrSubstitute{\thetcbcounter}{\thetcb@cnt@block}{}}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>\space#1</xsl:text>
            <xsl:text>}}, </xsl:text>
        </xsl:when>
        <!-- Only the type-number is bolded, caption in #1 is plain text -->
        <xsl:when test="self::figure|self::listing">
            <xsl:text>lower separated=false, </xsl:text>
            <xsl:text>before lower={{</xsl:text>
            <xsl:text>\textbf{</xsl:text>
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text>~</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-latex-hardcode-numbers">
                    <xsl:text>#3</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\thetcbcounter</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>}</xsl:text>
            <xsl:text>\space#1</xsl:text>
            <xsl:text>}}, </xsl:text>
        </xsl:when>
        <!-- Only the type-number is bolded here, caption in #1 is bold text -->
        <xsl:when test="self::table|self::list">
            <xsl:text>title={{</xsl:text>
            <xsl:text>\textbf{</xsl:text>
            <xsl:apply-templates select="." mode="type-name"/>
            <xsl:text>~</xsl:text>
            <xsl:choose>
                <xsl:when test="$b-latex-hardcode-numbers">
                    <xsl:text>#3</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\thetcbcounter</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>}</xsl:text>
            <xsl:text>\space#1</xsl:text>
            <xsl:text>}}, </xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- end: title/caption construction -->
    <!-- label in argument 2             -->
    <xsl:text>phantomlabel={#2}, </xsl:text>
    <!-- always unbreakable, except for "list"           -->
    <!-- list will be unbreakable once inside sidebyside -->
    <xsl:choose>
        <xsl:when test="self::list">
            <xsl:text>breakable, </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>unbreakable, </xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>parbox=false, </xsl:text>
    <xsl:value-of select="$environment-name"/>
    <xsl:text>style, }&#xa;</xsl:text>
    <!-- end: options -->
</xsl:template>

<!-- ########################## -->
<!-- LaTeX Styling via Preamble -->
<!-- ########################## -->

<!-- General Notes: -->
<!--                -->
<!-- * Protect tcolorbox arguments with braces, especially titles, -->
<!--   since commas will bleed through into the options otherwise  -->
<!-- * Separate the tcolorbox options with spaces after commas     -->
<!-- * Run the LaTeX compilation at least twice before giving up   -->
<!-- * The tcolorbox "title" option is set in the environment      -->
<!-- * End lists of styling options with a trailing comma          -->
<!-- * tcolorbox, boxrule=-0.3pt seems necessary to avoid          -->
<!--   very faint lines/rules appearing in some PDF viewers,       -->
<!--   not clear if "frame empty" is also necessary                -->
<!-- * See discussion of end-of-block markers (eg, a proof         -->
<!--   tombstone/Halmos) at the default style for proof            -->

<!-- "abbr", "acro", "init" -->
<!-- We default to small caps for abbreviations, acronyms, and  -->
<!-- initialisms.  See Bringhurst, 4e, 3.2.2, p. 48.  These can -->
<!-- be overridden with simply "#1" to provide macros that just -->
<!-- repeat their arguments.                                    -->
<!-- lower-casing macro:  ("force-all-small-caps") at           -->
<!-- http://tex.stackexchange.com/questions/114592/             -->
<xsl:template match="abbr|acro|init" mode="tex-macro-style">
    <!-- <xsl:text>{\scshape #1}</xsl:text> -->
    <xsl:text>\textsc{\MakeLowercase{#1}}</xsl:text>
</xsl:template>

<!-- "introduction", "conclusion" -->
<!-- Run-in optional title, which will eventually go away       -->
<!-- We add a gap before just a "conclusion", using XSL.        -->
<!-- If you are using this as an example/guide, and don't       -->
<!-- understand this more advanced use of XSL, just make two    -->
<!-- templates, one for "introduction" and one for "conclusion" -->
<xsl:template match="introduction|conclusion" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, </xsl:text>
    <xsl:if test="self::conclusion">
        <xsl:text>before skip=3ex</xsl:text>
    </xsl:if>
</xsl:template>

<!-- "commentary" -->
<!-- "Greg's L" with tcolorbox and tikz code. The "enhanced" -->
<!-- skin is necessary for the predefined "frame.*" nodes    -->
<!-- The 5% horizontal leg is a "partway modifier", from     -->
<!-- https://tex.stackexchange.com/questions/48756/tikz-relative-coordinates -->
<xsl:template match="commentary" mode="tcb-style">
    <xsl:text>blockspacingstyle, skin=enhanced,fonttitle=\bfseries,coltitle=black,colback=white,frame code={&#xa;</xsl:text>
    <xsl:text>\path[draw=red!75!black,line width=0.5mm] (frame.north west) -- (frame.south west) -- ($ (frame.south west)!0.05!(frame.south east) $);}</xsl:text>
</xsl:template>

<!-- "proof" -->
<!-- Title in italics, as in amsthm style.           -->
<!-- Filled, black square as QED, tombstone, Halmos. -->
<!-- Pushing the tombstone flush-right is a bit      -->
<!-- ham-handed, but more elegant TeX-isms           -->
<!-- (eg \hfill) did not get it done.  We require at -->
<!-- least two spaces gap to remain on the same      -->
<!-- line. Presumably the line will stretch when the -->
<!-- tombstone moves onto its own line.              -->
<xsl:template match="proof" mode="tcb-style">
    <xsl:text>bwminimalstyle, fonttitle=\normalfont\itshape, attach title to upper, after title={\space}, after upper={\space\space\hspace*{\stretch{1}}\(\blacksquare\)},&#xa;</xsl:text>
</xsl:template>

<!-- "objectives" -->
<!-- Rules top and bottom, title on its own line, as a heading -->
<xsl:template match="objectives" mode="tcb-style">
    <xsl:text>bwminimalstyle, blockspacingstyle, fonttitle=\large\bfseries, toprule=0.1ex, toptitle=0.5ex, top=2ex, bottom=0.5ex, bottomrule=0.1ex</xsl:text>
</xsl:template>

<!-- "outcomes" -->
<!-- Differs only by spacing prior, this could go away  -->
<!-- if headings, etc handle vertical space correctly   -->
<xsl:template match="outcomes" mode="tcb-style">
    <xsl:text>bwminimalstyle, blockspacingstyle, fonttitle=\large\bfseries, toprule=0.1ex, toptitle=0.5ex, top=2ex, bottom=0.5ex, bottomrule=0.1ex, before skip=2ex</xsl:text>
</xsl:template>

<!-- back "colophon" -->
<xsl:template match="backmatter/colophon" mode="tcb-style">
    <xsl:text>bwminimalstyle, blockspacingstyle, before skip=5ex, left skip=0.15\textwidth, right skip=0.15\textwidth, fonttitle=\large\bfseries, center title, halign=center, bottomtitle=2ex</xsl:text>
</xsl:template>

<!-- "defined-term" -->
<!-- Differs only by spacing prior, this could go away  -->
<!-- if headings, etc handle vertical space correctly   -->
<xsl:template match="defined-term" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, </xsl:text>
</xsl:template>


<!-- THEOREM-LIKE: "theorem", "corollary", "lemma",    -->
<!--               "algorithm", "proposition",         -->
<!--               "claim", "fact", "identity"         -->
<!-- AXIOM-LIKE: "axiom", "conjecture", "principle",   -->
<!--             "heuristic", "hypothesis",            -->
<!--             "assumption                           -->
<!-- DEFINITION-LIKE: "definition"                     -->
<!-- REMARK-LIKE: "remark", "convention", "note",      -->
<!--              "observation", "warning", "insight"  -->
<!-- COMPUTATION-LIKE: "computation", "technology"     -->
<!-- EXAMPLE-LIKE: "example", "question", "problem"    -->
<!-- PROJECT-LIKE: "activity", "exploration",          -->
<!--               "exploration", "investigation"      -->
<!-- ASIDE-LIKE: "aside", "historical", "biographical" -->
<!-- Inline Exercises                                  -->
<!--                                                   -->
<!-- Inline, bold face title, otherwise B/W, plain     -->
<!-- The "\normalfont" on the title is to counteract   -->
<!-- the italicized bodies of theorems and axioms      -->
<!-- coming from the "environment" template, since the -->
<!-- title is being smashed inline into the upper part -->
<!-- of the box.  It has no effect on other            -->
<!-- environments.  But ideally, we would split out    -->
<!-- this piece into a template for just theorems      -->
<!-- and axioms.                                       -->
<!-- DEFINITION-LIKE and EXAMPLE-LIKE are exceptional  -->
<!-- in that markers are inserted with "after upper"   -->
<!-- to indicate the end of the environment.           -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]|&ASIDE-LIKE;" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, after title={\space}, </xsl:text>
</xsl:template>

<xsl:template match="&DEFINITION-LIKE;" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, after title={\space}, after upper={\space\space\hspace*{\stretch{1}}\(\lozenge\)}, </xsl:text>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;" mode="tcb-style">
    <xsl:text>bwminimalstyle, runintitlestyle, blockspacingstyle, after title={\space}, after upper={\space\space\hspace*{\stretch{1}}\(\square\)}, </xsl:text>
</xsl:template>

<!-- FIGURE-LIKE: -->
<!-- 2019-08-08: ad-hoc for now, named-styles will evolve      -->
<!-- "figure" and listing" are very similar (captions)         -->
<!-- "table" and "list" are very similar (titles)              -->
<!-- NB: these will be used for "plain" 2D displays and for    -->
<!-- when these are the panels of a "sidebyside".  So within   -->
<!-- environments we bold titles (table and list) as produced, -->
<!-- and do not bold captions as produced.  This way titles    -->
<!-- that migrate to the lower part when subcaptioned will be  -->
<!-- bold.  So we also bold type names and numbers as          -->
<!-- produced. Net result is that we do not apply font weights -->
<!-- to titles via styles.                                     -->
<!-- NB: there could be 4 more styles, conditioning all 8 on   -->
<!-- "ancestor::*[self::figure]" (or "not()") to manage the    -->
<!-- panels of a subcaptioned sidebyside.                      -->
<xsl:template match="figure|listing" mode="tcb-style">
    <xsl:text>bwminimalstyle, middle=1ex, blockspacingstyle, </xsl:text>
</xsl:template>

<xsl:template match="table" mode="tcb-style">
    <xsl:text>bwminimalstyle, middle=1ex, blockspacingstyle, coltitle=black, bottomtitle=2ex, titlerule=-0.3pt</xsl:text>
</xsl:template>

<!-- "list" contents are breakable, so we rub out annoying faint lines -->
<xsl:template match="list" mode="tcb-style">
    <xsl:text>middle=1ex, blockspacingstyle, colback=white, colbacktitle=white, coltitle=black, colframe=black, titlerule=-0.3pt, toprule at break=-0.3pt, bottomrule at break=-0.3pt, sharp corners</xsl:text>
</xsl:template>

<!-- This is mostly ad-hoc.  An assemblage is meant to be prominent,   -->
<!-- we just use a simple box with rounded corners as a default, with  -->
<!-- the title (if present) centered.  Note that we get a bit of extra -->
<!-- vertical space in the title box in the event the title is null.   -->
<!-- For a document with titled and untitled assemblages maybe we need -->
<!-- a way to have two styles (tcb-title-style, tcb-notitle-style?)    -->
<!-- specified?                                                        -->
<!--                                                                   -->
<!-- A "list" will have square corners, thus the explicit rounded      -->
<!-- corners (the default).  We want to tell the difference when       -->
<!-- debugging or authoring.                                           -->
<!--                                                                   -->
<!-- NB: standard jigsaw, opacityback=0.0, opacitybacktitle=0.0  makes -->
<!-- title rule visible, and  opacity-fill=0.0  kills the the border   -->
<xsl:template match="assemblage" mode="tcb-style">
    <xsl:text>size=normal, colback=white, colbacktitle=white, coltitle=black, colframe=black, rounded corners, titlerule=0.0pt, center title, fonttitle=\normalfont\bfseries, blockspacingstyle, </xsl:text>
</xsl:template>

<!-- This is the gross default, across all objects and all styles -->
<!-- It is convenient for development, testing, and convenience    -->
<xsl:template match="*" mode="tcb-style" />

<!-- ################### -->
<!-- Titles of Divisions -->
<!-- ################### -->

<!-- Section 9.2 of the "titlesec" package has default parameters   -->
<!-- which mimic LaTeX style and spacing.  We use those here, so    -->
<!-- we can integrate an author credit into the heading/title       -->
<!-- before any spacing happens.  Authors are one fontsize smaller, -->
<!-- and placed in the optional "after-code" argument.              -->
<!-- We provide variants for the "numberless" case, which are only  -->
<!-- primarily necessary for chapter-level items (eg "preface"),    -->
<!-- but might also occur due to one-count specialized divisions,   -->
<!-- present in "unstructured" divisions. "chapter" has a "display" -->
<!-- format, to mimic the LaTeX two-line look, even for multiline   -->
<!-- titles.  For finer divisions, when numbered, we use a "hang"   -->
<!-- format, so any extra lines begin aligned with the first line   -->
<!-- (whether they are authored-too long and then wtap, or if       -->
<!-- structured with a "line" element and so earning dedicated "\\" -->
<!-- automatically.  For "numberless" variants the "block" shape    -->
<!-- seems sufficient as there is no label.  If more elaborate      -->
<!-- styling is employed, it may be necessary to put titles into    -->
<!-- "minipage" environments, or other LaTex boxes                  -->
<!-- NB: since have elected to use the "explicit" package option    -->
<!-- of titlesec, we need to *explicity* place a parameter #1.      -->
<!-- This will allow maximum flexibility for style writers.         -->
<!-- Simple use (as here) will be as the last thing in the          -->
<!-- "before-code" argument.                                        -->
<!-- TODO: integrate "epigraph" package perhaps                     -->

<!-- Pretty much everything for actually manipulating titles -->
<!-- happens in the -common template. But when structured by -->
<!-- "line" we need to implement an abstract variable with a -->
<!-- separator string.                                       -->
<!-- NB: \\ works better than \newline in a \centering       -->
<xsl:variable name="title-separator" select="'\\'"/>

<!-- This is adapted from the chapter format, and   -->
<!-- could be simpler than desired, specifically    -->
<!--   * no "number-less" version                   -->
<!--   * no \titlespacing needed for full page      -->
<!--   * author placement is untested               -->
<!--   * otherwise, jut a bit grander, and centered -->
<!-- There must be a  \titleformat{\part}  to get   -->
<!-- consistent entries in the ToC files            -->
<xsl:template name="titlesec-part-style">
    <xsl:text>\titleformat{\part}[display]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\Huge\bfseries\centering}{\divisionnameptx\space\thepart}{30pt}{\Huge#1}&#xa;</xsl:text>
    <xsl:text>[{\Large\centering\authorsptx}]&#xa;</xsl:text>
</xsl:template>

<!-- Note the use of "\divisionnameptx" macro              -->
<!-- A multiline title should be fine in a "display" shape -->
<xsl:template name="titlesec-chapter-style">
    <xsl:text>\titleformat{\chapter}[display]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\huge\bfseries}{\divisionnameptx\space\thechapter}{20pt}{\Huge#1}&#xa;</xsl:text>
    <xsl:text>[{\Large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\chapter,numberless}[display]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\huge\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\Large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\chapter}{0pt}{50pt}{40pt}&#xa;</xsl:text>
</xsl:template>

<!-- Refences, and especially Index, are unnumbered -->
<!-- section-level items in the back matter         -->
<xsl:template name="titlesec-section-style">
    <xsl:text>\titleformat{\section}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\Large\bfseries}{\thesection}{1ex}{#1}&#xa;</xsl:text>
    <xsl:text>[{\large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\section,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\Large\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\large\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\section}{0pt}{3.5ex plus 1ex minus .2ex}{2.3ex plus .2ex}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="titlesec-subsection-style">
    <xsl:text>\titleformat{\subsection}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\large\bfseries}{\thesubsection}{1ex}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\subsection,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\large\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\subsection}{0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="titlesec-subsubsection-style">
    <xsl:text>\titleformat{\subsubsection}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{\thesubsubsection}{1em}{#1}&#xa;</xsl:text>
    <xsl:text>[{\small\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\subsubsection,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\subsubsection}{0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}&#xa;</xsl:text>
</xsl:template>

<!-- We stick with LaTeX names for the hierarchy, so "paragraph" is next. -->
<!-- This will be used for single (hence numberless only) specialized     -->
<!-- divisions (e.g. "exercises") contained within a PTX subsubsection.   -->
<xsl:template name="titlesec-paragraph-style">
    <xsl:text>\titleformat{\paragraph}[hang]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{\theparagraph}{1em}{#1}&#xa;</xsl:text>
    <xsl:text>[{\small\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titleformat{name=\paragraph,numberless}[block]&#xa;</xsl:text>
    <xsl:text>{\divisionfont\normalsize\bfseries}{}{0pt}{#1}&#xa;</xsl:text>
    <xsl:text>[{\normalsize\authorsptx}]&#xa;</xsl:text>
    <xsl:text>\titlespacing*{\paragraph}{0pt}{3.25ex plus 1ex minus .2ex}{1.5em}&#xa;</xsl:text>
</xsl:template>

<!-- ################# -->
<!-- Table of Contents -->
<!-- ################# -->

<!-- Like division headings, the entries of the Table of -->
<!-- Contents can be styled on a per-division basis      -->

<!-- As normally written into LaTeX's *.toc file, the Roman     -->
<!-- number/label is tightly bound to the title and so it       -->
<!-- would be  the "number-less" argument in control.  Instead, -->
<!-- we load the  titlesec  package with the "newparttoc"       -->
<!-- option and get ToC entries that use LaTeX's "\numberline"  -->
<!-- macro, and so look to  titlesec  as numbered divisions.    -->
<!-- Hence the formatting here is the numbered argument.        -->
<!--                                                            -->
<!-- We drop page numbers for the parts as being redundant,     -->
<!-- since there *must* be a chapter starting on the next page. -->
<xsl:template name="titletoc-part-style">
    <xsl:text>\titlecontents{part}%&#xa;</xsl:text>
    <xsl:text>[0pt]{\contentsmargin{0em}\addvspace{1pc}\contentsfont\bfseries}%&#xa;</xsl:text>
    <xsl:text>{\Large\thecontentslabel\enspace}{\Large}%&#xa;</xsl:text>
    <xsl:text>{}%&#xa;</xsl:text>
    <xsl:text>[\addvspace{.5pc}]%&#xa;</xsl:text>
</xsl:template>

<!-- This should be mostly self-explanatory -->
<xsl:template name="titletoc-chapter-style">
    <xsl:text>\titlecontents{chapter}%&#xa;</xsl:text>
    <xsl:text>[0pt]{\contentsmargin{0em}\addvspace{1pc}\contentsfont\bfseries}%&#xa;</xsl:text>
    <xsl:text>{\large\thecontentslabel\enspace}{\large}%&#xa;</xsl:text>
    <xsl:text>{\hfill\bfseries\thecontentspage}%&#xa;</xsl:text>
    <xsl:text>[\addvspace{.5pc}]%&#xa;</xsl:text>
</xsl:template>

<!-- The indent, and space for the number/label are straight  -->
<!-- from the  titletoc  documentation, which says they match -->
<!-- the LaTeX  book  class                                   -->
<xsl:template name="titletoc-section-style">
    <xsl:text>\dottedcontents{section}[3.8em]{\contentsfont}{2.3em}{1pc}%&#xa;</xsl:text>
</xsl:template>

<!-- The indent, and space for the number/label are straight  -->
<!-- from the  titletoc  documentation, which says they match -->
<!-- the LaTeX  book  class                                   -->
<xsl:template name="titletoc-subsection-style">
    <xsl:text>\dottedcontents{subsection}[6.1em]{\contentsfont}{3.2em}{1pc}%&#xa;</xsl:text>
</xsl:template>

<!-- Each successive indent is increased by the maximum width -->
<!-- of the preceding label, so we just continue that pattern -->
<xsl:template name="titletoc-subsubsection-style">
    <xsl:text>\dottedcontents{subsubsection}[9.3em]{\contentsfont}{4.3em}{1pc}%&#xa;</xsl:text>
</xsl:template>


<!-- ############################ -->
<!-- Page Styles, Headers/Footers -->
<!-- ############################ -->

<!-- These definitions are just default LaTeX.  Why?  To insert the    -->
<!-- \pagefont font-change command into just the right places          -->
<!-- (later we can add color).                                         -->
<!--                                                                   -->
<!-- In more general use, make new page styles, or renew the "empty",  -->
<!-- "plain", "headings", and/or "myheadings" styles.  *Always* finish -->
<!-- by declaring a \pagestyle to be in effect.  But note, LaTeX will  -->
<!-- automagically decide some pages are plain or some are empty.  And -->
<!-- if you adjust "headings" or "myheadings" by doing something like  -->
<!-- changing a font, you might want to also change "plain" so that    -->
<!-- the (presumably) simple numbers or other information will be in   -->
<!-- a matching font.                                                  -->

<!-- N.B. This would be a natural place for \geometry{} commands       -->
<!-- N.B. We use an XSL variable to make the LaTeX output specific to  -->
<!-- one-sided or two-sided output.  Conceivably this *could* be done  -->
<!-- with a LaTeX conditional (at the cost of extraneous code)         -->
<!-- NB: the \ifthechapter conditional stops a "Chapter 0"             -->
<!-- appearing in the front matter                                     -->
<!-- NB: titlesec (not titleps) provides \chaptertitlename so that the -->
<!-- LaTeX \chaptername and \appendixname (which we internationalize)  -->
<!-- are used in the right places                                      -->
<!-- N.B. Investigate the "textcase" package for a more capable        -->
<!-- "\MakeTextUppercase" (or similar)                                 -->
<!-- TODO: redefine article, memo, letter correctly                    -->
<xsl:template match="book" mode="titleps-style">
    <xsl:text>%% Plain pages should have the same font for page numbers&#xa;</xsl:text>
    <xsl:text>\renewpagestyle{plain}{%&#xa;</xsl:text>
    <xsl:text>\setfoot{}{\pagefont\thepage}{}%&#xa;</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$latex-sides = 'one'">
            <!-- Every "regular" page has number top right -->
            <!-- CHAPTER 8. TITLE                      234 -->
            <xsl:text>%% Single pages as in default LaTeX&#xa;</xsl:text>
            <xsl:text>\renewpagestyle{headings}{%&#xa;</xsl:text>
            <xsl:text>\sethead{\pagefont\slshape\MakeUppercase{\ifthechapter{\chaptertitlename\space\thechapter.\space}{}\chaptertitle}}{}{\pagefont\thepage}%&#xa;</xsl:text>
            <xsl:text>}%&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="$latex-sides = 'two'">
            <!-- Two-page spread:  (Section empty if not in use)           -->
            <!-- 234       CHAPTER 8. TITLE || SECTION 8.4 TITLE       235 -->
            <xsl:text>%% Two-page spread as in default LaTeX&#xa;</xsl:text>
            <xsl:text>\renewpagestyle{headings}{%&#xa;</xsl:text>
            <xsl:text>\sethead%&#xa;</xsl:text>
            <xsl:text>[\pagefont\thepage}][][\pagefont\slshape\MakeUppercase{\ifthechapter{\chaptertitlename\space\thechapter.\space}{}\chaptertitle}]%&#xa;</xsl:text>
            <xsl:text>{\pagefont\slshape\MakeUppercase{\ifthesection{\sectiontitlename\space\thesection.\space\sectiontitle}{}}}{}{\pagefont\thepage}}%&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>\pagestyle{headings}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="article|letter|memo" mode="titleps-style">
    <xsl:text>\pagestyle{plain}&#xa;</xsl:text>
</xsl:template>


<!-- ##### -->
<!-- Fonts -->
<!-- ##### -->

<!-- General notes:                                                   -->
<!--                                                                  -->
<!-- * Any preamble activity relative to fonts can be set here        -->
<!-- * A font which has a "T1" encoding is more modern than one       -->
<!--   with "OT1" encoding, and preferred                             -->
<!--   https://tex.stackexchange.com/questions/664/                   -->
<!--   https://tex.stackexchange.com/questions/108417/                -->
<!-- * We could assume everybody will use fonts with T1 encoding,     -->
<!--   but have instead allowed for flexibility, so be sure to        -->
<!--   include the \usepackage{fontenc} with an option for the        -->
<!--   default encoding                                               -->
<!-- * If the <, > characters become upside-down exclamation or       -->
<!--   question mark, then you have a problem with font-encoding      -->
<!--   https://tex.stackexchange.com/questions/2369/                  -->
<!-- * The LaTeX Font Catalogue is a good place to start and shows    -->
<!--   recommended commands.  That is all we have done here to obtain -->
<!--   Latin Modern (which seems to be universally recommended)       -->
<!--   http://www.tug.dk/FontCatalogue/                               -->
<!-- * Some math fonts are designed to be more harmonious             -->
<!--   with certain text fonts, do your research                      -->
<!-- * If you only use "\usepackage[T1]{fontenc}" then the            -->
<!--   CM-Super fonts will be loaded.  These work well, but           -->
<!--   are inferior to Latin Modern in some ways                      -->
<!--   http://tex.stackexchange.com/questions/88368/                  -->
<!--   https://tex.stackexchange.com/questions/1390/                  -->
<!-- * Check new fonts carefully for missing, or poorly created,      -->
<!--   glyphs.  The sample article can be useful for this.            -->
<!--   Also: search the LaTeX *.log file for the string               -->
<!--   "Missing character:" for further clues.                        -->

<xsl:template name="font-pdflatex-style">
    <!-- This is the default Latin Modern font/package -->
    <xsl:text>\usepackage{lmodern}&#xa;</xsl:text>
    <xsl:text>\usepackage[T1]{fontenc}&#xa;</xsl:text>
</xsl:template>

<!-- Experiment with different fonts: e.g., TeX Gyre Schola, Latin Modern Sans -->
<xsl:template name="font-xelatex-style">
    <!-- <xsl:text>\setmainfont{Latin Modern Roman}[Numbers=OldStyle]&#xa;</xsl:text> -->
    <!-- <xsl:text>\newfontfamily{\divisionfont}{Latin Modern Roman}[Numbers=Lining]&#xa;</xsl:text> -->
    <!-- <xsl:text>\newfontfamily{\contentsfont}{Latin Modern Roman}[Numbers=Lining]&#xa;</xsl:text> -->
    <!-- <xsl:text>\newfontfamily{\tabularfont}{Latin Modern Roman}[Numbers={Monospaced,Lining}]&#xa;</xsl:text> -->
</xsl:template>


<!-- ################## -->
<!-- End: LaTeX Styling -->
<!-- ################## -->

<!-- Tack in a graphic with initials                   -->
<!-- Height is just enough to not disrupt line spacing -->
<!-- Place inline, no carriage returns                 -->
<xsl:template match="initial">
  <xsl:text>\hspace*{-0.75ex}{}</xsl:text>
  <xsl:text>\raisebox{0.2\baselineskip}{\includegraphics[height=0.55\baselineskip]{</xsl:text>
  <xsl:apply-templates select="@source" />
  <xsl:text></xsl:text>
  <xsl:text>}}\hspace*{-0.75ex}{}</xsl:text>
</xsl:template>

<!-- Includes an "event" for presentations -->
<xsl:template name="title-page-info-article">
    <xsl:text>%% Title page information for article&#xa;</xsl:text>
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:if test="subtitle">
        <xsl:text>\\&#xa;</xsl:text>
        <!-- Trying to match author fontsize -->
        <xsl:text>{\large </xsl:text>
        <xsl:apply-templates select="." mode="subtitle" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="$docinfo/event">
        <xsl:if test="title">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="$docinfo/event" />
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="frontmatter/titlepage/author or frontmatter/titlepage/editor">
        <xsl:text>\author{</xsl:text>
        <xsl:apply-templates select="frontmatter/titlepage/author" mode="article-info"/>
        <xsl:apply-templates select="frontmatter/titlepage/editor" mode="article-info"/>
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\date{</xsl:text><xsl:apply-templates select="frontmatter/titlepage/date" /><xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- "half-title" is leading page with -->
<!-- title only, at about 1:2 split    -->
<xsl:template match="book" mode="half-title" >
    <xsl:text>%% begin: half-title&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>{\centering&#xa;</xsl:text>
    <xsl:text>\vspace*{0.28\textheight}&#xa;</xsl:text>
    <xsl:text>{\Huge </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}\\</xsl:text> <!-- always end line inside centering -->
    <xsl:if test="subtitle">
        <xsl:text>[2\baselineskip]&#xa;</xsl:text> <!-- extend line break if subtitle -->
        <xsl:text>{\LARGE </xsl:text>
        <xsl:apply-templates select="." mode="subtitle"/>
        <xsl:text>}\\&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text> <!-- finish centering -->
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   half-title&#xa;</xsl:text>
</xsl:template>

<!-- Ad card may contain list of other books        -->
<!-- Or may be overridden to make title page spread -->
<!-- Obverse of half-title                          -->
<xsl:template match="book" mode="ad-card">
    <xsl:text>%% begin: adcard&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\null%&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   adcard&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX's title page is not very robust, so we totally redo it         -->
<!-- Template produces a single page, followed by a \clearpage            -->
<!-- Customize with an override of this template in an imported stylesheet -->
<!-- For a two-page spread, consider modifying the "ad-card" template     -->
<!-- For "\centering" to work properly, obey the following scheme:              -->
<!-- Each group, but first, should begin with [<length>]&#xa; as vertical break -->
<!-- Each group, should end with only \\ as prelude to vertical break           -->
<xsl:template match="book" mode="title-page">
    <xsl:text>%% begin: title page&#xa;</xsl:text>
    <xsl:text>%% Inspired by Peter Wilson's "titleDB" in "titlepages" CTAN package&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>{\centering&#xa;</xsl:text>
    <xsl:text>\vspace*{0.14\textheight}&#xa;</xsl:text>
    <!-- Target for xref to top-level element -->
    <!-- immediately, or first in ToC         -->
    <xsl:choose>
        <xsl:when test="$b-has-toc">
            <!-- N.B.  A font change command for the entire ToC -->
            <!-- could be inserted here with something like     -->
            <!--   \addtocontents{toc}{\protect\contentsfont}   -->
            <!-- but I wanted to document it in place and could -->
            <!-- not determine how to add a comment into the    -->
            <!-- *.toc file.  Perhaps best to just employ the   -->
            <!-- font in the  titletoc  style templates anyway. -->
            <xsl:text>%% Target for xref to top-level element is ToC&#xa;</xsl:text>
            <xsl:text>\addtocontents{toc}{</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\protect\label{</xsl:text>
                <xsl:apply-templates select="." mode="latex-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\protect\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id" />
            <xsl:text>}{}</xsl:text>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>%% Target for xref to top-level element is document start&#xa;</xsl:text>
            <xsl:if test="$b-pageref">
                <xsl:text>\label{</xsl:text>
                <xsl:apply-templates select="." mode="latex-id" />
                <xsl:text>}</xsl:text>
            </xsl:if>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id" />
            <xsl:text>}{}&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{\Huge </xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}\\</xsl:text> <!-- end line inside centering -->
    <xsl:if test="subtitle">
        <xsl:text>[\baselineskip]&#xa;</xsl:text>  <!-- extend if subtitle -->
        <xsl:text>{\LARGE </xsl:text>
        <xsl:apply-templates select="." mode="subtitle" />
        <xsl:text>}\\</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="frontmatter/titlepage/author" mode="title-page"/>
    <xsl:apply-templates select="frontmatter/titlepage/editor" mode="title-page" />
    <xsl:apply-templates select="frontmatter/titlepage/credit" mode="title-page" />
    <xsl:apply-templates select="frontmatter/titlepage/date"   mode="title-page" />
    <xsl:text>}&#xa;</xsl:text> <!-- finish centering -->
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   title page&#xa;</xsl:text>
</xsl:template>

<xsl:template match="author|editor" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:if test="self::editor">
        <xsl:text>, </xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'editor'" />
        </xsl:call-template>
    </xsl:if>
    <xsl:text>}\\</xsl:text>
    <xsl:if test="institution">
        <xsl:text>[0.5\baselineskip]&#xa;</xsl:text>
        <xsl:text>{\Large </xsl:text>
        <xsl:apply-templates select="institution" />
        <xsl:text>}\\</xsl:text>
    </xsl:if>
</xsl:template>

<!-- One "title" per-credit, but multiple authors are OK -->
<xsl:template match="credit" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates  select="." mode="title-full" />
    <xsl:text>}\\[0.5\baselineskip]&#xa;</xsl:text>
    <xsl:for-each select="author">
        <xsl:text>{\normalsize </xsl:text>
        <xsl:apply-templates select="personname" />
        <xsl:text>}\\</xsl:text>
        <xsl:if test="institution">
            <xsl:text>[0.25\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="institution" />
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:if test="following-sibling::author">
            <xsl:text>[0.5\baselineskip]&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
</xsl:template>

<xsl:template match="date" mode="title-page">
    <xsl:text>[3\baselineskip]&#xa;</xsl:text>
    <xsl:text>{\Large </xsl:text>
    <xsl:apply-templates />
    <xsl:text>}\\</xsl:text>
</xsl:template>

<!-- Copyright page is obverse of title page  -->
<!-- Lots of stuff here, much of it optional  -->
<!-- But we always write something            -->
<!-- as the obverse of title page             -->
<xsl:template match="book" mode="copyright-page" >
    <!-- TODO: split out sections like "website" -->
    <!-- ISBN, Cover Design, Publisher -->
    <xsl:text>%% begin: copyright-page&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <!-- This is the most obvious place for   -->
    <!-- a target to the front colophon       -->
    <!-- NB: only a book has a front colophon -->
    <xsl:apply-templates select="frontmatter/colophon" mode="label" />
    <xsl:if test="not(../docinfo/author-biographies/@length = 'long')">
        <xsl:apply-templates select="frontmatter/biography" mode="copyright-page" />
    </xsl:if>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>

    <xsl:if test="frontmatter/colophon/credit">
        <xsl:text>\par\noindent&#xa;</xsl:text>
    </xsl:if>
    <xsl:for-each select="frontmatter/colophon/credit">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates select="role" />
        <xsl:text>}:\ \ </xsl:text>
        <xsl:apply-templates select="entity" />
        <xsl:if test="following-sibling::credit">
            <xsl:text>\\</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
    <xsl:if test="frontmatter/colophon/credit">
        <xsl:text>\par\vspace*{\stretch{2}}&#xa;</xsl:text>
    </xsl:if>

    <xsl:if test="frontmatter/colophon/edition" >
        <xsl:text>\noindent{\bfseries </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/edition" mode="type-name" />
        <xsl:text>}: </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/edition" />
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:if>

    <xsl:if test="frontmatter/colophon/website" >
        <xsl:text>\noindent{\bfseries </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/website" mode="type-name" />
        <xsl:text>}: </xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/website" />
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:if>

    <xsl:if test="frontmatter/colophon/copyright" >
        <xsl:text>\noindent</xsl:text>
        <xsl:call-template name="copyright-character"/>
        <xsl:apply-templates select="frontmatter/colophon/copyright/year" />
        <xsl:text>\quad{}</xsl:text>
        <xsl:apply-templates select="frontmatter/colophon/copyright/holder" />
        <xsl:if test="frontmatter/colophon/copyright/shortlicense">
            <xsl:text>\\[0.5\baselineskip]&#xa;</xsl:text>
            <xsl:apply-templates select="frontmatter/colophon/copyright/shortlicense" />
        </xsl:if>
        <xsl:text>\par\medskip&#xa;</xsl:text>
    </xsl:if>

    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <!-- Something so page is not totally nothing -->
    <xsl:text>\null\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   copyright-page&#xa;</xsl:text>
</xsl:template>

<!-- URL for canonical project website -->
<xsl:template match="frontmatter/colophon/website" >
    <xsl:text>\href{</xsl:text>
    <xsl:apply-templates select="address" />
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="name" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Author biographies -->
<!-- Verso of title page, we call this the front colophon -->
<!-- Title is optional, presumably for a single author    -->
<xsl:template match="biography" mode="copyright-page">
    <xsl:if test="preceding-sibling::*[self::biography]">
        <xsl:text>\bigskip</xsl:text>
    </xsl:if>
    <xsl:text>\noindent</xsl:text>
    <xsl:if test="title">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}\space\space</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates/>
    <!-- drop a par, for next bio, or for big vspace -->
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<!-- Authors, editors, info for article info to \maketitle -->
<!-- http://stackoverflow.com/questions/2817664/xsl-how-to-tell-if-element-is-last-in-series -->
<xsl:template match="author" mode="article-info">
    <xsl:apply-templates select="personname" />
    <xsl:if test="department">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="department" />
    </xsl:if>
    <xsl:if test="institution">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="institution" />
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="email" />
    </xsl:if>
    <xsl:if test="position() != last()" >
        <xsl:text>&#xa;\and</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="editor" mode="article-info">
    <xsl:apply-templates select="personname" />
    <xsl:text>, </xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'editor'" />
    </xsl:call-template>
    <xsl:if test="department">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="department" />
    </xsl:if>
    <xsl:if test="institution">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="institution" />
    </xsl:if>
    <xsl:if test="email">
        <xsl:text>\\&#xa;</xsl:text>
        <xsl:apply-templates select="email" />
    </xsl:if>
    <xsl:if test="position() != last()" >
        <xsl:text>&#xa;\and</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>


<!-- Departments and Institutions are free-form, or sequences of lines -->
<!-- Line breaks are inserted above, due to \and, etc,                 -->
<!-- so do not end last line here                                      -->
<xsl:template match="department|institution">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="department[line]|institution[line]">
    <xsl:apply-templates select="line" />
</xsl:template>

<!-- ###################### -->
<!-- Front Matter, Articles -->
<!-- ###################### -->

<!-- The DTD should enforce order(titlepage|abstract) -->
<!-- An optional ToC follows and is final decoration  -->
<xsl:template match="article/frontmatter">
    <xsl:apply-templates select="titlepage|abstract" />
    <xsl:if test="$latex-toc-level > 0">
        <xsl:text>%% Adjust Table of Contents&#xa;</xsl:text>
        <xsl:text>\setcounter{tocdepth}{</xsl:text>
        <xsl:value-of select="$latex-toc-level" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\contentsname{</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'toc'" />
        </xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
        <xsl:text>\clearpage&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Title information handling is a bit ad-hoc                        -->
<!-- We should perhaps roll-our-own here                               -->
<!-- Instead we assume the title-page-info-article has set *something* -->
<!-- NB: it is possible for there to be no article/title               -->
<xsl:template match="article/frontmatter/titlepage">
    <xsl:text>\maketitle&#xa;</xsl:text>
    <!-- If a title, we know it is page 1, so use empty style -->
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
</xsl:template>

<!-- Articles may have an abstract in the frontmatter -->
<xsl:template match="article/frontmatter/abstract">
    <xsl:text>\begin{abstract}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{abstract}&#xa;</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- Front Matter, Books -->
<!-- ################### -->

<!-- The <colophon> portion of <frontmatter> generally  -->
<!-- gets mined to migrate various places, so we kill   -->
<!-- it as part of processing the front matter element. -->
<!-- Author biography migrates to the obverse of the    -->
<!-- copyright page in LaTeX, sans any provided title.  -->
<!-- So we kill this part of the front matter as        -->
<!-- a section of its own.  (In HTML the material       -->
<!-- is its own titled division).                       -->
<xsl:template match="book/frontmatter">
    <!-- DTD: does the next line presume <frontmatter> is required? -->
    <xsl:text>\frontmatter&#xa;</xsl:text>
    <xsl:call-template name="front-cover"/>
    <xsl:apply-templates select="*[not(self::colophon or self::biography)]" />
    <xsl:text>%% begin: table of contents&#xa;</xsl:text>
    <xsl:if test="$latex-toc-level > -1">
        <xsl:text>%% Adjust Table of Contents&#xa;</xsl:text>
        <xsl:text>\setcounter{tocdepth}{</xsl:text>
        <xsl:value-of select="$latex-toc-level" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\renewcommand*\contentsname{</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'toc'" />
        </xsl:call-template>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>\tableofcontents&#xa;</xsl:text>
        <xsl:text>%% end:   table of contents&#xa;</xsl:text>
    </xsl:if>
    <!-- Potentially: list of illustrations, etc.     -->
    <!-- Potentially: introduction, second half-title -->
    <!-- if we have a \frontmatter, we must end it with \mainmatter -->
    <xsl:text>\mainmatter&#xa;</xsl:text>
</xsl:template>

<!-- A huge decoration, spanning many pages             -->
<!-- Not structural, titlepage element is just a signal -->
<!-- Includes items from the colophon                   -->
<xsl:template match="book/frontmatter/titlepage">
    <!-- first page, title only -->
    <xsl:apply-templates select="../.." mode="half-title" />
    <!-- Obverse of half-title is adcard -->
    <xsl:apply-templates select="../.." mode="ad-card" />
    <!-- title page -->
    <xsl:apply-templates select="../.." mode="title-page" />
    <!-- title page obverse is copyright, possibly empty -->
    <xsl:apply-templates select="../.." mode="copyright-page" />
    <!-- long biographies come earliest, since normally on copyright page -->
    <!-- short biographies are part of the copyright-page template        -->
    <xsl:if test="$docinfo/author-biographies/@length = 'long' and ../biography">
        <xsl:apply-templates select="../.." mode="author-biography-subdivision" />
    </xsl:if>
</xsl:template>

<xsl:template match="book" mode="author-biography-subdivision">
    <xsl:variable name="number-authors" select="count(frontmatter/biography)" />
    <xsl:variable name="title-string">
        <xsl:choose>
            <xsl:when test="$number-authors > 1">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'about-authors'" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'about-author'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>%% begin: author biography (long)&#xa;</xsl:text>
    <xsl:text>\chapter*{</xsl:text>
    <xsl:value-of select="$title-string" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\addcontentsline{toc}{chapter}{</xsl:text>
    <xsl:value-of select="$title-string" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="$number-authors > 1">
            <xsl:apply-templates select="frontmatter/biography" mode="biography-subdivision" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="frontmatter/biography/title">
                <xsl:text>\section*{</xsl:text>
                <xsl:apply-templates select="frontmatter/biography" mode="title-full" />
                <xsl:text>}&#xa;</xsl:text>
            </xsl:if>
            <!-- else don't bother titling-->
            <xsl:apply-templates select="frontmatter/biography/*" />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\cleardoublepage</xsl:text>
    <xsl:text>%% end: author biography (long)&#xa;</xsl:text>
</xsl:template>

<xsl:template match="biography" mode="biography-subdivision">
    <xsl:text>\section*{</xsl:text>
    <xsl:choose>
        <xsl:when test="title">
            <xsl:apply-templates select="." mode="title-full" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>DEFAULT TO FULL NAME HERE</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates/>
</xsl:template>

<!-- Dedication page is very plain, with a blank obverse     -->
<!-- Accomodates multiple recipient (eg if multiple authors) -->
<xsl:template match="dedication">
    <xsl:text>%% begin: dedication-page&#xa;</xsl:text>
    <xsl:text>\cleardoublepage&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <!-- paragraphs only, one per dedication -->
    <xsl:apply-templates select="p"/>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   dedication-page&#xa;</xsl:text>
    <xsl:text>%% begin: obverse-dedication-page (empty)&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\null%&#xa;</xsl:text>
    <xsl:text>\clearpage&#xa;</xsl:text>
    <xsl:text>%% end:   obverse-dedication-page&#xa;</xsl:text>
</xsl:template>

<!-- Dedications are meant to be very short      -->
<!-- so are each a single paragraph and          -->
<!-- are centered on a page of their own         -->
<!-- The center environment provides good        -->
<!-- vertical break between multiple instances   -->
<!-- Each "p" may be structured by "line"        -->
<!-- The p[1] elsewhere is the default,          -->
<!-- hence we use the priority mechanism (>0.5)  -->
<xsl:template match="dedication/p|dedication/p[1]" priority="1">
    <xsl:text>\begin{center}\Large%&#xa;</xsl:text>
        <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\end{center}&#xa;</xsl:text>
</xsl:template>

<!-- ##################### -->
<!-- Front Matter, Letters -->
<!-- ##################### -->

<xsl:template match="letter/frontmatter">
    <!-- Logos (letterhead images) immediately -->
    <xsl:apply-templates select="$docinfo/logo" />
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\thispagestyle{empty}&#xa;</xsl:text>
    <!-- Push down some on first page to accomodate letterhead -->
    <xsl:text>\vspace*{0.75in}&#xa;</xsl:text>
    <!-- Stretchy vertical space if page 1 does not fill -->
    <xsl:text>\vspace*{\stretch{1}}&#xa;%&#xa;</xsl:text>
    <!-- Sender's address, sans name typically -->
    <!-- and if not already on letterhead      -->
    <!-- Structured as lines, always           -->
    <!-- http://tex.stackexchange.com/questions/13542/flush-a-left-flushed-box-right -->
    <xsl:if test="from or date">
        <xsl:text>\hfill\begin{tabular}{l@{}}&#xa;</xsl:text>
        <xsl:if test="from">
            <xsl:apply-templates select="from/line" />
            <xsl:if test="date">
                <!-- end from -->
                <xsl:text>\\&#xa;</xsl:text>
                <!-- introduce a blank line -->
                <xsl:text>\mbox{}\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <!-- Date -->
        <xsl:if test="date">
            <xsl:apply-templates select="date" />
        </xsl:if>
        <xsl:text>&#xa;\end{tabular}\\\par&#xa;</xsl:text>
    </xsl:if>
    <!-- Destination address, flush left -->
    <!-- Structured as lines, always     -->
    <xsl:if test="to">
        <xsl:text>\noindent{}</xsl:text>
        <xsl:apply-templates select="to/line" />
        <xsl:text>\\\par</xsl:text>
        <!-- extra comment line before salutation/body -->
        <xsl:text>&#xa;%&#xa;</xsl:text>
    </xsl:if>
    <!-- Salutation, flush left                   -->
    <!-- No punctuation (author's responsibility) -->
    <xsl:if test="salutation">
        <xsl:text>\noindent{}</xsl:text>
        <xsl:apply-templates select="salutation" />
        <xsl:text>\\\par</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Final lines of from/to address get treated carefully above -->
<!-- Differentiate from memo versions                           -->
<xsl:template match="letter/frontmatter/from/line|letter/frontmatter/to/line">
    <xsl:apply-templates />
    <!-- is there a following line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ################### -->
<!-- Front Matter, Memos -->
<!-- ################### -->

<xsl:template match="memo/frontmatter">
    <xsl:text>\thispagestyle{empty}&#xa;%&#xa;</xsl:text>
    <!-- Logos (letterhead images) to first page -->
    <xsl:apply-templates select="$docinfo/logo" />
    <!-- Get width of widest out-dented text -->
    <xsl:text>\newlength{\subjectwidth}&#xa;</xsl:text>
    <xsl:text>\settowidth{\subjectwidth}{\textsf{Subject:}}&#xa;</xsl:text>
    <!-- Push down some on first page to accomodate letterhead -->
    <xsl:text>\vspace*{0.75in}&#xa;</xsl:text>
    <!-- Outdent experimentally, scales well at 10pt, 11pt, 12pt -->
    <!-- Control separation                                      -->
    <xsl:text>\hspace*{-1.87\subjectwidth}%&#xa;</xsl:text>
    <xsl:text>{\setlength{\tabcolsep}{1ex}%&#xa;</xsl:text>
    <!-- Second column at textwidth is slightly too much -->
    <xsl:text>\begin{tabular}{rp{0.97\textwidth}}&#xa;</xsl:text>
    <xsl:text>\textsf{To:}</xsl:text>
    <xsl:choose>
        <!-- multiline structured -->
        <xsl:when test="to/line">
            <xsl:apply-templates select="to/line" />
        </xsl:when>
        <!-- always a newline, even if blank -->
        <xsl:otherwise>
            <xsl:text>&amp;</xsl:text>
            <xsl:apply-templates select="to" />
            <xsl:text>\\&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\textsf{From:}</xsl:text>
    <xsl:choose>
        <!-- multiline structured -->
        <xsl:when test="from/line">
            <xsl:apply-templates select="from/line" />
        </xsl:when>
        <!-- always a newline, even if blank -->
        <xsl:otherwise>
            <xsl:text>&amp;</xsl:text>
            <xsl:apply-templates select="from" />
            <xsl:text>\\&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\textsf{Date:}&amp;</xsl:text>
    <xsl:apply-templates select="date" /><xsl:text>\\&#xa;</xsl:text>
    <xsl:text>\textsf{Subject:}&amp;</xsl:text>
    <xsl:apply-templates select="subject" /><xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{tabular}%&#xa;</xsl:text>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- And drop a bit -->
    <xsl:text>\par\bigskip&#xa;</xsl:text>
</xsl:template>

<!-- Differentiate from letter versions -->
<xsl:template match="memo/frontmatter/from/line|memo/frontmatter/to/line">
    <xsl:text>&amp;</xsl:text>
    <xsl:apply-templates />
    <!-- part of a big block, use newline everywhere -->
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Back Matter -->
<!-- ############ -->

<!-- <backmatter> is structural -->
<!-- Noted in an book           -->
<!-- But not in an article      -->
<xsl:template match="article/backmatter">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="book/backmatter">
    <!-- If no appendices, go straight to book backmatter,      -->
    <!-- which automatically produces divisions with no numbers -->
    <!-- Otherwise \appendix,...\backmatter is handled in the   -->
    <!-- template for general subdivisions                      -->
    <xsl:if test="ancestor::book and not(appendix)">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\backmatter&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <!-- Some vertical separation into backmatter contents is useful -->
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>%% A lineskip in table of contents as transition to appendices, backmatter&#xa;</xsl:text>
    <xsl:text>\addtocontents{toc}{\vspace{\normalbaselineskip}}&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- The back colophon of a book goes on its own recto page -->
<!-- The "backcolophon" environment is a tcolorbox          -->
<xsl:template match="book/backmatter/colophon">
    <xsl:text>\cleardoublepage&#xa;</xsl:text>
    <xsl:text>\pagestyle{empty}&#xa;</xsl:text>
    <xsl:text>\vspace*{\stretch{1}}&#xa;</xsl:text>
    <xsl:text>\begin{backcolophon}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{backcolophon}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
    <xsl:text>\vspace*{\stretch{2}}&#xa;</xsl:text>
</xsl:template>

<!-- The back colophon of an article is simpler -->
<xsl:template match="article/backmatter/colophon">
    <xsl:text>\begin{backcolophon}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{backcolophon}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Appendices are handled in the general subdivision template -->

<!-- The index itself needs special handling    -->
<!-- The "index-part" element signals an index, -->
<!-- and the content is just an optional title  -->
<!-- and a compulsory "index-list"              -->
<!-- LaTeX does sectioning via \printindex      -->
<!-- TODO: multiple indices, with different titles -->
<xsl:template match="index-part|index[index-list]">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="index-list">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>%% The index is here, setup is all in preamble&#xa;</xsl:text>
    <xsl:text>\printindex&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!--               -->
<!-- Notation List -->
<!--               -->

<!-- At location, we just drop a marker to get the page number -->
<xsl:template match="notation">
    <xsl:apply-templates select="." mode="label" />
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Deccription column is "p" to enable word-wrapping  -->
<!-- The 60% width is arbitrary, could see improvements -->
<!-- This is not a PreTeXt "table" so we don't let      -->
<!-- LaTeX number it, nor increment the table counter   -->
<xsl:template match="notation-list">
    <xsl:text>\begin{longtable}[l]{lp{0.60\textwidth}r}&#xa;</xsl:text>
    <xsl:text>\addtocounter{table}{-1}&#xa;</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'symbol'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'description'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'page'" />
    </xsl:call-template>
    <xsl:text>}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endfirsthead&#xa;</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'symbol'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'description'" />
    </xsl:call-template>
    <xsl:text>}&amp;\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'page'" />
    </xsl:call-template>
    <xsl:text>}\\[1em]&#xa;</xsl:text>
    <xsl:text>\endhead&#xa;</xsl:text>
    <xsl:text>\multicolumn{3}{r}{(</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'continued'" />
    </xsl:call-template>
    <xsl:text>)}\\&#xa;</xsl:text>
    <xsl:text>\endfoot&#xa;</xsl:text>
    <xsl:text>\endlastfoot&#xa;</xsl:text>
    <xsl:apply-templates select="$document-root//notation" mode="backmatter" />
    <xsl:text>\end{longtable}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="notation" mode="backmatter">
    <xsl:text>\(</xsl:text>
    <!-- "usage" should be raw latex, so -->
    <!-- should avoid text processing    -->
    <xsl:value-of select="usage" />
    <xsl:text>\)</xsl:text>
    <xsl:text>&amp;</xsl:text>
    <xsl:apply-templates select="description" />
    <xsl:text>&amp;</xsl:text>
    <xsl:text>\pageref{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ####################################### -->
<!-- Solutions Divisions, Content Generation -->
<!-- ####################################### -->

<!-- We pass in the "scope", which will be a traditional division   -->
<!-- and then can create an appropriate size for a heading (without -->
<!-- needing to deal with specialized divisions possibly appearing  -->
<!-- at most any level).                                            -->
<!-- "book" and "article" need to be in the match so this template  -->
<!-- is defined for those top-level (whole document) cases, even if -->
<!-- $b-has-heading will always be "false" in these situations.     -->
<!-- TODO: this could be an xparse environment, perhaps -->
<!-- with a key indicating fontsize or division level   -->
<xsl:template match="book|article|chapter|section|subsection|subsubsection|exercises|worksheet|reading-questions" mode="division-in-solutions">
    <xsl:param name="scope" />
    <xsl:param name="b-has-heading"/>
    <xsl:param name="content" />
    <!-- Usually we create an automatic heading,  -->
    <!-- but not at the root division -->
    <xsl:if test="$b-has-heading">
        <xsl:variable name="font-size">
            <xsl:choose>
                <!-- backmatter placement gets appendix like chapter -->
                <xsl:when test="$scope/self::book">
                    <xsl:text>\Large</xsl:text>
                </xsl:when>
                <!-- backmatter placement gets appendix like section -->
                <xsl:when test="$scope/self::article">
                    <xsl:text>\large</xsl:text>
                </xsl:when>
                <!-- divisional placement is one level less -->
                <xsl:when test="$scope/self::chapter">
                    <xsl:text>\Large</xsl:text>
                </xsl:when>
                <xsl:when test="$scope/self::section">
                    <xsl:text>\large</xsl:text>
                </xsl:when>
                <xsl:when test="$scope/self::subsection">
                    <xsl:text>\normalsize</xsl:text>
                </xsl:when>
                <xsl:when test="$scope/self::subsubsection">
                    <xsl:text>\normalsize</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:BUG:     "solutions" division title does not have a font size</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Does the current division get a number at birth? -->
        <xsl:variable name="is-structured">
            <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
        </xsl:variable>
        <xsl:variable name="b-is-structured" select="$is-structured = 'true'"/>

        <!-- LaTeX heading, possibly with hard-coded number -->
        <xsl:text>\par\smallskip&#xa;\noindent\textbf{</xsl:text>
        <xsl:value-of select="$font-size" />
        <!-- A structured division has numbered subdivisions              -->
        <!-- Otherwise "exercises" do not display their number at "birth" -->
        <xsl:if test="$b-is-structured">
            <xsl:text>{}</xsl:text>
            <xsl:apply-templates select="." mode="number" />
            <xsl:text>\space</xsl:text>
        </xsl:if>
        <xsl:text>\textperiodcentered\space{}</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}&#xa;\par\smallskip&#xa;</xsl:text>
    </xsl:if>
    <xsl:copy-of select="$content" />
</xsl:template>

<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/mathbook-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks, for long table,        -->
<!-- two columns and just "continued" adornment       -->
<!-- This is not a PreTeXt "table" so we don't let    -->
<!-- LaTeX number it, nor increment the table counter -->
<xsl:template name="list-of-begin">
    <xsl:text>\noindent&#xa;</xsl:text>
    <xsl:text>\begin{longtable}[l]{ll}&#xa;</xsl:text>
    <xsl:text>\addtocounter{table}{-1}&#xa;</xsl:text>
    <xsl:text>\endfirsthead&#xa;</xsl:text>
    <xsl:text>\endhead&#xa;</xsl:text>
    <xsl:text>\multicolumn{2}{r}{(</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'continued'" />
    </xsl:call-template>
    <xsl:text>)}\\&#xa;</xsl:text>
    <xsl:text>\endfoot&#xa;</xsl:text>
    <xsl:text>\endlastfoot&#xa;</xsl:text>
</xsl:template>

<!-- Done -->
<xsl:template name="list-of-end">
    <xsl:text>\end{longtable}&#xa;</xsl:text>
</xsl:template>

<!-- Some insulating space around headings    -->
<!-- All in one, so not part of table columns -->
<xsl:template match="*" mode="list-of-header">
    <xsl:text>\multicolumn{2}{l}{\null}\\[1.5ex] </xsl:text>
    <xsl:text>\multicolumn{2}{l}{\large </xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}\\[0.5ex]&#xa;</xsl:text>
</xsl:template>

<!-- Hyperlink with type, number, then a title -->
<!-- TODO: xref-link's select is a fiction and may lead to  bugs -->
<xsl:template match="*" mode="list-of-element">
    <xsl:apply-templates select="." mode="xref-link">
        <xsl:with-param name="target" select="." />
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="number" />
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- title plain, separated             -->
    <!-- xref version, no additional period -->
    <xsl:text>&amp;</xsl:text>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-xref"/>
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Contributor List -->
<!-- ################ -->

<xsl:template match="contributors">
    <!-- <xsl:text>\par\bigskip&#xa;</xsl:text> -->
    <xsl:text>\begin{multicols}{2}&#xa;</xsl:text>
    <xsl:apply-templates select="contributor" />
    <xsl:text>\end{multicols}&#xa;</xsl:text>
</xsl:template>

<!-- label works best before *anything* happens -->
<!-- tested for first name in second column     -->
<xsl:template match="contributor">
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\contributor{</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\contributorname{</xsl:text>
    <xsl:apply-templates select="personname" />
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:if test="department|institution|email">
        <xsl:text>\contributorinfo{</xsl:text>
        <xsl:if test="department">
            <xsl:apply-templates select="department" />
            <xsl:if test="department/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="institution">
            <xsl:apply-templates select="institution" />
            <xsl:if test="institution/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="location">
            <xsl:apply-templates select="location" />
            <xsl:if test="location/following-sibling::*">
                <xsl:text>\\&#xa;</xsl:text>
            </xsl:if>
        </xsl:if>
        <xsl:if test="email">
            <!-- switch to node-set with "c" if characters need escaping -->
            <xsl:text>\mono{</xsl:text>
            <xsl:apply-templates select="email" />
            <xsl:text>}</xsl:text>
        </xsl:if>
        <xsl:text>}%&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>


<!-- #################### -->
<!-- Back Matter, Letters -->
<!-- #################### -->

<xsl:template match="letter/backmatter">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="closing">
        <xsl:text>\par&#xa;</xsl:text>
        <xsl:text>\vspace*{1.5\baselineskip}\noindent&#xa;</xsl:text>
        <xsl:text>\hspace{\stretch{2}}&#xa;</xsl:text>
        <xsl:text>\begin{tabular}{l@{}}&#xa;</xsl:text>
        <xsl:apply-templates select="closing" />
        <xsl:choose>
            <xsl:when test="graphic-signature">
                <xsl:text>\\[1ex]&#xa;</xsl:text>
                <xsl:text>\includegraphics[height=</xsl:text>
                <xsl:choose>
                    <xsl:when test="graphic-signature/@height">
                        <xsl:value-of select="graphic-signature/@height" />
                    </xsl:when>
                    <xsl:otherwise>24pt</xsl:otherwise>
                </xsl:choose>
                <xsl:text>]{</xsl:text>
                <xsl:value-of select="graphic-signature/@source" />
                <xsl:text>}\\[0.5ex]&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- About two blank lines for written signature -->
                <xsl:text>\\[5.5ex]&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="signature/line" />
        <xsl:text>&#xa;\end{tabular}&#xa;</xsl:text>
        <xsl:text>\hspace{\stretch{1}}&#xa;</xsl:text>
    </xsl:if>
    <!-- Stretchy vertical space, useful if still on page 1 -->
    <xsl:text>\par\vspace*{\stretch{2}}&#xa;%&#xa;</xsl:text>
</xsl:template>

<!-- Final line of signature get treated carefully above -->
<xsl:template match="signature/line">
    <xsl:apply-templates />
    <!-- is there a following line to separate? -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ################## -->
<!-- Back Matter, Memos -->
<!-- ################## -->

<!-- No such thing yet                -->
<!-- TODO: add "cc" block like to/from -->
<xsl:template match="memo/backmatter" />


<!-- ####################### -->
<!-- Logos (image placements) -->
<!-- ####################### -->

<!-- Fine-grained placement of graphics files on pages      -->
<!-- May be placed anywhere on current page                 -->
<!-- Page coordinates are measured in "true" points         -->
<!-- (72.27 points to the inch)                             -->
<!-- (0,0) is the lower left corner of the page             -->
<!-- llx, lly: places lower-left corner of graphic          -->
<!-- at the specified coordinates of the page               -->
<!-- Use width, in fixed units (eg cm), to optionally scale -->
<!-- pages='first|all' controls repetition, default: first  -->
<xsl:template match="docinfo/logo" >
    <xsl:text>\AddToShipoutPicture</xsl:text>
    <xsl:if test="not(@pages) or @pages='first'">
        <xsl:text>*</xsl:text>
    </xsl:if>
    <xsl:text>{\put(</xsl:text>
    <xsl:value-of select="@llx" />
    <xsl:text>,</xsl:text>
    <xsl:value-of select="@lly" />
    <xsl:text>){\includegraphics</xsl:text>
    <xsl:if test="@width">
        <xsl:text>[width=</xsl:text>
            <xsl:value-of select="@width" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="@source" />
    <xsl:text>}}}&#xa;</xsl:text>
</xsl:template>


<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Divisions, "part" to "subsubsection", and specialized -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|exercises|worksheet|reading-questions|solutions|glossary|references">
    <!-- appendices are peers of chapters (book) or sections (article)  -->
    <!-- so we need to slip this in first, with book's \backmatter later-->
    <!-- NB: if no appendices, the backmatter template does \backmatter -->
    <xsl:apply-templates select="." mode="console-typeout" />
    <xsl:apply-templates select="." mode="begin-language" />
    <!-- To make LaTeX produce "lettered" appendices we issue the \appendix -->
    <!-- macro prior to the first to the first "appendix" or backmatter/solutions.                            -->
    <xsl:if test="(self::appendix or self::solutions[parent::backmatter]) and not(preceding-sibling::appendix|preceding-sibling::solutions)">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\appendix&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="latex-division-heading" />
    <!-- Process the contents, title, idx killed, but avoid author -->
    <!-- "solutions" content needs to call content generator       -->
    <xsl:choose>
        <xsl:when test="self::solutions">
            <xsl:apply-templates select="." mode="solutions" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="." mode="latex-division-footing" />
    <xsl:apply-templates select="." mode="end-language" />
    <!-- transition to LaTeX's book backmatter, which is not -->
    <!-- our backmatter: identify last appendix or solutions  -->
    <xsl:if test="ancestor::book and ancestor::backmatter and (self::appendix or self::solutions) and not(following-sibling::appendix or following-sibling::solutions)">
        <xsl:text>%&#xa;</xsl:text>
        <xsl:text>\backmatter&#xa;</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Information to console for latex run -->
<!-- Generally these precede structural divisions, so some -->
<!-- nearly-blank lines provide some visual organization   -->
<xsl:template match="*" mode="console-typeout">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>\typeout{</xsl:text>
    <xsl:apply-templates select="." mode="long-name" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\typeout{************************************************}&#xa;</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- ############################ -->
<!-- Division Headers and Footers -->
<!-- ############################ -->

<!-- A typical division has 5 arguments (below).  For specialized       -->
<!-- divisions we need to adjust the environment name for numbered      -->
<!-- v. unnumbered instances.  Worksheets are exception with a          -->
<!-- page layout change.                                                -->
<!--                                                                    -->
<!--    1. title                                                        -->
<!--    2. subtitle                                                     -->
<!--    3. shorttitle                                                   -->
<!--    4. author                                                       -->
<!--    5. epigraph (unimplemented)                                     -->
<!--                                                                    -->
<!-- A "solutions" division in the back matter is implemented as an     -->
<!-- appendix.  The levels and division-name templates will produce a   -->
<!-- LaTeX chapter for a "book" and a LaTeX "section" for an "article". -->

<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|solutions[parent::backmatter]" mode="latex-division-heading">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- subtitle here -->
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-short"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="author" mode="name-list"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- subtitle here -->
    <!-- <xsl:text>An epigraph here\\with two lines\\-Rob</xsl:text> -->
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Specialized Divisions: we do not implement "author", "subtitle",  -->
<!-- or "epigraph" yet.  These may be added/supported later.           -->
<xsl:template match="exercises|solutions[not(parent::backmatter)]|reading-questions|glossary|references|worksheet" mode="latex-division-heading">
    <!-- Inspect parent (part through subsubsection)  -->
    <!-- to determine one of two models of a division -->
    <!-- NB: return values are 'true' and empty       -->
    <xsl:variable name="is-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:variable name="b-is-structured" select="$is-structured = 'true'"/>

    <xsl:if test="self::worksheet">
        <!-- \newgeometry includes a \clearpage -->
        <xsl:apply-templates select="." mode="new-geometry"/>
    </xsl:if>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name" />
    <xsl:if test="not($b-is-structured)">
        <xsl:text>-numberless</xsl:text>
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- subtitle here -->
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-short"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- author here -->
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- subtitle here -->
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Exceptional, for a worksheet only, we clear the page  -->
<!-- at the start and provide many options for specifying  -->
<!-- the four margins, in units LaTeX understands (such as -->
<!-- cm, in, pt).  This only produces text, so could go in -->
<!-- -common, but is also only useful for LaTeX output.    -->
<xsl:template match="worksheet" mode="new-geometry">
    <!-- Roughly, skinny half-inch margins, -->
    <!-- to use lots of the available space -->
    <!-- Perhaps this should be global, but -->
    <!-- no harm placing it here for now.   -->
    <xsl:variable name="default-worksheet-margin" select="'1.25cm'"/>
    <!-- Four similar "choose" effect hierarchy/priority -->
    <!-- NB: a publisher string parameter to      -->
    <!-- *really* override (worksheet.left, etc.) -->
    <xsl:text>\newgeometry{</xsl:text>
    <xsl:text>left=</xsl:text>
    <xsl:choose>
        <xsl:when test="@left">
            <xsl:value-of select="normalize-space(@left)"/>
        </xsl:when>
        <xsl:when test="@margin">
            <xsl:value-of select="normalize-space(@margin)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@left">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@left)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@margin">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@margin)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$default-worksheet-margin"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, right=</xsl:text>
    <xsl:choose>
        <xsl:when test="@right">
            <xsl:value-of select="normalize-space(@right)"/>
        </xsl:when>
        <xsl:when test="@margin">
            <xsl:value-of select="normalize-space(@margin)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@right">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@right)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@margin">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@margin)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$default-worksheet-margin"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, top=</xsl:text>
    <xsl:choose>
        <xsl:when test="@top">
            <xsl:value-of select="normalize-space(@top)"/>
        </xsl:when>
        <xsl:when test="@margin">
            <xsl:value-of select="normalize-space(@margin)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@top">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@top)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@margin">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@margin)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$default-worksheet-margin"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>, bottom=</xsl:text>
    <xsl:choose>
        <xsl:when test="@bottom">
            <xsl:value-of select="normalize-space(@bottom)"/>
        </xsl:when>
        <xsl:when test="@margin">
            <xsl:value-of select="normalize-space(@margin)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@bottom">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@bottom)"/>
        </xsl:when>
        <xsl:when test="$docinfo/latex-output/worksheet/@margin">
            <xsl:value-of select="normalize-space($docinfo/latex-output/worksheet/@margin)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$default-worksheet-margin"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Footers are straightfoward, except for specialized divisions -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|acknowledgement|foreword|preface|solutions[parent::backmatter]" mode="latex-division-footing">
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="exercises|solutions[not(parent::backmatter)]|reading-questions|glossary|references|worksheet" mode="latex-division-footing">
    <!-- Inspect parent (part through subsubsection)  -->
    <!-- to determine one of two models of a division -->
    <!-- NB: return values are 'true' and empty       -->
    <xsl:variable name="is-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:variable name="b-is-structured" select="$is-structured = 'true'"/>

    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="division-environment-name" />
    <xsl:if test="not($b-is-structured)">
        <xsl:text>-numberless</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:if test="self::worksheet">
        <!-- \restoregeometry includes a \clearpage -->
        <xsl:text>\restoregeometry&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############ -->
<!-- Subexercises -->
<!-- ############ -->

<xsl:template match="subexercises">
    <xsl:text>\paragraph{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="idx|notation|introduction|exercisegroup|exercise|conclusion"/>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after      -->
<!-- explicit subdivisions, to introduce or summarize -->
<!-- Title optional (and discouraged), in argument    -->
<!-- typically just a few paragraphs                  -->
<xsl:template match="article/introduction|chapter/introduction|section/introduction|subsection/introduction|appendix/introduction|exercises/introduction|solutions/introduction|worksheet/introduction|reading-questions/introduction|glossary/introduction|references/introduction">
    <xsl:text>\begin{introduction}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{introduction}%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="article/conclusion|chapter/conclusion|section/conclusion|subsection/conclusion|appendix/conclusion|exercises/conclusion|solutions/conclusion|worksheet/conclusion|reading-questions/conclusion|glossary/conclusion|references/conclusion">
    <xsl:text>\begin{conclusion}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{conclusion}%&#xa;</xsl:text>
</xsl:template>


<!-- Most introductions are followed by other sectioning blocks (e.g. subsection) -->
<!-- And then there is a resetting of the carriage. An introduction preceding a   -->
<!-- webwork needs an additional \par at the end (if there even was an intro)     -->
<xsl:template match="introduction[following-sibling::webwork-reps]">
    <xsl:apply-templates/>
    <xsl:text>\par\medskip&#xa;</xsl:text>
</xsl:template>

<!-- webwork conclusions forego the \bigbreak  -->
<!-- To stand apart, a medskip and noindent    -->
<xsl:template match="conclusion[preceding-sibling::webwork-reps]">
    <xsl:text>\par\medskip\noindent </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\par&#xa;</xsl:text>
</xsl:template>

<xsl:template match="exercisegroup/introduction">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="exercisegroup/conclusion">
    <xsl:apply-templates/>
</xsl:template>

<!-- Page Break in a Worksheet -->
<!-- Not very semantic, but worksheet construction for        -->
<!-- print does involve some layout. Only with a "worksheet". -->
<!-- NB: A "page" grouping interferes with numbering that     -->
<!-- looks to the parent.                                     -->
<xsl:template match="worksheet/pagebreak">
    <xsl:text>\clearpage&#xa;</xsl:text>
</xsl:template>

<!-- Statement -->
<!-- Simple containier for blocks with structured contents -->
<!-- Consumers are responsible for surrounding breaks      -->
<xsl:template match="statement">
    <xsl:apply-templates/>
</xsl:template>

<!-- Prelude, Interlude, Postlude -->
<!-- Very simple containiers, to help with movement, use -->
<xsl:template match="prelude|interlude|postlude">
    <xsl:text>\par&#xa;</xsl:text>
    <xsl:apply-templates/>
</xsl:template>


<!-- Paragraphs -->
<!-- Non-structural, even if they appear to be -->
<xsl:template match="paragraphs">
    <!-- Warn about paragraph deprecation -->
    <xsl:text>\begin{paragraphs}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{paragraphs}%&#xa;</xsl:text>
</xsl:template>

<!-- Commentary -->
<!-- For an enhanced edition, like an Instructor's Manual. -->
<!-- Must be elected by a publisher, based on the switch.  -->
<xsl:template match="commentary">
    <xsl:if test="$b-commentary">
        <!-- environment, title, label string, newline -->
        <xsl:text>\begin{commentary}</xsl:text>
        <xsl:apply-templates select="." mode="block-options"/>
        <xsl:text>%&#xa;</xsl:text>
        <!-- coordinate select with schema's BlockStatementNoCaption       -->
        <!-- Note sufficiency and necessity of processing index items here -->
        <xsl:apply-templates select="idx|p|blockquote|pre|aside|sidebyside|sbsgroup" />
        <xsl:text>\end{commentary}&#xa;</xsl:text>
        <xsl:apply-templates select="." mode="pop-footnote-text"/>
    </xsl:if>
</xsl:template>

<!-- Theorems, Proofs, Definitions, Examples, Exercises -->

<!-- Theorems have statement/proof structure                    -->
<!-- Definitions have notation, which is handled elsewhere      -->
<!-- Examples have no structure, or have statement and solution -->
<!-- Exercises have hints, answers and solutions                -->

<!-- Environments/blocks implemented with tcolorbox          -->
<!-- expect certain arguments.  This template provides them. -->
<!--                                                         -->
<!-- 1.  title, with punctuation as needed                   -->
<!-- 2.  the "latex-id", which suffices for                  -->
<!--     the LaTeX label/ref mechanism                       -->
<!--                                                         -->
<!-- Or, for THEOREM-LIKE and AXIOM-LIKE,                    -->
<!--                                                         -->
<!-- 1.  title, right now we add punctuation as needed       -->
<!-- 2.  a list of creator(s)                                -->
<!-- 3.  the "latex-id", which suffices for                  -->
<!--     the LaTeX label/ref mechanism                       -->
<!-- N.B.: "objectives", "outcomes" need to use this         -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&ASIDE-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]|commentary|assemblage" mode="block-options">
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="&THEOREM-FILTER; or &AXIOM-FILTER;">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="creator-full" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- latex-id destined for tcolorbox  phantomlabel=  option -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Theorems and Axioms-->
<!-- Very similar to case of definitions   -->
<!-- Adds (potential) proofs, and creators -->
<!-- Statement structure should be relaxed -->
<!-- Style is controlled in the preamble   -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;">
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <!-- statement is required now, to be relaxed in DTD      -->
    <!-- explicitly ignore proof and pickup just for theorems -->
    <!-- Locate first "proof", select only preceding:: ?      -->
    <xsl:apply-templates select="*[not(self::proof)]" />
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <!-- proof(s) are optional, so may not match at all          -->
    <!-- And the point of the AXIOM-LIKE is that they lack proof -->
    <xsl:if test="&THEOREM-FILTER;">
        <xsl:apply-templates select="proof" />
    </xsl:if>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Proofs -->
<!-- Subsidary to THEOREM-LIKE, or standalone        -->
<!-- Defaults to "Proof", can be replaced by "title" -->
<!-- TODO: rename as "proof" once  amsthm  package goes away -->
<xsl:template match="proof">
    <xsl:text>\begin{proofptx}</xsl:text>
    <!-- The AMS environment handles punctuation carefully, so  -->
    <!-- we just use the "title-full" template, with protection -->
    <xsl:text>{</xsl:text>
    <xsl:if test="title">
        <xsl:apply-templates select="." mode="title-full"/>
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{proofptx}&#xa;</xsl:text>
</xsl:template>

<!-- cases in proofs -->
<!-- Three arguments: direction arrow, title, label -->
<!-- The environment combines and styles            -->
<xsl:template match="case">
    <xsl:text>\begin{case}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- optional direction, given by attribute -->
    <xsl:choose>
        <xsl:when test="@direction='forward'">
            <xsl:text>\forwardimplication</xsl:text>
        </xsl:when>
        <xsl:when test="@direction='backward'">
            <xsl:text>\backwardimplication</xsl:text>
        </xsl:when>
        <!-- DTD will catch incorrect values -->
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <!-- optional title -->
    <xsl:text>{</xsl:text>
    <xsl:if test="title">
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:if>
    <xsl:text>}</xsl:text>
    <!-- label -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{case}&#xa;</xsl:text>
</xsl:template>

<!-- ######### -->
<!-- Exercises -->
<!-- ######### -->

<!-- Exercises are inline (parent is a division), or           -->
<!-- divisional by virtue of being in an "exercises"           -->
<!-- division, though they may be buried down in an            -->
<!-- "exercisedivision" or an "exercisegroup"                  -->

<!-- Switches provided here as defaults are the global values  -->
<!-- specified for the main narrative by an author, so these   -->
<!-- are employed when matching in document order.  Other uses -->
<!-- will need more care about passing in the right switches.  -->
<!-- Some of these switches might be moot, eg WeBWorK does not -->
<!-- have an "answer" and MyOpenMath only has "solution".  But -->
<!-- passing in values for the relevant switches will not do   -->
<!-- any harm in these cases.                                  -->

<!-- The next two routines are similar, but accept different   -->
<!-- default values for switches, so cannot be combined.       -->
<!-- The central 4-part "choose" could be extracted to a       -->
<!-- parameterized, modal template.                            -->

<!-- Every exercise may have its four components               -->
<!-- (statement, hint, answer, solution) visible or not        -->

<!-- Free-range (inline) exercises go into environments,       -->
<!-- they earn a different name this way, and their numbers    -->
<!-- are integrated with LaTeX's automated numbering schemes   -->

<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]">
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{inlineexercise}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Allow a webwork or myopenmath exercise to introduce/connect    -->
    <!-- a problem (especially from server) to the text in various ways -->
    <xsl:if test="webwork-reps|myopenmath">
        <xsl:apply-templates select="introduction"/>
    </xsl:if>
    <!-- condition on how statement, hint, answer, solution are presented -->
    <xsl:choose>
        <!-- webwork, structured with "stage" matches first  -->
        <!-- Above provides infrastructure for the exercise, -->
        <!-- we pass the stage on to a WW-specific template  -->
        <!-- since each stage may have hints, answers, and   -->
        <!-- solutions.                                      -->
        <xsl:when test="webwork-reps/static/stage">
            <xsl:apply-templates select="webwork-reps/static/stage">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-inline-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-inline-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-inline-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- webwork exercise, no "stage" -->
        <xsl:when test="webwork-reps/static">
            <xsl:apply-templates select="webwork-reps/static" mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-inline-hint" />
                <!-- 2018-09-21: WW answers may become available -->
                <xsl:with-param name="b-has-answer"    select="$b-has-inline-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-inline-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- myopenmath exercise -->
        <!-- We only try to open an external file when the source  -->
        <!-- has a MOM problem (with an id number).  The second    -->
        <!-- argument of the "document()" function is a node and   -->
        <!-- causes the relative file name to resolve according    -->
        <!-- to the location of the XML.   Experiments with the    -->
        <!-- empty node "/.." are interesting.                     -->
        <!-- https://ajwelch.blogspot.co.za/2008/04/relative-paths-and-document-function.html -->
        <!-- http://www.dpawson.co.uk/xsl/sect2/N2602.html#d3862e73 (Point 4) -->
        <xsl:when test="myopenmath">
            <xsl:variable name="filename" select="concat(concat('problems/mom-', myopenmath/@problem), '.xml')" />
            <xsl:apply-templates select="document($filename, .)/myopenmath"  mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="false()" />
                <xsl:with-param name="b-has-answer"    select="false()" />
                <xsl:with-param name="b-has-solution"  select="$b-has-inline-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- "normal" exercise -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-inline-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-inline-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-inline-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Allow a webwork or myopenmath exercise to conclude/connect     -->
    <!-- a problem (especially from server) to the text in various ways -->
    <xsl:if test="webwork-reps|myopenmath">
        <xsl:apply-templates select="conclusion"/>
    </xsl:if>
    <!-- end enclosure/environment -->
    <xsl:text>\end{inlineexercise}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Inline Exercises (exercises//exercise) in solutions-->
<!-- Nothing produced if there is no content       -->
<!-- Otherwise, no label, since duplicate          -->
<!-- Different environment, with hard-coded number -->
<!-- Switches for solutions are generated          -->
<!-- elsewhere and always supplied in call         -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint"      />
    <xsl:param name="b-has-answer"    />
    <xsl:param name="b-has-solution"  />

    <!-- Subsetting, especially in the back matter can yield no content at all    -->
    <!-- Schema says there is always some sort of statement, explicit or implicit -->
    <!-- We frequently build collections of "dry-run" output to determine if a    -->
    <!-- collection of exercises (e.g. in an "exercisegroup") is empty or not.    -->
    <!-- So it is *critical* that we get zero output for an exercise that has     -->
    <!-- no content due to settings of switches.                                  -->

     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- <xsl:variable name="nonempty" select="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)" /> -->

    <xsl:if test="not($dry-run = '')">
        <!-- heading, start enclosure/environment -->
        <xsl:text>\begin{inlineexercisesolution}</xsl:text>
        <!-- mandatory hard-coded number for solution version -->
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>}</xsl:text>
        <!-- label of the exercise, to link back to it -->
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="latex-id"/>
        <xsl:text>}</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <!-- Allow a webwork or myopenmath exercise to introduce/connect    -->
        <!-- a problem (especially from server) to the text in various ways -->
        <xsl:if test="webwork-reps|myopenmath">
            <xsl:apply-templates select="introduction"/>
        </xsl:if>
        <!-- condition on how statement, hint, answer, solution are presented -->
        <xsl:choose>
            <!-- webwork, structured with "stage" matches first -->
            <!-- Above provides infrastructure for the exercise, -->
            <!-- we pass the stage on to a WW-specific template  -->
            <!-- since each stage may have hints, answers, and   -->
            <!-- solutions.                                      -->
            <xsl:when test="webwork-reps/static/stage">
                <xsl:apply-templates select="webwork-reps/static/stage" mode="solutions">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:when>
            <!-- webwork exercise, no "stage" -->
            <xsl:when test="webwork-reps/static">
                <xsl:apply-templates select="webwork-reps/static" mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <!-- 2018-09-21: WW answers may become available -->
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:when>
            <!-- myopenmath exercise -->
            <!-- We only try to open an external file when the source  -->
            <!-- has a MOM problem (with an id number).  The second    -->
            <!-- argument of the "document()" function is a node and   -->
            <!-- causes the relative file name to resolve according    -->
            <!-- to the location of the XML.   Experiments with the    -->
            <!-- empty node "/.." are interesting.                     -->
            <!-- https://ajwelch.blogspot.co.za/2008/04/relative-paths-and-document-function.html -->
            <!-- http://www.dpawson.co.uk/xsl/sect2/N2602.html#d3862e73 (Point 4) -->
            <xsl:when test="myopenmath">
                <xsl:variable name="filename" select="concat(concat('problems/mom-', myopenmath/@problem), '.xml')" />
                <xsl:apply-templates select="document($filename, .)/myopenmath"  mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="false()" />
                    <xsl:with-param name="b-has-answer"    select="false()" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:when>
            <!-- "normal" exercise -->
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Allow a webwork or myopenmath exercise to conclude/connect     -->
        <!-- a problem (especially from server) to the text in various ways -->
        <xsl:if test="webwork-reps|myopenmath">
            <xsl:apply-templates select="conclusion"/>
        </xsl:if>
        <!-- end enclosure/environment -->
        <xsl:text>\end{inlineexercisesolution}</xsl:text>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Divisional Exercises (exercises//exercise, worksheet//exercise, etc) -->
<!-- Divisional exercises are not named when born, by virtue -->
<!-- of being within an "exercises" division.  We hard-code  -->
<!-- their numbers to allow for flexibility, and since it is -->
<!-- too hard (impossible?) to mesh into LaTeX's scheme.  An -->
<!-- "exercises" may be divided by a future "subexercises"   -->
<!-- and/or by an "exercisegroup", so we match with "//"     -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise">
    <!-- There are three sets of switches, so we build a single set, -->
    <!-- depending on what type of division the "exercise" lives in. -->
    <!-- For each, exactly one "ancestor" is true, and then the      -->
    <!-- expression will evaluate to the corresponding global switch -->
    <xsl:variable name="b-has-statement" select="true()"/>
    <xsl:variable name="b-has-hint"
        select="(ancestor::exercises and $b-has-divisional-hint) or
                (ancestor::worksheet and $b-has-worksheet-hint)  or
                (ancestor::reading-questions and $b-has-reading-hint)"/>
    <xsl:variable name="b-has-answer"
        select="(ancestor::exercises and $b-has-divisional-answer) or
                (ancestor::worksheet and $b-has-worksheet-answer)  or
                (ancestor::reading-questions and $b-has-reading-answer)"/>
    <xsl:variable name="b-has-solution"
        select="(ancestor::exercises and $b-has-divisional-solution) or
                (ancestor::worksheet and $b-has-worksheet-solution)  or
                (ancestor::reading-questions and $b-has-reading-solution)"/>
    <!-- The exact environment depends on the placement of the -->
    <!-- "exercise" when located in an "exercises" division    -->
    <xsl:variable name="env-name">
        <xsl:text>divisionexercise</xsl:text>
        <xsl:if test="ancestor::exercisegroup">
            <xsl:text>eg</xsl:text>
        </xsl:if>
        <xsl:if test="ancestor::exercisegroup/@cols">
            <xsl:text>col</xsl:text>
        </xsl:if>
    </xsl:variable>
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="$env-name"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <!-- workspace fraction, only if given, else blank -->
    <!-- worksheets only now, eventually exams?        -->
    <xsl:text>{</xsl:text>
    <xsl:if test="ancestor::worksheet and @workspace">
        <xsl:value-of select="substring-before(@workspace,'%') div 100" />
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id"/>
    <xsl:text>}</xsl:text>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Allow a webwork or myopenmath exercise to introduce/connect    -->
    <!-- a problem (especially from server) to the text in various ways -->
    <xsl:if test="webwork-reps|myopenmath">
        <xsl:apply-templates select="introduction"/>
    </xsl:if>
    <!-- condition on how statement, hint, answer, solution are presented -->
    <xsl:choose>
        <!-- webwork, structured with "stage" matches first -->
        <!-- Above provides infrastructure for the exercise, -->
        <!-- we pass the stage on to a WW-specific template  -->
        <!-- since each stage may have hints, answers, and   -->
        <!-- solutions.                                      -->
        <xsl:when test="webwork-reps/static/stage">
            <xsl:apply-templates select="webwork-reps/static/stage">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- webwork exercise, no "stage" -->
        <xsl:when test="webwork-reps/static">
            <xsl:apply-templates select="webwork-reps/static" mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <!-- 2018-09-21: WW answers may become available -->
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- myopenmath exercise -->
        <!-- We only try to open an external file when the source  -->
        <!-- has a MOM problem (with an id number).  The second    -->
        <!-- argument of the "document()" function is a node and   -->
        <!-- causes the relative file name to resolve according    -->
        <!-- to the location of the XML.   Experiments with the    -->
        <!-- empty node "/.." are interesting.                     -->
        <!-- https://ajwelch.blogspot.co.za/2008/04/relative-paths-and-document-function.html -->
        <!-- http://www.dpawson.co.uk/xsl/sect2/N2602.html#d3862e73 (Point 4) -->
        <xsl:when test="myopenmath">
            <xsl:variable name="filename" select="concat(concat('problems/mom-', myopenmath/@problem), '.xml')" />
            <xsl:apply-templates select="document($filename, .)/myopenmath"  mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="false()" />
                <xsl:with-param name="b-has-answer"    select="false()" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- "normal" exercise -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Allow a webwork or myopenmath exercise to conclude/connect     -->
    <!-- a problem (especially from server) to the text in various ways -->
    <xsl:if test="webwork-reps|myopenmath">
        <xsl:apply-templates select="conclusion"/>
    </xsl:if>
    <!-- closing % necessary, as newline between adjacent environments -->
    <!-- will cause a slight indent on trailing exercise               -->
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$env-name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>


<!-- Divisional Exercises (exercises//exercise, etc) in solutions-->
<!-- Nothing produced if there is no content -->
<!-- Otherwise, no label, since duplicate    -->
<!-- Switches for solutions are generated    -->
<!-- elsewhere and always supplied in call   -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- Subsetting, especially in the back matter can yield no content at all    -->
    <!-- Schema says there is always some sort of statement, explicit or implicit -->
    <!-- We frequently build collections of "dry-run" output to determine if a    -->
    <!-- collection of exercises (e.g. in an "exercisegroup") is empty or not.    -->
    <!-- So it is *critical* that we get zero output for an exercise that has     -->
    <!-- no content due to settings of switches.                                  -->
    <!-- When we subset exercises for solutions, an entire      -->
    <!-- "exercisegroup" can become empty.  So we do a dry-run  -->
    <!-- and if there is no content at all we bail out.         -->

     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- <xsl:variable name="nonempty" select="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)" /> -->

    <xsl:if test="not($dry-run = '')">
        <!-- Using fully-qualified number in solution lists -->
        <xsl:variable name="env-name">
            <xsl:text>divisionsolution</xsl:text>
            <xsl:if test="ancestor::exercisegroup">
                <xsl:text>eg</xsl:text>
            </xsl:if>
            <xsl:if test="ancestor::exercisegroup/@cols">
                <xsl:text>col</xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="$env-name"/>
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>}</xsl:text>
        <!-- label of the exercise, to link back to it -->
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="latex-id"/>
        <xsl:text>}</xsl:text>
        <!-- no workspace fraction in a solution -->
        <xsl:text>%&#xa;</xsl:text>
        <!-- Allow a webwork or myopenmath exercise to introduce/connect    -->
        <!-- a problem (especially from server) to the text in various ways -->
        <xsl:if test="webwork-reps|myopenmath">
            <xsl:apply-templates select="introduction"/>
        </xsl:if>
        <!-- condition on how statement, hint, answer, solution are presented -->
        <xsl:choose>
            <!-- webwork, structured with "stage" matches first -->
            <!-- Above provides infrastructure for the exercise, -->
            <!-- we pass the stage on to a WW-specific template  -->
            <!-- since each stage may have hints, answers, and   -->
            <!-- solutions.                                      -->
            <xsl:when test="webwork-reps/static/stage">
                <xsl:apply-templates select="webwork-reps/static/stage" mode="solutions">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:when>
            <!-- webwork exercise, no "stage" -->
            <xsl:when test="webwork-reps/static">
                <xsl:apply-templates select="webwork-reps/static" mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <!-- 2018-09-21: WW answers may become available -->
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:when>
            <!-- myopenmath exercise -->
            <!-- We only try to open an external file when the source  -->
            <!-- has a MOM problem (with an id number).  The second    -->
            <!-- argument of the "document()" function is a node and   -->
            <!-- causes the relative file name to resolve according    -->
            <!-- to the location of the XML.   Experiments with the    -->
            <!-- empty node "/.." are interesting.                     -->
            <!-- https://ajwelch.blogspot.co.za/2008/04/relative-paths-and-document-function.html -->
            <!-- http://www.dpawson.co.uk/xsl/sect2/N2602.html#d3862e73 (Point 4) -->
            <xsl:when test="myopenmath">
                <xsl:variable name="filename" select="concat(concat('problems/mom-', myopenmath/@problem), '.xml')" />
                <xsl:apply-templates select="document($filename, .)/myopenmath"  mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="false()" />
                    <xsl:with-param name="b-has-answer"    select="false()" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:when>
            <!-- "normal" exercise -->
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Allow a webwork or myopenmath exercise to conclude/connect     -->
        <!-- a problem (especially from server) to the text in various ways -->
        <xsl:if test="webwork-reps|myopenmath">
            <xsl:apply-templates select="conclusion"/>
        </xsl:if>
        <!-- closing % necessary, as newline between adjacent environments -->
        <!-- will cause a slight indent on trailing exercise               -->
        <xsl:text>\end{</xsl:text>
        <xsl:value-of select="$env-name"/>
        <xsl:text>}%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- ######################### -->
<!-- Components of an Exercise -->
<!-- ######################### -->

<!-- Three components of a "regular" exercise, two components         -->
<!-- of a "webwork" exercise, two components of a "webwork/stage",    -->
<!-- and one component of a "myopenmath".  In other words, "hint",    -->
<!-- "answer", "solution".  For re-use in solution lists and          -->
<!-- solutions manuals, we also interpret "statement" as a component. -->
<!-- $purpose determines if the components are being built for the    -->
<!-- main matter or back matter and so help be certain the right      -->
<!-- label is created.                                                -->

<xsl:template match="exercise|webwork-reps/static|webwork-reps/static/stage|myopenmath|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task" mode="exercise-components">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer"  />
    <xsl:param name="b-has-solution"  />

    <!-- structured (with components) versus unstructured (simply a bare statement) -->
    <xsl:choose>
        <xsl:when test="statement">
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="statement">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
                <xsl:if test="$b-original and ($debug.exercises.forward = 'yes')">
                    <!-- if several, all exist together, so just work with first one -->
                    <xsl:for-each select="hint[1]|answer[1]|solution[1]">
                        <!-- closer is better, so mainmatter solutions first -->
                        <xsl:choose>
                            <xsl:when test="count(.|$solutions-mainmatter) = count($solutions-mainmatter)">
                                <xsl:text>\space</xsl:text>
                                <xsl:text>\hyperlink{</xsl:text>
                                <xsl:apply-templates select="." mode="latex-id-duplicate">
                                    <xsl:with-param name="suffix" select="'main'"/>
                                </xsl:apply-templates>
                                <xsl:text>}{[</xsl:text>
                                <xsl:apply-templates select="." mode="type-name"/>
                                <xsl:text>]}</xsl:text>
                            </xsl:when>
                            <xsl:when test="count(.|$solutions-backmatter) = count($solutions-backmatter)">
                                <xsl:text>\space</xsl:text>
                                <xsl:text>\hyperlink{</xsl:text>
                                <xsl:apply-templates select="." mode="latex-id-duplicate">
                                    <xsl:with-param name="suffix" select="'back'"/>
                                </xsl:apply-templates>
                                <xsl:text>}{[</xsl:text>
                                <xsl:apply-templates select="." mode="type-name"/>
                                <xsl:text>]}</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="(hint and $b-has-hint) or (answer and $b-has-answer) or (solution and $b-has-solution)">
                    <xsl:call-template name="exercise-component-separator" />
                </xsl:if>
            </xsl:if>
            <xsl:if test="$b-has-hint">
                <xsl:apply-templates select="hint">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-answer" select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:if>
            <xsl:if test="$b-has-answer">
                <xsl:apply-templates select="answer">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:if>
            <xsl:if test="$b-has-solution">
                <xsl:apply-templates select="solution">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="purpose" select="$purpose" />
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <!-- no explicit "statement", so all content is the statement -->
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
                <!-- no separator, since no trailing components -->
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="hint">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="." mode="solution-heading">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="purpose" select="$purpose" />
    </xsl:apply-templates>
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <xsl:choose>
        <xsl:when test="following-sibling::hint">
            <xsl:call-template name="exercise-component-separator" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="(following-sibling::answer and $b-has-answer) or (following-sibling::solution and $b-has-solution)">
                <xsl:call-template name="exercise-component-separator" />
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="answer">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="." mode="solution-heading">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="purpose" select="$purpose" />
    </xsl:apply-templates>
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <xsl:choose>
        <xsl:when test="following-sibling::answer">
            <xsl:call-template name="exercise-component-separator" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="following-sibling::solution and $b-has-solution">
                <xsl:call-template name="exercise-component-separator" />
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="solution">
    <xsl:param name="b-original" />
    <xsl:param name="purpose" />

    <xsl:apply-templates select="." mode="solution-heading">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="purpose" select="$purpose" />
    </xsl:apply-templates>
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <xsl:if test="following-sibling::solution">
        <xsl:call-template name="exercise-component-separator" />
    </xsl:if>
    <!-- no final separator, solutions are last, let environment handle -->
</xsl:template>

<!-- Each component has a similar look, so we combine here -->
<!-- Separators depend on possible trailing items, so no   -->
<!-- vertical spacing beforehand is present here           -->
<xsl:template match="hint|answer|solution" mode="solution-heading">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="purpose" />

    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="type-name" />
    <!-- An empty value means element is a singleton -->
    <!-- else the serial number comes through        -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="non-singleton-number" />
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:if>
    <xsl:text>}</xsl:text> <!-- end bold number -->
    <xsl:if test="title">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text>.</xsl:text>
    <!-- if original, label in the usual ways  -->
    <!-- if duplicate, use extraordinary label -->
    <xsl:choose>
        <!-- a solution right where the exercise is born -->
        <xsl:when test="$b-original">
            <xsl:apply-templates select="." mode="label"/>
        </xsl:when>
            <!-- Finally, the purpose of $purpose.  We know if this  -->
            <!-- solution is being displayed in the main matter or   -->
            <!-- in the back matter, so we can provide the correct   -->
            <!-- suffix to the label.                                -->
        <xsl:when test="$purpose = 'mainmatter'">
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id-duplicate">
                <xsl:with-param name="suffix" select="'main'"/>
            </xsl:apply-templates>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:when test="$purpose = 'backmatter'">
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id-duplicate">
                <xsl:with-param name="suffix" select="'back'"/>
            </xsl:apply-templates>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- linking not enabled for PDF solution manual -->
        <xsl:when test="$purpose = 'solutionmanual'" />
        <!-- born (original=true), or mainmatter, or backmatter, or solutionmanual -->
        <xsl:otherwise>
            <xsl:message>PTX:BUG:     Exercise component mis-labeled</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- some distance to actual content -->
    <xsl:text>\quad{}</xsl:text>
</xsl:template>

<xsl:template name="exercise-component-separator">
    <!-- <xsl:text>\par\smallskip\noindent%&#xa;</xsl:text> -->
    <xsl:text>\par\smallskip%&#xa;</xsl:text>
    <xsl:text>\noindent</xsl:text>
</xsl:template>

<!-- Exercise Group -->
<!-- We interrupt a run of exercises with short commentary, -->
<!-- typically instructions for a list of similar exercises -->
<!-- Commentary goes in an introduction and/or conclusion   -->
<!-- When we point to these, we use custom hypertarget, etc -->
<xsl:template match="exercisegroup">
    <xsl:text>\par\medskip\noindent%&#xa;</xsl:text>
    <xsl:if test="title">
        <xsl:text>\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}\space\space</xsl:text>
    </xsl:if>
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label"/>
    </xsl:if>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="introduction" />
    <xsl:choose>
        <xsl:when test="not(@cols) or (@cols = 1)">
            <xsl:text>\begin{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@cols = 2 or @cols = 3 or @cols = 4 or @cols = 5 or @cols = 6">
            <xsl:text>\begin{exercisegroupcol}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="@cols"/>
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate="yes">MBX:ERROR: invalid value <xsl:value-of select="@cols" /> for cols attribute of exercisegroup</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- an exercisegroup can only appear in an "exercises" division,    -->
    <!-- the template for exercises//exercise will consult switches for  -->
    <!-- visibility of components when born (not doing "solutions" here) -->
    <xsl:apply-templates select="exercise"/>
    <xsl:choose>
        <xsl:when test="not(@cols) or (@cols = 1)">
            <xsl:text>\end{exercisegroup}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@cols = 2 or @cols = 3 or @cols = 4 or @cols = 5 or @cols = 6">
            <xsl:text>\end{exercisegroupcol}&#xa;</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:if test="conclusion">
        <xsl:text>\par\noindent%&#xa;</xsl:text>
        <xsl:apply-templates select="conclusion" />
    </xsl:if>
    <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
</xsl:template>

<xsl:template match="subexercises" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- When we subset exercises for solutions, an entire      -->
    <!-- "subexercises" can become empty.  So we do a dry-run  -->
    <!-- and if there is no content at all we bail out.         -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <xsl:if test="title">
            <xsl:text>\paragraph</xsl:text>
            <!-- keep optional title if LaTeX source is re-purposed -->
            <xsl:text>[{</xsl:text>
            <xsl:apply-templates select="." mode="title-short" />
            <xsl:text>}]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="." mode="title-full" />
            <xsl:text>}</xsl:text>
            <!-- no label, as this is a duplicate              -->
            <!-- no title, no heading, so only line-break here -->
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="introduction" />
        </xsl:if>
        <xsl:apply-templates select="exercise|exercisegroup" mode="solutions">
            <xsl:with-param name="purpose" select="$purpose" />
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="conclusion" />
        </xsl:if>
        <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Exercise Group (in solutions division) -->
<!-- Nothing produced if there is no content         -->
<!-- Otherwise, no label, since duplicate            -->
<!-- Introduction and conclusion iff with statements -->
<xsl:template match="exercisegroup" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- When we subset exercises for solutions, an entire      -->
    <!-- "exercisegroup" can become empty.  So we do a dry-run  -->
    <!-- and if there is no content at all we bail out.         -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <xsl:if test="title">
            <xsl:text>\subparagraph</xsl:text>
            <!-- keep optional title if LaTeX source is re-purposed -->
            <xsl:text>[{</xsl:text>
            <xsl:apply-templates select="." mode="title-short" />
            <xsl:text>}]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="." mode="title-full" />
            <xsl:text>}</xsl:text>
            <!-- no label, as this is a duplicate              -->
            <!-- no title, no heading, so only line-break here -->
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="introduction" />
        </xsl:if>
        <!-- the container for the exercisegroup does not need to change -->
        <!-- when in a solutions list.  The indentation might look odd   -->
        <!-- without an introduction (when there are no statements), or  -->
        <!-- it might remind the reader of the grouping                  -->
        <xsl:choose>
            <xsl:when test="not(@cols) or (@cols = 1)">
                <xsl:text>\begin{exercisegroup}&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@cols = 2 or @cols = 3 or @cols = 4 or @cols = 5 or @cols = 6">
                <xsl:text>\begin{exercisegroupcol}</xsl:text>
                <xsl:text>{</xsl:text>
                <xsl:value-of select="@cols"/>
                <xsl:text>}&#xa;</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:apply-templates select="exercise" mode="solutions">
            <xsl:with-param name="purpose" select="$purpose" />
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
        <xsl:choose>
            <xsl:when test="not(@cols) or (@cols = 1)">
                <xsl:text>\end{exercisegroup}&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@cols = 2 or @cols = 3 or @cols = 4 or @cols = 5 or @cols = 6">
                <xsl:text>\end{exercisegroupcol}&#xa;</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:if test="$b-has-statement">
            <xsl:apply-templates select="conclusion" />
        </xsl:if>
        <xsl:text>\par\medskip\noindent&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ################ -->
<!-- WeBWorK Problems -->
<!-- ################ -->

<!-- The following routines are particular to extensions present  -->
<!-- in "static" versions of a WeBWorK problem.  In some cases,   -->
<!-- the PTX/XML markup includes tags and attributes generated    -->
<!-- by a WW server.  These may not be part of an author's source -->
<!-- and so is not part of the PTX schema.                        -->

<!-- A WW "stage" is a division of a problem.  It requires a      -->
<!-- reader to complete a stage before moving on to the next      -->
<!-- stage.  We realize each stage in print as a "Part", which    -->
<!-- has a statement and optionally, hints, answers and solutions.-->

<!-- Fail if WeBWorK extraction and merging has not been done -->
<xsl:template match="webwork[node()|@*]">
    <xsl:message>PTX:ERROR: A document that uses WeBWorK must have the mbx script webwork extraction run, followed by a merge using pretext-merge.xsl.  Apply subsequent style sheets to the merged output.  Your WeBWorK problems will be absent from your LaTeX output.</xsl:message>
</xsl:template>

<xsl:template match="webwork-reps/static/stage">
    <xsl:param name="b-original" />
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:if test="not(preceding-sibling::stage)">
        <text>\leavevmode\par\noindent%&#xa;</text>
    </xsl:if>
    <!-- e.g., Part 2. -->
    <xsl:text>\textbf{</xsl:text>
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'part'" />
    </xsl:call-template>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>.}\quad </xsl:text>
    <xsl:apply-templates select="." mode="exercise-components">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint" select="$b-has-hint" />
        <xsl:with-param name="b-has-answer" select="$b-has-answer" />
        <xsl:with-param name="b-has-solution" select="$b-has-solution" />
    </xsl:apply-templates>
    <xsl:if test="following-sibling::stage">
        <xsl:text>\par\medskip\noindent%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="webwork-reps/static/stage" mode="solutions">
    <xsl:param name="b-original"/>
    <xsl:param name="purpose"/>
    <xsl:param name="b-has-statement"/>
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-answer"/>
    <xsl:param name="b-has-solution"/>

    <!-- When we subset exercises for solutions, an entire -->
    <!-- "stage" can become empty.  So we do a dry-run     -->
    <!-- and if there is no content at all we bail out.    -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <xsl:if test="not(preceding-sibling::stage)">
            <text>\leavevmode\par\noindent%&#xa;</text>
        </xsl:if>
        <!-- e.g., Part 2. -->
        <xsl:text>\textbf{</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'part'" />
        </xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>.}\quad </xsl:text>
        <xsl:apply-templates select="." mode="exercise-components">
            <xsl:with-param name="b-original" select="$b-original"/>
            <xsl:with-param name="purpose" select="$purpose"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement"/>
            <xsl:with-param name="b-has-hint" select="$b-has-hint"/>
            <xsl:with-param name="b-has-answer" select="$b-has-answer"/>
            <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
        </xsl:apply-templates>
        <xsl:if test="following-sibling::stage">
            <xsl:text>\par\medskip\noindent%&#xa;</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- answer blank for quantitative answers              -->
<xsl:template match="webwork-reps/static//statement//fillin">
    <xsl:text> \fillin{</xsl:text>
    <xsl:choose>
        <xsl:when test="@characters">
            <xsl:value-of select="@characters" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>5</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- answer blank for other kinds of answers                 -->
<!-- TODO: gradually eliminate "var"'s presence from static  -->
<!-- coming from a WeBWorK server, similar to how the above  -->
<!-- replaced var with fillin for quantitative answers.      -->
<xsl:template match="webwork-reps/static//statement//var[@form]">
    <xsl:choose>
        <!-- TODO: make semantic list style in preamble -->
        <xsl:when test="@form='popup'" >
            <xsl:text>\quad(\begin{itemize*}[label=$\square$,leftmargin=3em,itemjoin=\hspace{1em}]&#xa;</xsl:text>
            <xsl:for-each select="li">
                <xsl:if test="not(p[.='?']) and not(normalize-space(.)='?')">
                    <xsl:text>\item{}</xsl:text>
                    <xsl:apply-templates select='.' />
                    <xsl:text>&#xa;</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>\end{itemize*})\quad&#xa;</xsl:text>
        </xsl:when>
        <!-- Radio button alternatives:                                -->
        <!--     \ocircle (wasysym), \circledcirc (amssymb),           -->
        <!--     \textopenbullet, \textbigcircle (textcomp)            -->
        <!-- To adjust in preamble, test on:                           -->
        <!-- $b-has-webwork-reps, then on                              -->
        <!-- $document-root//webwork-reps/static//var[@form='buttons'] -->
        <xsl:when test="@form='buttons'" >
            <xsl:text>\par&#xa;</xsl:text>
            <xsl:text>\begin{itemize}[label=$\odot$,leftmargin=3em,]&#xa;</xsl:text>
            <xsl:for-each select="li">
                <xsl:text>\item{}</xsl:text>
                <xsl:apply-templates select='.' />
                <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
            <xsl:text>\end{itemize}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@form='checkboxes'" >
            <xsl:text>\par&#xa;</xsl:text>
            <xsl:text>\begin{itemize*}[label=$\square$,leftmargin=3em,itemjoin=\hspace{4em plus 1em minus 3em}]&#xa;</xsl:text>
            <xsl:for-each select="li">
                <xsl:if test="not(p[.='?']) and not(normalize-space(.)='?')">
                    <xsl:text>\item{}</xsl:text>
                    <xsl:apply-templates select='.' />
                    <xsl:text>&#xa;</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>\end{itemize*}&#xa;</xsl:text>
        </xsl:when>
        <xsl:when test="@form='essay'" >
            <xsl:text>\quad\lbrack Essay Answer\rbrack</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Definition Like, Remark Like, Computation Like, Example Like  -->
<!-- Simpler than theorems, definitions, etc      -->
<!-- Only EXAMPLE-LIKE has hint, answer, solution -->
<xsl:template match="&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;">
    <!-- structured version may contain a prelude -->
    <xsl:if test="statement">
        <xsl:apply-templates select="prelude" />
    </xsl:if>
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:choose>
        <!-- We use common routines for this variant, but     -->
        <!-- components of these objects are not controllable -->
        <!-- by switches, as their nomenclature implies they  -->
        <!-- are essential, not like exercises or projects.   -->
        <!-- NB: template is not parameterized at all         -->
        <!-- prelude?, statement, hint*, answer*, solution*, postlude? -->
        <xsl:when test="&EXAMPLE-FILTER;">
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint" select="true()" />
                <xsl:with-param name="b-has-answer" select="true()" />
                <xsl:with-param name="b-has-solution" select="true()" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- unstructured, just a bare statement          -->
        <!-- no need to avoid dangerous misunderstandings -->
        <xsl:otherwise>
            <xsl:apply-templates/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
    <!-- structured version may contain a postlude -->
    <xsl:if test="statement">
        <xsl:apply-templates select="postlude" />
    </xsl:if>
</xsl:template>

<!-- Project Like -->
<!-- More complicated structure possibly, with task as division -->
<!-- Parameterized to allow control on hint, answer, solution   -->
<xsl:template match="&PROJECT-LIKE;">
    <!-- structured version may contain a prelude -->
    <xsl:if test="statement or task">
        <xsl:apply-templates select="prelude" />
    </xsl:if>
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:choose>
        <!-- structured versions first      -->
        <!-- prelude?, introduction?, task+, conclusion?, postlude? -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction"/>
            <xsl:apply-templates select="task"/>
            <xsl:apply-templates select="conclusion"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-project-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-project-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-project-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
    <!-- structured version may contain a postlude -->
    <xsl:if test="statement or task">
        <xsl:apply-templates select="postlude" />
    </xsl:if>
</xsl:template>


<!-- Project Like (in solutions divisions) -->
<!-- Nothing produced if there is no content  -->
<!-- Otherwise, no label, since duplicate     -->
<!-- No prelude or postlude since duplicate   -->
<!-- Different environment, hard-coded number -->
<xsl:template match="&PROJECT-LIKE;" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <!-- no prelude as duplicating in solutions division -->
    <xsl:if test="not($dry-run= '')">
        <xsl:text>\begin{</xsl:text>
        <xsl:value-of select="local-name(.)" />
        <xsl:text>solution</xsl:text>
        <xsl:text>}</xsl:text>
        <!-- mandatory hard-coded number for solution version -->
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text>}</xsl:text>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:text>}</xsl:text>
        <!-- label of the project, to link back to it -->
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="latex-id"/>
        <xsl:text>}</xsl:text>
        <xsl:text>%&#xa;</xsl:text>
        <xsl:choose>
            <!-- structured versions first      -->
            <!-- prelude?, introduction?, task+, conclusion?, postlude? -->
            <xsl:when test="task">
                <xsl:if test="$b-has-statement">
                    <xsl:apply-templates select="introduction"/>
                </xsl:if>
                <xsl:apply-templates select="task" mode="solutions">
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint" select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer" select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
                <xsl:if test="$b-has-statement">
                    <xsl:apply-templates select="conclusion"/>
                </xsl:if>
            </xsl:when>
            <!-- Now no project/task possibility -->
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()" />
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint" select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer" select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>\end{</xsl:text>
        <xsl:value-of select="local-name(.)" />
        <xsl:text>solution</xsl:text>
        <xsl:text>}%&#xa;</xsl:text>
    </xsl:if>
    <!-- no prelude as duplicating in solutions division -->
</xsl:template>

<!-- Task (a part of a project) -->
<!-- Parameterized, but with no defaults, since this -->
<!-- is always a constituent of something larger     -->
<xsl:template match="task">
    <!-- if first at its level, start the list environment -->
    <xsl:if test="not(preceding-sibling::task)">
        <!-- set the label style of this list       -->
        <!-- using features of the enumitem package -->
        <xsl:text>\begin{enumerate}[font=\bfseries,label=</xsl:text>
        <xsl:choose>
            <!-- three deep -->
            <xsl:when test="parent::task/parent::task">
                <xsl:text>(\Alph*),ref=\theenumi.\theenumii.\Alph*</xsl:text>
            </xsl:when>
            <!-- two deep -->
            <xsl:when test="parent::task">
                <xsl:text>(\roman*),ref=\theenumi.\roman*</xsl:text>
            </xsl:when>
            <!-- one deep -->
            <xsl:otherwise>
                <xsl:text>(\alph*),ref=\alph*</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>]&#xa;</xsl:text>
    </xsl:if>
    <!-- always a list item -->
    <xsl:text>\item</xsl:text>
    <!-- \label{} will separate content, if   -->
    <!-- employed, else we use an empty group -->
    <xsl:choose>
        <xsl:when test="@xml:id">
            <xsl:apply-templates select="." mode="label" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- more structured versions first -->
    <xsl:choose>
        <xsl:when test="task">
            <xsl:apply-templates select="introduction"/>
            <xsl:apply-templates select="task" />
            <xsl:apply-templates select="conclusion"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-original" select="true()" />
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint" select="$b-has-project-hint" />
                <xsl:with-param name="b-has-answer" select="$b-has-project-answer" />
                <xsl:with-param name="b-has-solution" select="$b-has-project-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
    <!-- if last at its level, end the list environment -->
    <xsl:if test="not(following-sibling::task)">
        <xsl:text>\end{enumerate}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Task (a part of a project), in solutions division -->
<xsl:template match="task" mode="solutions">
    <xsl:param name="purpose"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:variable name="preceding-dry-run">
        <xsl:apply-templates select="preceding-sibling::task" mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="following-dry-run">
        <xsl:apply-templates select="following-sibling::task" mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
            <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
            <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <!-- if first at its level, non-empty list, start the list environment -->
    <xsl:if test="($preceding-dry-run = '') and not($dry-run = '')">
        <!-- set the label style of this list       -->
        <!-- using features of the enumitem package -->
        <xsl:text>\begin{enumerate}[font=\bfseries,label=</xsl:text>
        <xsl:choose>
            <!-- three deep -->
            <xsl:when test="parent::task/parent::task">
                <xsl:text>(\Alph*),ref=\theenumi.\theenumii.\Alph*</xsl:text>
            </xsl:when>
            <!-- two deep -->
            <xsl:when test="parent::task">
                <xsl:text>(\roman*),ref=\theenumi.\roman*</xsl:text>
            </xsl:when>
            <!-- one deep -->
            <xsl:otherwise>
                <xsl:text>(\alph*),ref=\alph*</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>]&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="not($dry-run = '')">
        <!-- always a list item -->
        <xsl:text>\item</xsl:text>
        <!-- hard-code the number when duplicating, since some items -->
        <!-- are absent, and then automatic numbering would be wrong -->
        <xsl:text>[(</xsl:text>
        <xsl:apply-templates select="." mode="list-number" />
        <xsl:text>)]</xsl:text>
        <!-- no label since duplicating -->
        <!-- more structured versions first -->
        <xsl:choose>
            <!-- introduction?, task+, conclusion? -->
            <xsl:when test="task">
                <xsl:if test="$b-has-statement">
                    <xsl:apply-templates select="introduction"/>
                </xsl:if>
                <xsl:apply-templates select="task" mode="solutions">
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint" select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer" select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
                <xsl:if test="$b-has-statement">
                    <xsl:apply-templates select="conclusion"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="exercise-components">
                    <xsl:with-param name="b-original" select="false()"/>
                    <xsl:with-param name="purpose" select="$purpose" />
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint" select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer" select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution" select="$b-has-solution" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- if last at its level, non-empty-list, end the list environment -->
    <xsl:if test="not($dry-run = '') and ($following-dry-run = '') ">
        <xsl:text>\end{enumerate}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- An aside goes into a framed box             -->
<!-- We do not distinguish biographical or       -->
<!-- historical semantically, but perhaps should -->
<!-- title is inline, boldface in mdframe setup  -->
<xsl:template match="&ASIDE-LIKE;">
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="p|&FIGURE-LIKE;|sidebyside" />
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Assemblages -->
<!-- Low-structure content, high-visibility presentation -->
<!-- Title is optional, keep remainders coordinated      -->
<xsl:template match="assemblage">
    <!-- environment, title, label string, newline -->
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="block-options"/>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates select="p|blockquote|pre|sidebyside|sbsgroup" />
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- A GOAL-LIKE element holds a list,         -->
<!-- surrounded by introduction and conclusion -->
<xsl:template match="&GOAL-LIKE;">
    <xsl:text>\begin{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <!-- Following is not consistent, might be better to    -->
    <!-- opt for a default title of one is not provided     -->
    <!-- Then maybe integrate with "block-options" template -->
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:if test="title">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id"/>
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="introduction" />
    <xsl:apply-templates select="ol|ul|dl" />
    <xsl:apply-templates select="conclusion" />
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="local-name(.)" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Paragraphs -->
<!-- \par *separates* paragraphs So look backward for          -->
<!-- cases where a paragraph would have been the previous      -->
<!-- thing in the output Not: "notation", "todo", index, etc   -->
<!-- Guarantee: Never a blank line, always finish with newline -->
<!--                                                           -->
<!-- Note: a paragraph could end with an item we want          -->
<!-- to look good in teh source, like a list or display        -->
<!-- math and we already have a newline so any subsequent      -->
<!-- content from the paragraph will start anwew.  But         -->
<!-- there might not be anything more to output.  So we        -->
<!-- always end with a %-newline combo.                        -->

<!-- TODO: maybe we could look backward at the end of a paragraph       -->
<!-- to see if the above scenario happens, and we could end gracefully. -->
<!-- Note: a commentary may be present in PTX, but not in LaTeX         -->
<xsl:template match="p">
    <xsl:if test="preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)][1][self::p or self::paragraphs or self::commentary or self::sidebyside]">
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <!-- we can't cross-reference here without an @xml:id -->
    <!-- place it on a line of its own just prior to guts -->
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label" />
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- In WeBWorK problems, a p whose only child is a fillin blank     -->
<!-- almost certainly means a question has been asked, and below it  -->
<!-- there is an entry field. In print, there is no need to print    -->
<!-- that entry field and removing it can save a lot of vertical     -->
<!-- space. This is in constrast with fillins in the middle of a p,  -->
<!-- where answer blanks need to be printed because of the fill      -->
<!-- in the blank nature of the quesiton.                            -->
<xsl:template match="p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][not(parent::li)]|p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][parent::li][preceding-sibling::*]" />




<!-- For a memo, not indenting the first paragraph helps -->
<!-- with alignment and the to/from/subject/date block   -->
<!-- TODO: maybe memo header should set this up          -->
<xsl:template match="memo/p[1]">
    <xsl:text>\noindent{}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax should be       -->
<!-- independent of output format.  Despite MathJax's     -->
<!-- broad array of capabilities, there are still some    -->
<!-- differences which we need to accomodate via abstract -->
<!-- templates.                                           -->

<!-- Inline Mathematics ("m") -->
<!-- We use the asymmetric LaTeX delimiters \( and \).     -->
<!-- For LaTeX these are not "robust", hence break moving  -->
<!-- items (titles, index), so use the "fixltx2e" package, -->
<!-- which declares \MakeRobust\( and \MakeRobust\)        -->
<!-- Note: LaTeX, unlike HTML, needs no help with          -->
<!-- clause-ending punctuation trailing inline math,       -->
<!-- it always does the right thing.  So when the general  -->
<!-- template for text nodes in -common goes to drop this  -->
<!-- punctuation, it also checks the $latex-processing     -->
<!-- global variable                                       -->
<!-- NB: we should be able to use templates to make this   -->
<!-- happen without the global variable                    -->

<!-- These two templates provide the delimiters for -->
<!-- inline math, implementing abstract templates.  -->
<xsl:template name="begin-inline-math">
    <xsl:text>\(</xsl:text>
</xsl:template>

<xsl:template name="end-inline-math">
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- This is the override for LaTeX processing,        -->
<!-- since punctuation following inline math is        -->
<!-- not a problem for traditional TeX's line-breaking -->
<xsl:template match="m" mode="get-clause-punctuation" />


<!-- Displayed Single-Line Math ("me", "men") -->

<!-- All displayed mathematics gets wrapped by  -->
<!-- an abstract template, a necessity for HTML -->
<!-- output.  It is unnecessary for LaTeX, and  -->
<!-- so just a copy machine.                    -->
<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="content" />
    <xsl:value-of select="$content" />
</xsl:template>


<!-- The default template just calls the modal "body"      -->
<!-- template needed for the HTML knowl production scheme. -->
<!-- The variables in the "body" template have the right   -->
<!-- defaults for this application                         -->
<xsl:template match="me|men">
    <xsl:apply-templates select="." mode="body" />
</xsl:template>

<xsl:template name="display-math-visual-blank-line">
    <xsl:text>%&#xa;</xsl:text>
</xsl:template>

<!-- "me" is not numbered, not a cross-reference target -->
<xsl:template match="me" mode="tag" />

<!-- Simply apply modal "label" template,  -->
<!-- to allow for LaTeX equation numbering -->
<xsl:template match="men|mrow" mode="tag">
    <xsl:apply-templates select="." mode="label" />
</xsl:template>

<!-- An mrow with a \label{} can be cross-referenced    -->
<!-- md/mdn and \notag in -common control much of this  -->
<!-- For a local tag, we need to provide the symbol AND -->
<!-- also provide a label for the cross-reference       -->
<xsl:template match="mrow[@tag]" mode="tag">
    <!-- if mrow has custom tag, we add it here -->
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
</xsl:template>

<!-- QED Here -->
<!-- 2018-11-20: we have abandoned the amsthm "proof"              -->
<!-- environment, in favor of tcolorbox.  But this is              -->
<!--   (a) some fancy XSL                                          -->
<!--   (b) perhaps useful if the LaTeX is recycled                 -->
<!-- So elsewhere, we redefine \qedhere to do nothing              -->
<!--                                                               -->
<!-- Analyze a final "mrow" or any "me"                            -->
<!-- Strictly LaTeX/amsthm, not a MathJax feature (yet? ever?)     -->
<!--   (1) Locate enclosing proof, quit if no such thing           -->
<!--   (2) Check an mrow for being numbered, do not clobber that   -->
<!--   (3) Locate all trailing element, text nodes                 -->
<!--       strip-space: between "mrow" and "md" or "mdn"           -->
<!--       strip-space: between final "p" and "proof"              -->
<!--   (4) Form nodes interior to proof, and trailing ("remnants") -->
<!--   (5) At very end of proof                                    -->
<!--      (a) if no more nodes, or                                 -->
<!--      (b) one node, totally whitespace and punctuation         -->
<!--          (we don't differentiate whitespace policy here)      -->
<!--   (6) Having survived all this write a \qedhere               -->
<!-- TODO: \qedhere also functions at the end of a list            -->
<xsl:template match="men" mode="qed-here" />

<xsl:template match="mrow|me" mode="qed-here">
    <!-- <xsl:message>here</xsl:message> -->
    <xsl:variable name="enclosing-proof" select="ancestor::proof" />
    <xsl:if test="$enclosing-proof and not(self::mrow and parent::md and @number='yes') and not(self::mrow and parent::mdn and not(@number='no'))">
        <xsl:variable name="proof-nodes" select="$enclosing-proof/descendant-or-self::*|$enclosing-proof/descendant-or-self::text()" />
        <xsl:variable name="trailing-nodes" select="following::*|following::text()" />
        <xsl:variable name="proof-remnants" select="$proof-nodes[count(.|$trailing-nodes) = count($trailing-nodes)]" />
        <xsl:choose>
            <xsl:when test="count($proof-remnants) = 0">
                <xsl:text>\qedhere</xsl:text>
            </xsl:when>
            <xsl:when test="(count($proof-remnants) = 1) and (translate(normalize-space($proof-remnants), $clause-ending-marks, '') = '')">
                <xsl:text>\qedhere</xsl:text>
            </xsl:when>
            <xsl:otherwise />
        </xsl:choose>
    </xsl:if>
</xsl:template>


<!-- Displayed Multi-Line Math ("md", "mdn") -->

<!-- The default template for the "md" and "mdn" containers   -->
<!-- just calls the modal "body" template needed for the HTML -->
<!-- knowl production scheme. The variables in the "body"     -->
<!-- template have the right defaults for this application    -->

<xsl:template match="md|mdn">
    <xsl:apply-templates select="." mode="body" />
</xsl:template>

<!-- Rows of Displayed Multi-Line Math ("mrow") -->
<!-- Template in -common is sufficient with abstract templates -->
<!--                                                           -->
<!-- (1) "display-page-break"                                  -->
<!-- (2) "qed-here"                                            -->

<!-- Page Breaks within Display Math -->
<!-- \allowdisplaybreaks is on globally always          -->
<!-- If parent has  break="no"  then surpress with a *  -->
<!-- Unless "mrow" has  break="yes" then leave alone    -->
<!-- no-op for the HTML version, where it is irrelevant -->

<xsl:template match="mrow" mode="display-page-break">
    <xsl:if test="parent::*/@break='no' and not(@break='yes')">
        <xsl:text>*</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Intertext -->
<!-- An <mrow> will provide trailing newline, -->
<!-- so we do the same here for visual source -->
<!-- We need to do this very differently for  -->
<!-- HTML (we fake it), so there is no        -->
<!-- implementation in the -common scheme     -->
<xsl:template match="intertext">
    <xsl:text>\intertext{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>


<!-- ##### -->
<!-- Index -->
<!-- ##### -->

<!-- Excellent built-in LaTeX support, HTML may lag -->

<!-- Unstructured                       -->
<!-- simple and quick, minimal features -->
<!-- Only supports  @sortby  attribute  -->
<xsl:template match="index[not(main) and not(index-list)] | idx[not(h)]">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Structured                                      -->
<!--   main - one only, optional @sortby             -->
<!--   sub - up two, optional, with optional @sortby -->
<!--   see, seealso - one total                      -->
<!--   @start, @finish support page ranges for print -->
<xsl:template match="index[main] | idx[h]">
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="h" />
    <xsl:apply-templates select="main" />
    <xsl:apply-templates select="sub" />
    <xsl:apply-templates select="see" />
    <xsl:apply-templates select="seealso" />
    <xsl:apply-templates select="@finish" />
    <xsl:text>}</xsl:text>
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Page Range, Finish Variant              -->
<!-- @start is a marker for END of a range   -->
<!-- End of page range duplicates it's start -->
<xsl:template match="index[@start] | idx[@start]">
    <xsl:variable name="start" select="id(@start)" />
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates select="$start/h" />
    <xsl:apply-templates select="$start/main" />
    <xsl:apply-templates select="$start/sub" />
    <xsl:apply-templates select="$start/see" />
    <xsl:apply-templates select="$start/seealso" />
    <xsl:apply-templates select="@start" />
    <xsl:text>}</xsl:text>
    <!-- do not introduce anymore whitespace into a "p" than there   -->
    <!-- already is, but do format these one-per-line outside of "p" -->
    <xsl:if test="not(ancestor::p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="index/main">
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="index/@sortby|main/@sortby|sub/@sortby|idx/@sortby|h/@sortby">
    <xsl:value-of select="." />
    <xsl:text>@</xsl:text>
</xsl:template>

<xsl:template match="index/sub">
    <xsl:text>!</xsl:text>
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="idx/h">
    <xsl:if test="preceding-sibling::h">
        <xsl:text>!</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="@sortby" />
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="index/see|idx/see">
    <xsl:text>|see{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="index/seealso|idx/seealso">
    <xsl:text>|seealso{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- finish  attribute suggests range (only) -->
<xsl:template match="@finish">
    <xsl:text>|(</xsl:text>
</xsl:template>

<!-- start  attribute marks end of range  -->
<xsl:template match="@start">
    <xsl:text>|)</xsl:text>
</xsl:template>

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Good match between basic HTML types and basic LaTeX types -->

<!-- Utility templates to translate MBX @label specification -->
<!-- for use with LaTeX enumitem package's label keyword     -->
<xsl:template match="ol" mode="latex-list-label">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <!-- deconstruct the left and right adornments of the label   -->
    <!-- or provide the default adornments, consistent with LaTeX -->
    <!-- in the middle, translate MBX codes for enumitem package  -->
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:value-of select="substring-before(@label, $mbx-format-code)" />
        </xsl:when>
        <xsl:when test="$mbx-format-code='a'">
            <xsl:text>(</xsl:text>
        </xsl:when>
        <xsl:otherwise />
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = '1'">\arabic*</xsl:when>
        <xsl:when test="$mbx-format-code = 'a'">\alph*</xsl:when>
        <xsl:when test="$mbx-format-code = 'A'">\Alph*</xsl:when>
        <xsl:when test="$mbx-format-code = 'i'">\roman*</xsl:when>
        <xsl:when test="$mbx-format-code = 'I'">\Roman*</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX ordered list label format code in LaTeX conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:value-of select="substring-after(@label, $mbx-format-code)" />
        </xsl:when>
        <xsl:when test="$mbx-format-code='a'">
            <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:when test="($mbx-format-code='a') or ($mbx-format-code='i') or ($mbx-format-code='A')">
            <xsl:text>.</xsl:text>
        </xsl:when>
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<xsl:template match="ul" mode="latex-list-label">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
   <xsl:choose>
        <xsl:when test="$mbx-format-code = 'disc'">\textbullet</xsl:when>
        <xsl:when test="$mbx-format-code = 'circle'">$\circ$</xsl:when>
        <xsl:when test="$mbx-format-code = 'square'">$\blacksquare$</xsl:when>
        <xsl:when test="$mbx-format-code = 'none'"></xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad MBX unordered list label format code in LaTeX conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Utility template to translate unordered    -->
<!-- list level to HTML list-style-type         -->
<!-- This is similar to Firefox default choices -->
<!-- but different in the fourth slot           -->
<!-- disc, circle, square, disc                 -->
<!-- TODO: cannot find text mode filled black square symbol -->
<!-- TODO: textcomp (now in main latex) has \textopenbullet (unexamined) -->
<xsl:template match="*" mode="latex-unordered-list-label-default">
    <xsl:variable name="level">
        <xsl:apply-templates select="." mode="unordered-list-level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$level='0'">\textbullet</xsl:when>
        <xsl:when test="$level='1'">$\circ$</xsl:when>
        <xsl:when test="$level='2'">$\blacksquare$</xsl:when>
        <xsl:when test="$level='3'">\textbullet</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: unordered list is more than 4 levels deep</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists themselves -->
<!-- If columns are specified, we        -->
<!-- wrap in the multicolumn environment -->
<xsl:template match="ol">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{enumerate}</xsl:text>
    <!-- override LaTeX defaults as indicated -->
    <xsl:if test="@label or ancestor::exercises or ancestor::worksheet or ancestor::reading-questions or ancestor::references">
        <xsl:text>[label=</xsl:text>
        <xsl:apply-templates select="." mode="latex-list-label" />
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
     <xsl:apply-templates />
    <xsl:text>\end{enumerate}&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- MBX unordered list scheme is distinct -->
<!-- from LaTeX's so we write out a label  -->
<!-- choice for each such list             -->
<xsl:template match="ul">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{itemize}[label=</xsl:text>
    <xsl:apply-templates select="." mode="latex-list-label" />
    <xsl:text>]&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{itemize}&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template match="dl">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\begin{multicols}{</xsl:text>
        <xsl:value-of select="@cols" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{description}&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{description}&#xa;</xsl:text>
    <xsl:if test="@cols">
        <xsl:text>\end{multicols}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- List Items -->
<!-- If the content is structured, we presume the last  -->
<!-- element ends the line with a newline of some sort. -->
<!-- If the content is unstructured, we end the line    -->
<!-- with at least some content (%) and a newline.      -->
<!-- Keep the tests here in sync with DTD.              -->

<!-- In an ordered list, an item can be a target -->
<!-- but only if it has an @xml:id to use        -->
<xsl:template match="ol/li">
    <xsl:text>\item</xsl:text>
    <!-- \label{} will separate content, if   -->
    <!-- employed, else we use an empty group -->
    <xsl:choose>
        <xsl:when test="@xml:id">
            <xsl:apply-templates select="." mode="label" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates />
    <xsl:if test="not(p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- In an unordered list, an item cannot be a target -->
<!-- So we use an empty group to end the \item        -->
<xsl:template match="ul/li">
    <xsl:text>\item{}</xsl:text>
    <xsl:apply-templates />
    <xsl:if test="not(p)">
        <xsl:text>%&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Description lists always have title as additional -->
<!-- argument In a description list, an item can be a  -->
<!-- target but only if it has an @xml:id to use       -->
<xsl:template match="dl/li">
    <xsl:text>\item[{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}]</xsl:text>
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label" />
    </xsl:if>
    <!-- title or label will protect -->
    <!-- content, so no {} ever      -->
    <xsl:apply-templates />
</xsl:template>

<!-- ###################################### -->
<!-- Static Versions of Interactive Content -->
<!-- ###################################### -->


<xsl:template match="audio|video|interactive">
    <!-- scale to fit into a side-by-side -->
    <xsl:variable name="width-percentage">
        <xsl:choose>
            <xsl:when test="ancestor::sidebyside">
                <xsl:apply-templates select="." mode="get-width-percentage" />
                <xsl:text>&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>100%</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Adjust lengths for just this interactive -->
    <!-- i.e., these values are local             -->
    <!-- maybe get this scale factor via general % sanitization -->
    <!-- 11em at 10pt is about 1.5 inches, we go a bit smaller  -->
    <!--  9em at 10pt is closer to 1.25 inches                  -->
    <xsl:variable name="width-scale" select="substring-before($width-percentage,'%') div 100" />
    <xsl:text>\setlength{\qrsize}{</xsl:text>
    <xsl:value-of select="9 * $width-scale" />
    <xsl:text>em}&#xa;</xsl:text>
    <!-- give over all additional space to preview image -->
    <!-- this forces QR code to left margin              -->
    <xsl:text>\setlength{\previewwidth}{\linewidth}&#xa;</xsl:text>
    <xsl:text>\addtolength{\previewwidth}{-\qrsize}&#xa;</xsl:text>

    <!-- left skip, right skip are necessary for embedding in a sidebyside -->
    <xsl:text>\begin{tcbraster}[raster columns=2, raster column skip=1pt, raster halign=center, raster force size=false, raster left skip=0pt, raster right skip=0pt]%&#xa;</xsl:text>

    <!-- preview image (supplied or scraped) -->
    <xsl:text>\begin{tcolorbox}[previewstyle, width=\previewwidth]%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="static-image" />
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\end{tcolorbox}%&#xa;</xsl:text>

    <!-- QR code to the right, or default [LINK] -->
    <xsl:text>\begin{tcolorbox}[qrstyle]%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="static-qr" />
    <xsl:text>\end{tcolorbox}%&#xa;</xsl:text>

    <xsl:variable name="the-caption">
        <xsl:apply-templates select="." mode="static-caption">
            <xsl:with-param name="width-scale" select="$width-scale" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="not($the-caption ='')">
        <xsl:text>\begin{tcolorbox}[captionstyle]%&#xa;</xsl:text>
        <xsl:text>\small </xsl:text>
        <xsl:value-of select="$the-caption" />
        <xsl:text>\end{tcolorbox}%&#xa;</xsl:text>
    </xsl:if>

    <xsl:text>\end{tcbraster}%&#xa;</xsl:text>
</xsl:template>

<!-- Should an author provide an alternate version of the -->
<!-- static representation of an interactive, we want to  -->
<!-- use it above all other possibilities.                -->
<!-- For now we process the "static" indiscriminantly     -->
<!-- NB: this might require an explicit priority          -->
<xsl:template match="interactive[static]">
    <xsl:apply-templates select="static"/>
</xsl:template>

<!-- Input a URL, get back LaTeX to construct a URL              -->
<!-- The macro \qrsize is set elsewhere (ie not here)            -->
<!-- By loading hyperref, we automatically get a version         -->
<!-- that also functions as a link (we color it black locally)   -->
<!-- It seems that special TeX characters (of a URL) are handled -->
<!-- A blank URL sends back failure indicator                    -->
<!-- TODO: switches for color, nolink in print   -->
<!-- TODO: size as parameter, defauls to \qrsize -->
<xsl:template match="*" mode="static-qr">
    <xsl:variable name="the-url">
        <xsl:apply-templates select="." mode="static-url" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="not($the-url = '')">
            <xsl:text>{\hypersetup{urlcolor=black}</xsl:text>
            <xsl:text>\qrcode[height=\qrsize]{</xsl:text>
                <xsl:value-of select="$the-url" />
            <xsl:text>}}%&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[QR LINK]</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Static URL's -->
<!-- Predictable and/or stable URLs for versions  -->
<!-- of interactives available online.  These are -->
<!--  -->
<!-- (1) "standalone" pages for author/local material,  -->
<!-- as a product of the HTML conversion -->
<!-- (2) computable addresses of network resources, -->
<!-- eg the YouTube page of a resource -->

<!-- point to HTML-produced, and canonically-hosted, standalone page -->
<!-- Eventually match on all interactives                            -->
<!-- NB baseurl is not assumed to have a trailing slash              -->

<xsl:template match="audio[@source]|video[@source]|interactive" mode="static-url">
    <xsl:value-of select="$baseurl"/>
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="standalone-filename" />
</xsl:template>

<!-- Natural override for YouTube videos               -->
<!-- Better - standalone page, with "View on You Tube" -->
<xsl:template match="video[@youtube|@youtubeplaylist]" mode="static-url">
    <xsl:apply-templates select="." mode="youtube-view-url" />
    <xsl:if test="@start">
        <xsl:text>\&amp;start=</xsl:text>
        <xsl:value-of select="@start" />
    </xsl:if>
    <xsl:if test="@end">
        <xsl:text>\&amp;end=</xsl:text>
        <xsl:value-of select="@end" />
    </xsl:if>
</xsl:template>

<!-- Vimeo view URL -->
<xsl:template match="video[@vimeo]" mode="static-url">
    <xsl:text>https://vimeo.com/</xsl:text>
    <xsl:value-of select="@vimeo"/>
</xsl:template>

<!-- Static Images -->
<!-- (1) @preview given in source -->
<!-- (2) scraped image, name via visible-id -->
<!-- https://tex.stackexchange.com/questions/47245/ -->
<!-- set-a-maximum-width-and-height-for-an-image    -->

<!-- needs work -->
<xsl:template match="audio" mode="static-image"/>

<xsl:template match="video" mode="static-image">
    <xsl:choose>
        <!-- has @preview, and is 'generic' -->
        <xsl:when test="@preview = 'generic'">
            <!-- We know the "Play" button has landscape orientation -->
            <!-- the "adjustbox" package will size correctly, OR we  -->
            <!-- could test aspect ratio against 1 and react with    -->
            <!-- the exclamation in the other part of the \resizebox -->
            <!-- https://tex.stackexchange.com/questions/170770/     -->
            <xsl:text>\resizebox{!}{\qrsize}{\genericpreview}</xsl:text>
        </xsl:when>
        <!-- has @preview -->
        <xsl:when test="@preview">
            <xsl:text>\includegraphics[width=0.80\linewidth,height=\qrsize,keepaspectratio]{</xsl:text>
            <xsl:value-of select="@preview" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- No good way to scrape image from a playlist, so do as with @preview='generic' for now -->
        <xsl:when test="@youtubeplaylist">
            <xsl:text>\resizebox{!}{\qrsize}{\genericpreview}</xsl:text>
        </xsl:when>
        <!-- nothing specified, look for scraped via visible-id -->
        <xsl:otherwise>
            <xsl:text>\includegraphics[width=0.80\linewidth,height=\qrsize,keepaspectratio]{</xsl:text>
            <xsl:value-of select="$directory.images" />
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="." mode="visible-id" />
            <xsl:text>.jpg</xsl:text>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="interactive" mode="static-image">
    <xsl:choose>
        <!-- has @preview -->
        <xsl:when test="@preview">
            <xsl:text>\includegraphics[width=0.80\linewidth,height=\qrsize,keepaspectratio]{</xsl:text>
            <xsl:value-of select="@preview" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- nothing specified, look for scraped via visible-id -->
        <!-- Critical: coordinate with "extract-interactive.xsl" -->
        <xsl:otherwise>
            <xsl:variable name="default-preview-image">
                <xsl:value-of select="$directory.images" />
                <xsl:text>/</xsl:text>
                <xsl:apply-templates select="." mode="visible-id" />
                <xsl:text>-preview.png</xsl:text>
            </xsl:variable>
            <xsl:text>\IfFileExists{</xsl:text>
            <xsl:value-of select="$default-preview-image"/>
            <xsl:text>}%&#xa;</xsl:text>
            <xsl:text>{\includegraphics[width=0.80\linewidth,height=\qrsize,keepaspectratio]{</xsl:text>
            <xsl:value-of select="$default-preview-image"/>
            <xsl:text>}}%&#xa;</xsl:text>
            <xsl:text>{\small{}Specify static image with \mono{@preview} attribute,\\Or create and provide automatic screenshot as \mono{</xsl:text>
            <xsl:value-of select="$default-preview-image"/>
            <xsl:text>} via the \mono{mbx} script}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="audio[@source]|video[@source]" mode="static-caption">
    <xsl:choose>
        <!-- author-supplied override -->
        <xsl:when test="caption">
            <xsl:apply-templates select="caption" />
        </xsl:when>
        <!-- nothing to say, empty is flag -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<xsl:template match="video[@youtube|@youtubeplaylist]" mode="static-caption">
    <xsl:param name="width-scale" />
    <xsl:choose>
        <!-- author-supplied override -->
        <xsl:when test="caption">
            <xsl:apply-templates select="caption" />
        </xsl:when>
        <!-- identification, url for typing-in -->
        <xsl:when test="$width-scale &gt; 0.70">
            <xsl:text>YouTube: </xsl:text>
            <xsl:variable name="visual-url">
                <c>
                    <xsl:apply-templates select="." mode="youtube-view-url" />
                </c>
            </xsl:variable>
            <xsl:apply-templates select="exsl:node-set($visual-url)/*" />
        </xsl:when>
        <xsl:when test="$width-scale &gt; 0.4499">
            <xsl:variable name="visual-url">
                <c>
                    <xsl:apply-templates select="." mode="youtube-view-url" />
                </c>
            </xsl:variable>
            <xsl:apply-templates select="exsl:node-set($visual-url)/*" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>YT: </xsl:text>
            <xsl:variable name="visual-url">
                <c>
                    <xsl:value-of select="@youtube|@youtubeplaylist" />
                </c>
            </xsl:variable>
            <xsl:apply-templates select="exsl:node-set($visual-url)/*" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="video[@vimeo]" mode="static-caption">
    <xsl:variable name="visual-url">
        <c>
            <xsl:text>vimeo.com/</xsl:text>
            <xsl:value-of select="@vimeo"/>
        </c>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($visual-url)/*"/>
</xsl:template>

<xsl:template match="video[@youtube|@youtubeplaylist]" mode="youtube-view-url">
    <xsl:variable name="youtube">
        <xsl:choose>
            <xsl:when test="@youtubeplaylist">
                <xsl:value-of select="normalize-space(@youtubeplaylist)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space(str:replace(@youtube, ',', ' '))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>https://www.youtube.com/</xsl:text>
    <xsl:choose>
        <xsl:when test="@youtubeplaylist">
            <xsl:text>playlist?list=</xsl:text>
            <xsl:value-of select="$youtube" />
        </xsl:when>
        <xsl:when test="contains($youtube, ' ')">
            <xsl:text>watch_videos?video_ids=</xsl:text>
            <xsl:value-of select="str:replace($youtube, ' ', ',')" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>watch?v=</xsl:text>
            <xsl:value-of select="$youtube" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="interactive[@geogebra]" mode="static-caption">
    <xsl:choose>
        <!-- author-supplied override -->
        <xsl:when test="caption">
            <xsl:apply-templates select="caption" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\mono{www.geogebra.org/material/iframe/id/</xsl:text>
            <xsl:value-of select="@geogebra"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="interactive[@desmos]" mode="static-caption">
    <xsl:choose>
        <!-- author-supplied override -->
        <xsl:when test="caption">
            <xsl:apply-templates select="caption" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\mono{www.desmos.com/calculator/</xsl:text>
            <xsl:value-of select="@desmos"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="interactive[@wolfram-cdf]" mode="static-caption">
    <xsl:choose>
        <!-- author-supplied override -->
        <xsl:when test="caption">
            <xsl:apply-templates select="caption" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\mono{www.wolframcloud.com/objects/</xsl:text>
            <xsl:value-of select="@wolfram-cdf"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Nothing automatic to say about non-server interactives -->
<xsl:template match="interactive" mode="static-caption">
    <xsl:choose>
        <!-- author-supplied override -->
        <xsl:when test="caption">
            <xsl:apply-templates select="caption" />
        </xsl:when>
        <!-- nothing to say, empty is flag -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<!-- ############ -->
<!-- Music Scores -->
<!-- ############ -->

<!-- Embed an interactive score from MuseScore                          -->
<!-- Flag: score element has two MuseScore-specific attributes          -->
<!-- https://musescore.org/user/{usernumber}/scores/{scorenumber}/embed -->
<!-- into an iframe with width and height (todo)                        -->
<xsl:template match="score[@musescoreuser and @musescore]">
    <xsl:text>[\mono{\nolinkurl{https://musescore.org/user/</xsl:text>
    <xsl:value-of select="@musescoreuser" />
    <xsl:text>/scores/</xsl:text>
    <xsl:value-of select="@musescore" />
    <xsl:text>}} not yet realized in \LaTeX]&#xa;</xsl:text>
</xsl:template>

<!-- ######## -->
<!-- SI Units -->
<!-- ######## -->

<xsl:template match="quantity">
    <xsl:choose>
        <!-- no magnitude, only units -->
        <xsl:when test="not(mag) and (unit or per)">
            <xsl:text>\si{</xsl:text>
            <xsl:apply-templates select="unit"/>
            <xsl:apply-templates select="per"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- magnitude, plus units -->
        <xsl:when test="mag and (unit or per)">
            <xsl:text>\SI{</xsl:text>
            <xsl:value-of select="mag"/>
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates select="unit"/>
            <xsl:apply-templates select="per"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- magnitude only -->
        <xsl:when test="mag">
            <xsl:text>\num{</xsl:text>
            <xsl:value-of select="mag"/>
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- nothing (really should be caught in schema) -->
        <!-- but no real harm in just doing nothing      -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<xsl:template match="unit|per">
    <xsl:if test="self::per">
        <xsl:text>\per</xsl:text>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:text>\</xsl:text>
        <xsl:value-of select="@prefix"/>
    </xsl:if>
    <!-- base unit is required -->
    <xsl:text>\</xsl:text>
    <xsl:value-of select="@base"/>
    <!-- optional exponent -->
    <xsl:if test="@exp">
        <xsl:text>\tothe{</xsl:text>
            <xsl:value-of select="@exp"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Actual Quotations                -->
<!-- TODO: <quote> element for inline -->
<xsl:template match="blockquote">
    <xsl:text>\begin{quote}</xsl:text>
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label"/>
    </xsl:if>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{quote}&#xa;</xsl:text>
</xsl:template>

<!-- ############ -->
<!-- Attributions -->
<!-- ############ -->

<!-- At end of: blockquote, preface, foreword       -->
<!-- free-form for one line, or structured as lines -->
<!-- LaTeX lacks a quotation dash, emdash instead   -->
<!-- Discourage a page break prior                  -->
<!-- TODO: make a rule for quotation-dash?          -->

<!-- Single line, mixed-content                     -->
<!-- Or structured by "line" elements               -->
<!-- Quotation dash if within blockquote            -->
<!-- A table, pushed right, with left-justification -->
<!-- TODO: CMOS says blockquote-attribution goes in -->
<!-- parentheses (see 5e, 11.81), while this style  -->
<!-- is for chapter epigraphs (see 5e, 1.39, 11.40) -->
<xsl:template match="attribution">
    <xsl:text>\nopagebreak\par%&#xa;</xsl:text>
    <xsl:text>\hfill</xsl:text>
    <xsl:if test="parent::blockquote">
        <xsl:call-template name="mdash-character"/>
        <!-- remove the left-side column spacing -->
        <xsl:text>{\setlength{\tabcolsep}{0pt}</xsl:text>
    </xsl:if>
    <xsl:text>\begin{tabular}[t]{l@{}}&#xa;</xsl:text>
    <xsl:choose>
        <xsl:when test="line">
            <xsl:apply-templates select="line" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{tabular}</xsl:text>
    <!-- end group with table spacing change -->
    <xsl:if test="parent::blockquote">
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\\\par&#xa;</xsl:text>
</xsl:template>

<!-- Emphasis -->
<xsl:template match="em">
    <xsl:text>\emph{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Alert -->
<!-- \alert{} defined in preamble as semantic macro -->
<xsl:template match="alert">
    <xsl:text>\alert{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Insert (an edit) -->
<!-- \inserted{} defined in preamble as semantic macro -->
<xsl:template match="insert">
    <xsl:text>\inserted{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<xsl:template match="title//insert|shortitle//insert">
    <xsl:text>\protect\inserted{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Delete (an edit) -->
<!-- \deleted{} defined in preamble as semantic macro -->
<xsl:template match="delete">
    <xsl:text>\deleted{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<xsl:template match="title//delete|shortitle//delete">
    <xsl:text>\protect\deleted{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Stale (no longer relevant) -->
<!-- \stale{} defined in preamble as semantic macro -->
<xsl:template match="stale">
    <xsl:text>\stale{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<xsl:template match="title//stale|shorttitle//stale">
    <xsl:text>\protect\stale{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Term (defined terms) -->
<!-- \terminology{} defined in preamble as semantic macro -->
<xsl:template match="term">
    <xsl:text>\terminology{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Acronyms, Initialisms, Abbreviations -->
<!-- abbreviation: contracted form                             -->
<!-- acronym: initials, pronounced as a word (eg SCUBA, RADAR) -->
<!-- initialism: one letter at a time, (eg CIA, FBI)           -->
<!-- All use (no-op) semantic macros, defined in preamble      -->
<!-- TODO:  Test here for content ends in a period            -->
<!-- if next char is space, use macro that accomplishes "\@." -->
<!-- if next char is a char, use macro for .\@                -->
<!-- BUT if new sentence, then just leave the period alone    -->
<xsl:template match="abbr">
    <xsl:text>\abbreviation{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="acro">
    <xsl:text>\acronym{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="init">
    <xsl:text>\initialism{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Titles migrate to PDF bookmarks/ToC and need to be handled  -->
<!-- differently, even if we haven't quite figured out how       -->
<xsl:template match="title//abbr|shortitle//abbr">
    <xsl:text>\abbreviationintitle{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="title//acro|shortitle//acro">
    <xsl:text>\acronymintitle{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="title//init|shortitle//acro">
    <xsl:text>\initialismintitle{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- ############# -->
<!-- External URLs -->
<!-- ############# -->

<!-- We escape all the problem LaTeX characters      -->
<!-- when given in the @href attribute, the \url{}   -->
<!-- and \href{}{} seem to do the right thing        -->
<!-- and they do better in footnotes and table cells -->
<!-- Within titles, we just produce (formatted)      -->
<!-- text, but nothing active                        -->

<xsl:template match="url">
    <!-- choose a macro, font change, or active link -->
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <!-- switch to node-set with "c" if characters need escaping -->
            <xsl:text>\mono{</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\url{</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- sanitize the URL for LaTeX output -->
    <xsl:call-template name="escape-url-to-latex">
        <xsl:with-param name="text">
            <xsl:value-of select="@href" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Checking for "content-less" form           -->
<!-- http://stackoverflow.com/questions/9782021 -->
<xsl:template match="url[* or normalize-space()]">
    <xsl:choose>
        <!-- just the content, ignore the actual URL -->
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:apply-templates />
        </xsl:when>
        <!-- the functional version, usually -->
        <xsl:otherwise>
            <xsl:text>\href{</xsl:text>
            <xsl:call-template name="escape-url-to-latex">
                <xsl:with-param name="text">
                    <xsl:value-of select="@href" />
                </xsl:with-param>
            </xsl:call-template>
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates />
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############# -->
<!-- Verbatim Text -->
<!-- ############# -->

<!-- Code, inline -->
<!-- We escape every possible problematic character before     -->
<!-- applying a macro which will presumably apply a typewriter -->
<!-- font (which is not presumed to get strict mono spacing).  -->
<xsl:template match="c">
    <xsl:text>\mono{</xsl:text>
    <xsl:call-template name="escape-text-to-latex">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- 100% analogue of LaTeX's verbatim            -->
<!-- environment or HTML's <pre> element          -->
<!-- TODO: center on page with fancyvrb/BVerbatim -->
<!-- and \centering in a custom semantic macro?   -->

<!-- cd is for use in paragraphs, inline            -->
<!-- One line is mixed content, and should be tight -->
<!-- Formatted for visual appeal in LaTeX source    -->
<!-- "cd" could be first in a paragraph, so do not  -->
<!-- drop an empty line                             -->
<xsl:template match="cd">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\begin{codedisplay}&#xa;</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{codedisplay}&#xa;</xsl:text>
</xsl:template>

<!-- With a "cline" element present, we assume   -->
<!-- that is the entire structure (see the cline -->
<!-- template in the mathbook-common.xsl file)   -->
<xsl:template match="cd[cline]">
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\begin{codedisplay}&#xa;</xsl:text>
    <xsl:apply-templates select="cline" />
    <xsl:text>\end{codedisplay}&#xa;</xsl:text>
</xsl:template>

<!-- "pre" is analogous to the HTML tag of the same name -->
<!-- The "interior" templates decide between two styles  -->
<!--   (a) clean up raw text, just like for Sage code    -->
<!--   (b) interpret cline as line-by-line structure     -->
<!-- (See templates in xsl/mathbook-common.xsl file)     -->
<!-- Then wrap in a  verbatim  environment               -->
<xsl:template match="pre">
    <xsl:text>\begin{preformatted}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="interior"/>
    <xsl:text>\end{preformatted}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="email">
    <xsl:text>\href{mailto:</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>}{\nolinkurl{</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>}}</xsl:text>
</xsl:template>


<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- Across all possibilities                     -->
<!-- See mathbook-common.xsl for discussion       -->
<!-- See default LaTeX2e textcomp symbols at:     -->
<!-- http://hevea.inria.fr/examples/test/sym.html -->

<!-- Note: characters given by argument-less macros    -->
<!-- should finish with an empty group ({}) so that    -->
<!-- they do not run-in to subsequent text.            -->
<!-- Alternatives:                                     -->
<!--   1.  Wrap macro in a group, eg "{\foo}".         -->
<!--       Disrupts any kerning that might occur.      -->
<!--   2.  Add a trailing space, eg "\foo ".           -->
<!--       Breaks when output is edited, lines broken. -->
<!--   3.  \xspace might work after words.             -->
<!--       Even if followed by punctuation (?).  Ugly. -->

<!--           -->
<!-- XML, HTML -->
<!--           -->

<!-- & < > -->

<!-- Ampersand -->
<xsl:template name="ampersand-character">
    <xsl:text>\&amp;</xsl:text>
</xsl:template>

<!-- Less Than -->
<xsl:template name="less-character">
    <xsl:text>\textless{}</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template name="greater-character">
    <xsl:text>\textgreater{}</xsl:text>
</xsl:template>

<!--       -->
<!-- LaTeX -->
<!--       -->

<!-- # $ % ^ & _ { } ~ \ -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template name="hash-character">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template name="dollar-character">
    <xsl:text>\textdollar{}</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template name="percent-character">
    <xsl:text>\%</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<xsl:template name="circumflex-character">
    <xsl:text>\textasciicircum{}</xsl:text>
</xsl:template>

<!-- Ampersand -->
<!-- Handled above -->

<!-- Underscore -->
<xsl:template name="underscore-character">
    <xsl:text>\textunderscore{}</xsl:text>
</xsl:template>

<!-- Left Brace -->
<xsl:template name="lbrace-character">
    <xsl:text>\textbraceleft{}</xsl:text>
</xsl:template>

<!-- Right  Brace -->
<xsl:template name="rbrace-character">
    <xsl:text>\textbraceright{}</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template name="tilde-character">
    <xsl:text>\textasciitilde{}</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template name="backslash-character">
    <xsl:text>\textbackslash{}</xsl:text>
</xsl:template>

<!-- Other characters -->

<!-- Asterisk -->
<!-- Centered as a character, not an exponent -->
<xsl:template name="asterisk-character">
    <xsl:text>\textasteriskcentered{}</xsl:text>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template name="lsq-character">
    <xsl:text>`</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template name="rsq-character">
    <xsl:text>'</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template name="lq-character">
    <xsl:text>``</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template name="rq-character">
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- Left Bracket -->
<xsl:template name="lbracket-character">
    <xsl:text>[</xsl:text>
</xsl:template>

<!-- Right Bracket -->
<xsl:template name="rbracket-character">
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- Left Double Bracket -->
<xsl:template name="ldblbracket-character">
    <xsl:text>\textlbrackdbl{}</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<xsl:template name="rdblbracket-character">
    <xsl:text>\textrbrackdbl{}</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template name="langle-character">
    <xsl:text>\textlangle{}</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template name="rangle-character">
    <xsl:text>\textrangle{}</xsl:text>
</xsl:template>

<!-- Vertical Bar -->
<!-- Bringhurst: a "pipe" is a broken bar -->
<!-- Exists as \textbrokenbar             -->
<xsl:template name="bar-character">
    <xsl:text>\textbar{}</xsl:text>
</xsl:template>

<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template name="ellipsis-character">
    <xsl:text>\textellipsis{}</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<!-- http://tex.stackexchange.com/questions/19180/which-dot-character-to-use-in-which-context -->
<xsl:template name="midpoint-character">
    <xsl:text>\textperiodcentered{}</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<!-- http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/  -->
<xsl:template name="swungdash-character">
    <xsl:text>\swungdash{}</xsl:text>
</xsl:template>
<!-- Protect the version of the macro appearing in titles -->
<!-- This is an override of the base *template*           -->
<xsl:template match="title//swungdash|shortitle//swungdash">
    <xsl:text>\protect</xsl:text>
    <xsl:call-template name="swungdash-character"/>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template name="permille-character">
    <xsl:text>\textperthousand{}</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template name="pilcrow-character">
    <xsl:text>\textpilcrow{}</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template name="section-mark-character">
    <xsl:text>\textsection{}</xsl:text>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text -->
<xsl:template name="times-character">
    <xsl:text>\texttimes{}</xsl:text>
</xsl:template>

<!-- Slash -->
<!-- Forward slash, or virgule (see solidus)   -->
<!-- This should allow a linebreak, not tested -->
<xsl:template name="slash-character">
    <xsl:text>\slash{}</xsl:text>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<!-- This should not allow a linebreak, not tested -->
<xsl:template name="solidus-character">
    <xsl:text>\textfractionsolidus{}</xsl:text>
</xsl:template>

<!-- Backtick -->
<!-- This is the "accent grave" character.                 -->
<!-- Unicode Character 'GRAVE ACCENT' (U+0060)             -->
<!-- Really it is a modifier.  But as an ASCII character   -->
<!-- on most keyboards it gets used in computer languages. -->
<!-- Normally you would use this in verbatim contexts.     -->
<!-- It is not a left-quote (see <lsq />0, nor is it a     -->
<!-- modifier.  If you really want this character in a     -->
<!-- text context use this empty element.  For example,    -->
<!-- this is a character Markdown uses, so we want to      -->
<!-- provide this safety valve.                            -->
<xsl:template name="backtick-character">
    <xsl:text>\textasciigrave{}</xsl:text>
</xsl:template>

<!-- All Latin abbreviations are defined in -common    -->
<!-- since they are largely very simple.  But we       -->
<!-- implement the final period with a named template, -->
<!-- so we can get better behavior from LaTeX, mostly  -->
<!-- avoiding confusion with the end of a sentence.    -->

<!-- \@ following a period makes it an abbreviation, not the end of          -->
<!-- a sentence. So use it for abbreviations which will not end a sentence   -->
<!-- Best: \makeatletter\newcommand\etc{etc\@ifnextchar.{}{.\@}}\makeatother -->
<!-- http://latex-alive.tumblr.com/post/827168808/                           -->
<!-- correct-punctuation-spaces                                              -->
<!-- https://tex.stackexchange.com/questions/22561/                          -->
<!-- what-is-the-proper-use-of-i-e-backslash-at                              -->

<xsl:template name="abbreviation-period">
    <xsl:text>.\@</xsl:text>
</xsl:template>

<!-- Copyright symbol -->
<!-- http://tex.stackexchange.com/questions/1676/             -->
<!-- how-to-get-good-looking-copyright-and-registered-symbols -->
<xsl:template name="copyright-character">
    <xsl:text>\textcopyright{}</xsl:text>
</xsl:template>

<!-- Phonomark symbol -->
<xsl:template name="phonomark-character">
    <xsl:text>\textcircledP{}</xsl:text>
</xsl:template>

<!-- Copyleft symbol -->
<xsl:template name="copyleft-character">
    <xsl:text>\textcopyleft{}</xsl:text>
</xsl:template>

<!-- Registered symbol -->
<xsl:template name="registered-character">
    <xsl:text>\textregistered{}</xsl:text>
</xsl:template>

<!-- Trademark symbol -->
<xsl:template name="trademark-character">
    <xsl:text>\texttrademark{}</xsl:text>
</xsl:template>

<!-- Servicemark symbol -->
<xsl:template name="servicemark-character">
    <xsl:text>\textservicemark{}</xsl:text>
</xsl:template>

<!-- Degree -->
<xsl:template name="degree-character">
    <xsl:text>\textdegree{}</xsl:text>
</xsl:template>

<!-- Prime -->
<!-- A construction such as  \(^{\prime}\)  looks much better,     -->
<!-- but will require a lot of extra care in the "text-processing" -->
<!-- template since all this math-mode will need to be protected   -->
<!-- at the outset.  Bringhurst opines that many text fonts lack   -->
<!-- a prime and/or double-prime glyph, and LaTeX does not seem    -->
<!-- to have any good way to realize them without using math-mode. -->
<xsl:template name="prime-character">
    <xsl:text>\textquotesingle{}</xsl:text>
</xsl:template>

<!-- Double Prime -->
<xsl:template name="dblprime-character">
    <xsl:text>\textquotesingle\textquotesingle{}</xsl:text>
</xsl:template>

<!-- Fill-in blank -->
<!-- \fillin{} defined in preamble as semantic macro       -->
<!-- argument is number of "em", Bringhurst suggests 5/11  -->
<!-- \rule works in text and in math (unlike HTML/MathJax) -->
<xsl:template match="fillin">
    <xsl:variable name="characters">
        <xsl:choose>
            <xsl:when test="@characters">
                <xsl:value-of select="@characters" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>10</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>\fillin{</xsl:text>
    <xsl:value-of select="5 * $characters div 11" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>$\Rightarrow$</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>$\Leftarrow$</xsl:text>
</xsl:template>

<!-- TeX, LaTeX -->
<!-- PreTeXt is in -common -->
<xsl:template match="latex">
    <xsl:text>\LaTeX{}</xsl:text>
</xsl:template>
<xsl:template match="tex">
    <xsl:text>\TeX{}</xsl:text>
</xsl:template>

<!-- Foreign words/idioms -->
<xsl:template match="foreign">
    <xsl:apply-templates select="." mode="begin-language" />
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="end-language" />
</xsl:template>

<!-- Single and Double Quote Groupings -->
<!-- LaTeX is a bit brain-dead when a single quote        -->
<!-- is up tight against a double quote, or vice-versa,   -->
<!-- as the three consecutive single-quote characters are -->
<!-- ambiguous.  So we protect single quotes anytime it   -->
<!-- could be dangerous, even if precedence might do the  -->
<!-- right thing.  Double quotes are unmolested since     -->
<!-- they will work fine even in consecutive runs         -->
<!-- We have to override the RTF routines here.           -->

<xsl:template match="q">
    <xsl:text>``</xsl:text>
    <xsl:apply-templates />
    <xsl:text>''</xsl:text>
</xsl:template>

<!-- We look left (up the tree) and right   -->
<!-- (down the tree) for adjacent groupings -->
<xsl:template match="sq">
    <xsl:choose>
        <!-- left quote, possibly protected in a group -->
        <xsl:when test="(parent::q or parent::sq) and not(preceding-sibling::*) and not(preceding-sibling::text())">
            <xsl:text>{`}</xsl:text>
        </xsl:when>
        <xsl:when test="(*|text())[1][self::q or self::sq]">
            <xsl:text>{`}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>`</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- content -->
    <xsl:apply-templates />
    <!-- right quote, possibly protected in a group -->
    <xsl:choose>
        <xsl:when test="(parent::q or parent::sq) and not(following-sibling::*) and not(following-sibling::text())">
            <xsl:text>{'}</xsl:text>
        </xsl:when>
        <xsl:when test="(*|text())[last()][self::q or self::sq]">
            <xsl:text>{'}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>'</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <xsl:variable name="fa-name">
        <xsl:choose>
            <!-- @latex (in FA style) is override for lagging package -->
            <xsl:when test="@latex">
                <xsl:value-of select="@latex"/>
            </xsl:when>
            <xsl:otherwise>
            <!-- for-each is just one node, but sets context for key() -->
                <xsl:for-each select="$icon-table">
                    <xsl:value-of select="key('icon-key', $icon-name)/@font-awesome"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>\fa</xsl:text>
    <xsl:call-template name="camel-case-font-name">
        <xsl:with-param name="text" select="$fa-name"/>
    </xsl:call-template>
    <xsl:text>{}</xsl:text>
</xsl:template>

<xsl:template name="camel-case-font-name">
    <xsl:param name="text"/>
    <xsl:choose>
        <xsl:when test="not(contains($text, '-'))">
            <xsl:value-of select="translate(substring($text, 1, 1), &LOWERCASE;, &UPPERCASE;)"/>
            <xsl:value-of select="substring($text, 2)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="first-part">
                <xsl:value-of select="substring-before($text, '-')"/>
            </xsl:variable>
            <xsl:value-of select="translate(substring($first-part, 1, 1), &LOWERCASE;, &UPPERCASE;)"/>
            <xsl:value-of select="substring($first-part, 2)"/>
            <xsl:call-template name="camel-case-font-name">
                <xsl:with-param name="text" select="substring-after($text, '-')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ############## -->
<!-- Keyboard Input -->
<!-- ############## -->

<xsl:template match="kbd[not(@name)]">
    <xsl:text>\kbd{</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="kbd[@name]">
    <!-- the name attribute of the "kbd" in text as a string -->
    <xsl:variable name="kbdkey-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <xsl:text>\kbd{</xsl:text>
        <!-- for-each is just one node, but sets context for key() -->
        <xsl:for-each select="$kbdkey-table">
            <xsl:value-of select="key('kbdkey-key', $kbdkey-name)/@latex" />
        </xsl:for-each>
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- ################ -->
<!-- Biological Names -->
<!-- ################ -->

<xsl:template match="taxon[not(genus) and not(species)]">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="taxon[genus or species]">
    <xsl:if test="genus">
        <xsl:text>\textit{</xsl:text>
        <xsl:apply-templates select="genus"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="genus and species">
        <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:if test="species">
        <xsl:text>\textit{</xsl:text>
        <xsl:apply-templates select="species"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>


<!-- Titles of Publications -->
<!-- 2018-02-05: Deprecate "booktitle" in favor of       -->
<!-- "pubtitle".  Will still maintain all for a while.   -->
<!-- CMOS:  When quoted in text or listed in a           -->
<!-- bibliography, titles of books, journals, plays,     -->
<!-- and other freestanding works are italicized; titles -->
<!-- of articles, chapters, and other shorter works      -->
<!-- are set in roman and enclosed in quotation marks.   -->
<!-- \pubtitle is a semantic macro defined only if       -->
<!-- "pubtitle" or "booktitle" is employed.  Adjust if   -->
<!-- deprecation is removed.                             -->
<xsl:template match="pubtitle|booktitle">
    <xsl:text>\pubtitle{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="articletitle">
    <xsl:call-template name="lq-character"/>
    <xsl:apply-templates/>
    <xsl:call-template name="rq-character"/>
</xsl:template>

<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- These are specific instances of abstract templates        -->
<!-- See the similar section of  mathbook-common.xsl  for more -->

<!-- TODO: Perhaps use LaTeX double and triple hyphen variants of  -->
<!-- en-dash and em-dash under some option for human-variant LaTeX -->

<xsl:template name="nbsp-character">
    <xsl:text>~</xsl:text>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:text>\textendash{}</xsl:text>
</xsl:template>

<xsl:template name="mdash-character">
    <xsl:text>\textemdash{}</xsl:text>
</xsl:template>

<!-- The abstract template for "mdash" consults a publisher option -->
<!-- for thin space, or no space, surrounding an em-dash.  So the  -->
<!-- "thin-space-character" is needed for that purpose, and does   -->
<!-- not have an associated empty PTX element.                     -->

<xsl:template name="thin-space-character">
    <xsl:text>\,</xsl:text>
</xsl:template>

<!-- Sage Cells -->

<!-- An abstract named template accepts input text and               -->
<!-- output text, then wraps it for print, including output          -->
<!-- But we do not write an environment if there isn't any content   -->
<!-- So conceivably, this template can do nothing (ie an empty cell) -->
<!-- As a named template, the context is a calling sage element,     -->
<!-- this could be reworked and many of the parameters inferred      -->
<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="in" />
    <xsl:param name="out" />
    <!-- Surrounding box gets clobbered if it is the first -->
    <!-- thing after a heading.  This could be excessive   -->
    <!-- if the cell is empty, but should not be harmful.  -->
    <!-- NB: maybe this should not even be called if all empty -->
    <xsl:if test="not(preceding-sibling::*[not(&SUBDIVISION-METADATA-FILTER;)])">
        <xsl:call-template name="leave-vertical-mode" />
    </xsl:if>
    <xsl:if test="$in!=''">
        <xsl:text>\begin{sageinput}&#xa;</xsl:text>
        <xsl:value-of select="$in" />
        <xsl:text>\end{sageinput}&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="$out!=''">
        <xsl:text>\begin{sageoutput}&#xa;</xsl:text>
        <xsl:value-of select="$out" />
        <xsl:text>\end{sageoutput}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- An abstract named template accepts input text -->
<!-- and wraps it, untouchable by default in print -->
<xsl:template name="sage-display-markup">
    <xsl:param name="in" />
    <xsl:if test="$in!=''">
        <xsl:text>\begin{sageinput}&#xa;</xsl:text>
        <xsl:value-of select="$in" />
        <xsl:text>\end{sageinput}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Type: "practice"; not much point to show to a print reader  -->
<!-- This overrides the default, which is a small annotated cell -->
<xsl:template match="sage[@type='practice']" />


<!-- Program Listings -->
<!-- The "listings-language" template is in the common file -->
<xsl:template match="program">
    <xsl:param name="width" select="''" />
    <xsl:variable name="language">
        <xsl:apply-templates select="." mode="listings-language" />
    </xsl:variable>
    <xsl:variable name="b-has-language" select="not($language = '')" />
    <xsl:text>\begin{program}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:choose>
        <xsl:when test="$b-has-language">
            <xsl:value-of select="$language" />
        </xsl:when>
        <!-- null language defined in preamble -->
        <xsl:otherwise>
            <xsl:text>none</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="input" />
    </xsl:call-template>
    <xsl:text>\end{program}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<xsl:template match="console">
    <!-- ignore prompt, and pick it up in trailing input  -->
    <xsl:text>\begin{console}&#xa;</xsl:text>
    <xsl:apply-templates select="input|output" />
    <xsl:text>\end{console}&#xa;</xsl:text>
</xsl:template>

<!-- match immediately preceding, only if a prompt:                   -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input">
    <!-- Prompt first, assumes does not exceed one line -->
    <xsl:call-template name="escape-console-prompt-output">
        <xsl:with-param name="text"  select="preceding-sibling::*[1][self::prompt]"/>
    </xsl:call-template>
    <!-- sanitize left-margin, etc                    -->
    <!-- then employ \consoleinput macro on each line -->
    <xsl:call-template name="wrap-console-input">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Output code gets massaged to remove a left margin, -->
<!-- leading blank lines, etc., then wrap as above-->
<xsl:template match="console/output">
    <xsl:call-template name="wrap-console-output">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text">
                    <xsl:call-template name="escape-console-prompt-output">
                        <xsl:with-param name="text"  select="."/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- TODO: consolidate/generalize next two templates -->

<!-- Line-by-line, apply \consoleinput macro defined in preamble -->
<xsl:template name="wrap-console-input">
    <xsl:param name="text" />
    <xsl:choose>
        <xsl:when test="$text=''" />
        <xsl:otherwise>
            <xsl:text>(*\consoleinput{</xsl:text>
                <xsl:call-template name="escape-console-input-to-latex">
                    <xsl:with-param name="text">
                        <xsl:value-of select="substring-before($text, '&#xa;')" />
                    </xsl:with-param>
                </xsl:call-template>
            <xsl:text>}*)</xsl:text>
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="wrap-console-input">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Line-by-line  -->
<xsl:template name="wrap-console-output">
    <xsl:param name="text" />
    <xsl:choose>
        <xsl:when test="$text=''" />
        <xsl:otherwise>
            <xsl:value-of select="substring-before($text, '&#xa;')" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="wrap-console-output">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############ -->
<!-- Interactives -->
<!-- ############ -->

<!-- Geogebra -->
<xsl:template match="interactive[@geogebra]" mode="info-text">
    <xsl:text>Geogebra: \href{https://www.geogebra.org/m/</xsl:text>
    <xsl:value-of select="@geogebra" />
    <xsl:text>}{\mono{www.geogebra.org/m/</xsl:text>
    <xsl:value-of select="@geogebra" />
    <xsl:text>}}</xsl:text>
</xsl:template>

<!-- Desmos -->
<xsl:template match="interactive[@desmos]" mode="info-text">
    <xsl:text>Desmos: \href{https://www.desmos.com/calculator/</xsl:text>
    <xsl:value-of select="@desmos" />
    <xsl:text>}{\mono{www.desmos.com/calculator/</xsl:text>
    <xsl:value-of select="@desmos" />
    <xsl:text>}}&#xa;</xsl:text>
</xsl:template>

<!-- CalcPlot3D -->
<xsl:template match="interactive[@platform='calcplot3d']" mode="info-text">
    <!-- code/url will need sanitization -->
    <xsl:text>CalcPlot3D: \href{https://www.monroecc.edu/faculty/paulseeburger/calcnsf/CalcPlot3D/}</xsl:text>
<!--     <xsl:text>CalcPlot3D: \href{https://www.monroecc.edu/faculty/paulseeburger/calcnsf/CalcPlot3D/?</xsl:text>
    <xsl:value-of select="code" />
 -->    <xsl:text>{\mono{www.monroecc.edu/faculty/paulseeburger/calcnsf/CalcPlot3D}}&#xa;</xsl:text>
</xsl:template>

<!-- JSXGraph -->
<xsl:template match="jsxgraph">
    <xsl:text>\par\smallskip\centerline{A deprecated JSXGraph interactive demonstration goes here in interactive output.}\smallskip&#xa;</xsl:text>
</xsl:template>

<!-- We sometimes need to explicitly leave LaTeX's vertical mode.     -->
<!-- But we try to be judicious about using this.  Overuse makes      -->
<!-- for bad spacing.                                                 -->
<!-- Explanation:  http://tex.stackexchange.com/questions/22852/      -->
<!-- function-and-usage-of-leavevmode                                 -->
<!--   "Use \leavevmode for all macros which could be used at         -->
<!--   the begin of the paragraph and add horizontal boxes            -->
<!--   by themselves (e.g. in form of text)."                         -->
<!-- Potential alternate solution: write a leading "empty" \mbox{}    -->
<!-- http://tex.stackexchange.com/questions/171220/                   -->
<!-- include-non-floating-graphic-in-a-theorem-environment            -->
<xsl:template name="leave-vertical-mode">
    <xsl:text>\leavevmode%&#xa;</xsl:text>
</xsl:template>

<xsl:template match="figure|table|list|listing" mode="environment-name">
    <!-- subfigures, etc -->
    <xsl:if test="ancestor::*[self::figure]">
        <xsl:text>sub</xsl:text>
    </xsl:if>
    <xsl:value-of select="local-name(.)"/>
    <!-- too many LaTeX names to clash with -->
    <xsl:text>ptx</xsl:text>
</xsl:template>

<!-- Figures, Listings -->
<!-- 0: enviroment name may be prefixed with "sub" -->
<!-- 1: caption text                               -->
<!-- 2: standard identifier for cross-references   -->
<!-- 3: empty, or a hard-coded number from -common -->
<xsl:template match="figure|listing">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="caption-full"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id"/>
    <xsl:text>}{</xsl:text>
    <xsl:if test="$b-latex-hardcode-numbers">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:if>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- images have margins and widths, so centering not needed -->
    <!-- Eventually everything in a figure should control itself -->
    <!-- or be flush left (or so)                                -->
    <xsl:if test="self::figure and not(image)">
        <xsl:text>\centering&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO: process meta-data, then restrict contents -->
    <!-- multiple, program|console                       -->
    <xsl:apply-templates select="*"/>
    <!-- reserve space for the caption -->
    <xsl:text>\tcblower&#xa;</xsl:text>
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- Tables, (Named) Lists -->
<!-- 0: enviroment name may be prefixed with "sub"  -->
<!-- 1: title text, bolded here, not in environment -->
<!-- 2: standard identifier for cross-references    -->
<!-- 3: empty, or a hard-coded number from -common  -->
<xsl:template match="table|list">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}{</xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id"/>
    <xsl:text>}{</xsl:text>
    <xsl:if test="$b-latex-hardcode-numbers">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:if>
    <xsl:text>}%&#xa;</xsl:text>
    <!-- A "list" has an introduction/conclusion, with a       -->
    <!-- list of some type in-between, and these will all      -->
    <!-- automatically word-wrap to fill the available width.  -->
    <!-- A "tabular" on the other hand, will have fixed-width, -->
    <!-- so needs to be explicitly centered.                   -->
    <!-- Note: centering seems to also happen (additionally)   -->
    <!-- for a "tabular" inside a sidebyside panel.            -->
    <xsl:if test="self::table">
        <xsl:text>\centering&#xa;</xsl:text>
    </xsl:if>
    <!-- TODO: process meta-data, then restrict contents -->
    <!-- tabular, introduction|list|conclusion           -->
    <xsl:apply-templates select="*"/>
    <!-- subcaption always goes in lower part -->
    <xsl:if test="ancestor::*[self::figure]">
        <xsl:text>\tcblower&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="environment-name"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>


<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- See xsl/mathbook-common.xsl for descriptions of the  -->
<!-- four modal templates which must be implemented here  -->
<!-- The main templates for "sidebyside" and "sbsgroup"   -->
<!-- are in xsl/mathbook-common.xsl, as befits containers -->

<!-- Note: Various end-of-line "%" are necessary to keep  -->
<!-- headings, panels, and captions together as one unit  -->
<!-- without a page -break, via the LaTeX                 -->
<!-- \nopagebreak=\nopagebreak[4] command                 -->

<xsl:template match="*" mode="panel-panel">
    <xsl:param name="width" />
    <xsl:param name="valign" />

    <xsl:text>\begin{sbspanel}{</xsl:text>
    <xsl:value-of select="substring-before($width,'%') div 100" />
    <xsl:text>}</xsl:text>
    <!-- 'top' is the sbspanel environment default -->
    <!-- could generate brackets of optional       -->
    <!-- argument outside of the choose            -->
    <xsl:choose>
        <xsl:when test="$valign = 'top'" />
        <xsl:when test="$valign = 'middle'">
            <xsl:text>[center]</xsl:text>
        </xsl:when>
        <xsl:when test="$valign = 'bottom'">
            <xsl:text>[bottom]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text>%&#xa;</xsl:text>
    <!-- Realize each panel's object -->
    <xsl:apply-templates select="."/>
    <xsl:text>\end{sbspanel}%&#xa;</xsl:text>
</xsl:template>


<!-- We take in all three rows of a LaTeX    -->
<!-- table and package them up appropriately -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="panels" />

    <xsl:variable name="number-panels" select="$layout/number-panels" />
    <xsl:variable name="left-margin" select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />
    <xsl:variable name="space-width" select="$layout/space-width" />

    <!-- TODO: Make "sidebyside" a 3-argument environment:          -->
    <!-- headings, panels, captions.  Then put "\nopagebreak"       -->
    <!-- into the definition, so it is "hidden" and not in the body -->

    <xsl:text>\begin{sidebyside}{</xsl:text>
    <xsl:value-of select="$number-panels" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="substring-before($left-margin, '%') div 100" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="substring-before($right-margin, '%') div 100" />
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="substring-before($space-width, '%') div 100" />
    <xsl:text>}%&#xa;</xsl:text>
    <!-- The main event -->
    <xsl:value-of select="$panels" />
    <xsl:text>\end{sidebyside}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- First: images in full-width contexts                   -->
<!-- naked images go into a tcolorbox for layout control    -->
<!-- figure/image (not in a sidebyside) into same tcolorbox -->
<xsl:template match="image[not(ancestor::sidebyside)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:text>\begin{image}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$layout/left-margin div 100"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$layout/width div 100"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$layout/right-margin div 100"/>
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="image-inclusion" />
    <xsl:text>\end{image}%&#xa;</xsl:text>
</xsl:template>

<!-- Second: images already constrained by side-by-side panels -->
<xsl:template match="image[ancestor::sidebyside]">
    <!-- get a newline if inside a "stack" -->
    <xsl:if test="parent::stack and preceding-sibling::*">
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="image-inclusion" />
</xsl:template>

<!-- Various versions of images have their width set to the         -->
<!-- prevailing available width.  This is \linewidth when:          -->
<!-- full text width is available, width is constrained (like in    -->
<!-- a list item), or width is constrained by a side-by-side panel. -->

<!-- With full source specified, default to PDF format -->
<xsl:template match="image[@source]" mode="image-inclusion">
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="@source" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:text>\includegraphics[width=\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="@source" mode="visible-id" />
    <xsl:if test="not($extension)">
        <xsl:text>.pdf&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Asymptote graphics language  -->
<!-- PDF's produced by mbx script -->
<xsl:template match="image[asymptote]" mode="image-inclusion">
    <xsl:text>\includegraphics[width=\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.pdf}&#xa;</xsl:text>
</xsl:template>

<!-- Sage graphics plots          -->
<!-- PDF's produced by mbx script -->
<!-- PNGs are fallback for 3D     -->
<xsl:template match="image[sageplot]" mode="image-inclusion">
    <xsl:text>\IfFileExists{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.pdf}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.pdf}}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=\linewidth]</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.png}}&#xa;</xsl:text>
</xsl:template>

<!-- LaTeX Image Code (tikz, pgfplots, pstricks, etc) -->
<!-- Clean indentation, drop into LaTeX               -->
<!-- See "latex-image-preamble" for critical parts    -->
<!-- Side-By-Side scaling happens there, could be here -->
<xsl:template match="image[latex-image-code]|image[latex-image]" mode="image-inclusion">
    <!-- tikz images go into a tcolorbox where \linewidth is reset. -->
    <!-- grouping reins in the scope of any local graphics settings -->
    <!-- we resize what tikz produces, to fill a containing box     -->
    <!-- changes to accomodate resizing to fit requested layouts -->
    <xsl:text>\resizebox{\linewidth}{!}{%&#xa;</xsl:text>
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="latex-image-code|latex-image" />
    </xsl:call-template>
    <xsl:text>}%&#xa;</xsl:text>
</xsl:template>

<!-- EXPERIMENTAL -->
<!-- use only for testing uses of QR codes          -->
<!-- this WILL change and/or disappear              -->
<!-- For LaTeX output only, place within an "image" -->
<!-- @size - a length LaTeX understands             -->
<!-- @href - realtive path or URL                   -->
<xsl:template match="image[qrcode-trial]">
    <xsl:apply-templates select="qrcode-trial" />
</xsl:template>

<xsl:template match="qrcode-trial">
    <xsl:text>{\hypersetup{urlcolor=black}</xsl:text>
    <xsl:text>\qrcode[height=</xsl:text>
    <xsl:value-of select="@size" />
    <xsl:text>]{</xsl:text>
        <xsl:value-of select="@href" />
    <xsl:text>}}%&#xa;</xsl:text>
</xsl:template>

<!-- was once direct-descendant of subdivision, this catches that -->
<xsl:template match="latex-image-code[not(parent::image)]">
    <xsl:message>MBX:WARNING: latex-image-code element should be enclosed by an image element</xsl:message>
</xsl:template>

<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="tikz">
    <xsl:message>MBX:WARNING: tikz element superceded by latex-image-code element</xsl:message>
    <xsl:message>MBX:WARNING: tikz package and necessary libraries should be included in docinfo/latex-image-preamble</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="asymptote">
    <xsl:message>MBX:WARNING: asymptote element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:text>\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.pdf}&#xa;</xsl:text>
</xsl:template>
<!-- 2015/02/08: Deprecated, still functional but not maintained -->
<xsl:template match="sageplot">
    <xsl:message>MBX:WARNING: sageplot element must be enclosed by an image element - deprecation (2015/02/08)</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:text>\IfFileExists{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.pdf}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.pdf}}%&#xa;</xsl:text>
    <xsl:text>{\includegraphics[width=0.80\textwidth]{</xsl:text>
    <xsl:value-of select="$directory.images" />
    <xsl:text>/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.png}}&#xa;</xsl:text>
</xsl:template>
<!-- ################################## -->
<!-- Deprecated Graphics Code Templates -->
<!-- ################################## -->

<!-- ############## -->
<!-- Tabular Layout -->
<!-- ############## -->

<xsl:template match="tabular">
    <!-- Abort if tabular's cols have widths summing to over 100% -->
    <xsl:call-template name="cap-width-at-one-hundred-percent">
        <xsl:with-param name="nodeset" select="col/@width" />
    </xsl:call-template>
    <!-- Determine global, table-wide properties -->
    <!-- set defaults here if values not given   -->
    <xsl:variable name="table-top">
        <xsl:choose>
            <xsl:when test="@top">
                <xsl:value-of select="@top" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-left">
        <xsl:choose>
            <xsl:when test="@left">
                <xsl:value-of select="@left" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-bottom">
        <xsl:choose>
            <xsl:when test="@bottom">
                <xsl:value-of select="@bottom" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-right">
        <xsl:choose>
            <xsl:when test="@right">
                <xsl:value-of select="@right" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>none</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-halign">
        <xsl:choose>
            <xsl:when test="@halign">
                <xsl:value-of select="@halign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>left</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="table-valign">
        <xsl:choose>
            <xsl:when test="@valign">
                <xsl:value-of select="@valign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>middle</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- get a newline if inside a "stack" -->
    <xsl:if test="parent::stack and preceding-sibling::*">
        <xsl:text>\par&#xa;</xsl:text>
    </xsl:if>
    <!-- center within a sidebyside if by itself       -->
    <!-- \centering needs a closing \par within a      -->
    <!-- defensive group if it is to be effective      -->
    <!-- https://tex.stackexchange.com/questions/23650 -->
    <!-- Necessary for both sidebyside/tabular AND sidebyside/table/tabular -->
    <!-- Does latter get a double-nested centering?                         -->
    <!-- Maybe this goes away with tcolorbox?                               -->
    <!-- NB: paired conditional way below!                                  -->
    <xsl:if test="ancestor::sidebyside">
        <xsl:text>{\centering%&#xa;</xsl:text>
    </xsl:if>
    <!-- Build latex column specification                         -->
    <!--   vertical borders (left side, right side, three widths) -->
    <!--   horizontal alignment (left, center, right)             -->
    <xsl:text>{\tabularfont%&#xa;</xsl:text>
    <xsl:text>\begin{tabular}{</xsl:text>
    <!-- start with left vertical border -->
    <xsl:call-template name="vrule-specification">
        <xsl:with-param name="width" select="$table-left" />
    </xsl:call-template>
    <xsl:choose>
        <!-- Potential for individual column overrides    -->
        <!--   Deduce number of columns from col elements -->
        <!--   Employ individual column overrides,        -->
        <!--   or use global table-wide values            -->
        <!--   write alignment (mandatory)                -->
        <!--   follow with right border (optional)        -->
        <xsl:when test="col">
            <xsl:for-each select="col">
                <xsl:call-template name="halign-specification">
                    <xsl:with-param name="align">
                        <xsl:choose>
                            <xsl:when test="@halign">
                                <xsl:value-of select="@halign" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$table-halign" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="vrule-specification">
                    <xsl:with-param name="width">
                        <xsl:choose>
                            <xsl:when test="@right">
                                <xsl:value-of select="@right" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$table-right" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:when>
        <!-- No col specifiaction                                  -->
        <!--   so default identically to global, table-wide values -->
        <!--   first row determines the  number of columns         -->
        <!--   write the alignment (mandatory)                     -->
        <!--   follow with right border (optional)                 -->
        <!-- TODO: error check each row for correct number of columns -->
        <xsl:otherwise>
            <xsl:variable name="ncols" select="count(row[1]/cell) + sum(row[1]/cell[@colspan]/@colspan) - count(row[1]/cell[@colspan])" />
            <xsl:call-template name="duplicate-string">
                <xsl:with-param name="count" select="$ncols" />
                <xsl:with-param name="text">
                    <xsl:call-template name="halign-specification">
                        <xsl:with-param name="align" select="$table-halign" />
                    </xsl:call-template>
                    <xsl:call-template name="vrule-specification">
                        <xsl:with-param name="width" select="$table-right" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}</xsl:text>
    <!-- column specification done -->
    <!-- top horizontal rule is specified after column specification -->
    <xsl:choose>
        <!-- A col element might indicate top border customizations   -->
        <!-- so we walk the cols to build a cline-style specification -->
        <xsl:when test="col/@top">
            <xsl:call-template name="column-cols">
                <xsl:with-param name="the-col" select="col[1]" />
                <xsl:with-param name="col-number" select="1" />
                <xsl:with-param name="clines" select="''" />
                <xsl:with-param name="table-top" select="$table-top"/>
                <xsl:with-param name="prior-top" select="'undefined'" />
                <xsl:with-param name="start-run" select="1" />
            </xsl:call-template>
        </xsl:when>
        <!-- with no customization, we have one continuous rule (if at all) -->
        <!-- use global, table-wide value of top specification              -->
        <xsl:otherwise>
            <xsl:call-template name="hrule-specification">
                <xsl:with-param name="width" select="$table-top" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
    <!-- now ready to build rows -->
    <xsl:text>&#xa;</xsl:text>
    <!-- table-wide values are needed to reconstruct/determine overrides -->
    <xsl:apply-templates select="row">
        <xsl:with-param name="table-left" select="$table-left" />
        <xsl:with-param name="table-bottom" select="$table-bottom" />
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
    </xsl:apply-templates>
    <!-- mandatory finish, exclusive of any final row specifications -->
    <xsl:text>\end{tabular}&#xa;</xsl:text>
    <!-- finish grouping for tabular font -->
    <xsl:text>}%&#xa;</xsl:text>
    <xsl:if test="ancestor::sidebyside">
        <xsl:text>\par}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- We recursively traverse the "col" elements of the "column" group         -->
<!-- The cline specification is accumulated in the clines variable            -->
<!-- A similar strategy is used to traverse the "cell" elements of each "row" -->
<!-- but becomes much more involved, see the "row-cells" template             -->
<xsl:template name="column-cols">
    <xsl:param name="the-col" />
    <xsl:param name="col-number" />
    <xsl:param name="clines" />
    <xsl:param name="table-top" />
    <xsl:param name="prior-top" />
    <xsl:param name="start-run" />
    <!-- Look ahead one column, anticipating recursion           -->
    <!-- but also probing for end of column group (no more cols) -->
    <xsl:variable name="next-col"  select="$the-col/following-sibling::col[1]" /> <!-- possibly empty -->
    <!-- The desired top border style for this column   -->
    <!-- Considered, but also paid forward as prior-top -->
    <xsl:variable name="current-top">
        <xsl:choose>
            <!-- cell specification -->
            <xsl:when test="$the-col/@top">
                <xsl:value-of select="$the-col/@top" />
            </xsl:when>
            <!-- inherited specification for top -->
            <xsl:otherwise>
                <xsl:value-of select="$table-top" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Formulate any necessary update to cline  -->
    <!-- information for the top border -->
    <xsl:variable name="updated-cline">
        <!-- write current cline information -->
        <xsl:value-of select="$clines" />
        <!-- is there a change, or end of column group, indicating need to flush -->
        <xsl:if test="not($the-col) or not($prior-top = $current-top)">
            <xsl:choose>
                <!-- end of column group and have never flushed -->
                <!-- hence a uniform top border                 -->
                <xsl:when test="not($the-col) and ($start-run = 1)">
                    <xsl:call-template name="hrule-specification">
                        <xsl:with-param name="width" select="$prior-top" />
                    </xsl:call-template>
                </xsl:when>
                <!-- write cline for up-to, and including, prior col   -->
                <!-- prior-top always lags, so never operate on col #1 -->
                <xsl:when test="($col-number != 1) and not($prior-top = 'none')">
                    <xsl:call-template name="crule-specification">
                        <xsl:with-param name="width" select="$prior-top" />
                        <xsl:with-param name="start" select="$start-run" />
                        <xsl:with-param name="finish" select="$col-number - 1" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- no update -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="new-start-run">
        <xsl:choose>
            <xsl:when test="$col-number = 1 or $prior-top = $current-top">
                <xsl:value-of select="$start-run" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$col-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- Call this template on next cell              -->
        <!-- Possibly passing an empty node (as sentinel) -->
        <xsl:when test="$the-col">
            <xsl:call-template name="column-cols">
                <xsl:with-param name="the-col" select="$next-col" />
                <xsl:with-param name="col-number" select="$col-number + 1" />
                <xsl:with-param name="clines" select="$updated-cline" />
                <xsl:with-param name="table-top" select="$table-top" />
                <xsl:with-param name="prior-top" select="$current-top" />
                <xsl:with-param name="start-run" select="$new-start-run" />
            </xsl:call-template>
        </xsl:when>
        <!-- At non-col, done with column group -->
        <!-- conclude line, dump cline info     -->
        <xsl:otherwise>
            <xsl:value-of select="$updated-cline" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="row">
    <xsl:param name="table-left" />
    <xsl:param name="table-bottom" />
    <xsl:param name="table-right" />
    <xsl:param name="table-halign" />
    <xsl:param name="table-valign" />
    <!-- inherit global table-wide values    -->
    <!-- or replace with row-specific values -->
    <xsl:variable name="row-left">
        <xsl:choose>
            <xsl:when test="@left">
                <xsl:value-of select="@left" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-left" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="row-bottom">
        <xsl:choose>
            <xsl:when test="@bottom">
                <xsl:value-of select="@bottom" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-bottom" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- End of the row is too late to see if we have the last one -->
    <!-- so we get it here and just kick it down the road          -->
    <xsl:variable name="last-row" select="not(following-sibling::row)" />
    <!-- Walking the row's cells, write contents and bottom borders -->
    <xsl:call-template name="row-cells">
        <xsl:with-param name="the-cell" select="cell[1]" />
        <xsl:with-param name="left-col" select="../col[1]" /> <!-- possibly empty -->
        <xsl:with-param name="left-column-number" select="1" />
        <xsl:with-param name="last-row" select="$last-row" />
        <xsl:with-param name="clines" select="''" />
        <xsl:with-param name="table-left" select="$table-left"/>
        <xsl:with-param name="table-bottom" select="$table-bottom"/>
        <xsl:with-param name="table-right" select="$table-right" />
        <xsl:with-param name="table-halign" select="$table-halign" />
        <xsl:with-param name="table-valign" select="$table-valign" />
        <xsl:with-param name="row-left" select="$row-left" />
        <xsl:with-param name="row-bottom" select="$row-bottom" />
        <xsl:with-param name="prior-bottom" select="'undefined'" />
        <xsl:with-param name="start-run" select="1" />
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Recursively traverse the "cell"'s of a "row" while simultaneously     -->
<!-- traversing the "col" elements of the column group, if present.        -->
<!-- Inspect the (previously) built column specifications to see if        -->
<!-- a \multicolumn is necessary for an override on a table entry          -->
<!-- Accumulate cline information to write at the end of the line/row.     -->
<!-- Study the "column-cols" template for a less-involved template         -->
<!-- that uses an identical strategy, if you want to see something simpler -->
<xsl:template name="row-cells">
    <xsl:param name="the-cell" />
    <xsl:param name="left-col" />
    <xsl:param name="left-column-number" />
    <xsl:param name="last-row" />
    <xsl:param name="clines" />
    <xsl:param name="table-left" />
    <xsl:param name="table-bottom" />
    <xsl:param name="table-right" />
    <xsl:param name="table-halign" />
    <xsl:param name="table-valign" />
    <xsl:param name="row-left" />
    <xsl:param name="row-bottom" />
    <xsl:param name="prior-bottom" />
    <xsl:param name="start-run" />
    <!-- A cell may span several columns, or default to just 1              -->
    <!-- When colspan is not trivial, we identify the left and right ends   -->
    <!-- of the span, both as col elements and as column numbers            -->
    <!-- When colspan is trivial, the left and right versions are identical -->
    <!-- Left is used for left border and for horizontal alignment          -->
    <!-- Right is used for right border                                     -->
    <!-- Left (less 1) is used for lagging cline flushes                    -->
    <xsl:variable name="column-span">
        <xsl:choose>
            <xsl:when test="$the-cell/@colspan">
                <xsl:value-of select="$the-cell/@colspan" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>1</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- For a "normal" 1-column cell these variables effectively make copies -->
    <xsl:variable name="right-column-number" select="$left-column-number + $column-span - 1" />
    <xsl:variable name="right-col" select="($left-col/self::*|$left-col/following-sibling::col)[position()=$column-span]" />
    <!-- recreate the column specification for a right border       -->
    <!-- either a per-column value, or the global, table-wide value -->
    <xsl:variable name="column-right">
        <xsl:choose>
            <xsl:when test="$right-col/@right">
                <xsl:value-of select="$right-col/@right" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-right" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- determine a custom right border on a cell -->
    <!-- else default to the column value          -->
    <xsl:variable name="cell-right">
        <xsl:choose>
            <xsl:when test="$the-cell/@right">
                <xsl:value-of select="$the-cell/@right" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$column-right" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Use cell attributes, or col attributes for horizontal alignment -->
    <!-- recreate the column specification for horizontal alignment      -->
    <!-- either a per-column value, or the global, table-wide value      -->
    <xsl:variable name="column-halign">
        <xsl:choose>
            <xsl:when test="$left-col/@halign">
                <xsl:value-of select="$left-col/@halign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-halign" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- determine a custom horizontal alignment on a cell        -->
    <!-- check for row override, else default to the column value -->
    <xsl:variable name="cell-halign">
        <xsl:choose>
            <xsl:when test="$the-cell/@halign">
                <xsl:value-of select="$the-cell/@halign" />
            </xsl:when>
            <!-- look to the row -->
            <xsl:when test="$the-cell/parent::*[1]/@halign">
                <xsl:value-of select="$the-cell/parent::*[1]/@halign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$column-halign" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Use row attributes for vertical alignment                -->
    <!-- recreate the row specification for vertical alignment    -->
    <!-- either a per-row value, or the global, table-wide value  -->
    <xsl:variable name="row-valign">
        <xsl:choose>
            <xsl:when test="$the-cell/parent::*[1]/@valign">
                <xsl:value-of select="$the-cell/parent::*[1]/@valign" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$table-valign" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Look ahead to next cell, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells),  -->
    <!-- which is needed when flushing cline specification -->
    <!-- Also advance to next col element from right one   -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" /> <!-- possibly empty -->
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" />
    <!-- Write the cell's contents -->
    <!-- Wrap in a multicolumn in any of the following situations for    -->
    <!-- the purposes of vertical boundary rules or content formatting:  -->
    <!--    -if the left border, horizontal alignment or right border    -->
    <!--         conflict with the column specification                  -->
    <!--    -if we have a colspan                                        -->
    <!--    -if there are paragraphs in the cell                         -->
    <!-- $table-left and $row-left *can* differ on first use,            -->
    <!-- but row-left is subsequently set to $table-left.                -->
    <xsl:if test="$the-cell">
        <xsl:choose>
            <xsl:when test="not($table-left = $row-left) or not($column-halign = $cell-halign) or not($column-right = $cell-right) or ($column-span > 1) or $the-cell/p">
                <xsl:text>\multicolumn{</xsl:text>
                <xsl:value-of select="$column-span" />
                <xsl:text>}{</xsl:text>
                <!-- only place latex allows/needs a left border -->
                <xsl:if test="$left-column-number = 1">
                    <xsl:call-template name="vrule-specification">
                        <xsl:with-param name="width" select="$row-left" />
                    </xsl:call-template>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="$the-cell/p">
                        <!-- paragraph-valign-specification differs from valign-specification -->
                        <xsl:call-template name="paragraph-valign-specification">
                            <xsl:with-param name="align" select="$row-valign" />
                        </xsl:call-template>
                        <xsl:text>{</xsl:text>
                        <xsl:choose>
                            <xsl:when test="$left-col/@width">
                                <xsl:variable name="width">
                                    <xsl:call-template name="normalize-percentage">
                                        <xsl:with-param name="percentage" select="$left-col/@width" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:value-of select="substring-before($width, '%') div 100" />
                            </xsl:when>
                            <!-- If there is no $left-col/@width, terminate -->
                            <xsl:otherwise>
                                <xsl:message terminate="yes">MBX:ERROR:   cell with p element has no corresponding col element with width attribute</xsl:message>
                                <xsl:apply-templates select="." mode="location-report" />
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>\linewidth}</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="halign-specification">
                            <xsl:with-param name="align" select="$cell-halign" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="vrule-specification">
                    <xsl:with-param name="width" select="$cell-right" />
                </xsl:call-template>
                <xsl:text>}{</xsl:text>
                <xsl:call-template name="table-cell-content">
                    <xsl:with-param name="the-cell" select="$the-cell" />
                    <xsl:with-param name="halign" select="$cell-halign" />
                    <xsl:with-param name="valign" select="$row-valign" />
                </xsl:call-template>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="table-cell-content">
                    <xsl:with-param name="the-cell" select="$the-cell" />
                    <xsl:with-param name="halign" select="$cell-halign" />
                    <xsl:with-param name="valign" select="$row-valign" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$the-cell/following-sibling::cell">
            <xsl:text>&amp;</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- The desired bottom border style for this cell     -->
    <!-- Considered, but also paid forward as prior-bottom -->
    <xsl:variable name="current-bottom">
        <xsl:choose>
            <!-- cell specification -->
            <xsl:when test="$the-cell/@bottom">
                <xsl:value-of select="$the-cell/@bottom" />
            </xsl:when>
            <!-- inherited specification for row -->
            <xsl:otherwise>
                <xsl:value-of select="$row-bottom" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Formulate any necessary update to cline  -->
    <!-- information for the bottom border -->
    <xsl:variable name="updated-cline">
        <!-- write current cline information -->
        <xsl:value-of select="$clines" />
        <!-- is there a change, or end of row, indicating need to flush -->
        <xsl:if test="not($the-cell) or not($prior-bottom = $current-bottom)">
            <xsl:choose>
                <!-- end of row and have never flushed -->
                <!-- hence a uniform bottom border     -->
                <xsl:when test="not($the-cell) and ($start-run = 1)">
                    <xsl:call-template name="hrule-specification">
                        <xsl:with-param name="width" select="$prior-bottom" />
                    </xsl:call-template>
                </xsl:when>
                <!-- write cline for up-to, and including, prior cell      -->
                <!-- prior-bottom always lags, so never operate on cell #1 -->
                <xsl:when test="($left-column-number != 1) and not($prior-bottom = 'none')">
                    <xsl:call-template name="crule-specification">
                        <xsl:with-param name="width" select="$prior-bottom" />
                        <xsl:with-param name="start" select="$start-run" />
                        <xsl:with-param name="finish" select="$left-column-number - 1" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- no update -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <!-- update start of consecutive run of styles -->
    <xsl:variable name="new-start-run">
        <xsl:choose>
            <xsl:when test="$left-column-number = 1 or $prior-bottom = $current-bottom">
                <xsl:value-of select="$start-run" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$left-column-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- Call this template on next cell              -->
        <!-- Possibly passing an empty node (as sentinel) -->
        <xsl:when test="$the-cell">
            <xsl:call-template name="row-cells">
                <xsl:with-param name="the-cell" select="$next-cell" />
                <xsl:with-param name="left-col" select="$next-col" /> <!-- possibly empty -->
                <xsl:with-param name="left-column-number" select="$right-column-number + 1" />
                <xsl:with-param name="last-row" select="$last-row" />
                <xsl:with-param name="clines" select="$updated-cline" />
                <xsl:with-param name="table-left" select="$table-left" />
                <xsl:with-param name="table-bottom" select="$table-bottom" />
                <xsl:with-param name="table-right" select="$table-right" />
                <xsl:with-param name="table-halign" select="$table-halign" />
                <xsl:with-param name="table-valign" select="$table-valign" />
                <!-- next line correct, only allow discrepancy on first use -->
                <xsl:with-param name="row-left" select="$table-left" />
                <xsl:with-param name="row-bottom" select="$row-bottom" />
                <xsl:with-param name="prior-bottom" select="$current-bottom" />
                <xsl:with-param name="start-run" select="$new-start-run" />
            </xsl:call-template>
        </xsl:when>
        <!-- At non-cell, done with row          -->
        <!-- conclude line, dump cline info, etc -->
        <xsl:otherwise>
            <!-- \tabularnewline is unambiguous, better than \\    -->
            <!-- also at a final line with end-of-line decoration  -->
            <xsl:if test="not($updated-cline='') or not($last-row)">
                <xsl:text>\tabularnewline</xsl:text>
            </xsl:if>
            <!-- no harm if end-of-line decoration is empty -->
            <xsl:value-of select="$updated-cline" />
            <!-- next row could begin with bare [ and LaTeX sees -->
            <!-- the start of \tabularnewline[] which would      -->
            <!-- indicate space, so we just appease the macro    -->
            <!-- https://github.com/rbeezer/mathbook/issues/300  -->
            <xsl:if test="$updated-cline='' and not($last-row)">
                <xsl:text>[0pt]</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- Mostly translating MBX terms to LaTeX terms         -->
<!-- Typically use these at the last moment,             -->
<!-- while outputting, and thus use MBX terms internally -->

<!-- Some utilities are defined in xsl/mathbook-common.xsl -->

<!-- "halign-specification" : param "align" -->
<!--     left, right, center -> l, c, r     -->

<!-- "valign-specification" : param "align" -->
<!--     top, middle, bottom -> t, m, b     -->

<!-- paragraph valign-specifications (p, m, b) are  -->
<!-- different from (t, m, b) in mathbook-common    -->

<!-- paragraph halign-specifications (left, center, right, justify) -->
<!-- converted to \raggedright, \centering, \raggedleft, <empty>    -->

<xsl:template name="paragraph-valign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='top'">
            <xsl:text>p</xsl:text>
        </xsl:when>
        <xsl:when test="$align='middle'">
            <xsl:text>m</xsl:text>
        </xsl:when>
        <xsl:when test="$align='bottom'">
            <xsl:text>b</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: vertical alignment attribute not recognized: use top, middle, bottom</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="paragraph-halign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='justify'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$align='left'">
            <xsl:text>\raggedright</xsl:text>
        </xsl:when>
        <xsl:when test="$align='center'">
            <xsl:text>\centering</xsl:text>
        </xsl:when>
        <xsl:when test="$align='right'">
            <xsl:text>\raggedleft</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: horizontal alignment attribute not recognized: use left, center, right, justify</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical rule width to a LaTeX "new" column specification -->
<xsl:template name="vrule-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>A</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>B</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>C</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular left or right attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate horizontal rule width to hrule terms -->
<xsl:template name="hrule-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>\hrulethin</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>\hrulemedium</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>\hrulethick</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular top or bottom attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate abbreviated horizontal rules to cline specifications -->
<xsl:template name="crule-specification">
    <xsl:param name="width" />
    <xsl:param name="start" />
    <xsl:param name="finish" />
    <!-- style. thickness -->
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text></xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>\crulethin</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>\crulemedium</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>\crulethick</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular top or bottom attribute not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- span -->
    <xsl:if test="not($width='none')">
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$start" />
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$finish" />
        <xsl:text>}</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="table-cell-content">
    <xsl:param name="the-cell" />
    <xsl:param name="halign" />
    <xsl:param name="valign" />
    <xsl:choose>
        <xsl:when test="$the-cell/p">
            <!-- paragraph-halign-specification differs from halign-specification -->
            <xsl:call-template name="paragraph-halign-specification">
                <xsl:with-param name="align" select="$halign" />
            </xsl:call-template>
            <!-- styling choice for interparagraph spacing within a table cell    -->
            <xsl:if test="$the-cell[count(p) &gt; 1]">
                <xsl:text>\setlength{\parskip}{0.5\baselineskip}</xsl:text>
            </xsl:if>
            <xsl:text>%&#xa;</xsl:text>
            <xsl:apply-templates select="$the-cell/p" />
        </xsl:when>
        <xsl:when test="$the-cell/line">
            <xsl:text>\tablecelllines{</xsl:text>
            <xsl:call-template name="halign-specification">
                <xsl:with-param name="align" select="$halign" />
            </xsl:call-template>
            <xsl:text>}{</xsl:text>
            <xsl:call-template name="valign-specification">
                <xsl:with-param name="align" select="$valign" />
            </xsl:call-template>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="$the-cell/line" />
            <xsl:text>}&#xa;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$the-cell" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ########################### -->
<!-- Labels and Cross-References -->
<!-- ########################### -->


<!-- We have two schemes in place for marking, number-generation, and       -->
<!-- cross-referencing of objects.  Our use of the  hyperref  package       -->
<!-- allows for more expressive links which allow us to duplicate LaTeX     -->
<!-- packages like "cleverref" and the base functionality of HTML.  We      -->
<!-- could accomplish (nearly) all of this with the second scheme only, but -->
<!-- we are following LaTeX's rules for numbering PreTeXt-wide, so the      -->
<!-- first scheme provides good checks.                                     -->
<!--                                                                        -->
<!-- 1.  Traditional LaTeX \label{}, \ref{}                                 -->
<!-- \label marks a location.  If inside an item/object which LaTeX numbers -->
<!-- \naturally, then ref{} will generate that number.  In order to make an -->
<!-- \electronic PDF, we use the  hyperref  package, and specifically, the  -->
<!-- \hyperref[]{} command.  The string that associates these comes from    -->
<!-- \our "latex-id" template, often the @xml:id.  Example:                 -->
<!--                                                                        -->
<!--   \begin{theorem}\label{foo}                                           -->
<!--                                                                        -->
<!--   \hyperref[foo]{Theorem~\ref{foo}}                                    -->
<!--                                                                        -->
<!-- Note: for print, we could use "Theorem~\ref{foo}" just as easily and   -->
<!-- not utilize  hyperref  (presently, we just color links black and make  -->
<!-- them inactive via \hypersetup{draft}).                                 -->
<!--                                                                        -->
<!-- 2.  Hyperref                                                           -->
<!-- Some items are not numbered naturally by LaTeX, like a "proof".  Other -->
<!-- items we number in different ways, such as a solo "exercises" division -->
<!-- whose number is that of its containing division.  Some items are not   -->
<!-- numbered at all, like a "preface".  Here we use \hypertarget{}{} as    -->
<!-- the marker, and \hyperlink{}{} with custom text (title, hard-coded     -->
<!-- number, etc) as the visual, clickable link.  The "latex-id" is used -->
<!-- as before to link the two commands.  The second argument of            -->
<!-- \hypertarget can be text, but we uniformly leave it empty (a \null     -->
<!-- target text was unnecessary and visible, 2015-12-12).  Example:        -->
<!--                                                                        -->
<!--   \begin{proof}\hypertarget{foo}{}                                     -->
<!--                                                                        -->
<!--   \hyperlink{foo}{Proof~2.4.17}                                        -->
<!--                                                                        -->
<!-- Note: for print, we could use "Proof~2.4.17" just as easily and not    -->
<!-- utilize  hyperref  (presently, we just color links black and make them -->
<!-- inactive via \hypersetup{draft}).                                      -->
<!--                                                                        -->
<!-- Note: footnotes, "fn" are exceptional, see notes below                 -->

<!-- ################## -->
<!-- Unique Identifiers -->
<!-- ################## -->

<!-- This produces unique strings that are internal to the  -->
<!-- LaTeX (intermediate) file.  Since neither author nor   -->
<!-- reader will ever see these, they can be as fast and as -->
<!-- wild as necessary.  But for mature works, likely with  -->
<!-- @permid on many relevant objects, or many @xml:id      -->
<!-- provided for URLs in HTML, these can be predictable    -->
<!-- across runs (and therefore help with tweaking the LaTeX-->
<!-- output under revision control) These are employed with -->
<!-- \label{}, \ref{}, \cite{}, \pageref{}, \eqref{}, etc.  -->
<!-- We can change this at will, with no adverse effects    -->
<!-- NB: colons are banned from PTX @xml:id, and will not   -->
<!-- appear in @permid, though we could use dashes instead  -->
<!-- without getting duplicates.  The prefixes guarantee    -->
<!-- that the three uniqueness schemes do not overlap.      -->
<xsl:template match="*" mode="latex-id">
    <xsl:choose>
        <!-- xml:id may be more recognizable -->
        <xsl:when test="@xml:id">
            <xsl:text>x:</xsl:text>
            <xsl:value-of select="local-name(.)"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="@xml:id"/>
        </xsl:when>
        <!-- permid may be pervasive -->
        <xsl:when test="@permid">
            <xsl:text>p:</xsl:text>
            <xsl:value-of select="local-name(.)"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="@permid"/>
        </xsl:when>
        <!-- anything else we think of is too slow -->
        <xsl:otherwise>
            <xsl:text>g:</xsl:text>
            <xsl:value-of select="local-name(.)"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="generate-id(.)"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################################ -->
<!-- Labels (cross-reference targets) -->
<!-- ################################ -->

<!-- We assume traditional LaTeX  label/ref  system as the default, so      -->
<!-- anything that we allow to be the target of a cross-reference AND LaTeX -->
<!-- does not number automatically, we need to list in the "false"          -->
<!-- template. Anything in this latter list, which can be cross-referenced  -->
<!-- (by number or by title) will get a  \hypertarget  via the "label"      -->
<!-- template. Exceptions - "book" and "article" are carefully marked in    -->
<!-- special ways, so inclusion here is not ever exercised, unless we made  -->
<!-- some edits to employ this template in those special places. This list  -->
<!-- here is everything numbered by PreTeXt, followed by targets that are   -->
<!-- not numbered.                                                          -->

<xsl:template match="*" mode="xref-as-ref">
    <xsl:value-of select="true()" />
</xsl:template>

<!-- Any target of a PreTeXt cross-reference, which is not naturally -->
<!-- numbered by a LaTeX \label{} command, needs to go here.         -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise|biblio|biblio/note|proof|case|ol/li|dl/li|hint|answer|solution|exercisegroup|p|paragraphs|blockquote|contributor|colophon|book|article" mode="xref-as-ref">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- A specialized division in an unstructured division may  -->
<!-- not be numbered correctly via LaTeX's label/ref system, -->
<!-- so we will use the hypertarget/hyperlink system         -->
<xsl:template  match="exercises|reading-questions|glossary|references|worksheet|solutions[not(parent::backmatter)]" mode="xref-as-ref">
    <xsl:variable name="is-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$is-structured = 'true'">
            <xsl:value-of select="true()"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="false()"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="label">
    <xsl:variable name="xref-as-ref">
        <xsl:apply-templates select="." mode="xref-as-ref" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$xref-as-ref = 'true'">
            <xsl:text>\label{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <!-- Objects cross-referenced outside of LaTeX's usual     -->
        <!-- scheme need a \hypertarget, but for page numbers      -->
        <!-- in cross-references, we need a traditional label.     -->
        <xsl:otherwise>
            <xsl:if test="$b-pageref">
                <xsl:text>\label{</xsl:text>
                <xsl:apply-templates select="." mode="latex-id" />
                <xsl:text>}{}</xsl:text>
            </xsl:if>
            <xsl:text>\hypertarget{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id" />
            <xsl:text>}{}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An extraordinary template produces labels for exercise components -->
<!-- (hint, answer, solution) displayed in solution lists (via the     -->
<!-- "solutions" element).  The purpose is to allow the original       -->
<!-- version of an exercise to point to solutions elsewhere.           -->
<!-- The suffix is general-purpose, but is intended now to be          -->
<!-- "main" or "back", depending on where the solution is located.     -->
<xsl:template match="hint|answer|solution" mode="latex-id-duplicate">
    <xsl:param name="suffix" select="'bad-suffix'"/>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>-</xsl:text>
    <xsl:value-of select="$suffix"/>
</xsl:template>


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Much of the cross-reference mechanism is implemented in the common     -->
<!-- routines, here we need to implement two abstract templates which are   -->
<!-- called from those routines. First we generate a number, which for      -->
<!-- LaTeX may be the abstract representation of a \ref{} with a string     -->
<!-- identifier.  This goes back to the common routines and is used to      -->
<!-- fashion the entire link text.  This is the $content variable below.    -->
<!-- From this the actual \hyperref or \hypertarget is made. Almost always, -->
<!-- across PreTeXt, the "xref-number" template will return the number of   -->
<!-- an item as computed in teh -common routines.  However, to maintain     -->
<!-- fidelity with LaTeX's automatic numbering system, we create  \ref{}    -->
<!-- as often as possible. -->
<!--                                                                        -->
<!-- This is the implementation of an abstract template, creating \ref{} by -->
<!-- default. We check if a part number is needed to prevent ambiguity. The -->
<!-- exceptions above should be either (a) not numbered, or (b) numbered in -->
<!-- ways LaTeX cannot, so the union of the match critera here should be    -->
<!-- the list above.  Or said differently, a new object needs to preserve   -->
<!-- this union property across the various "xref-number" templates.        -->
<!-- See xsl/mathbook-common.xsl for more info.                             -->

<xsl:template match="*" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <xsl:apply-templates select="." mode="xref-number-latex">
        <xsl:with-param name="xref" select="$xref"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Tasks have a structure number from the enclosing project   -->
<!-- and a serial number from the enumitem package on the lists -->
<!-- We compose the two LaTeX \ref{}                            -->
<xsl:template match="task" mode="xref-number">
    <!-- ancestors, strip tasks, get number of next enclosure -->
    <xsl:apply-templates select="ancestor::*[not(self::task)][1]" mode="xref-number" />
    <xsl:text>.</xsl:text>
    <!-- task always gets a number, but we have to avoid recursion -->
    <!-- that would result by just getting a \ref from xref-number -->
    <xsl:text>\ref{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Straightforward exception, simple implementation,  -->
<!-- when an "mrow" of display mathematics is tagged    -->
<!-- with symbols not numbers                           -->
<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:text>\ref{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- These exceptions are unnumbered, and are just handled explicitly, -->
<!-- along with a check, the template produces *nothing*               -->
<xsl:template match="p|paragraphs|blockquote|contributor|colophon|book|article" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <!-- number is necessary only for a checking mechanism -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:if test="not($the-number = '')">
        <xsl:message>PTX:BUG:     LaTeX conversion thinks an item is not numbered, but common routines do produce a number.  The "xref" is</xsl:message>
        <xsl:apply-templates select="$xref" mode="location-report" />
        <xsl:message>             The target is</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
</xsl:template>

<!-- Now we have items that PreTeXt numbers itself, in ways LaTeX does not. -->
<!-- "fn" is exceptional - the \label\ref mechanism works well, providing   -->
<!-- local numbers where born (both on the same page), but we need to       -->
<!-- inlude "fn" at the end of this template so that cross-references get   -->
<!-- fully-qualified numbers in the link text.                              -->
<!--                                                                        -->
<!-- Note: objectives are one-per-subdivision, and precede the              -->
<!-- introduction, so the LaTeX \ref{} mechanism assigns the correct        -->
<!-- number - that of the enclosing subdivision                             -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise|biblio|biblio/note|proof|case|ol/li|dl/li|hint|answer|solution|exercisegroup|fn" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <xsl:apply-templates select="." mode="xref-number-hardcoded">
        <xsl:with-param name="xref" select="$xref"/>
    </xsl:apply-templates>
</xsl:template>

<!-- A specialized division in an unstructured division may  -->
<!-- not be numbered correctly via LaTeX's label/ref system, -->
<!-- so we will use the hypertarget/hyperlink system         -->
<!-- This template just copies the gut of two above, perhaps -->
<!-- there should be two utility templates that each get     -->
<!-- called twice overall.                                   -->
<xsl:template  match="exercises|reading-questions|glossary|references|worksheet|solutions[not(parent::backmatter)]" mode="xref-number">
    <xsl:param name="xref" select="/.." />

    <xsl:variable name="is-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$is-structured = 'true'">
            <xsl:apply-templates select="." mode="xref-number-latex">
                <xsl:with-param name="xref" select="$xref"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="xref-number-hardcoded">
                <xsl:with-param name="xref" select="$xref"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Two utility routines generate an "xref number" in a   -->
<!-- traditional way or in a hyperref way.  These are used -->
<!-- above in at least two places each.                    -->

<!-- A hardcoded number respecting the necessity of parts -->
<xsl:template  match="*" mode="xref-number-hardcoded">
    <xsl:param name="xref" select="/.." />

    <xsl:variable name="needs-part-prefix">
        <xsl:apply-templates select="." mode="crosses-part-boundary">
            <xsl:with-param name="xref" select="$xref" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$needs-part-prefix = 'true'">
        <xsl:apply-templates select="ancestor::part" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="number" />
</xsl:template>

<!-- A LaTeX \ref (number) respecting the necessity of parts -->
<xsl:template  match="*" mode="xref-number-latex">
    <xsl:param name="xref" select="/.." />

    <!-- number is necessary only for a checking mechanism -->
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="not($the-number = '')">
            <!-- check if part prefix is needed -->
            <xsl:variable name="needs-part-prefix">
                <xsl:apply-templates select="." mode="crosses-part-boundary">
                    <xsl:with-param name="xref" select="$xref" />
                </xsl:apply-templates>
            </xsl:variable>
            <!-- if so, append prefix with separator -->
            <xsl:if test="$needs-part-prefix = 'true'">
                <xsl:text>\ref{</xsl:text>
                <xsl:apply-templates select="ancestor::part" mode="latex-id" />
                <xsl:text>}</xsl:text>
                <xsl:text>.</xsl:text>
            </xsl:if>
            <!-- and always, a representation for the text of the xref -->
            <xsl:text>\ref{</xsl:text>
            <xsl:apply-templates select="." mode="latex-id" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING: there appears to be an "xref" by number to an item (of type "<xsl:value-of select="local-name(.)" />") without a number (or there is a bug).  The "xref" is</xsl:message>
            <xsl:apply-templates select="$xref" mode="location-report" />
            <xsl:message>             The target is</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This template actually manufactures the link.  When the link lives in  -->
<!-- a title, the link text is just reproduced.  If the number is hard-     -->
<!-- coded, fine.  If the number is obtained by a \ref, we use the starred  -->
<!-- form to prevent some link-inside-a-link confusion.  Some internet      -->
<!-- sites suggest maybe we should just use the *-form universally, though  -->
<!-- that would make the LaTex source a bit less portable?  This is where   -->
<!-- we could use "latex.print" to output the $content variable with no     -->
<!-- linking, perhaps making a better PDF?                                  -->
<!--                                                                        -->
<!-- Note that the "xref-as-ref" template is needed here to accomodate the  -->
<!-- $target's characteristics.  Also, this template then does not need to  -->
<!-- be edited.                                                             -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" select="/.." />
    <xsl:param name="content" select="'MISSING LINK CONTENT'"/>

    <xsl:variable name="xref-as-ref">
        <xsl:apply-templates select="$target" mode="xref-as-ref" />
    </xsl:variable>
    <xsl:choose>
        <!-- inactive in titles, just text               -->
        <!-- With protection against incorrect, sloppy   -->
        <!-- matches, we sneak in the starred version    -->
        <!-- of \ref{} so as to get a number for a label -->
        <!-- in a cross-references, not an active link   -->
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:variable name="active-ref">
                <xsl:text>\ref{</xsl:text>
                <xsl:apply-templates select="$target" mode="latex-id" />
                <xsl:text>}</xsl:text>
            </xsl:variable>
            <xsl:variable name="inactive-ref">
                <xsl:text>\ref*{</xsl:text>
                <xsl:apply-templates select="$target" mode="latex-id" />
                <xsl:text>}</xsl:text>
            </xsl:variable>
            <xsl:value-of select="str:replace($content, $active-ref, $inactive-ref)" />
        </xsl:when>
        <xsl:when test="$xref-as-ref='true'">
            <xsl:text>\hyperref[</xsl:text>
            <xsl:apply-templates select="$target" mode="latex-id" />
            <xsl:text>]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$content" />
            <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\hyperlink{</xsl:text>
            <xsl:apply-templates select="$target" mode="latex-id" />
            <xsl:text>}</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="$content" />
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="xref" mode="latex-page-number">
    <xsl:param name="target"/>

    <xsl:choose>
        <!-- looks bad when bibliographic number gets wrapped in [] -->
        <!-- and the number should suffice on its own               -->
        <xsl:when test="$target/self::biblio"/>
        <!-- and trailing a () for an equation number is overkill -->
        <xsl:when test="$target/self::mrow|$target/self::men"/>
        <!-- and it is really bad for an xref inside a title -->
        <xsl:when test="ancestor::title"/>
        <!-- off by default electronic PDF, -->
        <!-- or on by default for print PDF -->
        <xsl:when test="not($b-pageref)"/>
        <!-- OK, requested and helps, let's add it -->
        <xsl:otherwise>
            <xsl:text>, p.\,\pageref{</xsl:text>
            <xsl:apply-templates select="$target" mode="latex-id"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ################## -->
<!-- Languages, Scripts -->
<!-- ################## -->

<!-- Absent @xml:lang, do nothing -->
<xsl:template match="*" mode="begin-language" />
<xsl:template match="*" mode="end-language" />

<!-- More specifically, change language                -->
<!-- This assumes element is enabled for this behavior -->
<xsl:template match="*[@xml:lang]" mode="begin-language">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="." mode="country-to-language" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="*[@xml:lang]" mode="end-language">
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="." mode="country-to-language" />
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<!-- Even more specifically, we provide an inline version -->
<!-- This should be more readable in LaTex source         -->
<xsl:template match="foreign[@xml:lang]" mode="begin-language">
    <xsl:text>\text</xsl:text>
    <xsl:apply-templates select="." mode="country-to-language" />
    <xsl:text>{</xsl:text>
</xsl:template>

<xsl:template match="foreign[@xml:lang]" mode="end-language">
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Assumes element has an xml:lang attribute      -->
<!-- Translates a country-region code to a language -->
<xsl:template match="*[@xml:lang]" mode="country-to-language">
    <xsl:choose>
        <xsl:when test="@xml:lang='el'">
            <xsl:text>greek</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='ko-KR'">
            <xsl:text>korean</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='hu-HU'">
            <xsl:text>magyar</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='ru-RU'">
            <xsl:text>russian</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='es-ES'">
            <xsl:text>spanish</xsl:text>
        </xsl:when>
        <xsl:when test="@xml:lang='vi-VN'">
            <xsl:text>vietnamese</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- ################### -->
<!-- Structured by Lines -->
<!-- ################### -->

<!-- The LaTeX-specific line separator for use by  -->
<!-- the abstract template for a "line" elent used -->
<!-- to (optionally) structure certain elements.   -->

<xsl:template name="line-separator">
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- ###### -->
<!-- Poetry -->
<!-- ###### -->

<xsl:template match="poem">
    <xsl:text>\begin{poem}</xsl:text>
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label"/>
    </xsl:if>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:text>\poemTitle{</xsl:text>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="stanza"/>
    <xsl:apply-templates select="author" />
    <xsl:text>\end{poem}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="poem/author">
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <xsl:text>\poemauthor</xsl:text>
    <xsl:value-of select="$alignment"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="stanza">
    <xsl:if test="title">
        <xsl:text>\stanzaTitle{</xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\begin{stanza}&#xa;</xsl:text>
    <xsl:apply-templates select="line" />
    <xsl:text>\end{stanza}&#xa;</xsl:text>
</xsl:template>

<xsl:template match="stanza/line">
    <!-- Find Alignment -->
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <!-- Find Indentation -->
    <xsl:variable name="indentation">
        <xsl:apply-templates select="." mode="poem-indent"/>
    </xsl:variable>
    <!-- Apply Alignment and Indentation -->
    <xsl:text>\poemline</xsl:text>
    <xsl:value-of select="$alignment"/>
    <xsl:text>{</xsl:text>
    <xsl:if test="$alignment='left'"><!-- Left Alignment: Indent from Left -->
        <xsl:call-template name="poem-line-indenting">
            <xsl:with-param name="count"><xsl:value-of select="$indentation"/></xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates/><!-- Center Alignment: Ignore Indentation -->
    <xsl:if test="$alignment='right'"><!-- Right Alignment: Indent from Right -->
        <xsl:call-template name="poem-line-indenting">
            <xsl:with-param name="count"><xsl:value-of select="$indentation"/></xsl:with-param>
        </xsl:call-template>
        <!-- Latex seems to "eat" one indentation while right aligned, so we add one extra -->
        <xsl:text>\poemIndent{}</xsl:text>
    </xsl:if>
    <xsl:text>}&#xa;</xsl:text>
</xsl:template>

<xsl:template name="poem-line-indenting">
    <xsl:param name="count"/>
    <xsl:choose>
        <xsl:when test="(0 >= $count)"/>
        <xsl:otherwise>
            <xsl:text>\poemIndent{}</xsl:text>
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!--       -->
<!-- Music -->
<!--       -->

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->

<!-- These "choose" should really be separate match -->
<!-- templates on title//*, but the use of named    -->
<!-- templates would require a big re-write, so we  -->
<!-- have some technical debt here                  -->

<!-- Our macros need protection in titles and typeout commands -->

<!-- Double Sharp -->
<xsl:template name="doublesharp">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\doublesharp</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\doublesharp}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Sharp -->
<xsl:template name="sharp">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\sharp</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\sharp}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Natural -->
<xsl:template name="natural">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\natural</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\natural}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Flat -->
<xsl:template name="flat">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\flat</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\flat}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Double Flat -->
<xsl:template name="doubleflat">
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::subtitle">
            <xsl:text>\protect\doubleflat</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>{\doubleflat}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Footnotes -->
<!-- For blocks implemented as "tcolorbox" we need to manage -->
<!-- footnotes more carefully.  Also for captions since they -->
<!-- migrate to list of figures.  At the location, we just   -->
<!-- drop a mark, with no text.  Testing with the "footmisc" -->
<!-- package, and its "\mpfootnotemark" alternative works    -->
<!-- worse than simple default LaTeX (though the numbers     -->
<!-- could be hard-coded if necessary).                      -->
<xsl:template match="fn">
    <xsl:choose>
        <xsl:when test="ancestor::*[&ASIDE-FILTER; or &THEOREM-FILTER; or &AXIOM-FILTER;  or &DEFINITION-FILTER; or &REMARK-FILTER; or &COMPUTATION-FILTER; or &EXAMPLE-FILTER; or &PROJECT-FILTER; or &GOAL-FILTER; or &FIGURE-FILTER; or self::list or self::sidebyside or self::defined-term or self::colophon/parent::backmatter or self::assemblage or self::exercise]">
            <!-- a footnote in the text of a caption will migrate to -->
            <!-- the auxiliary file for use in the "list of figures" -->
            <!-- and there is some confusion of braces and the use   -->
            <!-- of \footnote and \footnotemark, hence a \protect    -->
            <!-- https://tex.stackexchange.com/questions/10181       -->
            <xsl:if test="ancestor::*[&FIGURE-FILTER;]">
                <xsl:text>\protect</xsl:text>
            </xsl:if>
            <xsl:text>\footnotemark{}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\footnote{</xsl:text>
            <xsl:apply-templates />
            <xsl:apply-templates select="." mode="label" />
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Part 2: for items implemented as "tcolorbox" we scan back     -->
<!-- through the contents, formulating the text of footnotes,      -->
<!-- in order.  it is necessary to hard-code the (serial) number   -->
<!-- of the footnote since otherwise the numbering gets confused   -->
<!-- by an intervening "tcolorbox".  The template should be placed -->
<!-- immediately after the "\end{}" of affected environments.      -->
<!-- It will format as one footnote text per output line.          -->
<!--                                                               -->
<!-- We need to pop all interior footnotes iff we are free of      -->
<!-- enclosing blocks implemented with tcolorbox.  So this         -->
<!-- template is called at the end of a template for a block,      -->
<!-- but after the tcolorbox closes.  So we are in the clear when  -->
<!-- no ancestors are implmented by tcolorbox.  Otherwise, we      -->
<!-- "wait" and pop all interior footnotes later.                  -->
<!-- NB: these templates could be improved with an entity          -->
<xsl:template match="&ASIDE-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|list|sidebyside|defined-term|&GOAL-LIKE;|backmatter/colophon|assemblage|exercise" mode="pop-footnote-text">
    <xsl:if test="count(ancestor::*[&ASIDE-FILTER; or &THEOREM-FILTER; or &AXIOM-FILTER;  or &DEFINITION-FILTER; or &REMARK-FILTER; or &COMPUTATION-FILTER; or &EXAMPLE-FILTER; or &PROJECT-FILTER; or &GOAL-FILTER; or &FIGURE-FILTER; or self::list or self::sidebyside or self::defined-term or self::colophon/parent::backmatter or self::assemblage or self::exercise]) = 0">
        <xsl:for-each select=".//fn">
            <xsl:text>\footnotetext[</xsl:text>
            <xsl:apply-templates select="." mode="serial-number"/>
            <xsl:text>]</xsl:text>
            <xsl:text>{</xsl:text>
            <xsl:apply-templates />
            <xsl:apply-templates select="." mode="label" />
            <xsl:text>}%&#xa;</xsl:text>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<!-- Very nearly a no-op, but necessary for HTML -->
<xsl:template match="glossary/terms">
    <xsl:apply-templates select="defined-term"/>
</xsl:template>

<!-- Defined Terms, in a Glossary -->
<xsl:template match="defined-term">
    <xsl:text>\begin{definedterm}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id"/>
    <xsl:text>}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{definedterm}&#xa;</xsl:text>
    <xsl:apply-templates select="." mode="pop-footnote-text"/>
</xsl:template>

<!-- ############################ -->
<!-- Literate Programming Support -->
<!-- ############################ -->

<!-- common template so we can preferentially handle the filename  -->
<!-- case first, then have an xml:id on *any* fragment -->
<xsl:template match="fragment[@xml:id]|fragment[@filename]">
    <xsl:choose>
        <!-- filename fragments are the top of their trees, but -->
        <!-- can have an @xml:id so they can be referenced      -->
        <xsl:when test="@filename">
            <!-- switch to node-set with "c" if characters need escaping -->
            <xsl:text>\par\medskip\noindent\textbf{Begin File:} \mono{</xsl:text>
            <xsl:value-of select="@filename" />
            <xsl:text>}</xsl:text>
            <xsl:text>\index{file root!\mono{</xsl:text>
            <xsl:value-of select="@filename" />
            <xsl:text>}}</xsl:text>
        </xsl:when>
        <!-- other fragments are known by their xml:id strings -->
        <xsl:when test="@xml:id">
            <!-- switch to node-set with "c" if characters need escaping -->
            <xsl:text>\par\medskip\noindent\textbf{Fragment:} \mono{</xsl:text>
            <xsl:value-of select="@xml:id" />
            <xsl:text>}</xsl:text>
            <!-- sortby first, @ separator, then tt version -->
            <xsl:text>\index{</xsl:text>
            <xsl:value-of select="@xml:id" />
            <xsl:text>@\mono{</xsl:text>
            <xsl:value-of select="@xml:id" />
            <xsl:text>}}</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- always possible to label (universal PTX capability) -->
    <xsl:text>\phantomsection</xsl:text>
    <xsl:apply-templates select="." mode="label"/>
    <xsl:text>\\&#xa;</xsl:text>
    <!-- now the guts, in pieces -->
    <xsl:apply-templates select="text()|fragment[@ref]" />
</xsl:template>

<!-- convert fragment pointer to text -->
<!-- in monospace font                -->
<xsl:template match="fragment[@ref]">
    <!-- switch to node-set with "c" if characters need escaping -->
    <xsl:text>\mono{</xsl:text>
    <xsl:text>&lt;code: </xsl:text>
    <xsl:value-of select="@ref" />
    <xsl:text>\space\space\pageref{</xsl:text>
    <xsl:apply-templates select="id(@ref)" mode="latex-id"/>
    <xsl:text>}</xsl:text>
    <xsl:text>&gt;</xsl:text>
    <xsl:text>}</xsl:text>
    <xsl:text>\\&#xa;</xsl:text>
</xsl:template>

<!-- wrap code in a Verbatim environment, though perhaps another -->
<!-- LaTeX environment or a tcolor box would work better         -->
<!-- Drop whitespace only text() nodes                           -->
<xsl:template match="fragment/text()">
    <xsl:variable name="normalized-frag" select="normalize-space(.)"/>
    <xsl:if test="not($normalized-frag = '')">
        <xsl:text>\begin{Verbatim}</xsl:text>
        <xsl:text>&#xa;</xsl:text>  <!-- required by fancyvrb -->
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
        <xsl:text>\end{Verbatim}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>


<!-- References Sections -->
<!-- We use description lists to manage bibliographies,  -->
<!-- and \bibitem seems comfortable there, so our source -->
<!-- is nearly compatible with the usual usage           -->

<!-- As an item of a description list, but       -->
<!-- compatible with thebibliography environment -->
<xsl:template match="biblio[@type='raw']">
    <!-- begin the list with first item -->
    <xsl:if test="not(preceding-sibling::biblio)">
        <xsl:text>%% If this is a top-level references&#xa;</xsl:text>
        <xsl:text>%%   you can replace with "thebibliography" environment&#xa;</xsl:text>
        <xsl:text>\begin{referencelist}&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>\bibitem</xsl:text>
    <!-- "label" (e.g. Jud99), or by default serial number -->
    <!-- LaTeX's bibitem will provide the visual brackets  -->
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>]</xsl:text>
    <!-- "key" for cross-referencing -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="latex-id"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates />
    <xsl:text>&#xa;</xsl:text>
    <!-- end the list after last item -->
    <xsl:if test="not(following-sibling::biblio)">
        <xsl:text>\end{referencelist}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Raw Bibliographic Entry Formatting              -->
<!-- Markup really, not full-blown data preservation -->

<!-- Title in italics -->
<xsl:template match="biblio[@type='raw']/title">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- No treatment for journal -->
<xsl:template match="biblio[@type='raw']/journal">
    <xsl:apply-templates />
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[@type='raw']/volume">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Year in parentheses -->
<xsl:template match="biblio[@type='raw']/year">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Number, handle TeX period idosyncracy -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no.\@\,</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Ibid, nee ibidem, handle TeX period idosyncracy, empty element -->
<xsl:template match="biblio[@type='raw']/ibid">
    <xsl:text>Ibid.\@\,</xsl:text>
</xsl:template>


<!-- Annotated Bibliography Items -->
<!--   Presumably just paragraphs, nothing too complicated -->
<!--   We first close off the citation itself -->
<xsl:template match="biblio/note">
    <xsl:text>\par</xsl:text>
    <xsl:if test="@xml:id">
        <xsl:apply-templates select="." mode="label"/>
    </xsl:if>
    <xsl:text>%&#xa;</xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- ############### -->
<!-- Text Processing -->
<!-- ############### -->

<!-- The general template for matching "text()" nodes will     -->
<!-- apply this template (there is a hook there).  Verbatim    -->
<!-- text should be manipulated in templates with              -->
<!-- "xsl:value-of" and so not come through here.  Conversely, -->
<!-- when "xsl:apply-templates" is applied, the template will  -->
<!-- have effect.                                              -->
<!--                                                           -->
<!-- Our emphasis originally is on escaping characters that    -->
<!-- LaTeX has hijacked for special purposes.  First we define -->
<!-- some variables globally, so it is only necessary once.    -->

<!-- Following for disruption of "TeX ligatures"           -->
<!-- Second two are necessary to avoid XML quote confusion -->
<xsl:variable name="double-hyphen">
    <text>--</text>
</xsl:variable>
<xsl:variable name="double-hyphen-replacement">
    <text>-{}-{}</text>
</xsl:variable>

<xsl:variable name="double-apostrophe">
    <text>''</text>
</xsl:variable>
<xsl:variable name="double-apostrophe-replacement">
    <text>'{}'{}</text>
</xsl:variable>

<xsl:template name="text-processing">
    <xsl:param name="text"/>
    <!-- LaTeX's 10 reserved characters:  # $ % ^ & _ { } ~ \          -->
    <!-- We allow these in source, but must *always* escape them       -->
    <!--                                                               -->
    <!-- Strategy: replacements for backslash and braces use all       -->
    <!-- three characters, so it can be circular to just plow through  -->
    <!-- them.  We replace the backslash, then do replacements for the -->
    <!-- braces.  But we leave off the ending empty-group protection.  -->
    <!-- A second pass will never accidentally match remaining source  -->
    <!-- text due to the backslash replacements, so we safely place    -->
    <!-- the groups as pairs of braces.                                -->
    <!--                                                               -->
    <!-- This involves just one more search/replace than a previous    -->
    <!-- strategy that used a risky "unique string" strategy.          -->
    <!-- (Discussion referenced in "escape-text-to-latex" template)    -->

    <xsl:variable name="bs-one" select="str:replace($text,   '\', '\textbackslash')"/>
    <xsl:variable name="lb-one" select="str:replace($bs-one, '{', '\textbraceleft')"/>
    <xsl:variable name="rb-one" select="str:replace($lb-one, '}', '\textbraceright')"/>

    <xsl:variable name="bs-two" select="str:replace($rb-one, '\textbackslash',  '\textbackslash{}')"/>
    <xsl:variable name="lb-two" select="str:replace($bs-two, '\textbraceleft',  '\textbraceleft{}')"/>
    <xsl:variable name="rb-two" select="str:replace($lb-two, '\textbraceright', '\textbraceright{}')"/>

    <xsl:variable name="amp-fixed"        select="str:replace($rb-two,           '&amp;', '\&amp;')"/>
    <xsl:variable name="hash-fixed"       select="str:replace($amp-fixed,        '#',     '\#')"/>
    <xsl:variable name="dollar-fixed"     select="str:replace($hash-fixed,       '$',     '\textdollar{}')"/>
    <xsl:variable name="percent-fixed"    select="str:replace($dollar-fixed,     '%',     '\%')"/>
    <xsl:variable name="circumflex-fixed" select="str:replace($percent-fixed,    '^',     '\textasciicircum{}')"/>
    <xsl:variable name="underscore-fixed" select="str:replace($circumflex-fixed, '_',     '\textunderscore{}')"/>
    <xsl:variable name="tilde-fixed"      select="str:replace($underscore-fixed, '~',     '\textasciitilde{}')"/>

    <!-- These are characters improved by LaTeX versions (mostly from textcomp)                 -->
    <!-- \slash is important since it allows line-breaking, contrary to a bare "forward "slash" -->
    <xsl:variable name="less-fixed"     select="str:replace($tilde-fixed,    '&lt;', '\textless{}')"/>
    <xsl:variable name="greater-fixed"  select="str:replace($less-fixed,      '&gt;', '\textgreater{}')"/>
    <xsl:variable name="backtick-fixed" select="str:replace($greater-fixed,   '`',    '\textasciigrave{}')"/>
    <xsl:variable name="bar-fixed"      select="str:replace($backtick-fixed,  '|',    '\textbar{}')"/>
    <xsl:variable name="slash-fixed"    select="str:replace($bar-fixed,       '/',    '\slash{}')"/>
    <xsl:variable name="asterisk-fixed" select="str:replace($slash-fixed,     '*',    '\textasteriskcentered{}')"/>

    <!-- We disrupt certain "TeX ligatures" - combinations of keyboard -->
    <!-- characters which result in a single glyph in output           -->

    <!-- Hyphens -->
    <!-- An even number of hyphens will earn the same number of disrupting {} -->
    <!-- An odd number of hyphens will earn one less disrupting {} -->
    <!-- In particular, a single hyphen gets none -->
    <xsl:variable name="hyphen-fixed"    select="str:replace($asterisk-fixed, $double-hyphen, $double-hyphen-replacement)"/>

    <!-- Apostrophes -->
    <!-- Should not be combined in pairs to become a single right -->
    <!-- smart quote. Strategy is the same as for hyphens         -->
    <xsl:variable name="apostrophe-fixed" select="str:replace($hyphen-fixed, $double-apostrophe, $double-apostrophe-replacement)"/>

    <!-- Backticks -->
    <!-- Should not be combined in pairs to become a single left smart -->
    <!-- quote.  Replacement above by a macro will prevent this.       -->

    <!-- Currency -->
    <!-- Dollar is processed above.  13 other currencies seem to     -->
    <!-- behave just fine with our defaults, when simply entered     -->
    <!-- by their Unicode numbers, though each could be replaced     -->
    <!-- by a textcomp version, which we have elected to skirt until -->
    <!-- necessary.  The one exception is the Paraguayan guarani.    -->

    <!-- Paraguayan guarani -->
    <xsl:variable name="guarani-fixed" select="str:replace($apostrophe-fixed, '&#x20b2;', '\textguarani')"/>

    <xsl:value-of select="$guarani-fixed"/>
</xsl:template>


<!-- ######### -->
<!-- Utilities -->
<!-- ######### -->

<!-- Escape URL Text as LaTeX -->
<!-- Slash first, so don't clobber later additions    -->
<!-- Double-quote is problematic in LaTeX, and also   -->
<!-- in strings below, so use &#x22; it's hex Unicode -->
<!--     \ & # % ~ { } "                              -->
<!-- no problem yet with math underscore or caret     -->
<!-- (a text-only template, but LaTeX-specific)       -->
<!-- This is a subset of following utility, certain   -->
<!-- substitutions (such as \textsinglequote) will    -->
<!-- foul up the applications of this cleaner.        -->
<xsl:template name="escape-url-to-latex">
    <xsl:param    name="text" />

    <xsl:variable name="sans-slash" select="str:replace($text,       '\',      '\\'      )" />
    <xsl:variable name="sans-amp"   select="str:replace($sans-slash, '&amp;',  '\&amp;'  )" />
    <xsl:variable name="sans-hash"  select="str:replace($sans-amp,   '#',      '\#'      )" />
    <xsl:variable name="sans-per"   select="str:replace($sans-hash,  '%',      '\%'      )" />
    <xsl:variable name="sans-tilde" select="str:replace($sans-per,   '~',      '\~'      )" />
    <xsl:variable name="sans-open"  select="str:replace($sans-tilde, '{',      '\{'      )" />
    <xsl:variable name="sans-close" select="str:replace($sans-open,  '}',      '\}'      )" />
    <xsl:variable name="sans-quote" select="str:replace($sans-close, '&#x22;', '\&#x22;' )" />
    <xsl:value-of select="$sans-quote" />
</xsl:template>

<!-- Necessary for next template, defined globally -->
<xsl:variable name="sq">
    <xsl:text>'</xsl:text>
</xsl:variable>
<xsl:variable name="dq">
    <xsl:text>"</xsl:text>
</xsl:variable>

<!-- Author's Inline Verbatim to Escaped LaTeX -->
<!-- 10 wicked LaTeX characters:   & % $ # _ { } ~ ^ \.    -->
<!-- Plus single quote, double quote, and backtick.        -->
<!-- \, {, } all need replacement, and also occur in some  -->
<!-- replacements.  So order, and some care, is necessary. -->
<!-- Generally this is a "cleaner" template , prior  to    -->
<!--wrapping in our \mono macro, implemented with \texttt. -->
<!-- http://tex.stackexchange.com/questions/34580/         -->
<xsl:template name="escape-text-to-latex">
    <xsl:param    name="text" />

    <!-- See "text-processing" for discussion of a very similar strategy -->

    <xsl:variable name="bs-one" select="str:replace($text,   '\', '\textbackslash')"/>
    <xsl:variable name="lb-one" select="str:replace($bs-one, '{', '\textbraceleft')"/>
    <xsl:variable name="rb-one" select="str:replace($lb-one, '}', '\textbraceright')"/>

    <xsl:variable name="bs-two" select="str:replace($rb-one, '\textbackslash',  '\textbackslash{}')"/>
    <xsl:variable name="lb-two" select="str:replace($bs-two, '\textbraceleft',  '\{')"/>
    <xsl:variable name="rb-two" select="str:replace($lb-two, '\textbraceright', '\}')"/>

    <xsl:variable name="sans-amp"   select="str:replace($rb-two,      '&amp;', '\&amp;'  )" />
    <xsl:variable name="sans-hash"  select="str:replace($sans-amp,    '#',     '\#'      )" />
    <xsl:variable name="sans-per"   select="str:replace($sans-hash,   '%',     '\%'      )" />
    <xsl:variable name="sans-tilde" select="str:replace($sans-per,    '~',     '\textasciitilde{}')" />
    <xsl:variable name="sans-dollar" select="str:replace($sans-tilde, '$',     '\$' )" />
    <xsl:variable name="sans-under" select="str:replace($sans-dollar, '_',     '\_'      )" />
    <xsl:variable name="sans-caret" select="str:replace($sans-under,  '^',     '\textasciicircum{}')" />
    <xsl:variable name="sans-quote" select="str:replace($sans-caret,  $sq,     '\textquotesingle{}')" />
    <xsl:variable name="sans-dblqt" select="str:replace($sans-quote,  $dq,     '\textquotedbl{}')" />
    <xsl:value-of select="str:replace($sans-dblqt,  '`',     '\textasciigrave{}')" />
</xsl:template>

<!-- Escape Console Input to Latex -->
<!-- The entire input string is bolded, but now we have escaped     -->
<!-- into LaTeX for the entire string.  So we need to               -->
<!--   (1) Escape the usual problematic characters into their LaTeX -->
<!--       text equivalents.                                        -->
<!--   (2) Convert the "listings" escape sequence into something    -->
<!--       isomorphic, but not equal, in LaTeX.  We do this by      -->
<!--       adding an empty group to the escape sequences.           -->
<xsl:template name="escape-console-input-to-latex">
    <xsl:param name="text" />

    <xsl:variable name="all-latex">
        <xsl:call-template name="escape-text-to-latex">
            <xsl:with-param name="text" select="$text"/>
        </xsl:call-template>
    </xsl:variable>
    <!-- A trailing group seems necessary on the opening escape -->
    <!-- sequence, otherwise a trailing spce goes missing.      -->
    <!-- We add this to the closing sequence just in case.      -->
    <xsl:variable name="left-escape"  select="str:replace($all-latex, '(*', '({}*{}' )"/>
    <xsl:variable name="right-escape" select="str:replace($left-escape, '*)', '*{}){}' )"/>
    <xsl:value-of select="$right-escape"/>
</xsl:template>

<!-- Escape Console Text -->
<!-- The prompt and output for a "console" are handled capably by the   -->
<!-- "listings" package.  Except we need to break the escape characters -->
<!-- we use to accomodate bold text for the input.  So...we escape into -->
<!-- LaTeX mode, duplicate the desired sequence, and break it with an   -->
<!-- empty group.  Presumably no additional empty groups are necessary. -->
<!-- The usual three-step in necessary to not clobber earlier edits,    -->
<!-- we did not figure out a clever way to avoid a "unique" string.     -->
<xsl:template name="escape-console-prompt-output">
    <xsl:param name="text" />

    <xsl:variable name="left-escape-temp"  select="str:replace($text, '(*', 'XXvVY4DtfemxHkcXX' )"/>
    <xsl:variable name="right-escape" select="str:replace($left-escape-temp, '*)', '(**{})*)' )"/>
    <xsl:variable name="left-escape" select="str:replace($right-escape, 'XXvVY4DtfemxHkcXX', '(*({}**)' )"/>
    <xsl:value-of select="$left-escape"/>
</xsl:template>

<!-- Issue check and warning, under xelatex engine, -->
<!-- for a font missing from a system               -->
<xsl:template name="xelatex-font-check">
    <xsl:param name="font-name"/>

    <xsl:text>\IfFontExistsTF{</xsl:text>
    <xsl:value-of select="$font-name"/>
    <xsl:text>}{}{\GenericError{}{The font "</xsl:text>
    <xsl:value-of select="$font-name"/>
    <xsl:text>" requested by PreTeXt output is not available as a system font}{Consult the PreTeXt Guide for help with LaTeX fonts.}{}}&#xa;</xsl:text>
</xsl:template>

<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report      -->
<!-- A bad xml:id might have underscores, so we   -->
<!-- sanitize the entire warning text for LaTeX   -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <!-- Color for author tools version -->
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:text>\textcolor{red}</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:text>(((</xsl:text>
    <xsl:value-of select="str:replace($warning, '_', '\_')" />
    <xsl:text>)))</xsl:text>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Marginal notes are only for author's report          -->
<!-- and are always colored red                           -->
<!-- Marginpar's from http://www.f.kth.se/~ante/latex.php -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:text>\marginpar[\raggedleft\footnotesize\textcolor{red}{</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>}]{\raggedright\footnotesize\textcolor{red}{</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>}}</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Deprecations -->
<!-- These are global, LaTeX-only warnings which are not source -->
<!-- related and not possible in a template once executed       -->
<xsl:template match="mathbook|pretext" mode="deprecation-warnings-latex">
    <!-- 2017-12-18  deprecate console macro characters -->
    <xsl:if test="not($latex.console.macro-char = '')">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-12-18'" />
            <xsl:with-param name="message" select="'the  latex.console.macro-char  parameter is deprecated, and there is no longer a need to be careful about the backslash (\) character in a console'" />
                <xsl:with-param name="incorrect-use" select="not($latex.console.macro-char = '')" />
        </xsl:call-template>
    </xsl:if>
    <xsl:if test="not($latex.console.begin-char = '')">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-12-18'" />
            <xsl:with-param name="message" select="'the  latex.console.begin-char  parameter is deprecated, and there is no longer a need to be careful about the begin group ({) character in a console'" />
                <xsl:with-param name="incorrect-use" select="not($latex.console.begin-char = '')" />
        </xsl:call-template>
    </xsl:if>
    <xsl:if test="not($latex.console.end-char = '')">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-12-18'" />
            <xsl:with-param name="message" select="'the  latex.console.end-char  parameter is deprecated, and there is no longer a need to be careful about the end group (}) character in a console'" />
                <xsl:with-param name="incorrect-use" select="not($latex.console.end-char = '')" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
</xsl:template>

<!-- Uninteresting Code, aka the Bad Bank                    -->
<!-- Deprecated, unmaintained, etc, parked here out of sight -->

<!-- "solution-list" was supported by elaborate -->
<!-- modal templates, which are now renamed     -->
<!-- 2018-07-04: some day remove all this code  -->

<xsl:template match="solution-list">
    <!-- TODO: check here once for backmatter switches set to "knowl", which is unrealizable -->
    <xsl:apply-templates select="//exercises" mode="obsolete-backmatter" />
</xsl:template>

<!-- This is a hack that should go away when backmatter exercises are rethought -->
<xsl:template match="title" mode="obsolete-backmatter" />

<!-- Create a heading for each non-empty collection of solutions -->
<!-- Format as appropriate LaTeX subdivision for this level      -->
<!-- But number according to the actual Exercises section        -->
<xsl:template match="exercises" mode="obsolete-backmatter">
    <xsl:variable name="nonempty" select="(.//hint and $exercise.backmatter.hint='yes') or (.//answer and $exercise.backmatter.answer='yes') or (.//solution and $exercise.backmatter.solution='yes')" />
    <xsl:if test="$nonempty='true'">
        <xsl:text>\</xsl:text>
        <xsl:apply-templates select="." mode="division-name" />
        <xsl:text>*{</xsl:text>
        <xsl:apply-templates select="." mode="number" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full" />
        <xsl:text>}&#xa;</xsl:text>
        <xsl:apply-templates select="*" mode="obsolete-backmatter" />
    </xsl:if>
</xsl:template>

<!-- We kill the introduction and conclusion for -->
<!-- the exercises and for the exercisegroups    -->
<xsl:template match="exercises//introduction|exercises//conclusion" mode="obsolete-backmatter" />

<!-- Print exercises with some solution component -->
<!-- Respect switches about visibility ("knowl" is assumed to be 'no') -->
<xsl:template match="exercise" mode="obsolete-backmatter">
    <xsl:choose>
        <xsl:when test="webwork-reps/static/stage and (webwork-reps/static/stage/hint or webwork-reps/static/stage/solution)">
            <!-- Lead with the problem number and some space -->
            <xsl:text>\noindent\textbf{</xsl:text>
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:text>.}\quad{}</xsl:text>
            <!-- Within each stage enforce order -->
            <xsl:apply-templates select="webwork-reps/static/stage" mode="obsolete-backmatter"/>
        </xsl:when>
        <xsl:when test="webwork-reps/static and (webwork-reps/static/hint or webwork-reps/static/solution)">
            <!-- Lead with the problem number and some space -->
            <xsl:text>\noindent\textbf{</xsl:text>
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:text>.}\quad{}</xsl:text>
            <xsl:if test="$exercise.backmatter.statement='yes'">
                <xsl:apply-templates select="webwork-reps/static/statement" />
                <xsl:text>\par\smallskip&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="webwork-reps/static/hint and $exercise.backmatter.hint='yes'">
                <xsl:apply-templates select="webwork-reps/static/hint" mode="obsolete-backmatter"/>
            </xsl:if>
            <xsl:if test="webwork-reps/static/solution and $exercise.backmatter.solution='yes'">
                <xsl:apply-templates select="webwork-reps/static/solution" mode="obsolete-backmatter"/>
            </xsl:if>
        </xsl:when>
        <xsl:when test="hint or answer or solution">
            <!-- Lead with the problem number and some space -->
            <xsl:text>\noindent\textbf{</xsl:text>
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:text>.}\quad{}</xsl:text>
            <xsl:if test="$exercise.backmatter.statement='yes'">
                <!-- TODO: not a "backmatter" template - make one possibly? Or not necessary -->
                <xsl:apply-templates select="statement" />
                <xsl:text>\par\smallskip&#xa;</xsl:text>
            </xsl:if>
            <xsl:if test="//hint and $exercise.backmatter.hint='yes'">
                <xsl:apply-templates select="hint" mode="obsolete-backmatter" />
            </xsl:if>
            <xsl:if test="answer and $exercise.backmatter.answer='yes'">
                <xsl:apply-templates select="answer" mode="obsolete-backmatter" />
            </xsl:if>
            <xsl:if test="solution and $exercise.backmatter.solution='yes'">
                <xsl:apply-templates select="solution" mode="obsolete-backmatter" />
            </xsl:if>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- For stages of a webwork exercise inside an exercises, we must respect  -->
<!-- string parameters controlling whether to display parts.                -->
<xsl:template match="webwork-reps/static/stage" mode="obsolete-backmatter">
    <xsl:if test="$exercise.backmatter.statement='yes'">
        <xsl:apply-templates select="statement" />
        <xsl:text>\par\smallskip&#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="hint and $exercise.backmatter.hint='yes'">
        <xsl:apply-templates select="hint" mode="obsolete-backmatter"/>
    </xsl:if>
    <xsl:if test="solution and $exercise.backmatter.solution='yes'">
        <xsl:apply-templates select="solution" mode="obsolete-backmatter"/>
    </xsl:if>
</xsl:template>

<!-- We print hints, answers, solutions with no heading. -->
<!-- TODO: make heading on solution components configurable -->
<xsl:template match="exercise/hint|exercise/answer|exercise/solution|webwork-reps/static/hint|webwork-reps/static/stage/hint|webwork-reps/static/solution|webwork-reps/static/stage/solution" mode="obsolete-backmatter">
    <xsl:apply-templates />
    <xsl:text>\par\smallskip&#xa;</xsl:text>
</xsl:template>
</xsl:stylesheet>
