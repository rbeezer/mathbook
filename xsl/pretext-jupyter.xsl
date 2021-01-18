<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2015 Robert A. Beezer

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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    >

<xsl:import href="./pretext-common.xsl" />
<xsl:import href="./pretext-html.xsl" />

<!-- Output is JSON, enriched with serialized HTML -->
<xsl:output method="text" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- iPython files as output -->
<xsl:variable name="file-extension" select="'.ipynb'" />

<!-- Examples, proofs and inline exercises are knowled     -->
<!-- by default in HTML conversion.  While a THEOREM-LIKE  -->
<!-- is one big unit, so proofs are not even considered    -->
<!-- as knowls, EXAMPLE-LIKE do need protection.           -->

<xsl:param name="html.knowl.proof" select="'no'" />
<xsl:param name="html.knowl.example" select="'no'" />
<xsl:param name="html.knowl.exercise.inline" select="'no'" />
<xsl:param name="jupyter.kernel" select="''" />

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <xsl:apply-templates />
</xsl:template>

<!-- We process structural nodes via chunking routine in  xsl/pretext-common.xsl -->
<!-- This in turn calls specific modal templates defined elsewhere in this file    -->
<xsl:template match="/mathbook|/pretext">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Jupyter notebook conversion is experimental and incomplete&#xa;Requests to fix/implement specific constructions welcome</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="mathbook" mode="deprecation-warnings" />
    <xsl:apply-templates mode="chunking" />
</xsl:template>

<!-- ########### -->
<!-- Compromises -->
<!-- ########### -->

<!-- Knowls are not yet functional in Jupyter notebooks    -->
<!-- See:  https://github.com/jupyter/notebook/pull/2947   -->
<!-- So we kill them while we wait and get hyperlinks only -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>


<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/pretext-common.xsl -->
<!-- This will explain document structure (not XML structure) and has the       -->
<!-- routines which call the necessary realizations of two abstract templates.  -->

<!-- Divisions, and pseudo-divisions -->
<!-- A heading cell, then apply templates here to children -->
<xsl:template match="&STRUCTURAL;|paragraphs|introduction[parent::*[&STRUCTURAL-FILTER;]]|conclusion[parent::*[&STRUCTURAL-FILTER;]]">
    <!-- <xsl:message>S:<xsl:value-of select="local-name(.)" />:S</xsl:message> -->
    <xsl:apply-templates select="." mode="pretext-heading" />
    <xsl:apply-templates />
</xsl:template>

<!-- Some structural nodes do not need their title,                -->
<!-- (or subtitle) so we don't put a section heading there         -->
<!-- Title(s) for an article are forced by a frontmatter/titlepage -->
<!-- TODO: incorporate in above by implementing null heading template? -->
<xsl:template match="article|frontmatter">
    <xsl:apply-templates />
</xsl:template>

<!-- We have entire cells for division headings. -->
<xsl:template match="&STRUCTURAL;" mode="pretext-heading">
    <xsl:variable name="html-rtf">
        <xsl:apply-templates select="." mode="section-header" />
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="paragraphs|introduction|conclusion" mode="pretext-heading">
    <xsl:variable name="html-rtf">
        <xsl:apply-templates select="." mode="heading-title" />
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template match="*" mode="pretext-heading">
    <xsl:message>pretext-heading unmatched <xsl:value-of select="local-name(.)" /></xsl:message>
</xsl:template>

<!-- Three modal templates accomodate all document structure nodes -->
<!-- and all possibilities for chunking.  Read the description     -->
<!-- in  xsl/pretext-common.xsl to understand these.              -->
<!-- The  "file-wrap"  template is defined elsewhre in this file.  -->

<!-- Content of a summary page is usual content,  -->
<!-- or link to subsidiary content, all from HTML -->
<!-- template with same mode, as one big cell     -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <xsl:apply-templates select="objectives|introduction" />
    <xsl:variable name="html-rtf">
        <nav class="summary-links">
            <xsl:apply-templates select="*" mode="summary-nav" />
        </nav>
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="conclusion" />
</xsl:template>

