<?xml version='1.0'?> <!-- As XML file -->

<!--********************************************************************
Copyright 2018 Robert A. Beezer

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

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Command-line Documentation                              -->
<!--                                                         -->
<!-- 1.  xsltproc                                            -->
<!-- 2.  -xinclude                                           -->
<!--     Necessary for PTX source in modular files           -->
<!-- 3.  -stringparam chunk.level <integer>                  -->
<!--     Level at which text divisions become entire pages.  -->
<!--     Default is "2", which would create an HTML page for -->
<!--     each section.  "3" would create a page for each     -->
<!--     subsection.  This needs to match how the actual     -->
<!--     pages are constructed, so the filenames here match  -->
<!--     the actual pages output.                            -->
<!-- 3.  -stringparam base-url <url>                         -->
<!--     Prefix of filenames, including a trailing slash     -->
<!-- 4.  path/to/mathbook/xsl/pretext-json-manifest.xsl      -->
<!-- 5.  path/to/master-file.xml                             -->
<!--                                                         -->
<!-- Output will be on stdout.                               -->
<!--                                                         -->
<!-- Example for Judson's Abstract Algebra:                  -->
<!--                                                         -->
<!-- $ xsltproc -xinclude                                    -->
<!--   -stringparam chunk.level 2                            -->
<!--   -stringparam base-url "http://abstract.ups.edu/aata/" -->
<!--   /path/to/mathbook/xsl/pretext-json-manifest.xsl       -->
<!--   /path/to/aata/src/aata.xml                            -->


<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<xsl:import href="./pretext-text.xsl" />

<!-- override on command-line with xsltproc's "-stringparam" option -->
<xsl:param name="chunk.level" select="2"/>
<xsl:param name="base-url" select="'http://abstract.ups.edu/aata/'"/>
<!-- <xsl:param name="base-url" select="'http://set-base-url/'"/> -->

<!-- Necessary variables, typically set in  pretext-html.xsl -->
<!-- $chunk-level will eventually be referenced by templates  -->
<!-- for the containing filename used to construct a URL      -->
<!-- Since we are describing HTML output, we want filenames   -->
<!-- describing those files                                   -->
<xsl:variable name="file-extension" select="'.html'"/>
<xsl:variable name="chunk-level" select="number($chunk.level)"/>

<!-- Entry Template               -->
<!-- Create outermost array       -->
<!-- Start with "book", "article" -->
<xsl:template match="/">
    <xsl:text>[&#xa;</xsl:text>
     <xsl:apply-templates select="$document-root"/>
    <xsl:text>]&#xa;</xsl:text>
</xsl:template>

<xsl:template match="&STRUCTURAL;">
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="number"/>
    </xsl:variable>
    <xsl:variable name="current-level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>

    <!-- no newline on opening of object -->
    <xsl:text>{</xsl:text>
    <xsl:text>"title": </xsl:text>
    <xsl:text>"</xsl:text>
    <xsl:if test="not($the-number = '')">
        <xsl:value-of select="$the-number"/>
        <xsl:text>: </xsl:text>
    </xsl:if>
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
    <xsl:text>,&#xa;</xsl:text>
    <xsl:text>"link": </xsl:text>
    <xsl:text>"</xsl:text>
    <xsl:apply-templates select="." mode="full-url"/>
    <xsl:text>"</xsl:text>
    <xsl:text>,&#xa;</xsl:text>
    <xsl:text>"children": [</xsl:text>
    <!-- only examine children if a level  -->
    <!-- above the desired chunk-level     -->
    <xsl:if test="$current-level &lt; $chunk-level">
        <!-- if no children, then put -->
        <!-- empty array on one line  -->
        <xsl:if test="&STRUCTURAL;">
            <xsl:text>&#xa;</xsl:text>
        </xsl:if>
        <!-- recurse into structural children -->
        <xsl:apply-templates select="&STRUCTURAL;"/>
    </xsl:if>
    <xsl:text>]&#xa;</xsl:text>
    <xsl:text>}</xsl:text>
    <!-- separate children, if necessary -->
    <xsl:if test="following-sibling::*[&STRUCTURAL-FILTER;]">
        <xsl:text>,</xsl:text>
    </xsl:if>
    <!-- newline after every child -->
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="&STRUCTURAL;" mode="full-url">
    <xsl:value-of select="$base-url"/>
    <xsl:apply-templates select="." mode="containing-filename"/>
</xsl:template>

<!-- Necessary, override any definition in "pretext-tex.xsl" -->
<xsl:template name="begin-inline-math">
    <xsl:text>\(</xsl:text>
</xsl:template>
<xsl:template name="end-inline-math">
    <xsl:text>\)</xsl:text>
</xsl:template>

</xsl:stylesheet>
