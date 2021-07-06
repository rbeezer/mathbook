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
<!-- We choose to not include a default namespace       -->
<!-- (in particular  http://www.w3.org/1999/xhtml),     -->
<!-- even if this complicates adding namespaces onto    -->
<!-- derivatives, such as HTML destined for EPUB output -->
<!-- xmlns="http://www.w3.org/1999/xhtml"               -->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="b64"
    extension-element-prefixes="exsl date str"
>

<xsl:import href="./pretext-common.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>


<!-- We create HTML5 output.  The @doctype-system attribute will    -->
<!-- create a header in the old style that browsers will recognize  -->
<!-- as signaling HTML5.  However  xsltproc  does one better and    -->
<!-- writes the super-simple <!DOCTYPE html> header.  See all of    -->
<!-- https://stackoverflow.com/questions/3387127/                   -->
<!-- (set-html5-doctype-with-xslt)                                  -->
<!--                                                                -->
<!-- Indentation is weak, it is just strategic newlines.  This is   -->
<!-- explained late in the thread by Daniel Veillard:               -->
<!-- http://docbook-apps.oasis-open.narkive.com/tDqyEc91/           -->
<!-- (two-issues-with-xslt-processors-xsltproc-and-xalan)           -->
<!--                                                                -->
<!-- Since we write output into multiple files, likely this         -->
<!-- declaration is never active, but it serves as a model here for -->
<!-- subsequent exsl:document elements.                             -->

<xsl:output method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat" />

<!-- Not documented, for development use only -->
<xsl:param name="runestone.dev" select="''"/>
<xsl:variable name="runestone-dev" select="$runestone.dev = 'yes'"/>

<!-- ################################################ -->
<!-- Following is slated to migrate above, 2019-07-10 -->
<!-- ################################################ -->

<!-- Parameters -->
<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- See more generally applicable parameters in pretext-common.xsl file     -->

<!-- CSS and Javascript Servers -->
<!-- We allow processing paramteers to specify new servers   -->
<!-- or to specify the particular CSS file, which may have   -->
<!-- different color schemes.  The defaults should work      -->
<!-- fine and will not need changes on initial or casual use -->
<!-- Files with name colors_*.css set the colors.            -->
<!-- colors_default is similar to the old mathbook-3.css     -->
<!-- N.B.: if the CSS has a version bump, then be sure to    -->
<!-- visit the "css" directory and make an update there      -->
<!-- for the benefit of offline formats                      -->
<xsl:param name="html.css.server" select="'https://pretextbook.org'" />
<xsl:param name="html.css.version" select="'0.31'" />
<xsl:param name="html.js.server" select="'https://pretextbook.org'" />
<xsl:param name="html.js.version" select="'0.13'" />

<!-- Annotation -->
<xsl:param name="html.annotation" select="''" />
<xsl:variable name="b-activate-hypothesis" select="boolean($html.annotation='hypothesis')" />

<!-- Navigation -->
<!-- Navigation may follow two different logical models:                     -->
<!--   (a) Linear, Prev/Next - depth-first search, linear layout like a book -->
<!--       Previous and Next take you to the adjacent "page"                 -->
<!--   (b) Tree, Prev/Up/Next - explicitly traverse the document tree        -->
<!--       Prev and Next remain at same depth/level in tree                  -->
<!--       Must follow a summary link to descend to finer subdivisions       -->
<!--   'linear' is the default, 'tree' is an option                          -->
<xsl:param name="html.navigation.logic"  select="'linear'" />
<!-- The "up" button is optional given the contents sidebar, default is to have it -->
<!-- An up button is very desirable if you use the tree-like logic                 -->
<xsl:param name="html.navigation.upbutton"  select="'yes'" />
<!-- There are also "compact" versions of the navigation buttons in the top right -->
<xsl:param name="html.navigation.style"  select="'full'" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->
<!-- Variables that affect HTML creation -->
<!-- More in the common file             -->

<!-- Search for the "math.punctuation.include" -->
<!-- global variable, which is discussed in    -->
<!-- closer proximity to its application.      -->

<!-- This is cribbed from the CSS "max-width"-->
<!-- Design width, measured in pixels        -->
<!-- NB: the exact same value, for similar,  -->
<!-- but not identical, reasons is used in   -->
<!-- the formation of WeBWorK problems       -->
<xsl:variable name="design-width" select="'600'" />

<!-- We generally want to chunk longer HTML output -->
<xsl:variable name="chunk-level">
    <xsl:choose>
        <xsl:when test="$chunk-level-entered != ''">
            <xsl:value-of select="$chunk-level-entered" />
        </xsl:when>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: HTML chunk level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Local versions of navigation options -->
<!-- Fatal errors if not recognized       -->
<xsl:variable name="nav-logic">
    <xsl:choose>
        <xsl:when test="$html.navigation.logic='linear'">
            <xsl:text>linear</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.logic='tree'">
            <xsl:text>tree</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>linear</xsl:text>
            <xsl:message>MBX:ERROR: 'html.navigation.logic' must be 'linear' or 'tree', not '<xsl:value-of select="$html.navigation.logic" />.'  Using the default instead ('linear').</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="nav-upbutton">
    <xsl:choose>
        <xsl:when test="$html.navigation.upbutton='yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.upbutton='no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
            <xsl:message>MBX:ERROR: 'html.navigation.upbutton' must be 'yes' or 'no', not '<xsl:value-of select="$html.navigation.upbutton" />.'  Using the default instead ('yes').</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="nav-style">
    <xsl:choose>
        <xsl:when test="$html.navigation.style='full'">
            <xsl:text>full</xsl:text>
        </xsl:when>
        <xsl:when test="$html.navigation.style='compact'">
            <xsl:text>compact</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>full</xsl:text>
            <xsl:message>MBX:ERROR: 'html.navigation.style' must be 'full' or 'compact', not '<xsl:value-of select="$html.navigation.style" />.'  Using the default instead ('full').</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- HTML files as output -->
<xsl:variable name="file-extension" select="'.html'" />

<!-- "presentation" mode is experimental, target        -->
<!-- is in-class presentation of a textbook             -->
<!--   (1) clickable mathematics (MathJax) at 300% zoom -->
<!-- boolean variable $b-html-presentation              -->
<xsl:param name="html.presentation" select="'no'" />
<xsl:variable name="b-html-presentation" select="$html.presentation = 'yes'" />

<!-- We may someday support justified text, presuming good browser  -->
<!-- support.  For now, we warn if the global parameter is set, and -->
<!-- override the variable's value, which is not ever consulted     -->
<xsl:variable name="text-alignment">
    <xsl:if test="not($text.alignment = '')">
        <xsl:message>PTX:WARNING: the "text.alignment" string parameter ("<xsl:value-of select="$text.alignment"/>") has no effect on this conversion, assuming "raggedright"</xsl:message>
    </xsl:if>
    <xsl:text>raggedright</xsl:text>
</xsl:variable>

<!-- We make a much different variant of HTML output as input to    -->
<!-- liblouis for conversion of literary text to braille.  When it  -->
<!-- is easier to insert a small change in the interior of a        -->
<!-- template, we use this variable to condition the change, rather -->
<!-- than providing a new template in the braille conversion.       -->
<!--                                                                -->
<!-- We set the internal boolean variable to false() here, and turn -->
<!-- it on in the dedicated stylesheet for conversion to braille.   -->
<xsl:variable name="b-braille" select="false()"/>

<!-- The Runestone platform option requires output that can be used  -->
<!-- on the server with a templating language/tool.  For books       -->
<!-- originating from PreTeXt we use a non-default pair of strings.  -->
<!-- This is because the default is {{, }} and these behave poorly   -->
<!-- in  a/@href  output, since the outer pair looks like an XSL AVT -->
<!-- and then the inner pair gets escaped as a reserved character in -->
<!-- a URI.  (We can turn off URI-escaping with XSLT 2.0, but the    -->
<!-- AVT confusion may still be a problem.)                          -->

<!-- These are used two places, so defined globally, not  -->
<!-- conditionally.  Due to their ubiquity in these two   -->
<!-- concentrated locations, the variable names are       -->
<!-- intentionally cryptic, contrary to usual practice.   -->
<!-- rs = Runestone, o = open, c = close.                 -->

<xsl:variable name="rso" select="'~._'"/>
<xsl:variable name="rsc" select="'_.~'"/>

<!-- ############### -->
<!-- Source Analysis -->
<!-- ############### -->

<!-- We check certain aspects of the source and record the results   -->
<!-- in boolean ($b-has-*) variables or as particular nodes high up  -->
<!-- in the structure ($document-root).  Scans here in -html should  -->
<!-- help streamline the construction of the HTML page "head" by     -->
<!-- computing properties that will be used in the "head" of every   -->
<!-- page of every chunk. checked more than once. While technically  -->
<!-- generally part of constructing the head, there is no real harm  -->
<!-- in making these global variables.  Short, simple, and universal -->
<!-- properties are determined in -common. These may duplicate       -->
<!-- variables in disjoint conversions.                              -->

<xsl:variable name="b-has-icon"         select="boolean($document-root//icon)"/>
<xsl:variable name="b-has-webwork-reps" select="boolean($document-root//webwork-reps)"/>
<xsl:variable name="b-has-program"      select="boolean($document-root//program)"/>
<xsl:variable name="b-has-sage"         select="boolean($document-root//sage)"/>
<xsl:variable name="b-has-sfrac"        select="boolean($document-root//m[contains(text(),'sfrac')]|$document-root//md[contains(text(),'sfrac')]|$document-root//me[contains(text(),'sfrac')]|$document-root//mrow[contains(text(),'sfrac')])"/>
<xsl:variable name="b-has-geogebra"     select="boolean($document-root//interactive[@platform='geogebra'])"/>
<!-- 2018-04-06:  jsxgraph deprecated -->
<xsl:variable name="b-has-jsxgraph"     select="boolean($document-root//jsxgraph)"/>
<xsl:variable name="b-has-pytutor"      select="boolean($document-root//program[@interactive='pythontutor'])"/>
<!-- Every page has an index button, with a link to the index -->
<!-- Here we assume there is at most one                      -->
<!-- (The old style of specifying an index is deprecated)     -->
<xsl:variable name="the-index"          select="($document-root//index-part|$document-root//index[index-list])[1]"/>

<!-- ######## -->
<!-- WeBWorK  -->
<!-- ######## -->

<!-- WeBWorK exercise may be rendered static="yes" or static="no" makes  -->
<!-- an interactive problem. Also in play here are params from -common:  -->
<!-- exercise.text.statement, exercise.text.hint, exercise.text.solution -->
<!-- For a divisional exercise, when static="no", that is an intentional -->
<!-- decision to show the live problem, which means the statement will   -->
<!-- be shown, regardless of exercise.text.statement. For webwork-reps   -->
<!-- version 2 (WW 2.16 and later), we respect the values for            -->
<!-- exercise.text.hint, exercise.text.answer, exercise.text.solution.   -->
<!-- For version 1, if the problem was authored in PTX source, we can    -->
<!-- respect the values for exercise.text.hint, exercise.text.solution.  -->
<!-- When the problem is static, we can respect exercise.text.answer.    -->
<!-- When the problem is live, we cannot stop the user from seeing the   -->
<!-- answers. And if the problem source is on the webwork server, then   -->
<!-- hints and solutions will show  no matter what.                      -->
<xsl:param name="webwork.inline.static" select="'no'" />
<xsl:param name="webwork.divisional.static" select="'yes'" />
<xsl:param name="webwork.reading.static" select="'yes'" />
<xsl:param name="webwork.worksheet.static" select="'yes'" />

<xsl:variable name="webwork-reps-version" select="$document-root//webwork-reps[1]/@version"/>

<xsl:variable name="webwork-domain">
    <xsl:choose>
        <xsl:when test="$webwork-reps-version = 1">
            <xsl:value-of select="$document-root//webwork-reps[1]/server-url[1]/@domain" />
        </xsl:when>
        <xsl:when test="$webwork-reps-version = 2">
            <xsl:value-of select="$document-root//webwork-reps[1]/server-data/@domain" />
        </xsl:when>
    </xsl:choose>
</xsl:variable>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- Deprecation warnings are universal analysis of source and parameters   -->
<!-- There is always a "document root" directly under the mathbook element, -->
<!-- and we process it with the chunking template called below              -->
<!-- Note that "docinfo" is at the same level and not structural, so killed -->
<xsl:template match="/">
    <!-- temporary - while Hypothesis annotation is beta -->
    <xsl:if test="$b-activate-hypothesis">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">Hypothes.is annotation is experimental</xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <xsl:apply-templates select="mathbook|pretext" mode="generic-warnings" />
    <xsl:apply-templates select="mathbook|pretext" mode="deprecation-warnings" />
    <!-- Usually no manifest is created -->
    <xsl:call-template name="runestone-manifest"/>
    <!-- The main event                          -->
    <!-- We process the enhanced source pointed  -->
    <!-- to by $root at  /mathbook  or  /pretext -->
    <xsl:apply-templates select="$root"/>
</xsl:template>

<!-- We process structural nodes via chunking routine in xsl/pretext-common.xsl    -->
<!-- This in turn calls specific modal templates defined elsewhere in this file     -->
<!-- The xref-knowl templates run independently on content node of document tree    -->
<xsl:template match="/mathbook|/pretext">
    <xsl:call-template name="index-redirect-page"/>
    <xsl:apply-templates mode="chunking" />
    <xsl:if test="$b-knowls-new">
        <xsl:apply-templates select="." mode="make-efficient-knowls"/>
    </xsl:if>
    <xsl:if test="not($b-knowls-new)">
        <xsl:apply-templates select="$document-root" mode="xref-knowl-old"/>
    </xsl:if>
</xsl:template>

<!-- However, some MBX document types do not have    -->
<!-- universal conversion, so these default warnings -->
<!-- should be overridden by supported conversions   -->
<xsl:template match="letter" mode="chunking">
    <xsl:message terminate="yes">
        <xsl:text>MBX:FATAL:  HTML conversion does not support the "letter" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>

<xsl:template match="memo" mode="chunking">
    <xsl:message terminate="yes">
        <xsl:text>MBX:FATAL:  HTML conversion does not support the "memo" document type.  Quitting...</xsl:text>
    </xsl:message>
</xsl:template>

<!-- We build a simple, instantaneous, redirection page based on the    -->
<!-- publisher html/index-page/@ref option.  We write it first, so if   -->
<!-- the deprecated scheme is in place then it will overwrite this one. -->
<!-- See https://css-tricks.com/redirect-web-page/ for alternatives     -->
<xsl:template name="index-redirect-page">
    <exsl:document href="index.html" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <html>
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="converter-blurb-html" />
            <head>
                <meta http-equiv="refresh" content="0; URL='{$html-index-page}'" />
            </head>
            <body/>
        </html>
    </exsl:document>
</xsl:template>

<!-- ################ -->
<!-- Structural Nodes -->
<!-- ################ -->

<!-- Read the code and documentation for "chunking" in xsl/pretext-common.xsl  -->
<!-- This will explain document structure (not XML structure) and has the       -->
<!-- routines which employ the realizations below of two abstract templates.    -->

<!-- The HTML "section" elements created here could have an ARIA    -->
<!-- role="region", but would have to then have a @aria-labelled-by -->
<!-- whose value is the HTML id of the "hX" heading to get its      -->
<!-- content as the label.  But the "section-header" template is    -->
<!-- sometimes null, and even if not, the "hX" elements do not now  -->
<!-- have natural id on them (we could manufacture such a thing).   -->

<!-- Default template for content of a structural  -->
<!-- division, which could be an entire page's     -->
<!-- worth, or just a subdivision withing a page   -->
<!-- Increment $heading-level within this template -->
<!-- NB: Override in the Braille conversion for    -->
<!-- just "frontmatter" and "backmatter" simply    -->
<!-- to keep from stepping the heading level, so   -->
<!-- the liblouis styling on h1-h6 is consistent   -->
<xsl:template match="&STRUCTURAL;">
    <xsl:param name="heading-level"/>

    <!-- location info for debugging efforts -->
    <xsl:apply-templates select="." mode="debug-location" />
    <!-- Heading, div for this structural subdivision -->
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <section class="{local-name(.)}" id="{$hid}">
        <xsl:apply-templates select="." mode="section-header">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="author-byline"/>
        <!-- If there is watermark text, we print it here in an assistive p -->
        <!-- so that it is the first thing read by a screen-reader user.    -->
        <xsl:if test="$b-watermark and $heading-level = 2">
            <p class="watermark">
                <xsl:text>Watermark text: </xsl:text>
                <xsl:value-of select="$watermark.text"/>
                <xsl:text></xsl:text>
            </p>
        </xsl:if>
        <!-- After the heading, and before the actual guts, we      -->
        <!-- sometimes annotate with a knowl showing the source     -->
        <!-- of the current element.  This calls a stub, unless     -->
        <!-- a separate stylesheet is used to define the template,  -->
        <!-- and the method is defined there.                       -->
        <xsl:apply-templates select="." mode="view-source-knowl"/>
        <!-- Most divisions are a simple list of elements to be       -->
        <!-- processed in document order, once we handle metadata     -->
        <!-- properly, and also kill it so it is not caught up here.  -->
        <!-- One exception: the "solutions" division has no children, -->
        <!-- it just gets built (via a modal template so it does not  -->
        <!-- come back through here).                                 -->
        <xsl:choose>
            <xsl:when test="self::solutions">
                <!-- this is not recurrence, do not increment heading-level -->
                <xsl:apply-templates select="." mode="solutions">
                    <xsl:with-param name="heading-level" select="$heading-level"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <!-- this is usually recurrence, so increment heading-level, -->
                <!-- but "book" and "article" have an h1  masthead, so if    -->
                <!-- this is the context, we just pass along the level of    -->
                <!-- "2" which is supplied by the chunking templates         -->
                <xsl:variable name="next-level">
                    <xsl:choose>
                        <xsl:when test="self::book or self::article">
                            <xsl:value-of select="$heading-level"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$heading-level + 1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:apply-templates>
                    <xsl:with-param name="heading-level" select="$next-level"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </section>
    <!-- For a "worksheet" (only), we do it again TWICE, -->
    <!-- to generate standalone printable versions       -->
    <xsl:if test="self::worksheet">
        <xsl:apply-templates select="." mode="standalone-worksheets"/>
    </xsl:if>
</xsl:template>

<!-- Worksheets generate two additional versions, each -->
<!-- designed for printing, on US Letter or A4 paper.  -->
<!-- TODO: worth making one template to use twice?     -->
<xsl:template match="worksheet" mode="standalone-worksheets">
    <xsl:variable name="base-filename">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:variable>
    <!-- US Letter version, indicated by class on the HTML body element -->
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="filename">
            <xsl:apply-templates select="." mode="standalone-filename-letter"/>
        </xsl:with-param>
        <xsl:with-param name="extra-body-classes">
            <!-- Hack, include leading space -->
            <xsl:text> standalone worksheet letter</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="content">
            <!-- No enclosing structure, just sequence of pages -->
            <!-- parameterized as 'printable' (not 'viewable')  -->
            <xsl:apply-templates select="page">
                <xsl:with-param name="purpose" select="'printable'"/>
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- A4 version, indicated by (lower-case) class on the HTML body element -->
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="filename">
            <xsl:apply-templates select="." mode="standalone-filename-A4"/>
        </xsl:with-param>
        <xsl:with-param name="extra-body-classes">
            <!-- Hack, include leading space -->
            <xsl:text> standalone worksheet a4</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="content">
            <!-- No enclosing structure, just sequence of pages -->
            <!-- parameterized as 'printable' (not 'viewable')  -->
            <xsl:apply-templates select="page">
                <xsl:with-param name="purpose" select="'printable'"/>
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Modal template for content of a summary page   -->
<!-- Introduction (etc.) and conclusion realized as -->
<!-- normal, then links to subsidiary divisions     -->
<!-- occur between, as a group of button/hyperlinks -->
<!-- heading-level of parent should come in as 1,   -->
<!-- so then passed to "section-header" as 2.       -->
<!-- Always.                                        -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <xsl:param name="heading-level"/>

    <!-- location info for debugging efforts -->
    <xsl:apply-templates select="." mode="debug-location" />
    <!-- Heading, div for this structural subdivision -->
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <section class="{local-name(.)}" id="{$hid}">
        <xsl:apply-templates select="." mode="section-header">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="author-byline"/>
        <xsl:apply-templates select="objectives|introduction|titlepage|abstract" />
        <nav class="summary-links">
            <ul>
                <xsl:apply-templates select="*" mode="summary-nav" />
            </ul>
        </nav>
        <xsl:apply-templates select="conclusion|outcomes"/>
    </section>
</xsl:template>

<!-- Navigation -->
<!-- Structural nodes on a summary page  -->
<!-- become attractive button/hyperlinks -->
<xsl:template match="&STRUCTURAL;" mode="summary-nav">
    <xsl:variable name="num">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:variable name="url">
        <xsl:apply-templates select="." mode="url" />
    </xsl:variable>
    <li>
        <a href="{$url}">
            <!-- do not include an empty codenumber span -->
            <xsl:if test="not($num = '')">
                <span class="codenumber">
                    <xsl:value-of select="$num" />
                </span>
                <xsl:text> </xsl:text>
            </xsl:if>
            <!-- title is required on structural elements -->
            <span class="title">
                <xsl:apply-templates select="." mode="title-short" />
            </span>
        </a>
    </li>
</xsl:template>

<!-- introduction (etc.) and conclusion get dropped -->
<xsl:template match="*" mode="summary-nav" />

<!-- ############### -->
<!-- Bits and Pieces -->
<!-- ############### -->

<!-- Header for Document Nodes -->
<!-- Every document node goes the same way, a    -->
<!-- heading followed by its subsidiary elements -->
<!-- hit with templates.  This is the header.    -->
<!-- Only "chapter" ever gets shown generically  -->
<!-- Subdivisions have titles, or default titles -->
<!-- NB: this template is overridden for Braille -->
<xsl:template match="*" mode="section-header">
    <xsl:param name="heading-level"/>

    <xsl:variable name="html-heading">
        <xsl:apply-templates select="." mode="html-heading">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:element name="{$html-heading}">
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="self::chapter and ($numbering-maxlevel > 0)">
                    <xsl:text>heading</xsl:text>
                </xsl:when>
                <!-- hide "Chapter" when numbers are killed -->
                <xsl:otherwise>
                    <xsl:text>heading hide-type</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="header-content" />
    </xsl:element>
</xsl:template>

<!-- Add an author's names, if present   -->
<!-- TODO: make match more restrictive?  -->
<xsl:template match="&STRUCTURAL;" mode="author-byline">
    <xsl:if test="author">
        <p class="byline">
            <xsl:apply-templates select="author" mode="name-list"/>
        </p>
    </xsl:if>
</xsl:template>

<!-- The front and back matter have their own style -->
<xsl:template match="frontmatter|backmatter" mode="section-header" />

<!-- A book or article is the top level, so the   -->
<!-- masthead might suffice, else an author can   -->
<!-- provide a frontmatter/titlepage to provide   -->
<!-- more specific information.  In either event, -->
<!-- a typical section header is out of place.    -->
<!-- NB: this is copied verbatim for Braille      -->
<xsl:template match="book|article" mode="section-header" />

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- Both environments and sections have a "type,"         -->
<!-- a "codenumber," and a "title."  We format these       -->
<!-- consistently here with a modal template.  We can hide -->
<!-- components with classes on the enclosing "heading"    -->
<!-- NB: this is overridden in the conversion to Braille,  -->
<!-- to center chapter numbers above titles (and appendix, -->
<!-- preface, etc), so coordinate with those templates.    -->
<xsl:template match="*" mode="header-content">
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
    </span>
    <xsl:text> </xsl:text>
    <span class="codenumber">
        <xsl:apply-templates select="." mode="number" />
    </span>
    <xsl:text> </xsl:text>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
</xsl:template>

<!-- Exercises, Solutions, References, Worksheets -->
<!-- We give them a localized "type" computed from     -->
<!-- their level. Numbers are displayed for structured -->
<!-- divisions, but not for unstructured divisions.    -->
<xsl:template match="exercises|solutions|glossary|references|worksheet|reading-questions" mode="header-content">
    <span class="type">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id">
                <xsl:value-of select="local-name(.)" />
            </xsl:with-param>
        </xsl:call-template>
    </span>
    <xsl:text> </xsl:text>
    <!-- be selective about showing numbers -->
    <xsl:variable name="is-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:variable name="b-is-structured" select="$is-structured = 'true'"/>
    <span class="codenumber">
        <xsl:choose>
            <xsl:when test="self::references[parent::backmatter]"/>
            <xsl:when test="self::glossary[parent::backmatter]"/>
            <xsl:when test="$b-is-structured or self::solutions[parent::backmatter]">
                <xsl:apply-templates select="." mode="number" />
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </span>
    <xsl:text> </xsl:text>
    <span class="title">
        <xsl:apply-templates select="." mode="title-full" />
    </span>
    <!-- Links to the "printable" version(s), meant only for "viewable" -->
    <!-- worksheet, so CSS can kill on the "printable" versions         -->
    <xsl:if test="self::worksheet">
        <xsl:variable name="letter">
            <xsl:apply-templates select="." mode="standalone-filename-letter"/>
        </xsl:variable>
        <xsl:variable name="A4">
            <xsl:apply-templates select="." mode="standalone-filename-A4"/>
        </xsl:variable>
        <div class="print-links">
            <a href="{$A4}" class="a4">A4</a>
            <a href="{$letter}" class="us">US</a>
        </div>
    </xsl:if>
</xsl:template>

<!-- Recursively finds enclosing structural node -->
<!-- and reports if it has an xml:id on it       -->
<!-- Note: from mode="containing-filename", can we return a node-set? -->
<xsl:template match="*" mode="has-id-on-enclosure">
    <xsl:variable name="intermediate"><xsl:apply-templates select="." mode="is-intermediate" /></xsl:variable>
    <xsl:variable name="chunk"><xsl:apply-templates select="." mode="is-chunk" /></xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <!-- found it, is there an xml:id? -->
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="has-id-on-enclosure" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ####################### -->
<!-- Front Matter Components -->
<!-- ####################### -->

<!-- Title Page -->
<!-- A frontmatter has no title, so we reproduce the       -->
<!-- title of the work (book or article) here              -->
<!-- NB: this could done with a "section-header" template? -->
<!-- Other divisions (eg, colophon, preface) will follow   -->
<!-- This is all within a .frontmatter class for CSS       -->
<!-- NB: this is redefined with the same @match in the     -->
<!-- Braille conversion, so keep these in-sync             -->
<xsl:template match="titlepage">
    <xsl:variable name="b-has-subtitle" select="parent::frontmatter/parent::*/subtitle"/>
    <h2 class="heading">
        <span class="title">
            <xsl:apply-templates select="parent::frontmatter/parent::*" mode="title-full" />
            <xsl:if test="$b-has-subtitle">
                <xsl:text>:</xsl:text>
            </xsl:if>
        </span>
        <xsl:if test="$b-has-subtitle">
            <xsl:text> </xsl:text>
            <span class="subtitle">
                <xsl:apply-templates select="parent::frontmatter/parent::*" mode="subtitle" />
            </span>
        </xsl:if>
    </h2>
    <!-- We list authors and editors in document order -->
    <xsl:apply-templates select="author|editor" mode="full-info"/>
    <!-- A credit is subsidiary, so follows -->
    <xsl:apply-templates select="credit" />
    <xsl:apply-templates select="date" />
</xsl:template>

<!-- A "credit" required "title" followed by an author (or several)    -->
<!-- CSS should give lesser prominence to these (versus "full" author) -->
<xsl:template match="titlepage/credit">
    <div class="credit">
        <div class="title">
            <xsl:apply-templates select="." mode="title-full"/>
        </div>
        <xsl:apply-templates select="author" mode="full-info" />
    </div>
</xsl:template>

<!-- The time element has content that is "human readable" time -->
<xsl:template match="titlepage/date">
    <div class="date">
        <xsl:apply-templates />
    </div>
</xsl:template>

<!-- Authors, Editors, Creditors -->

<!-- Authors and editors with affiliations (eg, on title page) -->
<!-- CSS does not distinguish authors from editors             -->
<xsl:template match="author|editor" mode="full-info">
    <div class="author">
        <div class="author-name">
            <xsl:apply-templates select="personname" />
            <xsl:if test="self::editor">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="." mode="type-name" />
            </xsl:if>
        </div>
        <div class="author-info">
            <xsl:if test="department">
                <xsl:apply-templates select="department" />
                <xsl:if test="department/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
            <xsl:if test="institution">
                <xsl:apply-templates select="institution" />
                <xsl:if test="institution/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
            <xsl:if test="email">
                <xsl:apply-templates select="email" />
                <xsl:if test="email/following-sibling::*">
                    <br />
                </xsl:if>
            </xsl:if>
        </div>
    </div>
</xsl:template>

<!-- Departments and Institutions are free-form, or sequences of lines -->
<xsl:template match="department|institution">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="department[line]|institution[line]">
    <xsl:apply-templates select="line" />
</xsl:template>

<!-- Front Colophon -->
<!-- Licenses, ISBN, Cover Designer, etc -->
<!-- We process pieces, in document order -->
<!-- TODO: edition, publisher, production notes, cover design, etc -->
<!-- TODO: revision control commit hash -->
<xsl:template match="frontmatter/colophon/credit">
    <p class="credit">
        <b class="title">
            <xsl:apply-templates select="role" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="entity"/>
    </p>
</xsl:template>

<xsl:template match="frontmatter/colophon/edition">
    <p class="credit">
        <b class="title">
            <xsl:apply-templates select="." mode="type-name" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:apply-templates />
    </p>
</xsl:template>

<!-- website for the book -->
<xsl:template match="frontmatter/colophon/website">
    <p class="credit">
        <b class="title">
            <xsl:apply-templates select="." mode="type-name" />
        </b>
        <xsl:text> </xsl:text>
        <xsl:variable name="web-address">
            <xsl:apply-templates select="address" />
        </xsl:variable>
        <a href="{$web-address}">
            <xsl:apply-templates select="name" />
        </a>
    </p>
</xsl:template>

<xsl:template match="frontmatter/colophon/copyright">
    <p class="copyright">
        <xsl:call-template name="copyright-character"/>
        <xsl:apply-templates select="year" />
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="holder" />
    </p>
    <xsl:if test="shortlicense">
        <p class="license">
            <xsl:apply-templates select="shortlicense" />
        </p>
    </xsl:if>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Simple containers, allowed before and after           -->
<!-- explicit subdivisions, to introduce or summarize      -->
<!-- Title optional, typically just a few paragraphs       -->
<!-- Also occur in "smaller" units (elsewhere), so the     -->
<!-- HTML element varies from a "section" to an "article"  -->

<!-- Not knowlable as a component of bigger things, a      -->
<!-- pure container.  This is the component of a division. -->
<!-- Tunnel the duplication flag, drop id if duplicate     -->
<xsl:template match="introduction[parent::*[&STRUCTURAL-FILTER;]]|conclusion[parent::*[&STRUCTURAL-FILTER;]]">
    <xsl:param name="b-original" select="true()" />
    <section>
        <!-- cheap, but it works -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
        </xsl:attribute>
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="html-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="title">
            <h6 class="heading">
                <xsl:apply-templates select="." mode="title-full" />
                <span> </span>
            </h6>
        </xsl:if>
        <xsl:apply-templates>
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </section>
</xsl:template>

<!-- ####################### -->
<!-- Back Matter Components -->
<!-- ####################### -->

<!-- Back Colophon -->
<!-- Nothing special, so just process similarly to front -->

<!--               -->
<!-- Notation List -->
<!--               -->

<!-- At actual location, we do nothing since  -->
<!-- the cross-reference will always be a     -->
<!-- knowl to the containing structure        -->
<xsl:template match="notation" />

<!-- Build the table infrastructure, then    -->
<!-- populate with all the notation entries, -->
<!-- in order of appearance                  -->
<xsl:template match="notation-list">
    <table class="notation-list">
        <tr>
            <th>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'symbol'" />
                </xsl:call-template>
            </th>
            <th>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'description'" />
                </xsl:call-template>
            </th>
            <th>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'location'" />
                </xsl:call-template>
            </th>
        </tr>
        <xsl:apply-templates select="$document-root//notation" mode="backmatter" />
    </table>
</xsl:template>

<!-- Process *exactly* one "m" element             -->
<!-- Duplicate the provided description            -->
<!-- Create a cross-reference to enclosing content -->
<xsl:template match="notation" mode="backmatter">
    <tr>
        <td>
            <xsl:apply-templates select="usage/m[1]"/>
        </td>
        <td>
            <xsl:apply-templates select="description" />
        </td>
        <td>
            <xsl:apply-templates select="." mode="enclosure-xref" />
        </td>
    </tr>
</xsl:template>

<!-- Experimental: maybe belongs in -common -->
<!-- Not -md, know where the link lives     -->
<xsl:template match="*" mode="enclosure-xref">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="." mode="is-block" />
    </xsl:variable>
    <xsl:choose>
        <!-- found a structural or block parent -->
        <!-- we fashion a cross-reference link  -->
        <!-- TODO: xref-link's select is a fiction, maybe lead to bugs? -->
        <xsl:when test="$structural='true' or $block='true'">
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="." />
                <xsl:with-param name="content">
                    <xsl:apply-templates select="." mode="type-name" />
                    <xsl:variable name="enclosure-number">
                        <xsl:apply-templates select="." mode="number" />
                    </xsl:variable>
                    <xsl:if test="not($enclosure-number = '')">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$enclosure-number" />
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
            <!-- When we make knowl content selectively, we may    -->
            <!-- need to produce the content for the notation link -->
            <xsl:if test="$b-knowls-new">
                <xsl:variable name="is-knowl">
                    <xsl:apply-templates select="." mode="xref-as-knowl"/>
                </xsl:variable>
                <xsl:if test="$is-knowl = 'true'">
                    <xsl:apply-templates select="." mode="xref-knowl"/>
                </xsl:if>
            </xsl:if>
        </xsl:when>
        <!-- nothing interesting here, so step up a level -->
        <!-- Eventually we find the top-level structure   -->
        <!-- eg article, book, etc                        -->
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosure-xref" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ####################################### -->
<!-- Solutions Divisions, Content Generation -->
<!-- ####################################### -->

<!-- "book" and "article" need to be in the match so this template  -->
<!-- is defined for those top-level (whole document) cases, even if -->
<!-- $b-has-heading will always be "false" in these situations.     -->
<xsl:template match="book|article|part|chapter|section|subsection|subsubsection|exercises|worksheet|reading-questions" mode="division-in-solutions">
    <xsl:param name="scope" /> <!-- ignored -->
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-heading"/>
    <xsl:param name="content" />

    <!-- Usually we create an automatic heading, -->
    <!-- but not at the root division            -->
    <xsl:choose>
        <xsl:when test="$b-has-heading">
            <!-- as a duplicate of generated content, no HTML id -->
            <section class="{local-name(.)}">
                <xsl:apply-templates select="." mode="section-header">
                    <xsl:with-param name="heading-level" select="$heading-level"/>
                </xsl:apply-templates>
                <!-- we don't do an "author-byline" here in duplication -->
                <xsl:copy-of select="$content" />
            </section>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy-of select="$content" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- See general routine in  xsl/pretext-common.xsl -->
<!-- which expects the two named templates and the  -->
<!-- two division'al and element'al templates below,  -->
<!-- it contains the logic of constructing such a list -->

<!-- List-of entry/exit hooks -->
<!-- No ops for HTML          -->
<xsl:template name="list-of-begin" />
<xsl:template name="list-of-end" />

<!-- Subdivision headings in list-of's -->
<!-- Amalgamation of "section-header" and "header-content" -->
<!--   (1) No author credit                                -->
<!--   (2) No permalink                                    -->
<!-- TODO: maybe a stock template could do a better job with this? -->
<xsl:template match="*" mode="list-of-header">
    <xsl:param name="heading-level"/>

    <xsl:variable name="heading-level">
        <xsl:apply-templates select="." mode="html-heading">
            <xsl:with-param name="heading-level" select="$heading-level"/>
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:element name="{$heading-level}">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <xsl:text> </xsl:text>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="number" />
        </span>
        <xsl:text> </xsl:text>
        <span class="title">
            <xsl:apply-templates select="." mode="title-full" />
        </span>
    </xsl:element>
</xsl:template>

<!-- Entries in list-of's -->
<!-- Partly borrowed from common routines -->
<!-- TODO: CSS styling of the div forcing the knowl to open in the right place -->
<!-- And spacing should be done with .type, .codenumber, .title                -->
<xsl:template match="*" mode="list-of-element">
    <!-- Name and number as a knowl/link, div to open against -->
    <!-- TODO: xref-link's select is a fiction, maybe lead to bugs? -->
    <div>
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
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-xref"/>
    </div>
    <!-- When we make knowl content selectively, we may   -->
    <!-- need to produce the content for a "list-of" link -->
    <xsl:if test="$b-knowls-new">
        <xsl:variable name="is-knowl">
            <xsl:apply-templates select="." mode="xref-as-knowl"/>
        </xsl:variable>
        <xsl:if test="$is-knowl = 'true'">
            <xsl:apply-templates select="." mode="xref-knowl"/>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- ################ -->
<!-- Contributor List -->
<!-- ################ -->

<!-- Not much happening here, will drop -->
<!-- into environment manufacture       -->
<xsl:template match="contributors">
    <xsl:apply-templates select="contributor" />
</xsl:template>

<!-- ######## -->
<!-- Glossary -->
<!-- ######## -->

<!-- A glossary has an introduction and conclusion, then -->
<!-- "defined-term" inside a "term" element. Here we     -->
<!-- implement a basic definition for "term", but this   -->
<!-- could be the place to get fancy and segment the     -->
<!-- entries with spacing by letter, or similar.         -->
<xsl:template match="glossary/terms">
    <dl class="glossary">
        <xsl:apply-templates select="defined-term"/>
    </dl>
</xsl:template>

<!-- ############## -->
<!-- Index Creation -->
<!-- ############## -->

<!-- Used at the end of the next template to group index       -->
<!-- entries by letter for eventual output organized by letter -->
<xsl:key name="index-entry-by-letter" match="index" use="@letter"/>

<!-- "index-list":                                           -->
<!--     build a sorted list of every "index" in text        -->
<!--     use Muenchian Method to group by letter and process -->
<!-- "group-by-heading":                                     -->
<!--     consolidate/accumulate entries with common heading  -->
<!-- "knowl-list":                                           -->
<!--     output the locators, see, see also                  -->
<xsl:template match="index-list">
    <!-- Save-off the "index-list" as context for placement  -->
    <!-- of eventual xref/cross-references, since we use a   -->
    <!-- for-each and context changes.  Not strictly         -->
    <!-- necessary, but correct.                             -->
    <xsl:variable name="the-index-list" select="."/>
    <!-- "idx" as mixed content (replaces "index").          -->
    <!-- Or, "idx" structured with up to three "h"           -->
    <!-- (replaces index/[main,sub,sub]).                    -->
    <!-- Start attribute is actual end of a "page            -->
    <!-- range", goodies at @finish.                         -->
    <!-- "commentary" is elective, so process, or not        -->
    <!-- NB: latter half of @select is deprecated usage      -->
    <!-- new style is index/index-list for the division,     -->
    <!-- we don't want that picked up in the deprecated      -->
    <!-- "index" used for the entries                        -->

    <!-- "index-items" is an internal structure, so very     -->
    <!-- predictable.  Looks like:                           -->
    <!--                                                     -->
    <!-- text/key: always three pairs, some may be empty.    -->
    <!-- "text" is author's heading and will be output at    -->
    <!-- the end, "key" is a sanitized version for sorting,  -->
    <!-- and could be an entire replacement if the @sortby   -->
    <!-- attribute is used.                                  -->
    <!--                                                     -->
    <!-- locator-type: used to identify a "traditional" page -->
    <!-- locator which points back to a place in the text,   -->
    <!-- versus a "see" or "see also" entry.  Only used for  -->
    <!-- sorting, and really only used to be sure a "see"    -->
    <!-- *follows* the page locator.                         -->
    <xsl:variable name="index-items">
        <xsl:for-each select="$document-root//idx[not(@start) and (not(ancestor::commentary) or $b-commentary)] | //index[not(index-list) and not(@start) and (not(ancestor::commentary) or $b-commentary)]">
            <index>
                <!-- identify content of primary sort key      -->
                <!-- this follows the logic of creating key[1] -->
                <!-- TODO: this may be too ad-hoc, study       -->
                <!--       closely on a refactor               -->
                <xsl:variable name="letter-content">
                    <xsl:choose>
                        <xsl:when test="@sortby">
                            <xsl:value-of select="@sortby" />
                        </xsl:when>
                        <xsl:when test="not(main) and not(h)">
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:when test="(main or h) and (main/@sortby or h[1]/@sortby)">
                            <xsl:apply-templates select="main/@sortby|h[1]/@sortby"/>
                        </xsl:when>
                        <xsl:when test="main or h">
                            <xsl:apply-templates select="main|h[1]"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <!-- lowercase first letter of primary sort key    -->
                <!-- used later to group items by letter in output -->
                <xsl:attribute name="letter">
                    <xsl:value-of select="translate(substring($letter-content,1,1), &UPPERCASE;, &LOWERCASE;)"/>
                </xsl:attribute>
                <xsl:choose>
                    <!-- simple mixed-content first, no structure -->
                    <!-- one text-key pair, two more empty        -->
                    <!-- "main" as indicator is deprecated        -->
                    <xsl:when test="not(main) and not(h)">
                        <xsl:variable name="content">
                            <xsl:apply-templates/>
                        </xsl:variable>
                        <!-- text, key-value for single index heading -->
                        <text>
                            <xsl:copy-of select="$content" />
                        </text>
                        <key>
                            <xsl:choose>
                                <xsl:when test="@sortby">
                                    <xsl:value-of select="translate(@sortby, &UPPERCASE;, &LOWERCASE;)" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </key>
                        <!-- plus two more empty text, key pairs -->
                        <text/><key/>
                        <text/><key/>
                    </xsl:when>
                    <!-- structured index entry, multiple text-key pairs -->
                    <!-- "main" as indicator is deprecated               -->
                    <xsl:when test="main or h">
                        <!-- "h" occur in order, main-sub-sub deprecated -->
                        <xsl:for-each select="main|sub|h">
                            <xsl:variable name="content">
                                <xsl:apply-templates/>
                            </xsl:variable>
                            <text>
                                <xsl:copy-of select="$content" />
                            </text>
                            <key>
                                <xsl:choose>
                                    <xsl:when test="@sortby">
                                        <xsl:value-of select="translate(@sortby, &UPPERCASE;, &LOWERCASE;)" />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="translate($content, &UPPERCASE;, &LOWERCASE;)" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </key>
                        </xsl:for-each>
                        <!-- add additional empty text, key pairs -->
                        <!-- so there are always three            -->
                        <xsl:if test="(count(h) = 1) or (count(h) = 2)">
                            <text/><key/>
                        </xsl:if>
                        <xsl:if test="count(h) = 1">
                            <text/><key/>
                        </xsl:if>
                        <xsl:if test="(main and not(sub[1]))">
                            <text/><key/>
                        </xsl:if>
                        <xsl:if test="(main and not(sub[2]))">
                            <text/><key/>
                        </xsl:if>
                        <!-- final sort key will prioritize  -->
                        <!-- this mimics LaTeX's ordering    -->
                        <!--   0 - has "see also"            -->
                        <!--   1 - has "see"                 -->
                        <!--   2 - is usual index reference  -->
                        <xsl:if test="not(following-sibling::*[self::sub]) and not(following-sibling::*[self::h])">
                            <locator-type>
                                <xsl:choose>
                                    <xsl:when test="seealso">
                                        <xsl:text>2</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="see">
                                        <xsl:text>1</xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>0</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </locator-type>
                        </xsl:if>
                    </xsl:when>
                </xsl:choose>
                <!-- Create the full locator and save now, since context will -->
                <!-- be lost later.  Save a page locator in "cross-reference" -->
                <!-- element.  We use the context of the index itself as the  -->
                <!-- location where the cross-reference is placed.  The       -->
                <!-- location of the "idx" is the start of a search for the   -->
                <!-- enclosing element.  See and "see also" take precedence.  -->
                <xsl:choose>
                    <xsl:when test="see">
                        <see>
                            <xsl:apply-templates select="see"/>
                        </see>
                    </xsl:when>
                    <xsl:when test="seealso">
                        <seealso>
                            <xsl:apply-templates select="seealso"/>
                        </seealso>
                    </xsl:when>
                    <xsl:otherwise>
                        <cross-reference>
                            <xsl:apply-templates select="$the-index-list" mode="index-enclosure">
                                <xsl:with-param name="enclosure" select="."/>
                            </xsl:apply-templates>
                        </cross-reference>
                    </xsl:otherwise>
                </xsl:choose>
            </index>
        </xsl:for-each>
    </xsl:variable>
    <!-- Sort, now that info from document tree ordering is recorded     -->
    <!-- Keys, normalized to lowercase, or @sortby attributes, are the   -->
    <!-- primary key for sorting, but if we have index entries that just -->
    <!-- differ by upper- or lower-case distinctions, we need to have    -->
    <!-- identical variants sort next to each other so they get grouped  -->
    <!-- as one entry with multiple cross-references, so we sort         -->
    <!-- secondarily on the actual text as well.  The page locators were -->
    <!-- built in document order and so should remain that way after the -->
    <!-- sort and so be output in order of appearance.                   -->
    <xsl:variable name="sorted-index">
        <xsl:for-each select="exsl:node-set($index-items)/*">
            <xsl:sort select="./key[1]" />
            <xsl:sort select="./text[1]"/>
            <xsl:sort select="./key[2]" />
            <xsl:sort select="./text[2]"/>
            <xsl:sort select="./key[3]" />
            <xsl:sort select="./text[3]"/>
            <xsl:sort select="./locator-type" />
            <xsl:sort select="./see"/>
            <xsl:sort select="./seealso"/>
            <xsl:copy-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- Group by Letter -->
    <!-- A careful exposition of the Muenchian Method, named after Steve Muench  -->
    <!-- of Oracle.  This is an well-known, but complicated, XSLT 1.0 technique. -->
    <!-- (This is much easier in XSLT 2.0 with certain instructions).  We follow -->
    <!-- the XSLT Cookbook 2.0, Recipe 6.2, modulo one critical typo, and also   -->
    <!-- Jeni Tennison's instructive  "Grouping Using the Muenchian Method" at   -->
    <!-- http://www.jenitennison.com/xslt/grouping/muenchian.html.               -->
    <!--                                                                         -->
    <!-- Initial "for-each" sieves out a single (the first) representative of    -->
    <!-- each group of "index" that have a common initial letter for their sort  -->
    <!-- criteria.  Each becomes the context node for the remainder.             -->
    <xsl:for-each select="exsl:node-set($sorted-index)/index[count(.|key('index-entry-by-letter', @letter)[1]) = 1]">
        <!-- save the key to use again in selecting the group -->
        <xsl:variable name="current-letter" select="@letter"/>
        <!-- collect all the "index" with the same initial letter as representative    -->
        <!-- this key is still perusing the nodes of $sorted-index as context document -->
        <xsl:variable name="letter-group" select="key('index-entry-by-letter', $current-letter)"/>
        <!-- wrap the group in a div, which will be used for presentation -->
        <div class="indexletter" id="indexletter-{$current-letter}">
            <!-- send to group-by-headings, which is vestigal -->
            <xsl:apply-templates select="$letter-group[1]" mode="group-by-heading">
                <xsl:with-param name="heading-group" select="/.." />
                <xsl:with-param name="letter-group" select="$letter-group" />
            </xsl:apply-templates>
        </div>
    </xsl:for-each>
</xsl:template>

<!-- Accumulate index entries with identical headings - their    -->
<!-- exact text, not anything related to the keys.  Quit         -->
<!-- accumulating when look-ahead shows next entry differs.      -->
<!-- Output the (3-part) heading and locators before restarting. -->
<!-- TODO: investigate reworking this via Muenchian Method       -->
<xsl:template match="index" mode="group-by-heading">
    <!-- Empty node list from parent of root node -->
    <xsl:param name="heading-group"/>
    <xsl:param name="letter-group"/>

    <!-- look ahead at next index entry -->
    <xsl:variable name="next-index" select="following-sibling::index[1]"/>
    <!-- check if context node is still in the letter-group -->
    <xsl:if test="count(.|$letter-group) = count($letter-group)">
        <xsl:variable name="new-heading-group" select="$heading-group|."/>
        <xsl:choose>
            <!-- same heading, accumulate and iterate -->
            <xsl:when test="($next-index/text[1] = ./text[1]) and ($next-index/text[2] = ./text[2]) and ($next-index/text[3] = ./text[3])">
                <xsl:apply-templates select="$next-index" mode="group-by-heading">
                    <xsl:with-param name="heading-group" select="$new-heading-group" />
                    <xsl:with-param name="letter-group" select="$letter-group"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- some text differs in next index entry, -->
            <!-- write and restart heading accumulation -->
            <xsl:otherwise>
                <xsl:call-template name="output-one-heading">
                    <xsl:with-param name="heading-group" select="$new-heading-group" />
                </xsl:call-template>
                <!-- restart grouping by heading, pass through letter-group -->
                <xsl:apply-templates select="$next-index" mode="group-by-heading">
                    <xsl:with-param name="heading-group" select="/.." />
                    <xsl:with-param name="letter-group" select="$letter-group"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Place the (possibly three) components of -->
<!-- the heading(s) into their proper divs.   -->
<!-- Do not duplicate prior components that   -->
<!-- match, do not write an empty heading.    -->
<xsl:template name="output-one-heading">
    <xsl:param name="heading-group" />

    <xsl:if test="$heading-group/see and $heading-group/cross-reference">
        <xsl:message>PTX:WARNING: an index entry should not have both a locator and a "see" reference.  Results may be unpredictable.  Perhaps you meant to employ a "seealso" reference?  Heading is: "<xsl:value-of select="text[1]"/>; <xsl:value-of select="text[2]"/>; <xsl:value-of select="text[3]"/>"</xsl:message>
    </xsl:if>
    <xsl:if test="$heading-group/seealso and not($heading-group/cross-reference)">
        <xsl:message>PTX:WARNING: an index entry should not have a "seealso" reference without also having a locator.  Results may be unpredictable.  Perhaps you meant to employ a "see" reference?  Heading is: "<xsl:value-of select="text[1]"/>; <xsl:value-of select="text[2]"/>; <xsl:value-of select="text[3]"/>"</xsl:message>
    </xsl:if>

    <xsl:variable name="pattern" select="$heading-group[1]" />
    <xsl:variable name="pred" select="$pattern/preceding-sibling::index[1]" />
    <!-- booleans for analysis of format of heading, xrefs -->
    <xsl:variable name="match1" select="($pred/text[1] = $pattern/text[1]) and $pred" />
    <xsl:variable name="match2" select="($pred/text[2] = $pattern/text[2]) and $pred" />
    <xsl:variable name="match3" select="($pred/text[3] = $pattern/text[3]) and $pred" />
    <xsl:variable name="empty2" select="boolean($pattern/text[2] = '')" />
    <xsl:variable name="empty3" select="boolean($pattern/text[3] = '')" />
    <!-- write an "indexitem", "subindexitem", "subsubindexitem" as     -->
    <!-- necessary to identify chnages in headings, without duplicating -->
    <!-- headings from prior entries. Add locators when texts go blank  -->
    <!--  -->
    <!-- first key differs from predecessor, or leads letter group -->
    <xsl:if test="not($match1)">
        <div class="indexitem">
            <xsl:copy-of select="$pattern/text[1]/node()" />
            <!-- next key is blank, hence done, so write xrefs        -->
            <!-- the next outermost tests will fail so no duplication -->
            <xsl:if test="$empty2">
                <xsl:call-template name="knowl-list">
                    <xsl:with-param name="heading-group" select="$heading-group" />
                </xsl:call-template>
            </xsl:if>
        </div>
    </xsl:if>
    <!-- second key is substantial, and mis-match is in   -->
    <!-- the second key, or first key (ie to to the left) -->
    <xsl:if test="not($empty2) and (not($match1) or not($match2))">
        <div class="subindexitem">
            <xsl:copy-of select="$pattern/text[2]/node()" />
            <!-- next key is blank, hence done, so write xrefs       -->
            <!-- the next outermost test will fail so no duplication -->
            <xsl:if test="$empty3">
                <xsl:call-template name="knowl-list">
                    <xsl:with-param name="heading-group" select="$heading-group" />
                </xsl:call-template>
            </xsl:if>
        </div>
    </xsl:if>
    <!-- third key is substantial, and mis-match is in the first   -->
    <!-- key, the second key, or the third key (ie to to the left) -->
    <xsl:if test="not($empty3) and (not($match1) or not($match2) or not($match3))">
        <div class="subsubindexitem">
            <xsl:copy-of select="$pattern/text[3]/node()" />
            <!-- last chance to write xref list -->
            <xsl:call-template name="knowl-list">
                <xsl:with-param name="heading-group" select="$heading-group" />
            </xsl:call-template>
        </div>
    </xsl:if>
</xsl:template>

<!-- Place all the locators into the div for -->
<!-- the final (sub)item in its own span.    -->

<!-- One-time, global variables provide index terms -->
<!-- Localization file should provide upper-case versions -->
<xsl:variable name="upper-see">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'see'" />
    </xsl:call-template>
</xsl:variable>

<xsl:variable name="lower-see">
    <xsl:variable name="upper">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'see'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="translate(substring($upper, 1, 1), &UPPERCASE;, &LOWERCASE;)"/>
    <xsl:value-of select="substring($upper, 2)"/>
</xsl:variable>

<xsl:variable name="upper-seealso">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'also'" />
    </xsl:call-template>
</xsl:variable>

<xsl:variable name="lower-seealso">
    <xsl:variable name="upper">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'also'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="translate(substring($upper, 1, 1), &UPPERCASE;, &LOWERCASE;)"/>
    <xsl:value-of select="substring($upper, 2)"/>
</xsl:variable>

<!-- Chicago Manual of Style, 15th edition, 18.14 - 18.22  -->
<!-- "see", following main entry, 18.16                    -->
<!--    Period after entry                                 -->
<!--    "See" capitalized (assumed from localization file) -->
<!--     multiple: alphabetical order, semicolon separator -->
<!-- "see", following a subentry, 18.17                    -->
<!--    Space after entry                                  -->
<!--    "see" lower case                                   -->
<!--    wrapped in parentheses                             -->
<!-- "see also", following main entry, 18.19               -->
<!--    Period after entry                                 -->
<!--    "See" capitalized (assumed from localization file) -->
<!--     multiple: alphabetical order, semicolon separator -->
<!-- "see", following a subentry, 18.19                    -->
<!--    Space after entry                                  -->
<!--    "see" lower case                                   -->
<!--    wrapped in parentheses                             -->
<!-- generic references, 18.22                             -->
<!--   TODO: use content of "see" and "seealso"            -->
<xsl:template name="knowl-list">
    <xsl:param name="heading-group" />

    <!-- Some formatting depends on presence of subentries -->
    <xsl:variable name="b-has-subentry" select="not(text[2] = '')"/>
    <!-- range through node-list, making cross-references -->
    <!-- Use a comma after the heading, then prefix each  -->
    <!-- cross-reference with a space as separators       -->
    <span class="indexknowl">
        <xsl:choose>
            <xsl:when test="$heading-group/see and not($b-has-subentry)">
                <xsl:text>. </xsl:text>
            </xsl:when>
            <!-- no punctuation, will earn parentheses -->
            <xsl:when test="$heading-group/see and $b-has-subentry">
                <xsl:text> </xsl:text>
            </xsl:when>
            <!-- cross-reference, w/ or w/out see also -->
            <xsl:otherwise>
                <xsl:text>,</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- course over the "index" in the group -->
        <xsl:for-each select="$heading-group">
            <xsl:choose>
                <!--  -->
                <xsl:when test="cross-reference">
                    <xsl:text> </xsl:text>
                    <xsl:copy-of select="cross-reference/node()"/>
                </xsl:when>
                <!--  -->
                <xsl:when test="see">
                    <span class="see">
                        <xsl:if test="position() = 1">
                            <xsl:if test="$b-has-subentry">
                                <xsl:text>(</xsl:text>
                            </xsl:if>
                            <em>
                                <xsl:choose>
                                    <xsl:when test="$b-has-subentry">
                                        <xsl:value-of select="$lower-see"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$upper-see"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </em>
                        </xsl:if>
                        <!-- just a space after "see", before first  -->
                        <!-- semi-colon before second and subsequent -->
                        <xsl:choose>
                            <xsl:when test="position() = 1">
                                <xsl:text> </xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>; </xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:copy-of select="see/node()" />
                        <xsl:if test="$b-has-subentry and (position() = last())">
                            <xsl:text>)</xsl:text>
                        </xsl:if>
                    </span>
                </xsl:when>
                <!--  -->
                <xsl:when test="seealso">
                    <xsl:if test="preceding-sibling::index[1]/cross-reference and not($b-has-subentry)">
                        <xsl:text>. </xsl:text>
                    </xsl:if>
                    <span class="seealso">
                        <xsl:choose>
                            <xsl:when test="preceding-sibling::index[1]/cross-reference">
                                <xsl:choose>
                                    <xsl:when test="$b-has-subentry">
                                        <xsl:text> </xsl:text>
                                        <xsl:text>(</xsl:text>
                                        <em>
                                            <xsl:value-of select="$lower-seealso"/>
                                        </em>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <em>
                                            <xsl:value-of select="$upper-seealso"/>
                                        </em>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>;</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text> </xsl:text>
                        <xsl:copy-of select="seealso/node()"/>
                        <xsl:if test="(position() = last()) and $b-has-subentry">
                            <xsl:text>)</xsl:text>
                        </xsl:if>
                    </span>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </span>
</xsl:template>

<!-- Climb the tree looking for an enclosing structure of        -->
<!-- interest.  Create cross-reference.                          -->
<!-- One notable case: paragraph must be "top-level", just below -->
<!-- a structural document node                                  -->
<!-- Recursion always halts, since "mathbook" is structural      -->
<!-- TODO: save knowl or section link                            -->
<!-- We create content of "xref-knowl" if it is a block.         -->
<!-- TODO: identify index targets consistently in "make-efficient-knowls" -->
<!-- template, presumably parents of "idx" that are knowlable.            -->
<xsl:template match="index-list" mode="index-enclosure">
    <xsl:param name="enclosure"/>

    <xsl:variable name="structural">
        <xsl:apply-templates select="$enclosure" mode="is-structural"/>
    </xsl:variable>
    <xsl:variable name="block">
        <xsl:apply-templates select="$enclosure" mode="is-block"/>
    </xsl:variable>
    <xsl:choose>
        <!-- found a structural parent first           -->
        <!-- collect a url for a traditional hyperlink -->
        <xsl:when test="($structural = 'true') or ($block = 'true')">
            <xsl:apply-templates select="." mode="xref-link">
                <xsl:with-param name="target" select="$enclosure"/>
                <xsl:with-param name="content">
                    <xsl:apply-templates select="$enclosure" mode="type-name"/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:if test="$block = 'true'">
                <xsl:apply-templates select="$enclosure" mode="xref-knowl"/>
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <!-- Recurse.  The "index-list" gets passed along unchanged,     -->
            <!-- as the context for location of the eventual cross-reference -->
            <xsl:apply-templates select="." mode="index-enclosure">
                <xsl:with-param name="enclosure" select="$enclosure/parent::*"/>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################################### -->
<!-- Cross-Reference Knowls (xref-knowl) -->
<!-- ################################### -->

<!-- Many elements are candidates for cross-references     -->
<!-- and many of those are nicely implemented as knowls.   -->
<!-- We traverse the entire document tree with a modal     -->
<!-- "xref-knowl-old" template.  When it encounters an element -->
<!-- that needs a cross-reference target as a knowl file,  -->
<!-- that file is built and the tree traversal continues.  -->
<!--                                                       -->
<!-- See initiation in the entry template.                 -->

<!-- Cross-references as knowls                               -->
<!-- Override to turn off cross-references as knowls          -->
<!-- NB: this device makes it easy to turn off knowlification -->
<!-- entirely, since some renders cannot use knowl JavaScript -->
<xsl:template match="*" mode="xref-as-knowl">
    <xsl:value-of select="false()" />
</xsl:template>
<!-- As an elective enhancement, we only make a knowl of -->
<!-- the commentary if they are being displayed anyway,  -->
<!-- since we may not want the content to bleed through  -->
<!-- into a knowl posted publicly                        -->
<!-- TEMPORARY: var/li is a WeBWorK popup or radio button, -->
<!-- which is not a cross-reference target (it originates  -->
<!-- in PG-code), and an error results when the header in  -->
<!-- the knowl content tries to compute a number           -->
<xsl:template match="commentary" mode="xref-as-knowl">
    <xsl:value-of select="$b-commentary" />
</xsl:template>
<xsl:template match="fn|p|blockquote|biblio|biblio/note|defined-term|&DEFINITION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|task|&FIGURE-LIKE;|&THEOREM-LIKE;|proof|case|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&ASIDE-LIKE;|poem|assemblage|paragraphs|&GOAL-LIKE;|exercise|hint|answer|solution|exercisegroup|men|mrow|li[not(parent::var)]|contributor|fragment" mode="xref-as-knowl">
    <xsl:value-of select="true()" />
</xsl:template>

<!-- build xref-knowl, and optionally a hidden-knowl duplicate       -->
<!-- NB: "me" has all the necessary templates, but is never a target -->
<!-- mrow is only ever an "xref" knowl, and has enclosing content    -->
<!-- These are "top-level" starting places for this process,         -->
<!-- assuming divisions are never knowled                            -->
<!-- NB: when this leaves, search for two uses in code comments -->
<xsl:template match="*" mode="xref-knowl-old">
    <xsl:variable name="knowlizable">
        <xsl:apply-templates select="." mode="xref-as-knowl" />
    </xsl:variable>
    <xsl:if test="$knowlizable = 'true'">
        <!-- a generally available cross-reference knowl file, of duplicated content -->
        <xsl:apply-templates select="." mode="manufacture-knowl">
            <xsl:with-param name="knowl-type" select="'xref'" />
        </xsl:apply-templates>
        <!-- optionally, a file version of duplicated hidden-knowl content -->
        <xsl:variable name="hidden">
            <xsl:apply-templates select="." mode="is-hidden" />
        </xsl:variable>
        <xsl:if test="$hidden = 'true'">
            <xsl:apply-templates select="." mode="manufacture-knowl">
                <xsl:with-param name="knowl-type" select="'hidden'" />
            </xsl:apply-templates>
        </xsl:if>
    </xsl:if>
    <!-- recurse into contents, as we may just        -->
    <!-- "skip over" some containers, such as an "ol" -->
    <xsl:apply-templates select="*" mode="xref-knowl-old" />
</xsl:template>

<xsl:template match="*" mode="make-efficient-knowls">
    <xsl:variable name="xref-ids">
        <xsl:for-each select="$document-root//xref">
            <xsl:choose>
                <!-- ignore, no-op -->
                <xsl:when test="@provisional"/>
                <!-- just use @first, clean-up spaces -->
                <xsl:when test="@first and @last">
                    <xid>
                        <xsl:value-of select="normalize-space(@first)"/>
                    </xid>
                </xsl:when>
                <!-- a space-separated or comma-separated list -->
                <!-- to bust up and wrap many times in "xid"   -->
                <xsl:when test="@ref and (contains(normalize-space(@ref), ' ') or contains(@ref, ','))">
                    <xsl:variable name="clean-list" select="concat(normalize-space(translate(@ref, ',', ' ')), ' ')"/>
                    <xsl:call-template name="split-ref-list">
                        <xsl:with-param name="list" select="$clean-list"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- clean-up reference as a courtesy -->
                <xsl:when test="@ref">
                    <xid>
                        <xsl:value-of select="normalize-space(@ref)"/>
                    </xid>
                </xsl:when>
                <!-- could error-check here -->
                <xsl:otherwise/>
            </xsl:choose>
            <!-- TODO: cruise "idx" to get references to parents -->
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="id-nodes" select="exsl:node-set($xref-ids)"/>

    <!-- might work better if sorted first -->
    <xsl:variable name="unique-ids-rtf">
        <xsl:for-each select="$id-nodes/xid[not(. = preceding::*/.)]">
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="unique-ids" select="exsl:node-set($unique-ids-rtf)"/>

    <xsl:for-each select="$unique-ids/xid">
        <!-- context change coming, so save off the actual id string -->
        <xsl:variable name="the-id" select="."/>
        <!-- for-each only loops over one item, but changes context, -->
        <!-- so the id() function is checking against the right document -->
        <xsl:for-each select="$document-root">
            <xsl:variable name="target" select="id($the-id)"/>
            <xsl:variable name="is-knowl">
                <xsl:apply-templates select="$target" mode="xref-as-knowl"/>
            </xsl:variable>
            <xsl:if test="$is-knowl = 'true'">
                <xsl:apply-templates select="$target" mode="xref-knowl"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:for-each>
</xsl:template>

<!-- Decompose a string of references into elements for id  -->
<!-- rtf above.  Note: each token has a space following it  -->
<xsl:template name="split-ref-list">
    <xsl:param name="list"/>

    <xsl:choose>
        <!-- final space causes recursion with -->
        <!-- totally empty list, so halt       -->
        <xsl:when test="$list = ''"/>
        <xsl:otherwise>
            <xid>
                <xsl:value-of select="substring-before($list, ' ')"/>
            </xid>
            <xsl:call-template name="split-ref-list">
                <xsl:with-param name="list" select="substring-after($list, ' ')"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Context is an object that is the target of a cross-reference    -->
<!-- ("xref") and is known/checked to be implemented as a knowl.     -->
<!-- We cruise children for the necessity of hidden content which we -->
<!-- impersonate with a file knowl that looks like a hidden knowl.   -->
<xsl:template match="*" mode="xref-knowl">
    <xsl:apply-templates select="." mode="manufacture-knowl">
        <xsl:with-param name="knowl-type" select="'xref'"/>
    </xsl:apply-templates>
    <!-- Cruise children, note this is a context switch         -->
    <!-- Looking for born-hidden knowls in "xref" knowl content -->
    <xsl:for-each select=".//*">
        <xsl:variable name="hidden">
            <xsl:apply-templates select="." mode="is-hidden"/>
        </xsl:variable>
        <xsl:if test="$hidden = 'true'">
            <xsl:apply-templates select="." mode="manufacture-knowl">
                <xsl:with-param name="knowl-type" select="'hidden'"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- Build one, or two, files for knowl content -->
<xsl:template match="*" mode="manufacture-knowl">
    <xsl:param name="knowl-type" />
    <xsl:variable name="knowl-file">
        <xsl:choose>
            <xsl:when test="$knowl-type = 'xref'">
                <xsl:apply-templates select="." mode="xref-knowl-filename" />
            </xsl:when>
            <xsl:when test="$knowl-type = 'hidden'">
                <xsl:apply-templates select="." mode="hidden-knowl-filename" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- write file infrastructure first -->
    <exsl:document href="{$knowl-file}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <html lang="{$document-language}"> <!-- dir="rtl" here -->
            <!-- header since separate file -->
            <xsl:text>&#xa;</xsl:text>
            <xsl:call-template name="converter-blurb-html" />
            <head>
                <!-- dissuade indexing duplicated content -->
                <meta name="robots" content="noindex, nofollow" />
                <!-- we need Sage cell configuration functions     -->
                <!-- in the knowl file itself, the main Javascript -->
                <!-- is being placed on *every* page, if present   -->
                <!-- anywhere in the document, and that is         -->
                <!-- sufficient for the external knowl             -->
                <xsl:apply-templates select="." mode="sagecell" />
            </head>
            <body>
                <!-- content, in xref style or hidden style     -->
                <!-- initiate tunneling duplication flag here   -->
                <!-- We send a flag to the "body" template      -->
                <!-- indicating the call is at the outermost    -->
                <!-- level of the knowl being constructed,      -->
                <!-- rather than to manufacture a child element -->
                <!-- Usually this parameter is ignored          -->
                <!-- An xref to an mrow results in a knowl      -->
                <!-- whose content is more than just the xref,  -->
                <!-- it is the entire containing md or mdn      -->
                <xsl:choose>
                    <xsl:when test="$knowl-type = 'xref'">
                        <xsl:choose>
                            <xsl:when test="self::mrow">
                                <xsl:apply-templates select="parent::*" mode="body">
                                    <xsl:with-param name="block-type" select="'xref'" />
                                    <xsl:with-param name="b-original" select="false()" />
                                    <xsl:with-param name="b-top-level" select="true()" />
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="." mode="body">
                                    <xsl:with-param name="block-type" select="'xref'" />
                                    <xsl:with-param name="b-original" select="false()" />
                                    <xsl:with-param name="b-top-level" select="true()" />
                                </xsl:apply-templates>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$knowl-type = 'hidden'">
                        <xsl:apply-templates select="." mode="body">
                            <xsl:with-param name="block-type" select="'hidden'" />
                            <xsl:with-param name="b-original" select="false()" />
                            <xsl:with-param name="b-top-level" select="true()" />
                        </xsl:apply-templates>
                    </xsl:when>
                </xsl:choose>
                <!-- in-context link just for xref-knowl content -->
                <xsl:if test="$knowl-type = 'xref'">
                    <xsl:variable name="href">
                        <xsl:apply-templates select="." mode="url" />
                    </xsl:variable>
                    <span class="incontext">
                        <a href="{$href}">
                            <xsl:call-template name="type-name">
                                <xsl:with-param name="string-id" select="'incontext'" />
                            </xsl:call-template>
                        </a>
                    </span>
                </xsl:if>
            </body>
        </html>
    </exsl:document>  <!-- end file -->
</xsl:template>

<!-- The directory of knowls that are targets of cross-references    -->
<!-- The file extension is *.html so recognized as OK by Moodle, etc -->
<xsl:template match="*" mode="xref-knowl-filename">
    <xsl:text>./knowl/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>

<xsl:template match="*" mode="hidden-knowl-filename">
    <xsl:text>./knowl/</xsl:text>
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>-hidden.html</xsl:text>
</xsl:template>

<!-- ######## -->
<!-- Headings -->
<!-- ######## -->

<!-- Pretty much everything for actually manipluating titles -->
<!-- happens in the -common template. But when structured by -->
<!-- "line" we need to implement an abstract variable with a -->
<!-- separator string.  Since HTML (and EPUB, etc) are       -->
<!-- zoomable and reflowable, we just insert spaces and      -->
<!-- leave actual line-breaking to the laTeX conversion.     -->
<xsl:variable name="title-separator" select="' '"/>

<!-- This template manufactures HTML "headings", the "hN" elements.   -->
<!-- We do not style based on these elements, but a screen-reader     -->
<!-- or offline (no CSS) environment will use these profitably.       -->
<!-- So it is important for the elements to be in a logical           -->
<!-- progression corresponding to "section" and "article" nodes       -->
<!-- of the HTML tree.                                                -->
<!--                                                                  -->
<!-- We set the "heading-level" to "2" when chunking is initiated,    -->
<!-- since we expect the masthead/banner to contain an "h1".          -->
<!-- Whenever a template processes its children, we increment the     -->
<!-- variable as we pass it down, so a template receives the correct  -->
<!-- level (and before it ever gets here, since we have consciously   -->
<!-- chosen *not* to increment here).                                 -->
<!--                                                                  -->
<!-- There is no h7, so we need to just settle for h6, I guess.       -->
<!-- TODO: address h7 when "article" get careful headings             -->
<xsl:template match="*" mode="html-heading">
    <xsl:param name="heading-level"/>

    <!-- Debugging code, preserve temporarily, just for divisions now -->
    <!-- Turn on "CHUNK: and "INTER:" debugging in -common templates  -->
    <!-- <xsl:message> -->
        <!-- <xsl:text>  </xsl:text><xsl:value-of select="$heading-level"/> -->
        <!-- <xsl:text> : </xsl:text><xsl:value-of select="local-name(.)"/><xsl:text> : </xsl:text><xsl:apply-templates select="." mode="long-name"/> -->
    <!-- </xsl:message> -->

    <!-- simple -->
    <xsl:text>h</xsl:text>
    <xsl:choose>
        <xsl:when test="$heading-level &lt; 7">
            <xsl:value-of select="$heading-level"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- TODO: Report excessive heading here, as informational item           -->
            <!-- Perhaps include advice: chunk more, author with shallower divisions, -->
            <!-- use less comprehensive solutions nested at depth                     -->
            <xsl:text>6</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- These are convenience methods for frequently-used headings -->

<!-- h6, type name, number (if exists), title (if exists) -->
<!-- REMARK-LIKE, COMPUTATION-LIKE, DEFINITION-LIKE, SOLUTION-LIKE, objectives (xref-content), outcomes (xref-content), EXAMPLE-LIKE, PROJECT-LIKE, exercise (inline), task (xref-content), fn (xref-content), biblio/note (xref-content)-->
<!-- E.g. Corollary 4.1 (Leibniz, Newton).  The fundamental theorem of calculus. -->
<xsl:template match="*" mode="heading-full">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name"/>
        </span>
        <!--  -->
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number" />
        </xsl:variable>
        <xsl:if test="not($the-number='')">
            <xsl:call-template name="space-styled"/>
            <span class="codenumber">
                <xsl:value-of select="$the-number"/>
            </span>
        </xsl:if>
        <!--  -->
        <xsl:if test="creator and (&THEOREM-FILTER; or &AXIOM-FILTER;)">
            <xsl:call-template name="space-styled"/>
            <span class="creator">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates select="." mode="creator-full"/>
                <xsl:text>)</xsl:text>
            </span>
        </xsl:if>
        <!-- A period now, no matter which of 4 combinations we have above-->
        <xsl:call-template name="period-styled"/>
        <!-- A title carries its own punctuation -->
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full"/>
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<xsl:template match="figure|listing|table|list" mode="figure-caption">
    <xsl:param name="b-original"/>

    <xsl:variable name="b-subcaptioned" select="parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure"/>
    <figcaption>
        <!-- A normal caption, or a subcaption -->
        <xsl:choose>
            <xsl:when test="$b-subcaptioned">
                <span class="codenumber">
                    <xsl:apply-templates select="." mode="serial-number"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="type">
                    <xsl:apply-templates select="." mode="type-name"/>
                </span>
                <xsl:call-template name="space-styled"/>
                <span class="codenumber">
                    <xsl:apply-templates select="." mode="number"/>
                    <xsl:call-template name="period-styled"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="space-styled"/>
        <xsl:choose>
            <!-- a caption can have a footnote, hence a -->
            <!-- knowl, hence original or duplicate     -->
            <xsl:when test="self::figure or self::listing">
                <xsl:apply-templates select="." mode="caption-full">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="self::table or self::list">
                <xsl:apply-templates select="." mode="title-full"/>
            </xsl:when>
        </xsl:choose>
    </figcaption>
</xsl:template>


<!-- h6, no type name, full number, title (if exists)   -->
<!-- divisional exercise, principally for solution list -->
<xsl:template match="*" mode="heading-divisional-exercise">
    <h6 class="heading">
        <span class="codenumber">
            <xsl:apply-templates select="." mode="number" />
            <xsl:call-template name="period-styled"/>
        </span>
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- h6, no type name, serial number, title (if exists) -->
<!-- divisional exercise, principally when born         -->
<xsl:template match="*" mode="heading-divisional-exercise-serial">
    <h6 class="heading">
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:call-template name="period-styled"/>
        </span>
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- h6, type name, serial number, title (if exists) -->
<!-- exercise (divisional, xref-content)      -->
<xsl:template match="*" mode="heading-divisional-exercise-typed">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <xsl:call-template name="space-styled"/>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
            <xsl:call-template name="period-styled"/>
        </span>
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- h6, no type name, just simple list number, no title -->
<!-- task (when born) -->
<xsl:template match="*" mode="heading-list-number">
    <h6 class="heading">
        <span class="codenumber">
            <xsl:text>(</xsl:text>
            <xsl:apply-templates select="." mode="list-number" />
            <xsl:text>)</xsl:text>
        </span>
    </h6>
</xsl:template>

<!-- h6, type name, no number (even if exists), title (if exists)              -->
<!-- eg, objectives is one-per-subdivison, max, so no need to display at birth -->
<!-- NB: rather specific to "objectives" and "outcomes", careful               -->
<!-- objectives and outcomes (when born) -->
<xsl:template match="*" mode="heading-full-implicit-number">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
            <xsl:if test="title">
                <xsl:text>:</xsl:text>
            </xsl:if>
        </span>
        <!-- codenumber is implicit via placement -->
        <xsl:if test="title">
            <xsl:call-template name="space-styled"/>
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h6>
</xsl:template>

<!-- Not normally titled, but knowl content gives some indication -->
<!-- NB: no punctuation, intended only for xref knowl content     -->
<!-- blockquote, exercisegroup, defined term -->
<xsl:template match="*" mode="heading-type">
    <h6 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
    </h6>
</xsl:template>

<!-- A title or the type, with a period -->
<!-- proof is the only known case       -->
<xsl:template match="*" mode="heading-no-number">
    <h6 class="heading">
        <xsl:choose>
            <xsl:when test="title">
                <!-- comes with punctuation -->
                <span class="title">
                    <xsl:apply-templates select="." mode="title-full"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <!-- supply a period -->
                <span class="type">
                    <xsl:apply-templates select="." mode="type-name" />
                    <xsl:call-template name="period-styled"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </h6>
</xsl:template>

<!-- Title only -->
<!-- ASIDE-LIKE, exercisegroup, dl/li -->
<!-- proof, when optionally titled    -->
<!-- Subsidiary to paragraphs,        -->
<!-- and divisions of "exercises"     -->
<!-- No title, then nothing happens   -->
<xsl:template match="*" mode="heading-title">
    <xsl:if test="title/*|title/text()">
        <h6 class="heading">
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </h6>
    </xsl:if>
</xsl:template>

<!-- Title only, paragraphs, commentary   -->
<!-- h5 for paragraphs, lowest of the low -->
<!-- No title, then nothing happens       -->
<!-- TODO: titles will be mandatory sometime -->
<xsl:template match="*" mode="heading-title-paragraphs">
    <xsl:if test="title/*|title/text()">
        <h5 class="heading">
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </h5>
    </xsl:if>
</xsl:template>

<!-- A type, with maybe a serial number to disambiguate -->
<!-- No h6, optional title                              -->
<!-- SOLUTION-LIKE (xref-text), biblio/note (xref-text) -->
<xsl:template match="*" mode="heading-simple">
    <!-- the name of the object, its "type" -->
    <span class="type">
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>.</xsl:text>
    </span>
    <xsl:text> </xsl:text>
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="non-singleton-number" />
    </xsl:variable>
    <!-- An empty value means element is a singleton -->
    <!-- else the serial number comes through        -->
    <xsl:if test="not($the-number = '')">
        <xsl:call-template name="space-styled"/>
        <span class="codenumber">
            <xsl:apply-templates select="." mode="serial-number" />
        </span>
    </xsl:if>
    <xsl:if test="title">
        <xsl:call-template name="space-styled"/>
        <span class="title">
            <xsl:apply-templates select="." mode="title-full" />
        </span>
    </xsl:if>
</xsl:template>

<!-- A case in a proof, eg "(=>) Necessity." -->
<!-- case -->
<xsl:template match="*" mode="heading-case">
    <h6 class="heading">
        <xsl:choose>
            <!-- 'RIGHTWARDS DOUBLE ARROW' (U+21D2) -->
            <xsl:when test="@direction='forward'">
                <xsl:comment>Style arrows in CSS?</xsl:comment>
                <xsl:text>(&#x21d2;)&#xa0;</xsl:text>
            </xsl:when>
            <!-- 'LEFTWARDS DOUBLE ARROW' (U+21D0) -->
            <xsl:when test="@direction='backward'">
                <xsl:comment>Style arrows in CSS?</xsl:comment>
                <xsl:text>(&#x21d0;)&#xa0;</xsl:text>
            </xsl:when>
            <!-- DTD will catch wrong values -->
            <xsl:otherwise />
        </xsl:choose>
        <!-- If there is a title, the following will produce it. If -->
        <!-- no title, and we don't have a direction already, the   -->
        <!-- following will produce a default title, eg "Case."     -->
        <xsl:if test="boolean(title) or not(@direction)">
            <xsl:apply-templates select="." mode="title-full" />
        </xsl:if>
    </h6>
</xsl:template>

<!-- Heading Utilities -->

<!-- These two named templates create a space or a      -->
<!-- period with enough HTML markup to allow for hiding -->
<!-- them if some other part of a heading is hidden.    -->

<xsl:template name="space-styled">
    <span class="space">
        <xsl:text> </xsl:text>
    </span>
</xsl:template>

<xsl:template name="period-styled">
    <span class="period">
        <xsl:text>.</xsl:text>
    </span>
</xsl:template>


<!-- ######################## -->
<!-- Block Production, Knowls -->
<!-- ######################## -->

<!-- Generically, a "block" is a child of a "division."  See the schema for more precision.  Blocks also have significant components.  An "example" is a block, and its "solution" is a significant component.  A "p" might be a block, but it could also be a significant component of an "example." -->

<!-- Some blocks and components can be realized in a hidden fashion, as knowls whose content is embedded within the page.  This may be automatic (footnotes, "fn", are a good example), elective ("theorem" is a good example), or banned (a "blockquote" is never hidden). -->

<!-- All blocks, and many of their significant components, are available as targets of cross-references, implemented as knowls, but now the content resides in external files.  These files contain duplicates of blocks and their components (rather than originals), so need to be free of the unique identifiers that are used in the original versions. -->

<!-- This suggests four modes for the initial production of a block or component, though some blocks may only be produced in two of the four modes: visible and original, hidden and original, a cross-reference knowl, an external knowl duplicating a hidden knowl. -->
<!-- (a) Visible and original (on a main page) -->
<!-- (b) Hidden and original (embedded knowl on a page) -->
<!-- (c) Visible and duplicate (in, or as, a cross-reference knowl) -->
<!-- (d) Hidden and duplicate (an external knowl, duplicating the hidden original knowl) -->

<!-- The generic (not modal) template matches any element that is a block or a significant component of some other element that is a block or a component. -->

<!-- Every such element is only output in one of two forms, and as few times as possible.  One form is the "original" and includes full identifying information, such as an HTML id attribute or a LaTeX label for rows of display mathematics.  The other form is a "duplicate", as an external file, for use by the knowl code to open and display.  As a duplicate of the orginal, it should be free of all identifying information and should recycle other duplicates as much as possible. -->

<!-- An element arrives here in one of four situations, two as originals and two as duplicates.  We describe those situations and what should happen. -->

<!-- Original, born visible.  The obvious situation, we render the element as part of the page, adding identifying information.  The template sets the "b-original" flag to true by default, for this reason.  Children of the element are incorporated (through the modal body templates) as originals (visible and/or hidden) by passing along the "b-original" flag. -->

<!-- Original, born hidden.  The element knows if it should be hidden on the page in an embedded knowl via the modal "is-hidden" template.  So a link is written on the page, and the main content is written onto the page as a hidden, embedded knowl.  The "b-original" flag (set to true) is passed through to templates for the children. -->

<!-- Duplicates.  Duplicated versions, sans identification, are created by an extra, specialized, traversal of the entire document tree with the "xref-knowl-old" modal templates.  When an element is first encountered the infrastructure for an external file is constructed and the modal "body" template of the element is called with the "b-original" flag set to false.  The content of the knowl should have an overall header, explaining what it is, since it is a target of the cross-reference.  Now the body template will pass along the "b-original" flag set to false, indicating the production mode should be duplication.  For a block that is born hidden, we build an additional external knowl that duplicates it, so without identification, without an overall header, and without an in-context link.  -->

<!-- Child elements born visible will be written into knowl files without identification.  Child elements born hidden will write a knowl link into the page, pointing to the duplicated (hidden) version.  -->

<!-- The upshot is that the main pages have visible content and hidden, embedded content (knowls) with full identification as original canonical versions.  Cross-references open external file knowls, whose hidden components are again accessed via knowls that use external files of duplicated content.  None of the knowl files contain any identification, so these identifiers remain unique in their appearances as part of the main pages. -->

<!-- This process is controlled by the boolean "b-original" parameter, which needs to be laboriously passed down and through templates, including containers like "sidebyside."  The XSLT 2.0 tunnel parameter would be a huge advantage here.  The parameter "block-type" can take on the values: 'visible', 'embed', 'xref', 'hidden'.  The four situations above can be identified with these parameters.  The block-type parameter is also used to aid in placement of identification.  For example, an element born visible will have an HTML id on its outermost element, such as an "article".  But as an embedded knowl, we put the id onto the visible link text instead, even if the same outermost element is employed for the hidden content.  Also, the block-type parameter is tunneled down to the Sage cells so they can be constructed properly when inside of knowls. -->

<!-- The relevant templates controlling production of a block, and their use, are: -->

<!-- (1) "is-hidden":  mandatory, value is 'true' or 'false' (could move to a boolean), controls visible or hidden property, so usd in a variety of situations to control flow.  Often fixed, but also responds to options. (As boolean: do conditionals in global text variable, then check value in "select" of new global boolean variable.) -->

<!-- (2) "body-element", "body-css-class": useful for general production, but sometimes its employment leads to requiring exceptional templates (eg display math).  The outermost HTML element of a block.  Sometimes it gets an ID, sometimes not, which is its main purpose.  Employed in "body" templates (see below).  The "body-element" should always be a block element, since it will be the outer-level element for knowl content, which will (always) have blocks as content. -->

<!-- (3) "heading-birth": produces HTML immediately interior to the "body-element", for visible blocks, in both the original and duplication processes.  Similarly, it is the link-text of a knowl for a block that is hidden (again in original or duplication modes).  Employed in "body" templates. -->

<!-- (4) "hidden-knowl-placement": 'block' or 'inline' to indicate how to wrap hidden knowl links so they appear correctly on a page (block or inline, basically).  'block' means a wrapper with the class of the "body-element", while 'inline' means no wrapper is needed since the link is just fine in an inline situation.  Only relevant for an object which can be born hidden via a switch (e.g. a theorem), or is *always* born hidden (e.g. "fn" (footnote)).  So this template could be defined to produce no output and an error will be raised during processing if there is a mismatch (i.e. no ouput is a third possible value.  -->

<!-- (5) "heading-xref-knowl": when a knowl is a target of a cross-reference, sometimes a better heading is necessary to help identify it.  For example, a cross-refernce to a list item can be improved by providing the number of the item in a heading. -->

<!-- (6) "body": main template to produce the HTML "body" portion of a knowl, or the content displayed on a page.  Reacts to four modes: 'visible' (original or duplicate), 'embed', or 'xref'. -->

<!-- (7) TODO: "wrapped-content" called by "body" to separate code. -->

<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&DEFINITION-LIKE;|&ASIDE-LIKE;|poem|&FIGURE-LIKE;|assemblage|blockquote|paragraphs|commentary|&GOAL-LIKE;|&EXAMPLE-LIKE;|subexercises|exercisegroup|exercise|&PROJECT-LIKE;|task|&SOLUTION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|proof|case|fn|contributor|biblio|biblio/note|defined-term|p|li|me|men|md|mdn|fragment">
    <xsl:param name="b-original" select="true()" />
    <xsl:variable name="hidden">
        <xsl:apply-templates select="." mode="is-hidden" />
    </xsl:variable>
    <xsl:choose>
        <!-- born-hidden case -->
        <xsl:when test="$hidden = 'true'">
            <xsl:choose>
                <!-- primary occurrence, born hidden as embedded knowl     -->
                <!-- is original flag pass-thru necessary?  always true()? -->
                <xsl:when test="$b-original">
                    <xsl:apply-templates select="." mode="born-hidden">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- duplicating, so just make a xref-knowl in same style, -->
                <!-- but therefore clean of id's or other identification   -->
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="duplicate-born-hidden">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- born-visible case -->
        <xsl:otherwise>
            <!-- pass-thru of b-original mandatory -->
            <xsl:apply-templates select="." mode="born-visible">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="born-visible">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="." mode="body">
        <xsl:with-param name="block-type" select="'visible'" />
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="born-hidden">
    <xsl:param name="b-original" select="true()" />
    <xsl:variable name="placement">
        <xsl:apply-templates select="." mode="hidden-knowl-placement" />
    </xsl:variable>
    <!-- First: the link that is visible on the page         -->
    <xsl:choose>
        <xsl:when test="$placement = 'block'">
            <xsl:variable name="body-elt">
                <xsl:apply-templates select="." mode="body-element" />
            </xsl:variable>
            <xsl:element name="{$body-elt}">
                <xsl:attribute name="class">
                    <xsl:apply-templates select="." mode="body-css-class" />
                </xsl:attribute>
                <!-- HTML id is best on element surrounding born-hidden knowl anchor -->
                <xsl:attribute name="id">
                    <xsl:apply-templates select="." mode="html-id" />
                </xsl:attribute>
                <xsl:apply-templates select="." mode="hidden-knowl-link">
                    <xsl:with-param name="placement" select="$placement"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:when>
        <xsl:when test="$placement = 'inline'">
            <xsl:apply-templates select="." mode="hidden-knowl-link">
                <xsl:with-param name="placement" select="$placement"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG:     an object ("<xsl:value-of select="local-name(.)" />") being born hidden as a knowl does not know if the link is a block or is inline.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Second: the content of the knowl, to be revealed/parsed later -->
    <!-- Exception: born-hidden content is always in a "div", so an    -->
    <!-- intra-paragraph knowl (e.g. a footnote) needs to be placed    -->
    <!-- outside of HTML structures (e.g. a "p"), so we skip it here.  -->
    <!-- But see "pop-footnote-text" modal template.                   -->
    <xsl:apply-templates select="self::*[not(self::fn)]" mode="hidden-knowl-content">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- We need to relocate the hidden knowls for footnotes, since they live  -->
<!-- in a "div" for the knowl mechanism, but are typically placed inside   -->
<!-- HTML elements that do not allow div's as children (e.g. "p").  In     -->
<!-- order to not pop prematurely, we look to ancestors that may also need -->
<!-- this treatment.  So these elements are *any* element that could have  -->
<!-- an "fn" buried down at some (arbitrary) level.                        -->
<!--                                                                       -->
<!-- Every element match'ed here should have a call to pop the footnote    -->
<!-- text, *outside* of the creation of its outermost element, typically   -->
<!-- afterwards.                                                           -->
<!--                                                                       -->
<!-- Footnote text only needs to be relocated when the surrounding element -->
<!-- is the original version, for duplicates, a born-hidden knowl within   -->
<!-- is impersonated with knowl content located in an external file.  So   -->
<!-- this template is a no-op for duplicates.                              -->

<xsl:template match="p|figure|table|listing|tabular|ol|ul|dl" mode="pop-footnote-text">
    <xsl:param name="b-original"/>

    <xsl:if test="$b-original">
        <xsl:if test="count(ancestor::*[self::p|self::figure|self::table|self::listing|self::tabular|self::ol|self::ul|self::dl]) = 0">
            <xsl:for-each select=".//fn">
                <xsl:apply-templates select="."  mode="hidden-knowl-content">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- An external file knowl, impersonating a hidden knowl -->
<xsl:template match="*" mode="duplicate-born-hidden">
    <xsl:param name="b-original" select="false()" />
    <xsl:variable name="placement">
        <xsl:apply-templates select="." mode="hidden-knowl-placement" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$placement = 'block'">
            <xsl:variable name="body-elt">
                <xsl:apply-templates select="." mode="body-element" />
            </xsl:variable>
            <xsl:element name="{$body-elt}">
                <xsl:attribute name="class">
                    <xsl:apply-templates select="." mode="body-css-class" />
                </xsl:attribute>
                <xsl:apply-templates select="." mode="duplicate-hidden-knowl-link" />
            </xsl:element>
        </xsl:when>
        <xsl:when test="$placement = 'inline'">
            <xsl:apply-templates select="." mode="duplicate-hidden-knowl-link" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:BUG:     an object ("<xsl:value-of select="local-name(.)" />") being born hidden as a knowl does not know if the link is a block or is inline.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Hidden knowls are in two pieces.  This template -->
<!-- ensures consistency of the common, linking id.  -->
<xsl:template match="*" mode="hidden-knowl-id">
    <xsl:text>hk-</xsl:text>  <!-- "hidden-knowl" -->
    <xsl:apply-templates select="." mode="html-id" />
</xsl:template>

<!-- The link portion of a hidden-knowl -->
<xsl:template match="*" mode="hidden-knowl-link">
    <xsl:param name="placement"/>

    <xsl:element name="a">
        <!-- empty, indicates content *not* in a file -->
        <xsl:attribute name="data-knowl" />
        <!-- id-ref class: content is in div referenced by id       -->
        <!-- (element-name)-knowl: specific element used in content -->
        <!-- original: born hidden knowl, not xref                  -->
        <!-- Similar to "duplicate-hidden-knowl-link", id-ref extra -->
        <xsl:attribute name="class">
            <xsl:text>id-ref</xsl:text>
            <!--  -->
            <xsl:text> </xsl:text>
            <xsl:value-of select="local-name(.)"/>
            <xsl:text>-knowl</xsl:text>
            <!--  -->
            <xsl:text> original</xsl:text>
        </xsl:attribute>
        <!-- and the id via a template for consistency -->
        <xsl:attribute name="data-refid">
            <xsl:apply-templates select="." mode="hidden-knowl-id" />
        </xsl:attribute>
        <!-- the object could be the target of an in-context link, and     -->
        <!-- if inline, then just a bare anchor, so put id here, otherwise -->
        <!-- in the 'block' case, it is on the surrounding element         -->
        <xsl:if test="$placement = 'inline'">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="html-id" />
            </xsl:attribute>
        </xsl:if>
        <!-- marked-up knowl text link *inside* of knowl anchor to be effective -->
        <!-- heading in an HTML container -->
        <xsl:apply-templates select="." mode="heading-birth" />
    </xsl:element>
</xsl:template>

<!-- The content portion of a hidden knowl -->
<!-- *Always* as div.hidden-content"       -->
<xsl:template match="*" mode="hidden-knowl-content">
    <xsl:param name="b-original" select="true()" />

    <!-- .hidden-content is CSS for display: none           -->
    <!-- Stop MathJax from processing contents on page load -->
    <div class="hidden-content tex2jax_ignore">
        <!-- different id, for use by the knowl mechanism -->
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="hidden-knowl-id" />
        </xsl:attribute>
        <!-- should the b-original flag always be true() here -->
        <xsl:apply-templates select="." mode="body">
            <xsl:with-param name="block-type" select="'embed'" />
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </div>
</xsl:template>

<!-- The link for a duplicate hidden knowl -->
<xsl:template match="*" mode="duplicate-hidden-knowl-link">
    <xsl:element name="a">
        <!-- (element-name)-knowl: specific element used in content -->
        <!-- original: born hidden knowl, not xref                  -->
        <!-- Similar to "hidden-knowl-link", no id-ref              -->
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)"/>
            <xsl:text>-knowl</xsl:text>
            <!--  -->
            <xsl:text> original</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="data-knowl">
            <xsl:apply-templates select="." mode="hidden-knowl-filename" />
        </xsl:attribute>
        <!-- add HTML title attribute to the link -->
        <xsl:attribute name="title">
            <xsl:apply-templates select="." mode="tooltip-text" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="heading-birth" />
    </xsl:element>
</xsl:template>


<!-- ##################### -->
<!-- Block Implementations -->
<!-- ##################### -->

<!-- We devise the more straightforward blocks first, -->
<!-- saving the exceptions for subsequent exposition  -->

<!-- REMARK-LIKE -->
<!-- A simple block with full titles and generic contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&REMARK-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-remark = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&REMARK-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&REMARK-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> remark-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&REMARK-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&REMARK-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&REMARK-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&REMARK-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- COMPUTATION-LIKE -->
<!-- A simple block with full titles, but more substantial contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&COMPUTATION-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-remark = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&COMPUTATION-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&COMPUTATION-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> computation-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&COMPUTATION-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&COMPUTATION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&COMPUTATION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&COMPUTATION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- DEFINITION-LIKE -->
<!-- A simple block with full titles and generic contents -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&DEFINITION-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-definition = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&DEFINITION-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&DEFINITION-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> definition-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&DEFINITION-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&DEFINITION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&DEFINITION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&DEFINITION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- ASIDE-LIKE -->
<!-- A simple block with a title (no number) and generic contents -->

<!-- Never born-hidden, other devices partially hide -->
<xsl:template match="&ASIDE-LIKE;" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&ASIDE-LIKE;" mode="body-element">
    <xsl:text>aside</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&ASIDE-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> aside-like</xsl:text>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="&ASIDE-LIKE;" mode="hidden-knowl-placement" />

<!-- When born use this heading -->
<xsl:template match="&ASIDE-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&ASIDE-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Potentially knowled, may have statement      -->
<!-- with Sage, so pass block type                -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="&ASIDE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- Poem -->
<!-- Titled, not numbered, but with an author's name. -->
<!-- Knowled as a cross-reference target, but never born  -->
<!-- hidden (for now particular reason).  A complicated  -->
<!-- implementation, which should rely more on CSS. -->

<!-- Never born-hidden, other devices partially hide -->
<xsl:template match="poem" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="poem" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="poem" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="poem" mode="hidden-knowl-placement" />

<!-- When born use this heading -->
<xsl:template match="poem" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="poem" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="poem" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="stanza" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <!-- author comes early in schema, but is rendered below -->
    <xsl:apply-templates select="author" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- ################### -->
<!-- Structured by Lines -->
<!-- ################### -->

<!-- The HTML-specific line separator for use by   -->
<!-- the abstract template for a "line" elent used -->
<!-- to (optionally) structure certain elements.   -->

<xsl:template name="line-separator">
    <br/>
</xsl:template>

<!-- ###### -->
<!-- Poetry -->
<!-- ###### -->

<!-- TODO: Address GitHub issues regarding poetry output:   -->
<!-- https://github.com/BooksHTML/mathbook-assets/issues/65 -->

<xsl:template match="poem/author">
    <div>
        <xsl:attribute name="class">
            <xsl:text>author</xsl:text>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="poem-halign"/>
        </xsl:attribute>
        <xsl:apply-templates/>
    </div>
</xsl:template>

<xsl:template match="stanza">
    <div class="stanza">
        <xsl:apply-templates select="." mode="heading-title"/>
        <xsl:apply-templates select="line"/>
    </div>
</xsl:template>

<xsl:template match="stanza/line">
    <xsl:variable name="alignment">
        <xsl:apply-templates select="." mode="poem-halign"/>
    </xsl:variable>
    <xsl:variable name="indentation">
        <xsl:apply-templates select="." mode="poem-indent"/>
    </xsl:variable>
    <div>
        <xsl:attribute name="class">
            <xsl:text>line</xsl:text>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="." mode="poem-halign"/>
        </xsl:attribute>
        <!-- Left Alignment: Indent from Left -->
        <xsl:if test="$alignment='left'">
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$indentation"/>
            </xsl:call-template>
        </xsl:if>
        <!-- Center Alignment: Ignore Indentation -->
        <xsl:apply-templates/>
        <!-- Right Alignment: Indent from Right -->
        <xsl:if test="$alignment='right'">
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$indentation"/>
            </xsl:call-template>
        </xsl:if>
    </div>
</xsl:template>

<xsl:template name="poem-line-indenting">
    <xsl:param name="count"/>
    <xsl:choose>
        <xsl:when test="(0 >= $count)"/>
        <xsl:otherwise>
            <span class="tab"/>
            <xsl:call-template name="poem-line-indenting">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- FIGURE-LIKE -->
<!-- Captioned, titled (heading) -->

<!-- Born-hidden behavior is configurable -->
<!-- On a per-element basis               -->
<xsl:template match="figure" mode="is-hidden">
    <xsl:value-of select="$knowl-figure = 'yes'" />
</xsl:template>

<xsl:template match="table" mode="is-hidden">
    <xsl:value-of select="$knowl-table = 'yes'" />
</xsl:template>

<xsl:template match="listing" mode="is-hidden">
    <xsl:value-of select="$knowl-listing = 'yes'" />
</xsl:template>

<xsl:template match="list" mode="is-hidden">
    <xsl:value-of select="$knowl-list = 'yes'" />
</xsl:template>

<!-- The optionally born-hidden items can be panels of -->
<!-- a sidebyside, where we should not be hiding them. -->
<!-- A figure wrapping the sidebyside could be knowled -->
<!-- if they need to be hidden.                        -->
<xsl:template match="sidebyside/figure|sidebyside/table|sidebyside/listing|sidebyside/list" mode="is-hidden">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="&FIGURE-LIKE;" mode="body-element">
    <xsl:text>figure</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="figure|listing" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> figure-like</xsl:text>
</xsl:template>
<!-- a table of data will use this class when -->
<!-- the title is placed above the tabular    -->
<xsl:template match="table|list" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> table-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&FIGURE-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- TODO - sort out title/caption -->
<!-- Use title for xref-link text  -->

<!-- When born use this heading -->
<!-- no heading, since captioned -->
<xsl:template match="&FIGURE-LIKE;" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<!-- no heading, since captioned -->
<xsl:template match="&FIGURE-LIKE;" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Handle "caption" exceptionally               -->
<xsl:template match="&FIGURE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />

    <xsl:variable name="b-subcaptioned" select="parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure"/>
    <xsl:choose>
        <!-- caption at the bottom, always        -->
        <xsl:when test="self::figure|self::listing">
            <xsl:apply-templates select="*">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
            <xsl:apply-templates select="." mode="figure-caption">
                <xsl:with-param name="b-original" select="$b-original"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- table only contains a tabular, if not subcaptioned -->
        <!-- title is displayed before data/tabular             -->
        <xsl:when test="self::table">
            <xsl:if test="not($b-subcaptioned)">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="tabular">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
            <xsl:if test="$b-subcaptioned">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
        <!-- "title" at the top, subcaption at the bottom -->
        <xsl:when test="self::list">
            <xsl:if test="not($b-subcaptioned)">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
            <div class="named-list-content">
                <xsl:apply-templates select="introduction|ol|ul|dl|conclusion">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </div>
            <xsl:if test="$b-subcaptioned">
                <xsl:apply-templates select="." mode="figure-caption">
                    <xsl:with-param name="b-original" select="$b-original"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- Assemblage -->
<!-- A simple block with an optional title and limited contents -->

<!-- Never born-hidden, simply by design -->
<xsl:template match="assemblage" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="assemblage" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="assemblage" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> assemblage-like</xsl:text>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="assemblage" mode="hidden-knowl-placement" />

<!-- When born use this heading -->
<xsl:template match="assemblage" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="assemblage" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Primary content of generic "body" template    -->
<!-- Pass along b-original flag                    -->
<!-- Simply process contents, restrictions match   -->
<!-- schema, except schema says no captioned items -->
<!-- in the side-by-side                           -->
<xsl:template match="assemblage" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="p|blockquote|pre|sidebyside|sbsgroup" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Block Quote -->
<!-- A very simple block with just an enclosing div -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="blockquote" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="blockquote" mode="body-element">
    <xsl:text>blockquote</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="blockquote" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="blockquote" mode="hidden-knowl-placement" />

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="blockquote" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="blockquote" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="blockquote" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Paragraphs -->
<!-- Technically a division, but small enough to xref knowl -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="paragraphs" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="paragraphs" mode="body-element">
    <xsl:text>section</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="paragraphs" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="paragraphs" mode="hidden-knowl-placement" />

<!-- When born use this heading -->
<!-- NB: this is modified in the conversion to Braille -->
<xsl:template match="paragraphs" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="paragraphs" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="paragraphs" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- Commentary -->
<!-- Like "paragraphs" but electively not displayed -->

<!-- Not born-hidden by choice -->
<xsl:template match="commentary" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="commentary" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="commentary" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Not born hidden -->
<xsl:template match="commentary" mode="hidden-knowl-placement" />

<!-- When born use this heading -->
<xsl:template match="commentary" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="commentary" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title-paragraphs" />
</xsl:template>

<!-- Primary content of generic "body" template -->
<!-- Pass along b-original flag                 -->
<!-- Simply process contents, we restrict here  -->
<xsl:template match="commentary" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- coordinate select with schema's BlockStatementNoCaption -->
    <!-- Note that index items are dealt with elsewhere          -->
    <xsl:apply-templates select="idx|p|blockquote|pre|aside|sidebyside|sbsgroup">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- GOAL-LIKE -->
<!-- Special, and restricted, blocks -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="objectives" mode="is-hidden">
    <xsl:value-of select="$knowl-objectives = 'yes'" />
</xsl:template>
<xsl:template match="outcomes" mode="is-hidden">
    <xsl:value-of select="$knowl-outcomes = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&GOAL-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&GOAL-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> goal-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&GOAL-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&GOAL-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full-implicit-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&GOAL-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template        -->
<!-- Pass along b-original flag                        -->
<!-- Simply process contents, with partial restriction -->
<xsl:template match="&GOAL-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="introduction|ol|ul|dl|conclusion" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- The next few implementations have hints, answers, -->
<!-- or solutions hanging off the ends.  Examples may  -->
<!-- elect to have these.  Exercises may have them and -->
<!-- they are more configurable.  Projects may have    -->
<!-- them prima facie, or associated with tasks.  In   -->
<!-- all cases the hints, answers, and solutions are   -->
<!-- presented as knowls.                              -->

<!-- EXAMPLE-LIKE -->
<!-- A simple block, but with possible appendages -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&EXAMPLE-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-example = 'yes'" />
    <!-- Preserving a way to not knowl anything in a worksheet -->
    <!-- 
    <xsl:choose>
        <xsl:when test="ancestor::worksheet">
            <xsl:value-of select="false()"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$knowl-example = 'yes'" />
        </xsl:otherwise>
    </xsl:choose>
    -->
 </xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&EXAMPLE-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&EXAMPLE-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> example-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&EXAMPLE-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&EXAMPLE-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&EXAMPLE-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Process according to structure              -->
<xsl:template match="&EXAMPLE-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="." mode="exercise-components">
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
        <xsl:with-param name="b-has-statement" select="true()" />
        <xsl:with-param name="b-has-hint"      select="true()" />
        <xsl:with-param name="b-has-answer"    select="true()" />
        <xsl:with-param name="b-has-solution"  select="true()" />
    </xsl:apply-templates>
</xsl:template>


<!-- Subexercises -->
<!-- A pseudo-division, implemented more like an "exercisegroup" -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="subexercises" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="subexercises" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="subexercises" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="subexercises" mode="hidden-knowl-placement"/>

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="subexercises" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title"/>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<!-- Not knowlizable, more like a division      -->
<xsl:template match="subexercises" mode="heading-xref-knowl"/>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Mirror changes here into "solutions" below   -->
<xsl:template match="subexercises" mode="wrapped-content">
    <xsl:param name="b-original" select="true()"/>
    <xsl:apply-templates select="introduction">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="exercise|exercisegroup">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="conclusion">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="subexercises" mode="solutions">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <article class="subexercises">
            <xsl:apply-templates select="." mode="heading-title"/>
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="introduction">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="exercise|exercisegroup" mode="solutions">
                <xsl:with-param name="admit"           select="$admit"/>
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="conclusion">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
        </article>
    </xsl:if>
</xsl:template>

<!-- Exercise Group -->
<!-- A very simple block with just an enclosing div -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="exercisegroup" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="exercisegroup" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="exercisegroup" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="exercisegroup" mode="hidden-knowl-placement" />

<!-- When born use this heading         -->
<!-- Never hidden, never gets a heading -->
<xsl:template match="exercisegroup" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="exercisegroup" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Mirror changes here into "solutions" below   -->
<xsl:template match="exercisegroup" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="introduction">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
    <div>
        <xsl:attribute name="class">
            <xsl:text>exercisegroup-exercises</xsl:text>
            <xsl:variable name="cols-class-name">
                <!-- HTML-specific, but in pretext-common.xsl -->
                <xsl:apply-templates select="." mode="number-cols-CSS-class"/>
            </xsl:variable>
            <xsl:if test="not($cols-class-name = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cols-class-name"/>
            </xsl:if>
        </xsl:attribute>
        <xsl:apply-templates select="exercise">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </div>
    <xsl:apply-templates select="conclusion">
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="exercisegroup" mode="solutions">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <div class="exercisegroup">
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="introduction">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
            <div>
                <xsl:attribute name="class">
                    <xsl:text>exercisegroup-exercises</xsl:text>
                    <xsl:variable name="cols-class-name">
                        <!-- HTML-specific, but in pretext-common.xsl -->
                        <xsl:apply-templates select="." mode="number-cols-CSS-class"/>
                    </xsl:variable>
                    <xsl:if test="not($cols-class-name = '')">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$cols-class-name"/>
                    </xsl:if>
                </xsl:attribute>
                <xsl:apply-templates select="exercise" mode="solutions">
                    <xsl:with-param name="admit"           select="$admit"/>
                    <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                    <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                    <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                    <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                </xsl:apply-templates>
            </div>
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates select="conclusion">
                    <xsl:with-param name="b-original" select="false()" />
                </xsl:apply-templates>
            </xsl:if>
        </div>
    </xsl:if>
</xsl:template>

<!-- Exercise -->
<!-- Inline and divisional, with appendages -->

<!-- Born-hidden behavior is configurable   -->
<!-- Note match first on inline first, override if divisional -->
<xsl:template match="exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-inline = 'yes'"/>
</xsl:template>
<xsl:template match="exercises//exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-divisional = 'yes'"/>
</xsl:template>
<xsl:template match="worksheet//exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-worksheet = 'yes'"/>
</xsl:template>
<xsl:template match="reading-questions//exercise" mode="is-hidden">
    <xsl:value-of select="$knowl-exercise-readingquestion = 'yes'"/>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="exercise" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="exercise" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> exercise-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="exercise" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<!-- Note match first on inline, then divisional -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-divisional-exercise-serial" />
</xsl:template>

<!-- Heading for interior of xref-knowl content  -->
<!-- Note match first on inline, then divisional -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-divisional-exercise-typed" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type               -->
<!-- Process according to structure              -->
<!-- Mirror changes here into "solutions" below  -->
<xsl:template match="exercise" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:choose>
        <!-- webwork case -->
        <xsl:when test="webwork-reps">
            <xsl:apply-templates select="introduction|webwork-reps|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- MyOpenMath case -->
        <xsl:when test="myopenmath">
            <xsl:apply-templates select="introduction|myopenmath|conclusion">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- inline                                        -->
        <!-- only possibility to be knowled, so only time  -->
        <!-- we pass block-type for Sage cells to react to -->
        <xsl:when test="boolean(&INLINE-EXERCISE-FILTER;)">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-inline-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-inline-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-inline-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- divisional -->
        <xsl:when test="ancestor::exercises">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-divisional-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-divisional-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-divisional-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- worksheet -->
        <xsl:when test="ancestor::worksheet">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-worksheet-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-worksheet-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-worksheet-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- reading -->
        <xsl:when test="ancestor::reading-questions">
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-reading-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-reading-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-reading-solution" />
            </xsl:apply-templates>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Project-LIKE -->
<!-- A complex block, possibly structured with task -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&PROJECT-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-project = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&PROJECT-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&PROJECT-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> project-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&PROJECT-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&PROJECT-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&PROJECT-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement    -->
<!-- with Sage, so pass block type              -->
<!-- Process according to structure              -->
<!-- Mirror changes here into "solutions" below  -->
<xsl:template match="&PROJECT-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:choose>
        <xsl:when test="task">
            <xsl:apply-templates select="introduction|task|conclusion">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-project-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-project-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-project-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="exercise|&PROJECT-LIKE;" mode="solutions">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit" select="$admit"/>
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <!-- incongruities here are historical, -->
        <!-- keeping the diff low-impact        -->
        <xsl:element name="article">
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="self::exercise">
                        <xsl:text>exercise-like</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>project-like</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- A variety of headings -->
            <xsl:choose>
                <!-- inline can go with generic, which is switched on inline/divisional -->
                <xsl:when test="boolean(&INLINE-EXERCISE-FILTER;)">
                    <xsl:apply-templates select="." mode="heading-birth" />
                </xsl:when>
                <!-- with full number just for solution list -->
                <!-- "exercise" must be divisional now -->
                <xsl:when test="self::exercise">
                    <xsl:apply-templates select="." mode="heading-divisional-exercise" />
                </xsl:when>
                <!-- now PROJECT-LIKE -->
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="heading-birth" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <!-- structured version -->
                <xsl:when test="task">
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="introduction">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="task" mode="solutions">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="conclusion">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="webwork-reps/static/task">
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="webwork-reps/static/introduction">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="webwork-reps/static/task" mode="solutions">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="webwork-reps/static/conclusion">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:when>
                <!-- webwork with stages -->
                <xsl:when test="webwork-reps/static/stage">
                    <xsl:apply-templates select="webwork-reps/static/stage" mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- webwork without tasks or stages -->
                <xsl:when test="webwork-reps/static">
                    <xsl:apply-templates select="webwork-reps/static" mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="."  mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- Task -->
<!-- A division of a PROJECT-LIKE, with appendages -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="task" mode="is-hidden">
    <xsl:value-of select="$knowl-task = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="task" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="task" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> exercise-like</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="task" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="task" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-list-number" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="task" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Potentially knowled, may have statement      -->
<!-- with Sage, so pass block type                -->
<!-- Process according to structure               -->
<!-- Mirror changes here into "solutions" below  -->
<xsl:template match="task" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <!-- *Something* is being output, so include an (optional) title -->
    <xsl:if test="title">
        <h6 class="heading">
            <span class="title">
                <xsl:apply-templates select="." mode="title-full"/>
            </span>
        </h6>
    </xsl:if>
    <xsl:choose>
        <!-- introduction?, task+, conclusion? -->
        <xsl:when test="task">
            <xsl:apply-templates select="introduction|task|conclusion">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="."  mode="exercise-components">
                <xsl:with-param name="b-original" select="$b-original"/>
                <xsl:with-param name="block-type" select="$block-type"/>
                <xsl:with-param name="b-has-statement" select="true()" />
                <xsl:with-param name="b-has-hint"      select="$b-has-project-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-project-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-project-solution" />
            </xsl:apply-templates>
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- For solutions divisions, we mimic and reuse some of the above -->
<xsl:template match="task" mode="solutions">
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <!-- we check for content, subject to selection of switches          -->
    <!-- if there is no content, then we will not output anything at all -->
     <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="b-has-statement" select="$b-has-statement" />
            <xsl:with-param name="b-has-hint" select="$b-has-hint" />
            <xsl:with-param name="b-has-answer" select="$b-has-answer" />
            <xsl:with-param name="b-has-solution" select="$b-has-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <article class="exercise-like">
            <xsl:apply-templates select="." mode="heading-birth" />

            <!-- *Something* is being output, so include an (optional) title -->
            <xsl:if test="title">
                <h6 class="heading">
                    <span class="title">
                        <xsl:apply-templates select="." mode="title-full"/>
                    </span>
                </h6>
            </xsl:if>
            <xsl:choose>
                <!-- introduction?, task+, conclusion? -->
                <xsl:when test="task">
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="introduction">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="task" mode="solutions">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                    <xsl:if test="$b-has-statement">
                        <xsl:apply-templates select="conclusion">
                            <xsl:with-param name="b-original" select="false()" />
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="."  mode="exercise-components">
                        <xsl:with-param name="b-original" select="false()" />
                        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </article>
    </xsl:if>
</xsl:template>


<!-- SOLUTION-LIKE -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="&SOLUTION-LIKE;" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&SOLUTION-LIKE;" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&SOLUTION-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> solution-like</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="&SOLUTION-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>inline</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&SOLUTION-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Potentially knowled, may have statement      -->
<!-- with Sage, so pass block type                -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="&SOLUTION-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="exercise|&PROJECT-LIKE;|task|&EXAMPLE-LIKE;|webwork-reps/static|webwork-reps/static/task|webwork-reps/static/stage" mode="exercise-components">
    <xsl:param name="b-original"/>
    <xsl:param name="block-type"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:choose>
        <!-- intercept a reading question, when hosted on Runestone -->
        <xsl:when test="ancestor::reading-questions and $b-host-runestone">
            <div class="runestone outer-exercise-wrapper">
                <div data-component="shortanswer" class="journal alert alert-success exercise-wrapper" data-optional="" data-mathjax="">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="html-id"/>
                    </xsl:attribute>
                    <!-- structured versus unstructured -->
                    <xsl:choose>
                        <!-- subelements of the structured "statement" -->
                        <xsl:when test="statement">
                            <xsl:apply-templates select="statement/*"/>
                        </xsl:when>
                        <!-- all content, but in elements, e.g "p" -->
                        <xsl:otherwise>
                            <xsl:apply-templates select="*"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </div>
        </xsl:when>
        <!-- now, structured versus unstructured -->
        <xsl:when test="statement">
            <!-- exceptional, Runestone ActiveCode exercise     -->
            <!-- statement as a parameter, so inserted properly -->
            <xsl:choose>
                <xsl:when test="$b-host-runestone and $b-has-statement and program">
                    <xsl:apply-templates select="program" mode="runestone-activecode">
                        <xsl:with-param name="statement-content">
                            <xsl:apply-templates select="statement">
                                <xsl:with-param name="b-original" select="$b-original" />
                                <xsl:with-param name="block-type" select="$block-type"/>
                            </xsl:apply-templates>
                        </xsl:with-param>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$b-has-statement">
                    <xsl:apply-templates select="statement">
                        <xsl:with-param name="b-original" select="$b-original" />
                        <xsl:with-param name="block-type" select="$block-type"/>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
            <!-- A "program" gets absorbed above, so we don't want to show it twice -->
            <!-- Outside of Runestone, we just follow-on with the program           -->
            <xsl:if test="not($b-host-runestone) and $b-has-statement and program">
                <xsl:apply-templates select="program"/>
            </xsl:if>
            <!-- no  div.solutions  if there is nothing to go into it -->
            <xsl:if test="(hint and $b-has-hint) or (answer and $b-has-answer) or (solution and $b-has-solution)">
                <div class="solutions">
                    <xsl:if test="$b-has-hint">
                        <xsl:apply-templates select="hint">
                            <xsl:with-param name="b-original" select="$b-original" />
                            <xsl:with-param name="block-type" select="$block-type"/>
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$b-has-answer">
                        <xsl:apply-templates select="answer">
                            <xsl:with-param name="b-original" select="$b-original" />
                            <xsl:with-param name="block-type" select="$block-type"/>
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:if test="$b-has-solution">
                        <xsl:apply-templates select="solution">
                            <xsl:with-param name="b-original" select="$b-original" />
                            <xsl:with-param name="block-type" select="$block-type"/>
                        </xsl:apply-templates>
                    </xsl:if>
                </div>
            </xsl:if>
            <!-- optionally, an indication of workspace -->
            <!-- for a print version of a worksheet     -->
            <xsl:apply-templates select="." mode="worksheet-workspace"/>
        </xsl:when>
        <!-- TODO: contained "if" should just be a new "when"? (look around for similar)" -->
        <xsl:otherwise>
            <!-- no explicit "statement", so all content is the statement -->
            <!-- the "dry-run" templates should prevent an empty shell  -->
            <xsl:if test="$b-has-statement">
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="block-type" select="$block-type"/>
                </xsl:apply-templates>
                <!-- no separator, since no trailing components -->
                <!-- optionally, an indication of workspace     -->
                <!-- for a print version of a worksheet         -->
                <xsl:apply-templates select="." mode="worksheet-workspace"/>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- All of the items matching the previous template (except perhaps   -->
<!-- the WW exercises) can appear in a worksheet with some room to     -->
<!-- work a problem given by a @workspace attribute.  (But we are not  -->
<!-- careful with the match, given the limited reach here.)  The "div" -->
<!-- we drop here is controlled by the Javascript - on a "normal" page -->
<!-- displaying a worksheet it is ineffective, and on a printable,     -->
<!-- standalone page it produces space that is visually apparent, but  -->
<!-- prints invisible.  No @workspace attribute, nothing is added.     -->
<!-- We rely on a template in -common to error-check the value of      -->
<!-- the attribute.                                                    -->
<xsl:template match="*" mode="worksheet-workspace">
    <xsl:variable name="vertical-space">
        <xsl:apply-templates select="." mode="sanitize-workspace"/>
    </xsl:variable>
    <xsl:if test="not($vertical-space = '')">
        <div class="workspace" data-space="{$vertical-space}"/>
    </xsl:if>
</xsl:template>

<!-- The next few implementions support theorems,       -->
<!-- which may have knowls containing proofs hanging    -->
<!-- off them.  A proof can be a block in its own right -->
<!-- (a "detached" proof).                              -->


<!-- THEOREM-LIKE, AXIOM-LIKE -->
<!-- Similar blocks, former may have a proof appendage -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="is-hidden">
    <xsl:value-of select="$knowl-theorem = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
    <xsl:text> theorem-like</xsl:text>
</xsl:template>

<!-- When born hidden, block-level -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement     -->
<!-- with Sage, so pass block type              -->
<!-- Simply process contents, could restict here -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <!-- Locate first "proof", select only preceding:: ? -->
    <xsl:apply-templates select="*[not(self::proof)]" >
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- Proof -->
<!-- A fairly simple block, though configurable -->

<!-- Born-hidden behavior is configurable -->
<xsl:template match="proof" mode="is-hidden">
    <xsl:value-of select="$knowl-proof = 'yes'" />
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="proof" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- Only subsidiary item that is configurable -->
<!-- as visible or hidden in a knowl           -->
<xsl:template match="proof" mode="body-css-class">
    <xsl:choose>
        <xsl:when test="$knowl-proof = 'yes'">
            <xsl:text>hiddenproof</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>proof</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Trailing as a hidden knowl, or plainly  -->
<!-- visible, a proof is a block level item  -->
<xsl:template match="proof" mode="hidden-knowl-placement">
    <xsl:text>block</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<!-- Optionally titled          -->
<xsl:template match="proof" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-no-number"/>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<!-- Optionally titled                          -->
<xsl:template match="proof" mode="heading-xref-knowl">
    <xsl:choose>
        <xsl:when test="title">
            <xsl:apply-templates select="." mode="heading-title" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="heading-type" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Primary content of generic "body" template  -->
<!-- Pass along b-original flag                  -->
<!-- Potentially knowled, may have statement    -->
<!-- with Sage, so pass block type              -->
<!-- Simply process contents, could restict here -->
<xsl:template match="proof" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="block-type"/>

    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original"/>
        <xsl:with-param name="block-type" select="$block-type"/>
    </xsl:apply-templates>
</xsl:template>


<!-- Case (of a proof) -->
<!-- A simple block with an inline heading -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="case" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="case" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="case" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="case" mode="hidden-knowl-placement" />

<!-- When born use this specialized heading -->
<xsl:template match="case" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-case" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="case" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-case" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="case" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Next few implementations fit into general -->
<!-- framework, but have some one-off flavor   -->


<!-- Footnotes -->
<!-- A bit unusual, as inline with minimal appearance -->

<!-- Always born-hidden, by design -->
<xsl:template match="fn" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="fn" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="fn" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="fn" mode="hidden-knowl-placement">
    <xsl:text>inline</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<!-- This could move to headings, but is one-off -->
<xsl:template match="fn" mode="heading-birth">
    <xsl:element name="sup">
        <xsl:text>&#x2009;</xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>&#x2009;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="fn" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema is TextLong, so need to process mixed -->
<xsl:template match="fn" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- Contributor -->
<!-- A block with no subsidiary elements, no duplication -->

<!-- Never born-hidden, does not make sense -->
<xsl:template match="contributor" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<!-- Natural HTML element      -->
<xsl:template match="contributor" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="contributor" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="contributor" mode="hidden-knowl-placement" />

<!-- Heading is not needed -->
<xsl:template match="contributor" mode="heading-birth" />

<!-- xref-knowl content makes it obvious-->
<xsl:template match="contributor" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<xsl:template match="contributor" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- not interpreting duplication flag here -->
    <div class="contributor-name">
        <xsl:apply-templates select="personname" />
    </div>
    <div class="contributor-info">
        <xsl:if test="department">
            <xsl:apply-templates select="department" />
            <xsl:if test="department/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
        <xsl:if test="institution">
            <xsl:apply-templates select="institution" />
            <xsl:if test="institution/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
        <xsl:if test="location">
            <xsl:apply-templates select="location" />
            <xsl:if test="location/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
        <xsl:if test="email">
            <xsl:apply-templates select="email" />
            <xsl:if test="email/following-sibling::*">
                <br />
            </xsl:if>
        </xsl:if>
    </div>
</xsl:template>


<!-- Defined Terms (of a Glossary) -->

<!-- Never born-hidden, always in "glossary" -->
<xsl:template match="defined-term" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="defined-term" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="defined-term" mode="body-css-class">
    <xsl:value-of select="local-name()"/>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="defined-term" mode="hidden-knowl-placement" />

<!-- When born use this heading -->
<xsl:template match="defined-term" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<!-- Not necessary, obvious by appearance       -->
<xsl:template match="defined-term" mode="heading-xref-knowl" />

<!-- Glossary defined terms have more structure -->
<!-- The id is placed on the title as a target  -->
<xsl:template match="defined-term" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="li">
                <!-- "title" of item is replicated in heading -->
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <!-- a run of paragraphs, conceivably, title is killed -->
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <dt>
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="html-id" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="." mode="title-full" />
            </dt>
            <dd>
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </dd>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Bibliographic Entries -->
<!-- An obvious use for knowls, but occur inline -->

<!-- Never born-hidden, always in references -->
<xsl:template match="biblio" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="biblio" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<xsl:template match="biblio" mode="body-css-class">
    <xsl:text>bib</xsl:text>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="biblio" mode="hidden-knowl-placement" />

<!-- When born use this heading -->
<xsl:template match="biblio" mode="heading-birth" />

<!-- Heading for interior of xref-knowl content -->
<!-- Not necessary, obvious by appearance       -->
<xsl:template match="biblio" mode="heading-xref-knowl" />

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema is TextLong, so need to process mixed -->
<xsl:template match="biblio" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <!-- ignoring original flag at first, -->
    <!-- nothing interior gets duplicated -->
    <div class="bibitem">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="." mode="serial-number" />
        <xsl:text>]</xsl:text>
    </div>
    <xsl:text>&#xa0;&#xa0;</xsl:text>
    <div class="bibentry">
        <xsl:apply-templates select="text()|*[not(self::note)]">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </div>
    <xsl:if test="note">
        <div class="knowl-container">
            <xsl:apply-templates select="note">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </div>
    </xsl:if>
</xsl:template>

<!-- Bibliographic Note -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="biblio/note" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="biblio/note" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- This is a temporary hack, which should go away -->
<xsl:template match="biblio/note" mode="body-css-class">
    <xsl:text>solution-like</xsl:text>
</xsl:template>

<!-- When born hidden, inline-level -->
<xsl:template match="biblio/note" mode="hidden-knowl-placement">
    <xsl:text>inline</xsl:text>
</xsl:template>

<!-- When born use this heading -->
<xsl:template match="biblio/note" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple" />
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="biblio/note" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template   -->
<!-- Pass along b-original flag                   -->
<!-- Simply process contents, could restrict here -->
<!-- Schema says just paragraphs, "p"             -->
<xsl:template match="biblio/note" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates select="p" >
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>

<!-- Fragment (literate programming) -->
<!-- A simple item hanging off others -->

<!-- Always born-hidden, by design -->
<xsl:template match="fragment" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- Overall enclosing element -->
<xsl:template match="fragment" mode="body-element">
    <xsl:text>div</xsl:text>
</xsl:template>

<!-- And its CSS class -->
<!-- This is a temporary hack, which should go away -->
<xsl:template match="fragment" mode="body-css-class">
    <xsl:text>fragment</xsl:text>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="fragment" mode="hidden-knowl-placement"/>

<!-- When born use this heading -->
<xsl:template match="fragment" mode="heading-birth">
    <h6 class="heading">
        <xsl:call-template name="langle-character"/>
        <xsl:apply-templates select="." mode="number"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
        <xsl:call-template name="rangle-character"/>
        <!--  U+2261 ≡ IDENTICAL TO -->
        <xsl:text> &#x2261;</xsl:text>
    </h6>
    <xsl:if test="@filename">
        <xsl:text>Root of file: </xsl:text>
        <xsl:value-of select="@filename"/>
        <br/>
    </xsl:if>
</xsl:template>

<!-- Heading for interior of xref-knowl content -->
<xsl:template match="fragment" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- Primary content of generic "body" template -->
<!-- Pass along b-original flag                 -->
<xsl:template match="fragment" mode="wrapped-content">
    <xsl:param name="b-original" select="true()" />
    <pre>
        <xsl:apply-templates select="code|fragref"/>
    </pre>
</xsl:template>

<!-- Stub: for the conversion to braille, which imports this -->
<!-- stylesheet, we sometimes add a @data-braille attribute  -->
<!-- to guide the application of  liblouis  styles.  For     -->
<!-- blocks, we have a "block-data-braille-attribute" hook   -->
<!-- in the "body" template.  Here (and now) it is           -->
<!-- implemented as a no-op stub.  The stylesheet for the    -->
<!-- conversion to braille will override this template with  -->
<!-- the desired functionality.                              -->
<xsl:template match="*" mode="block-data-braille-attribute"/>

<!-- All of the implementations above use the same   -->
<!-- template for their body, it relies on various   -->
<!-- templates but most of the work comes via the    -->
<!-- "wrapped-content" template.  Here is that       -->
<!-- "body" template.  The items in the "match"      -->
<!-- are in the order presented above: simple first, -->
<!-- and top-down when components are also knowled.  -->


<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&DEFINITION-LIKE;|&ASIDE-LIKE;|poem|&FIGURE-LIKE;|assemblage|blockquote|paragraphs|commentary|&GOAL-LIKE;|&EXAMPLE-LIKE;|subexercises|exercisegroup|exercise|&PROJECT-LIKE;|task|&SOLUTION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|proof|case|fn|contributor|biblio|biblio/note|fragment" mode="body">
    <xsl:param name="b-original" select="true()"/>
    <xsl:param name="block-type"/>

    <!-- prelude beforehand, when original -->
    <xsl:if test="$b-original">
        <xsl:apply-templates select="prelude">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
    <!-- A "commentary" element is a top-level block,    -->
    <!-- unlike a subsidiary element like a "hint",      -->
    <!-- which must be elected to be visible, so this is -->
    <!-- a bit of an ad-hock hack to handle this case    -->
    <!-- No prelude, postlude, proof for "commentary"    -->
    <xsl:if test="not(self::commentary) or $b-commentary">
        <xsl:variable name="body-elt">
            <xsl:apply-templates select="." mode="body-element" />
        </xsl:variable>
        <xsl:element name="{$body-elt}">
            <xsl:attribute name="class">
                <xsl:apply-templates select="." mode="body-css-class" />
            </xsl:attribute>
            <!-- possible indicator for use in for braille conversion, -->
            <!-- activated by a non-trivial implementation of this     -->
            <!-- hook in the braille stylesheet                        -->
            <xsl:apply-templates select="." mode="block-data-braille-attribute"/>
            <!-- Label original, but not if embedded            -->
            <!-- Then id goes onto the knowl text, so locatable -->
            <xsl:if test="$b-original and not($block-type = 'embed')">
                <xsl:attribute name="id">
                    <xsl:apply-templates select="." mode="html-id" />
                </xsl:attribute>
            </xsl:if>
            <!-- If visible, heading interior to article -->
            <xsl:if test="$block-type = 'visible'">
                <xsl:apply-templates select="." mode="heading-birth" />
            </xsl:if>
            <!-- If xref-knowl, heading interior to article -->
            <xsl:if test="$block-type = 'xref'">
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
            </xsl:if>
            <!-- After the heading, and before the actual guts, we      -->
            <!-- sometimes annotate with a knowl showing the source     -->
            <!-- of the current element.  This calls a stub, unless     -->
            <!-- a separate stylesheet is used to define the template,  -->
            <!-- and the method is defined there.                       -->
            <xsl:apply-templates select="." mode="view-source-knowl"/>
            <!-- Then actual content, respecting b-original flag  -->
            <!-- Pass $block-type for Sage cells to know environs -->
            <xsl:apply-templates select="." mode="wrapped-content">
                <xsl:with-param name="b-original" select="$b-original" />
                <xsl:with-param name="block-type" select="$block-type" />
            </xsl:apply-templates>
        </xsl:element>
        <!-- collect elements which can have footnotes within -->
        <!-- footnotes in captions of figures and listings,   -->
        <!-- but not in titles of tables or lists             -->
        <xsl:apply-templates select="self::figure|self::table|self::listing" mode="pop-footnote-text">
            <xsl:with-param name="b-original" select="$b-original"/>
        </xsl:apply-templates>
    </xsl:if>
    <!-- Extraordinary: proofs are not displayed within their    -->
    <!-- parent theorem, but as a sibling, following.  It might  -->
    <!-- be a hidden knowl, it might just be the proof visible.  -->
    <!-- The conditional simply prevents abuse.                  -->
    <xsl:if test="(&THEOREM-FILTER;)">
        <xsl:apply-templates select="proof">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
    <!-- postlude afterward, when original -->
    <xsl:if test="$b-original">
        <xsl:apply-templates select="postlude">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>


<!-- The following feed into the same framework,   -->
<!-- but have their own specific "body" templates  -->
<!-- due to their unique characteristics.  We have -->
<!-- paragraphs ("p"), list items ("li"), webwork  -->
<!-- exercises ("webwork-reps"), and numbered      -->
<!-- mathematics ("men", "md", "mdn")              -->


<!-- Paragraph -->
<!-- These are never born hidden.  They are     -->
<!-- often xref targets (such as in the index). -->
<!-- Because we bust up some paragraphs into    -->
<!-- smaller ones, interleaved with displays    -->
<!-- (lists, math, code display), and because   -->
<!-- they do not have titles or heading,        -->
<!-- we process everything in the body.         -->

<xsl:template match="p" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="p" mode="body-element" />

<xsl:template match="p" mode="body-css-class" />

<xsl:template match="p" mode="heading-birth" />

<xsl:template match="p" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-type" />
</xsl:template>

<!-- Paragraphs, without lists within   -->
<!-- Coordinate with simplified version -->
<!-- in the conversion to Braille       -->
<xsl:template match="p" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="$block-type = 'xref'">
        <xsl:apply-templates select="." mode="heading-xref-knowl" />
    </xsl:if>
    <p>
        <!-- label original -->
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="html-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates>
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </p>
    <!-- Single HTML paragraphs is done, place footnote content(s) here -->
    <xsl:apply-templates select="." mode="pop-footnote-text">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Paragraphs, with displays within                    -->
<!-- Later, so a higher priority match                   -->
<!-- Lists and display math are HTML blocks              -->
<!-- and so should not be within an HTML paragraph.      -->
<!-- We bust them out, and put the id for the paragraph  -->
<!-- on the first one, even if empty.                    -->
<!-- All but the first is p/@data-braille="continuation" -->
<!-- so later HTML "p" can be styled for Braille as if   -->
<!-- they are part of a logical PreTeXt paragraph        -->
<xsl:template match="p[ol|ul|dl|me|men|md|mdn|cd]" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="$block-type = 'xref'">
        <xsl:apply-templates select="." mode="heading-xref-knowl" />
    </xsl:if>
    <!-- will later loop over displays within paragraph -->
    <xsl:variable name="displays" select="ul|ol|dl|me|men|md|mdn|cd" />
    <!-- content prior to first display is exceptional, but if empty,   -->
    <!-- as indicated by $initial, we do not produce an empty paragraph -->
    <!-- NB: this means first display must check for no predecessor,    -->
    <!-- and react accordingly to employ the real paragraph's id.  See  -->
    <!-- the modal "insert-paragraph-id" just below, and its employment -->
    <!--                                                                -->
    <!-- all interesting nodes of paragraph, before first display       -->
    <xsl:variable name="initial" select="$displays[1]/preceding-sibling::*|$displays[1]/preceding-sibling::text()" />
    <xsl:variable name="initial-content">
        <xsl:apply-templates select="$initial">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
    <!-- This comparison might improve with a normalize-space()      -->
    <xsl:if test="not($initial-content='')">
        <p>
            <xsl:if test="$b-original">
                <xsl:attribute name="id">
                    <xsl:apply-templates select="." mode="html-id" />
                </xsl:attribute>
            </xsl:if>
            <xsl:copy-of select="$initial-content" />
        </p>
    </xsl:if>
    <!-- for each display, output the display, plus trailing content -->
    <xsl:for-each select="$displays">
        <!-- do the display proper -->
        <xsl:apply-templates select=".">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <!-- look through remainder, all element and text nodes, and the next display -->
        <xsl:variable name="rightward" select="following-sibling::*|following-sibling::text()" />
        <xsl:variable name="next-display" select="following-sibling::*[self::ul or self::ol or self::dl or self::me or self::men or self::md or self::mdn or self::cd][1]" />
        <xsl:choose>
            <xsl:when test="$next-display">
                <xsl:variable name="leftward" select="$next-display/preceding-sibling::*|$next-display/preceding-sibling::text()" />
                <!-- device below forms set intersection -->
                <xsl:variable name="common" select="$rightward[count(. | $leftward) = count($leftward)]" />
                <!-- No id on these, as the first "p" got that    -->
                <!-- Careful, punctuation after display math      -->
                <!-- gets absorbed into display and so is a node  -->
                <!-- that produces no content (cannot just count) -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$common">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <p class="continuation">
                        <xsl:if test="$b-braille">
                            <xsl:attribute name="data-braille">
                                <xsl:text>continuation</xsl:text>
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:copy-of select="$common-content" />
                    </p>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- finish the trailing content, if nonempty -->
                <xsl:variable name="common-content">
                    <xsl:apply-templates select="$rightward">
                        <xsl:with-param name="b-original" select="$b-original" />
                    </xsl:apply-templates>
                </xsl:variable>
                <!-- XSLT 1.0: RTF is just a string if not converted to node set -->
                <!-- This comparison might improve with a normalize-space()      -->
                <xsl:if test="not($common-content = '')">
                    <p class="continuation">
                        <xsl:if test="$b-braille">
                            <xsl:attribute name="data-braille">
                                <xsl:text>continuation</xsl:text>
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:copy-of select="$common-content" />
                    </p>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
    <!-- All HTML paragraphs are done, place footnote content(s) here -->
    <xsl:apply-templates select="." mode="pop-footnote-text">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
</xsl:template>

<!-- We drop an empty "leading paragraph" above.  Whatever     -->
<!-- display comes next needs to grab the id of the enclosing  -->
<!-- paragraph and place it on the enclosing HTML element of   -->
<!-- that item.  So these displays should never have an id     -->
<!-- anyway.  Said differently, a paragraph should be atomic,  -->
<!-- and you cannot point to its constituents. The $b-original -->
<!-- flag is passed in by the enclosing paragraph and is not a -->
<!-- property of the display, per se, but instead is the       -->
<!-- paragraph's status.                                       -->
<xsl:template match="ul|ol|dl|me|men|md|mdn|cd" mode="insert-paragraph-id">
    <xsl:param name="b-original" select="true()" />
    <xsl:if test="parent::p and $b-original">
        <xsl:variable name="leading" select="preceding-sibling::*|preceding-sibling::text()" />
        <xsl:variable name="leading-content">
            <xsl:apply-templates select="$leading">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:if test="$leading-content = ''">
            <xsl:attribute name="id">
                <xsl:apply-templates select="parent::p" mode="html-id" />
            </xsl:attribute>
        </xsl:if>
    </xsl:if>
</xsl:template>


<!-- List Items -->
<!-- A list item can be the target of a        -->
<!-- cross-reference, so we need to make       -->
<!-- a xref-knowl for that scenario.  Also,    -->
<!-- we produce the original versions here     -->
<!-- too.  The "ol, "ul", "dl" are pure        -->
<!-- containers and are implemented elsewhere. -->

<!-- Not applicable -->
<xsl:template match="li" mode="is-hidden" />

<xsl:template match="li" mode="body-element">
    <xsl:text>article</xsl:text>
</xsl:template>

<!-- not yet supported, change this? -->
<xsl:template match="li" mode="body-css-class">
    <xsl:text>li</xsl:text>
</xsl:template>

<!-- Never born hidden -->
<xsl:template match="li" mode="hidden-knowl-placement" />

<!-- Not applicable -->
<xsl:template match="li" mode="heading-birth" />

<xsl:template match="li" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full" />
</xsl:template>

<!-- For a description list, the title alone is enough -->
<xsl:template match="dl/li" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-title" />
</xsl:template>

<!-- Pass-through regular list items    -->
<!-- Allow paragraphs in larger items,  -->
<!-- or just snippets for smaller items -->
<!-- radically diffferent looks if part -->
<!-- of overall list versus being a     -->
<!-- standalone display of one item     -->
<!-- var may be a multiple choice list  -->
<!-- container from a webwork-reps      -->
<xsl:template match="ol/li|ul/li|var/li" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="li">
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="li">
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="html-id" />
                    </xsl:attribute>
                </xsl:if>
                <!-- "title" only possible for structured version of a list item -->
                <xsl:if test="title">
                    <h6 class="heading">
                        <span class="title">
                            <xsl:apply-templates select="." mode="title-full"/>
                        </span>
                    </h6>
                </xsl:if>
                <!-- Unstructured list items will be output as an HTML "p"     -->
                <!-- within the "li", much like a structured list item could   -->
                <!-- have a single "p" as its structured content.  This is     -->
                <!-- meant to help with authoring tools based on HTML content  -->
                <!-- and for CSS withing Kindle versions.  A "dl/li" is always -->
                <!-- structured, so we can do this here.                       -->
                <xsl:choose>
                    <!-- Any of these children is an indicator of a structured  -->
                    <!-- list item, according to the schema, as of 2021-07-03   -->
                    <xsl:when test="p|blockquote|pre|image|video|program|console|tabular|&FIGURE-LIKE;|&ASIDE-LIKE;|sidebyside|sbsgroup|sage">
                        <xsl:apply-templates>
                            <xsl:with-param name="b-original" select="$b-original" />
                        </xsl:apply-templates>
                    </xsl:when>
                    <!-- No good test for unstructured? -->
                    <xsl:otherwise>
                        <p>
                            <!-- Create a derived id, if original.  Somewhat  -->
                            <!-- contrived so it doesn't collide with another. -->
                            <xsl:if test="$b-original">
                                <xsl:attribute name="id">
                                    <xsl:text>p-derived-</xsl:text>
                                    <xsl:apply-templates select="." mode="html-id" />
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:apply-templates>
                                <xsl:with-param name="b-original" select="$b-original" />
                            </xsl:apply-templates>
                        </p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Description list items have more structure -->
<!-- The id is placed on the title as a target  -->
<xsl:template match="dl/li" mode="body">
    <xsl:param name="block-type" />
    <xsl:param name="b-original" select="true()" />
    <xsl:choose>
        <xsl:when test="$block-type = 'xref'">
            <article class="li">
                <!-- "title" of item is replicated in heading -->
                <xsl:apply-templates select="." mode="heading-xref-knowl" />
                <!-- a run of paragraphs, conceivably, title is killed -->
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </article>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="dt">
                <!-- label original -->
                <xsl:if test="$b-original">
                    <xsl:attribute name="id">
                        <xsl:apply-templates select="." mode="html-id" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="." mode="title-full" />
            </xsl:element>
            <xsl:element name="dd">
                <xsl:apply-templates>
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax should be       -->
<!-- independent of output format.  Despite MathJax's     -->
<!-- broad array of capabilities, there are still some    -->
<!-- differences which we need to accomodate via abstract -->
<!-- templates.                                           -->

<!-- See the -common stylesheet for manipulations of math elements      -->
<!-- and subsequent text nodes that lead with punctuation.  Basically,  -->
<!-- punctuation can migrate from the start of the text node and into   -->
<!-- the math, wrapped in a \text{}.  We do this to display math as a   -->
<!-- service to authors.  But for HTML/MathJax we avoid bad line-breaks -->
<!-- if we do this routinely for inline math also.  If MathJax ever     -->
<!-- gets better at this, then we can set this switch to 'display',     -->
<!-- as for LaTeX.                                                      -->
<xsl:variable name="math.punctuation.include" select="'all'"/>

<!-- Inline Mathematics ("m") -->

<!-- Never labeled, so not ever knowled,        -->
<!-- and so no need for a duplicate template    -->
<!-- Asymmetric LaTeX delimiters \( and \) need -->
<!-- to be part of MathJax configuration, but   -->
<!-- also free up the dollar sign               -->

<!-- These two templates provide the delimiters for -->
<!-- inline math, so we can adjust with overides.   -->
<xsl:template name="begin-inline-math">
    <xsl:text>\(</xsl:text>
</xsl:template>

<xsl:template name="end-inline-math">
    <xsl:text>\)</xsl:text>
</xsl:template>

<!-- Displayed Single-Line Math ("me", "men") -->

<!-- All displayed mathematics is wrapped by a div,    -->
<!-- motivated in part by the need to sometimes put an -->
<!-- HTML id on the first item of an exploded logical  -->
<!-- paragraph into several HTML block level items     -->
<!-- NB: displaymath might have an intertext           -->
<!-- becoming "p", thus the necessity of "copy-of"     -->
<xsl:template match="me|men|md|mdn" mode="display-math-wrapper">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="content" />
    <div class="displaymath">
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:copy-of select="$content" />
    </div>
</xsl:template>

<!-- "men" needs to be handled in the knowl production          -->
<!-- scheme (but just barely), since it can be duplicated,      -->
<!-- and there are minor details with trailing punctuation.     -->
<!-- Then we just add "me" in as well, since it is so similar.  -->
<!-- The necessary modal "body" template is in -common, and     -->
<!-- is called by other conversions with the default variables. -->

<!-- We need a few templates for knowl production, -->
<!-- but generally they do nothing                 -->

<!-- always visible -->
<xsl:template match="me|men" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="me|men" mode="body-element" />
<xsl:template match="me|men" mode="body-css-class" />

<!-- No title; type and number obvious from content -->
<xsl:template match="me|men" mode="heading-xref-knowl" />

<!-- We need this so a % is used only on the LaTeX side -->
<xsl:template name="display-math-visual-blank-line">
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- Manual Number Tagging -->
<!-- We do "tag" numbered equations in MathJax output, -->
<!-- because we want to control and duplicate the way  -->
<!-- numbers are generated and assigned by LaTeX       -->
<!-- "me" is never numbered/tagged, "men" always is    -->
<!-- This is the MathJax hard-coded technique          -->
<!-- Local tag preempts a hard-coded number, and we    -->
<!-- need to also take care with the numbering         -->
<!-- \label{} uses author's @xml:id as the logical,    -->
<!-- unique identifier in source and in HTML.  \tag{}  -->
<!-- is what a reader sees, usually the number         -->
<!-- computed in -common, but sometimes symbols        -->
<!-- generated by mrow/@tag                            -->

<!-- 2020-08-17: \label{} gets butchered in the SRE conversion      -->
<!-- to Nemeth braille, so we are using stripped down versions      -->
<!-- of these templates in the "extract-math" stylesheet (look      -->
<!-- there before editing here).  Presently, the useLabelIDs        -->
<!-- scheme with the "mjx-eqn-foo" manufactured is used in HTML     -->
<!-- output.  But maybe we should mimic knowl creation and have     -->
<!-- a cross-reference (in-context) point to an ID on an            -->
<!-- (existing) enclosing "div" on display mathematics.  That       -->
<!-- might be better for EPUB, speech, etc, in addition to braille. -->

<xsl:template match="men|mrow" mode="tag">
    <xsl:param name="b-original" />
    <xsl:if test="$b-original and @xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:apply-templates select="." mode="html-id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="mrow[@tag]" mode="tag">
    <xsl:param name="b-original" />
    <xsl:if test="$b-original and @xml:id">
        <xsl:text>\label{</xsl:text>
        <xsl:apply-templates select="." mode="html-id" />
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>\tag{</xsl:text>
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
    <xsl:text>}</xsl:text>
</xsl:template>


<!-- Displayed Multi-Line Math ("md", "mdn") -->

<!-- The default template for the "md" and "mdn" containers   -->
<!-- just calls the modal "body" template needed for the HTML -->
<!-- knowl production scheme.                                 -->

<!-- We need a few templates for knowl production, -->
<!-- but generally they do nothing                 -->

<!-- always visible -->
<xsl:template match="md|mdn" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<xsl:template match="md|mdn" mode="body-element" />
<xsl:template match="md|mdn" mode="body-css-class" />

<!-- No title; type and number obvious from content -->
<xsl:template match="md|mdn" mode="heading-xref-knowl" />

<!-- Rows of Displayed Multi-Line Math ("mrow") -->
<!-- Template in -common is sufficient with base templates     -->
<!--                                                           -->
<!-- (1) "display-page-break" (LaTeX only)                     -->
<!-- (2) "qed-here" (LaTeX only)                               -->

<!-- Intertext -->
<!-- A LaTeX construct really, we just jump out/in of    -->
<!-- the align/gather environment and process the text.  -->
<!-- "md" and "mdn" can only occur in a "p" and          -->
<!-- we break a logical PreTeXt "p" into multiple HTML   -->
<!-- "p" at places where displays occur, such as math    -->
<!-- and lists.  So we can wrap the "intertext" in a     -->
<!-- p.intertext, giving xref knowls a place to open.    -->
<!-- This breaks the alignment, but MathJax has no good  -->
<!-- solution for this.                                  -->
<!-- NB: "displaymath-alignment" needs to be just right  -->
<!-- NB: we check the *parent* for alignment information -->
<!-- NB: the out-of-order LaTeX begin/end pairs mean     -->
<!-- the "p" for intertext are contained in the overall  -->
<!-- "display-math-wrapper".  It might be advisable      -->
<!-- to unpack the whole md/mdn into math bits and       -->
<!-- intertext bits, similar to how paragraphs are       -->
<!-- exploded.  This will make it harder to locate       -->
<!-- the id of an enclosing paragraph onto the first     -->
<!-- component (first in exploded paragraph, first in    -->
<!-- exploded md/intertext).                             -->
<!-- An abstact "intertext-wrapper" would allow all      -->
<!-- this to live in -common.                            -->
<!-- TODO: pass duplication flag, reaction unnecessary?  -->
<xsl:template match="intertext">
    <xsl:param name="b-nonumbers" select="false()" />
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment">
        <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
    </xsl:apply-templates>
    <xsl:text>}&#xa;</xsl:text>
    <p class="intertext">
        <xsl:apply-templates />
    </p>
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="parent::*" mode="displaymath-alignment">
        <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
    </xsl:apply-templates>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="parent::*" mode="alignat-columns" />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- It is too easy to type in LaTeX which can be picked up by   -->
<!-- MathJax in HTML.  We provide just enough disruption with    -->
<!-- the insertion of a "zero width space", U+200B, into the     -->
<!-- opening signals.  Note that MathJax needs both an opening   -->
<!-- signal, and a closing signal, in proximity, before anything -->
<!-- gets processed.  So the situations considered here are      -->
<!-- either rare or intentional.                                 -->
<!--                                                             -->
<!-- Note this holds for parts of interactives as well, so       -->
<!-- authors need to use the MathJax script tags for any part of -->
<!-- thier HTML they want displayed as mathematics.              -->

<xsl:template name="text-processing">
    <xsl:param name="text"/>

    <xsl:variable name="inline-fixed"      select="str:replace($text,         '\(',      '\&#x200b;(' )"/>
    <xsl:variable name="environment-fixed" select="str:replace($inline-fixed, '\begin{', '\&#x200b;begin{' )"/>

    <xsl:value-of select="$environment-fixed"/>
</xsl:template>

<!-- We cruise knowled content for necessity of hidden knowls -->
<xsl:template match="*" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- ############################# -->
<!-- End: Block Production, Knowls -->
<!-- ############################# -->


<!-- #################### -->
<!-- Components of Blocks -->
<!-- #################### -->

<!-- Introductions and Conclusions -->
<!-- As components of blocks.      -->
<xsl:template match="introduction[not(parent::*[&STRUCTURAL-FILTER;])]|conclusion[not(parent::*[&STRUCTURAL-FILTER;])]">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:value-of select="local-name(.)" />
        </xsl:attribute>
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="html-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="title">
            <h6 class="heading">
                <xsl:apply-templates select="." mode="title-full" />
                <span> </span>
            </h6>
        </xsl:if>
        <xsl:apply-templates>
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- Prelude, Interlude, Postlude -->
<!-- Very simple containiers, to help with movement, use -->
<xsl:template match="prelude|interlude|postlude">
    <xsl:param name="b-original" select="true()" />
    <xsl:apply-templates>
        <xsl:with-param name="b-original" select="$b-original" />
    </xsl:apply-templates>
</xsl:template>


<!-- ########### -->
<!-- HTML Markup -->
<!-- ########### -->

<!-- ##### -->
<!-- Lists -->
<!-- ##### -->

<!-- Utility templates to translate MBX              -->
<!-- enumeration style to HTML list-style-type       -->
<!-- NB: this is currently inferior to latex version -->
<!-- NB: all pre-, post-formatting is lost           -->
<xsl:template match="ol" mode="html-list-class">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = '0'">decimal</xsl:when>
        <xsl:when test="$mbx-format-code = '1'">decimal</xsl:when>
        <xsl:when test="$mbx-format-code = 'a'">lower-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'A'">upper-alpha</xsl:when>
        <xsl:when test="$mbx-format-code = 'i'">lower-roman</xsl:when>
        <xsl:when test="$mbx-format-code = 'I'">upper-roman</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad ordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="ul" mode="html-list-class">
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$mbx-format-code = 'disc'">disc</xsl:when>
        <xsl:when test="$mbx-format-code = 'circle'">circle</xsl:when>
        <xsl:when test="$mbx-format-code = 'square'">square</xsl:when>
        <xsl:when test="$mbx-format-code = 'none'">no-marker</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: bad unordered list label format code in HTML conversion</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Lists themselves -->
<!-- Hard-code the list style, trading -->
<!-- on match in label templates.      -->
<!-- Tunnel duplication flag to list items -->
<xsl:template match="ol|ul">
    <xsl:param name="b-original" select="true()" />
    <!-- need to switch on 0-1 for ol Arabic -->
    <!-- no harm if called on "ul"           -->
    <xsl:variable name="mbx-format-code">
        <xsl:apply-templates select="." mode="format-code" />
    </xsl:variable>
    <xsl:element name="{local-name(.)}">
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:if test="$mbx-format-code = '0'">
            <xsl:attribute name="start">
                <xsl:text>0</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="class">
            <xsl:apply-templates select="." mode="html-list-class" />
            <xsl:variable name="cols-class-name">
                <!-- HTML-specific, but in pretext-common.xsl -->
                <xsl:apply-templates select="." mode="number-cols-CSS-class"/>
            </xsl:variable>
            <xsl:if test="not($cols-class-name = '')">
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cols-class-name"/>
            </xsl:if>
        </xsl:attribute>
        <xsl:apply-templates select="li">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
    <xsl:apply-templates select="." mode="pop-footnote-text">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
</xsl:template>

<!-- We let CSS react to narrow titles for dl -->
<!-- But no support for multiple columns      -->
<!-- tunnel duplication flag to list items -->
<xsl:template match="dl">
    <xsl:param name="b-original" select="true()" />
    <dl>
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="@width = 'narrow'">
                    <xsl:text>description-list narrow</xsl:text>
                </xsl:when>
                <!-- 'medium', 'wide', and any typo (let DTD check) -->
                <xsl:otherwise>
                    <xsl:text>description-list</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates select="li">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </dl>
    <xsl:apply-templates select="." mode="pop-footnote-text">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
</xsl:template>

<!-- ###### -->
<!-- Images -->
<!-- ###### -->

<!-- A bare image, or an image in a PTX "figure" that is not part  -->
<!-- of a panel of a "sidebyside", can be given horizontal layout  -->
<!-- control.  This is placed on a constraining "div.image-box"    -->
<!-- via the "@style" attribute.  The image simply "grows" to      -->
<!-- fill this box horizontally, with necessary vertical dimension -->
<!-- to preserve the aspect ratio.  This div is also used to       -->
<!-- provide vertical spacing from its surroundings.               -->
<xsl:template match="image[not(ancestor::sidebyside)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <!-- div is constraint/positioning for contained image -->
    <div class="image-box">
        <xsl:attribute name="style">
            <xsl:text>width: </xsl:text>
            <xsl:value-of select="$layout/width"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-left: </xsl:text>
            <xsl:value-of select="$layout/left-margin"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-right: </xsl:text>
            <xsl:value-of select="$layout/right-margin"/>
            <xsl:text>%;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="image-inclusion"/>
    </div>
</xsl:template>

<!-- The div for a panel of a sidebyside will provide  -->
<!-- the constraint/positioning of the contained image -->
<!-- If the panel is a PTX "figure" then there will be -->
<!-- an intermediate HTML "figure" which will not      -->
<!-- interfere with the panel's constraints            -->
<xsl:template match="image[ancestor::sidebyside]">
    <xsl:apply-templates select="." mode="image-inclusion" />
</xsl:template>

<!-- With a @source attribute, without an extension, -->
<!--   we presume an SVG has been manufactured       -->
<!-- With a @source attribute, with an extension,    -->
<!--   we write an HTML "img" tag with attributes    -->
<xsl:template match="image[@source]" mode="image-inclusion">
    <!-- condition on file extension -->
    <!-- no period, lowercase'ed     -->
    <xsl:variable name="extension">
        <xsl:call-template name="file-extension">
            <xsl:with-param name="filename" select="@source" />
        </xsl:call-template>
    </xsl:variable>
    <!-- location of image, based on configured directory in publisher file -->
    <xsl:variable name="location" select="concat($external-directory, @source)"/>
    <xsl:choose>
        <!-- no extension, presume SVG provided as external image -->
        <xsl:when test="$extension=''">
            <xsl:call-template name="svg-wrapper">
                <xsl:with-param name="svg-filename">
                    <xsl:value-of select="$location"/>
                    <xsl:text>.svg</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="png-fallback-filename" />
                <xsl:with-param name="image-width">
                    <xsl:apply-templates select="." mode="get-width-percentage" />
                </xsl:with-param>
                <xsl:with-param name="image-description">
                    <xsl:apply-templates select="description" />
                </xsl:with-param>
            </xsl:call-template>
            <!-- possibly annotate with archive links -->
            <xsl:apply-templates select="." mode="archive">
                <xsl:with-param name="base-pathname" select="$location"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- with extension, just include it -->
        <xsl:otherwise>
            <img>
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                </xsl:attribute>
                <xsl:attribute name="class">
                    <xsl:text>contained</xsl:text>
                </xsl:attribute>
                <!-- alt attribute for accessibility -->
                <xsl:attribute name="alt">
                    <xsl:apply-templates select="description" />
                </xsl:attribute>
            </img>
            <!-- possibly annotate with archive links -->
            <xsl:apply-templates select="." mode="archive">
                <xsl:with-param name="base-pathname">
                    <xsl:value-of select="$external-directory"/>
                    <xsl:call-template name="substring-before-last">
                        <xsl:with-param name="input" select="$location" />
                        <xsl:with-param name="substr" select="'.'" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- SVG's produced by mbx script                     -->
<!--   Asymptote graphics language                    -->
<!--   LaTeX source code images                       -->
<!--   Sage graphics plots, w/ PNG fallback for 3D    -->
<!--   Match style is duplicated in mathbook-epub.xsl -->
<xsl:template match="image[latex-image]|image[sageplot]" mode="image-inclusion">
    <xsl:variable name="base-pathname">
        <xsl:value-of select="$generated-directory"/>
        <xsl:if test="$b-managed-directories">
            <xsl:choose>
                <xsl:when test="latex-image">
                    <xsl:text>latex-image/</xsl:text>
                </xsl:when>
                <xsl:when test="sageplot">
                    <xsl:text>sageplot/</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <xsl:call-template name="svg-wrapper">
        <xsl:with-param name="svg-filename" select="concat($base-pathname, '.svg')" />
        <!-- maybe empty, which is fine -->
        <xsl:with-param name="png-fallback-filename">
            <xsl:if test="sageplot">
                <xsl:value-of select="$base-pathname" />
                <xsl:text>.png</xsl:text>
            </xsl:if>
        </xsl:with-param>
        <xsl:with-param name="image-width">
            <xsl:apply-templates select="." mode="get-width-percentage" />
        </xsl:with-param>
        <xsl:with-param name="image-description">
            <xsl:apply-templates select="description" />
        </xsl:with-param>
    </xsl:call-template>
    <!-- possibly annotate with archive links -->
    <xsl:apply-templates select="." mode="archive">
        <xsl:with-param name="base-pathname" select="$base-pathname" />
    </xsl:apply-templates>
</xsl:template>

<!-- Asymptote graphics language -->
<xsl:template match="image[asymptote]" mode="image-inclusion">
    <!-- base-pathname needed later for archive link production -->
    <xsl:variable name="base-pathname">
        <xsl:value-of select="$generated-directory"/>
        <xsl:if test="$b-managed-directories">
            <xsl:text>asymptote/</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <xsl:variable name="html-filename" select="concat($base-pathname, '.html')" />

    <!-- Assumes filename is relative to primary source file, -->
    <!-- which must be specified with the original version,   -->
    <!-- not the pre-processed, "assembled" version           -->
    <xsl:variable name="image-xml" select="document($html-filename, $original)"/>
    <!-- width first -->
    <xsl:variable name="width">
        <xsl:choose>
            <!-- 2-D diagram -->
            <!-- note necessity of namespace for "svg" element -->
            <xsl:when test="$image-xml/html/body/svg:svg">
                <xsl:variable name="wpt" select="$image-xml/html/body/svg:svg/@width"/>
                <!-- Strip "pt" suffix -->
                <xsl:value-of select="substring($wpt, 1, string-length($wpt) - 2)"/>
            </xsl:when>
            <!-- 3-D diagram -->
            <xsl:when test="$image-xml/html/body/canvas">
                <xsl:value-of select="$image-xml/html/body/canvas/@width"/>
            </xsl:when>
            <!-- failure -->
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   the Asympote diagram produced in "<xsl:value-of select="$html-filename"/>" needs to be available relative to the primary source file, or if available it is perhaps ill-formed and its width cannot be determined (which you might report as a bug).  We might be able to procede as if the diagram is square, but results can be unpredictable.</xsl:message>
                <!-- reasonable guess at points/pixels -->
                <xsl:text>400</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- now height, similarly -->
    <xsl:variable name="height">
        <xsl:choose>
            <!-- 2-D diagram -->
            <!-- note necessity of namespace for "svg" element -->
            <xsl:when test="$image-xml/html/body/svg:svg">
                <xsl:variable name="hpt" select="$image-xml/html/body/svg:svg/@height"/>
                <!-- Strip "pt" suffix -->
                <xsl:value-of select="substring($hpt, 1, string-length($hpt) - 2)"/>
            </xsl:when>
            <!-- 3-D diagram -->
            <xsl:when test="$image-xml/html/body/canvas">
                <xsl:value-of select="$image-xml/html/body/canvas/@height"/>
            </xsl:when>
            <!-- failure -->
            <xsl:otherwise>
                <xsl:message>PTX:ERROR:   the Asympote diagram produced in "<xsl:value-of select="$html-filename"/>" needs to be available relative to the primary source file, or if available it is perhaps ill-formed and its height cannot be determined (which you might report as a bug).  We might be able to procede as if the diagram is square, but results can be unpredictable.</xsl:message>
                <!-- reasonable guess at points/pixels -->
                <xsl:text>400</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- All that was to get an aspect-ratio for a responsive iframe embedding -->
    <xsl:variable name="aspect-percent" select="($height div $width) * 100"/>

    <!-- Surrounding/constraining "image", or "sidebyside" panel, or ...    -->
    <!-- will provide an overall width.  The "padding-top" property is what -->
    <!-- makes the right shape.  CSS provides some constant properties.     -->
    <div class="asymptote-box" style="padding-top: {$aspect-percent}%">
        <iframe src="{$html-filename}" class="asymptote"/>
    </div>
    <!-- possibly annotate with archive links -->
    <xsl:apply-templates select="." mode="archive">
        <xsl:with-param name="base-pathname" select="$base-pathname" />
    </xsl:apply-templates>
</xsl:template>

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
    <img>
        <!-- source file attribute for img element, the SVG image -->
        <xsl:attribute name="src">
            <xsl:value-of select="$svg-filename" />
        </xsl:attribute>
        <!-- For accessibility use an ARIA role, e.g so screen  -->
        <!-- readers do not try to read the elements of the SVG -->
        <!-- NB: if we write SVG into the page, put this        -->
        <!-- attribute onto the "svg" element                   -->
        <xsl:attribute name="role">
            <xsl:text>img</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>contained</xsl:text>
        </xsl:attribute>
        <!-- alt attribute for accessibility -->
        <xsl:attribute name="alt">
            <xsl:value-of select="$image-description" />
        </xsl:attribute>
        <!-- PNG fallback, if available                                     -->
        <!-- https://www.envano.com/2014/04/using-svg-images-in-responsive- -->
        <!-- websites-with-a-fallback-for-browsers-not-supporting-svg/      -->
        <xsl:if test="not($png-fallback-filename = '')">
            <xsl:attribute name="onerror">
                <xsl:text>this.src='</xsl:text>
                <xsl:value-of select="$png-fallback-filename" />
                <xsl:text>';this.onerror=null;</xsl:text>
            </xsl:attribute>
        </xsl:if>
    </img>
</xsl:template>

<!-- Image Archives -->
<!-- Under an image provide a set of (download) links              -->
<!-- for archival versions of the image in different formats       -->
<!--                                                               -->
<!-- 1.  @archive is a space-delimited list of file suffixes       -->
<!-- 2.  Author must ensure the versions are next to file employed -->
<!-- 3.  Formatting and case of suffixes is author's choice        -->
<!-- 4.  Order in suffix list is respected in output               -->
<!-- 5.  Per-image, with global spec in "docinfo/images/archive"   -->
<!--                                                               -->
<!-- The originating image template knows/computes the filename,   -->
<!-- so this template accepts the filename, sans period and        -->
<!-- extension, to transmit to the actual link production where    -->
<!-- different extensions are added                                -->
<!--                                                               -->
<xsl:template match="image" mode="archive">
    <xsl:param name="base-pathname" />
    <!-- Determine requested archive links            -->
    <!-- Local request on image overrides global      -->
    <!-- If $formats ends empty, then nothing happens -->
    <xsl:variable name="formats">
        <xsl:choose>
            <!-- local, given on image, including suppression -->
            <xsl:when test="@archive">
                <xsl:value-of select="normalize-space(@archive)" />
            </xsl:when>
            <!-- semi-local, semi-global via subtree specification     -->
            <!-- last in list that contains the image wins             -->
            <!-- Documented heavily as first "mid-range" specification -->
            <!-- A single @from puts us in mid-range mode              -->
            <xsl:when test="$docinfo/images/archive[@from]">
                <!-- context of next "select" filters is "archive" -->
                <!-- so save off the present context, the "image"  -->
                <xsl:variable name="the-image" select="." />
                <!-- Filter all of the "archive" in docinfo with @from      -->
                <!-- Subset occurs in document order                        -->
                <!-- Form two subtrees of all desendant nodes, rooted at    -->
                <!--   (1) the image node                                   -->
                <!--   (2) the node pointed to by @from                     -->
                <!-- The pipe forms a union of the nodes in the subtrees    -->
                <!-- "image" is on the subtree @from iff union is no larger -->
                <xsl:variable name="containing-archives"
                    select="$docinfo/images/archive[@from][count($the-image/descendant-or-self::node()|id(@from)/descendant-or-self::node())=count(id(@from)/descendant-or-self::node())]" />
                <!-- We mimic XSL and the last applicable "archive" is effective -->
                <!-- This way, big subtrees go first, included subtrees refine   -->
                <!-- @from can be an empty string and turn off the behavior      -->
                <!-- We grab the content of the last "archive" to be the formats -->
                <xsl:value-of select="$containing-archives[last()]/." />
            </xsl:when>
            <!-- global, presumes one only, ignores subtree versions -->
            <xsl:when test="$docinfo/images/archive[not(@from)]">
                <xsl:value-of select="normalize-space($docinfo/images/archive)" />
            </xsl:when>
            <!-- nothing begets nothing -->
            <xsl:otherwise />
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="not($formats = '')">
        <!-- Build the links with recursion through formats    -->
        <!-- First wrap resulting links in overall styling div -->
        <xsl:element name="div">
            <xsl:attribute name="class">
                <xsl:text>image-archive</xsl:text>
            </xsl:attribute>
            <!-- Add trailing space as marker for recursion finale -->
            <xsl:call-template name="archive-links">
                <xsl:with-param name="base-pathname" select="$base-pathname" />
                <xsl:with-param name="formats" select="concat($formats, ' ')" />
            </xsl:call-template>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- $base-pathname has no concluding -->
<!-- period, so we add it here        -->
<xsl:template name="archive-links">
    <xsl:param name="base-pathname" />
    <xsl:param name="formats" />
    <!-- stop recursion if empty (note extra space added in initial call) -->
    <xsl:if test="not($formats = '')">
        <xsl:variable name="next-format" select="substring-before($formats, ' ')" />
        <xsl:variable name="remaining-formats" select="substring-after($formats, ' ')" />
        <!-- link to the file, author's responsibility  -->
        <!-- add period, and the suffix to rest of path -->
        <!-- text of link is the format suffix verbatim -->
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:value-of select="$base-pathname" />
                <xsl:text>.</xsl:text>
                <xsl:value-of select="$next-format" />
            </xsl:attribute>
            <xsl:value-of select="$next-format" />
        </xsl:element>
        <!-- recurse through remaining formats -->
        <xsl:call-template name="archive-links">
            <xsl:with-param name="base-pathname" select="$base-pathname" />
            <xsl:with-param name="formats" select="$remaining-formats" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>


<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- See xsl/pretext-common.xsl for descriptions of the  -->
<!-- four modal templates which must be implemented here  -->
<!-- The main templates for "sidebyside" and "sbsgroup"   -->
<!-- are in xsl/pretext-common.xsl, as befits containers -->

<!-- When we use CSS margins (or padding), then percentage        -->
<!-- widths are relative to the remaining space.  This utility    -->
<!-- takes in a width relative to full-text-width and the margins -->
<!-- (both with "%" attached) and returns the larger percentage   -->
<!-- of the remaining space.                                      -->
<xsl:template name="relative-width">
    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:value-of select="(100 * substring-before($width, '%')) div (100 - substring-before($left-margin, '%') - substring-before($right-margin, '%'))" />
    <xsl:text>%</xsl:text>
</xsl:template>



<!-- generic "panel-panel" template            -->
<!-- makes a "sbspanel" div of specified width -->
<!-- calls modal "panel-html-box" for contents -->
<!-- fixed-width class is additional           -->
<xsl:template match="*" mode="panel-panel">
    <xsl:param name="b-original" select="true()" />

    <xsl:param name="width" />
    <xsl:param name="left-margin" />
    <xsl:param name="right-margin" />
    <xsl:param name="valign" />
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sbspanel</xsl:text>
            <xsl:if test="self::table or self::tabular">
                <xsl:text> fixed-width</xsl:text>
            </xsl:if>
            <!-- assumes "sbspanel" class set vertical direction -->
            <!-- the CSS class equals the source attribute, but that may change -->
            <xsl:choose>
                <xsl:when test="$valign = 'top'">
                    <xsl:text> top</xsl:text>
                </xsl:when>
                <xsl:when test="$valign = 'middle'">
                    <xsl:text> middle</xsl:text>
                </xsl:when>
                <xsl:when test="$valign = 'bottom'">
                    <xsl:text> bottom</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:call-template name="relative-width">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="left-margin"  select="$left-margin" />
                <xsl:with-param name="right-margin" select="$right-margin" />
            </xsl:call-template>
            <xsl:text>;</xsl:text>
            <xsl:if test="$sbsdebug">
                <xsl:text>box-sizing: border-box;</xsl:text>
                <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                <xsl:text>border: 2px solid black;</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <!-- Realize each panel's object -->
        <xsl:apply-templates select=".">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="width" select="$width" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- We take in all three rows and package       -->
<!-- them up inside an overriding "sidebyside"   -->
<!-- div containing three "sbsrow" divs.  Purely -->
<!--  a container, never a target, so no xml:id  -->
<!-- in source, so no HTML id on div.sidebyside  -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="panels" />

    <xsl:variable name="left-margin"  select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />

    <!-- A "sidebyside" div, to contain headings,  -->
    <!-- panels, captions rows as "sbsrow" divs -->
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>sidebyside</xsl:text>
        </xsl:attribute>
        <xsl:if test="$sbsdebug">
            <xsl:attribute name="style">
                <xsl:text>box-sizing: border-box;</xsl:text>
                <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                <xsl:text>border: 2px solid purple;</xsl:text>
            </xsl:attribute>
        </xsl:if>

        <!-- Panels in an "sbsrow" div, always -->
        <xsl:element name="div">
            <xsl:attribute name="class">
                <xsl:text>sbsrow</xsl:text>
            </xsl:attribute>
            <!-- margins are custom from source -->
            <xsl:attribute name="style">
                <xsl:text>margin-left:</xsl:text>
                <xsl:value-of select="$left-margin" />
                <xsl:text>;</xsl:text>
                <xsl:text>margin-right:</xsl:text>
                <xsl:value-of select="$right-margin" />
                <xsl:text>;</xsl:text>
                <xsl:if test="$sbsdebug">
                    <xsl:text>box-sizing: border-box;</xsl:text>
                    <xsl:text>-moz-box-sizing: border-box;</xsl:text>
                    <xsl:text>-webkit-box-sizing: border-box;</xsl:text>
                    <xsl:text>border: 2px solid green;</xsl:text>
                    <xsl:text>background: LightGray;</xsl:text>
                    <xsl:text>background-clip: content-box;</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:copy-of select="$panels" />
        </xsl:element>

    </xsl:element>
</xsl:template>


<!-- ############# -->
<!-- Audio & Video -->
<!-- ############# -->

<!-- Audio and video are similar enough that we share    -->
<!-- some routines under the general heading of "media", -->
<!-- or else we present them here alongside, due to the  -->
<!-- similarities.                                       -->

<xsl:template match="video">
    <!-- This is an RTF of the object, it is important that it returns -->
    <!-- 100% width as default, so when the object is in an enclosing  -->
    <!-- "sidebyside" only the @aspect is on the object and hence a    -->
    <!-- $layout/height is computed properly.                          -->
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters">
            <xsl:with-param name="default-aspect" select="'16:9'"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <!-- div is constraint/positioning for contained video   -->
    <!-- Use of "padding-top" for responsive iframes is from -->
    <!-- https://davidwalsh.name/responsive-iframes          -->
    <div class="video-box">
        <xsl:attribute name="style">
            <xsl:text>width: </xsl:text>
            <xsl:value-of select="$layout/width"/>
            <xsl:text>%;</xsl:text>
            <!-- surrogate for height, except on Runestone -->
            <xsl:if test="not($b-host-runestone and @youtube)">
                <xsl:text>padding-top: </xsl:text>
                <xsl:value-of select="$layout/height"/>
                <xsl:text>%;</xsl:text>
            </xsl:if>
            <xsl:text> margin-left: </xsl:text>
            <xsl:value-of select="$layout/left-margin"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-right: </xsl:text>
            <xsl:value-of select="$layout/right-margin"/>
            <xsl:text>%;</xsl:text>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="$b-host-runestone and @youtube">
                <!-- we compute pixels in the parameter value -->
                <xsl:apply-templates select="." mode="runestone-youtube-embed">
                    <xsl:with-param name="width" select="($layout/width * $design-width) div 100"/>
                    <xsl:with-param name="height" select="($layout/height * $design-width) div 100"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="media-embed"/>
            </xsl:otherwise>
        </xsl:choose>
    </div>
    <!-- Always build a standalone page, PDF links to these -->
    <xsl:apply-templates select="." mode="media-standalone-page" />
</xsl:template>

<xsl:template match="audio">
    <!-- This is an RTF of the object, it is important that it returns -->
    <!-- 100% width as default, so when the object is in an enclosing  -->
    <!-- "sidebyside" it fills the panel.                              -->
    <!-- Note: we may want to support images as posters, so we may  -->
    <!-- want to support an aspect-ratio, or perhaps the image will -->
    <!-- define the size?                                           -->
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters"/>
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <!-- div is constraint/positioning for contained audio -->
    <div class="audio-box">
        <xsl:attribute name="style">
            <xsl:text>width: </xsl:text>
            <xsl:value-of select="$layout/width"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-left: </xsl:text>
            <xsl:value-of select="$layout/left-margin"/>
            <xsl:text>%;</xsl:text>
            <xsl:text> margin-right: </xsl:text>
            <xsl:value-of select="$layout/right-margin"/>
            <xsl:text>%;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="media-embed"/>
    </div>
    <!-- Always build a standalone page, PDF links to these -->
    <xsl:apply-templates select="." mode="media-standalone-page" />
</xsl:template>

<!-- Formerly a "pop-out" page, now a "standalone" page     -->
<!-- Has autoplay on since a reader has elected to go there -->
<!-- TODO: override preview, since it just plays, pass 'default -->
<xsl:template match="audio|video" mode="media-standalone-page">
    <xsl:apply-templates select="." mode="standalone-page">
        <xsl:with-param name="content">
            <!-- display preview, and enable autoplay  -->
            <!-- since reader has elected this page    -->
            <div style="text-align: center;">Reloading this page will reset a start location</div>
            <div>
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="self::audio">
                            <xsl:text>audio-box</xsl:text>
                        </xsl:when>
                        <xsl:when test="self::video">
                            <xsl:text>video-box</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:text>100%;</xsl:text>
                    <xsl:if test="self::video">
                        <xsl:variable name="rtf-layout">
                            <xsl:apply-templates select="." mode="layout-parameters">
                                <xsl:with-param name="default-aspect" select="'16:9'"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
                        <!-- get back the aspect ratio via height and width of layout, -->
                        <!-- which are both defined for a video (but not an audio)     -->
                        <!-- Pairs with 100% width above                               -->
                        <xsl:variable name="height-percent" select="100 * ($layout/height div $layout/width)"/>
                        <xsl:text>padding-top: </xsl:text>
                        <xsl:value-of select="$height-percent"/>
                        <xsl:text>%;</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="media-embed">
                    <xsl:with-param name="preview" select="'false'" />
                    <xsl:with-param name="autoplay" select="'true'" />
                </xsl:apply-templates>
            </div>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Use this to ensure consistency -->
<xsl:template match="*" mode="iframe-filename">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>-if.html</xsl:text>
</xsl:template>

<!-- A "Standalone" Page -->
<!-- Formerly a "pop-out" page, now a "standalone" page    -->
<!-- (A bit rough - this could be improved, consolidated)  -->
<!-- no extra libraries, no sidebar                        -->
<!-- 840px available (~900 - 2*30)                         -->
<!-- Page's  filename comes from modal template on context -->
<!-- TODO:  one page template, super-parameterized      -->
<!-- TODO:  trash navigation further in masthead        -->
<!-- TODO:  replace libraries by hooks to add some back -->
<xsl:template match="*" mode="standalone-page">
    <xsl:param name="content" select="''" />
    <xsl:variable name="filename">
        <xsl:apply-templates select="." mode="standalone-filename" />
    </xsl:variable>
    <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <xsl:call-template name="converter-blurb-html" />
        <html lang="{$document-language}"> <!-- dir="rtl" here -->
            <head>
                <title>
                    <!-- Leading with initials is useful for small tabs -->
                    <xsl:if test="$docinfo/initialism">
                        <xsl:apply-templates select="$docinfo/initialism" />
                        <xsl:text> </xsl:text>
                    </xsl:if>
                <xsl:apply-templates select="." mode="title-short" />
                </title>
                <meta name="Keywords" content="Authored in PreTeXt" />
                <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                <!-- ########################################## -->
                <!-- A variety of libraries were loaded here    -->
                <!-- Only purpose of this page is YouTube video -->
                <!-- A hook could go here for some extras       -->
                <!-- ########################################## -->
                <xsl:call-template name="mathbook-js" />
                <xsl:call-template name="knowl" />
                <xsl:call-template name="fonts" />
                <xsl:call-template name="css" />
                <xsl:call-template name="runestone-header"/>
                <xsl:call-template name="font-awesome" />
            </head>
            <body>
                <!-- potential document-id per-page -->
                <xsl:call-template name="document-id"/>
                <!-- the first class controls the default icon -->
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="$root/book">mathbook-book</xsl:when>
                        <xsl:when test="$root/article">mathbook-article</xsl:when>
                    </xsl:choose>
                    <!-- ################################################# -->
                    <!-- This is how the left sidebar goes away            -->
                    <!-- <xsl:if test="$b-has-toc">                        -->
                    <!--    <xsl:text> has-toc has-sidebar-left</xsl:text> -->
                    <!-- </xsl:if>                                         -->
                    <!-- ################################################# -->
                </xsl:attribute>
                <!-- assistive "Skip to main content" link    -->
                <!-- this *must* be first for maximum utility -->
                <xsl:call-template name="skip-to-content-link" />
                <xsl:call-template name="latex-macros" />
                 <header id="masthead" class="smallbuttons">
                    <div class="banner">
                        <div class="container">
                            <xsl:call-template name="brand-logo" />
                            <div class="title-container">
                                <h1 class="heading">
                                    <xsl:variable name="root-filename">
                                        <xsl:apply-templates select="$document-root" mode="containing-filename" />
                                    </xsl:variable>
                                    <a href="{$root-filename}">
                                        <xsl:variable name="b-has-subtitle" select="boolean($document-root/subtitle)"/>
                                        <span class="title">
                                            <!-- Do not use shorttitle in masthead,  -->
                                            <!-- which is much like cover of a book  -->
                                            <xsl:apply-templates select="$document-root" mode="title-simple" />
                                            <xsl:if test="$b-has-subtitle">
                                                <xsl:text>:</xsl:text>
                                            </xsl:if>
                                        </span>
                                        <xsl:if test="$b-has-subtitle">
                                            <xsl:text> </xsl:text>
                                            <span class="subtitle">
                                                <xsl:apply-templates select="$document-root" mode="subtitle" />
                                            </span>
                                        </xsl:if>
                                    </a>
                                </h1>
                                <!-- Serial list of authors/editors -->
                                <p class="byline">
                                    <xsl:apply-templates select="$document-root/frontmatter/titlepage/author" mode="name-list"/>
                                    <xsl:apply-templates select="$document-root/frontmatter/titlepage/editor" mode="name-list"/>
                                </p>
                            </div>  <!-- title-container -->
                        </div>  <!-- container -->
                    </div> <!-- banner -->
                    <!-- This seemed to not be enough, until Google Search went away  -->
                    <!-- <xsl:apply-templates select="." mode="primary-navigation" /> -->
                </header> <!-- masthead -->
                <div class="page">
                    <!-- With sidebars killed, this stuff is extraneous     -->
                    <!-- <xsl:apply-templates select="." mode="sidebars" /> -->
                    <main class="main">
                        <!-- relax the 600px width restriction, so with    -->
                        <!-- responsive videos they grow to be much bigger -->
                        <div id="content" class="pretext-content" style="max-width: 1600px">
                            <!-- This is content passed in as a parameter -->
                            <xsl:copy-of select="$content" />
                          </div>
                    </main>
                </div>
                <!-- analytics services, if requested -->
                <xsl:call-template name="statcounter"/>
                <xsl:call-template name="google-classic"/>
                <xsl:call-template name="google-universal"/>
                <xsl:call-template name="google-gst"/>
                <!-- <xsl:call-template name="pytutor-footer" /> -->
                <xsl:call-template name="extra-js-footer"/>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<xsl:template name="generic-preview-svg">
    <!-- viewbox was square (0,0), 96x96, now clipped 14 above and below                   -->
    <!-- preserveAspectRatio="none" makes it amenable to matching video it hides           -->
    <!-- SVG scaling, comprehensive: https://css-tricks.com/scale-svg/                     -->
    <!-- Accessed: 2017-08-08                                                              -->
    <!-- Page: https://commons.wikimedia.org/wiki/File:YouTube_Play_Button.svg             -->
    <!-- File: https://upload.wikimedia.org/wikipedia/commons/d/d1/YouTube_Play_Button.svg -->
    <!-- License text:  This image only consists of simple geometric shapes or text.       -->
    <!-- It does not meet the threshold of originality needed for copyright protection,    -->
    <!-- and is therefore in the public domain.                                            -->
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 14 96 68" style="cursor:pointer; position: absolute; top: 0; left: 0; width: 100%; height: 100%;" preserveAspectRatio="none">
        <path fill="#e62117" d="M94.98,28.84c0,0-0.94-6.6-3.81-9.5c-3.64-3.81-7.72-3.83-9.59-4.05c-13.4-0.97-33.52-0.85-33.52-0.85s-20.12-0.12-33.52,0.85c-1.87,0.22-5.95,0.24-9.59,4.05c-2.87,2.9-3.81,9.5-3.81,9.5S0.18,36.58,0,44.33v7.26c0.18,7.75,1.14,15.49,1.14,15.49s0.93,6.6,3.81,9.5c3.64,3.81,8.43,3.69,10.56,4.09c7.53,0.72,31.7,0.89,32.54,0.9c0.01,0,20.14,0.03,33.54-0.94c1.87-0.22,5.95-0.24,9.59-4.05c2.87-2.9,3.81-9.5,3.81-9.5s0.96-7.75,1.02-15.49v-7.26C95.94,36.58,94.98,28.84,94.98,28.84z M38.28,61.41v-27l25.74,13.5L38.28,61.41z"/>
    </svg>
</xsl:template>

<!-- Take <svg> element above, remove width and height attributes  -->
<!-- (not ever needed???), compact to one long string.             -->
<!-- URL encode via: https://meyerweb.com/eric/tools/dencoder/     -->
<!-- Then add a bit of voodoo, and this may be used as the value   -->
<!-- of the HTML5 video/@poster attribute (and other places?)      -->
<xsl:variable name="generic-preview-svg-data-uri">
    <xsl:text>data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%2014%2096%2068%22%20style%3D%22cursor%3Apointer%3B%22%20preserveAspectRatio%3D%22none%22%3E%3Cpath%20fill%3D%22%23e62117%22%20d%3D%22M94.98%2C28.84c0%2C0-0.94-6.6-3.81-9.5c-3.64-3.81-7.72-3.83-9.59-4.05c-13.4-0.97-33.52-0.85-33.52-0.85s-20.12-0.12-33.52%2C0.85c-1.87%2C0.22-5.95%2C0.24-9.59%2C4.05c-2.87%2C2.9-3.81%2C9.5-3.81%2C9.5S0.18%2C36.58%2C0%2C44.33v7.26c0.18%2C7.75%2C1.14%2C15.49%2C1.14%2C15.49s0.93%2C6.6%2C3.81%2C9.5c3.64%2C3.81%2C8.43%2C3.69%2C10.56%2C4.09c7.53%2C0.72%2C31.7%2C0.89%2C32.54%2C0.9c0.01%2C0%2C20.14%2C0.03%2C33.54-0.94c1.87-0.22%2C5.95-0.24%2C9.59-4.05c2.87-2.9%2C3.81-9.5%2C3.81-9.5s0.96-7.75%2C1.02-15.49v-7.26C95.94%2C36.58%2C94.98%2C28.84%2C94.98%2C28.84z%20M38.28%2C61.41v-27l25.74%2C13.5L38.28%2C61.41z%22%2F%3E%3C%2Fsvg%3E</xsl:text>
</xsl:variable>

<!-- LaTeX watermark uses default 5cm font which is then scaled by watermark.scale -->
<!-- We copy that here. We also copy the 45 degree angle.                          -->
<!-- Color rgb(204,204,204) matches LaTeX 80% grayscale.                           -->
<xsl:variable name="watermark-svg">
    <svg xmlns="http://www.w3.org/2000/svg" version="1.1" height="600" width="600">
        <text x="50%" y="50%" text-anchor="middle" transform="rotate(-45,300,300)" fill="rgb(204,204,204)" style="font-family:sans-serif; font-size:{5*$watermark.scale}cm;">
            <xsl:value-of select="$watermark.text"/>
        </text>
    </svg>
</xsl:variable>

<xsl:variable name="watermark-css">
    <xsl:text>background-image:url('data:image/svg+xml;utf8,</xsl:text>
    <xsl:apply-templates select="exsl:node-set($watermark-svg)" mode="serialize" />
    <xsl:text>');</xsl:text>
</xsl:variable>

<!-- NB: here, and elesewhere, references -->
<!-- to "video" should become "media"     -->
<xsl:template match="audio[@source|@href]" mode="media-embed">
    <xsl:param name="preview" select="'false'" />
    <xsl:param name="autoplay" select="'false'" />

    <xsl:variable name="location">
        <xsl:choose>
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- Now, must have a @source. For backwards -->
            <!-- compatibility, consider a @source that  -->
            <!-- really appears to be a @href. Might be  -->
            <!-- http or https.                          -->
            <xsl:when test="substring(@source,1,4) = 'http'">
                <xsl:value-of select="@source"/>
            </xsl:when>
            <!-- else a local filename in @source -->
            <xsl:otherwise>
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:element name="audio">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="html-id"/>
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>audio</xsl:text>
        </xsl:attribute>
        <!-- empty forms work as boolean switches -->
        <xsl:attribute name="controls"/>
        <xsl:if test="$autoplay = 'true'">
            <xsl:attribute name="autoplay" />
        </xsl:if>
        <!-- @poster, or equivalent does not seem trivial -->
        <!-- Construct the HTML5 source URL(s)                  -->
        <!-- If this gets refactored, it could be best to form  -->
        <!-- base, extension, query, fragment strings/variables -->
        <!-- First, grab extension of source URL in PTX @source -->
        <xsl:variable name="extension">
            <xsl:call-template name="file-extension">
                <xsl:with-param name="filename" select="$location" />
            </xsl:call-template>
        </xsl:variable>
        <!-- "source" elements, children of HTML5 audio -->
        <!-- no extension suggests hosting has multiple -->
        <!-- versions for browser to sort through       -->
        <!-- More open formats first!  ;-)              -->
        <xsl:if test="$extension = '' or $extension = 'ogg'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.ogg</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>audio/ogg</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'mp3'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.mp3</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>audio/mp3</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'wav'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.wav</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>audio/wav</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <!-- failure to perform -->
        <xsl:text>Your browser does not support the &lt;audio&gt; tag.</xsl:text>
    </xsl:element>
</xsl:template>

<!-- create a "video" element for author-hosted   -->
<!-- dimensions and autoplay as parameters        -->
<!-- Normally $preview is true, and not passed in -->
<!-- 'false' is an override for standalone pages  -->
<xsl:template match="video[@source|@href]" mode="media-embed">
    <xsl:param name="preview" select="'true'" />
    <xsl:param name="autoplay" select="'false'" />

    <xsl:variable name="location">
        <xsl:choose>
            <xsl:when test="@href">
                <xsl:value-of select="@href"/>
            </xsl:when>
            <!-- Now, must have a @source. For backwards -->
            <!-- compatibility, consider a @source that  -->
            <!-- really appears to be a @href. Might be  -->
            <!-- http or https.                          -->
            <xsl:when test="substring(@source,1,4) = 'http'">
                <xsl:value-of select="@source"/>
            </xsl:when>
            <!-- else a local filename in @source -->
            <xsl:otherwise>
                <xsl:value-of select="$external-directory"/>
                <xsl:value-of select="@source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>


    <!-- we need to build the element, since @autoplay is optional -->
    <xsl:element name="video">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="html-id"/>
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>video</xsl:text>
        </xsl:attribute>
        <!-- empty forms work as boolean switches -->
        <xsl:attribute name="controls" />
        <xsl:if test="$autoplay = 'true'">
            <xsl:attribute name="autoplay" />
        </xsl:if>
        <!-- Optionally cover up with HTML5 @poster via PTX @preview -->
        <xsl:if test="($preview = 'true') and @preview and not(@preview = 'default')">
            <xsl:attribute name="poster">
                <xsl:choose>
                    <xsl:when test="@preview = 'generic'">
                        <xsl:value-of select="$generic-preview-svg-data-uri" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@preview" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
        <!-- Construct the HTML5 source URL(s)                  -->
        <!-- If this gets refactored, it could be best to form  -->
        <!-- base, extension, query, fragment strings/variables -->
        <!-- First, grab extension of source URL in PTX @source -->
        <xsl:variable name="extension">
            <xsl:call-template name="file-extension">
                <xsl:with-param name="filename" select="$location" />
            </xsl:call-template>
        </xsl:variable>
        <!-- "source" elements, children of HTML5 video -->
        <!-- no extension suggests hosting has multiple -->
        <!-- versions for browser to sort through       -->
        <!-- More open formats first!  ;-)              -->
        <xsl:if test="$extension = '' or $extension = 'ogv'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.ogv</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/ogg</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'webm'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.webm</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/webm</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:if test="$extension = '' or $extension = 'mp4'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.mp4</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/mp4</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <!-- 2007: *.oog officially replaced by *.ogv    -->
        <!-- 2018-04-01: we supported *.oog for video at -->
        <!--    91028991e081d2c933d46d3ce5d4d1cb6759c0bf -->
        <!-- 2020-07-05: demoted, but continue support   -->
        <xsl:if test="$extension = '' or $extension = 'oog'">
            <xsl:element name="source">
                <xsl:attribute name="src">
                    <xsl:value-of select="$location"/>
                    <!-- augment no-extension form -->
                    <xsl:if test="$extension = ''">
                        <xsl:text>.ogg</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="temporal-fragment"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                    <xsl:text>video/ogg</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <!-- failure to perform -->
        <xsl:text>Your browser does not support the &lt;video&gt; tag.</xsl:text>
        <xsl:apply-templates select="track"/>
    </xsl:element>
</xsl:template>


<!-- This an optional component of an author-hosted video, -->
<!-- and the markup closely tracks the generated HTML.     -->
<!-- The HTML @default attribute functions simply by being -->
<!-- present, so we do not provide a value.                -->
<xsl:template match="track">
    <xsl:variable name="location" select="concat($external-directory, @source)"/>

    <track>
        <xsl:if test="@default='yes'">
            <xsl:attribute name="default"/>
        </xsl:if>
        <xsl:attribute name="label">
            <xsl:value-of select="@label"/>
        </xsl:attribute>
        <xsl:attribute name="kind">
            <xsl:value-of select="@kind"/>
        </xsl:attribute>
        <xsl:attribute name="srclang">
            <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:value-of select="$location"/>
        </xsl:attribute>
    </track>
</xsl:template>

<!-- HTML5 Media Fragment URI (shared for audio, video)       -->
<!-- start/end times (read both, see 4.1, 4.2.1 at w3.org)    -->
<!-- Media Fragment URI: https://www.w3.org/TR/media-frags/   -->
<!-- Javascript: https://stackoverflow.com/questions/11212715 -->
<!-- return is possibly empty, so no harm using that later    -->
<!-- This portion of URL should follow any query string       -->
<xsl:template match="audio|video" mode="temporal-fragment">
    <xsl:if test="@start or @end">
        <xsl:text>#t=</xsl:text>
    </xsl:if>
    <xsl:if test="@start">
        <xsl:value-of select="@start" />
    </xsl:if>
    <!-- can lead with comma, implies 0,xx -->
    <xsl:if test="@end">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="@end" />
    </xsl:if>
</xsl:template>

<!-- You Tube, Vimeo -->
<!-- Better sizing would require CSS classes (16:9, 4:3?)                      -->
<!-- https://css-tricks.com/NetMag/FluidWidthVideo/Article-FluidWidthVideo.php -->

<!-- Configurable options, we are considering academic uses                       -->
<!-- https://developers.google.com/youtube/player_parameters#Manual_IFrame_Embeds -->
<!-- hl parameter for language seems superfluous, user settings override          -->
<!-- something to do with cross-domain scripting security?                        -->
<!-- <xsl:text>&amp;origin=http://example.com</xsl:text>                          -->
<!-- start/end time parameters                                                    -->

<!-- create iframe embedded video                     -->
<!-- dimensions and autoplay as parameters            -->
<!-- Normally $preview is true, and not passed in     -->
<!-- 'false' is an override for standalone pages      -->
<!-- Templates, on a per-service basis, supply a URL, -->
<!-- and any attributes on the "iframe" element which -->
<!-- are not shared                                   -->
<xsl:template match="video[@youtube|@youtubeplaylist|@vimeo]" mode="media-embed">
    <xsl:param name="preview" select="'true'" />
    <xsl:param name="autoplay" select="'false'" />

    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <xsl:variable name="source-url">
        <xsl:apply-templates select="." mode="video-embed-url">
            <xsl:with-param name="autoplay" select="$autoplay" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="source-url-autoplay-on">
        <xsl:apply-templates select="." mode="video-embed-url">
            <xsl:with-param name="autoplay">
                <xsl:choose>
                    <!-- the YouTube autoplay won't wait for the poster -->
                    <!-- to be withdrawn, so two clicks are needed,     -->
                    <!-- perhaps this is true of *all* services?        -->
                    <xsl:when test="@youtube|@youtubeplaylist">
                        <xsl:text>false</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>true</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:variable>
    <!-- allowfullscreen is an iframe parameter,   -->
    <!-- not a video-embedding parameter, but it's -->
    <!-- use enables the "full screen" button      -->
    <!-- http://w3c.github.io/test-results/html51/implementation-report.html -->
    <xsl:choose>
        <xsl:when test="($preview = 'true') and @preview and not(@preview = 'default')">
            <!-- hide behind a preview image, code from post at -->
            <!-- https://stackoverflow.com/questions/7199624    -->
            <div onclick="this.nextElementSibling.style.display='block'; this.style.display='none'">
                <xsl:choose>
                    <xsl:when test="@preview = 'generic'">
                        <xsl:call-template name="generic-preview-svg"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <img src="{@preview}" class="video-poster"
                            alt="Video cover image"/>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
            <div class="hidden-content">
                <!-- Hidden content in here                   -->
                <!-- Turn autoplay on, else two clicks needed -->
                <iframe id="{$hid}" class="video" 
                    allowfullscreen="" src="{$source-url-autoplay-on}">
                    <xsl:apply-templates select="." mode="video-iframe-attributes">
                        <xsl:with-param name="autoplay" select="'true'"/>
                    </xsl:apply-templates>
                </iframe>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <iframe id="{$hid}"  class="video"
                allowfullscreen="" src="{$source-url}">
                <xsl:apply-templates select="." mode="video-iframe-attributes">
                    <xsl:with-param name="autoplay" select="$autoplay"/>
                </xsl:apply-templates>
            </iframe>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Special for YouTube API setup on Runestone  -->
<!-- Uses pixels (to match containing video-box) -->
<!-- so is exceptional and featureless           -->
<!-- TODO: are start/end attributes useful?      -->
<xsl:template match="video[@youtube]" mode="runestone-youtube-embed">
    <xsl:param name="width"/>
    <xsl:param name="height"/>

    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>

    <div id="{$hid}" data-component="youtube" class="align-left youtube-video"
         data-video-height="{$height}" data-video-width="{$width}"
         data-video-videoid="{@youtube}" data-video-divid="{$hid}"
         data-video-start="0" data-video-end="-1"/>
</xsl:template>

<!-- Creates a YouTube URL for embedding for use in an iframe -->
<!-- Autoplay option is conveyed in the URL query options     -->
<!-- Autoplay is for popout, otherwise not                    -->
<xsl:template match="video[@youtube|@youtubeplaylist]" mode="video-embed-url">
    <xsl:param name="autoplay" select="'false'" />
    <xsl:variable name="youtube">
        <xsl:choose>
            <!-- forgive an author's leading or trailing space -->
            <xsl:when test="@youtubeplaylist">
                <xsl:value-of select="normalize-space(@youtubeplaylist)" />
            </xsl:when>
            <!-- replace commas with spaces then normalize space    -->
            <!-- result is a trim space-separated list of video IDs -->
            <xsl:otherwise>
                <xsl:value-of select="normalize-space(str:replace(@youtube, ',', ' '))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$b-video-privacy">
            <xsl:text>https://www.youtube-nocookie.com/embed</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>https://www.youtube.com/embed</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
        <!-- playlist with a YouTube ID -->
        <xsl:when test="@youtubeplaylist">
            <xsl:text>?listType=playlist&amp;list=</xsl:text>
            <xsl:value-of select="$youtube" />
        </xsl:when>
        <!-- if we get this far there must be a @youtube -->
        <!-- and $youtube is one or more video IDs       -->
        <xsl:when test="contains($youtube, ' ')">
            <xsl:text>?playlist=</xsl:text>
            <xsl:value-of select="str:replace($youtube, ' ', ',')" />
        </xsl:when>
        <!-- a single video ID -->
        <xsl:otherwise>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$youtube" />
            <xsl:text>?</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- use &amp; separator for remaining options -->
    <xsl:text>&amp;modestbranding=1</xsl:text>
    <!-- kill related videos at end -->
    <xsl:text>&amp;rel=0</xsl:text>
    <!-- start and end times; for a playlist these are applied to first video -->
    <xsl:if test="@start">
        <xsl:text>&amp;start=</xsl:text>
        <xsl:value-of select="@start" />
    </xsl:if>
    <xsl:if test="@end">
        <xsl:text>&amp;end=</xsl:text>
        <xsl:value-of select="@end" />
    </xsl:if>
    <!-- default autoplay is 0, don't -->
    <xsl:if test="$autoplay = 'true'">
        <xsl:text>&amp;autoplay=1</xsl:text>
    </xsl:if>
</xsl:template>

<!-- For a YouTube video, no YT-specific options come in the attributes -->
<xsl:template match="video[@youtube|@youtubeplaylist]" mode="video-iframe-attributes"/>

<!-- Creates a Vimeo URL for embedding, typically in an iframe  -->
<xsl:template match="video[@vimeo]" mode="video-embed-url">
    <xsl:param name="autoplay" select="'false'" />
    <xsl:text>https://player.vimeo.com/video/</xsl:text>
    <xsl:value-of select="@vimeo"/>
    <xsl:text>?color=ffffff</xsl:text>
    <!-- use &amp; separator for remaining options -->
    <!-- default autoplay is 0, don't -->
    <xsl:if test="$autoplay = 'true'">
        <xsl:text>&amp;autoplay=1</xsl:text>
    </xsl:if>
</xsl:template>

<!-- These are additional attributes on the "iframe" which seem specific to Vimeo -->
<!-- N.B. the autoplay seems ineffective                                          -->
<xsl:template match="video[@vimeo]" mode="video-iframe-attributes">
    <xsl:param name="autoplay" select="'false'" />

    <xsl:attribute name="frameborder">
        <xsl:text>0</xsl:text>
    </xsl:attribute>
    <xsl:attribute name="allow">
        <xsl:if test="$autoplay = 'true'">
            <xsl:text>autoplay; </xsl:text>
        </xsl:if>
        <xsl:text>fullscreen</xsl:text>
    </xsl:attribute>
</xsl:template>

<!-- ############ -->
<!-- Music Scores -->
<!-- ############ -->

<!-- Embed an interactive score from MuseScore                          -->
<!-- Flag: score element has two MuseScore-specific attributes          -->
<!-- https://musescore.org/user/{usernumber}/scores/{scorenumber}/embed -->
<!-- into an iframe with width and height (todo)                        -->
<xsl:template match="score[@musescoreuser and @musescore]">
    <xsl:element name="iframe">
        <xsl:attribute name="width">
            <xsl:text>100%</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="height">
            <xsl:text>500</xsl:text>
        </xsl:attribute>
        <!-- empty attribute, just switch -->
        <xsl:attribute name="allowfullscreen">
            <xsl:text></xsl:text>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:text>https://musescore.com/user/</xsl:text>
            <xsl:value-of select="@musescoreuser" />
            <xsl:text>/scores/</xsl:text>
            <xsl:value-of select="@musescore" />
            <xsl:text>/embed</xsl:text>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- ####### -->
<!-- Tabular -->
<!-- ####### -->

<!-- Top-down organization -->

<!-- A tabular layout, a naked table -->
<!-- Allowed to be placed various locations, but gets no              -->
<!-- vertical space etc, that is the container's responsibiility      -->
<!-- A sequence of rows, we ignore column group in applying templates -->
<!-- Realized as an HTML table                                        -->

<xsl:template match="tabular[not(ancestor::sidebyside)]">
    <xsl:param name="b-original" select="true()" />
    <!-- naked tabular carries its own width -->

    <xsl:choose>
        <xsl:when test="not(@margins) and (not(@width) or (@width = 'auto'))">
            <!-- the "natural width" case                       -->
            <!-- 100% width allows paragraph cells to be widest -->
            <div class="tabular-box natural-width">
                <xsl:apply-templates select="." mode="tabular-inclusion">
                    <xsl:with-param name="b-original" select="$b-original" />
                    <xsl:with-param name="width" select="'100%'" />
                </xsl:apply-templates>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="rtf-layout">
                <xsl:apply-templates select="." mode="layout-parameters"/>
            </xsl:variable>
            <xsl:variable name="layout" select="exsl:node-set($rtf-layout)"/>
            <div class="tabular-box">
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:value-of select="$layout/width"/>
                    <xsl:text>%;</xsl:text>
                    <xsl:text> margin-left: </xsl:text>
                    <xsl:value-of select="$layout/left-margin"/>
                    <xsl:text>%;</xsl:text>
                    <xsl:text> margin-right: </xsl:text>
                    <xsl:value-of select="$layout/right-margin"/>
                    <xsl:text>%;</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="tabular-inclusion">
                    <xsl:with-param name="b-original" select="$b-original"/>
                    <xsl:with-param name="width" select="concat($layout/width, '%')"/>
                </xsl:apply-templates>
            </div>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="tabular[ancestor::sidebyside]">
    <xsl:param name="b-original" select="true()" />
    <!-- sidebyside should always provide width, -->
    <!-- so no default value provided here       -->
    <xsl:param name="width"/>

    <xsl:apply-templates select="." mode="tabular-inclusion">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="width" select="$width" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="tabular" mode="tabular-inclusion">
    <xsl:param name="b-original" select="$b-original"/>
    <xsl:param name="width"  select="$width"/>

    <!-- Abort if tabular's cols have widths summing to over 100% -->
    <xsl:call-template name="cap-width-at-one-hundred-percent">
        <xsl:with-param name="nodeset" select="col/@width" />
    </xsl:call-template>

    <table class="tabular">
        <!-- If the source has a permid, then so will the HTML.  -->
        <!-- See the definition of this modal template for more. -->
        <!-- In particular, do not add an HTML id any other way. -->
        <xsl:apply-templates select="." mode="html-permid-only"/>
        <!-- We *actively* enforce header rows being (a) initial, and      -->
        <!-- (b) contiguous.  So following two-part match will do no harm  -->
        <!-- to correct source, but will definitely harm incorrect source. -->
        <xsl:apply-templates select="row[@header]">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$width" />
        </xsl:apply-templates>
        <xsl:apply-templates select="row[not(@header)]">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$width" />
        </xsl:apply-templates>
    </table>
    <!-- any footnote in a bare "tabular" can go here; if   -->
    <!-- wrapped in a PTX "table" it'll pop outside of that -->
    <xsl:apply-templates select="." mode="pop-footnote-text">
        <xsl:with-param name="b-original" select="$b-original"/>
    </xsl:apply-templates>
</xsl:template>

<!-- A row of table -->
<xsl:template match="row">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="ambient-relative-width" />

    <!-- Determine if the row is a header row -->
    <!-- and construct class names as needed  -->
    <xsl:variable name="header-row">
        <xsl:choose>
            <xsl:when test="@header = 'yes'">
                <xsl:text>header-horizontal</xsl:text>
            </xsl:when>
            <xsl:when test="@header = 'vertical'">
                <xsl:text>header-vertical</xsl:text>
            </xsl:when>
            <!-- "no" is other choice, or no attribute at all -->
            <!-- controlled by schema, so no error-check here -->
            <!-- empty implies no class attribute at all      -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:variable>

    <!-- Form the HTML table row -->
    <xsl:element name="tr">
        <!-- and a class attribute for horizontal or vertical headers -->
        <xsl:if test="not($header-row = '')">
            <xsl:attribute name="class">
                <xsl:value-of select="$header-row"/>
            </xsl:attribute>
        </xsl:if>
        <!-- Walk the cells of the row -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width">
                <xsl:value-of select="$ambient-relative-width" />
            </xsl:with-param>
            <xsl:with-param name="the-cell" select="cell[1]" />
            <xsl:with-param name="left-col" select="ancestor::tabular/col[1]" />  <!-- possibly empty -->
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<xsl:template name="row-cells">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="ambient-relative-width" />
    <xsl:param name="the-cell" />
    <xsl:param name="left-col" />
    <!-- A cell may span several columns, or default to just 1              -->
    <!-- When colspan is not trivial, we identify the col elements          -->
    <!-- for the left and right ends of the span                            -->
    <!-- When colspan is trivial, the left and right versions are identical -->
    <!-- Left is used for left border and for horizontal alignment          -->
    <!-- Right is used for right border                                     -->
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
    <!-- For a "normal" 1-column cell this variable effectively makes a copy -->
    <xsl:variable name="right-col" select="($left-col/self::*|$left-col/following-sibling::col)[position()=$column-span]" />
    <!-- Look ahead one column, anticipating recursion   -->
    <!-- but also probing for end of row (no more cells) -->
    <xsl:variable name="next-cell" select="$the-cell/following-sibling::cell[1]" />
    <xsl:variable name="next-col"  select="$right-col/following-sibling::col[1]" /> <!-- possibly empty -->
    <xsl:if test="$the-cell">
        <!-- build an HTML data cell, with CSS decorations              -->
        <!-- we set properties in various variables,                    -->
        <!-- then write them in a class attribute                       -->
        <!-- we look outward and upward for characteristics of the cell -->
        <!--                                                            -->
        <!-- horizontal alignment -->
        <xsl:variable name="alignment">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@halign">
                    <xsl:value-of select="$the-cell/@halign" />
                </xsl:when>
                <!-- parent row attribute next -->
                <xsl:when test="$the-cell/ancestor::row/@halign">
                    <xsl:value-of select="$the-cell/ancestor::row/@halign" />
                </xsl:when>
                <!-- col attribute next -->
                <xsl:when test="$left-col/@halign">
                    <xsl:value-of select="$left-col/@halign" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@halign">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@halign" />
                </xsl:when>
                <!-- HTML default is left, we write it for consistency -->
                <xsl:otherwise>
                    <xsl:text>left</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- vertical alignment -->
        <xsl:variable name="valignment">
            <xsl:choose>
                <!-- parent row attribute first -->
                <xsl:when test="$the-cell/ancestor::row/@valign">
                    <xsl:value-of select="$the-cell/ancestor::row/@valign" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@valign">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@valign" />
                </xsl:when>
                <!-- HTML default is "baseline", not supported by MBX           -->
                <!-- Instead we default to "middle" to be consistent with LaTeX -->
                <xsl:otherwise>
                    <xsl:text>middle</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- bottom borders -->
        <xsl:variable name="bottom">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@bottom">
                    <xsl:value-of select="$the-cell/@bottom" />
                </xsl:when>
                <!-- parent row attribute next -->
                <xsl:when test="$the-cell/ancestor::row/@bottom">
                    <xsl:value-of select="$the-cell/ancestor::row/@bottom" />
                </xsl:when>
                <!-- not available on columns, table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@bottom">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@bottom" />
                </xsl:when>
                <!-- default is none -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- right borders -->
        <xsl:variable name="right">
            <xsl:choose>
                <!-- cell attribute first -->
                <xsl:when test="$the-cell/@right">
                    <xsl:value-of select="$the-cell/@right" />
                </xsl:when>
                <!-- not available on rows, col attribute next -->
                <xsl:when test="$right-col/@right">
                    <xsl:value-of select="$right-col/@right" />
                </xsl:when>
                <!-- table attribute last -->
                <xsl:when test="$the-cell/ancestor::tabular/@right">
                    <xsl:value-of select="$the-cell/ancestor::tabular/@right" />
                </xsl:when>
                <!-- default is none -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- left borders -->
        <xsl:variable name="left">
            <xsl:choose>
                <!-- the first cell of the row, so may have left border -->
                <xsl:when test="not($the-cell/preceding-sibling::cell)">
                    <xsl:choose>
                        <!-- row attribute first -->
                        <xsl:when test="$the-cell/ancestor::row/@left">
                            <xsl:value-of select="$the-cell/ancestor::row/@left" />
                        </xsl:when>
                        <!-- table attribute last -->
                        <xsl:when test="$the-cell/ancestor::tabular/@left">
                            <xsl:value-of select="$the-cell/ancestor::tabular/@left" />
                        </xsl:when>
                        <!-- default is none -->
                        <xsl:otherwise>
                            <xsl:text>none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- not the first cell of the row, so no left border -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- top borders -->
        <xsl:variable name="top">
            <xsl:choose>
                <!-- the first row of the table, so may have top border -->
                <!-- http://ajaxandxml.blogspot.com/2006/11/xsl-detect-first-of-type-element-in.html -->
                <xsl:when test="not($the-cell/ancestor::row/preceding-sibling::row)">
                    <xsl:choose>
                        <!-- col attribute first -->
                        <xsl:when test="$left-col/@top">
                            <xsl:value-of select="$left-col/@top" />
                        </xsl:when>
                        <!-- table attribute last -->
                        <xsl:when test="$the-cell/ancestor::tabular/@top">
                            <xsl:value-of select="$the-cell/ancestor::tabular/@top" />
                        </xsl:when>
                        <!-- default is none -->
                        <xsl:otherwise>
                            <xsl:text>none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- not the first cell of the row, so no left border -->
                <xsl:otherwise>
                    <xsl:text>none</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- a cell of a header row needs to be "th" -->
        <!-- else the HTML mark up is "td"           -->
        <!-- NB: Named templates means context is a  -->
        <!-- row, which is really wrong.  Tests      -->
        <!-- should be on  parent::row/@header       -->
        <xsl:variable name="header-row-elt">
            <xsl:choose>
                <xsl:when test="@header = 'yes'">
                    <xsl:text>th</xsl:text>
                </xsl:when>
                <xsl:when test="@header = 'vertical'">
                    <xsl:text>th</xsl:text>
                </xsl:when>
                <!-- "no" is other choice, or no attribute at all -->
                <!-- controlled by schema, so no error-check here -->
                <xsl:otherwise>
                    <xsl:text>td</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- the HTML element for the cell -->
        <xsl:element name="{$header-row-elt}">
            <!-- and the class attribute -->
            <xsl:attribute name="class">
                <!-- always write alignment, so *precede* all subsequent with a space -->
                <xsl:choose>
                    <xsl:when test="$the-cell/p and $alignment='justify'">
                        <xsl:text>j</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="halign-specification">
                            <xsl:with-param name="align" select="$alignment" />
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- vertical alignment -->
                <xsl:text> </xsl:text>
                <xsl:call-template name="valign-specification">
                    <xsl:with-param name="align" select="$valignment" />
                </xsl:call-template>
                <!-- bottom border -->
                <xsl:text> b</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$bottom" />
                </xsl:call-template>
                <!-- right border -->
                <xsl:text> r</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$right" />
                </xsl:call-template>
                <!-- left border -->
                <xsl:text> l</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$left" />
                </xsl:call-template>
                <!-- top border -->
                <xsl:text> t</xsl:text>
                <xsl:call-template name="thickness-specification">
                    <xsl:with-param name="width" select="$top" />
                </xsl:call-template>
                <!-- no wrapping unless paragraph cell -->
                <xsl:if test="not($the-cell/p)">
                    <xsl:text> lines</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:if test="not($next-cell)">
                <xsl:if test="$b-braille">
                    <xsl:attribute name="data-braille">
                        <xsl:text>last-cell</xsl:text>
                    </xsl:attribute>
                </xsl:if>
            </xsl:if>
            <xsl:if test="not($column-span = 1)">
                <xsl:attribute name="colspan">
                    <xsl:value-of select="$column-span" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$the-cell/p">
                <xsl:attribute name="style">
                    <xsl:text>max-width:</xsl:text>
                    <xsl:choose>
                        <xsl:when test="$left-col/@width">
                            <xsl:variable name="width">
                                <xsl:call-template name="normalize-percentage">
                                    <xsl:with-param name="percentage" select="$left-col/@width" />
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:value-of select="$design-width * substring-before($width, '%') div 100 * substring-before($ambient-relative-width, '%') div 100" />
                            <xsl:text>px;</xsl:text>
                        </xsl:when>
                        <!-- If there is no $left-col/@width, terminate -->
                        <xsl:otherwise>
                            <xsl:message>MBX:FATAL:   cell with a "p" element has no corresponding col element with width attribute.</xsl:message>
                            <xsl:apply-templates select="." mode="location-report" />
                            <xsl:message terminate="yes">Quitting...</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <!-- process the actual contents           -->
            <!-- condition on indicators of structure  -->
            <!-- All "line", all "p", or mixed content -->
            <!-- TODO: is it important to pass $b-original -->
            <!-- flag into template for "line" elements?   -->
            <xsl:choose>
                <xsl:when test="$the-cell/line">
                    <xsl:apply-templates select="$the-cell/line"/>
                </xsl:when>
                <xsl:when test="$the-cell/p">
                    <xsl:apply-templates select="$the-cell/p">
                        <xsl:with-param name="b-original" select="$b-original"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$the-cell">
                        <xsl:with-param name="b-original" select="$b-original"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
        <!-- recurse forward, perhaps to an empty cell -->
        <xsl:call-template name="row-cells">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="ambient-relative-width" select="$ambient-relative-width" />
            <xsl:with-param name="the-cell" select="$next-cell" />
            <xsl:with-param name="left-col" select="$next-col" />
        </xsl:call-template>
    </xsl:if>
    <!-- Arrive here only when we have no cell so      -->
    <!-- we bail out of recursion with no action taken -->
</xsl:template>

<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- Utilities are defined in xsl/pretext-common.xsl -->

<!-- "thickness-specification" : param "width"    -->
<!--     none, minor, medium, major -> 0, 1, 2, 3 -->

<!-- "halign-specification" : param "align"       -->
<!--     left, right, center -> l, c, r           -->

<!-- "valign-specification" : param "align"       -->
<!--     top, middle, bottom -> t, m, b           -->


<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- Much of the cross-reference mechanism is -->
<!-- implemented in the common routines,      -->
<!-- here we implement two abstract templates -->
<!-- which are called from those routines     -->

<!-- The "text" of a cross-reference typically   -->
<!-- includes a number and our numbering code is -->
<!-- designed to sync with LaTeX's schemes       -->

<!-- The xref-link template provides one of two types of links      -->
<!--                                                                -->
<!-- (a) a traditional HTML hyperlink, a jump to a new location     -->
<!-- (b) a knowl, aka a transclusion, which appears within the text -->
<!--                                                                -->
<!-- A hyperlink is the default. For conversions to different       -->
<!-- HTML outputs, the choice of targets appearing as knowls        -->
<!-- can be adjusted by overriding the next template                -->

<!-- This is the implementation of an abstract template, -->
<!-- to accomodate hard-coded HTML numbers and for       -->
<!-- LaTeX the \ref and \label mechanism                 -->
<xsl:template match="*" mode="xref-number">
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

<!-- One exception is a local tag on an mrow -->
<xsl:template match="mrow[@tag]" mode="xref-number">
    <xsl:apply-templates select="@tag" mode="tag-symbol" />
</xsl:template>

<!-- The second abstract template, we condition   -->
<!-- on if the link is rendered as a knowl or not -->
<!-- and then condition on the location of the    -->
<!-- actual link, which is sensitive to display   -->
<!-- math in particular                           -->
<!-- See xsl/pretext-common.xsl for more info    -->
<!-- TODO: could match on "xref" once link routines  -->
<!-- are broken into two and other uses are rearranged -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" select="/.." />
    <xsl:param name="content" select="'MISSING LINK CONTENT'"/>
    <xsl:variable name="knowl">
        <xsl:apply-templates select="$target" mode="xref-as-knowl" />
    </xsl:variable>
    <xsl:choose>
        <!-- 1st exceptional case, xref in a webwork, or in    -->
        <!-- some sort of title.  Then just parrot the content -->
        <xsl:when test="ancestor::webwork-reps|ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:value-of select="$content" />
        </xsl:when>
        <!-- 2nd exceptional case, xref in mrow of display math  -->
        <!--   with Javascript (pure HTML) we can make knowls    -->
        <!--   without Javascript (EPUB) we use plain text       -->
        <xsl:when test="parent::mrow or parent::me or parent::men">
            <xsl:apply-templates select="." mode="xref-link-display-math">
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="content" select="$content"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- usual case, always an "a" element (anchor) -->
        <xsl:otherwise>
            <xsl:element name="a">
                <!-- knowl/hyperlink variability here -->
                <xsl:choose>
                    <!-- build a modern knowl -->
                    <xsl:when test="$knowl='true'">
                        <!-- mark as duplicated content via an xref -->
                        <xsl:attribute name="class">
                            <xsl:text>xref</xsl:text>
                        </xsl:attribute>
                        <xsl:attribute name="data-knowl">
                            <xsl:apply-templates select="$target" mode="xref-knowl-filename" />
                        </xsl:attribute>
                    </xsl:when>
                    <!-- build traditional hyperlink -->
                    <xsl:otherwise>
                        <xsl:attribute name="href">
                            <xsl:apply-templates select="$target" mode="url" />
                        </xsl:attribute>
                        <!-- use a class to identify an internal link -->
                        <xsl:attribute name="class">
                            <xsl:text>internal</xsl:text>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- add HTML title attribute to the link -->
                <xsl:attribute name="title">
                    <xsl:apply-templates select="$target" mode="tooltip-text" />
                </xsl:attribute>
                <!-- link content from common template -->
                <xsl:value-of select="$content" />
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- For pure HTML we can make a true knowl or traditional link -->
<!-- when an "xref" is authored inside of a display math "mrow" -->
<!-- Requires https://pretextbook.org/js/lib/mathjaxknowl.js    -->
<!-- loaded as a MathJax extension for knowls to render         -->
<xsl:template match="*" mode="xref-link-display-math">
    <xsl:param name="target"/>
    <xsl:param name="content"/>

    <!-- this could be passed as a parameter, but -->
    <!-- we have $target anyway, so can recompute -->
    <xsl:variable name="knowl">
        <xsl:apply-templates select="$target" mode="xref-as-knowl"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$knowl='true'">
            <xsl:text>\knowl{</xsl:text>
            <xsl:apply-templates select="$target" mode="xref-knowl-filename"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>\href{</xsl:text>
            <xsl:apply-templates select="$target" mode="url"/>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="$content"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- A URL is needed various places, such as                     -->
<!--   1. xref to material larger than a knowl, e.g. a "chapter" -->
<!--   2. "in-context" link in xref-knowls                       -->
<!--   3. summary-page links                                     -->
<!--   4. many navigation devices, e.g. ToC, prev/next buttons   -->
<!-- This is strictly an HTML construction.                      -->
<!-- A containing filename, plus possibly a fragment identifier. -->
<xsl:template match="*" mode="url">
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
    <xsl:apply-templates select="." mode="containing-filename" />
    <xsl:if test="$intermediate='false' and $chunk='false'">
        <xsl:text>#</xsl:text>
        <!-- the ids on equations are manufactured -->
        <!-- by MathJax to look this way           -->
        <xsl:if test="self::men|self::mrow">
            <xsl:text>mjx-eqn:</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:if>
</xsl:template>

<!-- The @id attribute of an HTML element is critical.      -->
<!--                                                        -->
<!--   1.  Use the assigned/managed @permid so that changes -->
<!--       between editions can be shown in HTML versions   -->
<!--   2.  Author-provided @xml:id is reasonably stable     -->
<!--   3.  We manufacture a guaranteed-unique string        -->
<!--                                                        -->
<!-- Every HTML @id produced should use this template, so   -->
<!--                                                        -->
<!--   A.  URL template above has correct fragments         -->
<!--   B.  The permid-edition scheme is effective           -->
<xsl:template match="*" mode="html-id">
    <xsl:choose>
        <!-- primary version, as described above -->
        <xsl:when test="not($b-host-runestone)">
            <xsl:choose>
                <xsl:when test="@name">
                    <xsl:value-of select="@name"/>
                </xsl:when>
                <xsl:when test="@permid">
                    <xsl:value-of select="@permid"/>
                </xsl:when>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local-name(.)"/>
                    <xsl:text>-</xsl:text>
                    <!-- 2015-09: slow version matches previous "internal-id" -->
                    <!-- use for third (automatic) construction               -->
                    <xsl:choose>
                        <xsl:when test="$b-fast-ids">
                            <!-- xsltproc produces non-numeric prefix "idm" -->
                            <xsl:value-of select="substring(generate-id(.), 4)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:number from="book|article|letter|memo" level="any"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- alternate version for Runestone, prefer @xml:id, -->
        <!-- never use permid, no fast-id testing, in -common -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="visible-id"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We manufacture Javascript variables sometimes using            -->
<!-- this id to keep them unique, but a dash (encouraged in PTX)    -->
<!-- is banned in Javascript, so we make a "no-dash" version,       -->
<!-- by replacing a hyphen by a double-underscore.                  -->
<!-- NB: This runs some non-zero probability of breaking uniqueness -->
<xsl:template match="*" mode="visible-id-no-dash">
    <xsl:variable name="the-id">
        <xsl:apply-templates select="." mode="visible-id" />
    </xsl:variable>
    <xsl:value-of select="str:replace($the-id, '-', '__')" />
</xsl:template>

<!-- This template is motivated by the need to put @permid on    -->
<!-- "tabular" as part of an "in context" testing regimen        -->
<!-- spearheaded by Volker Sorge.  As a PreTeXt construction,    -->
<!-- it could be ill-advised.  But we won't split that hair now. -->
<!-- Do not use any place another HTML is is being added.        -->
<!-- And use the "match" so we can catalog *where* it is used.   -->
<xsl:template match="tabular" mode="html-permid-only">
    <xsl:if test="@permid">
        <xsl:attribute name="id">
            <xsl:value-of select="@permid"/>
        </xsl:attribute>
    </xsl:if>
</xsl:template>


<!-- ######## -->
<!-- SI Units -->
<!-- ######## -->

<xsl:template match="quantity">
    <!-- Unicode FRACTION SLASH -->
    <xsl:variable name="fraction-slash" select="'&#x2044;'"/>

    <!-- span to prevent line breaks within the quantity -->
    <span class="quantity">
        <xsl:apply-templates select="mag"/>
        <!-- if not solo, add separation -->
        <xsl:if test="mag and (unit or per)">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="per">
               <sup>
                    <xsl:if test="not(unit)">
                        <xsl:text>1</xsl:text>
                    </xsl:if>
                    <xsl:apply-templates select="unit" />
                </sup>
                <xsl:value-of select="$fraction-slash"/>
                <sub>
                    <xsl:apply-templates select="per" />
                </sub>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="unit"/>
            </xsl:otherwise>
        </xsl:choose>
    </span>
    <!-- NB: no mag, no per, no unit implies no output -->
    <!-- (really should be caught in schema), but      -->
    <!-- no real harm in just doing nothing            -->
</xsl:template>

<xsl:template match="mag">
    <xsl:variable name="mag">
        <xsl:value-of select="."/>
    </xsl:variable>
    <xsl:variable name="math-pi">
        <xsl:call-template name="begin-inline-math" />
        <xsl:text>\pi</xsl:text>
        <xsl:call-template name="end-inline-math" />
    </xsl:variable>
    <xsl:value-of select="str:replace($mag,'\pi',string($math-pi))"/>
</xsl:template>

<!-- unit and per children of a quantity element    -->
<!-- have a mandatory base attribute                -->
<!-- may have prefix and exp attributes             -->
<!-- base and prefix are not abbreviations          -->

<xsl:key name="prefix-key" match="prefix" use="concat(../@name, @full)"/>
<xsl:key name="base-key" match="base" use="concat(../@name, @full)"/>

<xsl:template match="unit|per">
    <!-- Unicode MIDDLE-DOT -->
    <xsl:variable name="inter-unit-product" select="'&#x00B7;'"/>

    <!-- add non-breaking hyphen within a numerator or denominator of units -->
    <xsl:if test="(self::unit and preceding-sibling::unit) or (self::per and preceding-sibling::per)">
        <xsl:value-of select="$inter-unit-product"/>
    </xsl:if>
    <!-- prefix is optional -->
    <xsl:if test="@prefix">
        <xsl:variable name="prefix">
            <xsl:value-of select="@prefix" />
        </xsl:variable>
        <xsl:variable name="short">
            <xsl:for-each select="document('pretext-units.xsl')">
                <xsl:value-of select="key('prefix-key',concat('prefixes',$prefix))/@short"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$short" />
    </xsl:if>
    <!-- base unit is required -->
    <xsl:variable name="base">
        <xsl:value-of select="@base" />
    </xsl:variable>
    <xsl:variable name="short">
        <xsl:for-each select="document('pretext-units.xsl')">
            <xsl:value-of select="key('base-key',concat('bases',$base))/@short"/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="$short" />
     <!-- exponent is optional -->
    <xsl:if test="@exp">
        <sup>
            <xsl:value-of select="@exp"/>
        </sup>
    </xsl:if>
</xsl:template>

<!-- ############ -->
<!-- Attributions -->
<!-- ############ -->

<!-- At end of: blockquote, preface, foreword       -->
<!-- free-form for one line, or structured as lines -->
<!-- TODO: add CSS for attribution, div flush right         -->
<!-- And go slanted ("oblique"?)                            -->
<!-- Maybe use CSS to right align as a block                -->
<!-- https://github.com/BooksHTML/mathbook-assets/issues/64 -->

<!-- Single line, mixed-content          -->
<!-- Or structured by "line" elements    -->
<!-- Quotation dash if within blockquote -->
<!-- Unicode Character 'HORIZONTAL BAR' aka 'QUOTATION DASH' -->
<xsl:template match="attribution">
    <cite class="attribution">
        <xsl:if test="parent::blockquote">
            <xsl:text>&#x2015;</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="line">
                <xsl:apply-templates select="line" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </cite>
</xsl:template>

<!-- Defined terms (bold, typically) -->
<xsl:template match="term">
    <dfn class="terminology">
        <xsl:apply-templates />
    </dfn>
</xsl:template>

<!-- Acronyms, Initialisms, Abbreviations -->
<!-- abbreviation: contracted form                                  -->
<!-- acronym: initials, pronounced as a word (eg SCUBA, RADAR)      -->
<!-- initialism: one letter at a time, (eg CIA, FBI)                -->
<!-- All are marked as the HTML "abbr" tag, but classes distinguish -->
<!-- Would a screen reader know the difference?                     -->
<xsl:template match="abbr">
    <abbr class="abbreviation">
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<xsl:template match="acro">
    <abbr class="acronym">
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<xsl:template match="init">
    <abbr class="initialism">
        <xsl:apply-templates />
    </abbr>
</xsl:template>

<!-- Emphasis -->
<!-- NB: See override in Braille conversion -->
<xsl:template match="em">
    <em class="emphasis">
        <xsl:apply-templates />
    </em>
</xsl:template>

<!-- Alert -->
<xsl:template match="alert">
    <em class="alert">
        <xsl:apply-templates />
    </em>
</xsl:template>

<!-- CSS for ins, del, s -->
<!-- http://html5doctor.com/ins-del-s/           -->
<!-- http://stackoverflow.com/questions/2539207/ -->

<!-- Insert (an edit) -->
<xsl:template match="insert">
    <ins class="insert">
        <xsl:apply-templates />
    </ins>
</xsl:template>

<!-- Delete (an edit) -->
<xsl:template match="delete">
    <del class="delete">
        <xsl:apply-templates />
    </del>
</xsl:template>

<!-- Stale (no longer relevant) -->
<xsl:template match="stale">
    <s class="stale">
        <xsl:apply-templates />
    </s>
</xsl:template>

<!-- Copyright symbol -->
<xsl:template name="copyright-character">
    <xsl:text>&#xa9;</xsl:text>
</xsl:template>

<!-- Phonomark symbol -->
<xsl:template name="phonomark-character">
    <xsl:text>&#x2117;</xsl:text>
</xsl:template>

<!-- Copyleft symbol -->
<!-- May not be universally available in fonts                 -->
<!-- Open C (U+254) plus Combining Circle (U+20dd) can imitate -->
<xsl:template name="copyleft-character">
    <xsl:text>&#x1f12f;</xsl:text>
</xsl:template>

<!-- Registered symbol -->
<!-- Bringhurst: should be superscript                    -->
<!-- We consider it a font mistake if not superscripted,  -->
<!-- since if we use a "sup" tag then a correct font will -->
<!-- get way too small                                    -->
<xsl:template name="registered-character">
    <xsl:text>&#xae;</xsl:text>
</xsl:template>

<!-- Trademark symbol -->
<xsl:template name="trademark-character">
    <xsl:text>&#x2122;</xsl:text>
</xsl:template>

<!-- Servicemark symbol -->
<xsl:template name="servicemark-character">
    <xsl:text>&#x2120;</xsl:text>
</xsl:template>

<!-- Degree -->
<xsl:template name="degree-character">
    <xsl:text>&#xb0;</xsl:text>
</xsl:template>

<!-- Prime -->
<xsl:template name="prime-character">
    <xsl:text>&#x2032;</xsl:text>
</xsl:template>

<xsl:template name="dblprime-character">
    <xsl:text>&#x2033;</xsl:text>
</xsl:template>

<!-- Fill-in blank -->
<!-- Bringhurst suggests 5/11 em per character                            -->
<!-- A 'span' normally, but a MathJax non-standard \Rule for math         -->
<!-- "\Rule is a MathJax-specific extension with parameters being width,  -->
<!-- height and depth of the rule"                                        -->
<!-- Davide Cervone                                                       -->
<!-- https://groups.google.com/forum/#!topic/mathjax-users/IEivs1D7ntM    -->
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
    <xsl:choose>
        <xsl:when test="parent::m or parent::me or parent::men or parent::mrow">
            <xsl:text>\underline{\hspace{</xsl:text>
            <xsl:value-of select="5 * $characters div 11" />
            <xsl:text>em}}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <span class="fillin" role="img">
                <xsl:attribute name="aria-label">
                    <xsl:value-of select="$characters" />
                    <xsl:text>-character blank</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:value-of select="5 * $characters div 11" />
                    <xsl:text>em;</xsl:text>
                </xsl:attribute>
            </span>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="var[@form='checkboxes']">
    <ul style="list-style:circle;">
        <xsl:apply-templates select="li"/>
    </ul>
</xsl:template>

<xsl:template match="var[@form='buttons']">
    <ul style="list-style:circle;">
        <xsl:apply-templates select="li"/>
    </ul>
</xsl:template>

<xsl:template match="var[@form='popup']">
    <ul style="list-style:circle;">
        <xsl:for-each select="li">
            <xsl:if test="not(p[.='?']) and not(normalize-space(.)='?')">
                <xsl:apply-templates select='.' />
            </xsl:if>
        </xsl:for-each>
    </ul>
</xsl:template>

<!-- Implication Symbols -->
<!-- TODO: better names! -->
<xsl:template match="imply">
    <xsl:text>&#x21D2;</xsl:text>
</xsl:template>
<xsl:template match="implyreverse">
    <xsl:text>&#x21D0;</xsl:text>
</xsl:template>

<!-- TeX, LaTeX -->
<!-- Corresponding CSS from William Hammond   -->
<!-- attributed to David Carlisle             -->
<!-- "mathjax-users" Google Group, 2015-12-27 -->
<!-- PreTeXt is in -common                    -->

<xsl:template match="latex">
    <span class="latex-logo">L<span class="A">a</span>T<span class="E">e</span>X</span>
</xsl:template>
<xsl:template match="tex">
    <span class="latex-logo">T<span class="E">e</span>X</span>
</xsl:template>

<!-- External URLs, Email        -->
<!-- Open in new window/tab as external reference                        -->
<!-- If content-less, then automatically formatted like code             -->
<!-- Within titles, we just produce (formatted) text, but nothing active -->
<xsl:template match="url">
    <!-- visible portion of HTML is the URL itself,   -->
    <!-- formatted as code, or content of PTX element -->
    <xsl:variable name="visible-text">
        <xsl:choose>
            <xsl:when test="not(node())">
                <code class="code-inline tex2jax_ignore">
                    <xsl:value-of select="@href" />
                </code>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Normally in an active link, except inactive in titles -->
    <xsl:choose>
        <xsl:when test="ancestor::title|ancestor::shorttitle|ancestor::subtitle">
            <xsl:copy-of select="$visible-text" />
        </xsl:when>
        <xsl:otherwise>
            <!-- class name identifies an external link -->
            <a class="external" href="{@href}" target="_blank">
                <xsl:copy-of select="$visible-text" />
            </a>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="email">
    <xsl:element name="a">
        <xsl:attribute name="href">
            <xsl:text>mailto:</xsl:text>
            <xsl:value-of select="." />
        </xsl:attribute>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>


<!-- ############# -->
<!-- Verbatim Text -->
<!-- ############# -->

<!-- Code, inline -->
<!-- PCDATA only, so drop non-text nodes -->
<!-- NB: "code-block" class otherwise -->
<xsl:template match="c">
    <code class="code-inline tex2jax_ignore">
        <xsl:value-of select="." />
    </code>
</xsl:template>


<!-- 100% analogue of LaTeX's verbatim            -->
<!-- environment or HTML's <pre> element          -->
<!-- TODO: center on page?                        -->

<!-- cd is for use in paragraphs, inline -->
<!-- Unstructured is pure text           -->
<xsl:template match="cd">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-display tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:value-of select="." />
    </xsl:element>
</xsl:template>

<!-- cline template is in xsl/pretext-common.xsl -->
<xsl:template match="cd[cline]">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-display tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="insert-paragraph-id" >
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <xsl:apply-templates select="cline" />
    </xsl:element>
</xsl:template>

<!-- "pre" is analogous to the HTML tag of the same name -->
<!-- The "interior" templates decide between two styles  -->
<!--   (a) clean up raw text, just like for Sage code    -->
<!--   (b) interpret cline as line-by-line structure     -->
<!-- (See templates in xsl/pretext-common.xsl file)     -->
<!-- Then wrap in a pre element that MathJax ignores     -->
<xsl:template match="pre">
    <xsl:element name="pre">
        <xsl:attribute name="class">
            <xsl:text>code-block tex2jax_ignore</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="interior"/>
    </xsl:element>
</xsl:template>

<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- XML and LaTeX equal to ASCII defaults  -->
<!-- See pretext-common.xsl for discussion -->

<!--           -->
<!-- XML, HTML -->
<!--           -->

<!-- & < > -->

<!-- Ampersand -->
<!-- Less Than -->
<!-- Greater Than -->

<!--       -->
<!-- LaTeX -->
<!--       -->

<!-- # $ % ^ & _ { } ~ \ -->

<!-- Number Sign, Hash, Octothorpe -->
<!-- ASCII from -common suffices -->

<!-- Dollar sign -->
<!-- Percent sign -->
<!-- Circumflex  -->
<!-- Ampersand -->
<!-- Handled above -->
<!-- Underscore -->
<!-- Left Brace -->
<!-- Right  Brace -->
<!-- Tilde -->
<!-- Backslash -->

<!-- Asterisk -->
<!-- Was once: Unicode Character 'ASTERISK OPERATOR' (U+2217)  -->
<!-- which is not quite right.  Now identical to a plain       -->
<!-- ASCII version, and we hope fonts do not place it too high -->
<xsl:template name="asterisk-character">
    <xsl:text>*</xsl:text>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template name="lsq-character">
    <xsl:text>&#x2018;</xsl:text>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template name="rsq-character">
    <xsl:text>&#x2019;</xsl:text>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template name="lq-character">
    <xsl:text>&#x201c;</xsl:text>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template name="rq-character">
    <xsl:text>&#x201d;</xsl:text>
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
<!-- MATHEMATICAL LEFT WHITE SQUARE BRACKET -->
<xsl:template name="ldblbracket-character">
    <xsl:text>&#x27e6;</xsl:text>
</xsl:template>

<!-- Right Double Bracket -->
<!-- MATHEMATICAL RIGHT WHITE SQUARE BRACKET -->
<xsl:template name="rdblbracket-character">
    <xsl:text>&#x27e7;</xsl:text>
</xsl:template>

<!-- Left Angle Bracket -->
<!-- LEFT ANGLE BRACKET -->
<!-- U+2329 was once used and caused a validator warning      -->
<!-- "Text run is not in Unicode Normalization Form C" (NFC)  -->
<xsl:template name="langle-character">
    <xsl:text>&#x3008;</xsl:text>
</xsl:template>

<!-- Right Angle Bracket -->
<!-- RIGHT ANGLE BRACKET -->
<!-- U+232A was once used and caused a validator warning      -->
<!-- "Text run is not in Unicode Normalization Form C" (NFC)  -->
<xsl:template name="rangle-character">
    <xsl:text>&#x3009;</xsl:text>
</xsl:template>


<!-- Other Miscellaneous Symbols, Constructions -->

<!-- Ellipsis (dots), for text, not math -->
<xsl:template name="ellipsis-character">
    <xsl:text>&#x2026;</xsl:text>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<!-- Bringhurst: Not Unicode +387, "GREEK ANO TELEIA"     -->
<xsl:template name="midpoint-character">
    <xsl:text>&#xb7;</xsl:text>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<xsl:template name="swungdash-character">
    <xsl:text>&#x2053;</xsl:text>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template name="permille-character">
    <xsl:text>&#x2030;</xsl:text>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template name="pilcrow-character">
    <xsl:text>&#xb6;</xsl:text>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template name="section-mark-character">
    <xsl:text>&#xa7;</xsl:text>
</xsl:template>

<!-- Minus -->
<!-- A hyphen/dash for use in text as subtraction or negation-->
<xsl:template name="minus-character">
    <xsl:text>&#x2212;</xsl:text>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text   -->
<!-- Styled to enhance, consensus at Google Group was -->
<!-- font-size: larger; vertical-align: -.2ex;        -->
<xsl:template name="times-character">
    <xsl:element name="span">
        <xsl:attribute name="class">
            <xsl:text>times-sign</xsl:text>
        </xsl:attribute>
        <xsl:text>&#xd7;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Slash -->
<!-- Forward slash, or virgule (see solidus) -->
<xsl:template name="slash-character">
    <xsl:text>/</xsl:text>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<xsl:template name="solidus-character">
    <xsl:text>&#x2044;</xsl:text>
</xsl:template>

<!-- Obelus -->
<!-- A "division" symbol for use in text -->
<xsl:template name="obelus-character">
    <xsl:text>&#xf7;</xsl:text>
</xsl:template>

<!-- Plus/Minus -->
<!-- The combined symbol -->
<xsl:template name="plusminus-character">
    <xsl:text>&#xb1;</xsl:text>
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
    <xsl:text>&#x60;</xsl:text>
</xsl:template>

<!-- Foreign words/idioms -->
<!-- Rutter, Web Typography, p.50 advocates a "span" with      -->
<!-- a "lang" attribute for foreign words so screen readers    -->
<!-- and hyphenation react properly.  Elsewhere, italics is    -->
<!-- suggested only for transliterated wods, to avoid          -->
<!-- confusion. However, for now, we are using "i" by default, -->
<!-- with a class that can be used in CSS for distinctions.    -->
<!-- But see also (2018-03-23):                                -->
<!-- https://www.w3.org/TR/html5/text-level-semantics.html#the-i-element -->
<xsl:template match="foreign">
    <i class="foreign">
        <xsl:if test="@xml:lang">
            <xsl:attribute name="lang">
                <xsl:value-of select="@xml:lang" />
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates />
    </i>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<!-- Presumes CSS headers have been loaded -->
<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>

    <!-- for-each is just one node, but sets context for key() -->
    <xsl:variable name="fa-name">
        <xsl:for-each select="$icon-table">
            <xsl:value-of select="key('icon-key', $icon-name)/@font-awesome"/>
        </xsl:for-each>
    </xsl:variable>

    <span class ="fas fa-{$fa-name}"/>
</xsl:template>


<!-- ############# -->
<!-- Keyboard Keys -->
<!-- ############# -->

<xsl:template match="kbd[not(@name)]">
    <kbd class="kbdkey">
        <xsl:value-of select="."/>
    </kbd>
</xsl:template>

<xsl:template match="kbd[@name]">
    <!-- the name attribute of the "kbd" in text as a string -->
    <xsl:variable name="kbdkey-name">
        <xsl:value-of select="@name"/>
    </xsl:variable>
    <!-- Entirely similar HTML/CSS, but will hold a Unicode character -->
    <kbd class="kbdkey">
        <!-- for-each is just one node, but sets context for key() -->
        <xsl:for-each select="$kbdkey-table">
            <xsl:value-of select="key('kbdkey-key', $kbdkey-name)/@unicode" />
        </xsl:for-each>
    </kbd>
</xsl:template>


<!-- ################ -->
<!-- Biological Names -->
<!-- ################ -->

<xsl:template match="taxon[not(genus) and not(species)]">
    <span class="taxon">
        <xsl:apply-templates />
    </span>
</xsl:template>

<xsl:template match="taxon[genus or species]">
    <span class="taxon">
        <xsl:if test="genus">
            <span class="genus">
                <xsl:apply-templates select="genus"/>
            </span>
        </xsl:if>
        <xsl:if test="genus and species">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="species">
            <span class="species">
                <xsl:apply-templates select="species"/>
            </span>
        </xsl:if>
    </span>
</xsl:template>

<!-- Titles of Publications -->
<!-- 2018-02-05: Deprecate "booktitle" in favor of       -->
<!-- "pubtitle".  Will still maintain all for a while.   -->
<!-- CMOS:  When quoted in text or listed in a           -->
<!-- bibliography, titles of books, journals, plays,     -->
<!-- and other freestanding works are italicized; titles -->
<!-- of articles, chapters, and other shorter works      -->
<!-- are set in roman and enclosed in quotation marks.   -->
<xsl:template match="pubtitle|booktitle">
    <span class="booktitle">
        <xsl:apply-templates />
    </span>
</xsl:template>

<!-- We provide the quotation marks explicitly, along       -->
<!-- with a span for any additional styling.  The quotation -->
<!-- marks are necessary for accessibility, e.g., they are  -->
<!-- critical in the Braille conversion.                    -->
<xsl:template match="articletitle">
    <span class="articletitle">
        <xsl:call-template name="lq-character"/>
        <xsl:apply-templates/>
        <xsl:call-template name="rq-character"/>
    </span>
</xsl:template>


<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- These are specific instances of abstract templates        -->
<!-- See the similar section of  pretext-common.xsl  for more -->

<!-- Non-breaking space, which "joins" two words as a unit            -->
<!-- Using &nbsp; does not travel well into node-set() in common file -->
<!-- http://stackoverflow.com/questions/31870                         -->
<!-- /using-a-html-entity-in-xslt-e-g-nbsp                            -->
<!-- Should create UTF-8 anyway:                                      -->
<!-- https://html.spec.whatwg.org/multipage/semantics.html#charset    -->

<xsl:template name="nbsp-character">
    <xsl:text>&#xa0;</xsl:text>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:text>&#8211;</xsl:text>
</xsl:template>

<xsl:template name="mdash-character">
    <xsl:text>&#8212;</xsl:text>
</xsl:template>

<!-- The abstract template for "mdash" consults a publisher option -->
<!-- for thin space, or no space, surrounding an em-dash.  So the  -->
<!-- "thin-space-character" is needed for that purpose, and does   -->
<!-- not have an associated empty PTX element.                     -->

<xsl:template name="thin-space-character">
    <xsl:text>&#8201;</xsl:text>
</xsl:template>

<!--       -->
<!-- Music -->
<!--       -->

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->

<!-- Double Sharp -->
<!-- Unicode Character 'MUSICAL SYMBOL DOUBLE SHARP' (U+1D12A)    -->
<!-- http://www.fileformat.info/info/unicode/char/1d12a/index.htm -->
<xsl:template name="doublesharp">
    <xsl:text>&#x1D12A;</xsl:text>
</xsl:template>

<!-- Sharp -->
<!-- Unicode Character 'MUSIC SHARP SIGN' (U+266F)               -->
<!-- http://www.fileformat.info/info/unicode/char/266f/index.htm -->
<xsl:template name="sharp">
    <xsl:text>&#x266F;</xsl:text>
</xsl:template>

<!-- Natural -->
<!-- Unicode Character 'MUSIC NATURAL SIGN' (U+266E)             -->
<!-- http://www.fileformat.info/info/unicode/char/266e/index.htm -->
<xsl:template name="natural">
    <xsl:text>&#x266E;</xsl:text>
</xsl:template>

<!-- Flat -->
<!-- Unicode Character 'MUSIC FLAT SIGN' (U+266D)                -->
<!-- http://www.fileformat.info/info/unicode/char/266d/index.htm -->
<xsl:template name="flat">
    <xsl:text>&#x266D;</xsl:text>
</xsl:template>

<!-- Double Flat -->
<!-- Unicode Character 'MUSICAL SYMBOL DOUBLE FLAT' (U+1D12B)     -->
<!-- http://www.fileformat.info/info/unicode/char/1d12b/index.htm -->
<xsl:template name="doubleflat">
    <xsl:text>&#x1D12B;</xsl:text>
</xsl:template>

<!-- Half Diminished -->
<!-- (MathJax does not support "\o") -->
<!-- Unicode Character 'LATIN SMALL LETTER O WITH STROKE' (U+00F8) -->
<!-- http://www.fileformat.info/info/unicode/char/00F8/index.htm -->
<xsl:template name="halfdiminishedchordsymbol">
    <xsl:text>&#x00F8;</xsl:text>
</xsl:template>

<!-- Raw Bibliographic Entry Formatting              -->
<!-- Markup really, not full-blown data preservation -->

<!-- Title in italics -->
<xsl:template match="biblio[@type='raw']/title">
    <i><xsl:apply-templates /></i>
</xsl:template>

<!-- No treatment for journal -->
<xsl:template match="biblio[@type='raw']/journal">
    <xsl:apply-templates />
</xsl:template>

<!-- Volume in bold -->
<xsl:template match="biblio[@type='raw']/volume">
    <b><xsl:apply-templates /></b>
</xsl:template>

<!-- Year in parentheses -->
<xsl:template match="biblio[@type='raw']/year">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Number -->
<xsl:template match="biblio[@type='raw']/number">
    <xsl:text>no. </xsl:text>
    <xsl:apply-templates />
</xsl:template>

<!-- Ibid, nee ibidem, handle TeX period idosyncracy, empty element -->
<!-- A 3em dash is used for identical authors                       -->
<xsl:template match="biblio[@type='raw']/ibid">
    <xsl:text>Ibid.</xsl:text>
</xsl:template>
<!-- Index Entries -->
<!-- Kill on sight, collect later to build index  -->
<xsl:template match="index[not(index-list)]" />
<xsl:template match="idx" />


<!-- Demonstrations -->
<!-- A simple page with no constraints -->
<xsl:template match="demonstration">
    <xsl:variable name="url"><xsl:apply-templates select="." mode="visible-id" />.html</xsl:variable>
    <a href="{$url}" target="_blank" class="link">
        <xsl:apply-templates select="." mode="title-full" />
    </a>
    <xsl:apply-templates select="." mode="simple-file-wrap" >
        <xsl:with-param name="content">
            <xsl:apply-templates />
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>


<!-- ############################ -->
<!-- Literate Programming Support -->
<!-- ############################ -->

<!-- The "fragment" element is used various other places, so that it   -->
<!-- slots into the knowl-creation system.  The pointer to a fragment, -->
<!-- "fragref", is different, and this makes a visual representation   -->
<!-- of a pointer to the target, as a knowl.  The next two templates   -->
<!-- support the "wrapped-content" template for "fragment".            -->

<!-- @ref is simply a pointer to a fragment, so -->
<!-- convert title into a knowl for the target  -->
<xsl:template match="fragref">
    <xsl:variable name="target-id">
        <xsl:call-template name="id-lookup-by-name">
            <xsl:with-param name="name" select="@ref"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="target" select="id($target-id)"/>
    <span>
        <xsl:call-template name="langle-character"/>
        <xsl:apply-templates select="." mode="xref-link">
            <xsl:with-param name="target" select="$target" />
            <xsl:with-param name="content">
                <xsl:apply-templates select="$target" mode="title-full"/>
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="$target" mode="number"/>
        <xsl:call-template name="rangle-character"/>
    </span>
    <br/>
</xsl:template>

<!-- wrap code in a "pre" environment, after pulling left -->
<!-- Drop whitespace only text() nodes                    -->
<xsl:template match="fragment/code">
    <xsl:variable name="normalized-frag" select="normalize-space(.)"/>
    <xsl:if test="not($normalized-frag = '')">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </xsl:if>
</xsl:template>


<!-- Sage Cells -->
<!-- TODO: make hidden autoeval cells link against sage-compute cells -->

<!-- The block-type parameter is only received from, and sent to, the -->
<!-- templates in the HTML conversion.  The purpose is to inform that -->
<!-- conversion that the Sage cell is inside a born-hidden knowl      -->
<!-- ($block-type = 'embed') and adjust the class name accordingly.   -->

<!-- Never an @id , so just repeat -->
<xsl:template match="sage" mode="duplicate">
    <xsl:apply-templates select="." />
</xsl:template>

<!-- An abstract named template accepts input text and   -->
<!-- output text, then wraps it for the Sage Cell Server -->
<!-- TODO: consider showing output in green span (?),    -->
<!-- presently output is dropped as computable           -->
<!-- NB: button text is also set as part of knowls code  -->
<xsl:template match="sage" mode="sage-active-markup">
    <xsl:param name="block-type"/>
    <xsl:param name="language-attribute" />
    <xsl:param name="in" />
    <xsl:param name="out" />
    <xsl:param name="b-original"/>

    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:if test="$block-type = 'embed'">
                <xsl:text>hidden-</xsl:text>
            </xsl:if>
            <xsl:text>sagecell-</xsl:text>
            <xsl:if test="$language-attribute=''">
                <xsl:text>sage</xsl:text>
            </xsl:if>
            <xsl:value-of select="$language-attribute" />
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="html-id"/>
        </xsl:attribute>
        <xsl:element name="script">
            <xsl:attribute name="type">
                <xsl:text>text/x-sage</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="$in" />
        </xsl:element>
    </xsl:element>
</xsl:template>

<!-- An abstract named template accepts input text   -->
<!-- and provides the display class, so untouchable  -->
<xsl:template name="sage-display-markup">
    <xsl:param name="block-type"/>
    <xsl:param name="in" />

    <div>
        <xsl:attribute name="class">
            <xsl:if test="$block-type = 'embed'">
                <xsl:text>hidden-</xsl:text>
            </xsl:if>
            <xsl:text>sage-display</xsl:text>
        </xsl:attribute>
        <script type="text/x-sage">
            <xsl:value-of select="$in" />
        </script>
    </div>
</xsl:template>

<!-- Program Listings -->
<!-- Research:  http://softwaremaniacs.org/blog/2011/05/22/highlighters-comparison/  -->
<!-- See common file for more on language handlers, and "language-prism" template    -->
<!-- TODO: maybe ship sanitized "input" to each modal template? -->
<xsl:template match="program[not(ancestor::sidebyside)]|console[not(ancestor::sidebyside)]">
    <xsl:choose>
        <!-- 100% historical, replace with a "web" platform option       -->
        <!-- TODO: once "exercise" conditions earlier on the platform,   -->
        <!-- then maybe the parts of this "choose" will migrate to other -->
        <!-- places and this will be more straightforward.               -->
        <xsl:when test="self::program and not($b-host-runestone) and (@interactive='pythontutor')">
            <xsl:apply-templates select="." mode="python-tutor"/>
        </xsl:when>
        <!-- if elected as interactive and on Runestone -->
        <xsl:when test="self::program and (@interactive='yes') and $b-host-runestone">
            <xsl:apply-templates select="." mode="runestone-activecode"/>
        </xsl:when>
        <!-- fallback is a less-capable static version, which -->
        <!-- might actually be desired for many formats       -->
        <xsl:otherwise>
            <xsl:variable name="rtf-layout">
                <xsl:apply-templates select="." mode="layout-parameters" />
            </xsl:variable>
            <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
            <!-- div is constraint/positioning for contained image -->
            <div class="code-box">
                <xsl:attribute name="style">
                    <xsl:text>width: </xsl:text>
                    <xsl:value-of select="$layout/width"/>
                    <xsl:text>%;</xsl:text>
                    <xsl:text> margin-left: </xsl:text>
                    <xsl:value-of select="$layout/left-margin"/>
                    <xsl:text>%;</xsl:text>
                    <xsl:text> margin-right: </xsl:text>
                    <xsl:value-of select="$layout/right-margin"/>
                    <xsl:text>%;</xsl:text>
                </xsl:attribute>
                <xsl:apply-templates select="." mode="code-inclusion"/>
            </div>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="program[ancestor::sidebyside]|console[ancestor::sidebyside]">
    <xsl:choose>
        <!-- 100% historical, replace with a "web" platform option, see note above -->
        <xsl:when test="self::program and not($b-host-runestone) and (@interactive='pythontutor')">
            <xsl:apply-templates select="." mode="python-tutor"/>
        </xsl:when>
        <!-- if elected as interactive and on Runestone -->
        <xsl:when test="self::program and (@interactive='yes') and $b-host-runestone">
            <xsl:apply-templates select="." mode="runestone-activecode"/>
        </xsl:when>
        <!-- fallback is a less-capable static version, which -->
        <!-- might actually be desired for many formats       -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="code-inclusion"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A non-interactive version with potential -->
<!-- syntax highlighting from Prism           -->
<xsl:template match="program" mode="code-inclusion">
    <xsl:variable name="prism-language">
        <xsl:apply-templates select="." mode="prism-language"/>
    </xsl:variable>
    <!-- a "program" element may be empty in a coding       -->
    <!-- exercise, and just used to indicate an interactive -->
    <!-- area supporting some language                      -->
    <xsl:variable name="b-has-input" select="not(normalize-space(input) = '')"/>
    <xsl:if test="$b-has-input">
        <!-- always identify as coming from "program" -->
        <pre class="program">
            <code>
                <!-- Prism only needs a single class name, per language  -->
                <!-- placed on "code" but will migrate to the "pre" also -->
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="not($prism-language = '')">
                            <xsl:text>language-</xsl:text>
                            <xsl:value-of select="$prism-language" />
                        </xsl:when>
                        <!-- else, explicitly use what code gives -->
                        <xsl:otherwise>
                            <xsl:text>language-none</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:call-template name="sanitize-text">
                    <xsl:with-param name="text" select="input" />
                </xsl:call-template>
            </code>
        </pre>
    </xsl:if>
</xsl:template>

<!-- Runestone has support for various languages.  Some  -->
<!-- are "in-browser" while others are backed by "real"  -->
<!-- compilers as part of a Runestone server.  For an    -->
<!-- exercise, we pass in some lead-in text, which is    -->
<!-- the question posed for use in the ActiveCode window -->
<xsl:template match="program" mode="runestone-activecode">
    <xsl:param name="statement-content" select="''"/>

    <xsl:variable name="active-language">
        <xsl:apply-templates select="." mode="active-language"/>
    </xsl:variable>
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id"/>
    </xsl:variable>
    <!-- assumes we get here from inside an "exercise" -->
    <xsl:variable name="num">
        <xsl:apply-templates select="ancestor::exercise" mode="number"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="not($active-language = '')">
            <div class="runestone explainer ac_section alert alert-warning">
                <div data-component="activecode">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$hid"/>
                    </xsl:attribute>
                    <!-- add some lead-in text to the window -->
                    <xsl:if test="not($statement-content = '')">
                        <div class="ac_question col-md-12">
                            <xsl:attribute name="id">
                                <xsl:value-of select="concat($hid, '_question')"/>
                            </xsl:attribute>
                            <xsl:copy-of select="$statement-content"/>
                        </div>
                    </xsl:if>
                    <textarea data-lang="{$active-language}" data-timelimit="25000" data-audio="" data-coach="true" style="visibility: hidden;">
                        <xsl:attribute name="id">
                            <xsl:value-of select="concat($hid, '_editor')"/>
                        </xsl:attribute>
                        <xsl:attribute name="data-question_label">
                            <xsl:value-of select="$num"/>
                        </xsl:attribute>
                        <!-- Code Lens only for certain languages -->
                        <xsl:attribute name="data-codelens">
                            <xsl:choose>
                                <xsl:when test="($active-language = 'python') or ($active-language = 'python2') or ($active-language = 'python3')">
                                    <xsl:text>true</xsl:text>
                                </xsl:when>
                                <xsl:when test="($active-language = 'c') or ($active-language = 'cpp') or ($active-language = 'java')">
                                    <xsl:text>true</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>false</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <!-- SQL (only) needs an attribute so it can find some code -->
                        <xsl:if test="$active-language = 'sql'">
                            <xsl:attribute name="data-wasm">
                                <xsl:text>/_static</xsl:text>
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:call-template name="sanitize-text">
                            <xsl:with-param name="text" select="input" />
                        </xsl:call-template>
                    </textarea>
                </div>
            </div>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>PTX:WARNING:  a Runestone ActiveCode element cannot produce interactive code in the language "<xsl:value-of select="@language"/>", so the code will be rendered in a static form.</xsl:message>
            <xsl:apply-templates select="." mode="html-static"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Interactive Programs, PyTutor -->
<!-- Use the PyTutor embedding to provide a Python program     -->
<!-- where a reader can interactively step through the program -->
<xsl:template match="program" mode="python-tutor">
    <!-- check that the language is Python? -->
    <xsl:variable name="hid">
        <xsl:apply-templates select="." mode="html-id" />
    </xsl:variable>
    <xsl:element name="div">
        <xsl:attribute name="class">
            <xsl:text>pytutorVisualizer</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="id">
            <xsl:value-of select="$hid" />
        </xsl:attribute>
        <xsl:attribute name="data-tracefile">
            <xsl:if test="$b-managed-directories">
                <xsl:value-of select="$external-directory"/>
            </xsl:if>
            <xsl:text>pytutor/</xsl:text>
            <xsl:value-of select="$hid" />
            <xsl:text>.json</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="data-params">
            <xsl:text>{</xsl:text>
            <xsl:text>"verticalStack": true, </xsl:text>
            <xsl:text>"embeddedMode": false, </xsl:text>
            <xsl:text>"codeDivWidth": </xsl:text>
            <xsl:value-of select="$design-width" />
            <xsl:text>, </xsl:text>
            <xsl:text>"codeDivHeight": 300</xsl:text>
            <xsl:text>}</xsl:text>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- Bits of Javascript for the top and bottom of the web page -->
<xsl:template name="pytutor-header">
    <xsl:if test="$b-has-pytutor">
        <script src="http://pythontutor.com/build/pytutor-embed.bundle.js?cc25af72af"></script>
    </xsl:if>
</xsl:template>

<xsl:template name="pytutor-footer">
    <xsl:if test="$b-has-pytutor">
        <script>createAllVisualizersFromHtmlAttrs();</script>
    </xsl:if>
</xsl:template>

<xsl:template name="aim-login-header">
    <xsl:if test="$b-host-aim">
        <link href="{$html.css.server}/css/{$html.css.version}/features.css" rel="stylesheet" type="text/css"/>
        <script>
            <xsl:text>var logged_in = false;&#xa;</xsl:text>
            <xsl:text>var role = 'student';&#xa;</xsl:text>
            <xsl:text>var guest_access = true;&#xa;</xsl:text>
            <xsl:text>var login_required = false;&#xa;</xsl:text>
            <xsl:text>var js_version = </xsl:text>
            <xsl:value-of select='$html.js.version'/>
            <xsl:text>;&#xa;</xsl:text>
        </script>
    </xsl:if>
    <xsl:if test="$debug.editable = 'yes'">
        <script>
            <xsl:text>var online_editable=true;</xsl:text>
        </script>
    </xsl:if>
</xsl:template>

<xsl:template name="aim-login-footer">
    <xsl:if test="$b-host-aim">
        <div class="login-link"><span id="loginlogout" class="login">login</span></div>
        <script src="{$html.js.server}/js/{$html.js.version}/login.js"></script>
    </xsl:if>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<xsl:template match="console" mode="code-inclusion">
    <!-- ignore prompt, and pick it up in trailing input -->
    <pre class="console">
        <xsl:apply-templates select="input|output"/>
    </pre>
</xsl:template>

<!-- do not run through generic text() template -->
<xsl:template match="console/prompt">
    <span class="prompt unselectable">
        <xsl:value-of select="." />
    </span>
</xsl:template>

<!-- match immediately preceding, only if a prompt:                   -->
<!-- https://www.oxygenxml.com/archives/xsl-list/199910/msg00541.html -->
<xsl:template match="console/input">
    <xsl:apply-templates select="preceding-sibling::*[1][self::prompt]" />
    <b>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
    </b>
</xsl:template>

<xsl:template match="console/output">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>

<!-- ######### -->
<!-- Runestone -->
<!-- ######### -->

<!-- Hosting at Runestone Academy -->

<!-- Runestone Javascript -->
<xsl:template name="runestone-header">
    <!-- without switch, do not add *anything* -->
    <xsl:if test="$b-host-runestone">
        <!-- Runestone templating for customizing hosted books -->
        <script type="text/javascript">
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>eBookConfig = {};&#xa;</xsl:text>
            <!-- no Sphinx {% %} templating for build system at all,         -->
            <!-- everything conditional on $runestone-dev                    -->
            <!-- 'no'  - production, {{ }} templating replaced by $rso, $rsc -->
            <!-- 'yes' - local viewing, dummy values                         -->
        <xsl:choose>
            <!-- Hosted, dynamic: $runestone-dev = 'no' -->
            <xsl:when test="not($runestone-dev)">
                <xsl:text>eBookConfig.useRunestoneServices = true;&#xa;</xsl:text>
                <xsl:text>eBookConfig.host = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.app = eBookConfig.host + '/' + '</xsl:text><xsl:value-of select="$rso"/><xsl:text>= request.application </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.course = '</xsl:text><xsl:value-of select="$rso"/><xsl:text>= course_name </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.basecourse = '</xsl:text><xsl:value-of select="$rso"/><xsl:text>= base_course </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isLoggedIn = </xsl:text><xsl:value-of select="$rso"/><xsl:text>= is_logged_in</xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.email = '</xsl:text><xsl:value-of select="$rso"/><xsl:text>= user_email </xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isInstructor = </xsl:text><xsl:value-of select="$rso"/><xsl:text>= is_instructor </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.logLevel = 10;&#xa;</xsl:text>
                <xsl:text>eBookConfig.ajaxURL = eBookConfig.app + "/ajax/";&#xa;</xsl:text>
                <!-- no .loglevel -->
                <xsl:text>eBookConfig.username = '</xsl:text><xsl:value-of select="$rso"/><xsl:text>= user_id</xsl:text><xsl:value-of select="$rsc"/><xsl:text>';&#xa;</xsl:text>
                <xsl:text>eBookConfig.readings = </xsl:text><xsl:value-of select="$rso"/><xsl:text>= readings</xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.activities = </xsl:text><xsl:value-of select="$rso"/><xsl:text>= XML(activity_info) </xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.downloadsEnabled = </xsl:text><xsl:value-of select="$rso"/><xsl:text>=downloads_enabled</xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.allow_pairs = </xsl:text><xsl:value-of select="$rso"/><xsl:text>=allow_pairs</xsl:text><xsl:value-of select="$rsc"/><xsl:text>;&#xa;</xsl:text>
                <xsl:text>eBookConfig.enableScratchAC = false;&#xa;</xsl:text>
                <!-- no .build_info -->
                <!-- no .python3 -->
                <!-- no .acDefaultLanguage -->
                <!-- no .runestone_version -->
                <!-- no .jobehost -->
                <!-- no .proxyuri_runs -->
                <!-- no .proxyuri_files -->
                <!-- no .enable_chatcodes -->
            </xsl:when>
            <!-- Dev, testing: $runestone-dev = 'yes' -->
            <!-- 2021-07-01: to become universal HTML -->
            <xsl:otherwise>
                <xsl:comment>** eBookCongig is necessary to configure interactive       **</xsl:comment>
                <xsl:comment>** Runestone components to run locally in reader's browser **</xsl:comment>
                <xsl:comment>** No external communication:                              **</xsl:comment>
                <xsl:comment>**     log level is 0, Runestone Services are disabled     **</xsl:comment>
                <xsl:text>eBookConfig.useRunestoneServices = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.host = 'http://127.0.0.1:8000';&#xa;</xsl:text>
                <!-- no .app -->
                <xsl:text>eBookConfig.course = 'PTX Course: Title Here';&#xa;</xsl:text>
                <xsl:text>eBookConfig.basecourse = 'PTX Base Course';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isLoggedIn = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.email = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.isInstructor = false;&#xa;</xsl:text>
                <!-- no .ajaxURL since no .app -->
                <xsl:text>eBookConfig.logLevel = 0;&#xa;</xsl:text>
                <xsl:text>eBookConfig.username = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.readings = null;&#xa;</xsl:text>
                <xsl:text>eBookConfig.activities = null;&#xa;</xsl:text>
                <xsl:text>eBookConfig.downloadsEnabled = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.allow_pairs = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.enableScratchAC = false;&#xa;</xsl:text>
                <xsl:text>eBookConfig.build_info = "";&#xa;</xsl:text>
                <xsl:text>eBookConfig.python3 = null;&#xa;</xsl:text>
                <xsl:text>eBookConfig.acDefaultLanguage = 'python';&#xa;</xsl:text>
                <xsl:text>eBookConfig.runestone_version = '5.0.1';&#xa;</xsl:text>
                <xsl:text>eBookConfig.jobehost = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.proxyuri_runs = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.proxyuri_files = '';&#xa;</xsl:text>
                <xsl:text>eBookConfig.enable_chatcodes =  false;&#xa;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        </script>
        <xsl:text>&#xa;</xsl:text>

        <!-- Google Ads on Runestone -->
        <!-- Only in PreTeXt production version, only visible in -->
        <!-- *non-login* versions of books hosted at Runestone   -->
        <xsl:if test="not($runestone-dev)">
            <!-- attribute is templated, so we form it as a -->
            <!-- variable that we can place it using an AVT -->
            <xsl:variable name="id-attr">
                <xsl:value-of select="$rso"/>
                <xsl:text>=settings.adsenseid</xsl:text>
                <xsl:value-of select="$rsc"/>
            </xsl:variable>
            <!--  -->
            <xsl:value-of select="$rso"/>
            <xsl:text> if response.serve_ad and settings.adsenseid: </xsl:text>
            <xsl:value-of select="$rsc"/>
            <xsl:text>&#xa;</xsl:text>
            <!--  -->
            <script data-ad-client="{$id-attr}" async="" src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
            <!--  -->
            <xsl:text>&#xa;</xsl:text>
            <xsl:value-of select="$rso"/>
            <xsl:text> pass </xsl:text>
            <xsl:value-of select="$rsc"/>
            <xsl:text>&#xa;</xsl:text>
            <!--  -->
        </xsl:if>

        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.i18n/1.0.5/jquery.i18n.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.i18n/1.0.5/jquery.i18n.emitter.bidi.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.i18n/1.0.5/jquery.i18n.emitter.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.i18n/1.0.5/jquery.i18n.fallbacks.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.i18n/1.0.5/jquery.i18n.messagestore.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.i18n/1.0.5/jquery.i18n.parser.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.i18n/1.0.5/jquery.i18n.language.js"></script>

        <script type="text/javascript" src="_static/jquery.idle-timer.js"></script>
        <script type="text/javascript" src="_static/runestone.js"></script>
        <script type="text/javascript" src="https://www.youtube.com/player_api"></script>

        <style>
        <xsl:text>.dropdown {&#xa;</xsl:text>
        <xsl:text>    position: relative;&#xa;</xsl:text>
        <xsl:text>    display: inline-block;&#xa;</xsl:text>
        <xsl:text>    height: 39px;&#xa;</xsl:text>
        <xsl:text>    width: 50px;&#xa;</xsl:text>
        <xsl:text>    margin-left: auto;&#xa;</xsl:text>
        <xsl:text>    margin-right: auto;&#xa;</xsl:text>
        <xsl:text>    padding: 7px;&#xa;</xsl:text>
        <xsl:text>    text-align: center;&#xa;</xsl:text>
        <xsl:text>    background-color: #eeeeee;&#xa;</xsl:text>
        <xsl:text>    border: 1px solid;&#xa;</xsl:text>
        <xsl:text>    border-color: #aaaaaa;&#xa;</xsl:text>
        <xsl:text> }&#xa;</xsl:text>
        <xsl:text> .dropdown-content {&#xa;</xsl:text>
        <xsl:text>    position: absolute;&#xa;</xsl:text>
        <xsl:text>    display: none;&#xa;</xsl:text>
        <xsl:text>    left: 300px;&#xa;</xsl:text>
        <xsl:text>    text-align: left;&#xa;</xsl:text>
        <xsl:text>    font-family: 'Open Sans', 'Helvetica Neue', 'Helvetica';&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>.dropdown:hover {&#xa;</xsl:text>
        <xsl:text>    background-color: #ddd;&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>.dropdown:hover .dropdown-content {&#xa;</xsl:text>
        <xsl:text>    display: block;&#xa;</xsl:text>
        <xsl:text>    position: fixed;&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>.dropdown-content {&#xa;</xsl:text>
        <xsl:text>    background-color: white;&#xa;</xsl:text>
        <xsl:text>    z-index: 1800;&#xa;</xsl:text>
        <xsl:text>    min-width: 100px;&#xa;</xsl:text>
        <xsl:text>    padding: 5px;&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>.dropdown-content a {&#xa;</xsl:text>
        <xsl:text>    display: block;&#xa;</xsl:text>
        <xsl:text>    text-decoration: none;&#xa;</xsl:text>
        <xsl:text>    color: #662211;&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        <xsl:text>.dropdown-content a:hover {&#xa;</xsl:text>
        <xsl:text>    background-color: #671d12;&#xa;</xsl:text>
        <xsl:text>    color: #ffffff;&#xa;</xsl:text>
        <xsl:text>}&#xa;</xsl:text>
        </style>
    </xsl:if>
</xsl:template>

<!-- Runestone Manifest -->
<!-- HTML ID and real title for each chapter and section -->
<!-- A PTX "section" is a Runestone "subchapter"         -->
<!-- Document hierarchy is preserved in XML structure    -->
<!-- TODO: add exercises as "question"                   -->

<!-- Conditional run-in -->
<xsl:template name="runestone-manifest">
    <xsl:if test="$b-host-runestone and ($b-is-book or $b-is-article)">
        <!-- $document-root *will* be a book -->
        <xsl:apply-templates select="$document-root" mode="runestone-manifest"/>
    </xsl:if>
</xsl:template>

<xsl:template match="book|article" mode="runestone-manifest">
    <exsl:document href="runestone-manifest.xml" method="xml" indent="yes" encoding="UTF-8">
        <manifest>
            <!-- LaTeX packages and macros first -->
            <latex-macros>
                <xsl:text>&#xa;</xsl:text>
                <xsl:value-of select="$latex-packages-mathjax"/>
                <xsl:value-of select="$latex-macros"/>
            </latex-macros>
            <xsl:choose>
                <xsl:when test="self::book">
                    <!-- Now recurse into chapters, appendix -->
                    <xsl:apply-templates select="*" mode="runestone-manifest"/>
                </xsl:when>
                <xsl:when test="self::article">
                    <!-- Now recurse into sections, appendix  -->
                    <!-- with a faux chapter, using "article" -->
                    <chapter>
                        <id>
                            <xsl:apply-templates select="." mode="html-id"/>
                        </id>
                        <title>
                            <xsl:apply-templates select="." mode="title-full"/>
                        </title>
                        <xsl:apply-templates select="*" mode="runestone-manifest"/>
                    </chapter>
                </xsl:when>
            </xsl:choose>
        </manifest>
    </exsl:document>
</xsl:template>

<xsl:template match="chapter" mode="runestone-manifest">
    <chapter>
        <id>
            <xsl:apply-templates select="." mode="html-id"/>
        </id>
        <title>
            <xsl:apply-templates select="." mode="title-full"/>
        </title>
    <!-- Recurse into PTX sections, or if the chapter is not structured, -->
    <!-- then pick up inline exercises directly within a chapter         -->
    <xsl:apply-templates select="*" mode="runestone-manifest"/>
    </chapter>
</xsl:template>

<!-- Every division at PTX "section" level, -->
<!-- potentially containing an "exercise",  -->
<!-- e.g. "worksheet" but not "references", -->
<!-- is a RS "subchapter"                   -->
<xsl:template match="section|chapter/exercises|chapter/worksheet|chapter/reading-questions" mode="runestone-manifest">
    <subchapter>
        <id>
            <xsl:apply-templates select="." mode="html-id"/>
        </id>
        <title>
            <xsl:apply-templates select="." mode="title-full"/>
        </title>
        <!-- nearly a dead end, recurse into "exercise" and PROJECT-LIKE at *any* PTX -->
        <!-- depth, for example within a "subsection" (which Runestone does not have) -->
        <xsl:apply-templates select=".//exercise|.//project|.//activity|.//exploration|.//investigation"  mode="runestone-manifest"/>
    </subchapter>
    <!-- dead end structurally, no more recursion, even if "subsection", etc. -->
</xsl:template>

<!-- A Runestone exercise needs to identify itself when an instructor wants   -->
<!-- to select it for assignment, so we want to provide enough identification -->
<!-- in the manifest, via a "label" element full of raw text.                 -->
<xsl:template match="exercise|project|activity|exploration|investigation" mode="runestone-manifest-label">
    <label>
        <xsl:apply-templates select="." mode="type-name"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="number"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="title-full"/>
    </label>
</xsl:template>

<!-- Exercises to the Runestone manifest -->
<!--   - every "exercise" in a "reading-questions" division -->
<!--   - every multiple choice "exercise"                   -->
<!--   - every "exercise" with an interactive "program"     -->
<!-- Note, 2020-05-29: multiple choice not yet merged, markup is speculative -->
<xsl:template match="exercise[parent::reading-questions]|exercise[choices]" mode="runestone-manifest">
    <question>
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <xsl:apply-templates select="." mode="exercise-components"/>
    </question>
</xsl:template>

<xsl:template match="exercise[webwork-reps]" mode="runestone-manifest">
    <question>
        <xsl:apply-templates select="." mode="runestone-manifest-label"/>
        <!-- N.B.  Better here to ask for "exercise-components"? -->
        <xsl:apply-templates select="introduction|webwork-reps|conclusion"/>
    </question>
</xsl:template>

<!-- Coding Exercise to the Runestone manifest -->
<!--   "exercise" with "program" *outside* of "statement" -->
<!--   &PROJECT-LIKE; only at top-level                   -->
<xsl:template match="exercise[program]|project[program]|activity[program]|exploration[program]|investigation[program]" mode="runestone-manifest">
    <xsl:variable name="active-language">
        <xsl:apply-templates select="program" mode="active-language"/>
    </xsl:variable>
    <!-- if elected as interactive AND @language is supported -->
    <xsl:if test="not($active-language = '')">
        <question>
            <!-- label is from the "exercise" -->
            <xsl:apply-templates select="." mode="runestone-manifest-label"/>
            <!-- need to set controls on what gets produced by "exercise-components"     -->
            <!-- TODO: this is a band-aid, why isn't it necessary for reading questions? -->
            <xsl:apply-templates select="." mode="exercise-components">
                <xsl:with-param name="b-has-statement" select="true()"/>
            </xsl:apply-templates>
        </question>
    </xsl:if>
</xsl:template>

<!-- Appendix is explicitly no-op, so we do not recurse into "section"  -->
<xsl:template match="appendix" mode="runestone-manifest"/>

<!-- Traverse the tree,looking for things to do          -->
<!-- http://stackoverflow.com/questions/3776333/         -->
<!-- stripping-all-elements-except-one-in-xml-using-xslt -->
<xsl:template match="*" mode="runestone-manifest">
    <xsl:apply-templates select="*" mode="runestone-manifest"/>
</xsl:template>


<!-- ############ -->
<!-- Interactives -->
<!-- ############ -->

<!-- Every interactive is an "iframe" - this allows us to confine      -->
<!-- libraries, variables, and scripts to just where they are needed.  -->
<!-- And we can "sandbox" an iframe.  Some simple interactives, coming -->
<!-- from servers, are built to be iframes.  In other cases, we build  -->
<!-- a super-minimal page to serve as the @src of an iframe.  For each -->
<!-- "interactive", we also build a stand-alone page to serve as the   -->
<!-- target of a live link in a static format (such as a QR code in a  -->
<!-- LaTeX/PDF document).                                              -->
<!--                                                                   -->
<!-- PTX source may include a "static" element - we routinely ignore   -->
<!-- for HTML output, as it is only employed in static output formats  -->
<!-- https://www.html5rocks.com/en/tutorials/security/sandboxed-iframes/ -->

<!-- Three actions, all based on "interactive-core" template -->
<xsl:template match="interactive">
    <!-- (1) Build, display full content on the page, where born -->
    <xsl:apply-templates select="." mode="interactive-core" />
    <!-- (2) Identical content, but now isolated on a reader-friendly page -->
    <xsl:apply-templates select="." mode="standalone-page" >
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="interactive-core" />
        </xsl:with-param>
    </xsl:apply-templates>
    <!-- (3) A simple page that can be used in an iframe construction -->
    <xsl:apply-templates select="." mode="create-iframe-page" />
</xsl:template>

<!-- Following will generate:              -->
<!--   1.  Instructions (paragraphs, etc)  -->
<!--   2.  An iframe, via modal-template   -->
<xsl:template match="interactive" mode="interactive-core">
    <!-- "instructions" first in identical-width div -->
    <xsl:if test="instructions">
        <div>
            <xsl:variable name="width">
                <xsl:apply-templates select="." mode="get-width-pixels" />
            </xsl:variable>
            <xsl:attribute name="style">
                <xsl:text>width:</xsl:text>
                <xsl:value-of select="$width" />
                <xsl:text>px;</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates select="instructions" />
        </div>
    </xsl:if>
    <!-- An iframe follows next -->
    <xsl:apply-templates select="." mode="iframe-interactive" />
</xsl:template>

<!-- ################### -->
<!-- iframe Interactives -->
<!-- ################### -->

<!-- Given by a small piece of information used -->
<!-- to form the @src attribute of an "iframe"  -->
<!-- An iframe has @width, @height attributes,  -->
<!-- specified in pixels                        -->

<!-- Every "interactive" is realized as an -->
<!-- "iframe", so the HTML iframe/@id is   -->
<!-- derived from the "interactive"        -->
<xsl:template match="interactive" mode="iframe-id">
    <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="visible-id"/>
    </xsl:attribute>
</xsl:template>

<!-- Desmos -->
<!-- The simplest possible example of this type -->
<xsl:template match="interactive[@desmos]" mode="iframe-interactive">
    <iframe src="https://www.desmos.com/calculator/{@desmos}">
        <xsl:apply-templates select="." mode="iframe-id"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
    </iframe>
</xsl:template>

<!-- Wolfram Computable Document Format -->
<!-- Just mildly more involved than the Desmos case                                              -->
<!-- https://www.wolfram.com/cdf/adopting-cdf/deploying-cdf/web-delivery-cloud.html              -->
<!-- More for MMA origination, but discusses "cloud credits"                                     -->
<!-- https://reference.wolfram.com/language/howto/DeployInteractiveContentInTheWolframCloud.html -->
<!-- https://www.wolfram.com/cloud-credits/                                                      -->
<xsl:template match="interactive[@wolfram-cdf]" mode="iframe-interactive">
    <!-- Query string option: _embed=iframe will provide Wolfram footer -->
    <iframe src="https://www.wolframcloud.com/objects/{@wolfram-cdf}?_view=frameless">
        <xsl:apply-templates select="." mode="iframe-id"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
    </iframe>
</xsl:template>

<!-- Geogebra -->
<!-- Similar again, but with options fixed -->
<xsl:template match="interactive[@geogebra]" mode="iframe-interactive">
    <iframe src="https://www.geogebra.org/material/iframe/id/{@geogebra}/width/800/height/450/border/888888/smb/false/stb/false/stbh/false/ai/false/asb/false/sri/false/rc/false/ld/false/sdz/false/ctl/false">
        <xsl:apply-templates select="." mode="iframe-id"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
    </iframe>
</xsl:template>

<!-- CalcPlot3D -->
<!-- A bit more complicated, as the configuration   -->
<!-- is a query string of a URL, and we can specify -->
<!-- the style of the interface through @variant    -->
<xsl:template match="interactive[@calcplot3d]" mode="iframe-interactive">
    <!-- Use @variant to pick an endpoint/view/infrastructure -->
    <xsl:variable name="cp3d-endpoint">
        <xsl:choose>
            <xsl:when test="@variant='application'">
                <xsl:text>https://www.monroecc.edu/faculty/paulseeburger/calcnsf/CalcPlot3D</xsl:text>
            </xsl:when>
            <xsl:when test="@variant='controls'">
                <xsl:text>https://www.monroecc.edu/faculty/paulseeburger/CalcPlot3D/dynamicFigureWCP</xsl:text>
            </xsl:when>
            <xsl:when test="@variant='minimal'">
                <xsl:text>https://www.monroecc.edu/faculty/paulseeburger/CalcPlot3D/dynamicFigure</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- just a silly domain so something none-too-crazy happens -->
                <xsl:text>http://www.example.com/</xsl:text>
                <xsl:message>MBX:ERROR:  @variant="<xsl:value-of select="@variant" />" is not recognized for a CalcPlot3D &lt;interactive&gt;</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- load 'em up and go -->
    <!-- TODO: box-sizing, etc does not seem to help with vertical scroll bars -->
    <xsl:variable name="full-url" select="concat($cp3d-endpoint, '/?', @calcplot3d)" />
    <iframe src="{$full-url}">
        <xsl:apply-templates select="." mode="iframe-id"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
    </iframe>
</xsl:template>

<!-- For more complicated interactives, we just point to the page we generate -->
<xsl:template match="interactive[@platform]" mode="iframe-interactive">
    <iframe>
        <xsl:apply-templates select="." mode="iframe-id"/>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
        <xsl:attribute name="src">
            <xsl:apply-templates select="." mode="iframe-filename" />
        </xsl:attribute>
    </iframe>
</xsl:template>

<!-- ######################### -->
<!-- Source File Interactives  -->
<!-- ######################### -->

<!-- Build a minimal page for iframe contents -->
<!-- This version for @platform variant       -->
<!--   MathJax for PTX delimiters             -->
<!--   Platform specific libraries into head  -->
<!--   Author-libraries after slate exist     -->
<xsl:template match="interactive[@platform]" mode="create-iframe-page">
    <xsl:variable name="if-filename">
        <xsl:apply-templates select="." mode="iframe-filename" />
    </xsl:variable>
    <exsl:document href="{$if-filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
        <xsl:call-template name="converter-blurb-html" />
        <html lang="{$document-language}">
            <head>
                <!-- configure MathJax by default for @platform variants -->
                <xsl:call-template name="mathjax" />
                <!-- need CSS for sidebyside         -->
                <!-- perhaps this can be specialized -->
                <xsl:call-template name="css" />
                <!-- maybe icons in captions? -->
                <xsl:call-template name="font-awesome" />
                <!-- and CSS for the entire interactive, into the head -->
                <xsl:apply-templates select="@css" />
                <!-- load header libraries (for all "slate") -->
                <xsl:apply-templates select="." mode="header-libraries" />
            </head>
            <body class="pretext-content">
                <!-- potential document-id per-page -->
                <xsl:call-template name="document-id"/>
                <div>
                    <!-- the actual interactive bit          -->
                    <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
                    <!-- stack, else use a layout -->
                    <xsl:apply-templates select="slate|sidebyside|sbsgroup" />
                    <!-- accumulate script tags *after* HTML elements -->
                    <xsl:apply-templates select="@source" />
                </div>
            </body>
        </html>
    </exsl:document>
</xsl:template>

<!-- These forms *are* iframes, so we don't need to build their content -->
<xsl:template match="interactive[@desmos|@geogebra|@calcplot3d|@wolfram-cdf]" mode="create-iframe-page" />


<!-- ################ -->
<!-- Header Libraries -->
<!-- ################ -->

<!-- Specified by libraries through @platform attribute  -->
<!-- or explicitly with @library, and with per-slate     -->
<!-- @source files stored locally, these draw on "slate" -->
<!-- elements having different @surface characteristics  -->

<!-- Geogebra header libraries -->
<xsl:template match="interactive[@platform = 'geogebra']" mode="header-libraries">
    <script type="text/javascript" src="https://cdn.geogebra.org/apps/deployggb.js"></script>
</xsl:template>

<!-- Sage Interact header libraries -->
<!-- ".sage-interact" must match use in "slate" -->
<xsl:template match="interactive[@platform = 'sage']" mode="header-libraries">
    <script src="https://sagecell.sagemath.org/static/embedded_sagecell.js"></script>
    <script>
        <xsl:text>sagecell.makeSagecell({&#xa;</xsl:text>
        <xsl:text>    inputLocation: ".sage-interact",&#xa;</xsl:text>
        <xsl:text>    autoeval: 'true',&#xa;</xsl:text>
        <xsl:text>    hide: ["editor", "evalButton", "permalink"]&#xa;</xsl:text>
        <xsl:text>});&#xa;</xsl:text>
    </script>
    <link rel="stylesheet" type="text/css" href="https://sagecell.sagemath.org/static/sagecell_embed.css" />
</xsl:template>

<!-- JSXGraph header libraries -->
<xsl:template match="interactive[@platform = 'jsxgraph']" mode="header-libraries">
    <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraph.css" />
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraphcore.js"></script>
</xsl:template>

<!-- D3.js header libraries -->
<xsl:template match="interactive[@platform = 'd3']" mode="header-libraries">
    <xsl:variable name="d3-library-url">
        <xsl:text>https://d3js.org/d3.v</xsl:text>
        <!-- versions could be 3, 4, 5 -->
        <xsl:choose>
            <xsl:when test="@version">
                <xsl:value-of select="@version" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>5</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>.min.js</xsl:text>
    </xsl:variable>
    <script src="{$d3-library-url}"></script>
</xsl:template>

<!-- Javascript header libraries (none) -->
<xsl:template match="interactive[@platform = 'javascript']" mode="header-libraries" />

<!-- ########################### -->
<!-- Slates (objects to draw on) -->
<!-- ########################### -->

<!-- Slates are where we draw, with different surfaces -->

<xsl:template match="slate[@surface='div']">
    <div>
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
    </div>
</xsl:template>

<xsl:template match="slate[@surface='svg']">
    <svg>
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <!-- <xsl:apply-templates select="." mode="size-pixels-style-attribute" /> -->
    </svg>
</xsl:template>

<xsl:template match="slate[@surface = 'canvas']">
    <!-- display:block allows precise sizes, without   -->
    <!-- having inline content with extra line height, -->
    <!-- or whatever, inducing scroll bars             -->
    <canvas style="display:block">
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <xsl:apply-templates select="." mode="size-pixels-attributes" />
    </canvas>
</xsl:template>

<!-- HTML Code -->
<!-- Simply create deep-copy of HTML elements -->
<!-- TODO: should this be a div, with width and height? -->
<xsl:template match="slate[@surface = 'html']">
    <xsl:copy-of select="*" />
</xsl:template>

<!-- Similar to the "div" surface, but with class information -->
<xsl:template match="slate[@surface = 'jsxboard']">
    <div>
        <xsl:attribute name="id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>jxgbox</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
    </div>
</xsl:template>

<!-- Sage Cell Server will execute an interact, when     -->
<!-- properly bundled up with the right HTML markup      -->
<!-- ".sage-interact" must match use in "header-library" -->
<xsl:template match="slate[@surface = 'sage']">
    <div class="sage-interact">
      <script type="text/x-sage">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="." />
        </xsl:call-template>
      </script>
    </div>
</xsl:template>

<xsl:template match="slate[@surface='geogebra']">
    <!-- size of the window, to be passed as a parameter -->
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-pixels" />
    </xsl:variable>
    <xsl:variable name="height">
        <xsl:apply-templates select="." mode="get-height-pixels" />
    </xsl:variable>
    <!-- We need a Javascript identifier to name the applet -->
    <xsl:variable name="applet-name">
        <xsl:apply-templates select="." mode="visible-id-no-dash" />
    </xsl:variable>
    <!-- And a Javascript identifier for the parameters -->
    <xsl:variable name="applet-parameters">
        <xsl:apply-templates select="." mode="visible-id-no-dash" />
        <xsl:text>_params</xsl:text>
    </xsl:variable>
    <!-- And a Javascript identifier for the onload function -->
    <xsl:variable name="applet-onload">
        <xsl:apply-templates select="." mode="visible-id-no-dash" />
        <xsl:text>_onload</xsl:text>
    </xsl:variable>
    <!-- And a Javascript identifier for the onload function argument -->
    <!-- not strictly necessary, but clarifies HTML                   -->
    <xsl:variable name="applet-onload-argument">
        <xsl:apply-templates select="." mode="visible-id-no-dash" />
        <xsl:text>_applet</xsl:text>
    </xsl:variable>
    <!-- And an HTML unique identifier -->
    <xsl:variable name="applet-container">
        <xsl:apply-templates select="." mode="visible-id" />
        <xsl:text>-container</xsl:text>
    </xsl:variable>
    <!-- Javascript API for loading GeoGebra                               -->
    <script>
        <!-- API commands, as text() nodes in the slate. Manual at:   -->
        <!-- https://wiki.geogebra.org/en/Reference:GeoGebra_Apps_API -->
        <!-- In PTX source, use the commands one per line, as in:     -->
        <!-- setCoordSystem(0, 20, 0, 10);                            -->
        <!-- enableShiftDragZoom(false);                              -->
        <xsl:if test="normalize-space(text())">
            <xsl:text>var </xsl:text>
            <xsl:value-of select="$applet-onload" />
            <xsl:text> = function(</xsl:text>
            <xsl:value-of select="$applet-onload-argument" />
            <xsl:text>) {&#xa;</xsl:text>
            <xsl:call-template name="prepend-string">
                <xsl:with-param name="text">
                    <xsl:call-template name="sanitize-text">
                        <xsl:with-param name="text" select="." />
                    </xsl:call-template>
                </xsl:with-param>
                <!-- period below is Javascript syntax for methods -->
                <xsl:with-param name="pad" select="concat($applet-onload-argument,'.')" />
            </xsl:call-template>
            <xsl:text>};&#xa;</xsl:text>
        </xsl:if>
        <!-- Parameter reference:                                              -->
        <!-- https://wiki.geogebra.org/en/Reference:GeoGebra_App_Parameters    -->
        <!-- We leave most parameters as their default value. In most cases,   -->
        <!-- an author could use API commands to alter these settings.         -->
        <xsl:text>var </xsl:text>
        <xsl:value-of select="$applet-parameters" />
        <xsl:text> = {&#xa;</xsl:text>
        <!-- Prioritize local over remote -->
        <xsl:choose>
            <xsl:when test="@base64">
                <xsl:text>ggbBase64:"</xsl:text>
                <xsl:value-of select="@base64" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@source">
                <xsl:text>filename:"</xsl:text>
                <xsl:if test="$b-managed-directories">
                    <xsl:value-of select="$external-directory"/>
                </xsl:if>
                <xsl:value-of select="@source" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@material">
                <xsl:text>material_id:"</xsl:text>
                <xsl:value-of select="@material" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
            <xsl:when test="@geogebra">
                <xsl:message>PTX Warning:  "geogebra" attribute on "slate" element is deprecated; use "material" attribute</xsl:message>
                <xsl:text>material_id:"</xsl:text>
                <xsl:value-of select="@geogebra" />
                <xsl:text>",&#xa;</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:text>width:</xsl:text><xsl:value-of select="$width" />
        <xsl:text>,&#xa;</xsl:text>
        <xsl:text>height:</xsl:text><xsl:value-of select="$height" />
        <xsl:text>,&#xa;</xsl:text>
        <xsl:if test="normalize-space(text())">
            <xsl:text>appletOnLoad:</xsl:text>
            <xsl:value-of select="$applet-onload" />
        </xsl:if>
        <xsl:text>};&#xa;</xsl:text>

        <xsl:text>var </xsl:text>
            <xsl:value-of select="$applet-name" />
        <xsl:text> = new GGBApplet(</xsl:text>
            <xsl:value-of select="$applet-parameters" />
        <xsl:text>, true);&#xa;</xsl:text>

        <!-- inject the applet into the div below -->
        <xsl:text>window.onload = function() { </xsl:text>
        <xsl:value-of select="$applet-name" />
        <xsl:text>.inject('</xsl:text>
        <xsl:value-of select="$applet-container" />
        <xsl:text>'); }&#xa;</xsl:text>
    </script>
    <!-- build a container div with the right shape -->
    <div class="geogebra-applet" id="{$applet-container}">
        <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
    </div>
</xsl:template>

<xsl:template match="slate[@surface = 'jessiecode']">
  <!-- size of the window, to be passed as a parameter -->
  <xsl:variable name="width">
      <xsl:apply-templates select="." mode="get-width-pixels" />
  </xsl:variable>
  <xsl:variable name="height">
      <xsl:apply-templates select="." mode="get-height-pixels" />
  </xsl:variable>
  <!-- the div that jsxgraph will take over -->
  <xsl:element name="div">
      <xsl:attribute name="id">
          <xsl:apply-templates select="." mode="visible-id" />
      </xsl:attribute>
      <xsl:attribute name="class">
          <xsl:text>jxgbox</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates select="." mode="size-pixels-style-attribute" />
  </xsl:element>
  <!-- Add a script wrapper to parse using JSXGraph -->
  <xsl:choose>
      <xsl:when test="text()">
          <xsl:element name="script">
              <xsl:attribute name="type">
                  <xsl:text>text/jessiecode</xsl:text>
              </xsl:attribute>
              <!-- Put the board in the appropriate container. -->
              <xsl:attribute name="container">
                  <xsl:apply-templates select="." mode="visible-id" />
              </xsl:attribute>
              <xsl:if test="@boundingbox">
                  <xsl:attribute name="boundingbox">
                      <xsl:value-of select="@boundingbox" />
                  </xsl:attribute>
              </xsl:if>
              <xsl:if test="@axis">
                  <xsl:attribute name="axis">
                      <xsl:value-of select="@axis" />
                  </xsl:attribute>
              </xsl:if>
              <xsl:if test="@grid">
                  <xsl:attribute name="grid">
                      <xsl:value-of select="@grid" />
                  </xsl:attribute>
              </xsl:if>
              <!-- Add the script -->
              <xsl:call-template name="sanitize-text">
                  <xsl:with-param name="text" select="." />
              </xsl:call-template>
          </xsl:element>
      </xsl:when>
      <xsl:when test="@source">
          <xsl:element name="script">
              <xsl:attribute name="type">
                  <xsl:text>text/javascript</xsl:text>
              </xsl:attribute>
              <xsl:text>function parseJessie(code) {&#xa;</xsl:text>
              <xsl:text>  let board = JXG.JSXGraph.initBoard('</xsl:text>
              <xsl:apply-templates select="." mode="visible-id" />
              <xsl:text>', {</xsl:text>
              <xsl:if test="@boundingbox">
                  <xsl:text>boundingbox:[</xsl:text>
                  <xsl:value-of select="@boundingbox" />
                  <xsl:text>], </xsl:text>
              </xsl:if>
              <xsl:if test="@axis">
                  <xsl:text>axis:</xsl:text>
                  <xsl:value-of select="@axis" />
                  <xsl:text>, </xsl:text>
              </xsl:if>
              <xsl:if test="@grid">
                  <xsl:text>grid:</xsl:text>
                  <xsl:value-of select="@grid" />
                  <xsl:text>, </xsl:text>
              </xsl:if>
              <xsl:text>keepaspectratio:true});&#xa;</xsl:text>
              <xsl:text>  board.jc = new JXG.JessieCode();&#xa;</xsl:text>
              <xsl:text>  board.jc.use(board);&#xa;</xsl:text>
              <xsl:text>  board.suspendUpdate();&#xa;</xsl:text>
              <xsl:text>  board.jc.parse(code);&#xa;</xsl:text>
              <xsl:text>  board.unsuspendUpdate();&#xa;</xsl:text>
              <xsl:text>}&#xa;</xsl:text>
              <xsl:text>fetch('</xsl:text>
              <xsl:if test="$b-managed-directories">
                <xsl:value-of select="$external-directory"/>
              </xsl:if>
              <xsl:value-of select="@source" />
              <xsl:text>').then(function(response) { response.text().then( function(text) { parseJessie(text); }); });&#xa;</xsl:text>
          </xsl:element>
      </xsl:when>
  </xsl:choose>
</xsl:template>

<!-- Utilities -->

<!-- These can be vastly improved with a call to "tokenize()"   -->
<!-- and then a "for-each" can effectively loop over the pieces -->

<!-- @source attribute to multiple script tags -->
<xsl:template match="interactive[@platform]/@source">
    <xsl:call-template name="one-script">
        <xsl:with-param name="token-list">
            <xsl:call-template name="prepare-token-list">
                <xsl:with-param name="token-list" select="." />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- A recursive template to create a script tag for each JS file -->
<xsl:template name="one-script">
    <xsl:param name="token-list" />
    <xsl:choose>
        <xsl:when test="$token-list = ''" />
        <xsl:otherwise>
            <script>
                <!-- this is a hack to allow for local files and network resources,   -->
                <!-- with or without managed directories.  There should be a seperate -->
                <!-- attribute like an @href used for audio and video, and then any   -->
                <!-- "http"-leading string should be flagged as a deprecation         -->
                <xsl:variable name="location">
                    <xsl:variable name="raw-location" select="substring-before($token-list, ' ')"/>
                    <xsl:choose>
                        <xsl:when test="substring($raw-location,1,4) = 'http'">
                            <xsl:value-of select="$raw-location"/>
                        </xsl:when>
                        <xsl:when test="not($b-managed-directories)">
                            <xsl:value-of select="$raw-location"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$external-directory"/>
                            <xsl:value-of select="$raw-location"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:attribute name="src">
                    <xsl:value-of select="$location" />
                </xsl:attribute>
            </script>
            <xsl:call-template name="one-script">
                <xsl:with-param name="token-list" select="substring-after($token-list, ' ')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- @css attribute to multiple "link" element -->
<xsl:template match="interactive[@platform]/@css">
    <xsl:call-template name="one-css">
        <xsl:with-param name="token-list">
            <xsl:call-template name="prepare-token-list">
                <xsl:with-param name="token-list" select="." />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- A recursive template to create a link element for each CSS file -->
<!-- This is used to process  $html.css.extra  as well               -->
<xsl:template name="one-css">
    <xsl:param name="token-list" />
    <xsl:choose>
        <xsl:when test="$token-list = ''" />
        <xsl:otherwise>
            <link rel="stylesheet" type="text/css">
                <xsl:attribute name="href">
                    <xsl:value-of select="substring-before($token-list, ' ')" />
                </xsl:attribute>
            </link>
            <xsl:call-template name="one-css">
                <xsl:with-param name="token-list" select="substring-after($token-list, ' ')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Next two utilities write attributes, so cannot go in -common -->

<!-- iframes, etc, need size as a pair of attributes in pixels -->
<xsl:template match="*" mode="size-pixels-attributes">
    <xsl:attribute name="width">
        <xsl:apply-templates select="." mode="get-width-pixels" />
    </xsl:attribute>
    <xsl:attribute name="height">
        <xsl:apply-templates select="." mode="get-height-pixels" />
    </xsl:attribute>
</xsl:template>

<!-- div's need size in a style attribute -->
<xsl:template match="*" mode="size-pixels-style-attribute">
    <xsl:variable name="width">
        <xsl:apply-templates select="." mode="get-width-pixels" />
    </xsl:variable>
    <xsl:variable name="height">
        <xsl:apply-templates select="." mode="get-height-pixels" />
    </xsl:variable>
    <xsl:attribute name="style">
        <xsl:text>width:</xsl:text>
        <xsl:value-of select="$width" />
        <xsl:text>px; </xsl:text>
        <xsl:text>height:</xsl:text>
        <xsl:value-of select="$height" />
        <xsl:text>px; </xsl:text>
        <xsl:text>display: block; </xsl:text>
        <xsl:text>box-sizing: border-box; -moz-box-sizing: border-box; -webkit-box-sizing: border-box;</xsl:text>
    </xsl:attribute>
</xsl:template>

<!-- This is a no-op stub, so we can insert annotations at  -->
<!-- key locations.  To "activate", an importing stylesheet -->
<!-- needs to define this template.  So in this way we have -->
<!-- the same effect as if we had a switch.                 -->
<xsl:template match="*" mode="view-source-knowl"/>

<!-- JSXGraph -->
<!-- DEPRECATED (2018-04-06)                             -->
<!-- Restrict edits to cosmetic, no functional change    -->
<!-- Remove when continued maintenance becomes untenable -->
<!-- Not updated to be part of @permid scheme            -->
<xsl:template match="jsxgraph">
    <!-- interpret @width percentage and @aspect ratio -->
    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction">
        <xsl:value-of select="substring-before($width-percent,'%') div 100" />
    </xsl:variable>
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="'1:1'" />
        </xsl:apply-templates>
    </xsl:variable>
    <!-- these are now standardized templates -->
    <xsl:variable name="width"  select="$design-width * $width-fraction" />
    <xsl:variable name="height" select="$design-width * $width-fraction div $aspect-ratio" />
    <!-- the div to hold the JSX output -->
    <xsl:element name="div">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="visible-id" />
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>jxgbox</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>width:</xsl:text>
            <xsl:value-of select="$width" />
            <xsl:text>px; height:</xsl:text>
            <xsl:value-of select="$height" />
            <xsl:text>px;</xsl:text>
        </xsl:attribute>
    </xsl:element>
    <!-- the script to hold the code                       -->
    <!-- JSXGraph code must reference the id on the div,   -->
    <!-- so ideally an xml:id specifies this in the source -->
    <xsl:element name="script">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="input" />
        </xsl:call-template>
    </xsl:element>
    <xsl:copy-of select="controls" />
</xsl:template>

<!-- ########################## -->
<!-- WeBWorK Embedded Exercises -->
<!-- ########################## -->

<!-- WeBWorK HTML CSS header -->
<!-- MathView is a math entry palette tool that could be enabled  -->
<!-- in the host anonymous course.   It is incorporated only if   -->
<!-- "webwork-reps" element is present                            -->
<!-- TODO: should also depend on whether all are presented as static -->
<!-- TODO: it is unclear if MathView should be loaded here at all; -->
<xsl:template name="webwork">
    <xsl:if test="$b-has-webwork-reps">
        <link href="{$webwork-domain}/webwork2_files/js/apps/MathView/mathview.css" rel="stylesheet" />
        <xsl:choose>
            <xsl:when test="$webwork-reps-version = 1">
                <script src="{$webwork-domain}/webwork2_files/js/vendor/iframe-resizer/js/iframeResizer.min.js"></script>
            </xsl:when>
            <xsl:when test="$webwork-reps-version = 2">
                <script src="{$html.js.server}/js/{$html.js.version}/pretext-webwork.js"></script>
                <script src="{$webwork-domain}/webwork2_files/node_modules/iframe-resizer/js/iframeResizer.min.js"></script>
            </xsl:when>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Fail if WeBWorK extraction and merging has not been done -->
<xsl:template match="webwork[node()|@*]">
    <xsl:message>PTX:ERROR: A document that uses WeBWorK must have the mbx script webwork extraction run, followed by a merge using pretext-merge.xsl.  Apply subsequent style sheets to the merged output.  Your WeBWorK problems will be absent from your HTML output.</xsl:message>
</xsl:template>

<!-- The guts of a WeBWorK problem realized in HTML -->
<!-- This is heart of an external knowl version, or -->
<!-- what is born visible under control of a switch -->
<xsl:template match="webwork-reps">
    <xsl:param name="b-original" select="true()"/>
    <xsl:variable name="b-has-hint" select="(ancestor::exercises and $b-has-divisional-hint) or
                                            (ancestor::reading-questions and $b-has-reading-hint) or
                                            (ancestor::worksheet and $b-has-worksheet-hint) or
                                            (not(ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-hint)" />
    <xsl:variable name="b-has-answer" select="(ancestor::exercises and $b-has-divisional-answer) or
                                              (ancestor::reading-questions and $b-has-reading-answer) or
                                              (ancestor::worksheet and $b-has-worksheet-answer) or
                                              (not(ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-answer)" />
    <xsl:variable name="b-has-solution" select="(ancestor::exercises and $b-has-divisional-solution) or
                                                (ancestor::reading-questions and $b-has-reading-solution) or
                                                (ancestor::worksheet and $b-has-worksheet-solution) or
                                                (not(ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and $b-has-inline-solution)"/>
    <xsl:variable name="b-static" select="(ancestor::exercises and ($webwork.divisional.static = 'yes')) or
                                          (ancestor::reading-questions and ($webwork.reading.static = 'yes')) or
                                          (ancestor::worksheet and ($webwork.worksheet.static = 'yes')) or
                                          (not(ancestor::exercises or ancestor::reading-questions or ancestor::worksheet) and ($webwork.inline.static = 'yes'))"/>
    <xsl:choose>
        <!-- We print the static version when that is explicitly directed -->
        <!-- but also when the static has no "answer" element. This means -->
        <!-- the problem had no answer input fields, so why make it       -->
        <!-- interactive? This includes problems with only essay fields.  -->
        <!-- NB: for Runestone, we may want to allow essay answer fields  -->
        <!-- to make live problems, and Runestone records submissions.    -->
        <xsl:when test="($b-static = 'yes')">
            <xsl:apply-templates select="static" mode="exercise-components">
                <xsl:with-param name="b-original"      select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()"/>
                <xsl:with-param name="b-has-hint"      select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"    select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution"  select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$webwork-reps-version = 1">
            <xsl:if test="$b-webwork-inline-randomize">
                <xsl:apply-templates select="." mode="webwork-randomize-buttons"/>
            </xsl:if>
            <xsl:apply-templates select="." mode="webwork-iframe">
                <xsl:with-param name="b-has-hint"     select="$b-has-hint"/>
                <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$webwork-reps-version = 2">
            <xsl:apply-templates select="." mode="webwork-interactive-div">
                <xsl:with-param name="b-original"     select="$b-original"/>
                <xsl:with-param name="b-has-hint"     select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"   select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution" select="$b-has-solution"/>
            </xsl:apply-templates>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Make a div with a button, where pretext-webwork.js can   -->
<!-- replace the div content with a live, interactive problem -->
<xsl:template match="webwork-reps" mode="webwork-interactive-div">
    <xsl:param name="b-original"/>
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-answer"/>
    <xsl:param name="b-has-solution"/>
    <xsl:element name="div">
        <xsl:attribute name="id">
            <xsl:value-of select="@ww-id"/>
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>exercise-wrapper</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="data-domain">
            <xsl:value-of select="$webwork-domain"/>
        </xsl:attribute>
        <xsl:attribute name="data-seed" >
            <xsl:value-of select="static/@seed"/>
        </xsl:attribute>
        <xsl:choose>
            <xsl:when test="server-data/@problemSource">
                <xsl:attribute name="data-problemSource">
                    <xsl:value-of select="server-data/@problemSource"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:when test="server-data/@sourceFilePath">
                <xsl:attribute name="data-sourceFilePath">
                    <xsl:value-of select="server-data/@sourceFilePath"/>
                </xsl:attribute>
            </xsl:when>
        </xsl:choose>
        <xsl:attribute name="data-courseID">
            <xsl:value-of select="server-data/@course-id"/>
        </xsl:attribute>
        <xsl:attribute name="data-userID">
            <xsl:value-of select="server-data/@user-id"/>
        </xsl:attribute>
        <xsl:attribute name="data-coursePassword">
            <xsl:value-of select="server-data/@course-password"/>
        </xsl:attribute>
        <xsl:attribute name="aria-live">
            <xsl:value-of select="'polite'"/>
        </xsl:attribute>
        <div class="problem-contents">
            <xsl:apply-templates select="static" mode="exercise-components">
                <xsl:with-param name="b-original"      select="$b-original"/>
                <xsl:with-param name="b-has-statement" select="true()"/>
                <xsl:with-param name="b-has-hint"      select="$b-has-hint"/>
                <xsl:with-param name="b-has-answer"    select="$b-has-answer"/>
                <xsl:with-param name="b-has-solution"  select="$b-has-solution"/>
            </xsl:apply-templates>
        </div>
        <div class="problem-buttons">
            <button class="webwork-button" onclick="handleWW('{@ww-id}')">Make Interactive</button>
        </div>
    </xsl:element>
</xsl:template>

<!-- Select the correct URL from four pre-generated choices -->
<!-- and package up as an iframe for interactive version    -->
<!-- Used with 2.15- WW servers (webwork-reps version 1)    -->
<xsl:template match="webwork-reps" mode="webwork-iframe">
    <xsl:param name="b-has-hint"/>
    <xsl:param name="b-has-solution"/>
    <xsl:variable name="the-url">
        <xsl:choose>
            <xsl:when test="$b-has-hint and $b-has-solution">
                <xsl:apply-templates select="server-url[@hint='yes' and @solution='yes']"/>
            </xsl:when>
            <xsl:when test="$b-has-hint and not($b-has-solution)">
                <xsl:apply-templates select="server-url[@hint='yes' and @solution='no']"/>
            </xsl:when>
            <xsl:when test="not($b-has-hint) and $b-has-solution">
                <xsl:apply-templates select="server-url[@hint='no'  and @solution='yes']"/>
            </xsl:when>
            <xsl:when test="not($b-has-hint) and not($b-has-solution)">
                <xsl:apply-templates select="server-url[@hint='no'  and @solution='no']"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- build the iframe -->
    <!-- mimicking Mike Gage's blog post -->
    <iframe name="{@ww-id}" width="{$design-width}" src="{$the-url}" data-seed="{static/@seed}"/>
    <script>
        <xsl:text>iFrameResize({log:true,inPageLinks:true,resizeFrom:'child',checkOrigin:["</xsl:text>
        <xsl:value-of select="$webwork-domain" />
        <xsl:text>"]})</xsl:text>
    </script>
</xsl:template>

<!-- Buttons for randomizing the seed of a live WeBWorK problem            -->
<!-- Undocumented. Only designed to work with 2.15 and earlier WW servers. -->
<xsl:template match="webwork-reps" mode="webwork-randomize-buttons">
    <div class="WW-randomize-buttons">
        <button class="WW-randomize" type="button" onclick="WWiframeReseed('{@ww-id}')">Randomize</button>
        <button class="WW-randomize" type="button" onclick="WWiframeReseed('{@ww-id}',{static/@seed})">Reset</button>
    </div>
</xsl:template>

<!-- In WeBWorK problems, a p whose only child is a fillin blank     -->
<!-- almost certainly means a question has been asked, and below it  -->
<!-- there is an entry field. In print, there is no need to print    -->
<!-- that entry field and removing it can save a lot of vertical     -->
<!-- space. This is in constrast with fillins in the middle of a p,  -->
<!-- where answer blanks need to be printed because of the fill      -->
<!-- in the blank nature of the quesiton.                            -->
<xsl:template match="p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][not(parent::li)]|p[not(normalize-space(text()))][count(fillin)=1 and count(*)=1][parent::li][preceding-sibling::*]" />

<!-- ############################# -->
<!-- MyOpenMath Embedded Exercises -->
<!-- ############################# -->

<xsl:template match="myopenmath">
    <!-- A container controls the width. At 100% this is the     -->
    <!-- full page width and when revealed in a knowl it shrinks -->
    <!-- to fill available width.  In another application, the   -->
    <!-- width might come from an author's source.               -->
    <div style="width:100%;">
        <!-- This preserves the aspect-ratio, and there is no       -->
        <!-- clipping.  Basically this says scale the iframe to     -->
        <!-- fill whatever width is available in the containing div -->
        <iframe style="object-fit: contain; width: 100%;">
            <xsl:attribute name="src">
                <xsl:text>https://www.myopenmath.com/embedq.php?id=</xsl:text>
                <xsl:value-of select="@problem" />
                <!-- can't disable escaping text of an attribute -->
                <xsl:text>&amp;resizer=true</xsl:text>
            </xsl:attribute>
        </iframe>
    </div>
    <!-- not so great -->
    <!-- <script>iFrameResize({log:true,inPageLinks:true,resizeFrom:'child'})</script> -->
</xsl:template>

<!--                         -->
<!-- Web Page Infrastructure -->
<!--                         -->

<!-- An individual page:                                   -->
<!-- Inputs:                                               -->
<!-- * page content (exclusive of banners, navigation etc) -->
<xsl:template match="*" mode="file-wrap">
    <xsl:param name="content" />
    <!-- Hack, include leading space for now -->
    <xsl:param name="extra-body-classes"/>
    <xsl:param name="filename" select="''"/>

    <xsl:variable name="the-filename">
        <xsl:choose>
            <xsl:when test="not($filename = '')">
                <xsl:value-of select="$filename"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="containing-filename" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Experimental - companion, chunked HTML -->
    <xsl:if test="$debug.editable = 'yes'">
        <xsl:variable name="the-source-filename">
            <xsl:value-of select="str:replace($the-filename, '.html', '.ptx')"/>
        </xsl:variable>
        <exsl:document href="{$the-source-filename}" method="xml" omit-xml-declaration="no" indent="yes" encoding="UTF-8">
            <xsl:copy-of select="."/>
        </exsl:document>
    </xsl:if>

    <exsl:document href="{$the-filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
    <xsl:call-template name="converter-blurb-html" />
    <html lang="{$document-language}"> <!-- dir="rtl" here -->
        <head>
            <title>
                <!-- Leading with initials is useful for small tabs -->
                <xsl:if test="$docinfo/initialism">
                    <xsl:apply-templates select="$docinfo/initialism" />
                    <xsl:text> </xsl:text>
                </xsl:if>
            <xsl:apply-templates select="." mode="title-short" />
            </title>
            <meta name="Keywords" content="Authored in PreTeXt" />
            <!-- http://webdesignerwall.com/tutorials/responsive-design-in-3-steps -->
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
            <!-- favicon -->
            <xsl:call-template name="favicon"/>
            <!-- jquery used by sage, webwork, knowls -->
            <xsl:call-template name="sagecell-code" />
            <xsl:call-template name="mathjax" />
            <!-- webwork's iframeResizer needs to come before sage -->
            <xsl:call-template name="webwork" />
            <xsl:apply-templates select="." mode="sagecell" />
            <xsl:call-template name="syntax-highlight-header"/>
            <xsl:call-template name="google-search-box-js" />
            <xsl:call-template name="mathbook-js" />
            <xsl:call-template name="knowl" />
            <xsl:call-template name="fonts" />
            <xsl:call-template name="hypothesis-annotation" />
            <xsl:call-template name="geogebra" />
            <xsl:call-template name="jsxgraph" />
            <xsl:call-template name="css" />
            <xsl:call-template name="aim-login-header" />
            <xsl:call-template name="pytutor-header" />
            <xsl:call-template name="runestone-header"/>
            <xsl:call-template name="font-awesome" />
        </head>
        <body>
            <!-- potential document-id per-page -->
            <xsl:call-template name="document-id"/>
            <!-- the first class controls the default icon -->
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="$root/book">mathbook-book</xsl:when>
                    <xsl:when test="$root/article">mathbook-article</xsl:when>
                </xsl:choose>
                <xsl:if test="$b-has-toc">
                    <xsl:text> has-toc has-sidebar-left</xsl:text> <!-- note space, later add right -->
                </xsl:if>
                <xsl:value-of select="$extra-body-classes"/>
            </xsl:attribute>
            <!-- assistive "Skip to main content" link    -->
            <!-- this *must* be first for maximum utility -->
            <xsl:call-template name="skip-to-content-link" />
            <xsl:call-template name="latex-macros" />
            <!-- HTML5 body/header will be a "banner" landmark automatically -->
            <header id="masthead" class="smallbuttons">
                <div class="banner">
                    <div class="container">
                        <xsl:call-template name="brand-logo" />
                        <div class="title-container">
                            <h1 class="heading">
                                <xsl:variable name="root-filename">
                                    <xsl:apply-templates select="$document-root" mode="containing-filename" />
                                </xsl:variable>
                                <a href="{$root-filename}">
                                    <xsl:variable name="b-has-subtitle" select="boolean($document-root/subtitle)"/>
                                    <span class="title">
                                        <!-- Do not use shorttitle in masthead,  -->
                                        <!-- which is much like cover of a book  -->
                                        <xsl:apply-templates select="$document-root" mode="title-simple" />
                                        <xsl:if test="$b-has-subtitle">
                                            <xsl:text>:</xsl:text>
                                        </xsl:if>
                                    </span>
                                    <xsl:if test="$b-has-subtitle">
                                        <xsl:text> </xsl:text>
                                        <span class="subtitle">
                                            <xsl:apply-templates select="$document-root" mode="subtitle" />
                                        </span>
                                    </xsl:if>
                                </a>
                            </h1>
                            <!-- Serial list of authors/editors -->
                            <p class="byline">
                                <xsl:apply-templates select="$document-root/frontmatter/titlepage/author" mode="name-list"/>
                                <xsl:apply-templates select="$document-root/frontmatter/titlepage/editor" mode="name-list"/>
                            </p>
                        </div>  <!-- title-container -->
                        <!-- accessibility suggests relative ordering of next items -->
                        <xsl:call-template name="google-search-box" />
                    </div>  <!-- container -->
                </div>  <!-- banner -->
            <xsl:apply-templates select="." mode="primary-navigation" />
            </header>  <!-- masthead -->
            <div class="page">
                <xsl:apply-templates select="." mode="sidebars" />
                <!-- HTML5 main will be a "main" landmark automatically -->
                <main class="main">
                    <div id="content" class="pretext-content">
                        <xsl:if test="$b-watermark">
                            <xsl:attribute name="style">
                                <xsl:value-of select="$watermark-css" />
                            </xsl:attribute>
                        </xsl:if>
                        <xsl:copy-of select="$content" />
                    </div>
                </main>
            </div>

            <!-- analytics services, if requested -->
            <xsl:call-template name="statcounter"/>
            <xsl:call-template name="google-classic"/>
            <xsl:call-template name="google-universal"/>
            <xsl:call-template name="google-gst"/>
            <xsl:call-template name="pytutor-footer" />
            <xsl:call-template name="syntax-highlight-footer" />
            <xsl:call-template name="aim-login-footer" />
            <xsl:call-template name="extra-js-footer"/>
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- A minimal individual page:                              -->
<!-- Inputs:                                                 -->
<!-- * page content (exclusive of banners, navigation etc)   -->
<!-- Maybe a page title -->
<xsl:template match="*" mode="simple-file-wrap">
    <xsl:param name="content" />
    <xsl:variable name="filename">
        <!-- do not use "containing-filename" may be different -->
        <xsl:apply-templates select="." mode="visible-id" />
        <text>.html</text>
    </xsl:variable>
    <exsl:document href="{$filename}" method="html" indent="yes" encoding="UTF-8" doctype-system="about:legacy-compat">
    <xsl:call-template name="converter-blurb-html" />
    <html lang="{$document-language}"> <!-- dir="rtl" here -->
        <head>
            <meta name="Keywords" content="Authored in PreTeXt" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

            <!-- jquery used by sage, webwork, knowls -->
            <xsl:call-template name="sagecell-code" />
            <xsl:call-template name="mathjax" />
            <!-- webwork's iframeResizer needs to come before sage -->
            <xsl:call-template name="webwork" />
            <xsl:apply-templates select="." mode="sagecell" />
            <xsl:call-template name="knowl" />
            <xsl:call-template name="fonts" />
            <xsl:call-template name="hypothesis-annotation" />
            <xsl:call-template name="geogebra" />
            <xsl:call-template name="jsxgraph" />
            <xsl:call-template name="css" />
            <xsl:call-template name="runestone-header"/>
            <xsl:call-template name="font-awesome" />
        </head>
        <!-- TODO: needs some padding etc -->
        <body>
            <!-- potential document-id per-page -->
            <xsl:call-template name="document-id"/>
            <xsl:copy-of select="$content" />
            <!-- analytics services, if requested -->
            <xsl:call-template name="statcounter"/>
            <xsl:call-template name="google-classic"/>
            <xsl:call-template name="google-universal"/>
            <xsl:call-template name="google-gst"/>
            <xsl:call-template name="extra-js-footer"/>
        </body>
    </html>
    </exsl:document>
</xsl:template>

<!-- The body element of every page will (optionally) carry  -->
<!-- an id that identifies which document the HTML page is a -->
<!-- portion of.  This requires the author to specify the    -->
<!-- string in the docinfo/document-id element, which comes  -->
<!-- here via the $document-id variable.                     -->
<xsl:template name="document-id">
    <xsl:if test="not($document-id = '')">
        <xsl:attribute name="id">
            <xsl:value-of select="$document-id"/>
        </xsl:attribute>
    </xsl:if>
</xsl:template>

<!-- ################# -->
<!-- Navigational Aids -->
<!-- ################# -->

<!-- Skip to Main Content link -->
<!-- For accessibilty, a link (hidden off-screen)  -->
<!-- which allows a quick by-pass of all the other -->
<!-- navigational elements, direct to content      -->
<xsl:template name="skip-to-content-link">
    <xsl:element name="a">
        <xsl:attribute name="class">
            <xsl:text>assistive</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="href">
            <xsl:text>#content</xsl:text>
        </xsl:attribute>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'skip-to-content'" />
        </xsl:call-template>
    </xsl:element>
</xsl:template>

<!-- Prev/Up/Next URL's -->
<!-- The "tree" versions are simpler, though less natural for a reader -->
<!-- They often return empty and require the use of the Up button      -->
<!-- The "linear" versions are breadth-first search, and so mimic      -->
<!-- the way a reader would encounter the sections in a (linear) book  -->

<!-- TODO: perhaps isolate logic to return nodes and put into "common" -->

<!-- Check if the XML tree has a preceding/following/parent node -->
<!-- Then check if it is a document node (structural)            -->
<!-- If so, compute the URL for the node                         -->
<!-- NB: tree urls maybe enabled as a processing option          -->
<xsl:template match="*" mode="previous-tree-url">
    <xsl:if test="preceding-sibling::*">
        <xsl:variable name="preceding" select="preceding-sibling::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$preceding" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$preceding" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- could be empty -->
</xsl:template>

<xsl:template match="*" mode="next-tree-url">
    <xsl:if test="following-sibling::*">
        <xsl:variable name="following" select="following-sibling::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$following" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$following" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- could be empty -->
</xsl:template>

<!-- Create the URL of the parent document node    -->
<!-- Parent always exists, since the               -->
<!-- structural check fails at <mathbook>          -->
<!-- Identical in tree/linear schemes, up is up    -->
<xsl:template match="*" mode="up-url">
    <xsl:if test="parent::*">
        <xsl:variable name="parent" select="parent::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$parent" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <xsl:apply-templates select="$parent" mode="url" />
        </xsl:if>
    </xsl:if>
    <!-- will be empty precisely at children of <mathbook> -->
</xsl:template>

<!-- Next Linear URL -->
<!-- Breadth-first search, try to descend into first summary link -->
<!-- Else, look sideways for next structural sibling              -->
<!-- Else, go up to parent and look sideways                      -->
<!-- Else done and return empty url                               -->
<xsl:template match="*" mode="next-linear-url">
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true'">
            <!-- Descend once, will always have a child that is structural -->
            <xsl:variable name="first-structural-child" select="*[&STRUCTURAL-FILTER;][1]" />
            <xsl:apply-templates select="$first-structural-child" mode="url" />
            <!-- remainder is a basic check, could be removed -->
            <xsl:variable name="structural">
                <xsl:apply-templates select="$first-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into first node of an intermediate page (<xsl:value-of select="local-name($first-structural-child)" />) that is non-structural; maybe your source has incorrect structure</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
        </xsl:when>
        <xsl:otherwise>
            <!-- try going sideways, which climbs up the tree recursively -->
            <xsl:apply-templates select="." mode="next-sideways-url" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Recursively look sideways to the right, else up     -->
<!-- <mathbook> is not structural, so halt looking there -->
<xsl:template match="*" mode="next-sideways-url">
    <xsl:variable name="url">
        <xsl:if test="following-sibling::*">
            <xsl:variable name="following" select="following-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$following" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <!-- A normal sibling following -->
                <xsl:apply-templates select="$following" mode="url" />
            </xsl:if>
        </xsl:if>
        <!-- could be empty here-->
    </xsl:variable>
    <xsl:value-of select="$url" /> <!-- no harm if empty -->
    <xsl:if test="$url=''">
        <!-- Try going up and then sideways                           -->
        <!-- parent always exists, since <mathbook> is non-structural -->
        <xsl:variable name="parent" select="parent::*[1]" />
        <xsl:variable name="structural">
            <xsl:apply-templates select="$parent" mode="is-structural" />
        </xsl:variable>
        <xsl:if test="$structural='true'">
            <!-- Up a level, so try looking sideways again -->
            <xsl:apply-templates select="$parent" mode="next-sideways-url" />
        </xsl:if>
        <!-- otherwise we are off the top and quit with an empty url -->
    </xsl:if>
</xsl:template>

<!-- Look sideways to the left                                  -->
<!-- If present, move there and descend right branches          -->
<!-- If nothing there, move up once                             -->
<!-- <mathbook> is not structural, so halt if we go up to there -->
<xsl:template match="*" mode="previous-linear-url">
    <xsl:variable name="url">
        <xsl:if test="preceding-sibling::*">
            <xsl:variable name="preceding" select="preceding-sibling::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$preceding" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <!-- A normal sibling precedin, result is just a sentinel-->
                <xsl:apply-templates select="$preceding" mode="url" />
            </xsl:if>
        </xsl:if>
        <!-- could be empty here -->
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$url=''">
            <!-- Go up to parent and get the URL there (not recursive)    -->
            <!-- parent always exists, since <mathbook> is non-structural -->
            <xsl:variable name="parent" select="parent::*[1]" />
            <xsl:variable name="structural">
                <xsl:apply-templates select="$parent" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='true'">
                <xsl:apply-templates select="$parent" mode="url" />
            </xsl:if>
            <!-- otherwise we are off the top and quit with an empty url -->
        </xsl:when>
        <xsl:otherwise>
            <!-- found a preceding sibling, so descend right branches to a leaf -->
            <xsl:apply-templates select="preceding-sibling::*[1]" mode="previous-descent-url"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Descend recursively through summary pages -->
<!-- to a leaf (content) and get URL           -->
<xsl:template match="*" mode="previous-descent-url" >
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='false'">
            <xsl:apply-templates select="." mode="url" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="last-structural-child" select="*[&STRUCTURAL-FILTER;][last()]" />
            <xsl:apply-templates select="$last-structural-child" mode="previous-descent-url" />
            <!-- remainder is a basic check, could be removed -->
            <xsl:variable name="structural">
                <xsl:apply-templates select="$last-structural-child" mode="is-structural" />
            </xsl:variable>
            <xsl:if test="$structural='false'">
                <xsl:message>MBX:ERROR: descending into last node of an intermediate page (<xsl:value-of select="local-name($last-structural-child)" />) that is non-structural</xsl:message>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!--                     -->
<!-- Navigation Sections -->
<!--                     -->

<!-- Button code, <a href=""> when active   -->
<!-- <span> with "disabled" class otherwise -->
<xsl:template match="*" mode="previous-button">
    <xsl:param name="id-label" select="''" />
    <xsl:variable name="previous-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="previous-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="previous-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$previous-url!=''">
            <xsl:element name="a">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">previous-button toolbar-item button</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$previous-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'previous'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'previous-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">previous-button button toolbar-item disabled</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'previous-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="index-button">
    <xsl:if test="$the-index">
        <xsl:variable name="url">
            <xsl:apply-templates select="$the-index" mode="url" />
        </xsl:variable>
        <xsl:element name="a">
            <xsl:attribute name="class">
                <xsl:text>index-button toolbar-item button</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="href">
                <xsl:value-of select="$url" />
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'index-part'" />
                </xsl:call-template>
            </xsl:attribute>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'index-part'" />
            </xsl:call-template>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- The "jump to" navigation on a page with the index -->
<xsl:template match="*" mode="index-jump-nav">
    <span class="mininav">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'jump-to'" />
        </xsl:call-template>
    </span>
    <span class="indexnav">
    <a href="#indexletter-a">A </a>
    <a href="#indexletter-b">B </a>
    <a href="#indexletter-c">C </a>
    <a href="#indexletter-d">D </a>
    <a href="#indexletter-e">E </a>
    <a href="#indexletter-f">F </a>
    <a href="#indexletter-g">G </a>
    <a href="#indexletter-h">H </a>
    <a href="#indexletter-i">I </a>
    <a href="#indexletter-j">J </a>
    <a href="#indexletter-k">K </a>
    <a href="#indexletter-l">L </a>
    <a href="#indexletter-m">M </a>
    <br />
    <a href="#indexletter-n">N </a>
    <a href="#indexletter-o">O </a>
    <a href="#indexletter-p">P </a>
    <a href="#indexletter-q">Q </a>
    <a href="#indexletter-r">R </a>
    <a href="#indexletter-s">S </a>
    <a href="#indexletter-t">T </a>
    <a href="#indexletter-u">U </a>
    <a href="#indexletter-v">V </a>
    <a href="#indexletter-w">W </a>
    <a href="#indexletter-x">X </a>
    <a href="#indexletter-y">Y </a>
    <a href="#indexletter-z">Z </a>
    </span>
</xsl:template>

<xsl:template match="*" mode="next-button">
    <xsl:param name="id-label" select="''" />
    <xsl:variable name="next-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="next-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="next-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$next-url!=''">
            <xsl:element name="a">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">next-button button toolbar-item</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$next-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'next'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'next-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">next-button button toolbar-item disabled</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'next-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="up-button">
    <xsl:param name="id-label" select="''" />
    <!-- up URL is identical for linear, tree logic -->
    <xsl:variable name="up-url">
        <xsl:apply-templates select="." mode="up-url" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$up-url!=''">
            <xsl:element name="a">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">up-button button toolbar-item</xsl:attribute>
                <xsl:attribute name="href">
                    <xsl:value-of select="$up-url" />
                </xsl:attribute>
                <xsl:attribute name="title">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'up'" />
                    </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'up-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="span">
                <xsl:if test="not($id-label='')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$id-label" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="class">up-button button disabled toolbar-item</xsl:attribute>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'up-short'" />
                </xsl:call-template>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="calculator-toggle">
    <button id="calculator-toggle" class="toolbar-item button toggle" title="Show calculator" aria-expanded="false" aria-controls="calculator-container">Calc</button>
</xsl:template>


<!-- Compact Buttons -->
<!-- These get smashed consecutively into a single "tool-bar" -->
<xsl:template match="*" mode="compact-buttons">
    <!-- URL formation, maybe this could be consolidated with above versions -->
    <xsl:variable name="previous-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="previous-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="previous-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="up-url">
        <xsl:apply-templates select="." mode="up-url" />
    </xsl:variable>
    <xsl:variable name="next-url">
        <xsl:choose>
            <xsl:when test="$nav-logic='linear'">
                <xsl:apply-templates select="." mode="next-linear-url" />
            </xsl:when>
            <xsl:when test="$nav-logic='tree'">
                <xsl:apply-templates select="." mode="next-tree-url" />
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <!-- toolbar-item when aligned right, get placed right: first in, first right -->
    <!-- so they apparently seem in the reversed order here and in HTML output    -->
    <!-- Empty URL, then no button                                                -->
    <xsl:if test="not($next-url = '')">
        <div class="toolbar-item">
            <a href="{$next-url}">
                <svg height="50" width="60" viewBox="0 50 110 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="110,100 75,75 0,75 0,125 75,125 " style="fill:darkred;stroke:maroon;stroke-width:1" />
                    <text x="13" y="108" fill="blanchedalmond" font-size="32">next</text>
                </svg>
            </a>
        </div>
    </xsl:if>
    <xsl:if test="not($up-url = '')">
        <div class="toolbar-item">
            <a href="{$up-url}">
                <svg height="50" width="60" viewBox="0 50 80 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="75,75 37,65 0,75 0,125 75,125 " style="fill:blanchedalmond;stroke:burlywood;stroke-width:1" />
                    <text x="13" y="108" fill="maroon" font-size="32">up</text>
                </svg>
            </a>
        </div>
    </xsl:if>
    <xsl:if test="not($previous-url = '')">
        <div class="toolbar-item">
            <a href="{$previous-url}">
                <svg height="50" width="60" viewBox="-10 50 110 100" xmlns="https://www.w3.org/2000/svg" >
                    <polygon points="-10,100 25,75 100,75 100,125 25,125 " style="fill:blanchedalmond;stroke:burlywood;stroke-width:1" />
                    <text x="28" y="108" fill="maroon" font-size="32">prev</text>
                </svg>
            </a>
        </div>
    </xsl:if>
</xsl:template>

<!-- Primary Navigation Panels -->
<!-- ToC, Prev/Up/Next/Annotation buttons  -->
<!-- Also organized for small screen modes -->
<xsl:template match="*" mode="primary-navigation">
    <nav id="primary-navbar" class="navbar">
        <div class="container">
            <!-- Several buttons across the top -->
            <div class="navbar-top-buttons">
                <xsl:element name="button">
                    <xsl:attribute name="class">
                        <xsl:text>sidebar-left-toggle-button button active</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="aria-label">
                        <xsl:text>Show or hide table of contents sidebar</xsl:text>
                    </xsl:attribute>
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </xsl:element>
                <!-- Prev/Up/Next buttons on top, according to options -->
                <xsl:choose>
                    <xsl:when test="$nav-style = 'full'">
                        <xsl:element name="div">
                            <xsl:attribute name="class">
                                <!-- 3 or 4 buttons, depending on Up Button choice -->
                                <xsl:choose>
                                    <xsl:when test="$nav-upbutton='yes'">
                                        <xsl:text>tree-nav toolbar toolbar-divisor-3</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="$nav-upbutton='no'">
                                        <xsl:text>tree-nav toolbar toolbar-divisor-2</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <!-- A page either has an/the index as    -->
                            <!-- a child, and gets the "jump to" bar, -->
                            <!-- or it deserves an index button       -->
                            <xsl:choose>
                                <xsl:when test="index-list">
                                    <xsl:apply-templates select="." mode="index-jump-nav" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="." mode="index-button" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <!-- Button to show/hide the calculator -->
                            <xsl:if test="$b-has-calculator">
                                <xsl:call-template name="calculator-toggle" />
                                <xsl:call-template name="calculator" />
                            </xsl:if>
                            <!-- Runestone user menu -->
                            <!-- "Bust w/ Silhoutte" is U+1F464, used as menu icon    -->
                            <!-- Templating {{ and }} really wreak havoc in  a/@href  -->
                            <!-- since the outer pair looks like an AVT and the inner -->
                            <!-- pair gets percent-encoded (which we cannot control   -->
                            <!-- in XSLT 1.0). So we use the odd delimiters defined   -->
                            <!-- above and Runestone will use them instead            -->
                            <xsl:if test="$b-host-runestone">
                                <div class="dropdown">
                                    <xsl:text>&#x1F464;</xsl:text>
                                    <div class="dropdown-content">
                                        <xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> if auth.user: </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <a href="{$rso}=URL('assignments','chooseAssignment'){$rsc}">Assignments</a>
                                        <a href="{$rso}=URL('assignments','practice'){$rsc}">Practice</a>
                                        <xsl:value-of select="$rso"/><xsl:text> if settings.academy_mode: </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <hr/>
                                        <a href='/{$rso}=request.application{$rsc}/default/courses'>Change Course</a>
                                        <xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> pass </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> pass </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> if auth.user: </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <hr/>
                                        <a href='/{$rso}=request.application{$rsc}/admin/index'>Instructor's Page</a>
                                        <xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> pass </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <hr/>
                                        <xsl:value-of select="$rso"/><xsl:text> pass </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> if not settings.lti_only_mode: </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> if auth.user: </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <a href="{$rso}=URL('dashboard','studentreport'){$rsc}">Progress Page</a>
                                        <hr/>
                                        <a href="/{$rso}=request.application{$rsc}/default/user/profile">Edit Profile</a>
                                        <a href="/{$rso}=request.application{$rsc}/default/user/change_password">Change Password</a>
                                        <a href="{$rso}=URL('default','user/logout'){$rsc}">Log Out</a>
                                        <xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> else: </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <a href="{$rso}=URL('default','user/register'){$rsc}">Register</a>
                                        <a href="{$rso}=URL('default','user/login'){$rsc}">Login</a>
                                        <xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> pass </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> else: </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                        <a href="{$rso}=URL('assignments','index'){$rsc}">Progress Page</a>
                                        <xsl:text>&#xa;</xsl:text>
                                        <xsl:value-of select="$rso"/><xsl:text> pass </xsl:text><xsl:value-of select="$rsc"/><xsl:text>&#xa;</xsl:text>
                                    </div>
                                </div>
                            </xsl:if>
                            <!-- Span to encase Prev/Up/Next buttons and float right    -->
                            <!-- Each button gets an id for keypress recognition/action -->
                            <xsl:element name="span">
                                <xsl:attribute name="class">
                                    <xsl:text>threebuttons</xsl:text>
                                </xsl:attribute>
                                <xsl:apply-templates select="." mode="previous-button">
                                    <xsl:with-param name="id-label" select="'previousbutton'" />
                                </xsl:apply-templates>
                                <xsl:if test="$nav-upbutton='yes'">
                                    <xsl:apply-templates select="." mode="up-button">
                                        <xsl:with-param name="id-label" select="'upbutton'" />
                                    </xsl:apply-templates>
                                </xsl:if>
                                <xsl:apply-templates select="." mode="next-button">
                                    <xsl:with-param name="id-label" select="'nextbutton'" />
                                </xsl:apply-templates>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$nav-style = 'compact'">
                        <div class="toolbar toolbar-align-right">
                            <xsl:apply-templates select="." mode="compact-buttons" />
                        </div>
                    </xsl:when>
                </xsl:choose>
                <!-- Annotations button was once here, see GitHub issue -->
                <!-- https://github.com/rbeezer/mathbook/issues/1010    -->
            </div>
            <!-- Bottom buttons, for mobile UI -->
            <xsl:element name="div">
                <xsl:attribute name="class">
                    <!-- 3 or 4 buttons, depending on Up Button choice -->
                    <xsl:choose>
                        <xsl:when test="$nav-upbutton='yes'">
                            <xsl:text>navbar-bottom-buttons toolbar toolbar-divisor-4</xsl:text>
                        </xsl:when>
                        <xsl:when test="$nav-upbutton='no'">
                            <xsl:text>navbar-bottom-buttons toolbar toolbar-divisor-3</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <!-- "contents" button is uniform across logic -->
                <button class="sidebar-left-toggle-button button toolbar-item active">
                    <xsl:call-template name="type-name">
                        <xsl:with-param name="string-id" select="'toc'" />
                    </xsl:call-template>
                </button>
                <!-- Prev/Up/Next buttons on top, according to options -->
                <!-- in order, for mobile interface on bottom          -->
                <!-- We do not pass an $id-label right now             -->
                <xsl:apply-templates select="." mode="previous-button" />
                <xsl:if test="$nav-upbutton='yes'">
                    <xsl:apply-templates select="." mode="up-button" />
                </xsl:if>
                <xsl:apply-templates select="." mode="next-button" />
                <!-- Annotations button was once here, see GitHub issue -->
                <!-- https://github.com/rbeezer/mathbook/issues/1010    -->
                <!-- increment the toolbar-divisor-4/5 if it returns    -->
             </xsl:element>
        </div>
    </nav>
</xsl:template>

<!-- Sidebars -->
<!-- Two HTML aside's for ToC (left), Annotations (right)       -->
<!-- Need to pass node down into "toc-items", which is per-page -->
<xsl:template match="*" mode="sidebars">
    <!-- ARIA: "navigation" role for sidebar ToC                 -->
    <!-- HTML5 nav will be a "navigation" landmark automatically -->
    <!-- Maybe this will change at some point                    -->
    <div id="sidebar-left" class="sidebar" role="navigation">
        <div class="sidebar-content">
            <nav id="toc">
              <ul>
                 <xsl:apply-templates select="." mode="toc-items" />
              </ul>
            </nav>
            <div class="extras">
                <nav>
                    <xsl:if test="$docinfo/feedback">
                        <xsl:call-template name="feedback-link" />
                    </xsl:if>
                    <xsl:call-template name="mathbook-link" />
                    <xsl:call-template name="powered-by-mathjax" />
                </nav>
            </div>
        </div>
    </div>
    <!-- Content here appears in odd places if turned sidebar is turned off
        <aside id="sidebar-right" class="sidebar">
            <div class="sidebar-content">Mock right sidebar content</div>
        </aside> -->
</xsl:template>

<xsl:template name="calculator">
    <xsl:if test="contains($html-calculator,'geogebra')">
        <div id="calculator-container" class="calculator-container" style="display: none; z-index:100;">
            <div id="geogebra-calculator"></div>
        </div>
        <script>
            <xsl:text>&#xa;</xsl:text>
            <!-- Here is where we could initialize some things to customize the display.                    -->
            <!-- But the customization should be different depending on classic, graphing, geometry, or 3d. -->
            <!-- For instance geometry probably does not benefit from showing the grid.                     -->
            <!-- If this is not in use, no need to set "appletOnLoad" further below.                        -->
            <!-- var onLoad = function(applet) {
                applet.setAxisLabels(1,'x','y','z');
                applet.setGridVisible(1,true);
                applet.showFullscreenButton(true);
            }; -->
            <xsl:text>var ggbApp = new GGBApplet({"appName": "</xsl:text>
            <xsl:value-of select="substring-after($html-calculator,'-')"/>
            <xsl:text>",&#xa;</xsl:text>
            <!-- width and height are required parameters                   -->
            <!-- All the rest is customizing some things away from defaults -->
            <!-- (or maybe in some cases explicitly using the defaults)     -->
            <!-- The last parameters have to do with scaling. This combination allows the 330x600 applet -->
            <!-- to scale up or down to the width of the contining div with class calculator-container.  -->
            <!-- The applet's height will scale proportionately.                                         -->
            <xsl:text>    "width": 330,&#xa;</xsl:text>
            <xsl:text>    "height": 600,&#xa;</xsl:text>
            <xsl:text>    "showToolBar": true,&#xa;</xsl:text>
            <xsl:text>    "showAlgebraInput": true,&#xa;</xsl:text>
            <xsl:text>    "perspective": "G/A",&#xa;</xsl:text>
            <xsl:text>    "algebraInputPosition": "bottom",&#xa;</xsl:text>
            <!--          "appletOnLoad": onLoad, -->
            <xsl:text>    "scaleContainerClass": "calculator-container",&#xa;</xsl:text>
            <xsl:text>    "allowUpscale": true,&#xa;</xsl:text>
            <xsl:text>    "autoHeight": true,&#xa;</xsl:text>
            <xsl:text>    "disableAutoScale": false},&#xa;</xsl:text>
            <xsl:text>true);&#xa;</xsl:text>
            <!--   The calculator is created by                    -->
            <!--   ggbApp.inject('geogebra-calculator');           -->
            <!--   which is inserted by code in pretext_add_on.js  -->
        </script>
    </xsl:if>
</xsl:template>


<!-- Table of Contents Contents (Items) -->
<!-- Includes "active" class for enclosing outer node              -->
<!-- Node set equality and subset based on unions of subtrees, see -->
<!-- http://www.xml.com/cookbooks/xsltckbk/solution.csp?day=5      -->
<!-- Displayed text is simple titles                               -->
<!-- TODO: split out inner link formation, outer link formation? -->
<xsl:template match="*" mode="toc-items">
    <xsl:if test="$b-has-toc">
        <!-- Decrement level for books with parts, -->
        <!-- then 0 is exceptional - parts only    -->
        <xsl:variable name="adjusted-toc-level">
            <xsl:choose>
                <xsl:when test="not($parts = 'absent')">
                    <xsl:value-of select="$toc-level - 1" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$toc-level" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Subtree for page this sidebar will adorn -->
        <xsl:variable name="this-page-node" select="self::*" />
        <!-- If a book has parts, they appear as top-level items.       -->
        <!-- Front matter and back matter will also appear as top-level -->
        <!-- items, which is especially ueful when they get renamed     -->
        <!-- (eg "Reference" for "backmatter").  Children of backmatter -->
        <!-- are like "book/chapter" or "article/section" and also get  -->
        <!-- a top-level appearance.                                    -->
        <xsl:for-each select="$root/book/*|$root/book/part/*|$root/article/*|$root/book/backmatter/*|$root/article/backmatter/*">
            <xsl:variable name="structural">
                <xsl:apply-templates select="." mode="is-structural" />
            </xsl:variable>
            <!-- Bypass chapters for compact ToC for book with parts -->
            <xsl:if test="$structural='true' and not(($adjusted-toc-level = 0) and self::chapter)">
                <!-- Subtree represented by this ToC item -->
                <xsl:variable name="outer-node" select="self::*" />
                <xsl:variable name="outer-url">
                    <xsl:apply-templates select="." mode="url"/>
               </xsl:variable>
               <!-- text of anchor's class, active if a match, otherwise plain -->
               <!-- Based on node-set union size; "frontmatter", "backmatter", -->
               <!-- "part" are for styling                                     -->
               <xsl:variable name="class">
                    <xsl:text>link</xsl:text>
                    <xsl:if test="self::frontmatter">
                        <xsl:text> frontmatter</xsl:text>
                    </xsl:if>
                    <xsl:if test="self::backmatter">
                        <xsl:text> backmatter</xsl:text>
                    </xsl:if>
                    <xsl:if test="self::part">
                        <xsl:text> part</xsl:text>
                    </xsl:if>
                    <xsl:if test="count($this-page-node|$outer-node) = 1" >
                        <xsl:text> active</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="outer-pid">
                    <xsl:apply-templates select="." mode="html-id" />
                </xsl:variable>
                <!-- The link itself -->
                <li class="{$class}">
                    <xsl:element name="a">
                        <xsl:attribute name="href">
                            <xsl:value-of select="$outer-url" />
                        </xsl:attribute>
                        <xsl:attribute name="data-scroll">
                            <xsl:value-of select="$outer-pid" />
                        </xsl:attribute>
                        <xsl:variable name="num"><xsl:apply-templates select="." mode="number" /></xsl:variable>
                        <xsl:if test="$num!=''">
                            <span class="codenumber">
                                <xsl:value-of select="$num" />
                            </span>
                            <xsl:text> </xsl:text>
                        </xsl:if>
                        <span class="title">
                            <xsl:apply-templates select="." mode="title-short" />
                        </span>
                    </xsl:element>
                <!-- Any "part" or "backmatter" displayed as top-level items     -->
                <!-- have children that are also considered as top-level items,  -->
                <!-- so we do not examine the children of "part" or "backmatter" -->
                <!-- as potential second-level items. -->
                <xsl:if test="not(self::part or self::backmatter) and $adjusted-toc-level > 1">
                    <!-- a level 1 ToC entry may not have any structural      -->
                    <!-- descendants, so we build a possible sublist in a     -->
                    <!-- variable and do not use it if it ends up being empty -->
                    <xsl:variable name="sublist">
                        <xsl:for-each select="./*">
                            <xsl:variable name="inner-structural">
                                <xsl:apply-templates select="." mode="is-structural" />
                            </xsl:variable>
                            <xsl:if test="$inner-structural='true'">
                                <!-- Subtree represented by this ToC item -->
                                <xsl:variable name="inner-node" select="self::*" />
                                <xsl:variable name="inner-url">
                                    <xsl:apply-templates select="." mode="url" />
                                </xsl:variable>
                                <xsl:variable name="inner-pid">
                                    <xsl:apply-templates select="." mode="html-id" />
                                </xsl:variable>
                                <li>
                                    <xsl:element name="a">
                                        <xsl:attribute name="href">
                                            <xsl:value-of select="$inner-url" />
                                        </xsl:attribute>
                                        <xsl:attribute name="data-scroll">
                                            <xsl:value-of select="$inner-pid" />
                                        </xsl:attribute>
                                        <!-- Add if an "active" class if this is where we are -->
                                        <xsl:if test="count($this-page-node|$inner-node) = 1">
                                            <xsl:attribute name="class">active</xsl:attribute>
                                        </xsl:if>
                                        <xsl:apply-templates select="." mode="title-short" />
                                    </xsl:element>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- not clear why this is the right test         -->
                    <!-- make an unordered list if there is a sublist -->
                    <xsl:if test="not($sublist='')">
                        <ul>
                            <xsl:copy-of select="$sublist" />
                        </ul>
                    </xsl:if>
                </xsl:if>  <!-- end $toc-level > 1 -->
                </li>
            </xsl:if>  <!-- end structural, level 1 -->
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<!-- Feedback Button goes at the bottom (in "extras") -->
<!-- Text from docinfo, or localized string           -->
<!-- Target URL from docinfo                          -->
<xsl:template name="feedback-link">
    <!-- Possibly an empty URL -->
    <a class="feedback-link" href="{$docinfo/feedback/url}" target="_blank">
        <xsl:choose>
            <xsl:when test="$docinfo/feedback/text">
                <xsl:apply-templates select="$docinfo/feedback/text" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="type-name">
                    <xsl:with-param name="string-id" select="'feedback'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </a>
</xsl:template>

<!-- Branding in "extras", mostly hard-coded        -->
<!-- HTTPS for authors delivering from secure sites -->
<xsl:template name="mathbook-link">
    <a class="mathbook-link" href="https://pretextbook.org">
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'authored'" />
        </xsl:call-template>
    </a>
</xsl:template>

<!-- MathJax Logo for bottom of left sidebar -->
<xsl:template name="powered-by-mathjax">
    <a href="https://www.mathjax.org">
        <img title="Powered by MathJax" src="https://www.mathjax.org/badge/badge.gif" alt="Powered by MathJax" />
    </a>
</xsl:template>

<!-- Tooltip Text -->
<!-- Text for an HTML "title" attribute      -->
<!-- Always leverage the PreTeXt title, e.g. -->
<!-- don't use "caption", it could be BIG    -->
<xsl:template match="*" mode="tooltip-text">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:variable name="num">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:if test="not($num = '')">
        <xsl:text> </xsl:text>
        <xsl:value-of select="$num" />
    </xsl:if>
    <xsl:if test="title">
        <xsl:text>: </xsl:text>
        <xsl:apply-templates select="." mode="title-short" />
    </xsl:if>
</xsl:template>

<!-- MathJax header                                             -->
<!-- XML manages equation numbers                               -->
<!-- Config MathJax to make anchor names on equations           -->
<!--   these are just the contents of the \label on an equation -->
<!--   which we provide as the xml:id of the equation           -->
<!-- Note: we could set \label with something different         -->
<!-- extpfeil.js provides extensible arrows: \xmapsto, \xtofrom -->
<!--   \xtwoheadrightarrow, \xtwoheadleftarrow, \xlongequal     -->
<!--   equivalent to the LaTeX package of the same name         -->
<!-- Autobold extension is critical for captions (bold'ed) that -->
<!-- have mathematics in them (suggested by P. Krautzberger)    -->
<!-- "useLabelIDs" makes HTML @id "mjx-eqn-foo" from \label{}   -->
<xsl:template name="mathjax">
    <!-- mathjax configuration -->
    <xsl:element name="script">
        <xsl:text>window.MathJax = {&#xa;</xsl:text>
        <xsl:text>  tex: {&#xa;</xsl:text>
        <xsl:text>    inlineMath: [['\\(','\\)']],&#xa;</xsl:text>
        <xsl:text>    tags: "none",&#xa;</xsl:text>
        <xsl:text>    useLabelIds: true,&#xa;</xsl:text>
        <xsl:text>    tagSide: "right",&#xa;</xsl:text>
        <xsl:text>    tagIndent: ".8em",&#xa;</xsl:text>
        <xsl:text>    packages: {'[+]': ['base', 'extpfeil', 'ams', 'amscd', 'newcommand', 'knowl'</xsl:text>
        <!-- only add in faux sfrac package (below) if indicated -->
        <xsl:if test="$b-has-sfrac">
            <xsl:text>, 'sfrac'</xsl:text>
        </xsl:if>
        <xsl:text>]}&#xa;</xsl:text>
        <xsl:text>  },&#xa;</xsl:text>
        <xsl:text>  options: {&#xa;</xsl:text>
        <xsl:text>    ignoreHtmlClass: "tex2jax_ignore",&#xa;</xsl:text>
        <xsl:text>    processHtmlClass: "has_am",&#xa;</xsl:text>
        <xsl:if test="$b-has-webwork-reps or $b-has-sage">
            <xsl:text>    renderActions: {&#xa;</xsl:text>
            <xsl:text>        findScript: [10, function (doc) {&#xa;</xsl:text>
            <xsl:text>            document.querySelectorAll('script[type^="math/tex"]').forEach(function(node) {&#xa;</xsl:text>
            <xsl:text>                var display = !!node.type.match(/; *mode=display/);&#xa;</xsl:text>
            <xsl:text>                var math = new doc.options.MathItem(node.textContent, doc.inputJax[0], display);&#xa;</xsl:text>
            <xsl:text>                var text = document.createTextNode('');&#xa;</xsl:text>
            <xsl:text>                node.parentNode.replaceChild(text, node);&#xa;</xsl:text>
            <xsl:text>                math.start = {node: text, delim: '', n: 0};&#xa;</xsl:text>
            <xsl:text>                math.end = {node: text, delim: '', n: 0};&#xa;</xsl:text>
            <xsl:text>                doc.math.push(math);&#xa;</xsl:text>
            <xsl:text>            });&#xa;</xsl:text>
            <xsl:text>        }, '']&#xa;</xsl:text>
            <xsl:text>    },&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>  },&#xa;</xsl:text>
        <xsl:text>  chtml: {&#xa;</xsl:text>
        <xsl:text>    scale: 0.88,&#xa;</xsl:text>
        <xsl:text>    mtextInheritFont: true&#xa;</xsl:text>
        <xsl:text>  },&#xa;</xsl:text>
        <xsl:text>  loader: {&#xa;</xsl:text>
        <xsl:text>    load: ['input/asciimath', '[tex]/extpfeil', '[tex]/amscd', '[tex]/newcommand', '[pretext]/mathjaxknowl3.js'],&#xa;</xsl:text>
        <xsl:text>    paths: {pretext: "https://pretextbook.org/js/lib"},&#xa;</xsl:text>
        <xsl:text>  },&#xa;</xsl:text>
        <!-- trailing comma is legal as we lead into optional beveled fraction support -->
        <xsl:if test="$b-has-sfrac">
            <xsl:text>/* support for the sfrac command in MathJax (Beveled fraction) */&#xa;</xsl:text>
            <xsl:text>  startup: {&#xa;</xsl:text>
            <xsl:text>    ready() {&#xa;</xsl:text>
            <xsl:text>      //&#xa;</xsl:text>
            <xsl:text>      // Creating a simple "sfrac" package on-the-fly&#xa;</xsl:text>
            <xsl:text>      //&#xa;</xsl:text>
            <xsl:text>      const Configuration = MathJax._.input.tex.Configuration.Configuration;&#xa;</xsl:text>
            <xsl:text>      const CommandMap = MathJax._.input.tex.SymbolMap.CommandMap;&#xa;</xsl:text>
            <xsl:text>      &#xa;</xsl:text>
            <xsl:text>      new CommandMap('sfrac', {&#xa;</xsl:text>
            <xsl:text>        sfrac: 'SFrac'&#xa;</xsl:text>
            <xsl:text>        }, {&#xa;</xsl:text>
            <xsl:text>        SFrac(parser, name) {&#xa;</xsl:text>
            <xsl:text>        const num = parser.ParseArg(name);&#xa;</xsl:text>
            <xsl:text>        const den = parser.ParseArg(name);&#xa;</xsl:text>
            <xsl:text>        const frac = parser.create('node', 'mfrac', [num, den], {bevelled: true});&#xa;</xsl:text>
            <xsl:text>        parser.Push(frac);&#xa;</xsl:text>
            <xsl:text>        }&#xa;</xsl:text>
            <xsl:text>      });&#xa;</xsl:text>
            <xsl:text>      //&#xa;</xsl:text>
            <xsl:text>      // Create the package for the overridden macros&#xa;</xsl:text>
            <xsl:text>      //&#xa;</xsl:text>
            <xsl:text>      Configuration.create('sfrac', {&#xa;</xsl:text>
            <xsl:text>        handler: {macro: ['sfrac']}&#xa;</xsl:text>
            <xsl:text>      });&#xa;</xsl:text>
            <xsl:text>      &#xa;</xsl:text>
            <xsl:text>    MathJax.startup.defaultReady();&#xa;</xsl:text>
            <xsl:text>    }&#xa;</xsl:text>
            <xsl:text>  },&#xa;</xsl:text>
        </xsl:if>
        <!-- optional presentation mode gets clickable, large math -->
        <xsl:if test="$b-html-presentation">
            <xsl:text>  options: {&#xa;</xsl:text>
            <xsl:text>    menuOptions: {&#xa;</xsl:text>
            <xsl:text>      settings: {&#xa;</xsl:text>
            <xsl:text>        zoom: 'Click',&#xa;</xsl:text>
            <xsl:text>        zscale: '300%',&#xa;</xsl:text>
            <xsl:text>      },&#xa;</xsl:text>
            <xsl:text>    }&#xa;</xsl:text>
            <xsl:text>  },&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>};&#xa;</xsl:text>
    </xsl:element>
    <!-- mathjax javascript -->
    <xsl:element name="script">
        <xsl:attribute name="src">
            <xsl:text>https://cdn.jsdelivr.net/npm/mathjax@3/es5/</xsl:text>
            <!-- CHTML is the default, SVG is for debugging -->
            <xsl:choose>
                <xsl:when test="$debug.mathjax.svg = 'yes'">
                    <xsl:text>tex-svg.js</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>tex-chtml.js</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- jQuery, SageCell -->
<!-- jQuery used by sage, webwork, knowls, so load always  -->
<!--  * essential to use the version from sagemath.org *   -->
<!-- We never know if a Sage cell might be inside a knowl, -->
<!-- so we load the relevant JavaScript onto every page if -->
<!-- a cell occurs *anywhere* in the entire document       -->
<xsl:template name="sagecell-code">
    <xsl:if test="$b-has-sage">
        <script src="https://sagecell.sagemath.org/embedded_sagecell.js"></script>
    </xsl:if>
</xsl:template>

<!-- Sage Cell Setup -->
<!-- TODO: internationalize button labels, strings below -->
<!-- TODO: make an initialization cell which links with the sage-compute cells -->

<!-- A template for a generic makeSageCell script element -->
<!-- Parameters: language, evaluate-button text -->
<xsl:template name="makesagecell">
    <xsl:param name="language-attribute" />
    <xsl:param name="language-text" />
    <xsl:element name="script">
        <xsl:text>$(function () {&#xa;</xsl:text>
        <xsl:text>    // Make *any* div with class 'sagecell-</xsl:text>
            <xsl:value-of select="$language-attribute" />
        <xsl:text>' an executable Sage cell&#xa;</xsl:text>
        <xsl:text>    // Their results will be linked, only within language type&#xa;</xsl:text>
        <xsl:text>    sagecell.makeSagecell({inputLocation: 'div.sagecell-</xsl:text>
            <xsl:value-of select="$language-attribute" />
        <xsl:text>',&#xa;</xsl:text>
        <xsl:text>                           linked: true,&#xa;</xsl:text>
        <xsl:text>                           languages: ['</xsl:text>
            <xsl:value-of select="$language-attribute" />
        <xsl:text>'],&#xa;</xsl:text>
        <xsl:text>                           evalButtonText: '</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'evaluate'" />
            </xsl:call-template>
            <xsl:text> (</xsl:text>
            <xsl:value-of select="$language-text" />
            <xsl:text>)</xsl:text>
        <xsl:text>'});&#xa;</xsl:text>
        <xsl:text>});&#xa;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- template for a "display only" version -->
<xsl:template name="sagecell-display">
    <xsl:element name="script">
        <xsl:text>$(function () {&#xa;</xsl:text>
        <xsl:text>    // Make *any* div with class 'sage-display' a visible, uneditable Sage cell&#xa;</xsl:text>
        <xsl:text>    sagecell.makeSagecell({inputLocation: 'div.sage-display',&#xa;</xsl:text>
        <xsl:text>                           editor: 'codemirror-readonly',&#xa;</xsl:text>
        <xsl:text>                           hide: ['evalButton', 'editorToggle', 'language']});&#xa;</xsl:text>
        <xsl:text>});&#xa;</xsl:text>
    </xsl:element>
</xsl:template>

<!-- All languages, linked only to similar   -->
<!-- Generic button, drop-down for languages -->
<xsl:template name="sagecell-practice">
    <xsl:element name="script">
        <xsl:text>$(function () {&#xa;</xsl:text>
        <xsl:text>    // Make *any* div with class 'sagecell-practice' an executable Sage cell&#xa;</xsl:text>
        <xsl:text>    // Their results will be linked, only within language type&#xa;</xsl:text>
        <xsl:text>    sagecell.makeSagecell({inputLocation: 'div.sagecell-practice',&#xa;</xsl:text>
        <xsl:text>                           linked: true,&#xa;</xsl:text>
        <xsl:text>                           languages: sagecell.allLanguages,&#xa;</xsl:text>
        <xsl:text>                           evalButtonText: '</xsl:text>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'evaluate'" />
            </xsl:call-template>
        <xsl:text>'});&#xa;</xsl:text>
        <xsl:text>});&#xa;</xsl:text>
    </xsl:element>
</xsl:template>


<!-- Make Sage Cell Server headers on a per-language basis -->
<!-- Examine the subtree of the page, which can still be   -->
<!-- excessive for summary pages, so room for improvement  -->
<xsl:template match="*" mode="sagecell">
    <!-- making a Sage version now very liberally, could be more precise -->
    <xsl:if test=".//sage">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">sage</xsl:with-param>
            <xsl:with-param name="language-text">Sage</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@type='display']">
        <xsl:call-template name="sagecell-display" />
    </xsl:if>

    <xsl:if test=".//sage[@type='practice']">
        <xsl:call-template name="sagecell-practice" />
    </xsl:if>

    <!-- 2016-06-13: sage, gap, gp, html, maxima, octave, python, r, and singular -->

    <xsl:if test=".//sage[@language='gap']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>gap</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">GAP</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='gp']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>gp</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">GP</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='html']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>html</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">HTML</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='maxima']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>maxima</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Maxima</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='octave']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>octave</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Octave</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='python']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>python</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Python</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='r']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>r</xsl:text>
                <!-- <xsl:text></xsl:text> -->
            </xsl:with-param>
            <xsl:with-param name="language-text">R</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <xsl:if test=".//sage[@language='singular']">
        <xsl:call-template name="makesagecell">
            <xsl:with-param name="language-attribute">
                <xsl:text>singular</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="language-text">Singular</xsl:with-param>
        </xsl:call-template>
    </xsl:if>

</xsl:template>


<!-- Program Listings highlighted by Prism -->
<xsl:template name="syntax-highlight-header">
    <xsl:if test="$b-has-program">
        <link href="https://unpkg.com/prismjs@v1.22.0/themes/prism.css" rel="stylesheet"/>
    </xsl:if>
</xsl:template>

<xsl:template name="syntax-highlight-footer">
    <xsl:if test="$b-has-program">
        <script src="https://unpkg.com/prismjs@v1.22.0/components/prism-core.min.js"></script>
        <script src="https://unpkg.com/prismjs@v1.22.0/plugins/autoloader/prism-autoloader.min.js"></script>
    </xsl:if>
</xsl:template>

<!-- JS setup for a Google Custom Search Engine box -->
<!-- Empty if not enabled via presence of cx number -->
<xsl:template name="google-search-box-js">
    <xsl:if test="$b-google-cse">
        <script async="">
            <xsl:attribute name="src">
                <xsl:text>https://cse.google.com/cse.js?cx=</xsl:text>
                <xsl:value-of select="$google-search-cx"/>
            </xsl:attribute>
        </script>
    </xsl:if>
</xsl:template>

<!-- Div for Google Search -->
<!-- https://developers.google.com/custom-search/docs/element -->
<!-- Empty if not enabled via presence of cx number           -->
<xsl:template name="google-search-box">
    <xsl:if test="$b-google-cse">
        <!-- ARIA: "search" role for Google Search div/wrapper -->
        <div class="searchwrapper" role="search">
            <div class="gcse-search" />
        </div>
    </xsl:if>
</xsl:template>

<!-- Knowl header -->
<xsl:template name="knowl">
    <script src="{$html.js.server}/js/lib/knowl.js"></script>
    <!-- Variables are defined to defaults in knowl.js and  -->
    <!-- we can override them with new values here          -->
    <xsl:comment>knowl.js code controls Sage Cells within knowls</xsl:comment>
    <script>
        <!-- button text, internationalized -->
        <xsl:text>sagecellEvalName='</xsl:text>
        <xsl:call-template name="type-name">
            <xsl:with-param name="string-id" select="'evaluate'" />
        </xsl:call-template>
        <xsl:text> (</xsl:text>
        <!-- $language-text hard-coded since language  -->
        <!-- support within knowls is not yet settled -->
        <xsl:text>Sage</xsl:text>
        <xsl:text>)</xsl:text>
        <xsl:text>';&#xa;</xsl:text>
    </script>
</xsl:template>

<!-- Header information for favicon -->
<!-- Needs two image files in root of HTML output -->
<xsl:template name="favicon">
    <xsl:if test="$docinfo/html/favicon">
        <xsl:variable name="res32">
            <xsl:if test="$b-managed-directories">
                <xsl:value-of select="$external-directory"/>
            </xsl:if>
            <xsl:text>favicon/favicon-32x32.png</xsl:text>
        </xsl:variable>
        <xsl:variable name="res16">
            <xsl:if test="$b-managed-directories">
                <xsl:value-of select="$external-directory"/>
            </xsl:if>
            <xsl:text>favicon/favicon-16x16.png</xsl:text>
        </xsl:variable>
        <link rel="icon" type="image/png" sizes="32x32" href="{$res32}"/>
        <link rel="icon" type="image/png" sizes="16x16" href="{$res16}"/>
    </xsl:if>
</xsl:template>

<!-- Mathbook Javascript header -->
<xsl:template name="mathbook-js">
    <!-- condition first on toc present? -->
    <script src="{$html.js.server}/js/lib/jquery.min.js"></script>
    <script src="{$html.js.server}/js/lib/jquery.sticky.js" ></script>
    <script src="{$html.js.server}/js/lib/jquery.espy.min.js"></script>
    <script src="{$html.js.server}/js/{$html.js.version}/pretext.js"></script>
    <script src="{$html.js.server}/js/{$html.js.version}/pretext_add_on.js"></script>
</xsl:template>

<!-- Font header -->
<!-- Google Fonts -->
<!-- Text: Open Sans by default (was: Istok Web font, regular and italic (400), bold (700)) -->
<!-- Code: Inconsolata, regular (400), bold (700) (was: Source Code Pro regular (400))      -->
<!-- (SourceCodePro being removed) -->
<xsl:template name="fonts">
    <link href='https://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,600italic' rel='stylesheet' type='text/css' />
    <link href='https://fonts.googleapis.com/css?family=Inconsolata:400,700&amp;subset=latin,latin-ext' rel='stylesheet' type='text/css' />
</xsl:template>

<!-- Hypothes.is Annotations -->
<!-- Configurations are the defaults as of 2016-11-04   -->
<!-- async="" is a guessed-hack, docs ahve no attribute -->
<xsl:template name="hypothesis-annotation">
    <xsl:if test="$b-activate-hypothesis">
        <script type="application/json" class="js-hypothesis-config">
        <xsl:text>{&#xa;</xsl:text>
        <xsl:text>    "openLoginForm": false;</xsl:text>
        <xsl:text>    "openSidebar": false;</xsl:text>
        <xsl:text>    "showHighlights": true;</xsl:text>
        <xsl:text>}</xsl:text>
        </script>
        <script src="https://hypothes.is/embed.js" async=""></script>
    </xsl:if>
</xsl:template>

<!-- GeoGebra -->
<!-- The JS necessary to load the "App" for a generic calculator -->
<xsl:template name="geogebra">
    <xsl:if test="$b-has-calculator and contains($html-calculator,'geogebra')">
        <script src="https://cdn.geogebra.org/apps/deployggb.js"></script>
    </xsl:if>
</xsl:template>

<!-- JSXGraph -->
<xsl:template name="jsxgraph">
    <xsl:if test="$b-has-jsxgraph">
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraph.css" />
        <script src="https://cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.6/jsxgraphcore.js"></script>
    </xsl:if>
</xsl:template>

<!-- CSS header -->
<!-- The "one-css" template is defined elsewhere -->
<xsl:template name="css">
    <link href="{$html.css.server}/css/{$html.css.version}/pretext.css" rel="stylesheet" type="text/css" />
    <link href="{$html.css.server}/css/{$html.css.version}/pretext_add_on.css" rel="stylesheet" type="text/css" />
    <link href="{$html.css.server}/css/{$html.css.version}/{$html-css-bannerfile}" rel="stylesheet" type="text/css" />
    <link href="{$html.css.server}/css/{$html.css.version}/{$html-css-tocfile}" rel="stylesheet" type="text/css" />
    <link href="{$html.css.server}/css/{$html.css.version}/{$html-css-knowlfile}" rel="stylesheet" type="text/css" />
    <link href="{$html.css.server}/css/{$html.css.version}/{$html-css-stylefile}" rel="stylesheet" type="text/css"/>
    <link href="{$html.css.server}/css/{$html.css.version}/{$html-css-colorfile}" rel="stylesheet" type="text/css" />
    <link href="{$html.css.server}/css/{$html.css.version}/setcolors.css" rel="stylesheet" type="text/css" />
    <!-- If extra CSS is specified, then unpack multiple CSS files -->
    <!-- The prepared list (extra blank space) will cause failure  -->
    <!-- if $html.css.extra is empty (i.e. not specified)          -->
    <xsl:if test="not($html.css.extra = '')">
        <xsl:call-template name="one-css">
            <xsl:with-param name="token-list">
                <xsl:call-template name="prepare-token-list">
                    <xsl:with-param name="token-list" select="$html.css.extra" />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!-- For testing purposes, make a "developer.css" possible and always available -->
    <xsl:comment> 2019-10-12: Temporary - CSS file for experiments with styling </xsl:comment>
    <link href="developer.css" rel="stylesheet" type="text/css" />
</xsl:template>

<!-- Treated as characters, these could show up often, -->
<!-- so load into every possible HTML page instance    -->
<xsl:template name="font-awesome">
    <xsl:if test="$b-has-icon">
        <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" integrity="sha384-mzrmE5qonljUremFsqc01SB46JvROS7bZs3IO2EmfFsd15uHvIt+Y8vEf7N7fWAU" crossorigin="anonymous"/>
    </xsl:if>
</xsl:template>

<!-- A place to put *one* Javascript file at the *end* of an  -->
<!-- HTML page/file.  Not present in *every* page implemented -->
<!-- in this file, such as knowls.                            -->
<xsl:template name="extra-js-footer">
    <xsl:if test="not($html.js.extra = '')">
        <script src="{$html.js.extra}"></script>
    </xsl:if>
</xsl:template>


<!-- ############## -->
<!-- LaTeX Preamble -->
<!-- ############## -->

<!-- First a variable to massage the author-supplied -->
<!-- package list to the form MathJax expects        -->
<xsl:variable name="latex-packages-mathjax">
    <xsl:value-of select="str:replace($latex-packages, '\usepackage{', '\require{')" />
</xsl:variable>


<!-- MathJax expects math wrapping, and we place in   -->
<!-- a hidden div so not visible and take up no space -->
<!-- Inline CSS added because a "flash" was visible   -->
<!-- between HTML loading and CSS taking effect.      -->
<!-- We could rename this properly, since we are      -->
<!-- sneaking in packages, which load first, in       -->
<!-- case authors want to build on these macros       -->
<xsl:template name="latex-macros">
    <div id="latex-macros" class="hidden-content" style="display:none">
        <xsl:if test="$b-braille">
            <xsl:attribute name="data-braille">
                <xsl:text>latex-macros</xsl:text>
            </xsl:attribute>
        </xsl:if>
        <xsl:call-template name="begin-inline-math" />
        <xsl:value-of select="$latex-packages-mathjax" />
        <xsl:value-of select="$latex-macros" />
        <xsl:call-template name="end-inline-math" />
    </div>
</xsl:template>

<!-- Brand Logo -->
<!-- Place image in masthead -->
<!-- TODO: separate url and image, now need both or neither -->
<!-- should allow specifying just URL and get default image -->
<xsl:template name="brand-logo">
    <xsl:choose>
        <xsl:when test="$docinfo/brandlogo">
            <xsl:variable name="location" select="concat($external-directory, $docinfo/brandlogo/@source)"/>
            <a id="logo-link" href="{$docinfo/brandlogo/@url}" target="_blank" >
                <img src="{$location}" alt="Logo image"/>
            </a>
        </xsl:when>
        <xsl:otherwise>
            <a id="logo-link" href=""/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Analytics Footers -->

<!-- Google Analytics                     -->
<!-- "Classic", not compared to Universal -->
<xsl:template name="google-classic">
    <xsl:if test="$b-google-classic">
        <xsl:comment>Start: Google Classic code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***           GET YOUR OWN FROM GOOGLE             ***</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <script>
            <xsl:text>&#xa;</xsl:text>
            <xsl:text>var _gaq = _gaq || [];&#xa;</xsl:text>
            <xsl:text>_gaq.push(['_setAccount', '</xsl:text>
            <xsl:value-of select="$google-classic-tracking" />
            <xsl:text>']);&#xa;</xsl:text>
            <xsl:text>_gaq.push(['_trackPageview']);&#xa;</xsl:text>
            <xsl:text>(function() {&#xa;</xsl:text>
            <xsl:text>var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;&#xa;</xsl:text>
            <xsl:text>ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'https://www') + '.google-analytics.com/ga.js';&#xa;</xsl:text>
            <xsl:text>var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);&#xa;</xsl:text>
            <xsl:text>})();&#xa;</xsl:text>
        </script>
        <xsl:text>&#xa;</xsl:text>
        <xsl:comment>End: Google Classic code</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="google-universal">
    <xsl:if test="$b-google-universal">
        <xsl:comment>Start: Google Universal code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***           GET YOUR OWN FROM GOOGLE             ***</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <script>
            <xsl:text>(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){&#xa;</xsl:text>
            <xsl:text>(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),&#xa;</xsl:text>
            <xsl:text>m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)&#xa;</xsl:text>
            <xsl:text>})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');&#xa;</xsl:text>
            <xsl:text>ga('create', '</xsl:text>
            <xsl:value-of select="$google-universal-tracking" />
            <xsl:text>', 'auto');&#xa;</xsl:text>
            <xsl:text>ga('send', 'pageview');&#xa;</xsl:text>
        </script>
        <xsl:text>&#xa;</xsl:text>
        <xsl:comment>End: Google Universal code</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Google says use first in <head>, seems fine in foot -->
<xsl:template name="google-gst">
    <xsl:if test="$b-google-gst">
        <xsl:variable name="gst-url">
            <xsl:text>https://www.googletagmanager.com/gtag/js?id=</xsl:text>
            <xsl:value-of select="$google-gst-tracking"/>
        </xsl:variable>
        <xsl:comment>Start: Google Global Site Tag code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***           GET YOUR OWN FROM GOOGLE             ***</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <script async="" src="{$gst-url}"></script>
        <script>
            <xsl:text>  window.dataLayer = window.dataLayer || [];&#xa;</xsl:text>
            <xsl:text>  function gtag(){dataLayer.push(arguments);}&#xa;</xsl:text>
            <xsl:text>  gtag('js', new Date());&#xa;</xsl:text>
            <xsl:text>  gtag('config', '</xsl:text>
            <xsl:value-of select="$google-gst-tracking"/>
            <xsl:text>');&#xa;</xsl:text>
        </script>
        <xsl:comment>End: Google Global Site Tag code</xsl:comment>
    </xsl:if>
</xsl:template>

<!-- StatCounter                                -->
<!-- Set sc_invisible to 1                      -->
<!-- In noscript URL, final 1 is an edit from 0 -->
<xsl:template name="statcounter">
    <xsl:if test="$b-statcounter">
        <xsl:variable name="noscript_url">
            <xsl:text>https://c.statcounter.com/</xsl:text>
            <xsl:value-of select="$statcounter-project" />
            <xsl:text>/0/</xsl:text>
            <xsl:value-of select="$statcounter-security" />
            <xsl:text>/1/</xsl:text>
        </xsl:variable>
        <xsl:comment>Start: StatCounter code</xsl:comment>
        <xsl:comment>*** DO NOT COPY ANOTHER PROJECT'S MAGIC NUMBERS/ID ***</xsl:comment>
        <xsl:comment>***        GET YOUR OWN FROM STATCOUNTER           ***</xsl:comment>
        <script>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>var sc_project=</xsl:text>
        <xsl:value-of select="$statcounter-project" />
        <xsl:text>;&#xa;</xsl:text>
        <xsl:text>var sc_invisible=1;&#xa;</xsl:text>
        <xsl:text>var sc_security="</xsl:text>
        <xsl:value-of select="$statcounter-security" />
        <xsl:text>";&#xa;</xsl:text>
        <xsl:text>var scJsHost = (("https:" == document.location.protocol) ? "https://secure." : "https://www.");&#xa;</xsl:text>
        <xsl:text>document.write("&lt;sc"+"ript src='" + scJsHost+ "statcounter.com/counter/counter.js'&gt;&lt;/"+"script&gt;");&#xa;</xsl:text>
        </script>
        <noscript>
        <div class="statcounter">
        <a title="web analytics" href="https://statcounter.com/" target="_blank">
        <img class="statcounter" src="{$noscript_url}" alt="web analytics" /></a>
        </div>
        </noscript>
        <xsl:comment>End: StatCounter code</xsl:comment>
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############### -->
<!-- Worksheet Pages -->
<!-- ############### -->

<!-- A worksheet is (mostly) structured by "page", but we incorporate -->
<!-- certain beginning/ending items into a strict stucture organized  -->
<!-- by pages (HTML section.onepage), only, for printing purposes     -->
<!-- NB: extras print in document order, we are not imposing one here -->
<xsl:template match="worksheet/page">
    <xsl:param name="purpose" select="'viewable'"/>

    <section class="onepage">
        <!-- There is no enclosing HTML structure in the standalone, -->
        <!-- printable version, so we print a title/heading within   -->
        <!-- the first "section.onepage".  The is the only purpose   -->
        <!-- of the $purpose parameter. ("viewable" is usual HTML.)  -->
        <xsl:variable name="b-is-printable" select="$purpose = 'printable'"/>
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="html-id"/>
        </xsl:attribute>
        <!-- incorporate "extras" into Page 1 when printable -->
        <xsl:if test="not(preceding-sibling::page) and $b-is-printable">
            <!-- title of entire worksheet absorbed first into first page -->
            <!-- masthead is "h1", so specify "h2"?                       -->
            <xsl:apply-templates select=".." mode="section-header">
                <xsl:with-param name="heading-level" select="'2'"/>
            </xsl:apply-templates>
            <!-- other overall-worksheet times to absorb into first page -->
            <xsl:apply-templates select="../objectives|../introduction"/>
        </xsl:if>
        <!-- main content of *all* pages, especially intermediate pages,  -->
        <!-- whether viewable or printable (could kill banned items here) -->
        <xsl:apply-templates/>
        <!-- incorporate "extras" into Page N (even if N=1) when printable -->
        <xsl:if test="not(following-sibling::page) and $b-is-printable">
            <xsl:apply-templates select="../conclusion|../outcomes"/>
        </xsl:if>
    </section>
</xsl:template>

<!-- Templates ensure standalone page creation, -->
<!-- and links to same, are consistent          -->
<xsl:template match="worksheet" mode="standalone-filename-letter">
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>-letter.html</xsl:text>
</xsl:template>

<xsl:template match="worksheet" mode="standalone-filename-A4">
    <xsl:apply-templates select="." mode="visible-id"/>
    <xsl:text>-A4.html</xsl:text>
</xsl:template>

<!-- 2020-03-17: Empty element, since originally a       -->
<!-- "page" element interrupted numbering of contents.   -->
<!-- Now deprecated in favor of a proper "page" element. -->
<xsl:template match="worksheet/pagebreak">
    <hr class="pagebreak"/>
</xsl:template>

<!-- Miscellaneous -->

<!-- Inline warnings go into text, no matter what -->
<!-- They are colored for an author's report -->
<xsl:template name="inline-warning">
    <xsl:param name="warning" />
    <xsl:element name="span">
        <!-- Color for author tools version -->
        <xsl:if test="$author-tools-new = 'yes'" >
            <xsl:attribute name="style">color:red</xsl:attribute>
        </xsl:if>
        <xsl:text>(((</xsl:text>
        <xsl:value-of select="$warning" />
        <xsl:text>)))</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Marginal notes are only for author's report                     -->
<!-- and are always colored red.  Marginpar's from                   -->
<!-- http://www.sitepoint.com/web-foundations/floating-clearing-css/ -->
<xsl:template name="margin-warning">
    <xsl:param name="warning" />
    <xsl:if test="$author-tools-new = 'yes'" >
        <xsl:element name="span">
            <xsl:attribute name="style">color:red;float:right;width:20em;margin-right:-25em;</xsl:attribute>
            <xsl:value-of select="$warning" />
        </xsl:element>
    </xsl:if>
</xsl:template>


<!-- Uninteresting Code, aka the Bad Bank                    -->
<!-- Deprecated, unmaintained, etc, parked here out of sight -->

</xsl:stylesheet>