<!-- File Structure -->
<!-- Gross structure of a Jupyter notebook -->
<!-- TODO: need to make a "simple file wrap" template?  Or just call this?-->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <!--  -->
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="containing-filename" />
    </xsl:variable>
    <xsl:variable name="cell-list">
        <!-- a code cell for reader to load CSS -->
        <!-- First, so already with focus       -->
        <xsl:call-template name="load-css" />
        <!-- load LaTeX macros for MathJax               -->
        <!-- Empty visually, so also provides separation -->
        <xsl:call-template name="latex-macros" />
        <!-- the real content of the page -->
        <xsl:copy-of select="$content" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="text">
        <!-- <xsl:call-template name="converter-blurb-html" /> -->
        <!-- begin outermost group -->
        <xsl:text>{&#xa;</xsl:text>
        <!-- cell list first, majority of notebook, metadata to finish -->
        <xsl:text>"cells": [&#xa;</xsl:text>
        <!-- Escape JSON strings now, be sure later adjustments -->
        <!-- conform to JSON syntax in this regard              -->
        <xsl:variable name="escaped-cell-list">
            <xsl:call-template name="escape-json-string">
                <xsl:with-param name="text" select="$cell-list"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- Multiple strings in a cell are merged into one by    -->
        <!-- combining adjoining end/begin pairs, leaving only    -->
        <!-- leading and trailing delimiters (next substitution). -->
        <!-- This is one solution of the problem of $n-1$         -->
        <!-- separators for $n$ items.                            -->
        <xsl:variable name="split-strings" select="str:replace($escaped-cell-list, $ESBS, '')" />
        <xsl:variable name="finalize-strings" select="str:replace(str:replace($split-strings, $ES, '&quot;'), $BS, '&quot;')" />
        <!-- The only pseudo-markup left is that of the two types -->
        <!-- of cells possible in a Jupyter notebook.  We split   -->
        <!-- just the adjacent brackets with comma-newline, so    -->
        <!-- source has each cell entirely on its own line.  This -->
        <!-- is the other solution of the problem of $n-1$        -->
        <!-- separators for $n$ items.                            -->
        <xsl:variable name="split-cells" select="str:replace($finalize-strings, $RBLB, $RBLB-comma)" />
        <!-- Now we consider the actual markers and replace   -->
        <!-- with the JSON that Jupyter expects as source.    -->
        <!-- We are done, so "value-of" is good enough,       -->
        <!-- rather than having a final $code-cells.  The     -->
        <!-- four *-wrap variables here are just conveniences -->
        <xsl:variable name="markdown-cells" select="str:replace(str:replace($split-cells, $BM, $begin-markdown-wrap), $EM, $end-markdown-wrap)" />
        <xsl:value-of select="str:replace(str:replace($markdown-cells, $BC, $begin-code-wrap), $EC, $end-code-wrap)" />
        <!-- end cell list -->
        <xsl:text>&#xa;],&#xa;</xsl:text>
        <!-- version identifiers -->
        <xsl:text>"nbformat": 4, "nbformat_minor": 0, </xsl:text>
        <!-- metadata copied from blank SMC notebook -->
        <xsl:text>"metadata": {</xsl:text>
        <xsl:text>"kernelspec": {</xsl:text>
        <!-- TODO: configure kernel in "docinfo" -->
        <!-- "display_name" seems ineffective, but is required -->
        <xsl:text>"display_name": "", </xsl:text>
        <!-- TODO: language not needed? -->
        <!-- <xsl:text>"language": "python", </xsl:text> -->
        <!-- TODO: make kernelspec configurable? -->
        <!-- <xsl:text>"name": "python2"</xsl:text> -->
        <!-- "sagemath" as  "name" will be latest kernel -->
        <!-- in Sage distribution Jupyter, and in CoCalc -->
        <xsl:choose>
            <xsl:when test="contains('|python3|Python3|python 3|Python 3|py|Py|python|Python|'
                , concat('|', $jupyter.kernel, '|'))">
                <xsl:text>"name": "python3"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>"name": "sagemath"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- TODO: how much of the following is necessary before loading? -->
        <xsl:text>}, </xsl:text>
        <xsl:text>"language_info": {</xsl:text>
        <xsl:text>"codemirror_mode": {</xsl:text>
        <xsl:text>"name": "ipython", </xsl:text>
        <xsl:text>"version": 3</xsl:text>
        <xsl:text>}, </xsl:text>
        <xsl:text>"file_extension": ".py", </xsl:text>
        <xsl:text>"mimetype": "text/x-python", </xsl:text>
        <xsl:text>"name": "python", </xsl:text>
        <xsl:text>"nbconvert_exporter": "python", </xsl:text>
        <xsl:text>"pygments_lexer": "ipython3", </xsl:text>
        <xsl:text>"version": "3.6.4"</xsl:text>
        <xsl:text>}, </xsl:text>
        <xsl:text>"name": "</xsl:text>
        <xsl:value-of select="$filename" />
        <xsl:text>"</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <!-- end outermost group -->
        <xsl:text>}</xsl:text>
    </exsl:document>
</xsl:template>

<!-- a code cell with HTML magic         -->
<!-- allows reader to activate styling   -->
<!-- Code first, so it begins with focus -->
<xsl:template name="load-css">
    <!-- HTML as one-off code cell   -->
    <!-- Serialize HTML by hand here -->
    <xsl:call-template name="code-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>%%html&#xa;</xsl:text>
            <!-- for offline testing -->
            <!-- <xsl:text>&lt;link href="./mathbook-content.css" rel="stylesheet" type="text/css" /&gt;&#xa;</xsl:text> -->
            <xsl:text>&lt;link href="https://pretextbook.org/beta/mathbook-content.css" rel="stylesheet" type="text/css" /&gt;&#xa;</xsl:text>
            <xsl:text>&lt;link href="https://aimath.org/mathbook/mathbook-add-on.css" rel="stylesheet" type="text/css" /&gt;&#xa;</xsl:text>
            <!-- A bad hack since "subtitle" is in masthead code, better CSS should take care of this -->
            <xsl:if test="$document-root/subtitle">
                <xsl:text>&lt;style&gt;.subtitle {font-size:medium; display:block}&lt;/style&gt;&#xa;</xsl:text>
            </xsl:if>
            <xsl:text>&lt;link href="https://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,600italic" rel="stylesheet" type="text/css" /&gt;&#xa;</xsl:text>
            <xsl:text>&lt;link href="https://fonts.googleapis.com/css?family=Inconsolata:400,700&amp;subset=latin,latin-ext" rel="stylesheet" type="text/css" /&gt;</xsl:text>
            <!-- Cell hider is unwrapped from some notebook display command that injects HTML: -->
            <!-- https://nbviewer.jupyter.org/github/shashi/ijulia-notebooks/blob/master/funcgeo/Functional%20Geometry.ipynb -->
            <xsl:text>&lt;!-- Hide this cell. --&gt;&#xa;</xsl:text>
            <xsl:text>&lt;script&gt;&#xa;</xsl:text>
            <xsl:text>var cell = $(".container .cell").eq(0), ia = cell.find(".input_area")&#xa;</xsl:text>
            <xsl:text>if (cell.find(".toggle-button").length == 0) {&#xa;</xsl:text>
            <xsl:text>ia.after(&#xa;</xsl:text>
            <xsl:text>    $('&lt;button class="toggle-button"&gt;Toggle hidden code&lt;/button&gt;').click(&#xa;</xsl:text>
            <xsl:text>        function (){ ia.toggle() }&#xa;</xsl:text>
            <xsl:text>        )&#xa;</xsl:text>
            <xsl:text>    )&#xa;</xsl:text>
            <xsl:text>ia.hide()&#xa;</xsl:text>
            <xsl:text>}&#xa;</xsl:text>
            <xsl:text>&lt;/script&gt;&#xa;</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
    <!-- instructions as Markdown cell        -->
    <!-- Use markdown, since no CSS yet (duh) -->
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:text>**Important:** to view this notebook properly you will need to execute the cell above, which assumes you have an Internet connection.  It should already be selected, or place your cursor anywhere above to select.  Then press the "Run" button in the menu bar above (the right-pointing arrowhead), or press Shift-Enter on your keyboard.</xsl:text>
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- This will override the HTML version, but is patterned -->
<!-- after same.  Adjustments are: different overall       -->
<!-- delimiters, and no enclosing div to hide content      -->
<!-- (thereby avoiding the need for serialization).        -->
<xsl:template name="latex-macros">
    <xsl:call-template name="markdown-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
            <xsl:call-template name="begin-inline-math" />
            <xsl:value-of select="$latex-packages-mathjax" />
            <xsl:value-of select="$latex-macros" />
            <xsl:call-template name="end-inline-math" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>


<!-- ################# -->
<!-- Block Level Items -->
<!-- ################# -->

<!-- These are "top-level" items, children of divisions    -->
<!-- and pseudo-divisions.  Normally they would get a high -->
<!-- priority, but we want them to have the same low       -->
<!-- priority as a generic (default) wilcard match         -->
<!-- TODO: remove filter on paragraphs once we add stack for sidebyside -->
<xsl:template match="*[parent::*[&STRUCTURAL-FILTER; or self::paragraphs[not(ancestor::sidebyside)] or self::introduction[parent::*[&STRUCTURAL-FILTER;]] or self::conclusion[parent::*[&STRUCTURAL-FILTER;]]]]" priority="-0.5">
    <!-- <xsl:message>G:<xsl:value-of select="local-name(.)" />:G</xsl:message> -->
    <xsl:variable name="html-rtf">
        <xsl:apply-imports />
    </xsl:variable>
    <xsl:variable name="html-node-set" select="exsl:node-set($html-rtf)" />
    <xsl:call-template name="pretext-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:apply-templates select="$html-node-set" mode="serialize" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Kill some templates temporarily -->
<xsl:template name="inline-warning" />
<xsl:template name="margin-warning" />

<!-- Kill some metadata -->
<xsl:template match="title|idx|notation" />


<!-- Sage code -->
<!-- Should evolve to accomodate general template -->
<xsl:template match="sage">
    <!-- formulate lines of code -->
    <xsl:variable name="loc">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="input" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <!-- we trim a final trailing newline -->
    <!-- as we wrap into a single string  -->
    <xsl:call-template name="code-cell">
        <xsl:with-param name="content">
            <xsl:call-template name="begin-string" />
                <xsl:value-of select="substring($loc, 1, string-length($loc)-1)" />
            <xsl:call-template name="end-string" />
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- #### -->
<!-- Math -->
<!-- #### -->

<!-- Our sanitization procedures will preserve author's line   -->
<!-- breaks within mathematics.  Even inline math might be a   -->
<!-- complicated construction, like a column vector, with line -->
<!-- breaks.  Replacements late in the conversion will make    -->
<!-- these the "\n" acceptable in JSON.                        -->

<!-- These two templates provide the delimiters for inline math.     -->
<!-- The Jupyter notebook appears to support the AMS-style for       -->
<!-- inline math ( \(, \) ).  But in doing so, it fails to prevent   -->
<!-- Markdown syntax from mucking up the math.  For example, two     -->
<!-- underscores in a Markdown cell will look like underlining       -->
<!-- and override the LaTeX meaning for subscripts.  They can        -->
<!-- be escaped, but easier to just deal with "plain text" dollar    -->
<!-- signs as a possibility.  There is no issue for display          -->
<!-- mathematics, presumably since we use environments, exclusively. -->
<xsl:template name="begin-inline-math">
    <xsl:text>$</xsl:text>
</xsl:template>

<xsl:template name="end-inline-math">
    <xsl:text>$</xsl:text>
</xsl:template>


<!-- Images -->

<!-- Jupyter seems to not allow an "object" tag.        -->
<!-- So we override the HTML wrapper with a simpler     -->
<!-- version.  Interface info copied from HTML version. -->

<!-- A named template creates the infrastructure for an SVG image -->
<!-- Parameters                                 -->
<!-- svg-filename: required, full relative path -->
<!-- png-fallback-filename: optional            -->
<!-- image-width: required                      -->
<!-- image-description: optional                -->
<xsl:template name="svg-wrapper">
    <xsl:param name="svg-filename" />
    <xsl:param name="png-fallback-filename" select="''" />
    <xsl:param name="image-width" />
    <xsl:param name="image-description" select="''" />
    <xsl:element name="img">
        <xsl:attribute name="src">
            <xsl:value-of select="$svg-filename" />
        </xsl:attribute>
        <xsl:attribute name="width">
            <xsl:value-of select="$image-width" />
        </xsl:attribute>
        <!-- alt attribute for accessibility -->
        <xsl:attribute name="alt">
            <xsl:value-of select="$image-description" />
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<!-- Unicode characters will relieve necessity of        -->
<!-- Font Awesome CSS loading, $icon-table is in -common -->
<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name" select="string(@name)"/>

    <!-- for-each is just one node, but sets context for key() -->
    <xsl:for-each select="$icon-table">
        <xsl:value-of select="key('icon-key', $icon-name)/@unicode" />
    </xsl:for-each>
</xsl:template>

<!-- ################### -->
<!-- Markdown Protection -->
<!-- ################### -->

<!-- XML with LaTeX, to HTML, to JSON.  Its hard to keep track. -->
<!-- And the HTML is really spiced up with Markdown.  Or is it  -->
<!-- the other way around?  No matter, a first defense is to    -->
<!-- convert common simple characters employed by Markdown and  -->
<!-- make them escaped versions.  Here is the list of escapable -->
<!-- characters from the Markdown documentation on 2017-11-06.  -->
<!-- daringfireball.net/projects/markdown/syntax#backslash      -->
<!--                                                            -->
<!--         \   backslash                                      -->
<!--         `   backtick                                       -->
<!--         *   asterisk                                       -->
<!--         _   underscore                                     -->
<!--         {}  curly braces                                   -->
<!--         []  square brackets                                -->
<!--         ()  parentheses                                    -->
<!--         #   hash mark                                      -->
<!--         +   plus sign                                      -->
<!--         -   minus sign (hyphen)                            -->
<!--         .   dot                                            -->
<!--         !   exclamation mark                               -->


<!-- Dollar sign -->
<!-- The Jupyter notebook allows markdown cells to        -->
<!-- use dollar signs to delimit LaTeX, if you have       -->
<!-- two used for financial reasons, they will be         -->
<!-- interpreted incorrectly.  But they can be escaped.   -->
<!-- Not a Markdown element, but critical so here anyway. -->
<xsl:template name="dollar-character">
    <xsl:text>\$</xsl:text>
</xsl:template>

<!-- Other than the dollar sign, these are from the -html code.    -->
<!-- We escape ASCII versions, and leave just comments for         -->
<!-- those whose HTML definitions suffice, either as HTML entities -->
<!-- (&, <, >) or as fancier, non-ASCII, Unicode versions.         -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template name="hash-character">
    <xsl:text>\#</xsl:text>
</xsl:template>

<!-- Underscore -->
<xsl:template name="underscore-character">
    <xsl:text>\_</xsl:text>
</xsl:template>

<!-- Left Brace -->
<xsl:template name="lbrace-character">
    <xsl:text>\{</xsl:text>
</xsl:template>

<!-- Right  Brace -->
<xsl:template name="rbrace-character">
    <xsl:text>\}</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template name="backslash-character">
    <xsl:text>\\</xsl:text>
</xsl:template>

<!-- Asterisk  -->
<xsl:template name="asterisk-character">
    <xsl:text>\*</xsl:text>
</xsl:template>

<!-- Left Bracket -->
<xsl:template name="lbracket-character">
    <xsl:text>\[</xsl:text>
</xsl:template>

<!-- Right Bracket -->
<xsl:template name="rbracket-character">
    <xsl:text>\]</xsl:text>
</xsl:template>

<!-- Backtick -->
<!-- This is the rationale for this element. -->
<!-- We can use it in a text context,        -->
<!-- and protect it here from Markdown.      -->
<xsl:template name="backtick-character">
    <xsl:text>\`</xsl:text>
</xsl:template>

<!-- Markdown protection remaining unimplemented?            -->
<!-- These are symbols we would not want to need to          -->
<!-- replace by PreTeXt empty elements, since they           -->
<!-- are in heavy use.  Some require placement in            -->
<!-- column 1, which may never happen as a text              -->
<!-- (Markdown) cell will always have lots of HTML           -->
<!-- around without many newlines at all.  If square         -->
<!-- brackets are escaped, the link and image                -->
<!-- constructions will break, so exclamation marks          -->
<!-- and parentheses will render correctly, even if          -->
<!-- accidentally forming the Markdown constructions         -->
<!-- for links or images.                                    -->
<!--                                                         -->
<!-- 1.  parentheses - only an issue following []            -->
<!-- 2.  plus, minus/hyphen - list items if in column 1      -->
<!-- 3.  hyphens - three in a row is an hrule.  Breakup?     -->
<!-- 4.  dot - numbered list construction, in column 1       -->
<!-- 4.  exclamation - part of image construction, before [] -->

<!--
TODO: (overall)

1.  DONE: Interfere with left-angle bracket to make elements not evaporate in serialization.
2.  DONE: Escape $ so that pairs do not go MathJax on us.
3.  DONE: Do we need to protect a hash?  So not interpreted as a title?  Underscores, too.
4.  Update CSS, use add-on, make an output version to parse as text.
5.  ABANDON: Markup enclosed Sage cells (non-top-level) to allow dropout, dropin.
    Bad idea, breaks CSS begin/end across multiple cells
6.  Remove empty strings, empty anything, with search/replace step on null constructions.
7.  Maybe replace tabs (good for Sage code and/or JSON fidelity)?
8.  Hyperlinks within a file work better if not prefixed with file name.
    (General improvement, but not so important with knowls available.)
-->


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
<!-- Markdown has hijacked for special purposes.               -->

<xsl:template name="text-processing">
    <xsl:param name="text"/>

    <!-- Backslash first, then clear to add more -->
    <xsl:variable name="backslash-fixed"  select="str:replace($text,            '\',  '\\')"/>
    <xsl:variable name="lbrace-fixed"     select="str:replace($backslash-fixed, '{',  '\{')"/>
    <xsl:variable name="rbrace-fixed"     select="str:replace($lbrace-fixed,    '}',  '\}')"/>
    <xsl:variable name="hash-fixed"       select="str:replace($rbrace-fixed,    '#',  '\#')"/>
    <xsl:variable name="dollar-fixed"     select="str:replace($hash-fixed,      '$',  '\$')"/>
    <xsl:variable name="underscore-fixed" select="str:replace($dollar-fixed,    '_',  '\_')"/>
    <xsl:variable name="asterisk-fixed"   select="str:replace($underscore-fixed,'*',  '\*')"/>
    <xsl:variable name="backtick-fixed"   select="str:replace($asterisk-fixed,  '`',  '\`')"/>

    <!-- We disrupt accidental MathJax formulations in running text.  MathJax     -->
    <!-- needs both begin *and* end markers, enclosed in a single HTML element,   -->
    <!-- before it will start injecting itself onto the page.  We leave a begin   -->
    <!-- marker alone, but disrupt an end marker with a superfluous minimal span. -->
    <!-- This is advice from David Cervone, JMM Baltimore, 2019-01-18.            -->
    <!-- Note: we serialize the necessary HTML by hand, and the brace and         -->
    <!-- backslash used in matching the leading portion of a LaTeX environment    -->
    <!-- were both escaped above.                                                 -->
    <xsl:variable name="inline-fixed"      select="str:replace($backtick-fixed, '\)',      '&lt;span&gt;\)&lt;/span&gt;' )"/>
    <xsl:variable name="environment-fixed" select="str:replace($inline-fixed,   '\\end\{', '&lt;span&gt;\\end\{&lt;/span&gt;' )"/>

    <xsl:value-of select="$environment-fixed"/>
</xsl:template>

<!-- ############### -->
<!-- Inline Verbatim -->
<!-- ############### -->

<!-- Jupyter does a very good (but incomplete) job with inline -->
<!-- verbatim text, requiring little care by authors.  But a   -->
<!-- few gotchas need adjustment.  So we override.             -->
<xsl:template match="c">
    <!-- grab content literally -->
    <xsl:variable name="text" select="string(.)"/>

    <!-- We wrap verbatim inline text with an HTML "code" element. -->
    <!-- When there are to in close proximity (same paragraph)     -->
    <!-- certain characters can pair up (as Markdown, or MathJax,  -->
    <!-- delimiters?) and wreak havoc.  But escaped versions seem  -->
    <!-- to perform well in all cases, so we make these            -->
    <!-- replacements first.                                       -->
    <xsl:variable name="backtick-fixed"   select="str:replace($text,           '`',  '\`' )"/>
    <xsl:variable name="asterisk-fixed"   select="str:replace($backtick-fixed, '*',  '\*' )"/>
    <xsl:variable name="underscore-fixed" select="str:replace($asterisk-fixed, '_',  '\_' )"/>

    <!-- Jupyter notebook is careful about XML special characters, -->
    <!-- but if you want to write about the escaped versions, they -->
    <!-- just get converted to the real thing.  So in these five   -->
    <!-- very special situations we escape the leading ampersand   -->
    <!-- and whatever conversion is happening is satiated.         -->
    <xsl:variable name="escaped-ampersand-fixed"    select="str:replace($underscore-fixed,           '&amp;amp;',  '&amp;amp;amp;' )"/>
    <xsl:variable name="escaped-leftbracket-fixed"  select="str:replace($escaped-ampersand-fixed,    '&amp;lt;',   '&amp;amp;lt;' )"/>
    <xsl:variable name="escaped-rightbracket-fixed" select="str:replace($escaped-leftbracket-fixed,  '&amp;gt;',   '&amp;amp;gt;' )"/>
    <xsl:variable name="escaped-apostrophe-fixed"   select="str:replace($escaped-rightbracket-fixed, '&amp;apos;', '&amp;amp;apos;' )"/>
    <xsl:variable name="escaped-quote-fixed"        select="str:replace($escaped-apostrophe-fixed,   '&amp;quot;', '&amp;amp;quot;' )"/>

    <!-- If you want to write about elements (like in the Author's     -->
    <!-- Guide!) then you cannot have elements/tags sitting unaltered  -->
    <!-- in verbatim text, since they now look like interior HTML.     -->
    <!-- So we disrupt the leading left-bracket with an escaped        -->
    <!-- version and let that convert to the character.                -->
    <xsl:variable name="leftbracket-fixed" select="str:replace($escaped-quote-fixed, '&lt;', '&amp;lt;' )"/>

    <!-- We enclose with PreTeXt's HTML, serializing by hand -->
    <xsl:text>&lt;code class="code-inline tex2jax_ignore"&gt;</xsl:text>
        <xsl:value-of select="$leftbracket-fixed"/>
    <xsl:text>&lt;/code&gt;</xsl:text>
</xsl:template>

<!-- #### -->
<!-- URLs -->
<!-- #### -->

<!-- We encode some characters in href attributes, here   -->
<!-- just for the Jupyter conversion, as an override of   -->
<!-- part of the serialization.  This could instead be    -->
<!-- sanitization of the "url"element, in the general     -->
<!-- HTML conversion or here for just Jupyter.  So        -->
<!-- eventually this could migrate to another location    -->
<!-- in the pipeline.                                     -->
<!--                                                      -->
<!-- The problem seems to be characters, used in pairs,   -->
<!-- to delimit text for Markdown or MathJax:  underscore -->
<!-- is italics, asterisk is emphasis, and dollar signs   -->
<!-- delimit math.  This is a hunch based on similar      -->
<!-- experiences with inline verbatim text.  But here we  -->
<!-- are fortunate to be able to encode the dollar sign.  -->
<xsl:template match="@href" mode="serialize">
    <!-- sanitize value first -->
    <xsl:variable name="text" select="string(.)"/>
    <xsl:variable name="underscore-fixed" select="str:replace($text,             '_',  '%5F')"/>
    <xsl:variable name="asterisk-fixed"   select="str:replace($underscore-fixed, '*',  '%2A')"/>
    <xsl:variable name="dollar-fixed"     select="str:replace($asterisk-fixed,   '$',  '%24')"/>
    <!-- construct new attribute, spacing, name, value -->
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="$dollar-fixed"/>
    <xsl:text>"</xsl:text>
</xsl:template>

<!-- ########################## -->
<!-- Intermediate Pseudo-Markup -->
<!-- ########################## -->

<!-- A Jupyter notebook is a flat sequence of cells, of type either     -->
<!-- "markdown" or "code."  The content is primarily a list of strings. -->
<!-- This presents two fundamental problems:                            -->
<!--                                                                    -->
<!--   1.  Lists of cells, or lists of strings, with  n  items          -->
<!--       need exactly  n-1  commas.  It is hard to predict/find       -->
<!--       the first or last element of a list.                         -->
<!--                                                                    -->
<!--   2.  Cells cannot be nested and content should not lie            -->
<!--       outside of cells.                                            -->
<!--                                                                    -->
<!-- We use a sort of pseudo-markup.  Adjacency of items lets           -->
<!-- us solve the comma problem.  We are also able to effectively       -->
<!-- merge content into a cell, without knowing anything about          -->
<!-- the following cell.                                                -->
<!--                                                                    -->
<!-- We pipeline a pseudo-markup as an intermediate text format.        -->
<!--                                                                    -->
<!-- Pseudo-markup language:                                            -->
<!--                                                                    -->
<!-- LB, RB: left and right brackets - should be UUIDs eventually       -->
<!--                                                                    -->
<!-- BS, ES: begin and end string                                       -->
<!--                                                                    -->
<!-- BM, EM, BC, EC: begin and end, markdown and code, cells            -->


<!-- ####### -->
<!-- Markers -->
<!-- ####### -->

<!-- This is pseudo-markup, starting with delimiters       -->
<!-- analagous to < and > of XML.   Make these delimiters  -->
<!-- exceedingly unique.  Comment out salt while debugging -->
<!-- if it helps to see intermediate structure. Or leave   -->
<!-- salt in, and grep final output for this "bad" string  -->
<!-- that should not survive.                              -->

<!-- Random-ish output from  mkpasswd  utility,           -->
<!-- 2017-10-24 at AMS airport, Starbucks by faux gate D1 -->
<xsl:variable name="salt" select="'x9rNtyUydoz3o'" />

<xsl:variable name="LB">
    <xsl:text>[[[</xsl:text>
    <xsl:value-of select="$salt" />
</xsl:variable>

<xsl:variable name="RB">
    <xsl:value-of select="$salt" />
    <xsl:text>]]]</xsl:text>
</xsl:variable>

<!-- These are analagous to XML opening           -->
<!-- ("begin", B) and closing ("end", E) elements -->

<!-- Destined to be string -->
<xsl:variable name="BS">
    <xsl:value-of select="$LB" />
    <xsl:text>BS</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>
<xsl:variable name="ES">
    <xsl:value-of select="$LB" />
    <xsl:text>ES</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<!-- Destined to be a Jupyter markdown cell in JSON output-->
<xsl:variable name="BM">
    <xsl:value-of select="$LB" />
    <xsl:text>BM</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>
<xsl:variable name="EM">
    <xsl:value-of select="$LB" />
    <xsl:text>EM</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<!-- Destined to be a Jupyter code cell in JSON output-->
<xsl:variable name="BC">
    <xsl:value-of select="$LB" />
    <xsl:text>BC</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>
<xsl:variable name="EC">
    <xsl:value-of select="$LB" />
    <xsl:text>EC</xsl:text>
    <xsl:value-of select="$RB" />
</xsl:variable>

<!-- These variables describe adjacent pseudo-markup -->
<!-- that will be converted to JSON equivalents.     -->

<xsl:variable name="ESBS">
    <xsl:value-of select="$ES" />
    <xsl:value-of select="$BS" />
</xsl:variable>

<xsl:variable name="RBLB">
    <xsl:value-of select="$RB" />
    <xsl:value-of select="$LB" />
</xsl:variable>

<!-- This is a convenience for the replacement that -->
<!-- splits cells into lines within JSON file       -->
<xsl:variable name="RBLB-comma">
    <xsl:value-of select="$RB" />
    <xsl:text>,&#xa;</xsl:text>
    <xsl:value-of select="$LB" />
</xsl:variable>

<!-- Convenience templates -->
<!-- These are primary interface to our creation          -->
<!-- of pseudo-markup above, but are not the whole        -->
<!-- story since we convert markup based on the variables -->

<xsl:template name="begin-string">
    <xsl:value-of select="$BS" />
</xsl:template>

<xsl:template name="end-string">
    <xsl:value-of select="$ES" />
</xsl:template>

<xsl:template name="begin-markdown-cell">
    <xsl:value-of select="$BM" />
</xsl:template>

<xsl:template name="end-markdown-cell">
    <xsl:value-of select="$EM" />
</xsl:template>

<xsl:template name="begin-code-cell">
    <xsl:value-of select="$BC" />
</xsl:template>

<xsl:template name="end-code-cell">
    <xsl:value-of select="$EC" />
</xsl:template>


<!-- ################# -->
<!-- Cell Construction -->
<!-- ################# -->

<xsl:variable name="begin-markdown-wrap">
    <xsl:text>{"cell_type":"markdown", "metadata":{}, "source":[</xsl:text>
</xsl:variable>

<xsl:variable name="end-markdown-wrap">
    <xsl:text>]}</xsl:text>
</xsl:variable>

<xsl:variable name="begin-code-wrap">
    <xsl:text>{"cell_type":    "code", "execution_count":null, "metadata":{}, "source":[</xsl:text>
</xsl:variable>

<xsl:variable name="end-code-wrap">
    <xsl:text>], "outputs":[]}</xsl:text>
</xsl:variable>

<!-- A Jupyter markdown cell intended  -->
<!-- to hold markdown or unstyled HTML -->
<xsl:template name="markdown-cell">
    <xsl:param name="content" />
    <xsl:call-template name="begin-markdown-cell" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="end-markdown-cell" />
</xsl:template>

<!-- A Jupyter markdown cell intended -->
<!-- to hold PreTeXt styled HTML      -->
<!-- Serialization here is "by hand"  -->
<xsl:template name="pretext-cell">
    <xsl:param name="content" />
    <xsl:call-template name="begin-markdown-cell" />
    <xsl:call-template name="begin-string" />
    <xsl:text>&lt;div class="mathbook-content"&gt;</xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="begin-string" />
    <xsl:text>&lt;/div&gt;</xsl:text>
    <xsl:call-template name="end-string" />
    <xsl:call-template name="end-markdown-cell" />
</xsl:template>

<!-- A Jupyter code cell intended -->
<!-- to hold raw text/code        -->
<xsl:template name="code-cell">
    <xsl:param name="content" />
    <xsl:call-template name="begin-code-cell" />
    <xsl:value-of select="$content" />
    <xsl:call-template name="end-code-cell" />
</xsl:template>

</xsl:stylesheet>
