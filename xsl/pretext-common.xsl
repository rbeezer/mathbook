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

<!-- Indicated basic utilities are from:                      -->
<!-- XSLT Cookbook, 2nd Edition                               -->
<!-- Copyright 2006, O'Reilly Media, Inc.                     -->
<!--                                                          -->
<!-- From the section of the Preface, "Using Code Examples"   -->
<!-- "You do not need to contact us for permission unless     -->
<!-- you're reproducing a significant portion of the code.    -->
<!-- For example, writing a program that uses several chunks  -->
<!-- of code from this book does not require permission."     -->

<!-- http://pimpmyxslt.com/articles/entity-tricks-part2/ -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl date str"
    xmlns:mb="https://pretextbook.org/"
    exclude-result-prefixes="mb"
>

<!-- Any serious conversion will import this file (-common) -->
<!-- and the "publisher-variables" stylesheet will read a   -->
<!-- publisher file and create many global variables,       -->
<!-- which can be used to influence conversions             -->
<!-- See  publisher-variables.xsl  for more detail          -->
<xsl:import href="./publisher-variables.xsl"/>

<!-- MathBook XML common templates                        -->
<!-- Text creation/manipulation common to HTML, TeX, Sage -->

<!-- This collection of XSL routines is like a base library,          -->
<!-- it has no entry template and hence used by itself almost         -->
<!-- nothing should happen.  Typically the situation looks like this: -->
<!-- (example is LaTeX-specific but generalizes easily)               -->
<!--                                                                  -->
<!-- your-book-latex.xsl                                              -->
<!--   (a) is what you use on the command line                        -->
<!--   (b) contains very specific, atomic overrides for your project  -->
<!--   (c) imports xsl/pretext-latex.xsl                             -->
<!--                                                                  -->
<!-- xsl/pretext-latex.xsl                                           -->
<!--   (a) general conversion from MBX to LaTeX                       -->
<!--   (b) could be used at the command line for default conversion   -->
<!--   (c) imports xsl/pretext-common.xsl                            -->
<!--                                                                  -->
<!-- xsl/pretext-common.xsl                                          -->
<!--   (a) this file                                                  -->
<!--   (b) ensures commonality, such as text versions                 -->
<!--       of numbers for theorems, equations, etc                    -->
<!--   (c) has some abstract routines that require implementation     -->
<!--       in files above, such as file wrapping for a LaTeX file     -->
<!--       in this case                                               -->
<!--                                                                  -->
<!-- This creates a linear sequence of imports, so overrides          -->
<!-- behave as you might expect or predict.                           -->
<!-- To do otherwise is to invite confusion.                          -->

<!-- Output methods here are just pure text -->
<xsl:output method="text" />

<!-- Parameters to pass via xsltproc "stringparam" on command-line            -->
<!-- Or make a thin customization layer and use 'select' to provide overrides -->
<!-- These here are independent of the output format as well                  -->
<!--                                                                          -->
<!-- Depth to which a document is broken into smaller files/chunks -->
<!-- Sentinel indicates no choice made                             -->
<xsl:param name="chunk.level" select="''" />

<!-- An exercise has a statement, and may have hints,      -->
<!-- answers and solutions.  An answer is just the         -->
<!-- final number, expression, whatever; while a solution  -->
<!-- includes intermediate steps. Parameters here control  -->
<!-- the *visibility* of these four parts                  -->
<!--                                                       -->
<!-- Parameters are:                                       -->
<!--   'yes' - visible                                     -->
<!--   'no' - not visible                                  -->
<!--                                                       -->
<!-- Five categories:                                      -->
<!--   inline (checpoint) exercises                        -->
<!--   divisional (inside an "exercises" division)         -->
<!--   worksheet (inside a "worksheet" division)           -->
<!--   reading (inside a "reading-questions" division)     -->
<!--   project (on a project-like,                         -->
<!--   or possibly on a terminal "task" of a project-like) -->
<!--                                                       -->
<!-- Default is "yes" for every part, so experiment        -->
<!-- with parameters to make some parts hidden.            -->
<!--                                                       -->
<!-- These are global switches, so only need to be fed     -->
<!-- into the construction of exercises via the            -->
<!-- "exercise-components" template.                       -->
<!-- N.B. "statement" switches are necessary or desirable  -->
<!-- for alternate collections of solutions (only)         -->
<xsl:param name="exercise.inline.statement" select="''" />
<xsl:param name="exercise.inline.hint" select="''" />
<xsl:param name="exercise.inline.answer" select="''" />
<xsl:param name="exercise.inline.solution" select="''" />
<xsl:param name="exercise.divisional.statement" select="''" />
<xsl:param name="exercise.divisional.hint" select="''" />
<xsl:param name="exercise.divisional.answer" select="''" />
<xsl:param name="exercise.divisional.solution" select="''" />
<xsl:param name="exercise.worksheet.statement" select="''" />
<xsl:param name="exercise.worksheet.hint" select="''" />
<xsl:param name="exercise.worksheet.answer" select="''" />
<xsl:param name="exercise.worksheet.solution" select="''" />
<xsl:param name="exercise.reading.statement" select="''" />
<xsl:param name="exercise.reading.hint" select="''" />
<xsl:param name="exercise.reading.answer" select="''" />
<xsl:param name="exercise.reading.solution" select="''" />
<xsl:param name="project.statement" select="''" />
<xsl:param name="project.hint" select="''" />
<xsl:param name="project.answer" select="''" />
<xsl:param name="project.solution" select="''" />

<!-- Author tools are for drafts, mostly "todo" items  -->
<!-- and "provisional" citations and cross-references  -->
<!-- Default is to hide todo's, inline provisionals    -->
<!-- Otherwise ('yes'), todo's show in red paragraphs, -->
<!-- provisional cross-references show in red          -->
<xsl:param name="author.tools" select="''" />
<!-- How many levels to table of contents  -->
<!-- Not peculiar to HTML or LaTeX or etc. -->
<!-- Sentinel indicates no choice made     -->
<xsl:param name="toc.level" select="''" />
<!-- How many levels in numbering of theorems, etc     -->
<!-- Followed by a sequential number across that level -->
<!-- For example "2" implies Theorem 5.3.12 is         -->
<!-- 12-th theorem, lemma, etc in 5.2                  -->
<xsl:param name="numbering.theorems.level" select="''" />
<!-- How many levels in numbering of projects, etc     -->
<!-- PROJECT-LIKE gets independent numbering -->
<xsl:param name="numbering.projects.level" select="''" />
<!-- How many levels in numbering of equations     -->
<!-- Analagous to numbering theorems, but distinct -->
<xsl:param name="numbering.equations.level" select="''" />
<!-- Level where footnote numbering resets                                -->
<!-- For example, "2" would be sections in books, subsections in articles -->
<xsl:param name="numbering.footnotes.level" select="''" />
<!-- Last level where subdivision (section) numbering takes place     -->
<!-- For example, "2" would mean subsections of a book are unnumbered -->
<!-- N.B.: the levels above cannot be numerically larger              -->
<xsl:param name="numbering.maximum.level" select="''" />
<!-- Pointers to realizations of the actual document -->
<xsl:param name="address.html" select="''" />
<xsl:param name="address.pdf" select="''" />
<!-- Publisher option to surround emdash -->
<!-- Default is none, option is thin     -->
<xsl:param name="emdash.space" select="''" />
<!-- Publisher option to include "commentary" -->
<!-- Default will be "no"                     -->
<xsl:param name="commentary" select="''" />
<!-- Publisher option to influence horizontal alignment of text -->
<!-- Default will be "justify"                                  -->
<xsl:param name="text.alignment" select="''" />

<!-- Whitespace discussion: http://www.xmlplease.com/whitespace               -->
<!-- Describes source expectations, DO NOT override in subsequent conversions -->
<!-- Strip whitespace text nodes from container elements                      -->
<!-- Improve source readability with whitespace control in text output mode   -->
<!-- Newlines with &#xa; : http://stackoverflow.com/questions/723226/producing-a-new-line-in-xslt -->
<!-- Removing whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->
<xsl:strip-space elements="mathbook pretext book article memo letter" />
<xsl:strip-space elements="frontmatter chapter appendix index-part index section subsection subsubsection exercises worksheet reading-questions solutions references glossary introduction conclusion paragraphs subparagraph backmatter" />
<xsl:strip-space elements="docinfo author abstract" />
<xsl:strip-space elements="titlepage preface acknowledgement biography foreword dedication colophon" />
<!-- List is elements in DEFINITION-LIKE entity -->
<!-- definition -->
<xsl:strip-space elements="definition" />
<!-- List is elements in THEOREM-LIKE entity                           -->
<!-- theorem|corollary|lemma|algorithm|proposition|claim|fact|identity -->
<xsl:strip-space elements="theorem corollary lemma algorithm proposition claim fact identity" />
<xsl:strip-space elements="statement" />
<xsl:strip-space elements="proof case" />
<!-- List is elements in AXIOM-LIKE entity                  -->
<!-- axiom|conjecture|principle|heuristic|hypothesis|assumption -->
<xsl:strip-space elements="axiom conjecture principle heuristic hypothesis assumption" />
<!-- List is elements in REMARK-LIKE entity             -->
<!-- remark|convention|note|observation|warning|insight -->
<xsl:strip-space elements="remark convention note observation warning insight" />
<!-- List is elements in COMPUTATION-LIKE entity -->
<!-- computation|technology                      -->
<xsl:strip-space elements="computation technology" />
<!-- List is elements in EXAMPLE-LIKE entity -->
<!-- example|question|problem                -->
<xsl:strip-space elements="example question problem" />
<!-- List is elements in PROJECT-LIKE entity -->
<!-- project|activity|exploration|investigation -->
<xsl:strip-space elements="project activity exploration investigation" />
<!-- List is elements in FIGURE-LIKE -->
<!-- figure|table|listing|list -->
<xsl:strip-space elements="figure table listing list"/>
<xsl:strip-space elements="exercise hint answer solution" />
<xsl:strip-space elements="objectives outcomes"/>
<!-- The next three are containers -->
<xsl:strip-space elements="prelude interlude postlude" />
<xsl:strip-space elements="aside blockquote assemblage" />
<xsl:strip-space elements="list terms" />
<xsl:strip-space elements="sage program console task" />
<xsl:strip-space elements="exercisegroup" />
<xsl:strip-space elements="ul ol dl defined-term" />
<xsl:strip-space elements="md mdn quantity" />
<xsl:strip-space elements="sage figure table listing index" />
<xsl:strip-space elements="sidebyside paragraphs" />
<xsl:strip-space elements="tabular col row" />
<xsl:strip-space elements="webwork setup" />
<xsl:strip-space elements="notation image tabular row"/>

<!-- A few basic elements are explicitly mixed-content -->
<!-- So we must preserve whitespace-only text nodes    -->
<!-- Example: a space between two marked-up words      -->
<!--                                                   -->
<!--         <em>two</em> <alert>ducks</alert>         -->
<!--                                                   -->
<!-- Describes source expectations, DO NOT             -->
<!-- override in subsequent stylesheets                -->
<xsl:preserve-space elements="p li" />

<!-- ######### -->
<!-- Variables -->
<!-- ######### -->

<!-- The single quote character cannot be directly     -->
<!-- used in a string in XSLT functions, not even as   -->
<!-- &apos;. But if it is stored as a variable, then   -->
<!-- XSLT 1.0 will be OK with using $apos.             -->
<!-- Use like "contat('L',$apos,'Hospital')"           -->
<xsl:variable name="apos">'</xsl:variable>

<!-- Here we perform manipulations of math elements and subsequent  -->
<!-- text nodes that lead with punctuation.  Basically, punctuation -->
<!-- can migrate from the start of the text node and into the math, -->
<!-- wrapped in a \text{}.  We generally do this to display math as -->
<!-- a service to authors.  MathJax needs help for inline math.     -->
<!-- Braille and audio do not do so well with this manipulation.    -->
<!-- These variables are meant to be set by other stylesheets in    -->
<!-- various situations and there should be no cause for authors to -->
<!-- change them (this no elaborate error-checking, etc.)           -->
<xsl:variable name="math.punctuation.include" select="'none'"/>
<xsl:variable name="b-include-inline"
    select="($math.punctuation.include = 'inline')  or ($math.punctuation.include = 'all')"/>
<xsl:variable name="b-include-display"
    select="($math.punctuation.include = 'display') or ($math.punctuation.include = 'all')"/>

<!-- We set this variable a bit differently -->
<!-- for different conversions, so this is  -->
<!-- basically an abstract implementation   -->
<xsl:variable name="chunk-level">
    <xsl:text>0</xsl:text>
</xsl:variable>

<!-- Flag Table of Contents, or not, with boolean variable -->
<xsl:variable name="b-has-toc" select="$toc-level != 0" />

<!-- A book must have a chapter         -->
<!-- An article need not have a section -->
<xsl:variable name="toc-level">
    <xsl:choose>
        <xsl:when test="$toc.level != ''">
            <xsl:value-of select="$toc.level" />
        </xsl:when>
        <xsl:when test="$root/book/part/chapter/section">3</xsl:when>
        <xsl:when test="$root/book/part/chapter">2</xsl:when>
        <xsl:when test="$root/book/chapter/section">2</xsl:when>
        <xsl:when test="$root/book/chapter">1</xsl:when>
        <xsl:when test="$root/article/section/subsection">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Table of Contents level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Theorems, etc    -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-theorems">
    <xsl:choose>
        <xsl:when test="$numbering.theorems.level != ''">
            <xsl:value-of select="$numbering.theorems.level" />
        </xsl:when>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Theorem numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Projects, etc    -->
<!-- Respect switch, or provide sensible defaults -->
<!-- PROJECT-LIKE -->
<!-- NB: this should become elective, more like the      -->
<!-- schemes below for inline exercises and figure-like. -->
<xsl:variable name="numbering-projects">
    <xsl:choose>
        <xsl:when test="$numbering.projects.level != ''">
            <xsl:value-of select="$numbering.projects.level" />
        </xsl:when>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Theorem numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Inline Exercises can optionally run on their own numbering scheme -->
<!-- This is set (temporarily) in docinfo, which will change           -->
<!-- We do no special error-checking here since this will change       -->
<!-- The variable will be empty if not set                             -->
<xsl:variable name="numbering-exercises" select="number($docinfo/numbering/exercises/@level)"/>

<!-- Figure-Like can optionally run on their own numbering scheme      -->
<!-- This is set (temporarily) in docinfo, which will change           -->
<!-- We do no special error-checking here since this will change       -->
<!-- The variable will be empty if not set                             -->
<xsl:variable name="numbering-figures" select="number($docinfo/numbering/figures/@level)"/>

<!-- User-supplied Numbering for Equations    -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-equations">
    <xsl:choose>
        <xsl:when test="$numbering.equations.level != ''">
            <xsl:value-of select="$numbering.equations.level" />
        </xsl:when>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Equation numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Footnotes        -->
<!-- Respect switch, or provide sensible defaults -->
<xsl:variable name="numbering-footnotes">
    <xsl:choose>
        <xsl:when test="$numbering.footnotes.level != ''">
            <xsl:value-of select="$numbering.footnotes.level" />
        </xsl:when>
        <xsl:when test="$root/book/part">3</xsl:when>
        <xsl:when test="$root/book">2</xsl:when>
        <xsl:when test="$root/article/section|$root/article/worksheet">1</xsl:when>
        <xsl:when test="$root/article">0</xsl:when>
        <xsl:when test="$root/slideshow">0</xsl:when>
        <xsl:when test="$root/letter">0</xsl:when>
        <xsl:when test="$root/memo">0</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Footnote numbering level not determined</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- User-supplied Numbering for Maximum Level     -->
<!-- Respect switch, or provide sensible defaults  -->
<!-- NB: level number counts the number of         -->
<!-- separators (periods) present once qualified   -->
<!-- with a numbered item contained within         -->
<!-- NB: If we were to allow multiple (hence       -->
<!-- numbered) specialized divisions of a          -->
<!-- "subsubsection", then the non-zero maximums   -->
<!-- below would go up by 1                        -->
<!--   article/section: s.ss.sss => 3              -->
<!--   book:            c.s.ss.sss => 4            -->
<!--   book/part:       p.c.s.ss.sss => 5          -->
<xsl:variable name="numbering-maxlevel">
    <xsl:variable name="max-feasible">
        <xsl:choose>
            <xsl:when test="$root/book/part">5</xsl:when>
            <xsl:when test="$root/book">4</xsl:when>
            <xsl:when test="$root/article/section|$root/article/worksheet">3</xsl:when>
            <xsl:when test="$root/article">0</xsl:when>
            <xsl:when test="$root/letter">0</xsl:when>
            <xsl:when test="$root/slideshow">0</xsl:when>
            <xsl:when test="$root/memo">0</xsl:when>
            <xsl:otherwise>
                <xsl:message>MBX:BUG: New document type for maximum level defaults</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- If not provided, try the biggest possible for consistency -->
    <xsl:variable name="candidate">
        <xsl:choose>
            <xsl:when test="$numbering.maximum.level = ''">
                <xsl:value-of select="$max-feasible" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering.maximum.level" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$candidate &lt; $numbering-theorems">
            <xsl:message terminate="yes">MBX:FATAL:   theorem numbering level cannot exceed sectioning level</xsl:message>
        </xsl:when>
        <!-- PROJECT-LIKE -->
        <xsl:when test="$candidate &lt; $numbering-projects">
            <xsl:message terminate="yes">MBX:FATAL:   project numbering level cannot exceed sectioning level</xsl:message>
        </xsl:when>
        <xsl:when test="$candidate &lt; $numbering-equations">
            <xsl:message terminate="yes">MBX:FATAL:   equation numbering level cannot exceed sectioning level</xsl:message>
        </xsl:when>
        <xsl:when test="$candidate &lt; $numbering-footnotes">
            <xsl:message terminate="yes">MBX:FATAL:   footnote numbering level cannot exceed sectioning level</xsl:message>
        </xsl:when>
        <xsl:when test="$candidate &gt; $max-feasible">
            <xsl:message terminate="yes">MBX:FATAL:   sectioning level exceeds maximum possible for this document (<xsl:value-of select="$max-feasible" />)</xsl:message>
        </xsl:when>
        <!-- Survived the gauntlet, spit it out candidate as $numbering-maxlevel -->
        <xsl:otherwise>
            <xsl:value-of select="$candidate" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Document language comes from the mathbook element -->
<!-- or defaults to US English if not present          -->
<xsl:variable name="document-language">
    <xsl:choose>
        <xsl:when test="$root/@xml:lang">
            <xsl:value-of select="$root/@xml:lang" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="'en-US'" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- An author may elect to place a unique string into   -->
<!-- the docinfo/document-id element and conversions may -->
<!-- use this to distinguish one document from another.  -->
<!-- The global variable here is empty to signal         -->
<!-- "no choice" by the author.                          -->
<xsl:variable name="document-id" select="string($docinfo/document-id)"/>

<!-- The new version can return to the generic version  -->
<!-- once we kill the dashed version for author use.    -->
<xsl:variable name="author-tools-new">
    <xsl:choose>
        <!-- respect old switch, if set properly -->
        <!-- but don't error check or anything   -->
        <xsl:when test="$author-tools = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$author-tools = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:when test="$author.tools = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$author.tools = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <!-- could error-check not-empty here -->
        <!-- default is "no"                  -->
        <xsl:otherwise>
            <xsl:text>no</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- ########################### -->
<!-- Exercise component switches -->
<!-- ########################### -->

<!-- We santitize exercise component switches.  These control -->
<!-- text/narrative appearances *only*, solution lists in the -->
<!-- backmatter are given in alternate ways.  However, an     -->
<!-- alternate conversion (such as an Instructor's Guide) may -->
<!-- use these as well. We only do quality control here       -->
<!-- first. The "*.text.*" forms are deprecated with warnings -->
<!-- elsewhere, but we try to preserve their intent here.     -->
<!-- NB 2020-10-23: consider dropping "-statement" versions   -->
<!-- as silly, since a Solutions Manual, or similar, can be   -->
<!-- built with a solutions generator, and an Instructors     -->
<!-- Edition would need statements also (always)              -->
<xsl:variable name="entered-exercise-inline-statement">
    <xsl:choose>
        <xsl:when test="($exercise.inline.statement = 'yes') or
                        ($exercise.inline.statement = 'no')">
            <xsl:value-of select="$exercise.inline.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.statement = ''">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.inline.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-inline-hint">
    <xsl:choose>
        <xsl:when test="($exercise.inline.hint = 'yes') or
                        ($exercise.inline.hint = 'no')">
            <xsl:value-of select="$exercise.inline.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.hint = ''">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.inline.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-inline-answer">
    <xsl:choose>
        <xsl:when test="($exercise.inline.answer = 'yes') or
                        ($exercise.inline.answer = 'no')">
            <xsl:value-of select="$exercise.inline.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.answer = ''">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.inline.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-inline-solution">
    <xsl:choose>
        <xsl:when test="($exercise.inline.solution = 'yes') or
                        ($exercise.inline.solution = 'no')">
            <xsl:value-of select="$exercise.inline.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.inline.solution = ''">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.inline.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.inline.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-statement">
    <xsl:choose>
        <xsl:when test="($exercise.divisional.statement = 'yes') or
                        ($exercise.divisional.statement = 'no')">
            <xsl:value-of select="$exercise.divisional.statement" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.statement = ''">
            <xsl:value-of select="$exercise.divisional.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.divisional.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-hint">
    <xsl:choose>
        <xsl:when test="($exercise.divisional.hint = 'yes') or
                        ($exercise.divisional.hint = 'no')">
            <xsl:value-of select="$exercise.divisional.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.hint = ''">
            <xsl:value-of select="$exercise.divisional.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.divisional.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-answer">
    <xsl:choose>
        <xsl:when test="($exercise.divisional.answer = 'yes') or
                        ($exercise.divisional.answer = 'no')">
            <xsl:value-of select="$exercise.divisional.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.answer = ''">
            <xsl:value-of select="$exercise.divisional.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.divisional.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-divisional-solution">
    <xsl:choose>
        <xsl:when test="($exercise.divisional.solution = 'yes') or
                        ($exercise.divisional.solution = 'no')">
            <xsl:value-of select="$exercise.divisional.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.divisional.solution = ''">
            <xsl:value-of select="$exercise.divisional.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.divisional.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.divisional.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-statement">
    <xsl:choose>
        <xsl:when test="($exercise.worksheet.statement = 'yes') or
                        ($exercise.worksheet.statement = 'no')">
            <xsl:value-of select="$exercise.worksheet.statement" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.statement = ''">
            <xsl:value-of select="$exercise.worksheet.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.worksheet.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-hint">
    <xsl:choose>
        <xsl:when test="($exercise.worksheet.hint = 'yes') or
                        ($exercise.worksheet.hint = 'no')">
            <xsl:value-of select="$exercise.worksheet.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.hint = ''">
            <xsl:value-of select="$exercise.worksheet.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.worksheet.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-answer">
    <xsl:choose>
        <xsl:when test="($exercise.worksheet.answer = 'yes') or
                        ($exercise.worksheet.answer = 'no')">
            <xsl:value-of select="$exercise.worksheet.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.answer = ''">
            <xsl:value-of select="$exercise.worksheet.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.worksheet.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-worksheet-solution">
    <xsl:choose>
        <xsl:when test="($exercise.worksheet.solution = 'yes') or
                        ($exercise.worksheet.solution = 'no')">
            <xsl:value-of select="$exercise.worksheet.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.worksheet.solution = ''">
            <xsl:value-of select="$exercise.worksheet.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.worksheet.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.worksheet.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-statement">
    <xsl:choose>
        <xsl:when test="($exercise.reading.statement = 'yes') or
                        ($exercise.reading.statement = 'no')">
            <xsl:value-of select="$exercise.reading.statement" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.statement = 'yes') or ($exercise.text.statement = 'no')">
            <xsl:value-of select="$exercise.text.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.statement = ''">
            <xsl:value-of select="$exercise.reading.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.reading.statement parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-hint">
    <xsl:choose>
        <xsl:when test="($exercise.reading.hint = 'yes') or
                        ($exercise.reading.hint = 'no')">
            <xsl:value-of select="$exercise.reading.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.hint = 'yes') or ($exercise.text.hint = 'no')">
            <xsl:value-of select="$exercise.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.hint = ''">
            <xsl:value-of select="$exercise.reading.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.reading.hint parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-answer">
    <xsl:choose>
        <xsl:when test="($exercise.reading.answer = 'yes') or
                        ($exercise.reading.answer = 'no')">
            <xsl:value-of select="$exercise.reading.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.answer = 'yes') or ($exercise.text.answer = 'no')">
            <xsl:value-of select="$exercise.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.answer = ''">
            <xsl:value-of select="$exercise.reading.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.reading.answer parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-exercise-reading-solution">
    <xsl:choose>
        <xsl:when test="($exercise.reading.solution = 'yes') or
                        ($exercise.reading.solution = 'no')">
            <xsl:value-of select="$exercise.reading.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($exercise.text.solution = 'yes') or ($exercise.text.solution = 'no')">
            <xsl:value-of select="$exercise.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$exercise.reading.solution = ''">
            <xsl:value-of select="$exercise.reading.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: exercise.reading.solution parameter should be "yes" or "no", not "<xsl:value-of select="$exercise.reading.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-statement">
    <xsl:choose>
        <xsl:when test="($project.statement = 'yes') or
                        ($project.statement = 'no')">
            <xsl:value-of select="$project.statement" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.statement = ''">
            <xsl:value-of select="$project.statement" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: project.statement parameter should be "yes" or "no", not "<xsl:value-of select="$project.statement" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-hint">
    <xsl:choose>
        <xsl:when test="($project.hint = 'yes') or
                        ($project.hint = 'no')">
            <xsl:value-of select="$project.hint" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($project.text.hint = 'yes') or ($project.text.hint = 'no')">
            <xsl:value-of select="$project.text.hint" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.hint = ''">
            <xsl:value-of select="$project.hint" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: project.hint parameter should be "yes" or "no", not "<xsl:value-of select="$project.hint" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-answer">
    <xsl:choose>
        <xsl:when test="($project.answer = 'yes') or
                        ($project.answer = 'no')">
            <xsl:value-of select="$project.answer" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($project.text.answer = 'yes') or ($project.text.answer = 'no')">
            <xsl:value-of select="$project.text.answer" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.answer = ''">
            <xsl:value-of select="$project.answer" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: project.answer parameter should be "yes" or "no", not "<xsl:value-of select="$project.answer" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="entered-project-solution">
    <xsl:choose>
        <xsl:when test="($project.solution = 'yes') or
                        ($project.solution = 'no')">
            <xsl:value-of select="$project.solution" />
        </xsl:when>
        <!-- deprecated, but still honored, though with no error-checking, -->
        <!-- erroneous values will fall into default of replacement switch -->
        <xsl:when test="($project.text.solution = 'yes') or ($project.text.solution = 'no')">
            <xsl:value-of select="$project.text.solution" />
        </xsl:when>
        <!-- stick with no action by author/publisher -->
        <xsl:when test="$project.solution = ''">
            <xsl:value-of select="$project.solution" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message >MBX:WARNING: project.solution parameter should be "yes" or "no", not "<xsl:value-of select="$project.solution" />".  Proceeding with default value.</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- The "entered-*" versions have been sanitized      -->
<!-- to be "yes", "no" or "".  We make and use boolean -->
<!-- switches. Unset, or mis-entered is the default,   -->
<!-- which is to show all components until an author   -->
<!-- decides to hide them.                             -->
<!-- These are used in the solution manual conversion  -->
<xsl:variable name="b-has-inline-statement"
              select="($entered-exercise-inline-statement = 'yes') or ($entered-exercise-inline-statement = '')" />
<xsl:variable name="b-has-inline-hint"
              select="($entered-exercise-inline-hint = 'yes') or ($entered-exercise-inline-hint = '')" />
<xsl:variable name="b-has-inline-answer"
              select="($entered-exercise-inline-answer = 'yes') or ($entered-exercise-inline-answer = '')" />
<xsl:variable name="b-has-inline-solution"
              select="($entered-exercise-inline-solution = 'yes') or ($entered-exercise-inline-solution = '')" />
<xsl:variable name="b-has-divisional-statement"
              select="($entered-exercise-divisional-statement = 'yes') or ($entered-exercise-divisional-statement = '')" />
<xsl:variable name="b-has-divisional-hint"
              select="($entered-exercise-divisional-hint = 'yes') or ($entered-exercise-divisional-hint = '')" />
<xsl:variable name="b-has-divisional-answer"
              select="($entered-exercise-divisional-answer = 'yes') or ($entered-exercise-divisional-answer = '')" />
<xsl:variable name="b-has-divisional-solution"
              select="($entered-exercise-divisional-solution = 'yes') or ($entered-exercise-divisional-solution = '')" />
<xsl:variable name="b-has-worksheet-statement"
              select="($entered-exercise-worksheet-statement = 'yes') or ($entered-exercise-worksheet-statement = '')" />
<xsl:variable name="b-has-worksheet-hint"
              select="($entered-exercise-worksheet-hint = 'yes') or ($entered-exercise-worksheet-hint = '')" />
<xsl:variable name="b-has-worksheet-answer"
              select="($entered-exercise-worksheet-answer = 'yes') or ($entered-exercise-worksheet-answer = '')" />
<xsl:variable name="b-has-worksheet-solution"
              select="($entered-exercise-worksheet-solution = 'yes') or ($entered-exercise-worksheet-solution = '')" />
<xsl:variable name="b-has-reading-statement"
              select="($entered-exercise-reading-statement = 'yes') or ($entered-exercise-reading-statement = '')" />
<xsl:variable name="b-has-reading-hint"
              select="($entered-exercise-reading-hint = 'yes') or ($entered-exercise-reading-hint = '')" />
<xsl:variable name="b-has-reading-answer"
              select="($entered-exercise-reading-answer = 'yes') or ($entered-exercise-reading-answer = '')" />
<xsl:variable name="b-has-reading-solution"
              select="($entered-exercise-reading-solution = 'yes') or ($entered-exercise-reading-solution = '')" />
<xsl:variable name="b-has-project-statement"
              select="($entered-project-statement = 'yes') or ($entered-project-statement = '')" />
<xsl:variable name="b-has-project-hint"
              select="($entered-project-hint = 'yes') or ($entered-project-hint = '')" />
<xsl:variable name="b-has-project-answer"
              select="($entered-project-answer = 'yes') or ($entered-project-answer = '')" />
<xsl:variable name="b-has-project-solution"
              select="($entered-project-solution = 'yes') or ($entered-project-solution = '')" />


<!-- ############### -->
<!-- Source Analysis -->
<!-- ############### -->

<!-- We check certain aspects of the source and record the results  -->
<!-- in boolean ($b-has-*) variables or as particular nodes high    -->
<!-- up in the structure ($document-root).  Scans here in -common   -->
<!-- should be short and definite (no searching paths with //!),    -->
<!-- and universally useful, largely conveniences for consistency.  -->
<!-- Remember that many basic templates are shared out of this      -->
<!-- file for often very simple conversions (e.g. extractions)      -->
<!-- so excessive setup is an unnecessary drain on processing time. -->

<!-- The main "mathbook" element only has two possible children     -->
<!-- Or the main element could be "pretext" after name change       -->
<!-- One is "docinfo", the other is "book", "article", etc.         -->
<!-- This is of interest by itself, or the root of content searches -->
<!-- And docinfo is the other child                                 -->
<!-- These help prevent searching the wrong half                    -->
<!-- 2019-04-02: "mathbook" deprecated.  It still appears in        -->
<!-- multiple locations, even if the definitions below help         -->
<!-- isolate its use here.                                          -->
<xsl:variable name="root" select="/mathbook|/pretext" />
<xsl:variable name="docinfo" select="$root/docinfo" />
<xsl:variable name="document-root" select="$root/*[not(self::docinfo)]" />

<!-- "book" and "article" are sometimes different, esp. for LaTeX -->
<xsl:variable name="b-is-book"    select="$document-root/self::book" />
<xsl:variable name="b-is-article" select="$document-root/self::article" />
<!-- w/, w/o parts induces variants -->
<xsl:variable name="b-has-parts" select="boolean($root/book/part)" />


<!-- Some groups of elements are counted distinct -->
<!-- from other blocks.  A configuration element  -->
<!-- in "docinfo" is indicative of this           -->
<xsl:variable name="b-number-figure-distinct" select="boolean($docinfo/numbering/figures)" />
<!-- project historical default, switch it -->
<xsl:variable name="b-number-project-distinct" select="true()" />
<!-- historically false -->
<xsl:variable name="b-number-exercise-distinct" select="boolean($docinfo/numbering/exercises)" />

<!-- Status quo, for no-part books and articles is "absent".     -->
<!-- The "structural" option will change numbers and numbering   -->
<!-- substantially.  The "decorative" option is the default for  -->
<!-- books with parts, and it looks just like the LaTeX default. -->
<xsl:variable name="parts">
    <xsl:choose>
        <xsl:when test="not($document-root/part) and $docinfo/numbering/division/@part">
            <xsl:message>MBX:WARNING: your document is not a book with parts, so docinfo/numbering/division/@part will be ignored</xsl:message>
            <xsl:text>absent</xsl:text>
        </xsl:when>
        <!-- Schema restricts parts to a division of a book -->
        <!-- So usual no-part book, or article, or ...      -->
        <xsl:when test="not($document-root/part)">
            <xsl:text>absent</xsl:text>
        </xsl:when>
        <!-- has parts, check docinfo specification        -->
        <!-- nothing given is default, which is decorative -->
        <xsl:when test="not($docinfo/numbering/division/@part)">
            <xsl:text>decorative</xsl:text>
        </xsl:when>
        <xsl:when test="$docinfo/numbering/division/@part = 'structural'">
            <xsl:text>structural</xsl:text>
        </xsl:when>
        <xsl:when test="$docinfo/numbering/division/@part = 'decorative'">
            <xsl:text>decorative</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message terminate='yes'>MBX:WARNING: docinfo/numbering/division/@part should be "decorative" or "structural", not "<xsl:value-of select="$docinfo/numbering/division/@part" />"  Quitting...</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- We read the document language translation -->
<!-- nodes out of the right file, which relies -->
<!-- on filenames with country codes           -->
<xsl:variable name="localization-file">
    <xsl:text>localizations/</xsl:text>
    <xsl:value-of select="$document-language" />
    <xsl:text>.xsl</xsl:text>
</xsl:variable>
<xsl:variable name="translation-nodes" select="document($localization-file)" />

<!-- Document may exist in a variety of formats in  -->
<!-- various locations.  These parameters can be    -->
<!-- hard-coded in the docinfo and/or specified on  -->
<!-- the command line. Command line takes priority. -->
<!-- TODO: More formats could be implemented.       -->
<xsl:variable name="address-html">
    <xsl:choose>
        <xsl:when test="not($address.html = '')">
            <xsl:value-of select="$address.html" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$docinfo/address/html" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="address-pdf">
    <xsl:choose>
        <xsl:when test="not($address.pdf = '')">
            <xsl:value-of select="$address.pdf" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$docinfo/address/pdf" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- File extensions can be set globally for a conversion, -->
<!-- we set it here to something outlandish                -->
<!-- This should be overridden in an importing stylesheet  -->
<xsl:variable name="file-extension" select="'.need-to-set-file-extension-variable'" />

<!-- Prior to January 2017 we treated all whitespace as -->
<!-- significant in mixed-content nodes.  With changes  -->
<!-- in this policy we preserve the option to process   -->
<!-- in this older style.  This could avoid frequent    -->
<!-- applications of low-level text-processing routines -->
<!-- and perhaps speed up processing.  Switch here      -->
<!-- controls possible whitespace modes.                -->
<xsl:param name="whitespace" select="'flexible'" />
<xsl:variable name="whitespace-style">
    <xsl:choose>
        <xsl:when test="$whitespace='strict' or $whitespace='flexible'">
            <xsl:value-of select="$whitespace" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>
                <xsl:text>MBX:ERROR: the whitespace parameter can be 'strict' or 'flexible', not '</xsl:text>
                <xsl:value-of select="$whitespace" />
                <xsl:text>'.  Using the default ('flexible').</xsl:text>
            </xsl:message>
            <xsl:text>flexible</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- 2019-05: this is a switch to transition from slow, more-stable -->
<!-- identication strings to fast, less-stable strings.             -->
<!--   1.  Default should switch to make transition                 -->
<!--   2.  Switch should be deprecated and slow code abandoned      -->
<!-- To change default from old-slow-style                          -->
<!--   1.  move match on empty to "no" result                       -->
<!--   2.  flip otherwise clause                                    -->
<xsl:param name="oldids" select="''"/>
<xsl:variable name="oldstyle">
    <xsl:choose>
        <xsl:when test="($oldids = '') or ($oldids = 'yes')">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:when test="$oldids = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>yes</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:variable name="b-fast-ids" select="$oldstyle = 'no'"/>

<!-- We preserve action of the "autoname" parameter         -->
<!-- But originally the default was "no", and now is        -->
<!-- equivalent to "yes".  We set to blank on creation,     -->
<!-- so we can see if there is command-line action          -->
<!-- There is a warning that the default behavior has       -->
<!-- changed, and a warning that setting this is deprecated -->
<!-- (Deprecation 2017-07-25) -->
<xsl:variable name="legacy-autoname">
    <xsl:choose>
        <!-- nothing on command-line, nothing in docinfo    -->
        <!-- then this is what will be used globally        -->
        <!-- so preserve this behavior when this is removed -->
        <xsl:when test="$autoname = ''">
            <xsl:text>unset</xsl:text>
        </xsl:when>
        <!-- legacy had zero error-checking -->
        <xsl:otherwise>
            <xsl:value-of select="$autoname" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Employing variants of the text displayed for a cross-reference -->
<!-- affects the words shown to the reader, and hence is a choice   -->
<!-- preserved in the source, and is not just a processing decision -->
<!-- $xref-text-style is the global choice, based on                -->
<!--   docinfo/cross-references/@text                               -->
<!-- We control the possible values with the schema, allowing junk  -->
<!-- NB: blank is not set, and is ignored so the legacy-autoname    -->
<!-- scheme controls the global default.  When that goes away, we   -->
<!-- should set the default here when there is no attribute.        -->
<xsl:variable name="xref-text-style">
    <xsl:choose>
        <xsl:when test="$docinfo/cross-references/@text">
            <xsl:value-of select="$docinfo/cross-references/@text" />
        </xsl:when>
        <xsl:otherwise>
            <text />
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>


<!-- Sometimes  xsltproc fails, and fails spectacularly,        -->
<!-- setting this switch will dump lots of location info to the -->
<!-- console, and perhaps will be helpful in locating a failure -->
<!-- You might redirect stderror to a file with "2> errors.txt" -->
<!-- appended to your command line                              -->
<xsl:param name="debug" select="'no'" />
<xsl:variable name="b-debug" select="$debug = 'yes'" />

<xsl:param name="debug.datedfiles" select="'yes'" />
<xsl:variable name="b-debug-datedfiles" select="not($debug.datedfiles = 'no')" />

<!-- This code is correct, interface is temporary and will be redone with no notice -->
<xsl:param name="debug.chapter.start" select="''" />

<xsl:variable name="emdash-space">
    <xsl:choose>
        <xsl:when test="$emdash.space = ''">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when test="$emdash.space = 'thin'">
            <xsl:text>thin</xsl:text>
        </xsl:when>
        <xsl:when test="$emdash.space = 'none'">
            <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR:   Option for "emdash.space" should be "none" or "thin", not "<xsl:value-of select="$emdash.space" />".  Assuming the default, "none".</xsl:message>
            <xsl:text>none</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- very temporary, just for testing -->
<xsl:param name="debug.exercises.forward" select="''"/>

<!-- text for a watermark that is centered, -->
<!-- running at a 45 degree angle           -->
<xsl:param name="watermark.text" select="''" />
<xsl:variable name="b-watermark" select="not($watermark.text = '')" />

<!-- watermark uses a 5cm font, which can be scaled                     -->
<!-- and scaling by 0.5 makes "CONFIDENTIAL" fit well in 600 pixel HTML -->
<!-- and in the default body width for LaTeX                            -->
<xsl:param name="watermark.scale" select="'0.5'" />

<!-- Commentary is meant for an enhanced edition, -->
<!-- like an "Instructor's Manual".  A publisher  -->
<!-- will need to consciously elect "yes".        -->
<!-- $input-commentary is local and short-lived,  -->
<!-- $b-commentary is boolean and used elsewhere. -->
<xsl:variable name="input-commentary">
    <xsl:choose>
        <xsl:when test="$commentary = ''">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:when test="$commentary = 'no'">
            <xsl:text>no</xsl:text>
        </xsl:when>
        <xsl:when test="$commentary = 'yes'">
            <xsl:text>yes</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>no</xsl:text>
            <xsl:message>MBX:WARNING: the "commentary" stringparam should be "yes" or "no", not "<xsl:value-of select="$commentary"/>", so assuming "no"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="b-commentary" select="$input-commentary = 'yes'" />

<!-- Text alignment options -->
<xsl:variable name="text-alignment">
    <xsl:choose>
        <xsl:when test="($text.alignment = '') or ($text.alignment = 'justify')">
            <xsl:text>justify</xsl:text>
        </xsl:when>
        <xsl:when test="$text.alignment = 'raggedright'">
            <xsl:text>raggedright</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>justify</xsl:text>
            <xsl:message>MBX:WARNING: the "text.alignment" stringparam should be "justify" or "raggedright", not "<xsl:value-of select="$text.alignment"/>", so assuming "justify"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- To forward-reference solutions to exercises, we need       -->
<!-- to know which ones atually have solutions in place later.  -->
<!-- So we build 30 node-lists according to the direct product  -->
<!--                                                            -->
<!--   {inline, divisional, worksheet, reading, project}        -->
<!--     x                                                      -->
<!--   {hint, answer, solution}                                 -->
<!--     x                                                      -->
<!--   {main, back}                                             -->
<!--                                                            -->
<!-- iff they are elected to be displayed at some point         -->
<!-- (intra-division or back matter) via a "solutions" element. -->
<!--                                                            -->
<!-- First, we provide enough of a path to clearly identify the -->
<!-- exercise component and its location, allowing steps where  -->
<!-- there may be intervening structure (such as an             -->
<!-- "exercisegroup").  Careful - a component in a "worksheet"  -->
<!-- can be part of an "exercise" (worksheet exercise) or part  -->
<!-- of "project" inside a worksheet.                           -->
<!--                                                            -->
<!-- Second, we condition on whether there is a                 -->
<!-- backmatter/solutions  that elects inclusion of the         -->
<!-- component, or if there is a containing division which      -->
<!-- contains a solutions (ancestor::*/child::solutions)        -->
<!-- with the same election.                                    -->

<!-- Hint, Main Matter -->
<xsl:variable name="inline-hint-main"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//hint[ancestor::*/solutions[contains(@inline, 'hint')]]"/>
<xsl:variable name="divisional-hint-main" select="$document-root//exercises//hint[ancestor::*/solutions[contains(@divisional, 'hint')]]"/>
<xsl:variable name="worksheet-hint-main"  select="$document-root//worksheet//exercise//hint[ancestor::*/solutions[contains(@worksheet, 'hint')]]"/>
<xsl:variable name="reading-hint-main"    select="$document-root//reading-questions//hint[ancestor::*/solutions[contains(@reading, 'hint')]]"/>
<xsl:variable name="project-hint-main"    select="$document-root//*[&PROJECT-FILTER;]//hint[ancestor::*/solutions[contains(@project, 'hint')]]"/>
<!-- Hint, Back Matter -->
<xsl:variable name="inline-hint-back"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//hint[$document-root/backmatter/solutions[contains(@inline, 'hint')]]"/>
<xsl:variable name="divisional-hint-back" select="$document-root//exercises//hint[$document-root/backmatter/solutions[contains(@divisional, 'hint')]]"/>
<xsl:variable name="worksheet-hint-back"  select="$document-root//worksheet//exercise//hint[$document-root/backmatter/solutions[contains(@worksheet, 'hint')]]"/>
<xsl:variable name="reading-hint-back"    select="$document-root//reading-questions//hint[$document-root/backmatter/solutions[contains(@reading, 'hint')]]"/>
<xsl:variable name="project-hint-back"    select="$document-root//*[&PROJECT-FILTER;]//hint[$document-root/backmatter/solutions[contains(@project, 'hint')]]"/>
<!-- Answer, Main Matter -->
<xsl:variable name="inline-answer-main"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//answer[ancestor::*/solutions[contains(@inline, 'answer')]]"/>
<xsl:variable name="divisional-answer-main" select="$document-root//exercises//answer[ancestor::*/solutions[contains(@divisional, 'answer')]]"/>
<xsl:variable name="worksheet-answer-main"  select="$document-root//worksheet//exercise//answer[ancestor::*/solutions[contains(@worksheet, 'answer')]]"/>
<xsl:variable name="reading-answer-main"    select="$document-root//reading-questions//answer[ancestor::*/solutions[contains(@reading, 'answer')]]"/>
<xsl:variable name="project-answer-main"    select="$document-root//*[&PROJECT-FILTER;]//answer[ancestor::*/solutions[contains(@project, 'answer')]]"/>
<!-- Answer, Back Matter -->
<xsl:variable name="inline-answer-back"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//answer[$document-root/backmatter/solutions[contains(@inline, 'answer')]]"/>
<xsl:variable name="divisional-answer-back" select="$document-root//exercises//answer[$document-root/backmatter/solutions[contains(@divisional, 'answer')]]"/>
<xsl:variable name="worksheet-answer-back"  select="$document-root//worksheet//exercise//answer[$document-root/backmatter/solutions[contains(@worksheet, 'answer')]]"/>
<xsl:variable name="reading-answer-back"    select="$document-root//reading-questions//answer[$document-root/backmatter/solutions[contains(@reading, 'answer')]]"/>
<xsl:variable name="project-answer-back"    select="$document-root//*[&PROJECT-FILTER;]//answer[$document-root/backmatter/solutions[contains(@project, 'answer')]]"/>
<!-- Solution, Main Matter -->
<xsl:variable name="inline-solution-main"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//solution[ancestor::*/solutions[contains(@inline, 'solution')]]"/>
<xsl:variable name="divisional-solution-main" select="$document-root//exercises//solution[ancestor::*/solutions[contains(@divisional, 'solution')]]"/>
<xsl:variable name="worksheet-solution-main"  select="$document-root//worksheet//exercise//solution[ancestor::*/solutions[contains(@worksheet, 'solution')]]"/>
<xsl:variable name="reading-solution-main"    select="$document-root//reading-questions//solution[ancestor::*/solutions[contains(@reading, 'solution')]]"/>
<xsl:variable name="project-solution-main"    select="$document-root//*[&PROJECT-FILTER;]//solution[ancestor::*/solutions[contains(@project, 'solution')]]"/>
<!-- Solution, Back Matter -->
<xsl:variable name="inline-solution-back"     select="$document-root//exercise[&INLINE-EXERCISE-FILTER;]//solution[$document-root/backmatter/solutions[contains(@inline, 'solution')]]"/>
<xsl:variable name="divisional-solution-back" select="$document-root//exercises//solution[$document-root/backmatter/solutions[contains(@divisional, 'solution')]]"/>
<xsl:variable name="worksheet-solution-back"  select="$document-root//worksheet//exercise//solution[$document-root/backmatter/solutions[contains(@worksheet, 'solution')]]"/>
<xsl:variable name="reading-solution-back"    select="$document-root//reading-questions//solution[$document-root/backmatter/solutions[contains(@reading, 'solution')]]"/>
<xsl:variable name="project-solution-back"    select="$document-root//*[&PROJECT-FILTER;]//solution[$document-root/backmatter/solutions[contains(@project, 'solution')]]"/>

<!-- Combinations that are useful -->
<!-- First: main matter placement vs. back matter placement -->
<xsl:variable name="solutions-mainmatter" select="
$inline-hint-main    |$divisional-hint-main    |$worksheet-hint-main    |$reading-hint-main    |$project-hint-main|
$inline-answer-main  |$divisional-answer-main  |$worksheet-answer-main  |$reading-answer-main  |$project-answer-main|
$inline-solution-main|$divisional-solution-main|$worksheet-solution-main|$reading-solution-main|$project-solution-main"/>
<xsl:variable name="solutions-backmatter" select="
$inline-hint-back    |$divisional-hint-back    |$worksheet-hint-back    |$reading-hint-back    |$project-hint-back|
$inline-answer-back  |$divisional-answer-back  |$worksheet-answer-back  |$reading-answer-back  |$project-answer-back|
$inline-solution-back|$divisional-solution-back|$worksheet-solution-back|$reading-solution-back|$project-solution-back"/>

<!-- ############## -->
<!-- Entry Template -->
<!-- ############## -->

<!-- We never process using just this file, and often want  -->
<!-- to import it elsewhere for the utilities it contains.  -->
<!-- So there is no entry template, nor should there be.    -->
<!-- An importing file, designed for a specific conversion, -->
<!-- can have an entry template and use the general         -->
<!-- "chunking" templates defined below.                    -->


<!-- ###### -->
<!-- Levels -->
<!-- ###### -->

<!-- Certain characteristics of the output can be configured    -->
<!-- based on how deep they are in the hierachy of a structured -->
<!-- document.  Authors specify these characteristics relative  -->
<!-- to their own project, more specifically relative to the    -->
<!-- logical top-level element, such as "book" or "article".    -->
<!-- These are "Level 0". We normalize these numbers internally -->
<!-- so that level 0 is the first possible division in any      -->
<!-- document, which would be a "part"                          -->


<!-- (Relative) Levels -->
<!-- Input: an element that is a division of some kind -->
<!-- Output: its relative level, eg "book" is 0        -->
<!-- Front and back matter are faux divisions, so we   -->
<!-- filter them out.                                  -->


<!--
Schematic of levels of divisions
*  "preface" has 4 peers, eg, "dedication"
*  "appendix" has two peers, "index" and "colophon"
*  specialized divisions, e.g "references" can go numerous places

Article, "section" at level 1
||         0            ||    1     ||     2      ||      3        ||
||          frontmatter ||          ||            ||               ||
|| article              || section  || subsection || subsubsection ||
||          backmatter  || appendix || subsection || subsubsection ||


Book (no parts), "section" at level 2
||        0         ||    1     ||    2     ||     3      ||      4        ||
||      frontmatter || preface  ||          ||            ||               ||
|| book             || chapter  || section  || subsection || subsubsection ||
||      backmatter  || appendix || section  || subsection || subsubsection ||


Book (with parts), "section" at level 3
||  0   ||     1       ||    2     ||    3     ||     4      ||      5        ||
||      || frontmatter || preface  ||          ||            ||               ||
|| book || part        || chapter  || section  || subsection || subsubsection ||
||      || backmatter  || appendix || section  || subsection || subsubsection ||
-->

 <!-- Specific top-level divisions -->
<!-- article/frontmatter, article/backmatter are faux divisions, but   -->
<!-- will function as a terminating condition in recursive count below -->
<xsl:template match="book|article|slideshow|letter|memo|article/frontmatter|article/backmatter" mode="level">
    <xsl:value-of select="0"/>
</xsl:template>

<!-- A book/part will divide the mainmatter, so a "chapter" is at -->
<!-- level 2, so we also put the faux divisions at level 1 in the -->
<!-- case of parts, to again terminate recursive count            -->
<xsl:template match="book/part|book/frontmatter|book/backmatter" mode="level">
    <xsl:choose>
        <xsl:when test="$b-has-parts">
            <xsl:value-of select="1"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="0"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remaining divisions will follow a strict progression from their    -->
<!-- parents.  We have front matter divisions of a book first, which    -->
<!-- will have the same level as a chapter, then traditional divisions, -->
<!-- which may structure a chapter of a book, section of an article,    -->
<!-- or an appendix (structured as a chapter in a book or a sections    -->
<!-- in an article).  Then follows specialized divisions of the back    -->
<!-- matter, which are peers of an appendix.  Finally we have the       -->
<!-- "specialized divisions" of PreTeXt, which can be descendants of    -->
<!-- chapters of books, sections of articles, or in the case of         -->
<!-- solutions or references, children of an appendix.                  -->

<xsl:template match="colophon|biography|dedication|acknowledgement|preface|chapter|section|subsection|subsubsection|slide|appendix|index|colophon|exercises|reading-questions|references|solutions|glossary|worksheet" mode="level">
    <xsl:variable name="level-above">
        <xsl:apply-templates select="parent::*" mode="level"/>
    </xsl:variable>
    <xsl:value-of select="$level-above + 1"/>
</xsl:template>

<xsl:template match="*" mode="level">
    <xsl:message>PTX:BUG:   an element ("<xsl:value-of select="local-name(.)"/>") does not know its level</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>


<!-- Enclosing Level -->
<!-- For any element, work up the tree to a structural -->
<!-- node and then compute level as above              -->
<!-- NB: to meld with previous would require a better     -->
<!-- definition of structural, and care with introduction -->
<xsl:template match="*" mode="enclosing-level">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural = 'true'">
            <xsl:apply-templates select="." mode="level" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="enclosing-level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Relative level offset -->
<!-- This is the adjustment to move a relative       -->
<!-- level onto the absolute scale                   -->
<!--     part: 0                                     -->
<!--     chapter, appendix: 1                        -->
<!--     section: 2                                  -->
<!--     subsection: 3                               -->
<!--     subsubsection: 4                            -->
<!-- It can be defined as the value on this absolute -->
<!-- scale that the $document-root (book, article,   -->
<!-- memo, etc.) would have, depending on options    -->
<!-- for structure beneath it.  So for all divisions -->
<!--                                                 -->
<!-- absolute-level = (relative-)level + root-level  -->
<!--                                                 -->
<!-- NB: 2017-09-05, three places, keep as variable  -->
<xsl:variable name="root-level">
    <xsl:choose>
        <xsl:when test="$root/book/part">-1</xsl:when>
        <xsl:when test="$root/book/chapter">0</xsl:when>
        <!-- An article is rooted just above sections, -->
        <!-- on par with chapters of a book            -->
        <xsl:when test="$root/article">1</xsl:when>
        <xsl:when test="$root/slideshow">1</xsl:when>
        <xsl:when test="$root/letter">1</xsl:when>
        <xsl:when test="$root/memo">1</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Level offset undefined for this document type</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Names for Levels -->
<!-- Levels (ie depths in the tree) translate to MBX element -->
<!-- names and LaTeX divisions, which are generally the same -->
<!-- This is useful for "new" sections (eg exercises) when   -->
<!-- used with standard LaTeX sectioning and numbering       -->

<!-- Input:  a relative level, ie counted from document root -->
<!-- Output:  the LaTeX name (or close), HTML element        -->
<!-- NB:  this is a named template, independent of context   -->
<!-- NB: (2019-05-09) This could go to the -latex conversion -->
<xsl:template name="level-to-name">
    <xsl:param name="level" />
    <xsl:variable name="normalized-level" select="$level + $root-level" />
    <xsl:choose>
        <xsl:when test="$normalized-level=0">part</xsl:when>
        <xsl:when test="$normalized-level=1">chapter</xsl:when>
        <xsl:when test="$normalized-level=2">section</xsl:when>
        <xsl:when test="$normalized-level=3">subsection</xsl:when>
        <xsl:when test="$normalized-level=4">subsubsection</xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Level computation is out-of-bounds (input as <xsl:value-of select="$level" />, normalized to <xsl:value-of select="$normalized-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- LaTex Native Levels -->
<!-- LaTeX has its own internal absolute numbering scheme, -->
<!-- where sections are always level 1, while PTX uses     -->
<!-- level 2. So while a LaTeX-specific computation, we do -->
<!-- the translation here, so as to isolate the use of the -->
<!-- root-level variable in this -common file.             -->
<xsl:template name="level-to-latex-level">
    <xsl:param name="level" />
    <xsl:value-of select="$level + $root-level -1" />
</xsl:template>

<!-- ########### -->
<!-- Mathematics -->
<!-- ########### -->

<!-- Mathematics authored in LaTeX syntax should be       -->
<!-- independent of output format.  Despite MathJax's     -->
<!-- broad array of capabilities, there are still some    -->
<!-- differences which we need to accomodate via abstract -->
<!-- templates.  Those abstractions are documented here   -->
<!-- and also where implemented.  Elsewhere are low-level -->
<!-- manipulations of whitespace in processed versions    -->
<!-- of LaTeX output                                      -->


<!-- Inline Mathematics ("m") -->
<!--                                                     -->
<!-- This is fairly simple.  Differences are             -->
<!--   (1) Some conversions require different delimiters -->
<!--   (2) We adjust punctuation for HTML, but not Latex -->
<!--                                                     -->
<!-- Abstract Templates                                  -->
<!--                                                     -->
<!-- (1) begin-inline-math, end-inline-math              -->
<!--       The delimiters for inline mathematics         -->
<!--       Stub warnings follow below                    -->
<!-- (2) get-clause-punctuation                          -->
<!--       Look at next node, and if a text node,        -->
<!--       then look for leading punctuation, and        -->
<!--       bring into math with \text() wrapper          -->
<!--       when  $math.punctuation.include  indicates    -->

<xsl:param name="debug.displaystyle" select="'yes'"/>

<xsl:template match="m">
    <!-- Build a textual version of the latex,  -->
    <!-- applying the rare templates allowed,   -->
    <!-- save for minor manipulation later.     -->
    <!-- Note: generic text() template here in  -->
    <!-- -common should always pass through the -->
    <!-- text nodes within "m" with no changes  -->
    <xsl:variable name="raw-latex">
        <xsl:choose>
            <xsl:when test="ancestor::static/parent::webwork-reps">
                <xsl:apply-templates select="text()|var" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="text()|fillin" />
            </xsl:otherwise>
        </xsl:choose>
        <!-- look ahead to absorb immediate clause-ending punctuation   -->
        <!-- this is useful for HTML/MathJax to prevent bad line breaks -->
        <!-- The template here in -common is generally useful, but      -->
        <!-- for LaTeX we override to be a no-op, since not necessary   -->
        <xsl:apply-templates select="." mode="get-clause-punctuation" />
    </xsl:variable>
    <!-- wrap tightly in math delimiters -->
    <xsl:call-template name="begin-inline-math" />
    <!-- Prefix will normally be empty and have no effect.  We also have  -->
    <!-- an undocumented switch to totally kill the possibility entirely. -->
    <!-- This was added to support testing of braille output.             -->
    <xsl:if test="not($debug.displaystyle = 'no')">
        <xsl:apply-templates select="."  mode="display-style-prefix"/>
    </xsl:if>
    <!-- we clean whitespace that is irrelevant to LaTeX so that we -->
    <!--   (1) avoid LaTeX compilation errors                       -->
    <!--   (2) avoid spurious blank lines leading to new paragraphs -->
    <!--   (3) provide human-readable source of high quality        -->
    <!-- sanitize-latex template does not provide a final newline   -->
    <!-- and we do not add one here either, since it is inline math -->
    <!-- MathJax is more tolerant, but readability is still useful  -->
    <xsl:call-template name="sanitize-latex">
        <xsl:with-param name="text" select="$raw-latex" />
    </xsl:call-template>
    <xsl:call-template name="end-inline-math" />
</xsl:template>

<xsl:template name="begin-inline-math">
     <xsl:message>PTX:ERROR:   the "begin-inline-math" template needs an implementation in the current conversion</xsl:message>
     <xsl:text>[[[</xsl:text>
 </xsl:template>

<xsl:template name="end-inline-math">
     <xsl:message>PTX:ERROR:   the "end-inline-math" template needs an implementation in the current conversion</xsl:message>
     <xsl:text>]]]</xsl:text>
 </xsl:template>

<!-- Display Style LaTeX markup for inline math -->
<!--                                                     -->
<!-- If the current context "m" is a child of an "li",   -->
<!-- perhaps with an intervening "p", then we            -->
<!-- contemplate injecting a \displaystyle, if *the "m"  -->
<!-- is the only content of the "li"*.-->
<xsl:template match="m" mode="display-style-prefix">
    <!-- We first obtain a parent "li" (or come away    -->
    <!-- empty-handed). Booleans help readability later -->
    <xsl:variable name="parent-li" select="boolean(parent::li)"/>
    <xsl:variable name="grandparent-li" select="boolean(parent::p/parent::li)"/>
    <xsl:variable name="the-list-item" select="parent::li|parent::p/parent::li"/>
    <!-- If we have inline math inside a list item then we   -->
    <!-- can collect all of non-whitespace text() nodes.     -->
    <!-- We are only interested in the case of a single "p". -->
    <xsl:variable name="actual-text">
        <xsl:if test="$the-list-item">
            <xsl:choose>
                <xsl:when test="$parent-li">
                    <xsl:for-each select="$the-list-item/text()">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$grandparent-li">
                    <xsl:for-each select="$the-list-item/p[1]/text()">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:variable>
    <!-- Potential prefix with \displaystyle                        -->
    <!--                                                            -->
    <!-- (1) If there is not a list item, the next two tests fail.  -->
    <!-- (2) If there is any significant text() the tests will fail.-->
    <!-- (3) If there is a parent li, or li/p, the tests will fail  -->
    <!--     if there are more than two "p" or if the content       -->
    <!--     contains other markup (elements) other elements        -->
    <!--     besides just the lone "m".                             -->
    <!--                                                            -->
    <!-- So we improve the appearance of a lone "m" inside an "li". -->
    <!-- Authors who do not like this can add innocuous content.    -->
    <!--  -->
    <!-- The two "when" are disjoint and both may be false.  They   -->
    <!-- produce the same result.  This is meant to be more         -->
    <!-- readable than a big "or".  Note: this could be wrapped in  -->
    <!-- a big "if" based on the common $actual-text.               -->
    <!-- The result of this template is "\displaystyle " or ""      -->
    <xsl:choose>
        <xsl:when test="$parent-li and ($actual-text = '') and (count($the-list-item/*) = 1)">
            <xsl:text>\displaystyle </xsl:text>
        </xsl:when>
        <xsl:when test="$grandparent-li and ($actual-text = '') and (count($the-list-item/p) = 1) and (count($the-list-item/p[1]/*) = 1)">
            <xsl:text>\displaystyle </xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Displayed Single-Line Math ("me", "men") -->
<!-- Single equations ("math equation"), contained within paragraphs -->
<!-- or captions, but not in titles, or other places a 2-D layout    -->
<!-- would be a problem.  Some vertical spacing above and below,     -->
<!-- and centered.  "men" is the numbered variant, which suggests    -->
<!-- it is the target of a cross-reference, which means it needs     -->
<!-- unique identification in its original appearand, and not in     -->
<!-- a duplicate copy.  There is enough in common between these      -->
<!-- variants, but note that "me" could stand alone and be much      -->
<!-- simpler, since it is not numbered.                              -->
<!--                                                                 -->
<!-- Abstract Templates                                              -->
<!--                                                                 -->
<!-- (1) display-math-visual-blank-line                              -->
<!--       Just a line in source to help visually (% for LaTeX)      -->
<!--                                                                 -->
<!-- (2) tag                                                         -->
<!--       Equation-numbering, per equation                          -->
<!--       Never for "men", always for "me"                          -->
<!--                                                                 -->
<!-- (3) qed-here                                                    -->
<!--       Slick device, LaTeX only                                  -->
<!--       But avoid clobbering numbers on right                     -->
<!--                                                                 -->
<!-- (4) display-math-wrapper                                        -->
<!--       An enclosing environment for any displayed mathematics    -->
<!--       Necessary for HTML, no-op for LaTeX                       -->
<!--                                                                 -->
<!-- This is the HTML "body" template, which other conversions       -->
<!-- can just call trivially with some implementations of the        -->
<!-- abstract templates                                              -->

<xsl:template match="me|men" mode="body">
    <!-- block-type parameter is ignored, since the          -->
    <!-- representation never varies, no heading, no wrapper -->
    <xsl:param name="block-type" />
    <!-- If original content, or a duplication -->
    <xsl:param name="b-original" select="true()" />
    <!-- If the only content of a knowl ("men") then we  -->
    <!-- do not include adjacent (trailing) punctuation, -->
    <!-- since it is meaningless                         -->
    <xsl:param name="b-top-level" select="false()" />
    <!-- Build a textual version of the latex,       -->
    <!-- applying the rare templates allowed,        -->
    <!-- save for minor manipulation later.          -->
    <!-- Note: generic text() template here in       -->
    <!-- -common should always pass through the text -->
    <!-- nodes within "me" and "men" with no changes -->
    <xsl:variable name="raw-latex">
        <xsl:choose>
            <xsl:when test="ancestor::webwork">
                <xsl:apply-templates select="text()|var" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="text()|fillin" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="complete-latex">
        <!-- we provide a newline for visual appeal -->
        <xsl:call-template name="display-math-visual-blank-line" />
        <xsl:text>\begin{</xsl:text>
        <xsl:apply-templates select="." mode="displaymath-alignment" />
        <xsl:text>}</xsl:text>
        <xsl:apply-templates select="." mode="alignat-columns" />
        <!-- leading whitespace not present, or stripped -->
        <xsl:text>&#xa;</xsl:text>
        <!-- we clean whitespace that is irrelevant to LaTeX so that we -->
        <!--   (1) avoid LaTeX compilation errors                       -->
        <!--   (2) avoid spurious blank lines leading to new paragraphs -->
        <!--   (3) provide human-readable source of high quality        -->
        <!-- sanitize-latex template does not provide a final newline   -->
        <!-- and we do not add one here either, since it is inline math -->
        <!-- MathJax is more tolerant, but readability is still useful  -->
        <xsl:call-template name="sanitize-latex">
            <xsl:with-param name="text" select="$raw-latex" />
        </xsl:call-template>
        <!-- look ahead to absorb immediate clause-ending punctuation      -->
        <!-- for original versions, and as a child of a duplicated element -->
        <!-- but not in a duplicate that is entirely the display math      -->
        <xsl:if test="$b-original or not($b-top-level)">
            <xsl:apply-templates select="." mode="get-clause-punctuation" />
        </xsl:if>
        <!-- For "men" in LaTeX we supply a \label{},       -->
        <!-- and for HTML we hard-code the equation number, -->
        <!-- plus a label if it has an xml:id               -->
        <!-- This is a no-op for "me"                       -->
        <xsl:apply-templates select="." mode="tag">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
        <!-- For "me" and LaTeX output we perhaps sneak  -->
        <!-- in a \qedhere for tombstone placement       -->
        <!-- Inappropriate if numbers exist to the right -->
        <xsl:apply-templates select="." mode="qed-here" />
        <!-- We add a newline for visually appealing source -->
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>\end{</xsl:text>
        <xsl:apply-templates select="." mode="displaymath-alignment" />
        <xsl:text>}</xsl:text>
        <!-- We must return to a paragraph, so                     -->
        <!-- we can add an unprotected newline                     -->
        <!-- Note: clause-ending punctuation has been absorbed,    -->
        <!-- so is not left orphaned at the start of the next line -->
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    <xsl:apply-templates select="." mode="display-math-wrapper">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="content" select="$complete-latex" />
    </xsl:apply-templates>
</xsl:template>

<!-- Always an "equation" for an "me"              -->
<!-- The equation* is AMS-Math-specific,           -->
<!-- "displaymath" is base-LaTeX equivalent        -->
<!-- *Extensive* discussion at                     -->
<!-- http://tex.stackexchange.com/questions/40492/ -->

<xsl:template match="me" mode="displaymath-alignment">
    <xsl:text>equation*</xsl:text>
</xsl:template>

<xsl:template match="men" mode="displaymath-alignment">
    <xsl:text>equation</xsl:text>
</xsl:template>


<!-- Displayed Multi-Line Math ("md", "mdn") -->
<!-- These are containers for "mrow" and intermediate "intertext".  -->
<!-- The containers are fairly simple, are similar to above,        -->
<!-- and only use one abstract template.                            -->
<!--                                                                -->
<!-- Abstract Templates                                             -->
<!--                                                                -->
<!-- (1) display-math-visual-blank-line                             -->
<!--       Just a line in source to help visually (% for LaTeX)     -->
<!--                                                                -->
<!-- (2) display-math-wrapper                                       -->
<!--       An enclosing environment for any displayed mathematics   -->
<!--       Necessary for HTML, no-op for LaTeX                      -->
<!--                                                                -->
<!-- This is the HTML "body" template, which other conversions      -->
<!-- can just call trivially with some implementations of the       -->
<!-- abstract templates                                             -->

<xsl:template match="md|mdn" mode="body">
    <!-- block-type parameter is ignored, since the          -->
    <!-- representation never varies, no heading, no wrapper -->
    <xsl:param name="block-type" />
    <!-- If original content, or a duplication -->
    <xsl:param name="b-original" select="true()" />
    <!-- If the only content of a knowl ("men") then we  -->
    <!-- do not include adjacent (trailing) punctuation, -->
    <!-- since it is meaningless                         -->
    <xsl:param name="b-top-level" select="false()" />
    <!-- Look across all mrow for 100% no-number rows              -->
    <!-- This just allows for slightly nicer human-readable source -->
    <xsl:variable name="b-nonumbers" select="self::md and not(mrow[@number='yes' or @tag])" />
    <xsl:variable name="complete-latex">
        <!-- we provide a newline for visual appeal -->
        <xsl:call-template name="display-math-visual-blank-line" />
        <xsl:text>\begin{</xsl:text>
        <xsl:apply-templates select="." mode="displaymath-alignment">
            <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
        </xsl:apply-templates>
        <xsl:text>}</xsl:text>
        <xsl:apply-templates select="." mode="alignat-columns" />
        <!-- leading whitespace not present, or stripped -->
        <xsl:text>&#xa;</xsl:text>
        <!-- We don't sanitize, but instead sanitize text versions of  -->
        <!-- each individual "mrow", while not sanitizing "intertext", -->
        <!-- which may be a non-text format (eg HTML).                 -->
        <xsl:apply-templates select="mrow|intertext">
            <xsl:with-param name="b-original" select="$b-original" />
            <xsl:with-param name="b-top-level" select="$b-top-level" />
            <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
        </xsl:apply-templates>
        <!-- each mrow provides a newline, so unlike  -->
        <!-- above, we do not need to add one here    -->
        <xsl:text>\end{</xsl:text>
        <xsl:apply-templates select="." mode="displaymath-alignment">
            <xsl:with-param name="b-nonumbers" select="$b-nonumbers" />
        </xsl:apply-templates>
        <xsl:text>}</xsl:text>
        <!-- We must return to a paragraph, so                     -->
        <!-- we can add an unprotected newline                     -->
        <!-- Note: clause-ending punctuation has been absorbed,    -->
        <!-- so is not left orphaned at the start of the next line -->
        <xsl:text>&#xa;</xsl:text>
    </xsl:variable>
    <xsl:apply-templates select="." mode="display-math-wrapper">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="content" select="$complete-latex" />
    </xsl:apply-templates>
</xsl:template>

<!-- We sniff around for ampersands, to decide between "align"    -->
<!-- and "gather", plus an asterisk for the unnumbered version    -->
<!-- AMSMath has no easy way to make a one-off number within      -->
<!-- the *-form, so we lean toward always using the un-starred    -->
<!-- versions, except when we flag 100% no numbers inside an "md" -->
<xsl:template match="md|mdn" mode="displaymath-alignment">
    <xsl:param name="b-nonumbers" select="false()" />
    <xsl:choose>
        <!-- look for @alignment override, possibly bad -->
        <xsl:when test="@alignment='gather'">
            <xsl:text>gather</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='alignat'">
            <xsl:text>alignat</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment='align'">
            <xsl:text>align</xsl:text>
        </xsl:when>
        <xsl:when test="@alignment">
            <xsl:message>MBX:ERROR: display math @alignment attribute "<xsl:value-of select="@alignment" />" is not recognized (should be "align", "gather", "alignat")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- sniff for alignment specifications    -->
        <!-- this can be easily fooled, eg matrices-->
        <xsl:when test="contains(., '&amp;') or contains(., '\amp')">
            <xsl:text>align</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>gather</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- if absolutely no numbers, we'll economize -->
    <!-- in favor of human-readability             -->
    <xsl:if test="$b-nonumbers">
        <xsl:text>*</xsl:text>
    </xsl:if>
</xsl:template>

<!-- With alignment="alignat" we need the number of columns     -->
<!-- as an argument, complete with the LaTeX group (braces)     -->
<!-- Mostly we call this regularly, and it usually does nothing -->
<xsl:template match="me|men|md|mdn" mode="alignat-columns" />

<xsl:template match="md[@alignment='alignat']|mdn[@alignment='alignat']" mode="alignat-columns">
    <xsl:variable name="number-equation-columns">
        <xsl:choose>
            <!-- override first -->
            <xsl:when test="@alignat-columns">
                <!-- MathJax chokes on spaces here -->
                <xsl:value-of select="normalize-space(@alignat-columns)" />
            </xsl:when>
            <!-- count ampersands, compute columns -->
            <xsl:otherwise>
                <xsl:variable name="number-ampersands">
                    <xsl:apply-templates select="mrow[1]" mode="max-ampersands" />
                </xsl:variable>
                <!-- amps + 1, divide by 2, round up; 0.5 becomes 0.25, round behaves -->
                <xsl:value-of select="round(($number-ampersands + 1.5) div 2)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:text>{</xsl:text>
    <xsl:value-of select="$number-equation-columns" />
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- count ampersands in a string              -->
<!-- both as LaTeX macro and as bare character -->
<xsl:template name="count-ampersands">
    <xsl:param name="text" />
    <xsl:variable name="amp-char">
        <xsl:call-template name="count-substring">
            <xsl:with-param name="text" select="$text" />
            <xsl:with-param name="word" select="'&amp;'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="amp-macro">
        <xsl:call-template name="count-substring">
            <xsl:with-param name="text" select="$text" />
            <xsl:with-param name="word" select="'\amp'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$amp-char + $amp-macro" />
</xsl:template>

<!-- Recurse through "mrow"s of a presumed "md" or "mdn" -->
<!-- counting ampersands and tracking the maximum        -->
<xsl:template match="mrow" mode="max-ampersands">
    <xsl:param name="max" select="0"/>
    <!-- build string/text content -->
    <xsl:variable name="row-content">
        <xsl:for-each select="text()">
            <xsl:value-of select="." />
        </xsl:for-each>
    </xsl:variable>
    <!-- count row's ampersands -->
    <xsl:variable name="ampersands">
        <xsl:call-template name="count-ampersands">
            <xsl:with-param name="text" select="$row-content" />
        </xsl:call-template>
    </xsl:variable>
    <!-- recalculate maximum -->
    <xsl:variable name="new-max">
        <xsl:choose>
            <xsl:when test="$ampersands > $max">
                <xsl:value-of select="$ampersands" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$max" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- recurse or report -->
    <xsl:variable name="following-mrows" select="following-sibling::mrow" />
    <xsl:choose>
        <xsl:when test="$following-mrows">
            <xsl:apply-templates select="$following-mrows[1]" mode="max-ampersands">
                <xsl:with-param name="max" select="$new-max" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$new-max" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Rows of Displayed Multi-Line Math ("mrow") -->
<!-- Each mrow finishes with a newline, for visual output      -->
<!-- We perform LaTeX sanitization on each "mrow" here;        -->
<!-- "intertext" will have HTML output that might get          -->
<!-- stripped out in generic text processing.                  -->
<!--                                                           -->
<!-- Abstract Templates                                        -->
<!--                                                           -->
<!-- (1) display-page-break                                    -->
<!--       LaTeX scheme, no-op in HTML                         -->
<!-- (2) qed-here                                              -->
<!--       Identical to "me", "men" behavior                   -->
<!--       So defined in the vicinity of those                 -->

<xsl:template match="mrow">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="b-top-level" select="false()" />
    <xsl:param name="b-nonumbers" />
    <!-- Build a textual version of the latex,       -->
    <!-- applying the rare templates allowed,        -->
    <!-- save for minor manipulation later.          -->
    <!-- Note: generic text() template here in       -->
    <!-- -common should always pass through the text -->
    <!-- nodes within "me" and "men" with no changes -->
    <xsl:variable name="raw-latex">
        <xsl:choose>
            <xsl:when test="ancestor::webwork">
                <xsl:apply-templates select="text()|xref|var" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="text()|xref|fillin" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="sanitize-latex">
        <xsl:with-param name="text" select="$raw-latex" />
    </xsl:call-template>
    <xsl:if test="not(following-sibling::*[self::mrow or self::intertext])">
        <!-- look ahead to absorb immediate clause-ending punctuation         -->
        <!-- for original versions, and as a child of a duplicated element    -->
        <!-- but not in a duplicate that is entirely the display math         -->
        <!-- pass the context as enclosing environment (parent::*, md or mdn) -->
        <xsl:if test="$b-original or not($b-top-level)">
            <xsl:apply-templates select="parent::*" mode="get-clause-punctuation" />
        </xsl:if>
    </xsl:if>
    <!-- If we built a pure no-number environment, then we add nothing   -->
    <!-- Otherwise, we are in a non-starred environment and get a number -->
    <!-- unless we "\notag" it, which is the better choice under AMSmath -->
    <!-- The modal "tag" template is more complicated than just forming  -->
    <!-- a tag, it is everything associated with an equation, like a     -->
    <!-- \label{} for LaTeX, and also for HTML/MathJax.  It does depend  -->
    <!-- on if the display is the original version or not                -->
    <!-- http://tex.stackexchange.com/questions/48965                    -->
    <!-- The @tag attribute trumps almost everything                     -->
    <xsl:choose>
        <xsl:when test="$b-nonumbers" />
        <xsl:when test="@tag">
            <xsl:apply-templates select="." mode="tag">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="parent::md">
            <xsl:choose>
                <xsl:when test="@number='yes'">
                    <xsl:apply-templates select="." mode="tag">
                <xsl:with-param name="b-original" select="$b-original" />
            </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\notag</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="parent::mdn">
            <xsl:choose>
                <xsl:when test="@number='no'">
                    <xsl:text>\notag</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="tag">
                    <xsl:with-param name="b-original" select="$b-original" />
                </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
    <!-- we have a discretionary page break scheme for LaTeX -->
    <xsl:if test="following-sibling::mrow">
       <xsl:text>\\</xsl:text>
       <xsl:apply-templates select="." mode="display-page-break" />
    </xsl:if>
    <!-- check last row as very end of entire proof      -->
    <!-- and sneak in a \qedhere from the amsthm package -->
    <xsl:if test="not(following-sibling::*)">
        <xsl:apply-templates select="." mode="qed-here" />
    </xsl:if>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- We convert a token into the LaTeX for a symbol     -->
<!-- for use as a local tag. Since we need this to work -->
<!-- in MathJax, we need symbols that are available in  -->
<!-- its limited set of supported commands.  Generally, -->
<!-- AMSMath symbols are the best description.  See     -->
<!-- http://docs.mathjax.org/en/latest/tex.html         -->
<!--     #supported-latex-commands                      -->
<!-- Note: \tag{} expects text mode                     -->
<!-- More? \checkmark, \bullet?                         -->
<!-- TODO: if some text symbols are used, perhaps from  -->
<!-- the textcomp package, then math delimiters will    -->
<!-- move down into the "when" parts of the "choose"    -->
<xsl:template match="@tag" mode="tag-symbol">
    <xsl:call-template name="begin-inline-math" />
    <xsl:choose>
        <!-- Stars -->
        <xsl:when test=". = 'star'">
            <xsl:text>\star</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'dstar'">
            <xsl:text>\star\star</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'tstar'">
            <xsl:text>\star\star\star</xsl:text>
        </xsl:when>
        <!-- Dagger -->
        <xsl:when test=". = 'dagger'">
            <xsl:text>\dagger</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'ddagger'">
            <xsl:text>\dagger\dagger</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'tdagger'">
            <xsl:text>\dagger\dagger\dagger</xsl:text>
        </xsl:when>
        <!-- Hash -->
        <xsl:when test=". = 'hash'">
            <xsl:text>\#</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'dhash'">
            <xsl:text>\#\#</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'thash'">
            <xsl:text>\#\#\#</xsl:text>
        </xsl:when>
        <!-- Maltese -->
        <xsl:when test=". = 'maltese'">
            <xsl:text>\maltese</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'dmaltese'">
            <xsl:text>\maltese\maltese</xsl:text>
        </xsl:when>
        <xsl:when test=". = 'tmaltese'">
            <xsl:text>\maltese\maltese\maltese</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:call-template name="end-inline-math" />
</xsl:template>

<!-- Intertext -->
<!-- "intertext" needs wildly different implementations, -->
<!-- so we do not even try to provide a base             -->
<!-- implementation with abstract portions.              -->


<!-- ############## -->
<!-- LaTeX Preamble -->
<!-- ############## -->

<!-- We round up any author-supplied packages as   -->
<!-- a big string, in LaTeX syntax.  It will need  -->
<!-- manipulation to be usable on the MathJax side -->
<xsl:variable name="latex-packages">
    <xsl:for-each select="$docinfo/latex-preamble/package">
        <xsl:text>\usepackage{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
    </xsl:for-each>
</xsl:variable>

<!-- We pick up user-supplied macros, and         -->
<!-- add three of our own that are useful         -->
<!-- for avoiding conflicts with XML reserved     -->
<!-- characters.  Even though MathJax defines     -->
<!-- \lt  and  \gt  we go ahead and do it         -->
<!-- anyway for completeness.  We add these       -->
<!-- last with a \newcommand to minimize the      -->
<!-- possibility author defines them earlier      -->
<!-- This should be the primary and only          -->
<!-- interface to the macros list, though         -->
<!-- it might need some extra                     -->
<!-- conversion-specific wrapping in use          -->
<!-- and it may be necessary/desirable to replace -->
<!-- newline line-endings with something like {}  -->
<!-- First, we move left-margin as far left as    -->
<!-- possible, then strip all comments,  without  -->
<!-- stripping too much, such as useful \%        -->
<!-- We save in a variable, so only here once     -->
<xsl:variable name="latex-macros">
    <xsl:variable name="latex-left-justified">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text">
                <xsl:value-of select="$docinfo/macros" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="latex-macro-first-percent">
        <xsl:with-param name="latex-code">
            <xsl:value-of select="$latex-left-justified" />
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>\newcommand{\lt}{&lt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\gt}{&gt;}&#xa;</xsl:text>
    <xsl:text>\newcommand{\amp}{&amp;}&#xa;</xsl:text>
</xsl:variable>

<!-- Recursively, line-by-line, find first %                             -->
<!-- If preceded by \, then output and reform with rest of line          -->
<!-- If a naked %, then drop rest of line, tidy up and move to next line -->
<!-- Every output line ends with a newline                               -->
<xsl:template name="latex-macro-first-percent">
    <xsl:param name="latex-code" />
    <xsl:variable name="first-line" select="concat(substring-before($latex-code, '&#xA;'), '&#xA;')" />
    <xsl:variable name="remainder" select="substring-after($latex-code, '&#xA;')" />
    <xsl:choose>
        <!-- done, quit recursing -->
        <xsl:when test="not($latex-code)" />
        <!-- first potential comment character-->
        <xsl:when test="contains($first-line, '%')">
            <xsl:variable name="initial" select="substring-before($first-line, '%')" />
            <xsl:choose>
                <xsl:when test="substring($initial, string-length($initial))='\'">
                    <!-- false positive, output symptom and reorganize -->
                    <xsl:value-of select="concat($initial, '%')" />
                    <xsl:call-template name="latex-macro-first-percent">
                        <xsl:with-param name="latex-code" select="concat(substring-after($first-line, '%'), $remainder)" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- comment character in first column is no line        -->
                    <!-- else, content prior, with stripped newline restored -->
                    <xsl:if test="$initial">
                        <xsl:value-of select="concat($initial, '&#xA;')" />
                    </xsl:if>
                    <!-- move on to remaining lines -->
                    <xsl:call-template name="latex-macro-first-percent">
                        <xsl:with-param name="latex-code" select="$remainder" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- no action, just echo and work the rest -->
            <xsl:value-of select="$first-line" />
            <xsl:call-template name="latex-macro-first-percent">
                <xsl:with-param name="latex-code" select="substring-after($latex-code, '&#xA;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Sage Cells -->
<!-- Contents are text manipulations (below)     -->
<!-- Two abstract named templates in other files -->
<!-- provide the necessary wrapping, per format  -->

<!-- Type; empty element                      -->
<!-- Provide an empty cell to scribble in     -->
<!-- Or break text cells in the Sage notebook -->
<!-- This cell does respect @language         -->
<!-- @copy deprecated  2017-12-21 -->
<xsl:template match="sage[not(input) and not(output) and not(@type) and not(@copy)]">
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="." mode="sage-active-markup">
        <xsl:with-param name="block-type" select="$block-type"/>
        <!-- OK to send empty string, implementation reacts -->
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="@language" />
        </xsl:with-param>
        <xsl:with-param name="in" select="''"/>
        <xsl:with-param name="out" select="''" />
    </xsl:apply-templates>
</xsl:template>

<!-- Type: "invisible"; to doctest, but never show to a reader -->
<xsl:template match="sage[@type='invisible']" />

<!-- Type: "practice"; empty, but with practice announcement -->
<!-- We override this in LaTeX, since it is useless          -->
<!-- (and we can't tell in the abstract wrapping template)   -->
<xsl:template match="sage[@type='practice']">
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="." mode="sage-active-markup">
        <xsl:with-param name="block-type" select="$block-type"/>
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="'practice'" />
        </xsl:with-param>
        <xsl:with-param name="in" select="'# Practice area (not linked for Sage Cell use)&#xa;'"/>
        <xsl:with-param name="out" select="''" />
    </xsl:apply-templates>
</xsl:template>

<!-- @copy deprecated  2017-12-21 -->
<!-- Type: "copy"; used for replays     -->
<!-- Mostly when HTML is chunked        -->
<!-- Just handle the same way as others -->
<!-- TODO: HTML copies will get same id! -->
<xsl:template match="sage[@copy]">
    <xsl:apply-templates select="id(@copy)" />
</xsl:template>

<!-- Type: "display"; input portion as uneditable, unevaluatable -->
<!-- This calls a slightly different abstract template           -->
<!-- We do not pass along any output, since this is silly        -->
<!-- These cells are meant to be be incorrect or incomplete      -->
<xsl:template match="sage[@type='display']">
    <xsl:param name="block-type"/>

    <xsl:call-template name="sage-display-markup">
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="'display'" />
        </xsl:with-param>
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="input" />
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Type: "full" (the default)         -->
<!-- Absent meeting any other condition -->
<xsl:template match="sage|sage[@type='full']">
    <xsl:param name="block-type"/>

    <xsl:apply-templates select="." mode="sage-active-markup">
        <xsl:with-param name="block-type" select="$block-type"/>
        <!-- OK to send empty string, implementation reacts -->
        <xsl:with-param name="language-attribute">
            <xsl:value-of select="@language" />
        </xsl:with-param>
        <xsl:with-param name="in">
            <xsl:call-template name="sanitize-text">
                <xsl:with-param name="text" select="input" />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="out">
            <xsl:if test="output">
                <xsl:call-template name="sanitize-text" >
                    <xsl:with-param name="text" select="output" />
                </xsl:call-template>
            </xsl:if>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- Console Session -->
<!-- An interactive command-line session with a prompt, input and output -->
<!-- Generic template here, specifics of input and output elsewhere      -->
<xsl:template match="console">
    <!-- ignore prompt, and pick it up in trailing input -->
    <xsl:apply-templates select="input|output" />
</xsl:template>

<!-- ################# -->
<!-- Preformatted Text -->
<!-- ################# -->

<!-- The content of a "pre" element is wrapped many ways, -->
<!-- but the content itself is always strictly text       -->

<!-- With no "cline", we adjust left margin -->
<xsl:template match="pre" mode="interior">
    <xsl:call-template name="sanitize-text">
        <xsl:with-param name="text" select="." />
    </xsl:call-template>
</xsl:template>

<!-- With a "cline", we process the lines -->
<xsl:template match="pre[cline]" mode="interior">
    <xsl:apply-templates select="cline" />
</xsl:template>

<!-- Code Lines -->
<!-- A "cline" is used to (optionally) structure hunks     -->
<!-- of verbatim text.  Due to its simplicity, it should   -->
<!-- be universal and the only efffect is to add a newline -->
<!-- character, which the output format should recognize   -->
<!-- via its own devices.                                  -->
<xsl:template match="cline">
    <xsl:value-of select="." />
    <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- ############## -->
<!-- Lists of Names -->
<!-- ############## -->

<!-- Authors and editors are people credited in the front matter and in   -->
<!-- mastheads, etc.  Authors can appear on major divisions, such as      -->
<!-- chapters and sections.  There can be multiple, and we want to string -->
<!-- them together with commas, and give editors a parenthetical          -->
<!-- distinction.                                                         -->

<!-- First, we kill these elements as metadata, so we do not process them  -->
<!-- in document order, but instead need to always process them with modal -->
<!-- templates.                                                            -->
<xsl:template match="author|editor" />

<!-- Names can appear structured in the front matter, unstructured on -->
<!-- divisions, or as cross-references to contributors.               -->
<xsl:template match="author|editor" mode="name-only">
    <xsl:choose>
        <!-- structured version -->
        <xsl:when test="personname">
            <xsl:apply-templates select="personname"/>
        </xsl:when>
        <!-- Schematron assertion requires the target -->
        <!-- of the xref to be a contributor element  -->
        <xsl:when test="xref">
            <xsl:apply-templates select="xref"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="node()"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Authors, editors in serial lists for headers -->
<xsl:template match="author|editor" mode="name-list" >
    <!-- separator, if following -->
    <xsl:if test="preceding-sibling::author|preceding-sibling::editor">
        <xsl:text>, </xsl:text>
    </xsl:if>
    <!-- name itself, from "personname" or the content -->
    <xsl:apply-templates select="." mode="name-only"/>
    <xsl:if test="self::editor">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="." mode="type-name" />
        <xsl:text>)</xsl:text>
    </xsl:if>
</xsl:template>

<!-- ########################## -->
<!-- Text Manipulation Routines -->
<!-- ########################## -->

<!-- Various bits of textual material            -->
<!-- (eg Sage, code, verbatim, LaTeX)            -->
<!-- require manipulation to                     -->
<!--                                             -->
<!--   (a) behave in some output format          -->
<!--   (b) produce human-readable output (LaTeX) -->

<!-- We need to identify particular characters   -->
<!-- space, tab, carriage return, newline        -->
<xsl:variable name="whitespaces">
    <xsl:text>&#x20;&#x9;&#xD;&#xA;</xsl:text>
</xsl:variable>
<!-- space, tab, carriage return, newline        -->
<xsl:variable name="blanks">
    <xsl:text>&#x20;&#x9;</xsl:text>
</xsl:variable>
<!-- Punctuation ending a clause of a sentence   -->
<!-- Asymmetric: no space, mark, space           -->
<xsl:variable name="clause-ending-marks">
    <xsl:text>.?!:;,</xsl:text>
</xsl:variable>

<!-- Sanitize Code -->
<!-- No leading whitespace, no trailing -->
<!-- http://stackoverflow.com/questions/1134318/xslt-xslstrip-space-does-not-work -->
<!-- Trim all whitespace at end of code hunk -->
<!-- Append carriage return to mark last line, remove later -->
<xsl:template name="trim-end">
   <xsl:param name="text"/>
   <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
   <xsl:choose>
        <xsl:when test="$last-char=''">
            <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="contains($whitespaces, $last-char)">
            <xsl:call-template name="trim-end">
                <xsl:with-param name="text" select="substring($text, 1, string-length($text) - 1)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text" />
            <xsl:text>&#xA;</xsl:text>
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Trim all totally whitespace lines from beginning of code hunk -->
<xsl:template name="trim-start-lines">
   <xsl:param name="text"/>
   <xsl:param name="pad" select="''"/>
   <xsl:variable name="first-char" select="substring($text, 1, 1)" />
   <xsl:choose>
        <!-- Possibly nothing, return just final carriage return -->
        <xsl:when test="$first-char=''">
            <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="$first-char='&#xA;'">
            <xsl:call-template name="trim-start-lines">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="trim-start-lines">
                <xsl:with-param name="text" select="substring($text, 2)" />
                <xsl:with-param name="pad"  select="concat($pad, $first-char)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="concat($pad, $text)" />
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Compute length of indentation of first line                   -->
<!-- Assumes no leading blank lines                                -->
<!-- Assumes each line, including last, ends in a carriage return  -->
<xsl:template name="count-pad-length">
   <xsl:param name="text"/>
   <xsl:param name="pad" select="''"/>
   <xsl:variable name="first-char" select="substring($text, 1, 1)" />
   <xsl:choose>
        <xsl:when test="$first-char='&#xA;'">
            <xsl:value-of select="string-length($pad)" />
        </xsl:when>
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="count-pad-length">
                <xsl:with-param name="text" select="substring($text, 2)" />
                <xsl:with-param name="pad"  select="concat($pad, $first-char)" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="string-length($pad)" />
        </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<!-- Compute width of left margin        -->
<!-- Assumes each line ends in a newline -->
<!-- A blank line will not contribute    -->
<xsl:template name="left-margin">
    <xsl:param name="text" />
    <xsl:param name="margin" select="32767" />  <!-- 2^15 - 1 as max? -->
    <xsl:choose>
        <xsl:when test="$text=''">
            <!-- Nothing left, then done, return -->
            <xsl:value-of select="$margin" />
        </xsl:when>
        <xsl:otherwise>
            <!-- Non-destructively count leading whitespace -->
            <xsl:variable name="pad-top-line">
                <xsl:call-template name="count-pad-length">
                    <xsl:with-param name="text" select="$text" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="content-top-line" select="substring-before($text, '&#xa;')" />
            <!-- Compute margin as smaller of incoming and computed -->
            <!-- Unless incoming is 0 due to blank line             -->
            <xsl:variable name="new-margin">
                <xsl:choose>
                    <xsl:when test="($margin > $pad-top-line) and not(string-length($content-top-line) = 0)">
                        <xsl:value-of select="$pad-top-line" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$margin" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- Recursive call with one less line, new margin -->
            <xsl:call-template name="left-margin">
                <xsl:with-param name="margin" select="$new-margin" />
                <xsl:with-param name="text" select="substring-after($text,'&#xA;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- An "out-dented" line is assumed to be intermediate blank line     -->
<!-- indent parameter is a number giving number of characters to strip -->
<xsl:template name="strip-indentation">
    <xsl:param name="text" />
    <xsl:param name="indent" />
    <xsl:if test="$text != ''">
        <xsl:variable name="first-line" select="substring-before($text, '&#xA;')" />
        <xsl:if test="string-length($first-line) > $indent" >
            <xsl:value-of select="substring($first-line, $indent + 1)" />
        </xsl:if>
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="strip-indentation">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')" />
            <xsl:with-param name="indent" select="$indent" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Add a common string in front of every line of a block -->
<!-- Typically spaces to format output block for doctest   -->
<!-- indent parameter is a string                          -->
<!-- Assumes last character is xA                          -->
<!-- Result has trailing xA                                -->
<xsl:template name="add-indentation">
    <xsl:param name="text" />
    <xsl:param name="indent" />
    <xsl:if test="$text != ''">
        <xsl:value-of select="concat($indent,substring-before($text, '&#xA;'))" />
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="add-indentation">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')" />
            <xsl:with-param name="indent" select="$indent" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Main template for cleaning up hunks of raw text      -->
<!--                                                      -->
<!-- 1) Trim all trailing whitespace                      -->
<!-- 2) Add carriage return marker to last line           -->
<!-- 3) Strip all totally blank leading lines             -->
<!-- 4) Determine indentation of left-most non-blank line -->
<!-- 5) Strip indentation from all lines                  -->
<!-- 6) Allow intermediate blank lines                    -->

<xsl:template name="sanitize-text">
    <xsl:param name="text" />
    <xsl:variable name="trimmed-text">
        <xsl:call-template name="trim-start-lines">
            <xsl:with-param name="text">
                <xsl:call-template name="trim-end">
                    <xsl:with-param name="text" select="$text" />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="left-margin">
        <xsl:call-template name="left-margin">
            <xsl:with-param name="text" select="$trimmed-text" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="strip-indentation" >
        <xsl:with-param name="text" select="$trimmed-text" />
        <xsl:with-param name="indent" select="$left-margin" />
    </xsl:call-template>
</xsl:template>

<!-- Substrings at last markers               -->
<!-- XSLT Cookbook, 2nd Edition               -->
<!-- Copyright 2006, O'Reilly Media, Inc.     -->
<!-- Recipe 2.4, nearly verbatim, reformatted -->
<xsl:template name="substring-before-last">
    <xsl:param name="input" />
    <xsl:param name="substr" />
    <xsl:if test="$substr and contains($input, $substr)">
        <xsl:variable name="temp" select="substring-after($input, $substr)" />
        <xsl:value-of select="substring-before($input, $substr)" />
        <xsl:if test="contains($temp, $substr)">
            <xsl:value-of select="$substr" />
            <xsl:call-template name="substring-before-last">
                <xsl:with-param name="input" select="$temp" />
                <xsl:with-param name="substr" select="$substr" />
            </xsl:call-template>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- If the substring is not contained, the first substring-after()   -->
<!-- will return empty and entire template will return empty.  To     -->
<!-- get the whole string, prepend $input with $substr prior to using -->
<xsl:template name="substring-after-last">
    <xsl:param name="input"/>
    <xsl:param name="substr"/>
    <!-- Extract the string which comes after the first occurrence -->
    <xsl:variable name="temp" select="substring-after($input,$substr)"/>
    <xsl:choose>
        <!-- If it still contains the search string then recursively process -->
        <xsl:when test="$substr and contains($temp,$substr)">
            <xsl:call-template name="substring-after-last">
                <xsl:with-param name="input" select="$temp"/>
                <xsl:with-param name="substr" select="$substr"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$temp"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Duplicating Strings                      -->
<!-- XSLT Cookbook, 2nd Edition               -->
<!-- Copyright 2006, O'Reilly Media, Inc.     -->
<!-- Recipe 2.5, nearly verbatim, reformatted -->
<xsl:template name="duplicate-string">
     <xsl:param name="text" />
     <xsl:param name="count" select="1" />
     <xsl:choose>
          <xsl:when test="not($count) or not($text)" />
          <xsl:when test="$count = 1">
               <xsl:value-of select="$text" />
          </xsl:when>
          <xsl:otherwise>
               <!-- If $count is odd, append one copy of input -->
               <xsl:if test="$count mod 2">
                    <xsl:value-of select="$text" />
               </xsl:if>
               <!-- Recursively apply template, after -->
               <!-- doubling input and halving count  -->
               <xsl:call-template name="duplicate-string">
                    <xsl:with-param name="text" select="concat($text,$text)" />
                    <xsl:with-param name="count" select="floor($count div 2)" />
               </xsl:call-template>
          </xsl:otherwise>
     </xsl:choose>
</xsl:template>

<!-- Prepending Strings -->
<!-- Add  count  copies of the string  pad  to  each line of  text -->
<!-- Presumes  text  has a newline character at the very end       -->
<xsl:template name="prepend-string">
    <xsl:param name="text" />
    <xsl:param name="pad" />
    <xsl:param name="count" select="1" />
    <xsl:variable name="bigpad">
        <xsl:call-template name="duplicate-string">
            <xsl:with-param name="text" select="$pad" />
            <xsl:with-param name="count" select="$count" />
        </xsl:call-template>
    </xsl:variable>
    <!-- Quit when string becomes empty -->
    <xsl:if test="string-length($text)">
        <xsl:variable name="first-line" select="substring-before($text, '&#xa;')" />
        <xsl:value-of select="$bigpad" />
        <xsl:value-of select="$first-line" />
        <xsl:text>&#xa;</xsl:text>
        <!-- recursive call on remaining lines -->
        <xsl:call-template name="prepend-string">
            <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            <xsl:with-param name="pad" select="$bigpad" />
            <xsl:with-param name="count" select="1" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Counting Substrings -->
<xsl:template name="count-substring">
    <xsl:param name="text" />
    <xsl:param name="word" />
    <xsl:param name="count" select="'0'" />
    <xsl:choose>
        <xsl:when test="not(contains($text, $word))">
            <xsl:value-of select="$count" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="count-substring">
                <xsl:with-param name="text" select="substring-after($text, $word)" />
                <xsl:with-param name="word" select="$word" />
                <xsl:with-param name="count" select="$count + 1" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remove empty lines -->
<!-- These are lines with no characters -->
<!-- at all, just a newline             -->
<!-- 2017-01-22: UNUSED, UNTESTED, incorporate with caution  -->
<xsl:template name="strip-empty-lines">
    <xsl:param name="text" />
    <xsl:choose>
        <!-- no more splitting, output $text, empty or not -->
        <xsl:when test="not(contains($text, '&#xa;'))">
            <xsl:value-of select="$text" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="firstline" select="substring-before($text, '&#xa;')" />
            <xsl:choose>
                <!-- silently drop an empty line, newline already gone -->
                <xsl:when test="not($firstline)" />
                <!-- output first line with restored newline -->
                <xsl:otherwise>
                    <xsl:value-of select="concat($firstline, '&#xa;')" />
                </xsl:otherwise>
            </xsl:choose>
            <!-- recurse with remainder -->
            <xsl:call-template name="strip-empty-lines">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Gobble leading whitespace -->
<!-- Drop consecutive leading spaces and tabs           -->
<!-- Designed for a single line as input                -->
<!-- Used after maniplating sentence ending punctuation -->
<xsl:template name="strip-leading-blanks">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- if empty, done -->
        <xsl:when test="not($first-char)" />
        <!-- first character is space, tab, drop it -->
        <xsl:when test="contains($blanks, $first-char)">
            <xsl:call-template name="strip-leading-blanks">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Shove text left -->
<!-- Remove all leading whitespace from every line -->
<!-- Note: very similar to "sanitize-latex" below           -->
<!-- 2017-01-22: UNUSED, UNTESTED, incorporate with caution -->
<xsl:template name="slide-text-left">
    <xsl:param name="text" />
    <xsl:choose>
        <!-- no more splitting, strip leading whitespace -->
        <xsl:when test="not(contains($text, '&#xa;'))">
            <xsl:call-template name="strip-leading-blanks">
                <xsl:with-param name="text">
                    <xsl:value-of select="$text" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="strip-leading-blanks">
                <xsl:with-param name="text" select="concat(substring-before($text, '&#xa;'), '&#xa;')" />
            </xsl:call-template>
            <!-- recurse with remainder -->
            <xsl:call-template name="slide-text-left">
                <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Sanitize LaTex -->
<!-- We allow authors to include whitespace for readability          -->
<!--                                                                 -->
<!-- (1) Newlines used to format complicated math (eg matrices)      -->
<!-- (2) Newlines used to avoid word-wrapping in editing tools       -->
<!-- (3) Newlines to support atomic version control changesets       -->
<!-- (4) Source indentation of above, consonant with XML indentation -->
<!--                                                                 -->
<!-- But once we form LaTeX output we want to                        -->
<!--                                                                 -->
<!--   (i)   Remove 100% whitespace lines                            -->
<!--   (ii)  Remove leading whitespace                               -->
<!--   (iii) Finish without a newline                                -->
<!--                                                                 -->
<!-- So we                                                           -->
<!--                                                                 -->
<!-- (a) Strip all leading whitespace                                -->
<!-- (b) Remove any 100% resulting empty lines (newline only)        -->
<!-- (c) Preserve remaining newlines (trailing after content)        -->
<!-- (d) Preserve remaining whitespace (eg, within expressions)      -->
<!-- (e) Take care with trailing characters, except final newline    -->
<!--                                                                 -->
<!-- We can do this because of the limited purposes of the           -->
<!-- m, me, men, md, mdn elements.  The whitespace we strip is not   -->
<!-- relevant/important, and what we leave does not change output    -->
<xsl:template name="sanitize-latex">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- empty, end recursion -->
        <xsl:when test="$first-char = ''" />
        <!-- first character is whitespace, including newline -->
        <!-- silently drop it as we recurse on remainder      -->
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="sanitize-latex">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- content followed by newline                           -->
        <!-- split, preserve newline, output, and recurse, but     -->
        <!-- drop a newline that only protects trailing whitespace -->
        <xsl:when test="contains($text, '&#xa;')">
            <xsl:value-of select="substring-before($text, '&#xa;')" />
            <xsl:variable name="remainder" select="substring-after($text, '&#xa;')" />
            <xsl:choose>
                <xsl:when test="normalize-space($remainder) = ''" />
                <xsl:otherwise>
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:call-template name="sanitize-latex">
                        <xsl:with-param name="text" select="$remainder" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- content, no following newline -->
        <!-- output in full, end recursion -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This collects "clause-ending" punctuation     -->
<!-- from the *front* of a text node.  It does not -->
<!-- change the text node, but simply outputs the  -->
<!-- punctuation for use by another template       -->
<xsl:template name="leading-clause-punctuation">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- empty, quit -->
        <xsl:when test="not($first-char)" />
        <!-- if punctuation, output and recurse -->
        <!-- else silently quit recursion       -->
        <xsl:when test="contains($clause-ending-marks, $first-char)">
            <xsl:value-of select="$first-char" />
            <xsl:call-template name="leading-clause-punctuation">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- consecutive only, stop collecting -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<!-- If we absorb punctuation, we need to scrub it by    -->
<!-- examining and manipulating the text node with       -->
<!-- those characters.  We drop consecutive punctuation. -->
<xsl:template name="drop-clause-punctuation">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- if empty, done -->
        <xsl:when test="not($first-char)" />
        <!-- first character ends sentence, drop it, recurse -->
        <xsl:when test="contains($clause-ending-marks, $first-char)">
            <xsl:call-template name="drop-clause-punctuation">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- no more punctuation, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remove consecutive run of blanks and  -->
<!-- newlines in first portion of a string -->
<xsl:template name="strip-leading-whitespace">
    <xsl:param name="text" />
    <xsl:variable name="first-char" select="substring($text, 1, 1)" />
    <xsl:choose>
        <!-- if empty, quit -->
        <xsl:when test="not($first-char)" />
        <!-- if first character is whitespace, drop it -->
        <xsl:when test="contains($whitespaces, $first-char)">
            <xsl:call-template name="strip-leading-whitespace">
                <xsl:with-param name="text" select="substring($text, 2)" />
            </xsl:call-template>
        </xsl:when>
        <!-- else finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Remove consecutive run of blanks and -->
<!-- newlines in last portion of a string -->
<xsl:template name="strip-trailing-whitespace">
    <xsl:param name="text" />
    <xsl:variable name="last-char" select="substring($text, string-length($text), 1)" />
    <xsl:choose>
        <!-- if empty, quit -->
        <xsl:when test="not($last-char)" />
        <!-- if last character is whitespace, drop it -->
        <xsl:when test="contains($whitespaces, $last-char)">
            <xsl:call-template name="strip-trailing-whitespace">
                <xsl:with-param name="text" select="substring($text, 1, string-length($text)-1)" />
            </xsl:call-template>
        </xsl:when>
        <!-- else finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- spurious newlines introduce whitespace on either side -->
<!-- we split at newlines, strip consecutive whitesapce on either side, -->
<!-- and replace newlines by spaces (could restore a single newline) -->
<xsl:template name="strip-newlines">
    <xsl:param name="text" />
    <xsl:choose>
        <!-- if has newline, modify newline-free front portion -->
        <!-- replace splitting newline with new separator      -->
        <!-- modify trailing portion, and recurse with it      -->
        <xsl:when test="contains($text, '&#xa;')">
            <!-- clean trailing portion of left half -->
            <xsl:call-template name="strip-trailing-whitespace">
                <xsl:with-param name="text" select="substring-before($text, '&#xa;')" />
            </xsl:call-template>
            <!-- restore a separator, blank now -->
            <!-- Note: this could be a newline, perhaps optionally (whitespace="breaks") -->
            <!-- Note: this could be " %\n" in LaTeX output to be super explicit -->
            <xsl:text> </xsl:text>
            <!-- recurse with modified right half -->
            <xsl:call-template name="strip-newlines">
                <xsl:with-param name="text">
                    <!-- clean leading portion of right half -->
                    <xsl:call-template name="strip-leading-whitespace">
                        <xsl:with-param name="text" select="substring-after($text, '&#xa;')" />
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:when>
        <!-- else finished stripping, output as-is -->
        <xsl:otherwise>
            <xsl:value-of select="$text" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- JSON Escaped Strings -->
<!-- Convert a string, just prior to dropping it into a  -->
<!-- JSON data structure, so this presumes nothing       -->
<!-- special has been done with the contents before-hand -->
<!-- In order converted, using the standard JSON names:  -->
<!--     reverse solidus (backslash), solidus (slash),   -->
<!--     quotation mark, backspace, horizontal tab,      -->
<!--     newline, form feed, carriage return             -->
<!-- Escaping solidus (forward slash) is only necessary  -->
<!-- for <\ inside a script tag (or similar?)  It makes  -->
<!-- URLs ugly, but we do it anyway so we don't get bit. -->
<!-- Strictly needed:  backslash, double quote, newline. -->
<!-- XSLT3:                                              -->
<!-- But XML 1.0 does not allow x08 (backspace) and x0c  -->
<!-- (form feed) so we ignore them for now.  Perhaps see -->
<!-- https://stackoverflow.com/questions/404107/         -->
<!-- why-are-control-characters-illegal-in-xml-1-0       -->
<xsl:template name="escape-json-string">
    <xsl:param name="text"/>

    <!-- backslash first since it will be introduced -->
    <!-- later as the escape character itself        -->
    <xsl:variable name="sans-backslash" select="str:replace($text,           '\',      '\\'     )"/>
    <xsl:variable name="sans-slash"     select="str:replace($sans-backslash, '/',      '\/'     )"/>
    <xsl:variable name="sans-quote"     select="str:replace($sans-slash,     '&#x22;', '\&#x22;')"/>
<!--<xsl:variable name="sans-backspace" select="str:replace($sans-quote,     '&#x08;', '\b'     )"/>-->
    <xsl:variable name="sans-tab"       select="str:replace($sans-quote,     '&#x09;', '\t'     )"/>
    <xsl:variable name="sans-newline"   select="str:replace($sans-tab,       '&#x0a;', '\n'     )"/>
<!--<xsl:variable name="sans-formfeed"  select="str:replace($sans-newline,   '&#x0c;', '\f'     )"/>-->
    <xsl:variable name="sans-return"    select="str:replace($sans-newline,   '&#x0d;', '\r'     )"/>

    <xsl:value-of select="$sans-return" />
</xsl:template>

<!-- File Extension -->
<!-- Input: full filename                       -->
<!-- Output: extension (no period), lowercase'd -->
<!-- Note: appended query string is stripped    -->
<xsl:template name="file-extension">
    <xsl:param name="filename" />
    <!-- Add a question mark, then grab leading substring -->
    <!-- This will fail if "?" is encoded                 -->
    <xsl:variable name="no-query-string" select="substring-before(concat($filename, '?'), '?')" />
    <!-- get extension after last period   -->
    <!-- will return empty if no extension -->
    <xsl:variable name="extension">
        <xsl:call-template name="substring-after-last">
            <xsl:with-param name="input" select="$no-query-string" />
            <xsl:with-param name="substr" select="'.'" />
        </xsl:call-template>
    </xsl:variable>
    <!-- to lowercase -->
    <xsl:value-of select="translate($extension, &UPPERCASE;, &LOWERCASE;)" />
</xsl:template>

<!-- ############# -->
<!-- Serialization -->
<!-- ############# -->

<!-- Convert a node (perhaps the root of a node-set       -->
<!-- built from an RTF) into its string representation.   -->
<!-- Used initially for conversion of PreTeXt markup to   -->
<!-- the JSON format of a Jupyter notebook.  Identical to -->
<!-- https://stackoverflow.com/questions/6696382 at       -->
<!-- comment https://stackoverflow.com/a/15783514         -->
<!--                                                      -->
<!-- Comment on original solution says:  "The above       -->
<!-- serializer templates do not handle e.g. attributes,  -->
<!-- namespaces, or reserved characters in text nodes..." -->
<!-- This serves our purposes, but perhaps needs          -->
<!-- improvements to be fully general.                    -->
<!-- (See https://stackoverflow.com/a/6698849)            -->


<xsl:template match="*" mode="serialize">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:apply-templates select="." mode="serialize-namespace" />
    <xsl:apply-templates select="@*" mode="serialize" />
    <xsl:choose>
        <xsl:when test="node()">
            <xsl:text>&gt;</xsl:text>
            <xsl:apply-templates mode="serialize" />
            <xsl:text>&lt;/</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>&gt;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text> /&gt;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="@*" mode="serialize">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
</xsl:template>

<!-- A namespace "attribute" is not really an attribute, and not captured by @* above.   -->
<!-- There seems to be no way to separate an element's actual namespaces from those that -->
<!-- are explicitly written where the element was created. Here, we loop through all the -->
<!-- element's namespaces, discarding some that can be safley assumed to not be in the   -->
<!-- original element declaration. And then serialize what is left.                      -->
<xsl:template match="*" mode="serialize-namespace">
    <xsl:for-each select="./namespace::*">
        <!-- test taken from http://lenzconsulting.com/namespace-normalizer/normalize-namespaces.xsl -->
        <xsl:if test="name()!='xml' and not(.=../preceding::*/namespace::* or .=ancestor::*[position()>1]/namespace::*)">
            <xsl:text> xmlns</xsl:text>
            <xsl:if test="not(name(current())='')">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="name(current())"/>
            </xsl:if>
            <xsl:text>="</xsl:text>
            <xsl:value-of select="current()"/>
            <xsl:text>"</xsl:text>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<xsl:template match="text()" mode="serialize">
    <xsl:value-of select="."/>
</xsl:template>

<!-- ################# -->
<!-- String Utilities -->
<!-- ################# -->

<!-- Find a delimiter: find a character that can be wrapped around a string -->
<!-- Take a string as one input and a list of characters as another input   -->
<!-- Return the first character from the list that is not in the string     -->
<xsl:template name="find-unused-character">
    <xsl:param name="string" select="''"/>
    <!-- set of characters passed in the original call -->
    <xsl:param name="charset" select="concat($apos,'&quot;|/!?=~')"/>
    <!-- reduced set of characters still in play during a recursive iteration  -->
    <xsl:param name="characters" select="$charset"/>
    <xsl:choose>
        <xsl:when test="$characters = ''">
            <xsl:message>PTX:FATAL:   Unable to find an unused character in:&#xa;<xsl:value-of select="$string" />&#xa;using characters from: <xsl:value-of select="$charset" /></xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="not(contains($string,substring($characters,1,1)))">
            <xsl:value-of select="substring($characters,1,1)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="find-unused-character">
                <xsl:with-param name="string" select="$string"/>
                <xsl:with-param name="charset" select="$charset"/>
                <xsl:with-param name="characters" select="substring($characters,2)"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ############### -->
<!-- Token Utilities -->
<!-- ############### -->

<!-- Routines that can be employed in a recursive      -->
<!-- formulation to process a string (attribute value, -->
<!-- usually) that is separated by spaces or by commas -->

<!-- Replace commas by blanks, constrict blanks to singletons, -->
<!-- add trailing blank for last step of iteration             -->
<xsl:template name="prepare-token-list">
    <xsl:param name="token-list" />
    <xsl:value-of select="concat(normalize-space(str:replace($token-list, ',', ' ')), ' ')" />
</xsl:template>

<!-- Now, to work through the $token-list                          -->
<!--   1. If $token-list = '', end recursion                       -->
<!--   2. Process substring-before($token-list, ' ') as next token -->
<!--   3. Pass substring-after($token-list, ' ') recursively       -->

<!-- ################## -->
<!-- LaTeX Shortcomings -->
<!-- ################## -->

<!-- Math bits are authored in LaTeX syntax, -->
<!-- but sometimes LaTeX needs a little help -->
<!-- to do the right thing.  This help is    -->
<!-- often common to several output formats, -->
<!-- so we put these modal templates here.   -->

<!-- Clauses ending with math -->
<!-- We look for an immediately adjacent/subsequent text -->
<!-- node and if we get any punctuation, we wrap it for  -->
<!-- inclusion in the final throes of the math part      -->
<!-- A corresponding event happens with the following    -->
<!-- text() node: the punctuation will get scrubbed      -->
<!-- from there iff the punctuation migrates in this     -->
<xsl:template match="m|me|men|md|mdn" mode="get-clause-punctuation">
    <xsl:if test="(self::m and $b-include-inline) or ((self::me|self::men|self::md|self::mdn) and $b-include-display)">
        <xsl:variable name="trailing-text" select="following-sibling::node()[1]/self::text()" />
        <xsl:variable name="punctuation">
            <xsl:call-template name="leading-clause-punctuation">
                <xsl:with-param name="text" select="$trailing-text" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="not($punctuation = '')">
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$punctuation" />
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:if>
</xsl:template>



<!-- ################################## -->
<!-- General Text Handling and Clean-Up -->
<!-- ################################## -->

<!-- Debugging information is not documented, nor supported -->
<!-- Only outputs on a change                               -->
<xsl:param name="ws.debug" select="'no'" />
<xsl:variable name="wsdebug" select="boolean($ws.debug = 'yes')" />

<!-- Text adjustments -->
<!-- This is a general template for every text node.  -->
<!-- Note that most verbatim-ish elements should not  -->
<!-- be applying templates, but instead will use      -->
<!-- "xsl:value-of".  Math is an exception, since     -->
<!-- we allow some elements in amongst the            -->
<!-- "pure text" LaTeX syntax.  We are first using    -->
<!-- it to adjust for clause-ending punctuation       -->
<!-- being absorbed elsewhere into math, so we place  -->
<!-- this near math handling.                         -->
<!--                                                  -->
<!-- Later Strategy                                   -->
<!--                                                  -->
<!-- 1.  "Display" objects, such as lists, display    -->
<!-- math, and displayed verbatim text, can have text -->
<!-- nodes (before and after), stripped of whitespace -->
<!-- (trailing and leading, respectively).            -->
<!--                                                  -->
<!-- 2.  Any newlines left after this can be removed, -->
<!-- with some whitespace consolidated                -->

<xsl:template match="text()">
    <!-- Scrub clause-ending punctuation immediately after math  -->
    <!-- It migrates and is absorbed in math templates elsewhere -->
    <!-- Side-effect: resulting leading whitespace is scrubbed   -->
    <!-- for displayed mathematics (only) as it is irrelevant    -->
    <xsl:variable name="first-char" select="substring(., 1, 1)" />
    <xsl:variable name="math-punctuation">
        <xsl:choose>
            <!-- drop punctuation after display math, if moving to math -->
            <xsl:when test="$b-include-display and contains($clause-ending-marks, $first-char) and preceding-sibling::node()[1][self::me|self::men|self::md|self::mdn]">
                <xsl:call-template name="strip-leading-whitespace">
                    <xsl:with-param name="text">
                        <xsl:call-template name="drop-clause-punctuation">
                            <xsl:with-param name="text" select="." />
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <!-- drop punctuation after inline math, if moving to math -->
            <xsl:when test="$b-include-inline and contains($clause-ending-marks, $first-char) and preceding-sibling::node()[1][self::m]">
                <xsl:call-template name="drop-clause-punctuation">
                    <xsl:with-param name="text" select="." />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- After math clause-ending rearrangements, we provide some    -->
    <!-- low-level text manipulations.  We do this via a conversion- -->
    <!-- specific hook, so we do not do more processing than is      -->
    <!-- necessary, presuming this template is executed frequently.  -->
    <!-- A math element that allows XML elements within will         -->
    <!-- be hit with "xsl:apply-templates" and arrive here,          -->
    <!-- so we need to guard against "text()" with parents:          -->
    <!-- "fillin", "xref", "var"   inside   "m", "me", "men", "mrow" -->
    <!-- The default behavior is a straight copy, with no changes.   -->
    <!-- NB: We defer WW-specific work for now.                      -->
    <xsl:variable name="text-processed">
        <xsl:choose>
            <xsl:when test="not(parent::m|parent::me|parent::men|parent::mrow)">
                <xsl:call-template name="text-processing">
                    <xsl:with-param name="text" select="$math-punctuation"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$math-punctuation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- TODO: strip leading whitespace above only under  -->
    <!-- 'strict' policy, and combine two when clauses.   -->
    <!-- Below, strip leading and trailing whitespace on  -->
    <!-- either side of displayed objects, math and lists -->
    <!-- (only?), in addition to first and last nodes     -->
    <xsl:choose>
        <!-- pass through if assuming strict adherence to whitespace policy -->
        <xsl:when test="$whitespace-style = 'strict'">
            <xsl:value-of select="$text-processed" />
        </xsl:when>
        <!-- We must "apply-templates" to math bits in order    -->
        <!-- to process "var", "fillin" and "xref", so we pass  -->
        <!-- through neighboring text nodes under any policy    -->
        <!-- and we handle whitespace specially afterward       -->
        <xsl:when test="parent::*[self::m|self::me|self::men|self::mrow]">
            <xsl:value-of select="$text-processed" />
        </xsl:when>
        <!-- If a pure-whitespace text node is bracketed on both sides by -->
        <!-- index or notation elements, then almost certainly the space  -->
        <!-- is for source-formatting clarity and not significant for the -->
        <!-- content.  In particular, in LaTeX output the macros left     -->
        <!-- behind prevent consolidation of this whitespace and can lead -->
        <!-- to significant runs of abnormal whitespace in the output.    -->
        <xsl:when test="normalize-space($text-processed) = '' and preceding-sibling::node()[1][self::idx|self::notation] and following-sibling::node()[1][self::idx|self::notation]"/>
        <!-- manipulate leading, trailing, intermediate whitespace under flexible policy -->
        <!-- if only text node inside parent, all three transformations may apply        -->
        <!-- Note: space after clause-punctuation will not be deleted here               -->
        <xsl:when test="$whitespace-style = 'flexible'">
            <xsl:variable name="original" select="$text-processed" />
            <xsl:variable name="front-cleaned">
                <xsl:choose>
                    <xsl:when test="not(preceding-sibling::node()[self::*|self::text()]) or preceding-sibling::node()[self::*|self::text()][1][self::me|self::men|self::md|self::mdn|self::cd|self::pre|self::ol/parent::p|self::ul/parent::p|self::dl/parent::p]">
                        <xsl:call-template name="strip-leading-whitespace">
                            <xsl:with-param name="text" select="$original" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$original" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="back-cleaned">
                <xsl:choose>
                    <xsl:when test="not(following-sibling::node()[self::*|self::text()])  or following-sibling::node()[self::*|self::text()][1][self::me|self::men|self::md|self::mdn|self::cd|self::pre|self::ol/parent::p|self::ul/parent::p|self::dl/parent::p]">
                        <xsl:call-template name="strip-trailing-whitespace">
                            <xsl:with-param name="text" select="$front-cleaned" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$front-cleaned" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="middle-cleaned">
                <xsl:call-template name="strip-newlines">
                    <xsl:with-param name="text" select="$back-cleaned" />
                </xsl:call-template>
            </xsl:variable>
            <!-- ACTUAL output -->
            <xsl:value-of select="$middle-cleaned" />
            <xsl:if test="$wsdebug and not($text-processed = $middle-cleaned)">
                <!-- DEBUGGING follows, maybe move outward later -->
                <xsl:message>
                    <xsl:text>****&#xa;</xsl:text>
                    <xsl:text>O:</xsl:text>
                    <xsl:value-of select="." />
                    <xsl:text>:O&#xa;</xsl:text>
                    <xsl:text>M:</xsl:text>
                    <xsl:value-of select="$text-processed" />
                    <xsl:text>:M&#xa;</xsl:text>
                    <xsl:text>F:</xsl:text>
                    <xsl:value-of select="$front-cleaned" />
                    <xsl:text>:F&#xa;</xsl:text>
                    <xsl:text>B:</xsl:text>
                    <xsl:value-of select="$back-cleaned" />
                    <xsl:text>:B&#xa;</xsl:text>
                    <xsl:text>M:</xsl:text>
                    <xsl:value-of select="$middle-cleaned" />
                    <xsl:text>:M&#xa;</xsl:text>
                    <xsl:text>****&#xa;</xsl:text>
                </xsl:message>
            </xsl:if>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Text-processing should be done carefully in a per-conversion -->
<!-- manner.  Absent anything special, we just duplicate.         -->
<xsl:template name="text-processing">
    <xsl:param name="text"/>
    <xsl:value-of select="$text"/>
</xsl:template>

<!-- Date and Time Functions -->
<!-- http://stackoverflow.com/questions/1437995/how-to-convert-2009-09-18-to-18th-sept-in-xslt -->
<!-- http://remysharp.com/2008/08/15/how-to-default-a-variable-in-xslt/ -->
<xsl:template match="today">
    <xsl:variable name="format">
        <xsl:choose>
            <xsl:when test="@format"><xsl:value-of select="@format" /></xsl:when>
            <xsl:otherwise>month-day-year</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="datetime" select="substring(date:date-time(),1,10)" />
    <xsl:choose>
        <xsl:when test="$format='month-day-year'">
            <xsl:value-of select="date:month-name($datetime)" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="date:day-in-month($datetime)" />
            <xsl:text>, </xsl:text>
            <xsl:value-of select="date:year($datetime)" />
        </xsl:when>
        <xsl:when test="$format='yyyy/mm/dd'">
            <xsl:value-of select="substring($datetime, 1, 4)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 6, 2)" />
            <xsl:text>/</xsl:text>
            <xsl:value-of select="substring($datetime, 9, 2)" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Could use a format to suppress/manipulate time zone -->
<xsl:template match="timeofday">
    <xsl:value-of select="substring(date:date-time(),12,8)" />
    <xsl:text> (</xsl:text>
    <xsl:value-of select="substring(date:date-time(),20)" />
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- ################## -->
<!-- Document Structure -->
<!-- ################## -->

<!-- Structural Nodes -->
<!-- Some elements of the XML tree are structural elements of the document tree  -->
<!-- This is our logical overlay on the (finer, larger, more expansive) XML tree -->
<!-- Example: <section> is structural, and ancestors are all structural          -->
<!-- Example: <title> is not structural, but does have a structural ancestor     -->
<!-- NB: These elements need only be specified here, and in leaf template (next) -->
<xsl:template match="&STRUCTURAL;" mode="is-structural">
    <xsl:value-of select="true()" />
</xsl:template>

<xsl:template match="*" mode="is-structural">
    <xsl:value-of select="false()" />
</xsl:template>

<!-- Structural Leaves -->
<!-- Some structural elements of the document tree     -->
<!-- are the leaves of that tree, meaning they do      -->
<!-- not contain any structural nodes themselves       -->
<!-- backmatter is always structured, else no purpose  -->
<!-- frontmatter is anomalous:  "titlepage" (and       -->
<!-- for an "article", "abstract") are not treated     -->
<!-- as divisions, they just get mined as part of the  -->
<!-- frontmatter itself.  So an article/frontmatter    -->
<!-- is always a leaf, and a book/frontmatter is not   -->
<!-- a leaf if it has a child other than a "titlepage" -->
<!-- Generally, we look for definitive markers         -->
<!-- NB: references, exercises, solutions not relevant -->
<xsl:template match="&STRUCTURAL;" mode="is-leaf">
    <xsl:choose>
        <xsl:when test="self::frontmatter">
            <xsl:choose>
                <xsl:when test="parent::article">
                    <xsl:value-of select="true()" />
                </xsl:when>
                <xsl:when test="parent::book">
                    <xsl:value-of select="not(*[not(self::titlepage)])" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:BUG:     asking if a "frontmatter" is a leaf, for a document that is not a "book" nor an "article"</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="self::backmatter">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:when test="part or chapter or section or subsection or subsubsection">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="true()" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This once just returned false,      -->
<!-- but should maybe not even be called -->
<xsl:template match="*" mode="is-leaf">
    <xsl:value-of select="false()" />
    <!-- <xsl:message>MBX:BUG:     asking if a non-structural division is a leaf</xsl:message> -->
</xsl:template>

<!-- There are two models for most of the divisions (part -->
<!-- through subsubsection, plus appendix).  One has      -->
<!-- subdivisions, and possibly multiple "exercises", or  -->
<!-- other specialized subdivisions.  (Namely             -->
<!-- "worksheet", "exercises", "solutions", and not       -->
<!-- "references", "glossary", nor "reading-questions".)  -->
<!-- The other has no subdivisions, and then at most one  -->
<!-- of each type of specialized subdivision, which       -->
<!-- inherit numbers from their parent division. This is  -->
<!-- the test, which is very similar to "is-leaf" above.  -->
<!--                                                      -->
<!-- A "part" must have chapters, so will always return   -->
<!-- 'true' and for a 'subsubsection' there are no more   -->
<!-- subdivisions to employ and so will return empty.     -->
<xsl:template match="book|article|part|chapter|appendix|section|subsection|subsubsection" mode="is-structured-division">
    <xsl:if test="part|chapter|section|subsection|subsubsection">
        <xsl:text>true</xsl:text>
    </xsl:if>
</xsl:template>

<!-- We also want to identify smaller pieces of a document,          -->
<!-- such as when they contain an index element or defined term,     -->
<!-- so we can reference back to them.  We call these "blocks" here, -->
<!-- which mostly corresponds to the use of the term in the DTD.     -->
<!-- The difference is that a paragraph is a "block" if and only if  -->
<!-- it is a direct descendant of a structural node or a directly    -->
<!-- descended introduction or conclusion .                          -->
<!-- Also, list items are considered blocks.                         -->
<!-- NB: we don't point to a sidebyside, so not included here        -->
<xsl:template match="md|mdn|ul|ol|dl|blockquote|pre|sage|&FIGURE-LIKE;|poem|program|image|tabular|paragraphs|commentary|&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|assemblage|exercise|li" mode="is-block">
    <xsl:value-of select="true()" />
</xsl:template>

<xsl:template match="p" mode="is-block">
    <xsl:choose>
        <xsl:when test="parent::introduction or parent::conclusion">
            <xsl:variable name="interloper" select="parent::*" />
            <xsl:apply-templates select="$interloper/parent::*" mode="is-structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="is-structural" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="is-block">
    <xsl:value-of select="false()" />
</xsl:template>


<!-- ####################### -->
<!-- Chunking Document Nodes -->
<!-- ####################### -->

<!--
When we break a document into pieces, known as "chunks,"
there is a configurable level (the "chunk-level") where
the document nodes at that level are always a chunk.
At a lesser level, document nodes are "intermediate" nodes
and so are output as summaries of their children.
However, an intermediate node may have no children
(is a "leaf") and hence is output as a chunk.

Said differently, chunks are natural leaves of the document
tree, or leaves (dead-ends) manufactured by an arbitrary
cutoff given by the chunk-level variable
-->

<!--
So we have three types of document nodes:
Intermediate: structural node, not a document leaf, smaller level than chunk-level
  Realization: some content (title, introduction, conclusion), links/includes to children
Leaf: structural node, at chunk-level or a leaf at smaller level than chunk-level
  Realization: a chunk will all content
Neither: A structural node that is simply a (visual) subdivision of a chunk
  Realization: usual presentation, but wtithin the enclosing chunk
-->

<!-- An intermediate node is at lesser level than chunk-level and is not a leaf -->
 <xsl:template match="*" mode="is-intermediate">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($leaf='false') and ($chunk-level > $current-level)" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-intermediate at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A chunk node is at the chunk-level, or a leaf at a lesser level -->
<xsl:template match="*" mode="is-chunk">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$structural='true'">
            <xsl:variable name="current-level">
                <xsl:apply-templates select="." mode="level" />
            </xsl:variable>
            <xsl:variable name="leaf">
                <xsl:apply-templates select="." mode="is-leaf" />
            </xsl:variable>
            <xsl:value-of select="($chunk-level = $current-level) or ( ($leaf='true') and ($chunk-level > $current-level) )" />
        </xsl:when>
        <xsl:when test="$structural='false'">
            <xsl:value-of select="$structural" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG: Structural determination (<xsl:value-of select="$structural" />) failed for is-chunk at <xsl:apply-templates select="." mode="long-name"/></xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #################################### -->
<!-- Abstract Chunking of Structural Nodes-->
<!-- #################################### -->

<!-- Implementations get structural nodes of two types          -->
<!--                                                            -->
<!--   1) "chunk"                                               -->
<!--       usually realizable as a single file by               -->
<!--       applying default templates                           -->
<!--                                                            -->
<!--   2) "intermediate":                                       -->
<!--       usually realizable as a single file with a title,    -->
<!--       introduction and conclusion surrounding a summary    -->
<!--       of the subdivisions it contains                      -->
<!--                                                            -->
<!-- So an implementation must implement two modal templates    -->
<!--                                                            -->
<!--   1) match="&STRUCTURAL;" mode="chunk"                     -->
<!--   2) match="&STRUCTURAL;" mode="intermediate"              -->
<!--                                                            -->
<!-- Similarities can be consolidated within the implementation -->
<!-- See  xsl/pretext-html.xsl  a typical example              -->

<xsl:template match="&STRUCTURAL;" mode="chunking">
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
     <xsl:choose>
        <xsl:when test="$chunk='true'">
            <!-- Very informative output for debugging purposes, comment/uncomment, but do not remove  -->
            <!-- <xsl:message>CHUNK: <xsl:apply-templates select="." mode="long-name" /></xsl:message> -->
            <xsl:apply-templates select="." mode="chunk" />
        </xsl:when>
        <xsl:otherwise>
            <!-- Very informative output for debugging purposes, comment/uncomment, but do not remove  -->
            <!-- <xsl:message>INTER: <xsl:apply-templates select="." mode="long-name" /></xsl:message> -->
            <xsl:apply-templates select="." mode="intermediate" />
            <xsl:apply-templates select="&STRUCTURAL;" mode="chunking" />
        </xsl:otherwise>
    </xsl:choose>
 </xsl:template>

<!-- docinfo, and anything else, is immune and dead-ends -->
<xsl:template match="*" mode="chunking" />

<!-- With an implementation of a file-wrapping routine,     -->
<!-- a typical use is to                                    -->
<!--                                                        -->
<!--   (a) apply a default template to the structural       -->
<!--       node for a complete (chunk'ed) node              -->
<!--                                                        -->
<!--   (b) apply a modal template to the structural         -->
<!--       node for a summary (intermediate) node           -->
<!--                                                        -->
<!-- The file-wrap routine should accept two parameters     -->
<!--                                                        -->
<!--   1) a "page-type" string to identify the type of page -->
<!--   2) the "content" to be wrapped                       -->

<!-- A complete page for a structural subdivision -->
<xsl:template match="&STRUCTURAL;" mode="chunk">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="page-type" select="'complete'" />
        <xsl:with-param name="content">
            <xsl:apply-templates select=".">
                <!-- the level of the object in the context on the page, -->
                <!-- here "2" since there is an "h1" in the masthead     -->
                <xsl:with-param name="heading-level" select="2"/>
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A summary page for a structural subdivision -->
<xsl:template match="&STRUCTURAL;" mode="intermediate">
    <xsl:apply-templates select="." mode="file-wrap">
        <xsl:with-param name="page-type" select="'summary'" />
        <xsl:with-param name="content">
            <xsl:apply-templates select="." mode="summary">
                <!-- the level of the object in the context on the page, -->
                <!-- here "2" since there is an "h1" in the masthead     -->
                <xsl:with-param name="heading-level" select="2"/>
            </xsl:apply-templates>
        </xsl:with-param>
    </xsl:apply-templates>
</xsl:template>

<!-- A default summary page can just ignore the structural      -->
<!-- divisions within though usually you might want to do       -->
<!-- something with them, so you would override this template   -->
<!-- with an implementation.  See xsl/pretext-sage-doctest.xsl -->
<!-- which uses all of these general routines here              -->
<xsl:template match="&STRUCTURAL;" mode="summary">
    <xsl:apply-templates select="*[not(&STRUCTURAL-FILTER;)]" />
</xsl:template>


<!-- Containing Filenames, URLs -->
<!-- Relative to the chunking in effect, every -->
<!-- XML element is born within some file.     -->
<!-- That filename will have a different       -->
<!-- suffix in different conversions.          -->
<!-- Parameter: $file-extension, set globally  -->
<xsl:template match="*" mode="containing-filename">
    <xsl:variable name="intermediate">
        <xsl:apply-templates select="." mode="is-intermediate" />
    </xsl:variable>
    <xsl:variable name="chunk">
        <xsl:apply-templates select="." mode="is-chunk" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$intermediate='true' or $chunk='true'">
            <xsl:apply-templates select="." mode="visible-id" />
            <xsl:value-of select="$file-extension" />
        </xsl:when>
        <!-- Halts since "mathbook" element will be chunk (or earlier) -->
        <xsl:otherwise>
            <xsl:apply-templates select=".." mode="containing-filename" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- ###### -->
<!-- Titles -->
<!-- ###### -->

<!-- Titles are like metadata, they are a useful property    -->
<!-- of many things and they migrate many different places.  -->
<!-- So principally, we kill them on sight.  But we provide  -->
<!-- modal templates as interfaces to titles and derivatives -->
<!-- of them for purposes where only a restricted subset of  -->
<!-- their content is allowed.                               -->
<!--                                                         -->
<!-- Also, many stock divisions have natural default titles, -->
<!-- so we want to accomodate that option, and do so via     -->
<!-- the localization routines.                              -->


<!-- With modal templates below, the default template does nothing   -->
<!-- We include the "creator" element of a theorem/axiom as metadata -->
<!-- NB: since these elements get killed on-sight, when we actually  -->
<!-- want to process them we need to use a "select" attribute        -->
<!-- similar to  title/*|title/text().                               -->
<xsl:template match="title" />
<xsl:template match="subtitle" />
<xsl:template match="shorttitle"/>
<xsl:template match="creator" />

<!-- Some items have default titles that make sense         -->
<!-- Typically these are one-off subdivisions (eg preface), -->
<!-- or repeated generic divisions (eg exercises)           -->
<xsl:template match="frontmatter|colophon|preface|foreword|acknowledgement|dedication|biography|references|glossary|exercises|worksheet|reading-questions|solutions|backmatter|index-part|index[index-list]|case" mode="has-default-title">
    <xsl:text>true</xsl:text>
</xsl:template>
<xsl:template match="*" mode="has-default-title">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- NB: these templates return a property of the title's parent -->

<!-- This has much of the logic of producing a title, but lacks any  -->
<!-- additional punctuation, so is useful for titles employed places  -->
<!-- other than immediately adjacent to the content they describe. -->
<xsl:template match="*" mode="title-xref">
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="title/line">
            <xsl:apply-templates select="title/line">
                <xsl:with-param name="separator" select="$title-separator"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- select="title" would just get it killed -->
        <xsl:when test="title">
            <xsl:apply-templates select="title/*|title/text()" />
        </xsl:when>
        <!-- A "table" and a "list" once had "caption", so provide this -->
        <!-- content for backward-compatibility, and just safely call   -->
        <!-- "title-full" on these objects                              -->
        <xsl:when test="(self::table or self::list) and caption">
            <xsl:apply-templates select="caption/*|caption/text()"/>
        </xsl:when>
        <xsl:when test="$default-exists='true'">
            <xsl:apply-templates select="." mode="type-name" />
        </xsl:when>
        <!-- otherwise empty -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="title-full">
    <!-- first, the punctuation-less version -->
    <xsl:apply-templates select="." mode="title-xref"/>
    <!-- Should we add punctuation?                       -->
    <!--   1. Should not have any already,                -->
    <!--   2. Or should be a default version,             -->
    <!--   3. Plus should be a situation where we want it -->

    <!-- with no title present, first variable is an empty string -->
    <xsl:variable name="has-punctuation">
        <xsl:apply-templates select="title" mode="has-punctuation"/>
    </xsl:variable>
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:variable name="wants-period">
        <xsl:apply-templates select="." mode="title-wants-punctuation"/>
    </xsl:variable>
    <xsl:if test="(($has-punctuation = 'false') or ($default-exists = 'true')) and ($wants-period = 'true')">
        <xsl:text>.</xsl:text>
    </xsl:if>
</xsl:template>

<!-- This template does elective sanitization of a title, which  -->
<!-- is distinct for universal adjustments (such as protecting   -->
<!-- LaTeX macros, or making any "xref" static.  So removing a   -->
<!-- footnote is such a sanitization (we allow it on a "real"    -->
<!-- title, but not when migrating other places).  This template -->
<!-- is not called often, usually the "title-short" template is  -->
<!-- the right template to call when a title is duplicated.      -->
<!-- We pass a space for the version structured with "line".     -->
<!-- TODO: ban fn in titles, then maybe this is obsolete -->
<!-- or maybe we should be careful about math            -->
<xsl:template match="*" mode="title-simple">
    <xsl:variable name="default-exists">
        <xsl:apply-templates select="." mode="has-default-title" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="title/line">
            <xsl:apply-templates select="title/line">
                <xsl:with-param name="separator" select="' '"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- select="title" would just get it killed -->
        <!-- avoid footnotes in simple version       -->
        <xsl:when test="title">
            <xsl:apply-templates select="title/*[not(self::fn)]|title/text()" />
        </xsl:when>
        <xsl:when test="$default-exists='true'">
            <xsl:apply-templates select="." mode="type-name" />
        </xsl:when>
        <!-- otherwise empty -->
        <xsl:otherwise />
    </xsl:choose>
</xsl:template>

<!-- Short titles are meant for places such as the Table of  -->
<!-- Contents and for LaTeX, the page headers and/or footers -->
<!-- It'd be silly to structure this with "line"             -->
<xsl:template match="*" mode="title-short">
    <xsl:choose>
        <!-- schema should control content, eg no footnotes -->
        <!-- optional, so check for author's suggestion     -->
        <xsl:when test="shorttitle">
            <xsl:apply-templates select="shorttitle/node()[not(self::fn)]"/>
        </xsl:when>
        <!-- else, existing title, cleaned up -->
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="title-simple"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- A version of the title with all abnormal characters stripped -->
<!-- and using underscores in place of spaces                     -->
<!-- http://stackoverflow.com/questions/1267934/                  -->
<!-- removing-non-alphanumeric-characters-from-string-in-xsl      -->
<xsl:template match="*" mode="title-filesafe">
    <!-- first, the simple title -->
    <xsl:variable name="raw-title">
        <xsl:apply-templates select="." mode="title-simple"/>
    </xsl:variable>
    <xsl:variable name="letter-only-title" select="translate($raw-title, translate($raw-title, concat(&SIMPLECHAR;,' '), ''), '')"/>
    <xsl:value-of select="translate($letter-only-title, ' ', '_')" />
</xsl:template>

<!-- This comes from writing out WW problems to filenames    -->
<!-- in some sort of reasonable numbering scheme             -->
<!-- It is not integrated into the above complexity-scheme   -->
<!-- (though does call the "title-filesafe" modal template)  -->
<!-- Consider integration if there is a refactoring of above -->
<xsl:template match="*" mode="numbered-title-filesafe">
    <!-- traditional "dotted" number -->
    <xsl:variable name="dotted-number">
        <xsl:apply-templates select="." mode="number" />
    </xsl:variable>
    <xsl:variable name="title-string">
        <xsl:apply-templates select="." mode="title-filesafe" />
    </xsl:variable>
    <!-- number output, with dot to dash conversion -->
    <xsl:value-of select="translate($dotted-number, '.', '_')" />
    <!-- separator, if needed -->
    <xsl:if test="not($dotted-number = '' or $title-string = '')">
        <xsl:text>-</xsl:text>
    </xsl:if>
    <xsl:value-of select="$title-string" />
</xsl:template>

<!-- We get subtitles the same way, but with no variations -->
<!-- Structured with "line" is a possibility               -->
<xsl:template match="*" mode="subtitle">
    <xsl:choose>
        <xsl:when test="subtitle/line">
            <xsl:apply-templates select="subtitle/line">
                <xsl:with-param name="separator" select="$title-separator"/>
            </xsl:apply-templates>
        </xsl:when>
        <!-- select="subtitle" would just get it killed -->
        <xsl:when test="subtitle">
            <xsl:apply-templates select="subtitle/*|subtitle/text()" />
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- We let styling provide punctuation for titles, principally       -->
<!-- a period at the end.  But this is awkward if there is already    -->
<!-- punctuation there.  This template returns the string 'true' if,  -->
<!-- and only if, such punctuation exists.  Else, it returns 'false'. -->
<!-- Consolidating interior whitespace should have no effect.         -->
<!-- Text generators (eg <today />) may fool this, but applying       -->
<!-- templates first will introduce LaTeX macros that will fool this  -->
<!-- To debug: add messages here, then call via this default template -->
<!-- TODO: maybe warn about "bad" ending-punctuation, like a colon? -->
<xsl:template match="title|subtitle" mode="has-punctuation">
    <xsl:variable name="title-ending-punctuation" select="'?!'" />
    <xsl:variable name="all-text" select="normalize-space(string(.))" />
    <xsl:variable name="last-char" select="substring($all-text, string-length($all-text))" />
    <!-- title should not be empty, but if so, the contains() alone is true -->
    <xsl:value-of select="$last-char and contains($title-ending-punctuation, $last-char)" />
</xsl:template>

<!-- Some titles should have periods supplied by PTX, mostly   -->
<!-- "smaller" objects like "example" and not "larger" objects -->
<!-- like "chapter".  We create a template to signal this, for -->
<!-- consistency across conversions, and so that it can be     -->
<!-- consciously overridden as part of styling work.  In       -->
<!-- pieces simply so it is more readable.                     -->
<!--                                                           -->
<!-- Blocks -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&ASIDE-LIKE;|exercise|commentary|assemblage" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<!-- Miscellaneous -->
<xsl:template match="paragraphs|proof|case|defined-term" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<!-- Titled: list items, tasks of exercise, PROJECT-LIKE, EXAMPLE-LIKE -->
<xsl:template match="ol/li|ul/li|task" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<!-- Introductions and Conclusions -->
<xsl:template match="article/introduction|chapter/introduction|section/introduction|subsection/introduction|appendix/introduction|exercises/introduction|solutions/introduction|worksheet/introduction|reading-questions/introduction|glossary/introduction|references/introduction|article/conclusion|chapter/conclusion|section/conclusion|subsection/conclusion|appendix/conclusion|exercises/conclusion|solutions/conclusion|worksheet/conclusion|reading-questions/conclusion|glossary/conclusion|references/conclusion" mode="title-wants-punctuation">
    <xsl:value-of select="true()"/>
</xsl:template>
<xsl:template match="*" mode="title-wants-punctuation">
    <xsl:value-of select="false()"/>
</xsl:template>

<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="creator-full">
    <!-- select="creator" would just get it killed -->
    <xsl:apply-templates select="creator/*|creator/text()" />
</xsl:template>

<!-- Structured titles -->

<!-- Each "line", except the last, gets a separator     -->
<!-- Almost always a space, but for LaTeX, at birth,    -->
<!-- a newline.  We make it obvious that this character -->
<!-- has not been overridden in a conversion            -->

<xsl:variable name="title-separator" select="'[TITLESEP]'"/>

<!-- Books:    overall title and subtitle, titles of parts, chapters and sections -->
<!-- Articles: overall title and subtitle, titles of sections                     -->
<xsl:template match="book/title/line|book/subtitle/line|book/part/title/line|book/part/chapter/title/line|book/chapter/title/line|book/part/chapter/section/title/line|book/chapter/section/title/line|article/title/line|article/subtitle/line|article/section/title/line">
    <xsl:param name="separator"/>

    <xsl:apply-templates/>
    <xsl:if test="following-sibling::line">
        <xsl:value-of select="$separator"/>
    </xsl:if>
</xsl:template>


<!-- ######## -->
<!-- Captions -->
<!-- ######## -->

<!-- Captions are similar to titles.  They should be -->
<!-- killed as metadata and requested when needed.   -->

<xsl:template match="caption"/>

<!-- A caption can have a footnote, thus HTML will create    -->
<!-- a knowl, and we need to distinguish between original    -->
<!-- and duplicate scenarios.  For other conversions, the    -->
<!-- "b-original" parameter should just be silently ignored. -->
<xsl:template match="figure|listing" mode="caption-full">
    <xsl:param name="b-original" select="true()"/>

    <xsl:if test="caption">
        <xsl:apply-templates select="caption/*|caption/text()">
            <xsl:with-param name="b-original" select="$b-original"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- ################ -->
<!-- Copies of Images -->
<!-- ################ -->

<!-- @copy deprecated  2017-12-21 -->
<xsl:template match="image[@copy]">
    <xsl:variable name="target" select="id(@copy)" />
    <xsl:choose>
        <xsl:when test="$target">
            <xsl:apply-templates select="$target" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: &lt;image&gt; failure due to unknown reference @copy="<xsl:value-of select="@copy"/>"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #################################### -->
<!-- Widths of Images, Audio, Videos, Etc -->
<!-- #################################### -->

<!-- Because we allow width settings as consequences of sidebyside     -->
<!-- layout parameters, we need to "reach up" and get these widths     -->
<!-- on occassion.  So we consider the PreTeXt markup/situation and    -->
<!-- produce a percentage as a string.  Consumers need to convert to   -->
<!-- a percentage, pixels, fractional linewidths - whatever is needed. -->

<!-- An image appears -->
<!--                                                                      -->
<!--   1.  in a figure (itself not in a sidebyside) where it              -->
<!--       can have a width specification on itself                       -->
<!--   2.  in a sidebyside directly, or a figure in a sidebyside.         -->
<!--       These widths come from the layout, and are converter dependent -->
<!--                                                                      -->
<!-- Entirely similar for jsxgraph, audio and video but we do             -->
<!-- not consult default *image* width in docinfo                         -->

<xsl:template match="image[not(ancestor::sidebyside)]|audio[not(ancestor::sidebyside)]|video[not(ancestor::sidebyside)]|jsxgraph[not(ancestor::sidebyside)]|interactive[not(ancestor::sidebyside)]|slate[not(ancestor::sidebyside)]" mode="get-width-percentage">
    <!-- find it first -->
    <xsl:variable name="raw-width">
        <xsl:choose>
            <!-- right on the element! -->
            <xsl:when test="@width">
                <xsl:value-of select="@width" />
            </xsl:when>
            <!-- not on an image, but doc-wide default exists -->
            <xsl:when test="self::image and $docinfo/defaults/image-width">
                <xsl:value-of select="$docinfo/defaults/image-width" />
            </xsl:when>
            <!-- naked slate, look to enclosing interactive -->
            <xsl:when test="self::slate">
                <xsl:apply-templates select="parent::interactive" mode="get-width-percentage" />
            </xsl:when>
            <!-- what to do? Author will figure it out if too extreme -->
            <xsl:otherwise>
                <xsl:text>100%</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- now sanitize it -->
    <xsl:variable name="normalized-width" select="normalize-space($raw-width)" />
    <xsl:choose>
        <xsl:when test="not(substring($normalized-width, string-length($normalized-width)) = '%')">
            <xsl:message>MBX:ERROR:   a "width" attribute should be given as a percentage (such as "40%", not as "<xsl:value-of select="$normalized-width" />, using 100% instead"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <!-- replace by 100% -->
            <xsl:text>100%</xsl:text>
        </xsl:when>
        <!-- test for stray interior spaces here? -->
        <xsl:otherwise>
            <xsl:value-of select="$normalized-width" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Any way that an image gets placed in a sidebyside -->
<!-- panel it should have a relative size filling that -->
<!-- panel, so this is easy, just 100% all the time    -->
<!-- Exception: asymptote WebGL needs actual pixels    -->
<xsl:template match="image[ancestor::sidebyside]" mode="get-width-percentage">
    <xsl:text>100%</xsl:text>
</xsl:template>

<!-- The exception is an image inside a sidebyside in a webwork  -->
<!-- where the parent sidebyside should only have a single percentage in its @widths -->
<!-- N.B. This should be reworked/removed when there is a one-item sbs equivalent -->
<xsl:template match="webwork//image[parent::sidebyside/@widths]" mode="get-width-percentage">
    <xsl:value-of select="parent::sidebyside/@widths" />
</xsl:template>

<!-- We need to get the right entry from the sidebyside layout.         -->
<!-- This is complicated slightly by two possibilities for the element  -->
<!-- of the sidebyside, a naked object, or a figure holding the object  -->
<!-- Widths from sidebyside layouts have been error-checked as input    -->

<!-- occurs in a figure, not contained in a sidebyside -->
<xsl:template match="audio[ancestor::sidebyside]|video[ancestor::sidebyside]|jsxgraph[ancestor::sidebyside]|interactive[ancestor::sidebyside]|slate[ancestor::sidebyside]|image[asymptote and ancestor::sidebyside]" mode="get-width-percentage">
    <!-- in a side-by-side, get layout, locate in layout -->
    <!-- and get width.  The layout-parameters template  -->
    <!-- will analyze an enclosing sbsgroup              -->
    <xsl:variable name="enclosing-sbs" select="ancestor::sidebyside" />
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="$enclosing-sbs" mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:choose>
        <xsl:when test="parent::figure or parent::stack">
            <xsl:variable name="panel-number" select="count(parent::*/preceding-sibling::*) + 1" />
            <xsl:value-of select="$layout/width[$panel-number]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
            <xsl:value-of select="$layout/width[$panel-number]" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Assumes element may have an @aspect attribute   -->
<!-- Caller can provide a default for its context    -->
<!-- Input:  "width:height", or decimal width/height -->
<!-- Return: real number as fraction width/height    -->
<!-- Totally blank means nothing could be determined -->
<xsl:template match="slate|interactive|jsxgraph|audio|video|image[asymptote]" mode="get-aspect-ratio">
    <xsl:param name="default-aspect" select="''" />

    <!-- look to element first, then to supplied default          -->
    <!-- this could be empty (default default), then return empty -->
    <xsl:variable name="the-aspect">
        <xsl:choose>
            <!-- The aspect ratio is a property of an       -->
            <!-- interactive Asymptote WebGL version, only. -->
            <xsl:when test="self::image and asymptote/@aspect">
                <xsl:value-of select="asymptote/@aspect" />
            </xsl:when>
            <xsl:when test="not(self::image) and @aspect">
                <xsl:value-of select="@aspect" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$default-aspect" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <!-- nothing provided by element or caller -->
        <xsl:when test="$the-aspect = ''" />
        <!-- test if a ratio is given, and assume parts are good -->
        <xsl:when test="contains($the-aspect, ':')">
            <xsl:variable name="width" select="substring-before($the-aspect, ':')" />
            <xsl:variable name="height" select="substring-after($the-aspect, ':')" />
            <xsl:value-of select="$width div $height" />
        </xsl:when>
        <!-- assume a number and see if it is bad, return nothing -->
        <!-- NaN does not equal *anything*, so tests if a number  -->
        <!-- http://stackoverflow.com/questions/6895870           -->
        <xsl:when test="not(number($the-aspect) = number($the-aspect)) or ($the-aspect &lt; 0)">
            <xsl:message>MBX:WARNING: the @aspect attribute should be a ratio, like 4:3, or a positive number, not "<xsl:value-of select="$the-aspect" />"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <!-- survives as a number -->
        <xsl:otherwise>
            <xsl:value-of select="$the-aspect" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This is cribbed from the CSS "max-width"-->
<!-- Design width, measured in pixels        -->
<!-- NB: the exact same value, for similar,  -->
<!-- but not identical, reasons is used in   -->
<!-- the formation of WeBWorK problems       -->
<xsl:variable name="design-width-pixels" select="'600'" />


<!-- Pixels are an HTML thing, but we may need these numbers -->
<!-- elsewhere, and these are are pure text templates        -->
<xsl:template match="slate|audio|video|interactive|image[asymptote]" mode="get-width-pixels">
    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction" select="substring-before($width-percent,'%') div 100"/>
    <xsl:value-of select="round($design-width-pixels * $width-fraction)" />
</xsl:template>

<!-- Square by default, when asked.  Can override -->
<xsl:template match="slate|audio|video|interactive|image[asymptote]" mode="get-height-pixels">
    <xsl:param name="default-aspect" select="'1:1'" />

    <xsl:variable name="width-percent">
        <xsl:apply-templates select="." mode="get-width-percentage" />
    </xsl:variable>
    <xsl:variable name="width-fraction" select="substring-before($width-percent,'%') div 100"/>
    <xsl:variable name="aspect-ratio">
        <xsl:apply-templates select="." mode="get-aspect-ratio">
            <xsl:with-param name="default-aspect" select="$default-aspect" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:value-of select="round($design-width-pixels * $width-fraction div $aspect-ratio)" />
</xsl:template>

<!-- The HTML conversion generates "standalone" pages for videos   -->
<!-- and other interactives.  Then the LaTeX conversion will make  -->
<!-- links to these pages (eg, via QR codes).  And we might use    -->
<!-- these pages as the basis for scraping preview images.  So we  -->
<!-- place a template here to achieve consistency across uses.     -->
<xsl:template match="audio|video|interactive" mode="standalone-filename">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>.html</xsl:text>
</xsl:template>
<xsl:template match="*" mode="standalone-filename">
    <xsl:apply-templates select="." mode="visible-id" />
    <xsl:text>-ERROR-no-standalone-filename.html</xsl:text>
</xsl:template>


<!-- ################ -->
<!-- Names of Objects -->
<!-- ################ -->

<!-- Ultimately translations are all contained in the files of  -->
<!-- the xsl/localizations directory, which provides            -->
<!-- upper-case, singular versions.  In this way, we only ever  -->
<!-- hardcode a string (like "Chapter") once                    -->
<!-- First template is modal, and calls subsequent named        -->
<!-- template where translation with keys happens               -->
<!-- This template allows a node to report its name             -->
<xsl:template match="*" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="local-name(.)" />
    </xsl:call-template>
</xsl:template>

<!-- We override a few elements using their XSLT locations      -->
<!-- There are corresponing strings in the localizations files, -->
<!-- and the "en-US" file will be the best documented           -->

<!-- A single objective or outcome is authored as a list item -->
<xsl:template match="objectives/ol/li|objectives/ul/li|objectives/dl/li" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'objective'" />
    </xsl:call-template>
</xsl:template>
<xsl:template match="outcomes/ol/li|outcomes/ul/li|outcomes/dl/li" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'outcome'" />
    </xsl:call-template>
</xsl:template>

<!-- There are lots of exercises, but differentiated by their parents,  -->
<!-- so we use identifiers that remind us of their location in the tree -->

<!-- First, a "divisional" "exercise" in an "exercises",      -->
<!-- with perhaps intervening groups, like an "exercisegroup" -->
<xsl:template match="exercises//exercise" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'divisionalexercise'" />
    </xsl:call-template>
</xsl:template>

<!-- Second, an "exercise" placed within a "worksheet"-->
<xsl:template match="worksheet//exercise" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'worksheetexercise'" />
    </xsl:call-template>
</xsl:template>

<!-- Third, an "exercise" placed within a "reading-questions"-->
<xsl:template match="reading-questions//exercise" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'readingquestion'" />
    </xsl:call-template>
</xsl:template>

<!-- Finally, an inline exercise has a division (several possible)        -->
<!-- as a parent. We just drop in here last if other matches do not       -->
<!-- succeed, but could improve with a filter or list of specific matches -->
<!-- This matches the LaTeX environment of the same name, so              -->
<!-- template to create an "inlineexercise" environment runs smoothly     -->
<xsl:template match="exercise" mode="type-name">
    <xsl:call-template name="type-name">
        <xsl:with-param name="string-id" select="'inlineexercise'" />
    </xsl:call-template>
</xsl:template>

<!-- "solutions" divisions are "Solutions 5.6" in the  -->
<!-- main matter, but "Appendix D" in the back matter -->
<xsl:template match="solutions" mode="type-name">
    <xsl:choose>
        <xsl:when test="parent::backmatter">
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'appendix'" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="type-name">
                <xsl:with-param name="string-id" select="'solutions'" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This template translates an string to an upper-case language-equivalent -->
<!-- Sometimes we must call this directly, but usually better to apply the   -->
<!-- template mode="type-name" to the node, which then calls this routine    -->
<!-- NB: this key concatenation might appear more complicated than           -->
<!--     necessary but may make supporting multiple languages easier?        -->
<!-- TODO: perhaps allow mixed languages, so don't set document language globally,  -->
<!-- but search up through parents until you find a lang tag                        -->
<xsl:key name="localization-key" match="localization" use="concat(../@name, @string-id)"/>

<xsl:template name="type-name">
    <xsl:param name="string-id" />
    <xsl:variable name="translation">
        <xsl:choose>
            <!-- First, look in docinfo for document-specific rename with correct language -->
            <xsl:when test="$docinfo/rename[@element=$string-id and @xml:lang=$document-language]">
                <xsl:apply-templates select="$docinfo/rename[@element=$string-id and @xml:lang=$document-language]"/>
            </xsl:when>
            <!-- Second, look in docinfo for document-specific rename with correct language, -->
            <!-- but with @lang attribute which was deprecated on 2019-02-23                 -->
            <xsl:when test="$docinfo/rename[@element=$string-id and @lang=$document-language]">
                <xsl:apply-templates select="$docinfo/rename[@element=$string-id and @lang=$document-language]"/>
            </xsl:when>
            <!-- Third, look in docinfo for document-specific rename, but now explicitly language-agnostic -->
            <xsl:when test="$docinfo/rename[@element=$string-id and not(@lang) and not(@xml:lang)]">
                <xsl:apply-templates select="$docinfo/rename[@element=$string-id and not(@lang) and not(@xml:lang)]"/>
            </xsl:when>
            <!-- Finally, default to a lookup from the localization file's nodes -->
            <xsl:otherwise>
                <xsl:for-each select="$translation-nodes">
                    <xsl:value-of select="key('localization-key', concat($document-language,$string-id) )"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$translation!=''">
            <xsl:value-of select="$translation" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$string-id" />
            <xsl:text>]</xsl:text>
            <xsl:message>MBX:WARNING: could not translate string with id "<xsl:value-of select="$string-id" />" into language for code "<xsl:value-of select="$document-language" />"</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<!-- Comments are Unicode names, from fileformat.info -->
<!-- @latex takes priority for LaTeX output when the  -->
<!-- Font Awesome name has changed, but the LaTeX     -->
<!-- package is lagging.  This needs to be in the     -->
<!-- Font Awesome style, with dashes and no CamelCase -->
<xsl:variable name="icon-rtf">
    <!-- see Unicode Character 'LEFTWARDS HEAVY ARROW' (U+1F844) -->
    <!-- for bulkier arrows (in "Supplemental Arrows-C Block")   -->
    <iconinfo name="arrow-left"
              font-awesome="arrow-left"
              unicode="&#x2190;"/> <!-- LEFTWARDS ARROW -->
    <iconinfo name="arrow-up"
              font-awesome="arrow-up"
              unicode="&#x2191;"/> <!-- UPWARDS ARROW -->
    <iconinfo name="arrow-right"
              font-awesome="arrow-right"
              unicode="&#x2192;"/> <!-- RIGHTWARDS ARROW -->
    <iconinfo name="arrow-down"
              font-awesome="arrow-down"
              unicode="&#x2193;"/> <!-- DOWNWARDS ARROW -->
    <iconinfo name="file-save"
              font-awesome="save"
              unicode="&#x1f4be;"/> <!-- FLOPPY DISK -->
    <iconinfo name="gear"
              font-awesome="cog"
              unicode="&#x2699;" /> <!-- GEAR -->
    <iconinfo name="menu"
              latex="favicon"
              font-awesome="bars"
              unicode="&#x2630;" /> <!-- TRIGRAM FOR HEAVEN -->
    <iconinfo name="wrench"
              font-awesome="wrench"
              unicode="&#x1f527;"/> <!-- WRENCH -->
    <iconinfo name="power"
              font-awesome="power-off"
              unicode="&#x23FB;"/> <!-- POWER SYMBOL -->
    <iconinfo name="media-play"
              font-awesome="play"
              unicode="&#x25B6;"/> <!--BLACK RIGHT-POINTING TRIANGLE-->
    <iconinfo name="media-pause"
              font-awesome="pause"
              unicode="&#x23F8;"/> <!-- DOUBLE VERTICAL BAR -->
    <iconinfo name="media-stop"
              font-awesome="stop"
              unicode="&#x23F9;"/> <!-- BLACK SQUARE FOR STOP-->
    <iconinfo name="media-fast-forward"
              font-awesome="forward"
              unicode="&#x23E9;"/> <!-- BLACK RIGHT-POINTING DOUBLE TRIANGLE -->
    <iconinfo name="media-rewind"
              font-awesome="backward"
              unicode="&#x23EA;"/> <!-- BLACK LEFT-POINTING DOUBLE TRIANGLE -->
    <iconinfo name="media-skip-to-end"
              font-awesome="fast-forward"
              unicode="&#x23ED;"/> <!-- BLACK RIGHT-POINTING DOUBLE TRIANGLE WITH VERTICAL BAR -->
    <iconinfo name="media-skip-to-start"
              font-awesome="fast-backward"
              unicode="&#x23EE;"/> <!-- BLACK LEFT-POINTING DOUBLE TRIANGLE WITH VERTICAL BAR -->
</xsl:variable>

<!-- If read from a file via "document()" then   -->
<!-- the exsl:node-set() call would seem to be   -->
<!-- unnecessary.  When list above gets too big, -->
<!-- migrate to a new file after consulting      -->
<!-- localization scheme                         -->
<xsl:variable name="icon-table" select="exsl:node-set($icon-rtf)"/>

<xsl:key name="icon-key" match="iconinfo" use="@name"/>

<!-- ##### -->
<!-- Icons -->
<!-- ##### -->

<xsl:template match="icon">
    <!-- the name attribute of the "icon" in text as a string -->
    <xsl:variable name="icon-name" select="string(@name)"/>

    <!-- for-each is just one node, but sets context for key() -->
    <xsl:for-each select="$icon-table">
        <xsl:value-of select="key('icon-key', $icon-name)/@unicode" />
    </xsl:for-each>
</xsl:template>

<!-- ############# -->
<!-- Keyboard Keys -->
<!-- ############# -->

<!-- Comments are Unicode names, from fileformat.info             -->
<!-- @latex values are macros in the menukeys package specifying  -->
<!-- keyboard keys that are typically labeled with graphics,      -->
<!-- or "textcomp Text-mode Math Symbols" from "The Comprehensive -->
<!-- LaTeX Symbol List", or constructions combining them          -->
<xsl:variable name="kbdkey-rtf">
    <kbdkeyinfo name="left"
                latex="\arrowkeyleft"
                unicode="&#x2190;"/> <!-- LEFTWARDS ARROW -->
    <kbdkeyinfo name="up"
                latex="\arrowkeyup"
                unicode="&#x2191;"/> <!-- UPWARDS ARROW -->
    <kbdkeyinfo name="right"
                latex="\arrowkeyright"
                unicode="&#x2192;"/> <!-- RIGHTWARDS ARROW -->
    <kbdkeyinfo name="down"
                latex="\arrowkeydown"
                unicode="&#x2193;"/> <!-- DOWNWARDS ARROW -->
    <kbdkeyinfo name="enter"
                latex="\return"
                unicode="&#x2BA0;"/> <!-- DOWNWARDS TRIANGLE-HEADED ARROW WITH LONG TIP LEFTWARDS -->
    <kbdkeyinfo name="shift"
                latex="\shift"
                unicode="&#x21E7;"/> <!-- UPWARDS WHITE ARROW -->
    <kbdkeyinfo name="ampersand"
                latex="\&amp;"
                unicode="&#x0026;"/> <!-- AMPERSAND -->
    <kbdkeyinfo name="less"
                latex='\textless'
                unicode="&#x003C;"/> <!-- LESS-THAN SIGN-->
    <kbdkeyinfo name="greater"
                latex='\textgreater'
                unicode="&#x003E;"/> <!-- GREATER-THAN SIGN-->
    <kbdkeyinfo name="dollar"
                latex='\$'
                unicode="&#x0024;"/> <!-- DOLLAR SIGN -->
    <kbdkeyinfo name="percent"
                latex='\%'
                unicode="&#x0025;"/> <!-- PERCENT SIGN -->
    <!-- pair of braces is not confused as AVT notation -->
    <kbdkeyinfo name="openbrace"
                latex='\textbraceleft'
                unicode="{{"/> <!-- LEFT CURLY BRACKET -->
    <kbdkeyinfo name="closebrace"
                latex='\textbraceright'
                unicode="}}"/> <!-- RIGHT CURLY BRACKET -->
    <kbdkeyinfo name="hash"
                latex='\#'
                unicode="&#x0023;"/> <!-- OCTOTHORPE -->
    <kbdkeyinfo name="backslash"
                latex='\textbackslash'
                unicode="&#x005C;"/> <!-- BACKSLASH -->
    <kbdkeyinfo name="tilde"
                latex='\textasciitilde'
                unicode="&#x007E;"/> <!-- TILDE -->
    <kbdkeyinfo name="circumflex"
                latex='\textasciicircum'
                unicode="&#x005E;"/> <!-- CIRCUMFLEX ACCENT -->
    <kbdkeyinfo name="underscore"
                latex='\textunderscore'
                unicode="&#x005F;"/> <!-- LOW LINE -->
    <kbdkeyinfo name="plus"
                latex='+'
                unicode="&#x002B;"/> <!-- PLUS SIGN -->
    <!-- MINUS SIGN is U+2212, but not in all fonts? -->
    <kbdkeyinfo name="minus"
                latex='\textminus'
                unicode="&#x002D;"/> <!-- HYPHEN-MINUS -->
    <kbdkeyinfo name="times"
                latex='\texttimes'
                unicode="&#x00D7;"/> <!-- MULTIPLICATION SIGN -->
    <kbdkeyinfo name="solidus"
                latex='\textfractionsolidus'
                unicode="&#x002F;"/> <!-- SOLIDUS -->
    <kbdkeyinfo name="obelus"
                latex='\textdiv'
                unicode="&#x00F7;"/> <!-- DIVISION SIGN -->
    <kbdkeyinfo name="squared"
                latex='x\textasciicircum{}2'
                unicode="x&#x005E;2"/> <!--  -->
    <kbdkeyinfo name="inverse"
                latex='x\textasciicircum{-1}'
                unicode="x&#x005E;-1"/> <!--  -->
    <kbdkeyinfo name="left-paren"
                latex='('
                unicode="&#x0028;"/> <!-- LEFT PARENTHESIS -->
    <kbdkeyinfo name="right-paren"
                latex=')'
                unicode="&#x0029;"/> <!-- RIGHT PARENTHESIS -->
</xsl:variable>

<!-- If read from a file via "document()" then   -->
<!-- the exsl:node-set() call would seem to be   -->
<!-- unnecessary.  When list above gets too big, -->
<!-- migrate to a new file after consulting      -->
<!-- localization scheme                         -->
<xsl:variable name="kbdkey-table" select="exsl:node-set($kbdkey-rtf)"/>

<xsl:key name="kbdkey-key" match="kbdkeyinfo" use="@name"/>

<!-- ########### -->
<!-- Identifiers -->
<!-- ########### -->

<!--                    -->
<!-- Visible Identifier -->
<!--                    -->

<!-- These strings are used for items an author must manage              -->
<!-- (image files) or that a reader will interact with (shared URLs)     -->
<!-- Fast version (as of 2019-05) prefers                                -->
<!--   1.  @xml:id - authored (with meaning), 100% author-controlled     -->
<!--   2.  @permid - highly stable, controlled via edition management    -->
<!--   3.  auto    - fast, unique per build, but unstable between builds -->
<!-- Since items like filenames and URLs are sometimes shared across     -->
<!-- conversions (or extractions) this template is in -common            -->
<xsl:template match="*" mode="visible-id">
    <xsl:choose>
        <!-- 2019-05: more efficient replacement -->
        <!-- version of previous internal-id     -->
        <xsl:when test="$b-fast-ids">
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id" />
                </xsl:when>
                <xsl:when test="@permid">
                    <xsl:value-of select="local-name(.)" />
                    <xsl:text>-</xsl:text>
                    <xsl:value-of select="@perm-id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local-name(.)" />
                    <xsl:text>-</xsl:text>
                    <!-- xsltproc produces non-numeric prefix "idm" -->
                    <xsl:value-of select="substring(generate-id(.), 4)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- 2019-05: following matches the slow       -->
        <!-- internal-id previously in use exclusively -->
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local-name(.)" />
                    <xsl:text>-</xsl:text>
                    <xsl:number from="book|article|letter|memo" level="any" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!--            -->
<!-- Long Names -->
<!--            -->

<!-- Simple text representations of structural elements        -->
<!-- Type, number (empty?), optional title typically           -->
<!-- Ignore footnotes in these constructions                   -->
<!-- Used for author's report, LaTeX typeout during processing -->
<xsl:template match="*" mode="long-name">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="." mode="title-simple"/>
</xsl:template>


<!-- ######### -->
<!-- Numbering -->
<!-- ######### -->

<!-- We mimic default LaTeX behavior as much as possible    -->
<!--                                                        -->
<!-- There are six numbering schemes in place:              -->
<!-- 1) divisions: sections, subsections, etc.              -->
<!-- 2) environments: theorems, examples, exercises, figures -->
<!-- 3) equations: display mathematics                      -->
<!-- 4) exercises: as part of a section of exercises        -->
<!-- 5) bibliographic items: in multiple sections           -->
<!-- 6) footnotes:                                          -->

<!-- Every such item has two numbers                   -->
<!--                                                   -->
<!-- a) "structural": for example, X.Y.Z for an item   -->
<!--     in Chapter X, Section Y, Subsection Z         -->
<!-- b) "serial": for example N, where the item is     -->
<!--     number N of its scheme, within some division  -->
<!--                                                   -->
<!-- We form a "full number" by concatenating these,   -->
<!-- so "Claim X.Y.Z.N" would be the N-th instance of  -->
<!-- a scheme 2 item with division X.Y.Z. An empty     -->
<!-- serial number is indicative of not being numbered -->
<!--                                                   -->
<!-- Parameters of the form "numbering.<scheme>.level" -->
<!-- control the number of components in these numbers -->

<!-- ############## -->
<!-- Serial Numbers -->
<!-- ############## -->

<!-- These count the occurrence of the item, within it's  -->
<!-- scheme and within a natural, or configured, subtree -->

<!-- Serial Numbers: Divisions -->
<!-- To respect the maximum level for numbering, we          -->
<!-- return an empty serial number at an excessive level,    -->
<!-- otherwise we call for a serial number relative to peers -->
<!-- An unstructured division has solo specialized divisions -->
<!-- which inherit numbers from their parents.  This too is  -->
<!-- handled in the "division-serial-number" template.       -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|exercises|solutions|reading-questions|references[not(parent::backmatter)]|glossary[not(parent::backmatter)]|worksheet" mode="serial-number">
    <xsl:variable name="relative-level">
        <xsl:apply-templates select="." mode="level" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$relative-level > $numbering-maxlevel" />
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="division-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- Backmatter references and glossary are unique and un-numbered -->
<xsl:template match="backmatter/references" mode="serial-number" />
<xsl:template match="backmatter/glossary" mode="serial-number" />

<!-- Divisions -->
<xsl:template match="part" mode="division-serial-number">
    <xsl:number format="I" />
</xsl:template>
<xsl:template match="chapter" mode="division-serial-number">
    <!-- chapters, in parts or not -->
    <xsl:choose>
        <xsl:when test="($parts = 'absent') or ($parts = 'decorative')">
            <xsl:variable name="true-count">
                <xsl:number from="book" level="any" count="chapter" format="1" />
            </xsl:variable>
            <xsl:choose>
                <!-- This code is correct, interface is temporary and will be redone with no notice -->
                <xsl:when test="$debug.chapter.start = ''">
                    <xsl:value-of select="$true-count" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$true-count + $debug.chapter.start - 1" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- author-specified chapter strat number does  -->
        <!-- not really make sense for structural parts? -->
        <xsl:when test="$parts = 'structural'">
            <xsl:number from="part" count="chapter" format="1" />
        </xsl:when>
    </xsl:choose>
</xsl:template>
<xsl:template match="appendix" mode="division-serial-number">
    <xsl:number from="backmatter" level="any" count="appendix|solutions" format="A"/>
</xsl:template>
<xsl:template match="backmatter/solutions" mode="division-serial-number">
    <xsl:number from="backmatter" level="any" count="appendix|solutions" format="A"/>
</xsl:template>
<!-- NB: following do not assume an ordering on the subdivisions,     -->
<!-- since this has not been solidified in the schema. At that point, -->
<!-- we might enforce some assumptions here, and elsewhere, by only   -->
<!-- including predecessors in the @count attribute.                  -->
<xsl:template match="section" mode="division-serial-number">
    <xsl:number count="section|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
</xsl:template>
<xsl:template match="subsection" mode="division-serial-number">
    <xsl:number count="subsection|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
</xsl:template>
<xsl:template match="subsubsection" mode="division-serial-number">
    <xsl:number count="subsubsection|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
</xsl:template>
<!-- Specialized Divisions -->
<!-- "exercises", "solutions", references, "worksheet" -->
<!-- Count preceding peers in structured case,         -->
<!-- or copy parent in unstructured case               -->
<!-- NB: backmatter/references and backmatter/glossary -->
<!-- should never come through here                    -->
<xsl:template match="exercises|reading-questions|solutions[not(parent::backmatter)]|references|glossary|worksheet" mode="division-serial-number">
    <!-- Inspect parent (part through subsubsection)  -->
    <!-- to determine one of two models of a division -->
    <!-- NB: return values are 'true" and empty       -->
    <xsl:variable name="is-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:variable name="b-is-structured" select="$is-structured = 'true'"/>
    <xsl:choose>
        <xsl:when test="$b-is-structured">
            <!-- NB: only one type of division will be a peer -->
            <!-- NB: not assuming an order on the divisions   -->
            <xsl:number count="chapter|section|subsection|subsubsection|exercises|reading-questions|solutions|references|glossary|worksheet" format="1" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="serial-number"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Theorems, Examples, Inline Exercise, Figures, Etc. -->
<!-- We determine the appropriate subtree to count within     -->
<!-- given the document root and the configured depth         -->
<!-- Note: the "from" attribute can only take a match pattern -->
<!-- See: the footnote template below for a simpler example   -->

<!-- First, if we are at the maximum numbering level,                            -->
<!-- or less, for a particular scheme then we always base the                    -->
<!-- subtree at the most immediate enclosing structural element                  -->
<!-- If we are at a greater level than the maximum numbering level,              -->
<!-- then we base the subtree at the enclosing structural                        -->
<!-- element that is at the maximum level                                        -->
<!-- This template returns the absolute level necessary based on                 -->
<!-- the particular scheme as a parameter: theorems, equations and footnotes.    -->
<!-- Divisional exercises and bibliographic items (in references) will always     -->
<!-- get their serial numbers from within their immediately enclosing structure. -->
<xsl:template match="*" mode="absolute-subtree-level">
    <xsl:param name="numbering-items" />
    <!-- determine enclosing level of numbered item -->

    <!-- determine if the object being numbered is inside  -->
    <!-- a decorative "exercises" or "worksheet" -->
    <xsl:variable name="inside-decorative">
        <xsl:if test="ancestor::*[self::exercises or self::reading-questions or self::worksheet]">
            <xsl:variable name="is-structured">
                <xsl:apply-templates select="ancestor::*[self::exercises or self::worksheet or self::reading-questions]/parent::*" mode="is-structured-division"/>
            </xsl:variable>
            <xsl:if test="not($is-structured ='true')">
                <xsl:text>true</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <xsl:variable name="enclosing-level">
        <xsl:apply-templates select="." mode="enclosing-level" />
    </xsl:variable>
    <!-- we move up a level if the structural element is decorative -->
    <xsl:variable name="raw-element-level">
        <xsl:choose>
            <xsl:when test="$inside-decorative = 'true'">
                <xsl:value-of select="$enclosing-level - 1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$enclosing-level"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- if we are deep into the tree, beyond resetting counters,           -->
    <!-- then count from a subtree at the numbering level,                  -->
    <!-- else remain within enclosing level, as structure number will reset -->
    <xsl:variable name="raw-subtree-level">
        <xsl:choose>
            <xsl:when test="$raw-element-level > $numbering-items">
                <xsl:value-of select="$numbering-items" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$raw-element-level" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$raw-subtree-level + $root-level" />
</xsl:template>

<!-- "Blocks" can be counted "all together," or some types may be "split out." -->
<!--                                                                           -->
<!-- Definitions, theorems, axioms, remarks, computations,                     -->
<!-- and examples always go together.                                          -->
<!-- Projects, figures, and inline exercises may be split out individually.    -->
<!--                                                                           -->
<!-- For each of these items, we count the predecessors within each of the     -->
<!-- four subgroups.  So every item has four "atomic" numbers.  The "block"    -->
<!-- count may, or may not, contain the three other counts as determined by    -->
<!-- options selected through the "docinfo/numbering" configuration.           -->


<!-- Serial Numbers: Fundamental Blocks (Theorems, Etc.) -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" mode="serial-number">
    <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
</xsl:template>

<!-- Serial Numbers: Projects -->
<xsl:template match="&PROJECT-LIKE;" mode="serial-number">
    <xsl:choose>
        <xsl:when test="$b-number-project-distinct">
            <xsl:apply-templates select="." mode="atomic-project-serial-number" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Figures -->
<xsl:template match="&FIGURE-LIKE;" mode="serial-number">
    <xsl:choose>
        <xsl:when test="$b-number-figure-distinct">
            <xsl:apply-templates select="." mode="atomic-figure-serial-number" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Inline Exercises -->
<xsl:template match="exercise" mode="serial-number">
    <xsl:choose>
        <xsl:when test="$b-number-exercise-distinct">
            <xsl:apply-templates select="." mode="atomic-exercise-serial-number" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="." mode="overall-blocks-serial-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We accumulate counts for any elements     -->
<!-- included in the grand, overall block      -->
<!-- count, while excluding those not included -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="overall-blocks-serial-number">
    <!-- always count fundamental blocks -->
    <xsl:variable name="atomic-block">
        <xsl:apply-templates select="." mode="atomic-block-serial-number" />
    </xsl:variable>
    <!-- include project count? -->
    <xsl:variable name="atomic-project">
        <xsl:choose>
            <xsl:when test="$b-number-project-distinct">
                <xsl:value-of select="0" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="atomic-project-serial-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- include figure count? -->
    <xsl:variable name="atomic-figure">
        <xsl:choose>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:value-of select="0" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="atomic-figure-serial-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- include exercise count? -->
    <xsl:variable name="atomic-exercise">
        <xsl:choose>
            <xsl:when test="$b-number-exercise-distinct">
                <xsl:value-of select="0" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="atomic-exercise-serial-number" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Add four groups and report -->
    <xsl:value-of select="$atomic-block + $atomic-project + $atomic-figure + $atomic-exercise" />
</xsl:template>

<!-- Atomic block serial number -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="atomic-block-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-theorems" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/reading-questions" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/reading-questions" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/reading-questions" level="any" count="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for atomic block number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Atomic project serial number -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="atomic-project-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:choose>
            <xsl:when test="$b-number-project-distinct">
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-projects" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-theorems" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/reading-questions" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/reading-questions" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/reading-questions" level="any" count="&PROJECT-LIKE;" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for project number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Atomic figure serial number -->
<!-- Note that since these are captioned items:       -->
<!-- If these live in "sidebyside", which is in       -->
<!-- turn contained in a "figure", then they will     -->
<!-- earn a subcaption with a subnumber, so we ignore -->
<!-- them in these counts of top-level numbered items -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&FIGURE-LIKE;|exercise" mode="atomic-figure-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:choose>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-figures" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-theorems" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/reading-questions" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/reading-questions" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/reading-questions" level="any"
                count="figure[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                table[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                listing[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]|
                list[not(parent::sidebyside/parent::figure or parent::sidebyside/parent::sbsgroup/parent::figure)]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for atomic figure number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Atomic inline exercise serial number -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|exercise|&FIGURE-LIKE;" mode="atomic-exercise-serial-number">
    <xsl:variable name="subtree-level">
        <xsl:choose>
            <xsl:when test="$b-number-exercise-distinct">
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-exercises" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="absolute-subtree-level">
                    <xsl:with-param name="numbering-items" select="$numbering-theorems" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet" level="any"
                count="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for atomic exercise number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Proofs may be numbered (for cross-reference knowls) -->
<xsl:template match="proof" mode="serial-number">
    <xsl:number />
</xsl:template>


<!-- Serial Numbers: Equations -->
<!-- We determine the appropriate subtree to count within  -->
<!-- given the document root and the configured depth      -->
<!-- Note: numbered/unnumbered accounted for here          -->
<!-- Note: presence of a local tag is like unnumbered      -->
<xsl:template match="mrow|men" mode="serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-equations" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no' or @tag)]"/>
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no' or @tag)]"/></xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no' or @tag)]"/>
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/reading-questions" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no' or @tag)]"/>
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/reading-questions" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no' or @tag)]"/>
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/reading-questions" level="any" count="men|md/mrow[@number = 'yes']|mdn/mrow[not(@number = 'no' or @tag)]"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for equation number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Exercises in Exercises or Worksheet or Reading Question Divisions -->
<!-- Note: numbers may be hard-coded for longevity        -->
<!-- exercisegroups  and future lightweight divisions may -->
<!-- be intermediate, but should not hinder the count     -->
<!-- NB: there are three historical "apply-templates"     -->
<!-- here which might now be written as "value-of",       -->
<!-- but perhaps it is irrelevant                         -->
<xsl:template match="exercises//exercise" mode="serial-number">
    <xsl:number from="exercises" level="any" count="exercise" />
</xsl:template>

<xsl:template match="exercises//exercise[@number]" mode="serial-number">
    <xsl:apply-templates select="@number" />
</xsl:template>

<xsl:template match="worksheet//exercise" mode="serial-number">
    <xsl:number from="worksheet" level="any" count="exercise" />
</xsl:template>

<xsl:template match="worksheet//exercise[@number]" mode="serial-number">
    <xsl:apply-templates select="@number" />
</xsl:template>

<xsl:template match="reading-questions//exercise" mode="serial-number">
    <xsl:number from="reading-questions" level="any" count="exercise" />
</xsl:template>

<xsl:template match="reading-questions//exercise[@number]" mode="serial-number">
    <xsl:apply-templates select="@number" />
</xsl:template>

<!-- Serial Numbers: Solutions -->
<!-- Hints, answers, solutions may be numbered (for cross-reference knowls) -->
<xsl:template match="hint|answer|solution" mode="serial-number">
    <xsl:number />
</xsl:template>

<!-- Serial Numbers: Bibliographic Items -->
<!-- Always sequential within a References section -->
<xsl:template match="biblio" mode="serial-number">
    <xsl:number from="references" level="any" count="biblio" />
</xsl:template>
<!-- Notes may be numbered (for cross-reference knowls) -->
<xsl:template match="biblio/note" mode="serial-number">
    <xsl:number />
</xsl:template>

<!-- Hints, answers, solutions, notes are often singletons.     -->
<!-- This utility returns the serial number, or if a singleton, -->
<!-- returns an empty string.  Employing templates will need    -->
<!-- to check if they want to react accordingly, or they should -->
<!-- just ask for the serial number itself if they don't care.  -->
<xsl:template match="hint|answer|solution|biblio/note" mode="non-singleton-number">
    <xsl:variable name="the-number">
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:variable>
    <xsl:choose>
        <!-- non-singletons always of interest/use -->
        <xsl:when test="not($the-number = 1)">
            <xsl:value-of select="$the-number" />
        </xsl:when>
        <!-- now being careful with "1" -->
        <xsl:otherwise>
            <xsl:variable name="elt-name" select="local-name(.)" />
            <!-- We go to the parent, get all like children, then     -->
            <!-- filter by name, since hints and answers, etc all mix -->
            <xsl:variable name="siblings-and-self" select="parent::*/*[local-name(.) = $elt-name]" />
            <!-- maybe "1" is interesting too -->
            <!-- if not, no result whatsoever -->
            <xsl:if test="count($siblings-and-self) > 1">
                <xsl:value-of select="$the-number" />
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Footnotes -->
<!-- We determine the appropriate subtree to count within -->
<!-- given the document root and the configured depth     -->
<xsl:template match="fn" mode="serial-number">
    <xsl:variable name="subtree-level">
        <xsl:apply-templates select="." mode="absolute-subtree-level">
            <xsl:with-param name="numbering-items" select="$numbering-footnotes" />
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$subtree-level=-1">
            <xsl:number from="book|article|letter|memo" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=0">
            <xsl:number from="part" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=1">
            <xsl:number from="chapter|book/backmatter/appendix" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=2">
            <xsl:number from="section|article/backmatter/appendix|chapter/exercises|chapter/worksheet|chapter/reading-questions" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=3">
            <xsl:number from="subsection|section/exercises|section/worksheet|section/reading-questions" level="any" count="fn" />
        </xsl:when>
        <xsl:when test="$subtree-level=4">
            <xsl:number from="subsubsection|subsection/exercises|subsection/worksheet|subsection/reading-questions" level="any" count="fn" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR: Subtree level for footnote number computation is out-of-bounds (<xsl:value-of select="$subtree-level" />)</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Serial Numbers: Subfigures, Subtables, Sublisting-->
<!-- Subcaptioning only happens with figures           -->
<!-- or tables arranged in a sidebyside, which         -->
<!-- is again contained inside a figure, the           -->
<!-- element providing the overall caption             -->
<!-- The serial number is a sub-number, (a), (b), (c), -->
<!-- *Always* with the parenthetical formatting        -->
<!-- Debatable if parentheses should come from here    -->


<!-- In this case the structure number is the          -->
<!-- full number of the enclosing figure               -->

<!-- a lone sidebyside, not in a sbsgroup -->
<xsl:template match="figure/sidebyside/figure | figure/sidebyside/table | figure/sidebyside/listing | figure/sidebyside/list" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="figure|table|listing|list"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- when inside a sbsgroup, subcaptions range across entire group -->
<xsl:template match="figure/sbsgroup/sidebyside/figure | figure/sbsgroup/sidebyside/table | figure/sbsgroup/sidebyside/listing | figure/sbsgroup/sidebyside/list" mode="serial-number">
    <xsl:text>(</xsl:text>
    <xsl:number format="a" count="figure|table|listing|list" level="any" from="sbsgroup"/>
    <xsl:text>)</xsl:text>
</xsl:template>

<!-- Serial Numbers: List Items -->

<!-- First, the number of a list item within its own ordered list.  This -->
<!-- trades on the MBX format codes being identical to the XSLT codes.   -->
<xsl:template match="ol/li" mode="item-number">
    <xsl:variable name="code">
        <xsl:apply-templates select=".." mode="format-code" />
    </xsl:variable>
    <xsl:number format="{$code}" />
</xsl:template>

<!-- Second, the serial number computed recursively.  The       -->
<!-- entire hierarchy should be ordered lists, since otherwise, -->
<!-- the template just below will apply instead.                -->
<xsl:template match="ol/li" mode="serial-number">
    <xsl:if test="ancestor::li">
        <xsl:apply-templates select="ancestor::li[1]" mode="serial-number" />
        <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="item-number" />
</xsl:template>

<!-- If any ancestor of a list item is not ordered, this     -->
<!-- template should match first, and the serial number      -->
<!-- will be empty, the signal that an object has no number. -->
<xsl:template match="ul//li|dl//li" mode="serial-number" />


<!-- Serial Numbers: Exercise Groups -->
<!-- We provide the range of the     -->
<!-- group as its serial number.     -->
<xsl:template match="exercisegroup" mode="serial-number">
    <xsl:apply-templates select="exercise[1]" mode="serial-number" />
    <xsl:call-template name="ndash-character"/>
    <xsl:apply-templates select="exercise[last()]" mode="serial-number" />
</xsl:template>

<!-- Serial Numbers: Tasks (in Projects) -->
<!-- Tasks have "list" numbers, which we use on labels -->
<!-- (we could use serial numbers for a more complex look) -->
<xsl:template match="task" mode="list-number">
    <xsl:number format="a" />
</xsl:template>
<xsl:template match="task/task" mode="list-number">
    <xsl:number format="i" />
</xsl:template>
<xsl:template match="task/task/task" mode="list-number">
    <xsl:number format="A" />
</xsl:template>
<!-- concatenate list numbers to get serial numbers, eg a.i.A -->
<xsl:template match="task" mode="serial-number">
    <xsl:apply-templates select="." mode="list-number" />
</xsl:template>
<xsl:template match="task/task" mode="serial-number">
    <xsl:apply-templates select="parent::task" mode="serial-number" />
    <xsl:text>.</xsl:text>
    <xsl:apply-templates select="." mode="list-number" />
</xsl:template>
<xsl:template match="task/task/task" mode="serial-number">
    <xsl:apply-templates select="parent::task" mode="serial-number" />
    <xsl:text>.</xsl:text>
    <xsl:apply-templates select="." mode="list-number" />
</xsl:template>

<!-- Serial Numbers: fragments -->
<!-- The @ref variant is not numbered, see below.  -->
<!-- We number the remainder sequentially.         -->
<xsl:template match="fragment" mode="serial-number">
    <xsl:value-of select="count(preceding::fragment) + 1"/>
</xsl:template>


<!-- Serial Numbers: the unnumbered     -->
<!-- Empty string signifies not numbered -->

<!-- We choose not to number unique, or semi-unique      -->
<!-- (eg prefaces, colophons), elements.  Other elements -->
<!-- are meant as local commentary, and may also carry   -->
<!-- a title for identification and cross-referencing.   -->
<xsl:template match="book|article|letter|memo|paragraphs|blockquote|preface|abstract|acknowledgement|biography|foreword|dedication|index-part|index[index-list]|colophon|webwork|p|assemblage|aside|biographical|historical|case|contributor" mode="serial-number" />

<!-- Some divisions, like "exercises", "solutions", "references",     -->
<!-- are part of the hierarchical numbering scheme, and look simply   -->
<!-- to their parent.  Which could be the top-level when in th main   -->
<!-- matter (we handle cases of children of "backmatter" carefully    -->
<!-- elsewhere or it does not happen).  So we need an empty structure -->
<!-- number for these cases.                                          -->
<xsl:template match="book|article|letter|memo" mode="structure-number" />

<!-- Some items are "containers".  They are not numbered, you  -->
<!-- cannot point to them, they are invisible to the reader    -->
<!-- in a way.  We kill their serial numbers explicitly here.  -->
<!-- Lists live in paragraphs, exercises, objectives, so       -->
<!-- should be referenced as part of some enclosing element.   -->
<!-- "mathbook" helps some tree-climbing routines halt -->
<xsl:template match="mathbook|pretext|introduction|conclusion|frontmatter|backmatter|sidebyside|ol|ul|dl|statement" mode="serial-number" />

<!-- Poems go by their titles, not numbers -->
<xsl:template match="poem" mode="serial-number" />

<!-- List items, subordinate to an unordered list, or a description  -->
<!-- list, will have numbers that are especically ambiguous, perhaps -->
<!-- even very clsoe within a multi-level list. They are unnumbered  -->
<!-- in the vicinity of computing serial numbers of list items in    -->
<!-- ordered lists.                                                  -->

<!-- Various displayed equations are not numbered.     -->
<!-- We do not consider the local @tag to be a number, -->
<!-- as it is more a string, formed from symbols       -->
<xsl:template match="me|md/mrow[not(@number='yes')]|mdn/mrow[@number='no']|mrow[@tag]" mode="serial-number" />

<!-- WeBWorK problems are never numbered, because they live    -->
<!-- in (numbered) exercises.  But they have identically named -->
<!-- components of exercises, so we might need to explicitly   -->
<!-- make webwork/solution, etc to be unnumbered.              -->

<!-- Defined terms, in a "glossary", are known by their title  -->
<xsl:template match="defined-term" mode="serial-number"/>

<!-- GOAL-LIKE are one-per-subdivision,               -->
<!-- and so get their serial number from their parent -->
<xsl:template match="&GOAL-LIKE;" mode="serial-number">
    <xsl:apply-templates select="parent::*" mode="serial-number" />
</xsl:template>

<!-- A subexercises is meant to be minimal, and does not have a number -->
<xsl:template match="subexercises" mode="serial-number"/>

<!-- This should not be called, a "fragment" as a      -->
<!-- pointer is not really much in the way of content, -->
<!-- and we are more interested in its target          -->
<xsl:template match="fragment[@ref]" mode="serial-number"/>

<!-- Multi-part WeBWorK problems have PTX elements        -->
<!-- called "stage" which typically render as "Part..."   -->
<!-- Their serial numbers are useful, there is no attempt -->
<!-- above to integrate these into our general scheme     -->
<!-- These are just counted among enclosing "webwork"     -->
<xsl:template match="webwork/stage" mode="serial-number">
    <xsl:number count="stage" from="webwork" />
</xsl:template>

<!-- But when a problem is part of the OPL and is retrieved -->
<!-- from the server, then we don't see the "stage" element -->
<!-- until we merge in the "static" version as part of the  -->
<!-- "webwork-reps" collection                              -->
<xsl:template match="webwork-reps/static/stage" mode="serial-number">
    <xsl:number count="stage" from="static" />
</xsl:template>


<!-- Should not drop in here.  Ever. -->
<xsl:template match="*" mode="serial-number">
    <xsl:text>[NUM]</xsl:text>
    <xsl:message>PTX:ERROR:   An object (<xsl:value-of select="local-name(.)" />) lacks a serial number, search output for "[NUM]"</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<!--                       -->
<!-- Multi-Numbers Utility -->
<!--                       -->

<!-- We concatenate serial numbers of divisions to form the       -->
<!-- "structure number" of a division or element.                 -->
<!-- NOTE: this is not the number of a division (or element),     -->
<!-- it is everything but the "serial number".  Later, the        -->
<!-- serial number is appended to form the "number".              -->
<!-- So if the context is a division element we look at strict    -->
<!-- *ancestors* to accumulate serial numbers into a structure    -->
<!-- number.  For example, an implication of this is that the     -->
<!-- structure number of a chapter in a part-less book will be    -->
<!-- empty - its number is just its serial-number.                -->
<!-- NB: the structure number never ends in a separator (period). -->
<!--                                                              -->
<!-- We initialize the recursion with exactly the ancestors       -->
<!-- that contributes to a structure number.  This is the only    -->
<!-- time the context is employed.  The level is                  -->
<!--   (a) $pad = 'no',  the maximum number of levels, which      -->
<!--   may not be reached if the $nodes get depleted              -->
<!--   (b) $pad = 'yes', the exact number of serial numbers       -->
<!--   accumulated, and hence the number of separators            -->
<!--   in the final number (after the serial number is appended)  -->
<!-- NB: decorative parts may mean we need                        -->
<!-- to exclude "part" from the ancestors?                        -->
<!-- NB: for a book with parts, we include the "backmatter" in    -->
<!-- the list of $nodes, to impersonate the "part" nodes when     -->
<!-- working with the main matter.  Like a "part", we silently    -->
<!-- drop it and decrement the level.                             -->

<!-- BUG: we include specialized divisions here, which inherit -->
<!-- their serial number from their parent.  The symptom is a  -->
<!-- duplicated serial number just before padding begins.  The -->
<!-- offending specialized division should be skipped with no  -->
<!-- contribution to the multi-number and no decrease in the   -->
<!-- level when passed recursively.                            -->

<xsl:template match="*" mode="multi-number">
    <xsl:param name="nodes" select="ancestor::*[self::part or self::chapter or self::appendix or self::section or self::subsection or self::subsubsection or self::exercises or self::reading-questions or self::solutions or self::references or self::glossary or self::worksheet or self::backmatter[$b-has-parts]]"/>
    <xsl:param name="levels" />
    <xsl:param name="pad" />

    <!-- Test if last node is unnumbered specialized division -->
    <!-- we do not want to duplicate the serial number, which is from the containing division -->
    <xsl:variable name="decorative-division">
        <xsl:if test="$nodes[last()][self::exercises or self::worksheet or self::reading-questions]">
            <xsl:variable name="is-structured">
                <xsl:apply-templates select="$nodes[last()]/parent::*" mode="is-structured-division"/>
            </xsl:variable>
            <xsl:if test="not($is-structured = 'true')">
                <xsl:text>true</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:variable>

    <xsl:choose>
        <!-- When the lead node is a part, we just drop it,   -->
        <!-- and we decrement the level.  A lead node of      -->
        <!-- backmatter will appear for a book with parts,    -->
        <!-- which is dropped also.  We may later devise      -->
        <!-- an option with more part numbers, and we can     -->
        <!-- condition here to include the part number in the -->
        <!-- numbering scheme NB: this is *not* the serial    -->
        <!-- number, so for example, the summary page for     -->
        <!-- a part *will* have a number, and the right one   -->
        <xsl:when test="$nodes[1][self::part or self::backmatter]">
            <xsl:apply-templates select="." mode="multi-number">
                <xsl:with-param name="nodes" select="$nodes[position() > 1]" />
                <xsl:with-param name="levels" select="$levels - 1" />
                <xsl:with-param name="pad" select="$pad" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- strip a decorative division -->
        <xsl:when test="$decorative-division = 'true'">
            <xsl:apply-templates select="." mode="multi-number">
                <xsl:with-param name="nodes" select="$nodes[position() &lt; last()]" />
                <xsl:with-param name="levels" select="$levels" />
                <xsl:with-param name="pad" select="$pad" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- always halt when levels met -->
        <xsl:when test="$levels = 0" />
        <!-- not padding, halt if $nodes exhausted -->
        <xsl:when test="($pad = 'no') and not($nodes)" />
        <xsl:otherwise>
            <xsl:choose>
                <xsl:when test="$nodes">
                    <xsl:apply-templates select="$nodes[1]" mode="serial-number"/>
                </xsl:when>
                <!-- no nodes, so must be padding -->
                <xsl:otherwise>
                    <xsl:text>0</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <!-- mutuially exclusive conditions, just for clarity           -->
            <!-- (a) if halting next pass, no separator, no-padding version -->
            <xsl:if test="($pad = 'no') and not(count($nodes) = 1) and not($levels = 1)">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <!-- (b) if halting next pass, no separator, padding version -->
            <xsl:if test="($pad = 'yes') and not($levels = 1)">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <!-- decrease $nodes and $levels             -->
            <!-- padding: empty $nodes can't get emptier -->
            <xsl:apply-templates select="." mode="multi-number">
                <xsl:with-param name="nodes" select="$nodes[position() > 1]" />
                <xsl:with-param name="levels" select="$levels - 1" />
                <xsl:with-param name="pad" select="$pad" />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!--                         -->
<!-- Structure Numbers       -->
<!--                         -->

<!-- We compute multi-part numbers to the necessary,  -->
<!-- or configured, number of components              -->
<!-- NB: *every* structure number should finish with  -->
<!-- a period as a separator, which is often provided -->
<!-- by the "multi-number" template.  Some of the     -->
<!-- cross-reference text code adds a period before   -->
<!-- testing equality of strings                      -->

<!-- Structure Numbers: Divisions -->
<!-- NB: this is number of the *container* of the division,   -->
<!-- a serial number for the division itself will be appended -->
<xsl:template match="part|chapter|appendix|section|subsection|subsubsection|backmatter/solutions" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-maxlevel - 1" />
        <xsl:with-param name="pad" select="'no'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Specialized Divisions -->
<!-- Some divisions get their numbers from their parents, or  -->
<!-- in other ways.  We are careful to do this by determining -->
<!-- the serial-numer and the structure-number, so that other -->
<!-- devices (like local numbers) will behave correctly.      -->
<!-- Serial numbers are computed elsewhere, but in tandem.    -->
<xsl:template match="exercises|solutions[not(parent::backmatter)]|worksheet|reading-questions|references[not(parent::backmatter)]|glossary[not(parent::backmatter)]" mode="structure-number">
    <xsl:variable name="is-structured">
        <xsl:apply-templates select="parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:variable name="b-is-structured" select="$is-structured = 'true'"/>
    <xsl:choose>
        <xsl:when test="$b-is-structured">
            <xsl:apply-templates select="." mode="multi-number">
                <xsl:with-param name="levels" select="$numbering-maxlevel - 1" />
                <xsl:with-param name="pad" select="'no'" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="structure-number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- "references" and "glossary" are solo in main matter -->
<!-- divisions, unique and not numbered in back matter   -->
<xsl:template match="backmatter/references" mode="structure-number" />
<xsl:template match="backmatter/glossary" mode="structure-number" />


<!-- Structure Numbers: Theorems, Examples, Projects, Figures -->
<xsl:template match="&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-theorems" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- PROJECT-LIKE is now independent, under control of $numbering-projects -->
<!-- But all ready to become elective -->
<xsl:template match="&PROJECT-LIKE;"  mode="structure-number">
    <xsl:variable name="project-levels">
        <xsl:choose>
            <xsl:when test="$b-number-project-distinct">
                <xsl:value-of select="$numbering-projects" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-theorems" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$project-levels" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- FIGURE-LIKE get a structure number from default $numbering-theorems -->
<!-- or from "docinfo" independent numbering configuration               -->
<xsl:template match="&FIGURE-LIKE;"  mode="structure-number">
    <xsl:variable name="figure-levels">
        <xsl:choose>
            <xsl:when test="$b-number-figure-distinct">
                <xsl:value-of select="$numbering-figures" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-theorems" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$figure-levels" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>
<!-- Proofs get structure number from parent theorem -->
<xsl:template match="proof" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>
<!-- Captioned items, arranged in a side-by-side,  -->
<!-- then inside a captioned figure, earn a serial -->
<!-- number that is a letter.  So their structure  -->
<!-- number comes from their grandparent figure    -->
<xsl:template match="figure/sidebyside/figure | figure/sidebyside/table | figure/sidebyside/listing | figure/sidebyside/list" mode="structure-number">
    <xsl:apply-templates select="parent::sidebyside/parent::figure" mode="number" />
</xsl:template>

<!-- Structure Numbers: Equations -->
<xsl:template match="mrow|men" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-equations" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Inline Exercises -->
<!-- Follows the theorem/figure/etc scheme (can't poll parent) -->
<xsl:template match="exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="structure-number">
    <xsl:variable name="equation-levels">
        <xsl:choose>
            <xsl:when test="$b-number-exercise-distinct">
                <xsl:value-of select="$numbering-exercises" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$numbering-theorems" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$equation-levels" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Divisional and Worksheet Exercises -->
<!-- Within a "exercises" or "worksheet", look up to enclosing division -->
<!-- in order to decide where the structure number comes from           -->
<xsl:template match="exercises//exercise|worksheet//exercise|reading-questions//exercise" mode="structure-number">
    <!-- one or the other, just a single node in variable -->
    <xsl:variable name="container" select="ancestor::*[self::exercises or self::worksheet or self::reading-questions]"/>
    <xsl:variable name="is-structured">
        <xsl:apply-templates select="$container/parent::*" mode="is-structured-division"/>
    </xsl:variable>
    <xsl:variable name="b-is-structured" select="$is-structured = 'true'"/>
    <xsl:choose>
        <xsl:when test="$b-is-structured">
            <xsl:apply-templates select="$container" mode="number" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$container/parent::*" mode="number" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Structure Numbers: Exercise Groups -->
<!-- An exercisegroup gets it structure number from the parent exercises -->
<xsl:template match="exercisegroup" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Hints, answers, solutions get structure number from parent       -->
<!-- exercise's number. Identical for inline and divisional exercises -->
<xsl:template match="hint|answer|solution" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Anything within a webwork-reps that needs a structure number    -->
<!-- gets it from the enclosing exercise.                            -->
<xsl:template match="webwork-reps//*" mode="structure-number">
    <xsl:apply-templates select="ancestor::exercise" mode="number" />
</xsl:template>

<!-- Structure Numbers: Bibliographic Items -->
<!-- Bibliographic items get their number from the containing     -->
<!-- "references", which may be solo in an unstructured division, -->
<!-- or one of potentially several in a structured division.      -->
<!-- Since the global "references" (child of "backmatter") is not -->
<!-- numbered, these items will have un-qualified numbers         -->
<!-- (serial number only). -->
<xsl:template match="biblio" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Notes get structure number from parent biblio's number -->
<xsl:template match="biblio/note" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="number" />
</xsl:template>

<!-- Structure Numbers: Footnotes -->
<xsl:template match="fn" mode="structure-number">
    <xsl:apply-templates select="." mode="multi-number">
        <xsl:with-param name="levels" select="$numbering-footnotes" />
        <xsl:with-param name="pad" select="'yes'" />
    </xsl:apply-templates>
</xsl:template>

<!-- Structure Numbers: Lists -->
<!-- Lists occur in paragraphs (anonymously), in "list"      -->
<!-- blocks (numbered), and within exercises (numbered).     -->
<!-- Typically we are interested in list items (only),       -->
<!-- since that is where there is content.  And then we      -->
<!-- are only interested in the list items within an ordered -->
<!-- list.  We control for items under unordered lists or    -->
<!-- description lists elsewhere by providing empty numbers. -->
<!-- NB: the order of these templates may matter             -->
<xsl:template match="li" mode="structure-number" />

<xsl:template match="list//li" mode="structure-number">
    <xsl:apply-templates select="ancestor::list" mode="number" />
</xsl:template>

<xsl:template match="exercise//li" mode="structure-number">
    <xsl:apply-templates select="ancestor::exercise" mode="number" />
</xsl:template>

<!-- Structure Numbers: Tasks (in projects) -->
<!-- A task gets it structure number from the parent project-like -->
<xsl:template match="task" mode="structure-number">
    <!-- ancestors, strip tasks, get number of next enclosure -->
    <xsl:apply-templates select="ancestor::*[not(self::task)][1]" mode="number" />
</xsl:template>

<!-- Structure Numbers: GOAL-LIKE -->
<!-- Objectives are one-per-subdivision, and so   -->
<!-- get their structure number from their parent -->
<xsl:template match="&GOAL-LIKE;" mode="structure-number">
    <xsl:apply-templates select="parent::*" mode="structure-number" />
</xsl:template>

<!-- Structure Numbers: Objective and Outcome-->
<!-- A single objective or outcome is a list item -->
<!-- in an objectives or outcomes environment     -->
<xsl:template match="objectives/ol/li|outcomes/ol/li" mode="structure-number">
    <xsl:apply-templates select="ancestor::*[&STRUCTURAL-FILTER;][1]" mode="number" />
</xsl:template>

<!-- Structure Numbers: Fragment -->
<!-- We number serially, see below -->
<xsl:template match="fragment" mode="structure-number"/>

<!-- Should not drop in here.  Ever. -->
<xsl:template match="*" mode="structure-number">
    <xsl:text>[STRUCT]</xsl:text>
    <xsl:message>PTX:ERROR:   An object (<xsl:value-of select="local-name(.)" />) lacks a structure number, search output for "[STRUCT]"</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
</xsl:template>

<!--              -->
<!-- Full Numbers -->
<!--              -->

<!-- Now trivial, the container structure plus the serial.  -->
<!-- We condition on empty serial number in order to create -->
<!-- empty full numbers.  This is where we add separator,   -->
<!-- normally a period, but for a list item within a named  -->
<!-- list, we use a colon (a double period?).               -->
<xsl:template match="*" mode="number">
    <xsl:variable name="serial">
        <xsl:apply-templates select="." mode="serial-number" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$serial = ''" />
        <xsl:otherwise>
            <xsl:variable name="structure">
                <xsl:apply-templates select="." mode="structure-number" />
            </xsl:variable>
            <xsl:if test="not($structure='')">
                <xsl:value-of select="$structure" />
                <xsl:choose>
                    <xsl:when test="self::li and ancestor::list">
                        <xsl:text>:</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>.</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:value-of select="$serial" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- TESTING -->
<!-- Some test images and debugging output, -->
<!-- while this is still in development -->

<!--
<image />
<image margins="20% 5%" />
<image width="75%" />
<image margins="20% 5%" width="75%" />
 -->
<!-- ~~~~~~~~~~~~~~ -->
<!--
<image margins="150pt" />
<image width="2000" />
<image margins="-40%" />
<image margins="300%" />
<image margins="-20% 5%" />
<image margins="20% 150%" />
<image margins="90% 40%" />
<image margins="5% 10%" width="120%" />
<image margins="5% 10%" width="-10%" />
<image margins="5% 10%" width="90%" />
<image margins="35% 25%" width="39.5%" />
-->

<!--
<xsl:template match="image[not(parent::sidebyside or parent::figure)]">
    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />
    <xsl:message><xsl:value-of select="$layout/left-margin" /></xsl:message>
    <xsl:message><xsl:value-of select="$layout/width" /></xsl:message>
    <xsl:message><xsl:value-of select="$layout/right-margin" /></xsl:message>
    <xsl:message><xsl:value-of select="$layout/left-margin = $layout/right-margin" /></xsl:message>
</xsl:template>
-->

<!-- ############## -->
<!-- Simple Layouts -->
<!-- ############## -->

<!-- This template creates a RTF (result tree fragment), -->
<!-- which needs to be captured in one variable, then    -->
<!-- converted to a node-set with an extension function  -->

<!-- aspect-ratio is only needed for videos in HTML.     -->
<!-- Long story.  It needs to match what is provided     -->
<!-- in the video (a file or an embedded player).  A     -->
<!-- sensible default is "1:1" but in context we might   -->
<!-- want to supply some other sensible default like     -->
<!-- "16:9".  The ONLY purpose of specifying an          -->
<!-- aspect-ratio is to compute some sort of height.     -->
<!-- So we do not report the aspect-ratio itself, but    -->
<!-- instead compute a height (*only* for video).        -->

<!-- NB: An RTF has a "root" node.  Then the elements    -->
<!-- manufactured for it occur as children.  If the      -->
<!-- "apply-templates" fails to have the "/*" at the end -->
<!-- of the "select", then the main entry template will  -->
<!-- be called to do any housekeeping it might do.       -->
<!-- This was a really tough bug to track down.          -->

<xsl:template match="image|audio|video|program|console|tabular" mode="layout-parameters">
    <xsl:param name="default-aspect" select="'1:1'"/>

    <!-- clean up margins -->
    <xsl:variable name="normalized-margins">
        <xsl:choose>
            <xsl:when test="@margins">
                <xsl:value-of select="normalize-space(@margins)" />
            </xsl:when>
            <!-- default if not specified -->
            <xsl:otherwise>
                <xsl:text>auto</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- split on space, or else duplicate (signals centered) -->
    <xsl:variable name="normalized-left-margin">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-before($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="normalized-right-margin">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-after($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- clean-up single width -->
    <xsl:variable name="normalized-width">
        <xsl:choose>
            <xsl:when test="@width">
                <xsl:value-of select="normalize-space(@width)" />
            </xsl:when>
            <!-- not placed on image, or figure/image,    -->
            <!-- but a document-wide default width exists -->
            <xsl:when test="self::image and not(ancestor::sidebyside) and $docinfo/defaults/image-width">
                <xsl:value-of select="$docinfo/defaults/image-width" />
            </xsl:when>
            <!-- default setting if not specified, and not global -->
            <xsl:otherwise>
                <xsl:value-of select="'auto'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- clean-up aspect-ratio -->
    <!-- may be a hollow exercise, but no harm since a -->
    <!-- valid ratio is given in parameter default     -->
    <xsl:variable name="normalized-aspect">
        <xsl:variable name="entered-aspect">
            <xsl:choose>
                <xsl:when test="@aspect">
                    <xsl:value-of select="normalize-space(@aspect)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space($default-aspect)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- test if a ratio is given, and assume parts are -->
            <!-- good and that there is only one colon, etc,... -->
            <xsl:when test="contains($entered-aspect, ':')">
                <xsl:variable name="width" select="substring-before($entered-aspect, ':')" />
                <xsl:variable name="height" select="substring-after($entered-aspect, ':')" />
                <xsl:value-of select="$width div $height" />
            </xsl:when>
            <!-- else assume a number was entered -->
            <xsl:otherwise>
                <xsl:value-of select="$entered-aspect"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Error checks on author's specifications     -->
    <!-- First, normalized to strings or percentages -->

    <xsl:if test="not(($normalized-left-margin = 'auto') or substring($normalized-left-margin, string-length($normalized-left-margin)) = '%')">
        <xsl:message>PTX:ERROR:   left margin (<xsl:value-of select="$normalized-left-margin" />) should be given as a percentage (such as "40%"), or as the string "auto"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <xsl:if test="not(($normalized-width = 'auto') or substring($normalized-width, string-length($normalized-width)) = '%')">
        <xsl:message>PTX:ERROR:   width (<xsl:value-of select="$normalized-width" />) should be given as a percentage (such as "40%"), or as the string "auto"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <xsl:if test="not(($normalized-right-margin = 'auto') or substring($normalized-right-margin, string-length($normalized-right-margin)) = '%')">
        <xsl:message>PTX:ERROR:   right margin (<xsl:value-of select="$normalized-right-margin" />) should be given as a percentage (such as "40%"), or as the string "auto"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Second, cases where computed values could be negative or too large -->

    <!-- Sanity check author's left margin -->
    <xsl:if test="not($normalized-left-margin = 'auto') and ((substring-before($normalized-left-margin, '%') &lt; 0) or (substring-before($normalized-left-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   left margin (<xsl:value-of select="$normalized-left-margin" />) must be in the interval [0%, 100%]</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check author's width -->
    <xsl:if test="not($normalized-width= 'auto') and ((substring-before($normalized-width, '%') &lt; 0) or (substring-before($normalized-width, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   width (<xsl:value-of select="$normalized-width" />) must be in the interval [0%, 100%]</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check author's right margin -->
    <xsl:if test="not($normalized-right-margin = 'auto') and ((substring-before($normalized-right-margin, '%') &lt; 0) or (substring-before($normalized-right-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   right margin (<xsl:value-of select="$normalized-right-margin" />) must be in the interval [0%, 100%]</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check author's cumulative margins -->
    <xsl:if test="not($normalized-left-margin = 'auto') and ((substring-before($normalized-left-margin, '%') + substring-before($normalized-right-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   margins (<xsl:value-of select="$normalized-left-margin" />, <xsl:value-of select="$normalized-right-margin" />) must not have a sum exceeding 100%</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check all parameters together as too large -->
    <xsl:if test="not($normalized-left-margin = 'auto') and not($normalized-width= 'auto') and ((substring-before($normalized-left-margin, '%') + substring-before($normalized-width, '%') + substring-before($normalized-right-margin, '%') &gt; 100))">
        <xsl:message>PTX:ERROR:   margins and width (<xsl:value-of select="$normalized-left-margin" />, <xsl:value-of select="$normalized-width" />, <xsl:value-of select="$normalized-right-margin" />) must not have a sum exceeding 100%</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check that all three parameters together sum to 100 *exactly* -->
    <xsl:if test="not($normalized-left-margin = 'auto') and not($normalized-width= 'auto') and not((substring-before($normalized-left-margin, '%') + substring-before($normalized-width, '%') + substring-before($normalized-right-margin, '%') = 100))">
        <xsl:message>PTX:ERROR:   margins and width (<xsl:value-of select="$normalized-left-margin" />, <xsl:value-of select="$normalized-width" />, <xsl:value-of select="$normalized-right-margin" />) must sum to 100%</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>

    <!-- Sanity check on the aspect-ratio -->
    <!-- NaN does not equal *anything*, so tests if a number  -->
    <!-- http://stackoverflow.com/questions/6895870           -->
    <xsl:if test="not(number($normalized-aspect) = number($normalized-aspect)) or ($normalized-aspect &lt; 0)">
        <xsl:message>PTX:ERROR:   the @aspect attribute should be a ratio, like 4:3, or a positive number, not "<xsl:value-of select="@aspect" />"</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="$normalized-aspect = 0">
        <xsl:message>PTX:ERROR:   an @aspect attribute equal to zero will cause serious errors.</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
        <xsl:message terminate="yes">Quitting...</xsl:message>
    </xsl:if>

    <!-- Perhaps save for debugging -->
    <!-- <xsl:message>L:<xsl:value-of select="$normalized-left-margin" />:L W:<xsl:value-of select="$normalized-width" />:W R:<xsl:value-of select="$normalized-right-margin" />:R</xsl:message> -->

    <!-- Now have three "normalized" percentages, with percentages   -->
    <!-- or default string values.  We would read the table below as -->
    <!-- rows (cases), but we instead focus on the three outcomes    -->
    <!-- as a single variable each.                                  -->
    <!--                                                             -->
    <!--     Margin   Width      Left      Width     Right           -->
    <!--                                                             -->
    <!--     auto     auto          0        100         0           -->
    <!--     value    auto      value    compute     value           -->
    <!--     auto     value    center      value    center           -->
    <!--     value    value     value      value     value           -->
    <!--                                                             -->
    <!-- In contrast to earlier practice, we now (2018-07-20) return -->
    <!-- percentages with no percent sign, so as to do the least     -->
    <!-- manipulation possible here.  Consumers can add back the     -->
    <!-- percent sign, divide by 100, take a fraction of a maximum   -->
    <!-- width, and so on.                                           -->

    <xsl:variable name="left-margin">
        <xsl:choose>
            <xsl:when test="($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="'0'" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-left-margin, '%')" />
            </xsl:when>
            <xsl:when test="($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="(100 - substring-before($normalized-width, '%')) div 2" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-left-margin, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>OOOPS1111</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="right-margin">
        <xsl:choose>
            <xsl:when test="($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="'0'" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-right-margin, '%')" />
            </xsl:when>
            <xsl:when test="($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="(100 - substring-before($normalized-width, '%')) div 2" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-right-margin, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>OOOPS22222</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="width">
        <xsl:choose>
            <xsl:when test="($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="'100'" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and ($normalized-width = 'auto')">
                <xsl:value-of select="100 - substring-before($normalized-left-margin, '%') - substring-before($normalized-right-margin, '%')" />
            </xsl:when>
            <xsl:when test="($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-width, '%')" />
            </xsl:when>
            <xsl:when test="not($normalized-left-margin = 'auto') and not($normalized-width = 'auto')">
                <xsl:value-of select="substring-before($normalized-width, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>OOOPS33333</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- "height" is derived from width and aspect-ratio.  -->
    <!-- We warn above about a potential division by zero. -->
    <xsl:variable name="height" select="$width div $normalized-aspect"/>

    <xsl:variable name="centered" select="$left-margin = $right-margin" />

    <!-- This is the RTF, which will automatically be bundled with -->
    <!-- a root. Elements should be mostly self-explanatory.       -->
    <!-- "centered" is reported NOW, not computed later, when the  -->
    <!-- two margins are either                                    -->
    <!--   (a) specified identically by the author,                -->
    <!--   (b) computed identically above, or                      -->
    <!--   (c) default to identical values.                        -->

    <left-margin>
        <xsl:value-of select="$left-margin" />
    </left-margin>
    <width>
        <xsl:value-of select="$width" />
    </width>
    <!-- Only a "video" gets its height from this layout object, -->
    <!-- so even if we have computed it, we do not report it     -->
    <xsl:if test="self::video">
        <height>
            <xsl:value-of select="$height"/>
        </height>
    </xsl:if>
    <right-margin>
        <xsl:value-of select="$right-margin" />
    </right-margin>
    <centered>
        <xsl:value-of select="$centered" />
    </centered>

    <!-- This will be useful in a debugging switch -->
<!--
    <xsl:message>l:<xsl:value-of select="$left-margin" />:l w:<xsl:value-of select="$width" />:w r:<xsl:value-of select="$right-margin" />:r c:<xsl:value-of select="$centered" />:c</xsl:message>
    <xsl:message>- - - - - - - - - - - - - </xsl:message>
-->
</xsl:template>

<!-- ################## -->
<!-- SideBySide Layouts -->
<!-- ################## -->

<!-- Horizontal layouts of "panels" with vertical alignments      -->
<!-- A container for layout of other elements, eg figures, images -->
<!-- No notion of columns, no rules or dividers, no row headings  -->
<!-- This is purely a container to specify layout parameters,     -->
<!-- and place/control the horizontal arrangement in converters   -->

<!-- Debugging information is not documented, nor supported     -->
<!-- Colored boxes in HTML, black boxes in LaTeX with baselines -->
<xsl:param name="sbs.debug" select="'no'" />
<xsl:variable name="sbsdebug" select="boolean($sbs.debug = 'yes')" />

<!-- A "sidebyside" is a sequence of objects laid out       -->
<!-- horizontally in panels.  This is a deviation from      -->
<!-- the usual vertical rythym of a page.  The "best"       -->
<!-- objects are those that are pliable horizontally,       -->
<!-- such as a paragraph, or a scalable image.  Rigid       -->
<!-- objects, like pre-formatted text or some tables,       -->
<!-- require some care from the author.  Attributes         -->
<!-- that control the layout follow, and override           -->
<!-- identical attributes placed on an enclosing            -->
<!-- "sbsgroup" (if employed).                              -->
<!--                                                        -->
<!-- (a) "margins"                                          -->
<!--  - one percentage for both left and right (nn%)        -->
<!--  - "auto" => margins are half the space between panels -->
<!--  - default is "auto"                                   -->
<!-- (b) "widths"                                           -->
<!--  - widths of panels, one per panel                     -->
<!--  - space separated list of percentages                 -->
<!--  - default is equal division of available total width  -->
<!-- (c) "valigns", "valign"                                -->
<!--  - vertical alignment of content within panel          -->
<!--  - space separated list of top, middle, bottom         -->
<!--  - singular is common alignment for all panels         -->
<!--  - default is top                                      -->
<!--                                                        -->
<!-- Default behavior is automatic margins, no spacing      -->
<!-- between panels and equally wide panels.                -->
<!--                                                        -->
<!-- With widths specified, remaining space is              -->
<!-- used to create equal spacing between panels            -->

<!-- Extensive layout analysis first, main templates follow -->

<!-- We analyze the attributes of a "sidebyside" element -->
<!-- in order to extract/compute the layout parameters   -->
<!-- This template creates a RTF (result tree fragment), -->
<!-- which needs to be captured in one variable, then    -->
<!-- converted to a node-set with an extension function  -->
<xsl:template match="sidebyside" mode="layout-parameters">

    <!-- Number of Panels -->
    <!-- count the elements destined for panels  -->
    <!-- Metadata banned, roughly 2017-07, now pure container  -->
    <!-- Retain filter for backward compatibility              -->
    <xsl:variable name="number-panels" select="count(*[not(&METADATA-FILTER;)])" />
    <xsl:if test="$sbsdebug">
        <xsl:message>N:<xsl:value-of select="$number-panels" />:N</xsl:message>
    </xsl:if>
    <!-- Add to RTF -->
    <number-panels>
        <xsl:value-of select="$number-panels" />
    </number-panels>

    <!-- Vertical Alignments of Panels -->
    <!-- Produce temporary space-separated list, with trailing space     -->
    <!-- Look up into enclosing "sbsgroup" if none given on "sidebyside" -->
    <!-- Error-check attribute values as $valigns string gets unpacked   -->
    <xsl:variable name="valigns">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@valigns">
                <xsl:value-of select="concat(normalize-space(@valigns), ' ')" />
            </xsl:when>
            <!-- singular form is convenience -->
            <xsl:when test="@valign">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(@valign), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- look to enclosing sbsgroup -->
            <xsl:when test="parent::sbsgroup[@valigns]">
                <xsl:value-of select="concat(normalize-space(parent::sbsgroup/@valigns), ' ')" />
            </xsl:when>
            <!-- look to enclosing sbsgroup for singular convenience -->
            <xsl:when test="parent::sbsgroup[@valign]">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(parent::sbsgroup/@valign), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- default: place all panels at the top   -->
            <!-- NB: space at end of $text is separator -->
            <xsl:otherwise>
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="'top '" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
             </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>VA:<xsl:value-of select="$valigns" />:VA</xsl:message>
    </xsl:if>
    <!-- check length (author-supplied could be wrong) -->
    <xsl:variable name="nspaces-valigns" select="string-length($valigns) - string-length(translate($valigns, ' ', ''))" />
    <xsl:choose>
        <xsl:when test="$nspaces-valigns &lt; $number-panels">
            <xsl:message>MBX:FATAL:   a &lt;sidebyside&gt; or &lt;sbsgroup&gt; does not have enough "@valigns" (maybe you did not specify enough?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="$nspaces-valigns &gt; $number-panels">
            <xsl:message>MBX:WARNING: a &lt;sidebyside&gt; or &lt;sbsgroup&gt; has extra "@valigns" (did you confuse singular and plural attribute names?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- unpack with an error-check on attribute values -->
    <!-- RTF formation happens with unpacking           -->
    <xsl:call-template name="decompose-valigns">
        <xsl:with-param name="valigns" select="$valigns" />
    </xsl:call-template>


    <!-- Margins and Widths -->
    <!-- clean up and organize widths                             -->
    <!-- Always produces space-separated list with trailing space -->
    <!-- Error-check as $widths string gets depleted below        -->
    <xsl:variable name="normalized-widths">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@widths">
                <xsl:value-of select="concat(normalize-space(@widths), ' ')" />
            </xsl:when>
            <!-- singular form is convenience -->
            <xsl:when test="@width">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(@width), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- look to enclosing sidebyside group -->
            <xsl:when test="parent::sbsgroup[@widths]">
                <xsl:value-of select="concat(normalize-space(parent::sbsgroup/@widths), ' ')" />
            </xsl:when>
            <!-- look to enclosing sidebyside group for singular convenience -->
            <xsl:when test="parent::sbsgroup[@width]">
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat(normalize-space(parent::sbsgroup/@width), ' ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
            </xsl:when>
            <!-- defer default computation post-margins      -->
            <!-- NB: "undetermined" widths is a single space -->
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- clean up margins -->
    <xsl:variable name="normalized-margins">
        <xsl:choose>
            <!-- individual sbs takes priority -->
            <xsl:when test="@margins">
                <xsl:value-of select="normalize-space(@margins)" />
            </xsl:when>
            <!-- look to enclosing sidebyside group -->
            <xsl:when test="parent::sbsgroup[@margins]">
                <xsl:value-of select="normalize-space(parent::sbsgroup/@margins)" />
            </xsl:when>
            <!-- default will make pleasing layout: -->
            <!--   (a) for one panel, no settings -->
            <!--   (b) no margin given, all sensible widths -->
            <xsl:otherwise>
                <xsl:text>auto</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- construct left and right margins, possibly identical      -->
    <!-- these may be 'auto' and get updated later (hence "early") -->
    <xsl:variable name="left-margin-early">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-before($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="right-margin-early">
        <xsl:choose>
            <xsl:when test="contains($normalized-margins, ' ')">
                <xsl:value-of select="substring-after($normalized-margins, ' ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$normalized-margins" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- total widths used/available    -->
    <!-- no attributes, use 100         -->
    <!-- no width, subtract two margins -->
    <!-- widths given, sum them         -->
    <!-- no percent sign, just internal -->
    <!-- TOD: error-check that sum is 100 or less -->
    <xsl:variable name="sum-widths">
        <xsl:choose>
            <xsl:when test="$normalized-widths = ' ' and $normalized-margins = 'auto'">
                <xsl:text>100</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-widths = ' '">
                <xsl:value-of select="100 - substring-before($left-margin-early, '%') - substring-before($right-margin-early, '%')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="sum-percentages">
                    <xsl:with-param name="percent-list" select="$normalized-widths" />
                    <xsl:with-param name="sum" select="'0'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- have width totals, determine margins         -->
    <!-- automatic creates margins that will be half -->
    <!-- of the subsequent space-width computation   -->
    <!-- Input assumes % present (unless 'auto')     -->
    <!-- Output preserves % on result                -->
    <xsl:variable name="left-margin">
        <xsl:choose>
            <xsl:when test="$number-panels = 0">
                <xsl:text>0%</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-margins = 'auto'">
                <xsl:value-of select="(100 - $sum-widths) div (2 * $number-panels)" />
                <xsl:text>%</xsl:text>
            </xsl:when>
            <!-- TODO: condition on % present, let otherwise report failure -->
            <xsl:otherwise>
                <xsl:value-of select="$left-margin-early" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="right-margin">
        <xsl:choose>
            <xsl:when test="$number-panels = 0">
                <xsl:text>0%</xsl:text>
            </xsl:when>
            <xsl:when test="$normalized-margins = 'auto'">
                <xsl:value-of select="(100 - $sum-widths) div (2 * $number-panels)" />
                <xsl:text>%</xsl:text>
            </xsl:when>
            <!-- TODO: condition on % present, let otherwise report failure -->
            <xsl:otherwise>
                <xsl:value-of select="$right-margin-early" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>M:<xsl:value-of select="$left-margin" />:<xsl:value-of select="$right-margin" />:M</xsl:message>
    </xsl:if>
    <!-- error check for reasonable values -->
    <xsl:if test="(substring-before($left-margin, '%') &lt; 0) or (substring-before($left-margin, '%') &gt; 100)">
        <xsl:message>MBX:ERROR:   left margin of a &lt;sidebyside&gt; ("<xsl:value-of select="$left-margin" />") is outside the interval [0%, 100%], (this may be computed, check consistency of "@margins" and "@widths")</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <xsl:if test="(substring-before($right-margin, '%') &lt; 0) or (substring-before($right-margin, '%') &gt; 100)">
        <xsl:message>MBX:ERROR:   right margin of a &lt;sidebyside&gt; ("<xsl:value-of select="$right-margin" />") is outside the interval [0%, 100%], (this may be computed, check consistency of "@margins" and "@widths")</xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:if>
    <!-- Add to RTF -->
    <left-margin>
        <xsl:value-of select="$left-margin" />
    </left-margin>
    <right-margin>
        <xsl:value-of select="$right-margin" />
    </right-margin>

    <!-- if no widths given, distribute excess beyond margins -->
    <!-- NB: with percent signs, blank at end always          -->
    <!-- Error-check as $widths string gets depleted below    -->
    <xsl:variable name="widths">
        <xsl:choose>
            <xsl:when test="$normalized-widths = ' '">
                <xsl:variable name="common-width" select="(100 - substring-before($left-margin, '%') - substring-before($right-margin, '%')) div $number-panels" />
                <!-- transfer as percentages (abstract), with blank at end -->
                <xsl:call-template name="duplicate-string">
                     <xsl:with-param name="text" select="concat($common-width, '% ')" />
                     <xsl:with-param name="count" select="$number-panels" />
                 </xsl:call-template>
             </xsl:when>
             <xsl:otherwise>
                <xsl:value-of select="$normalized-widths" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>W:<xsl:value-of select="$widths" />:W</xsl:message>
    </xsl:if>
    <!-- check length (author-supplied could be wrong) -->
    <xsl:variable name="nspaces-widths" select="string-length($widths) - string-length(translate($widths, ' ', ''))" />
    <xsl:choose>
        <xsl:when test="$nspaces-widths &lt; $number-panels">
            <xsl:message>MBX:FATAL:   a &lt;sidebyside&gt; or &lt;sbsgroup&gt; does not have enough "@widths" (maybe you did not specify enough?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
            <xsl:message terminate="yes">             That's fatal.  Sorry.  Quitting...</xsl:message>
        </xsl:when>
        <xsl:when test="$nspaces-widths &gt; $number-panels">
            <xsl:message>MBX:WARNING: a &lt;sidebyside&gt; or &lt;sbsgroup&gt; has extra "@widths" (did you confuse singular and plural attribute names?)</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- unpack with an error-check on attribute values -->
    <!-- RTF formation happens with unpacking           -->
    <xsl:call-template name="decompose-widths">
        <xsl:with-param name="widths" select="$widths" />
    </xsl:call-template>

    <!-- Spacing Between Panels -->
    <!-- compute common spacing between panels, as percent -->
    <!-- subtract margins and sum-widths from 100,         -->
    <!-- and then distribute to n - 1 spaces               -->
    <!-- includes % for external use                       -->
    <xsl:variable name="space-width">
        <xsl:choose>
            <xsl:when test="$number-panels &lt; 2">
                <!-- no spaces, avoids all division by zero -->
                <xsl:text>0</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="(100 - $sum-widths  - substring-before($left-margin, '%') - substring-before($right-margin, '%')) div ($number-panels - 1)" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>%</xsl:text>
    </xsl:variable>
    <xsl:if test="$sbsdebug">
        <xsl:message>SW:<xsl:value-of select="$space-width" />:SW</xsl:message>
    </xsl:if>
    <!-- overall error check on space width -->
    <xsl:choose>
        <xsl:when test="substring-before($space-width, '%') &lt; 0">
            <xsl:message>MBX:ERROR:   computed space between panels of a &lt;sidebyside&gt; ("<xsl:value-of select="$space-width" />") is negative (this value is computed, check consistency of "@margins" and "@widths")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
        <xsl:when test="substring-before($space-width, '%') = 'NaN'">
            <xsl:message>MBX:ERROR:   computed space between panels of a &lt;sidebyside&gt; is not a number (this value is computed, check that margins ("<xsl:value-of select="$left-margin" />, <xsl:value-of select="$right-margin" />") and widths ("<xsl:value-of select="$widths" />") are percentages of the form "nn%")</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:when>
    </xsl:choose>
    <!-- Add to RTF -->
    <space-width>
        <xsl:value-of select="$space-width" />
    </space-width>
</xsl:template>

<!-- ########################### -->
<!-- SidebySide Layout Utilities -->
<!-- ########################### -->

<!-- From a space-separated list of vertical alignments -->
<!-- create error-checked result tree fragment          -->
<xsl:template name="decompose-valigns">
    <xsl:param name="valigns" />
    <xsl:variable name="the-valign" select="substring-before($valigns, ' ')" />
    <xsl:if test="not($the-valign = '')">
        <!-- error-check, since list bypasses schema -->
        <!-- "top" is default, so check first        -->
        <xsl:choose>
            <xsl:when test="$the-valign = 'top'" />
            <xsl:when test="$the-valign = 'bottom'" />
            <xsl:when test="$the-valign = 'middle'" />
            <xsl:otherwise>
                <xsl:message>MBX:ERROR:   @valign(s) ("<xsl:value-of select="$the-valign" />") in &lt;sidebyside&gt; or &lt;sbsgroup&gt; is not "top," "middle" or "bottom"</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:otherwise>
        </xsl:choose>
        <!-- okay, output element -->
        <valign>
            <xsl:value-of select="$the-valign" />
        </valign>
        <!-- recurse on trailing -->
        <xsl:call-template name="decompose-valigns">
            <xsl:with-param name="valigns" select="substring-after($valigns, ' ')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- From a space-separated list of widths (percentages) -->
<!-- create error-checked result tree fragment           -->
<xsl:template name="decompose-widths">
    <xsl:param name="widths" />
    <xsl:variable name="the-width" select="substring-before($widths, ' ')" />
    <xsl:if test="not($the-width = '')">
        <!-- error-check, since author-supplied could be wild -->
        <xsl:choose>
            <xsl:when test="substring-before($the-width, '%') &lt; 0">
                <xsl:message>MBX:ERROR:   panel width ("<xsl:value-of select="$the-width" />") in a &lt;sidebyside&gt; or &lt;sbsgroup&gt; is negative (this may be computed, check "@margin(s)" and "@width(s)")</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
            <xsl:when test="substring-before($the-width, '%') &gt; 100">
                <xsl:message>MBX:ERROR:   panel width ("<xsl:value-of select="$the-width" />") in a &lt;sidebyside&gt; or &lt;sbsgroup&gt; is bigger than 100% (this may be computed, check "@margin(s)" and "@width(s)")</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:when>
        </xsl:choose>
        <!-- output element -->
        <width>
            <xsl:value-of select="$the-width" />
        </width>
        <!-- recurse on trailing -->
        <xsl:call-template name="decompose-widths">
            <xsl:with-param name="widths" select="substring-after($widths, ' ')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- recursive template to sum percentages         -->
<!-- input: a space-separated list, with %'s'      -->
<!-- NB: expect trailing space as sentinel for end -->
<!-- Output: total, without %, -common use only    -->
<xsl:template name="sum-percentages">
    <xsl:param name="percent-list" />
    <xsl:param name="sum" />
    <xsl:choose>
        <xsl:when test="$percent-list = ''">
            <xsl:value-of select="$sum" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="sum-percentages">
                <xsl:with-param name="percent-list" select="substring-after($percent-list, ' ')" />
                <xsl:with-param name="sum" select="$sum + substring-before($percent-list, '%')" />
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ######################## -->
<!-- SideBySide Main Template -->
<!-- ######################## -->

<xsl:template match="sidebyside">
    <xsl:param name="b-original" select="true()" />

    <xsl:variable name="rtf-layout">
        <xsl:apply-templates select="." mode="layout-parameters" />
    </xsl:variable>
    <xsl:variable name="layout" select="exsl:node-set($rtf-layout)" />

    <!-- local names of objects? -->
    <!-- below useful for debugging, worth keeping for a while, 2017-07 -->
    <!--
    <xsl:message>N:<xsl:value-of select="$layout/number-panels" />:N</xsl:message>
    <xsl:message>
        <xsl:text>VA:</xsl:text>
        <xsl:for-each select="$layout/valign">
            <xsl:value-of select="." />
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:text>:VA</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>W:</xsl:text>
        <xsl:for-each select="$layout/width">
            <xsl:value-of select="." />
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <xsl:text>:W</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>M:</xsl:text>
        <xsl:value-of select="$layout/margins" />
        <xsl:text>:M</xsl:text>
    </xsl:message>
    <xsl:message>
        <xsl:text>SW:</xsl:text>
        <xsl:value-of select="$layout/space-width" />
        <xsl:text>:SW</xsl:text>
    </xsl:message>
    <xsl:message>~~~~~~~~~~~~~~~~~~~~</xsl:message>
     -->

    <!-- "paragraphs" deprecated within sidebyside, 2018-05-02 -->
    <!-- jsxgraph deprecated?  Check                           -->

     <xsl:variable name="panels" select="p|pre|ol|ul|dl|program|console|poem|audio|video|interactive|slate|exercise|image|figure|table|listing|list|tabular|stack|jsxgraph|paragraphs" />

    <!-- We build up lists of various parts of a panel      -->
    <!-- It has setup (LaTeX), headings (titles), panels,   -->
    <!-- and captions.  These then go to "compose-panels".  -->
    <!-- Implementations need to define modal templates     -->
    <!--   panel-heading, panel-panel, panel-caption        -->
    <!-- The parameters passed to each is the union of what -->
    <!-- is needed for LaTeX and HTML implementations.      -->
    <!-- Final results are collectively sent to modal       -->
    <!--   compose-panels                                   -->
    <!-- template to be arranged                            -->
    <!-- TODO: Instead we could pass the $layout to the four,    -->
    <!-- and infer the $panel-number in the receiving templates. -->

    <xsl:variable name="panel-panels">
        <xsl:for-each select="$panels">
            <!-- context is now a particular panel -->
            <xsl:variable name="panel-number" select="count(preceding-sibling::*) + 1" />
            <xsl:apply-templates select="." mode="panel-panel">
                <xsl:with-param name="b-original" select="$b-original" />
                <xsl:with-param name="width" select="$layout/width[$panel-number]" />
                <xsl:with-param name="left-margin" select="$layout/left-margin" />
                <xsl:with-param name="right-margin" select="$layout/right-margin" />
                <xsl:with-param name="valign" select="$layout/valign[$panel-number]" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:variable>

    <!-- now collect components into output wrappers -->
    <xsl:apply-templates select="." mode="compose-panels">
        <xsl:with-param name="b-original" select="$b-original" />

        <xsl:with-param name="layout" select="$layout" />
        <xsl:with-param name="panels" select="$panel-panels" />
    </xsl:apply-templates>
</xsl:template>

<!-- ########################################### -->
<!-- Side-By-Side Group (sbsgroup) main template -->
<!-- ########################################### -->

<!-- A side-by-side group ("sbsgroup") is a wrapper    -->
<!-- around a sequence of "sidebyside".  It provides   -->
<!-- a place to specify common parameters for several  -->
<!-- side-by-side, for uniformity.  Also sub-captions  -->
<!-- should respect the grouping.  It is as pure a     -->
<!-- container as there can be.  Output is to just     -->
<!-- pile them up vertically.  Note, layout parameters -->
<!-- on enclosed "sidebyside" take precedence, and     -->
<!-- it is the layout template for each sidebyside     -->
<!-- that goes out to the enclosing group to get them  -->

<xsl:template match="sbsgroup">
    <xsl:apply-templates select="sidebyside" />
</xsl:template>

<!-- Since stackable items do not carry titles or captions,   -->
<!-- their templates do the right thing.  Items that normally -->
<!-- could go nline within a paragraph without any spacing    -->
<!-- will be preceded by a \par in their LaTeX representation -->
<!-- to get them onto a line of their own                     -->
<!-- 2019-06-28: parameters only consumed by HTML templates   -->
<xsl:template match="sidebyside/stack">
    <xsl:param name="b-original" select="true()" />
    <xsl:param name="width" />

    <xsl:apply-templates select="tabular|image|p|pre|ol|ul|dl|audio|video|interactive|slate|program|console|exercise">
        <xsl:with-param name="b-original" select="$b-original" />
        <xsl:with-param name="width" select="$width"/>
    </xsl:apply-templates>
</xsl:template>

<!-- ############## -->
<!-- List Utilities -->
<!-- ############## -->

<!-- A list item may be:                                        -->
<!--   * unstructured, like a sentence of a "p"                 -->
<!--   * structured into paragraphs, sublists, etc.             -->
<!-- For the first, we cannot automatically strip space         -->
<!-- To be flexible about the second, we kill interstitial text -->
<xsl:template match="li[p|ol|ul|dl]/text()">
    <xsl:variable name="text" select="normalize-space(.)" />
    <xsl:if test="$text">
        <xsl:message>MBX:WARNING: Unstructured content within a list item is being ignored ("<xsl:value-of select="$text" />")</xsl:message>
         <xsl:apply-templates select=".." mode="location-report" />
    </xsl:if>
</xsl:template>

<!-- List Levels -->
<!-- Utility templates to determine the depth      -->
<!-- of a list, relative to nesting in other lists -->

<!-- We determine the depth of an unordered     -->
<!-- list, relative only to other unordered     -->
<!-- lists in a nesting, so as to determine     -->
<!-- the right label to apply, esp. as defaults -->
<!-- The recursive template should be called    -->
<!-- without a level, since it defaults to zero -->
<xsl:template match="ul" mode="unordered-list-level">
    <!-- Start with level zero, and increment on successive calls -->
    <xsl:param name="level" select="0"/>
    <xsl:choose>
        <!-- Another unordered list above, add one and recurse -->
        <xsl:when test="ancestor::ul">
            <xsl:apply-templates select="ancestor::ul[1]" mode="unordered-list-level">
                <xsl:with-param name="level" select="$level + 1" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- No unordered list above, done, so return level -->
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Ordered lists follow the same strategy,           -->
<!-- except we implement exercises and references      -->
<!-- elements as ordered lists, so we need to absorb   -->
<!-- them into the general treatment of nested lists   -->
<!-- They do only occur as top-level elements, so that -->
<!-- assumption allows for some economy                -->
<xsl:template match="ol" mode="ordered-list-level">
    <xsl:param name="level" select="0"/>
    <xsl:choose>
        <!-- Since exercises divisions and references are top-level -->
        <!-- ordered lists, when these are the only interesting     -->
        <!-- ancestor, we add one to the level and return           -->
        <xsl:when test="(ancestor::exercises or ancestor::worksheet or ancestor::reading-questions or ancestor::references) and not(ancestor::ol)">
            <xsl:value-of select="$level + 1" />
        </xsl:when>
        <xsl:when test="ancestor::ol">
            <xsl:apply-templates select="ancestor::ol[1]" mode="ordered-list-level">
                <xsl:with-param name="level" select="$level + 1" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Exercises and References are        -->
<!-- specialized top-level ordered lists -->
<xsl:template match="exercises|worksheet|reading-questions|references" mode="ordered-list-level">
    <xsl:value-of select="0" />
</xsl:template>

<!-- To indent properly in markdown, we  -->
<!-- need to count every type of list    -->
<xsl:template match="*" mode="list-level">
    <xsl:param name="level" select="0" />
    <xsl:choose>
        <xsl:when test="ancestor-or-self::ol or ancestor-or-self::ul or ancestor-or-self::dl">
            <xsl:choose>
                <!-- at a node to count -->
                <xsl:when test="self::ol or self::ul or self::dl">
                    <xsl:apply-templates select="parent::*" mode="list-level">
                        <xsl:with-param name="level" select="$level + 1" />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- go up a level w/out incrementing-->
                <xsl:otherwise>
                    <xsl:apply-templates select="parent::*" mode="list-level">
                        <xsl:with-param name="level" select="$level" />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- now done, report level -->
        <xsl:otherwise>
            <xsl:value-of select="$level" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Labels of ordered lists have formatting codes, which  -->
<!-- we detect here and pass on to other more specialized  -->
<!-- templates for implementation specifics                -->
<!-- In order: Arabic (0-based), Arabic (1-based)          -->
<!-- lower-case Latin, upper-case Latin,                   -->
<!-- lower-case Roman numeral, upper-case Roman numeral    -->
<!-- Absent a label attribute, defaults go 4 levels deep   -->
<!-- (max for Latex) as: Arabic, lower-case Latin,         -->
<!-- lower-case Roman numeral, upper-case Latin            -->
<xsl:template match="ol" mode="format-code">
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:choose>
                <xsl:when test="contains(@label,'0')">0</xsl:when>
                <xsl:when test="contains(@label,'1')">1</xsl:when>
                <xsl:when test="contains(@label,'a')">a</xsl:when>
                <xsl:when test="contains(@label,'A')">A</xsl:when>
                <xsl:when test="contains(@label,'i')">i</xsl:when>
                <xsl:when test="contains(@label,'I')">I</xsl:when>
                <!-- DEPRECATED 2015-12-12 -->
                <xsl:when test="@label=''" />
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: ordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="level">
                <xsl:apply-templates select="." mode="ordered-list-level" />
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$level='0'">1</xsl:when>
                <xsl:when test="$level='1'">a</xsl:when>
                <xsl:when test="$level='2'">i</xsl:when>
                <xsl:when test="$level='3'">A</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: ordered list is more than 4 levels deep (at level <xsl:value-of select="$level" />) or is inside an "exercise" and is more than 3 levels deep  (at level <xsl:value-of select="$level - 1" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Labels of unordered list have formatting codes, which -->
<!-- we detect here and pass on to other more specialized  -->
<!-- templates for implementation specifics                -->
<!-- disc, circle, square or blank are the options         -->
<!-- Default order: disc, circle, square, disc             -->
<xsl:template match="ul" mode="format-code">
    <xsl:choose>
        <xsl:when test="@label">
            <xsl:choose>
                <xsl:when test="@label='disc'">disc</xsl:when>
                <xsl:when test="@label='circle'">circle</xsl:when>
                <xsl:when test="@label='square'">square</xsl:when>
                <xsl:when test="@label=''">none</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: unordered list label (<xsl:value-of select="@label" />) not recognized</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:variable name="level">
                <xsl:apply-templates select="." mode="unordered-list-level" />
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$level='0'">disc</xsl:when>
                <xsl:when test="$level='1'">circle</xsl:when>
                <xsl:when test="$level='2'">square</xsl:when>
                <xsl:when test="$level='3'">disc</xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:ERROR: unordered list is more than 4 levels deep (at level <xsl:value-of select="$level" />)</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- CSS class for multi-column lists -->
<!-- Context is element with potential "cols" attribute -->
<!-- Return value is "colsN" with 2 <= N <= 6           -->
<!-- @cols absent produces no result (i.e. classless)   -->
<!-- @cols = 1 produces no result (i.e. classless)      -->
<!-- Error message if out-of-range, could be made fatal -->
<!-- Schema should enforce this restriction also        -->
<xsl:template match="ol|ul|exercisegroup" mode="number-cols-CSS-class">
    <xsl:choose>
        <xsl:when test="not(@cols)"/>
        <xsl:when test="@cols = 1"/>
        <xsl:when test="(@cols = 2) or (@cols = 3) or (@cols = 4) or (@cols = 5) or (@cols = 6)">
            <xsl:text>cols</xsl:text>
            <xsl:value-of select="@cols" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:ERROR:   @cols attribute of lists or exercise groups, must be between 1 and 6 (inclusive), not "cols=<xsl:value-of select="@cols" />"</xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################## -->
<!-- Exercise Utilities -->
<!-- ################## -->

<!-- Exercises, projects and tasks, generally have "statement",    -->
<!-- "hint", "answer", and "solution".  Switches control           -->
<!-- appearance in the main matter and in solution lists.          -->
<!--                                                               -->
<!-- But they are surrounded by infrastructure:  number and title, -->
<!-- exercise group with introduction and conclusion, division     -->
<!-- headings.  If switches make all the content disappear within  -->
<!-- some infrastructure, then the infrastructure becomes          -->
<!-- superfluous.  So we provide a hierarchy of templates to       -->
<!-- determine if structure and content yield output.              -->

<!-- Bottom-up, a "traditional" exercise is clearest, so first.   -->
<!-- Strategy is to produce non-empty output if the item would    -->
<!-- normally produce some *real* output.                         -->

<!-- "exercise", not WeBWorK or MyOpenMath, plus project-like. -->
<!-- Easiest to switch on structured by task, or simpler       -->
<!-- "traditional" exercise.                                   -->

<xsl:template match="exercise[not(webwork-reps or myopenmath)]|&PROJECT-LIKE;" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:variable name="admitted">
        <xsl:apply-templates select="." mode="determine-admission">
            <xsl:with-param name="admit" select="$admit"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="b-admitted" select="boolean($admitted = 'yes')"/>

    <xsl:choose>
        <!-- return nothing if not admitted -->
        <xsl:when test="not($b-admitted)"/>
        <!-- recurse down into "task" via two templates above -->
        <xsl:when test="task">
            <xsl:apply-templates select="task" mode="dry-run">
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- simple "traditional" exercise -->
        <xsl:otherwise>
            <xsl:if test="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)">
                <xsl:text>X</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- We explicitly burrow down into tasks, since when we produce -->
<!-- the solutions, the labels on the tasks are infrastructure   -->
<!-- and we need the precision of knowing just which "task"      -->
<!-- harbor solutions (and which do not).                        -->

<!-- terminal (leaf) tasks -->
<xsl:template match="task[not(task)]" mode="dry-run">
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:if test="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)">
        <xsl:text>X</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Simply pass through intermediate task since they  -->
<!-- cannot harbor solutions (says schema) -->
<xsl:template match="task[task]" mode="dry-run">
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="task" mode="dry-run">
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- WeBWorK are exceptional.  We use the "webwork-reps" element -->
<!-- added by the assembly routine to examine "static" for the   -->
<!-- indication of existence of solutions - even if the problem  -->
 <!-- is "live" in interactive output.  Note that "stage" is     -->
 <!-- similar to "task" above, we need to carefully burrow down  -->
 <!-- into them to get indications of infrastructure when        -->
 <!-- producing output.                                          -->

<!-- WeBWorK exercise, structured by stages or not -->
<xsl:template match="exercise[webwork-reps]" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:variable name="admitted">
        <xsl:apply-templates select="." mode="determine-admission">
            <xsl:with-param name="admit" select="$admit"/>
        </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="b-admitted" select="boolean($admitted = 'yes')"/>

    <xsl:choose>
        <!-- return nothing if not admitted -->
        <xsl:when test="not($b-admitted)"/>
        <xsl:when test="webwork-reps/static/stage">
            <xsl:apply-templates select="webwork-reps/static/stage" mode="dry-run">
                <xsl:with-param name="b-has-statement" select="$b-has-statement" />
                <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
                <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
                <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <xsl:if test="$b-has-statement or ($b-has-hint and webwork-reps/static/hint) or ($b-has-answer and webwork-reps/static/answer) or ($b-has-solution and webwork-reps/static/solution)">
                <xsl:text>X</xsl:text>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- webwork stage is like a problem by itself-->
<xsl:template match="exercise/webwork-reps/static/stage" mode="dry-run">
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:if test="$b-has-statement or ($b-has-hint and hint) or ($b-has-answer and answer) or ($b-has-solution and solution)">
        <xsl:text>X</xsl:text>
    </xsl:if>
</xsl:template>

<!-- 2020-08-31: MyOpenMath is not really implemented fully, this is a -->
<!-- marker that will just prevent thse problems from appearing at all -->
<xsl:template match="exercise[myopenmath]" mode="dry-run"/>


<!-- Now we can tell is a given exercise (or project-like) will -->
<!-- generate some solutions, relative to the various switches  -->
<!-- in play.  So we now decide if various bits of surrounding  -->
<!-- infrastructure need repeating, since they do, or do not,   -->
<!-- contain exercises which will produce solutions.            -->


<!-- An "exercisegroup" potentially has an "introduction"  -->
<!-- and "conclusion" as infrastructure, and can only      -->
<!-- contain divisional "exercise" as varying items        -->
<!-- In a way, this is like an "exercise", it has content  -->
<!-- that is like a "statement", so a "dry-run" is checked -->
<!-- before outputting its introduction/conclusion         -->
<xsl:template match="exercisegroup" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- A "subexercises" potentially has an "introduction"    -->
<!-- and "conclusion" as infrastructure, and can only      -->
<!-- contain divisional "exercise" as varying items        -->
<!-- in addition to possible "exercisegroup"               -->
<!-- In a way, this is like an "exercisegroup", it has     -->
<!-- content that is like a "statement", so a "dry-run" is -->
<!-- checked before outputting its introduction/conclusion -->
<xsl:template match="subexercises" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-has-statement" />
    <xsl:param name="b-has-hint" />
    <xsl:param name="b-has-answer" />
    <xsl:param name="b-has-solution" />

    <xsl:apply-templates select="exercise|exercisegroup" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-has-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-has-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-has-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-has-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- Now specialized divisions that can hold "exercise".  These      -->
<!-- typically receive many parameters (~20) but only react/consider -->
<!-- the ones relevant to the type of division being investigated.   -->

<xsl:template match="exercises" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-divisional-statement" />
    <xsl:param name="b-divisional-hint" />
    <xsl:param name="b-divisional-answer" />
    <xsl:param name="b-divisional-solution" />

    <xsl:apply-templates select=".//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="worksheet" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-worksheet-statement" />
    <xsl:param name="b-worksheet-hint" />
    <xsl:param name="b-worksheet-answer" />
    <xsl:param name="b-worksheet-solution" />

    <xsl:apply-templates select=".//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-worksheet-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-worksheet-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-worksheet-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-worksheet-solution" />
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="reading-questions" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-reading-statement" />
    <xsl:param name="b-reading-hint" />
    <xsl:param name="b-reading-answer" />
    <xsl:param name="b-reading-solution" />

    <xsl:apply-templates select="exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-reading-statement" />
        <xsl:with-param name="b-has-hint"      select="$b-reading-hint" />
        <xsl:with-param name="b-has-answer"    select="$b-reading-answer" />
        <xsl:with-param name="b-has-solution"  select="$b-reading-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- An arbitrary division will have a heading as infrastructure.     -->
<!-- We drill down into the division at any depth looking for objects -->
<!-- based on the switches that control them.  This means we do not   -->
<!-- have to examine all possible subdivisions, both traditional      -->
<!-- and specialized.  Instead, we just pass through them.  But we do -->
<!-- need to be careful about sort of division is being considered    -->
<!-- and what switches are passed along.                              -->
<xsl:template match="part|chapter|section|subsection|subsubsection" mode="dry-run">
    <xsl:param name="admit"/>
    <xsl:param name="b-inline-statement" />
    <xsl:param name="b-inline-answer" />
    <xsl:param name="b-inline-hint" />
    <xsl:param name="b-inline-solution" />
    <xsl:param name="b-divisional-statement" />
    <xsl:param name="b-divisional-answer" />
    <xsl:param name="b-divisional-hint" />
    <xsl:param name="b-divisional-solution" />
    <xsl:param name="b-worksheet-statement" />
    <xsl:param name="b-worksheet-answer" />
    <xsl:param name="b-worksheet-hint" />
    <xsl:param name="b-worksheet-solution" />
    <xsl:param name="b-reading-statement" />
    <xsl:param name="b-reading-answer" />
    <xsl:param name="b-reading-hint" />
    <xsl:param name="b-reading-solution" />
    <xsl:param name="b-project-statement" />
    <xsl:param name="b-project-answer" />
    <xsl:param name="b-project-hint" />
    <xsl:param name="b-project-solution" />

    <xsl:apply-templates select=".//exercise[boolean(&INLINE-EXERCISE-FILTER;)]" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-inline-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-inline-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-inline-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-inline-solution" />
    </xsl:apply-templates>
    <xsl:apply-templates select=".//exercises//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
    </xsl:apply-templates>
    <xsl:apply-templates select=".//worksheet//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-worksheet-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-worksheet-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-worksheet-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-worksheet-solution" />
    </xsl:apply-templates>
    <xsl:apply-templates select=".//reading-questions//exercise" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-reading-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-reading-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-reading-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-reading-solution" />
    </xsl:apply-templates>
    <!-- &PROJECT-LIKE; "project|activity|exploration|investigation"> -->
    <xsl:apply-templates select=".//project|.//activity|.//exploration|.//investigation" mode="dry-run">
        <xsl:with-param name="admit"           select="$admit"/>
        <xsl:with-param name="b-has-statement" select="$b-project-statement" />
        <xsl:with-param name="b-has-answer"    select="$b-project-answer" />
        <xsl:with-param name="b-has-hint"      select="$b-project-hint" />
        <xsl:with-param name="b-has-solution"  select="$b-project-solution" />
    </xsl:apply-templates>
</xsl:template>

<!-- ####################################### -->
<!-- Solutions Divisions, Content Generation -->
<!-- ####################################### -->

<!-- A light wrapper around the "solutions-generator" template (next). -->
<!-- We just examine the attributes describing a "solutions" division. -->
<!-- The division is one-off (not knowled), so we treat the            -->
<!-- introduction and conclusion as original                           -->
<xsl:template match="solutions" mode="solutions">
    <xsl:param name="heading-level"/>

    <!-- A "solutions" division may exist in the main matter  -->
    <!-- or the back matter.  When we generate a solution, we -->
    <!-- want to know which kind it is, so it can be labeled  -->
    <!-- so that a forward-reference is accurate.             -->
    <xsl:variable name="purpose">
        <xsl:choose>
            <xsl:when test="parent::backmatter">
                <xsl:text>backmatter</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>mainmatter</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- A "solutions" may have an @admit that indicates a subset -->
    <!-- of which exercises to admit. The default is 'all'        -->
    <xsl:variable name="admit">
        <xsl:choose>
            <xsl:when test="@admit">
                <xsl:value-of select="@admit"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>all</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:apply-templates select="introduction">
        <xsl:with-param name="b-original" select="true()" />
    </xsl:apply-templates>
    <!-- We call the solutions-generator one of two ways, either by     -->
    <!-- looking up a level, to the parent (jumping over "backmatter")  -->
    <!-- or by respecting a @scope attribute that specifies the parent. -->
    <!-- The "call" is identical, only the @select is different.        -->
    <!-- (Maybe there is a better way to use just one call?)            -->

    <xsl:choose>
        <xsl:when test="@scope">
            <!-- First check that the scope is reasonable, i.e. it -->
            <!-- exists and is one of the elements defined for the -->
            <!-- "solutions-generator" template                    -->
            <xsl:variable name="scope" select="id(@scope)"/>

            <xsl:if test="not(exsl:node-set($scope))">
                <xsl:message>PTX:WARNING: unresolved @scope ("<xsl:value-of select="@scope"/>") for a &lt;solutions&gt; division</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
            <xsl:if test="not($scope/self::book|$scope/self::article|$scope/self::chapter|$scope/self::section|$scope/self::subsection|$scope/self::subsubsection|$scope/self::exercises|$scope/self::worksheet|$scope/self::reading-questions)">
                <xsl:message>PTX:ERROR: the @scope ("<xsl:value-of select="@scope"/>") of a &lt;solutions&gt; division is not a supported division.  If you think your attempt is reasonable, please make a feature request.  Results now will be unpredictable</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>

            <xsl:apply-templates select="$scope" mode="solutions-generator">
                <xsl:with-param name="purpose" select="$purpose" />
                <xsl:with-param name="admit"   select="$admit"/>
                <xsl:with-param name="heading-level" select="$heading-level"/>
                <xsl:with-param name="b-inline-statement"     select="contains(@inline,     'statement')" />
                <xsl:with-param name="b-inline-hint"          select="contains(@inline,     'hint')"      />
                <xsl:with-param name="b-inline-answer"        select="contains(@inline,     'answer')"    />
                <xsl:with-param name="b-inline-solution"      select="contains(@inline,     'solution')"  />
                <xsl:with-param name="b-divisional-statement" select="contains(@divisional, 'statement')" />
                <xsl:with-param name="b-divisional-hint"      select="contains(@divisional, 'hint')"      />
                <xsl:with-param name="b-divisional-answer"    select="contains(@divisional, 'answer')"    />
                <xsl:with-param name="b-divisional-solution"  select="contains(@divisional, 'solution')"  />
                <xsl:with-param name="b-worksheet-statement"  select="contains(@worksheet,  'statement')" />
                <xsl:with-param name="b-worksheet-hint"       select="contains(@worksheet,  'hint')"      />
                <xsl:with-param name="b-worksheet-answer"     select="contains(@worksheet,  'answer')"    />
                <xsl:with-param name="b-worksheet-solution"   select="contains(@worksheet,  'solution')"  />
                <xsl:with-param name="b-reading-statement"    select="contains(@reading,    'statement')" />
                <xsl:with-param name="b-reading-hint"         select="contains(@reading,    'hint')"      />
                <xsl:with-param name="b-reading-answer"       select="contains(@reading,    'answer')"    />
                <xsl:with-param name="b-reading-solution"     select="contains(@reading,    'solution')"  />
                <xsl:with-param name="b-project-statement"    select="contains(@project,    'statement')" />
                <xsl:with-param name="b-project-hint"         select="contains(@project,    'hint')"      />
                <xsl:with-param name="b-project-answer"       select="contains(@project,    'answer')"    />
                <xsl:with-param name="b-project-solution"     select="contains(@project,    'solution')"  />
            </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
            <!-- the default scope, first ancestor -->
            <xsl:apply-templates select="ancestor::*[not(self::backmatter)][1]" mode="solutions-generator">
                <xsl:with-param name="purpose" select="$purpose" />
                <xsl:with-param name="admit"   select="$admit"/>
                <xsl:with-param name="heading-level" select="$heading-level"/>
                <xsl:with-param name="b-inline-statement"     select="contains(@inline,     'statement')" />
                <xsl:with-param name="b-inline-hint"          select="contains(@inline,     'hint')"      />
                <xsl:with-param name="b-inline-answer"        select="contains(@inline,     'answer')"    />
                <xsl:with-param name="b-inline-solution"      select="contains(@inline,     'solution')"  />
                <xsl:with-param name="b-divisional-statement" select="contains(@divisional, 'statement')" />
                <xsl:with-param name="b-divisional-hint"      select="contains(@divisional, 'hint')"      />
                <xsl:with-param name="b-divisional-answer"    select="contains(@divisional, 'answer')"    />
                <xsl:with-param name="b-divisional-solution"  select="contains(@divisional, 'solution')"  />
                <xsl:with-param name="b-worksheet-statement"  select="contains(@worksheet,  'statement')" />
                <xsl:with-param name="b-worksheet-hint"       select="contains(@worksheet,  'hint')"      />
                <xsl:with-param name="b-worksheet-answer"     select="contains(@worksheet,  'answer')"    />
                <xsl:with-param name="b-worksheet-solution"   select="contains(@worksheet,  'solution')"  />
                <xsl:with-param name="b-reading-statement"    select="contains(@reading,    'statement')" />
                <xsl:with-param name="b-reading-hint"         select="contains(@reading,    'hint')"      />
                <xsl:with-param name="b-reading-answer"       select="contains(@reading,    'answer')"    />
                <xsl:with-param name="b-reading-solution"     select="contains(@reading,    'solution')"  />
                <xsl:with-param name="b-project-statement"    select="contains(@project,    'statement')" />
                <xsl:with-param name="b-project-hint"         select="contains(@project,    'hint')"      />
                <xsl:with-param name="b-project-answer"       select="contains(@project,    'answer')"    />
                <xsl:with-param name="b-project-solution"     select="contains(@project,    'solution')"  />
            </xsl:apply-templates>
        </xsl:otherwise>
    </xsl:choose>


    <xsl:apply-templates select="conclusion">
        <xsl:with-param name="b-original" select="true()" />
    </xsl:apply-templates>
</xsl:template>

<!-- Determine whether an exercise should be admitted, given its serial -->
<!-- number and some specification for what should be admitted.         -->
<xsl:template match="exercise|&PROJECT-LIKE;" mode="determine-admission">
    <xsl:param name="admit"/>
    <xsl:variable name="serial-number">
        <xsl:apply-templates select="." mode="serial-number"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="($admit='odd') and ($serial-number mod 2 = 1)">
            <xsl:value-of select="'yes'"/>
        </xsl:when>
        <xsl:when test="($admit='even') and ($serial-number mod 2 = 0)">
            <xsl:value-of select="'yes'"/>
        </xsl:when>
        <xsl:when test="$admit='all'">
            <xsl:value-of select="'yes'"/>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- Solutions Generator -->

<!-- Context is the originally the scope (root of subtree examined)      -->
<!-- and is meant to be a "traditional" division, as expressed in        -->
<!-- the schema.  However, on recusion context can be any division       -->
<!-- containing exercises, such as "worksheet".  We do not allow a       -->
<!-- "solutions" division to live inside a "part", so in the default     -->
<!-- use a part is not the context.  This is all to explain that         -->
<!-- the match is more expansive than first use, in practice.            -->
<!--                                                                     -->
<!-- On first call, the placing division should have a descriptive       -->
<!-- title from the author, such as "Solutions to Chapter Exercises",    -->
<!-- when placed at the level of a section (and assuming default scope). -->
<!-- So the "b-has-heading" should default to false, *and should not     -->
<!-- be overridden*.  Recursive calls will set this variable to true,    -->
<!-- and then there will be sectioning of the solutions.                 -->
<!--                                                                     -->
<!-- Similarly, "scope" is set to the context on first call, then        -->
<!-- replicated/preserved/remembered in recursive calls, so do not       -->
<!-- pass in a different value.                                          -->
<!--                                                                     -->
<!-- NB: this template is used/called directly by the                    -->
<!-- "solution-manual-latex.xsl" stylesheet, so coordinate               -->
<!-- changes here with usage there.                                      -->

<xsl:template match="book|article|part|chapter|section|subsection|subsubsection|exercises|worksheet|reading-questions" mode="solutions-generator">
    <xsl:param name="purpose"/>
    <xsl:param name="admit"/>
    <xsl:param name="heading-level"/>
    <xsl:param name="b-has-heading" select="false()"/>
    <xsl:param name="scope" select="."/>
    <xsl:param name="b-inline-statement"     />
    <xsl:param name="b-inline-hint"          />
    <xsl:param name="b-inline-answer"        />
    <xsl:param name="b-inline-solution"      />
    <xsl:param name="b-divisional-statement" />
    <xsl:param name="b-divisional-hint"      />
    <xsl:param name="b-divisional-answer"    />
    <xsl:param name="b-divisional-solution"  />
    <xsl:param name="b-worksheet-statement"  />
    <xsl:param name="b-worksheet-hint"       />
    <xsl:param name="b-worksheet-answer"     />
    <xsl:param name="b-worksheet-solution"   />
    <xsl:param name="b-reading-statement"    />
    <xsl:param name="b-reading-hint"         />
    <xsl:param name="b-reading-answer"       />
    <xsl:param name="b-reading-solution"     />
    <xsl:param name="b-project-statement"    />
    <xsl:param name="b-project-hint"         />
    <xsl:param name="b-project-answer"       />
    <xsl:param name="b-project-solution"     />

    <!-- See if division has *any* content, at any depth, in light of switches. -->
    <!-- Traditional divisions expect many switches, while specialized          -->
    <!-- divisions expect a limited subset                                      -->
    <xsl:variable name="dry-run">
        <xsl:apply-templates select="." mode="dry-run">
            <xsl:with-param name="admit"                  select="$admit"/>
            <xsl:with-param name="b-inline-statement"     select="$b-inline-statement" />
            <xsl:with-param name="b-inline-answer"        select="$b-inline-answer" />
            <xsl:with-param name="b-inline-hint"          select="$b-inline-hint" />
            <xsl:with-param name="b-inline-solution"      select="$b-inline-solution" />
            <xsl:with-param name="b-divisional-statement" select="$b-divisional-statement" />
            <xsl:with-param name="b-divisional-answer"    select="$b-divisional-answer" />
            <xsl:with-param name="b-divisional-hint"      select="$b-divisional-hint" />
            <xsl:with-param name="b-divisional-solution"  select="$b-divisional-solution" />
            <xsl:with-param name="b-worksheet-statement"  select="$b-worksheet-statement" />
            <xsl:with-param name="b-worksheet-answer"     select="$b-worksheet-answer" />
            <xsl:with-param name="b-worksheet-hint"       select="$b-worksheet-hint" />
            <xsl:with-param name="b-worksheet-solution"   select="$b-worksheet-solution" />
            <xsl:with-param name="b-reading-statement"    select="$b-reading-statement" />
            <xsl:with-param name="b-reading-answer"       select="$b-reading-answer" />
            <xsl:with-param name="b-reading-hint"         select="$b-reading-hint" />
            <xsl:with-param name="b-reading-solution"     select="$b-worksheet-solution" />
            <xsl:with-param name="b-project-statement"    select="$b-project-statement" />
            <xsl:with-param name="b-project-answer"       select="$b-project-answer" />
            <xsl:with-param name="b-project-hint"         select="$b-project-hint" />
            <xsl:with-param name="b-project-solution"     select="$b-project-solution" />
        </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="not($dry-run = '')">
        <!-- We call the only real abstract template, it simply        -->
        <!-- provides the correct wrapping for a division appearing    -->
        <!-- to aid in organizing a collection of solutions.           -->
        <!--                                                           -->
        <!-- Context is a division: traditional, or specialized.       -->
        <!-- We want all "exercise" and "project", in document order,  -->
        <!-- without descending into subdivisions.  We handle          -->
        <!-- "exercisegroup" specially, since it has "statement"       -->
        <!-- characteristics.  In a traditional division, an inline    -->
        <!-- exercise can be inside a "paragraphs".  If we divide an   -->
        <!-- "exercises" division, we will need to explicitly burrow   -->
        <!-- down into it.  Finally, a "worksheet" can have "exercise" -->
        <!-- laid out via "sidebyside".                                -->
        <!-- The purpose is sent to the modal "solutions" templates    -->
        <!-- in order to generate accurate labels based on position    -->
        <!-- The "heading-level" is the same as the originating        -->
        <!-- "solutions" division on the first call here               -->

        <!-- But first, we see if just one type of component has been  -->
        <!-- requested, across the various types of "exercise".  The   -->
        <!-- point is to squelch a repetitive heading all through a    -->
        <!-- list of solutions, so we need to pass the condition on    -->
        <!-- through.                                                  -->
        <!-- NB: this gets recomputed as we recurse into subdivisions, -->
        <!-- but it must be awful fast, so we don't try to set some    -->
        <!-- flag indicating necessity of computing it.  But recognize -->
        <!-- we don't need to pass it in the recursive call below.     -->
        <!-- NB: this is different than the actual components selected -->
        <!-- all ending up as the same type in the output, because     -->
        <!-- some requested type never appears.                        -->

        <xsl:variable name="variety">
            <xsl:if test="$b-inline-statement or $b-divisional-statement or $b-worksheet-statement or $b-reading-statement or $b-project-statement">
                <xsl:text>T</xsl:text>
            </xsl:if>
            <xsl:if test="$b-inline-hint or $b-divisional-hint or $b-worksheet-hint or $b-reading-hint or $b-project-hint">
                <xsl:text>H</xsl:text>
            </xsl:if>
            <xsl:if test="$b-inline-answer or $b-divisional-answer or $b-worksheet-answer or $b-reading-answer or $b-project-answer">
                <xsl:text>A</xsl:text>
            </xsl:if>
            <xsl:if test="$b-inline-solution or $b-divisional-solution or $b-worksheet-solution or $b-reading-solution or $b-project-solution">
                <xsl:text>S</xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="b-component-heading" select="string-length($variety) &gt; 1"/>

        <xsl:apply-templates select="." mode="division-in-solutions">
            <xsl:with-param name="scope" select="$scope" />
            <xsl:with-param name="heading-level" select="$heading-level"/>
            <xsl:with-param name="b-has-heading" select="$b-has-heading"/>
            <xsl:with-param name="content">

                <xsl:for-each select="exercise|subexercises|exercisegroup|&PROJECT-LIKE;|paragraphs/exercise|self::worksheet//exercise">
                     <xsl:choose>
                        <xsl:when test="self::exercise and boolean(&INLINE-EXERCISE-FILTER;)">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose" />
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="b-has-statement" select="$b-inline-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-inline-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-inline-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-inline-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::subexercises|self::exercisegroup">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::exercise and ancestor::exercises">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="b-has-statement" select="$b-divisional-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-divisional-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-divisional-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-divisional-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::exercise and ancestor::worksheet">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="b-has-statement" select="$b-worksheet-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-worksheet-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-worksheet-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-worksheet-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::exercise and ancestor::reading-questions">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="b-has-statement" select="$b-reading-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-reading-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-reading-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-reading-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="&PROJECT-FILTER;">
                            <xsl:apply-templates select="." mode="solutions">
                                <xsl:with-param name="purpose" select="$purpose"/>
                                <xsl:with-param name="admit"   select="$admit"/>
                                <xsl:with-param name="b-component-heading" select="$b-component-heading"/>
                                <xsl:with-param name="b-has-statement" select="$b-project-statement" />
                                <xsl:with-param name="b-has-answer"    select="$b-project-answer" />
                                <xsl:with-param name="b-has-hint"      select="$b-project-hint" />
                                <xsl:with-param name="b-has-solution"  select="$b-project-solution" />
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:if>
    <!-- recurse into (sub)divisions which can contain exercises     -->
    <!-- On every recursion (not initial call) we request a heading  -->
    <!-- and we pass in the scope of original call for help deciding -->
    <!-- the level of headings given surroundings.                   -->
    <!-- This is recurrence, so increment $heading-level.            -->
    <!-- NB: $b-component-heading is recomputed, so is not passed    -->
    <xsl:apply-templates select="book|article|part|chapter|section|subsection|subsubsection|exercises|worksheet|reading-questions" mode="solutions-generator">
        <xsl:with-param name="purpose" select="$purpose" />
        <xsl:with-param name="admit"   select="$admit"/>
        <xsl:with-param name="heading-level" select="$heading-level + 1"/>
        <xsl:with-param name="b-has-heading" select="true()" />
        <xsl:with-param name="scope" select="$scope" />
        <xsl:with-param name="b-inline-statement"     select="$b-inline-statement" />
        <xsl:with-param name="b-inline-answer"        select="$b-inline-answer" />
        <xsl:with-param name="b-inline-hint"          select="$b-inline-hint" />
        <xsl:with-param name="b-inline-solution"      select="$b-inline-solution" />
        <xsl:with-param name="b-divisional-statement" select="$b-divisional-statement" />
        <xsl:with-param name="b-divisional-answer"    select="$b-divisional-answer" />
        <xsl:with-param name="b-divisional-hint"      select="$b-divisional-hint" />
        <xsl:with-param name="b-divisional-solution"  select="$b-divisional-solution" />
        <xsl:with-param name="b-worksheet-statement"  select="$b-worksheet-statement" />
        <xsl:with-param name="b-worksheet-answer"     select="$b-worksheet-answer" />
        <xsl:with-param name="b-worksheet-hint"       select="$b-worksheet-hint" />
        <xsl:with-param name="b-worksheet-solution"   select="$b-worksheet-solution" />
        <xsl:with-param name="b-reading-statement"    select="$b-reading-statement" />
        <xsl:with-param name="b-reading-answer"       select="$b-reading-answer" />
        <xsl:with-param name="b-reading-hint"         select="$b-reading-hint" />
        <xsl:with-param name="b-reading-solution"     select="$b-worksheet-solution" />
        <xsl:with-param name="b-project-statement"    select="$b-project-statement" />
        <xsl:with-param name="b-project-answer"       select="$b-project-answer" />
        <xsl:with-param name="b-project-hint"         select="$b-project-hint" />
        <xsl:with-param name="b-project-solution"     select="$b-project-solution" />
    </xsl:apply-templates>
</xsl:template>


<!-- ############### -->
<!-- Arbitrary Lists -->
<!-- ############### -->

<!-- Format-independent construction of a list of    -->
<!-- intermediate elements, in order of appearance,  -->
<!-- with headers from indicated divisions           -->
<!--                                                 -->
<!-- Implementation requires four abstract templates -->
<!--                                                 -->
<!-- 1.  name="list-of-begin"                        -->
<!-- hook for start of list                          -->
<!--                                                 -->
<!-- 2.  mode="list-of-header"                       -->
<!-- Format/output per division                      -->
<!--                                                 -->
<!-- 3.  mode="list-of-element"                      -->
<!-- Format/output per element                       -->
<!--                                                 -->
<!-- 4. name="list-of-end"                           -->
<!-- hook for end of list                            -->

<!-- NB: possible improvements -->
<!-- 1.  Get $subroot via @ref and work with element, not a string            -->
<!-- 2.  Somehow abandon user strings sooner, so less reliant on local-name() -->

<xsl:template match="list-of">
    <xsl:param name="heading-level"/>

    <!-- Ring-fence terms so matches are not mistaken substrings -->
    <xsl:variable name="elements">
        <xsl:text>|</xsl:text>
        <xsl:value-of select="str:replace(normalize-space(@elements), ' ', '|')" />
        <xsl:text>|</xsl:text>
    </xsl:variable>
    <xsl:variable name="divisions">
        <xsl:text>|</xsl:text>
        <xsl:value-of select="str:replace(normalize-space(@divisions), ' ', '|')" />
        <xsl:text>|</xsl:text>
    </xsl:variable>
    <!-- display subdivision headers with empty contents? -->
    <xsl:variable name="empty">
        <xsl:choose>
            <xsl:when test="not(@empty)">
                <xsl:text>no</xsl:text>
            </xsl:when>
            <!-- DTD should restrict to 'yes'|'no' -->
            <xsl:otherwise>
                <xsl:value-of select="@empty" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- root of the document subtree for list formation     -->
    <!-- defaults to document-wide                           -->
    <!-- DTD should enforce subdivisions as values for scope -->
    <!-- TODO: perhaps use @ref to indicate $subroot,  -->
    <!-- and protect against both a @scope and a @ref  -->
    <xsl:variable name="scope">
        <xsl:choose>
            <xsl:when test="not(@scope)">
                <xsl:choose>
                    <xsl:when test="$root/book"><xsl:text>book</xsl:text></xsl:when>
                    <xsl:when test="$root/article"><xsl:text>article</xsl:text></xsl:when>
                    <xsl:when test="$root/letter"><xsl:text>letter</xsl:text></xsl:when>
                    <xsl:when test="$root/memo"><xsl:text>memo</xsl:text></xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@scope" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="subroot" select="ancestor-or-self::*[local-name() = $scope]" />
    <!-- variable behavior set, now setup -->
    <xsl:call-template name="list-of-begin" />
    <!-- recursive procedure, starting from indicated scope -->
    <xsl:apply-templates select="$subroot" mode="list-of-content">
        <xsl:with-param name="heading-level" select="$heading-level"/>
        <xsl:with-param name="elements" select="$elements"/>
        <xsl:with-param name="divisions" select="$divisions"/>
        <xsl:with-param name="empty" select="$empty"/>
    </xsl:apply-templates>
    <xsl:call-template name="list-of-end" />
</xsl:template>

<xsl:template match="*" mode="list-of-content">
    <xsl:param name="heading-level"/>
    <xsl:param name="elements"/>
    <xsl:param name="divisions"/>
    <xsl:param name="empty"/>

    <!-- write a division header, perhaps              -->
    <!-- check if desired, check if empty and unwanted -->
    <xsl:if test="contains($divisions, concat(concat('|', local-name(.)), '|'))">
        <xsl:choose>
            <xsl:when test="$empty='no'">
                <!-- probe subtree, even if we found empty super-tree earlier -->
                <xsl:variable name="all-elements" select=".//*[contains($elements, concat(concat('|', local-name(.)), '|'))]" />
                <xsl:if test="$all-elements">
                    <xsl:apply-templates select="." mode="list-of-header">
                        <xsl:with-param name="heading-level" select="$heading-level"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$empty='yes'">
                <xsl:apply-templates select="." mode="list-of-header">
                    <xsl:with-param name="heading-level" select="$heading-level"/>
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
    </xsl:if>
    <!-- if a desired element, write out summary/link -->
    <xsl:if test="contains($elements, concat(concat('|', local-name(.)), '|'))='true'">
        <xsl:apply-templates select="." mode="list-of-element" />
    </xsl:if>
    <!-- recurse into children -->
    <!-- increment heading-level, correct right now for divisions -->
    <xsl:if test="*">
        <xsl:apply-templates select="*" mode="list-of-content">
            <xsl:with-param name="heading-level" select="$heading-level + 1"/>
            <xsl:with-param name="elements" select="$elements"/>
            <xsl:with-param name="divisions" select="$divisions"/>
            <xsl:with-param name="empty" select="$empty"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Stub implementations, with warnings -->
<xsl:template name="list-of-begin">
     <xsl:message>PTX:ERROR:   the "list-of-begin" template needs an implementation in the current conversion</xsl:message>
     <xsl:text>[[[BEGINLIST]]]</xsl:text>
 </xsl:template>

<xsl:template name="list-of-end">
     <xsl:message>PTX:ERROR:   the "list-of-end" template needs an implementation in the current conversion</xsl:message>
     <xsl:text>[[[ENDLIST]]]</xsl:text>
 </xsl:template>


<!-- Programming Language Names -->
<!-- Packages for listing and syntax highlighting             -->
<!-- have their own ideas about the names of languages        -->
<!-- We use keys to perform the translation                   -->
<!-- See: https://gist.github.com/frabad/4189876              -->
<!-- for motivation and document() syntax for standalone file -->
<!-- Also: see contributors in FCLA work                      -->

<!-- The data: attribute is our usage, elements belong to     -->
<!-- other packages. Blank means not explicitly supported.    -->
<!-- Alphabetical by type.                                    -->

<!-- Prism: -->
<!-- Last reviewed 2020-10-21                        -->
<!-- 2020-10-21: Cutover from Google Code Prettifier -->

<!-- Listings: -->
<!-- Last reviewed carefully: 2014/06/28           -->
<!-- Exact matches, or best guesses, some          -->
<!-- unimplemented.  [] notation is for variants.  -->
<!-- 2019-09-23: minor review, v 1.7 (2018-09-02)  -->

<!-- ActiveCode (Runestone) -->
<!-- Languages supported by Runestone ActiveCode   -->
<!-- interactive element, added 2020-08-13         -->

<!-- Our strings (@ptx) are always all-lowercase, no symbols, no punctuation -->
<mb:programming>
    <!-- Procedural -->
    <language ptx="basic"       active=""            listings="Basic"            prism="basic"/>
    <language ptx="c"           active="c"           listings="C"                prism="c"/>
    <language ptx="cpp"         active="cpp"         listings="C++"              prism="cpp"/>
    <language ptx="go"          active=""            listings="C"                prism="go"/>
    <language ptx="java"        active="java"        listings="Java"             prism="java"/>
    <language ptx="javascript"  active="javascript"  listings=""                 prism="javascript"/>
    <language ptx="lua"         active=""            listings="Lua"              prism="lua"/>
    <language ptx="pascal"      active=""            listings="Pascal"           prism="pascal"/>
    <language ptx="perl"        active=""            listings="Perl"             prism="perl"/>
    <language ptx="python"      active="python"      listings="Python"           prism="py"/>
    <language ptx="python2"     active="python2"     listings="Python"           prism="py"/>
    <language ptx="python3"     active="python3"     listings="Python"           prism="py"/>
    <language ptx="r"           active=""            listings="R"                prism="r"/>
    <language ptx="s"           active=""            listings="S"                prism="s"/>
    <language ptx="sas"         active=""            listings="SAS"              prism="s"/>
    <language ptx="sage"        active=""            listings="Python"           prism="py"/>
    <language ptx="splus"       active=""            listings="[Plus]S"          prism="s"/>
    <language ptx="vbasic"      active=""            listings="[Visual]Basic"    prism="visual-basic"/>
    <language ptx="vbscript"    active=""            listings="VBscript"         prism="visual-basic"/>
    <!-- Others (esp. functional)  -->
    <language ptx="clojure"     active=""            listings="Lisp"             prism="clojure"/>
    <language ptx="lisp"        active=""            listings="Lisp"             prism="lisp"/>
    <language ptx="clisp"       active=""            listings="Lisp"             prism="lisp"/>
    <language ptx="elisp"       active=""            listings="Lisp"             prism="elisp"/>
    <language ptx="scheme"      active=""            listings="Lisp"             prism="scheme"/>
    <language ptx="racket"      active=""            listings="Lisp"             prism="racket"/>
    <language ptx="sql"         active="sql"         listings="SQL"                 prism="sql"/>
    <language ptx="llvm"        active=""            listings="LLVM"             prism="llvm"/>
    <language ptx="matlab"      active="octave"      listings="Matlab"           prism="matlab"/>
    <language ptx="octave"      active="octave"      listings="Octave"           prism="matlab"/>
    <language ptx="ml"          active=""            listings="ML"               prism=""/>
    <language ptx="ocaml"       active=""            listings="[Objective]Caml"  prism="ocaml"/>
    <language ptx="fsharp"      active=""            listings="ML"               prism="fsharp"/>
    <!-- Text Manipulation -->
    <language ptx="css"         active=""            listings=""                 prism="css"/>
    <language ptx="latex"       active=""            listings="[LaTeX]TeX"       prism="latex"/>
    <language ptx="html"        active="html"        listings="HTML"             prism="html"/>
    <language ptx="tex"         active=""            listings="[plain]TeX"       prism="tex"/>
    <language ptx="xml"         active=""            listings="XML"              prism="xml"/>
    <language ptx="xslt"        active=""            listings="XSLT"             prism="xml"/>
</mb:programming>

<!-- Define the key for indexing into the data list -->
<xsl:key name="proglang" match="language" use="@ptx" />

<!-- A whole <program> node comes in,  -->
<!-- text of ActiveCode name comes out -->
<xsl:template match="*" mode="active-language">
    <xsl:variable name="language"><xsl:value-of select="@language" /></xsl:variable>
    <xsl:for-each select="document('')/*/mb:programming">
        <xsl:value-of select="key('proglang', $language)/@active" />
    </xsl:for-each>
</xsl:template>

<!-- A whole <program> node comes in,  -->
<!-- text of listings name comes out -->
<xsl:template match="*" mode="listings-language">
    <xsl:variable name="language"><xsl:value-of select="@language" /></xsl:variable>
    <xsl:for-each select="document('')/*/mb:programming">
        <xsl:value-of select="key('proglang', $language)/@listings" />
    </xsl:for-each>
</xsl:template>

<!-- A whole <program> node comes in,  -->
<!-- text of prism name comes out -->
<xsl:template match="*" mode="prism-language">
    <xsl:variable name="language"><xsl:value-of select="@language" /></xsl:variable>
    <xsl:for-each select="document('')/*/mb:programming">
        <xsl:value-of select="key('proglang', $language)/@prism" />
    </xsl:for-each>
</xsl:template>

<!-- This works, without keys, and could be adapted to range over actual data in text -->
<!-- For example, this approach is used for contributors to FCLA                      -->
<!--
<xsl:template match="*" mode="listings-language">
    <xsl:variable name="language"><xsl:value-of select="@language" /></xsl:variable>
    <xsl:value-of select="document('')/*/mb:programming/language[@ptx=$language]/listings"/>
</xsl:template>
-->

<!-- ############################ -->
<!-- Table construction utilities -->
<!-- ############################ -->

<!-- These templates provide frequently-used      -->
<!-- functions for the construction of tables.    -->
<!-- Document uses carefully when newly employed. -->

<!-- Translate thickness attribute value to integer short name -->
<!-- HTML: makes portion of CSS class names for cells          -->
<!-- PG: makes portion of optional parameter for DataTable     -->
<!-- macro from niceTable.pl for thickness of table cells      -->
<xsl:template name="thickness-specification">
    <xsl:param name="width" />
    <xsl:choose>
        <xsl:when test="$width='none'">
            <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:when test="$width='minor'">
            <xsl:text>1</xsl:text>
        </xsl:when>
        <xsl:when test="$width='medium'">
            <xsl:text>2</xsl:text>
        </xsl:when>
        <xsl:when test="$width='major'">
            <xsl:text>3</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular rule thickness not recognized: use none, minor, medium, major</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate horizontal alignment to CSS short name    -->
<!-- HTML:  makes portion of CSS class names for cells   -->
<!-- LaTeX: provides standard LaTeX horizontal alignment -->
<!-- PG: provide LaTeX-style alignment string for        -->
<!-- DataTable macro from niceTable.pl                   -->
<xsl:template name="halign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='left' or $align='justify'">
            <xsl:text>l</xsl:text>
        </xsl:when>
        <xsl:when test="$align='center'">
            <xsl:text>c</xsl:text>
        </xsl:when>
        <xsl:when test="$align='right'">
            <xsl:text>r</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular horizontal alignment attribute not recognized: use left, center, right, justify</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Translate vertical alignment to CSS short name         -->
<!-- HTML:  makes portion of CSS class names for cells      -->
<!-- LaTeX: provides one standard LaTeX vertical alignment  -->
<!-- PG: provide LaTeX-style alignment string for           -->
<!-- DataTable macro from niceTable.pl                      -->
<xsl:template name="valign-specification">
    <xsl:param name="align" />
    <xsl:choose>
        <xsl:when test="$align='top'">
            <xsl:text>t</xsl:text>
        </xsl:when>
        <xsl:when test="$align='middle'">
            <xsl:text>m</xsl:text>
        </xsl:when>
        <xsl:when test="$align='bottom'">
            <xsl:text>b</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:WARNING: tabular vertical alignment attribute not recognized: use top, middle, bottom</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ################### -->
<!-- Structured by Lines -->
<!-- ################### -->

<!-- Some items, such as an address or an attribution,          -->
<!-- can be formatted like a poem, as a sequence of lines,      -->
<!-- without really being able to say just why or how in        -->
<!-- advance via markup.  So the schema will allow an element   -->
<!-- to be a simple, single line of text, OR a sequence of      -->
<!-- "line" elements (only), each "line" being the same simple  -->
<!-- text.  Generally, all we need is an abstract separator for -->
<!-- the first n-1 lines.  What happens after the last line     -->
<!-- should be in agreement with the single line version.       -->


<!-- Allowed to be structured, and handled abstractly -->
<!--   * department (author, editor, etc.)            -->
<!--   * institution (author, editor, etc.)           -->
<!--   * dedication/p                                 -->
<!--   * attribution                                  -->
<!--   * cell (tabular/row/cell/line)                 -->
<!--                                                  -->
<!-- Specialized, handled specifically (ie not here)  -->
<!--   * poem/stanza/line                             -->
<!--   * letter/frontmatter/to/line (from) (LaTeX)    -->
<!--   * memo/frontmatter/to/line (from) (LaTeX)      -->

<!-- The markup, and visual source necessary for the  -->
<!-- end of each line, default indicates a problem    -->
<!-- Needs an override for each conversion            -->
<xsl:template name="line-separator">
    <xsl:text>[LINESEP]</xsl:text>
</xsl:template>

<!-- Explicitly assumes a sequence of "line" -->
<xsl:template match="line">
    <xsl:apply-templates />
    <!-- is there a next line to separate? -->
    <xsl:if test="following-sibling::line">
        <xsl:call-template name="line-separator"/>
    </xsl:if>
</xsl:template>


<!-- ################ -->
<!-- Poetry Utilities -->
<!-- ################ -->

<!-- These inherit from their containers,    -->
<!-- which is why "poem" has a default value -->

<xsl:template match="poem|poem/author|stanza|stanza/line" mode="poem-indent">
    <xsl:choose>
        <xsl:when test="@indent">
            <xsl:value-of select="@indent" />
        </xsl:when>
        <xsl:when test="self::poem">
            <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="poem-indent" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="poem|poem/author|stanza|stanza/line" mode="poem-halign">
    <xsl:choose>
        <xsl:when test="@halign">
            <xsl:value-of select="@halign" />
        </xsl:when>
        <xsl:when test="self::poem">
            <xsl:text>left</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="parent::*" mode="poem-halign" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ##### -->
<!-- Music -->
<!-- ##### -->

<!-- Note -->
<xsl:template match="n">
    <xsl:call-template name="begin-inline-math"/>
    <!-- Test that pitch class is NOT castable as a number -->
    <xsl:if test="not(number(@pc) = number(@pc))">
        <xsl:text>\text{</xsl:text>
        <xsl:value-of select="@pc"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <!-- Provide something to place accidental -->
    <!-- on if the pitch class is numeric.     -->
    <xsl:if test="number(@pc) = number(@pc) and @acc">
        <xsl:text>{}</xsl:text>
    </xsl:if>
    <!-- Add an accidental if applicable -->
    <xsl:if test="@acc">
        <xsl:text>^</xsl:text>
        <xsl:call-template name="accidentals">
            <xsl:with-param name="accidental"><xsl:value-of select="@acc"/></xsl:with-param>
        </xsl:call-template>
    </xsl:if>
    <!-- Test that pitch class IS castable as a number -->
    <!-- Accidentals precede numeric pitch classes     -->
    <xsl:if test="number(@pc) = number(@pc)">
        <xsl:value-of select="@pc"/>
    </xsl:if>
    <!-- Add an octave number if applicable -->
    <xsl:if test="@octave">
        <!-- Consideration: should we accommodate other octave notations?    -->
        <!-- Current support is for scientific pitch notation (the standard), -->
        <!-- other octave notation exists such as "Helmholtz pitch notation"  -->
        <xsl:text>_{</xsl:text>
        <xsl:value-of select="@octave"/>
        <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:call-template name="end-inline-math"/>
</xsl:template>

<!-- Scale Degrees -->
<xsl:template match="scaledeg">
    <!-- Arabic numeral with circumflex accent above)-->
    <xsl:call-template name="begin-inline-math"/>
    <xsl:text>\hat{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <xsl:call-template name="end-inline-math"/>
    <!-- TODO: unclear if trailing space is necessary -->
    <xsl:text> </xsl:text>
</xsl:template>

<!-- Time Signatures -->
<xsl:template match="timesignature">
    <xsl:call-template name="begin-inline-math"/>
    <xsl:text>\begin{smallmatrix}</xsl:text>
    <xsl:value-of select="@top"/>
    <xsl:text>\\</xsl:text>
    <xsl:value-of select="@bottom"/>
    <xsl:text>\end{smallmatrix}</xsl:text>
    <xsl:call-template name="end-inline-math"/>
</xsl:template>

<!-- Chord -->
<xsl:template match="chord">
    <xsl:call-template name="begin-inline-math"/>
    <xsl:text>\left.</xsl:text>
    <!-- Root -->
    <xsl:choose>
        <!-- There is an accidental -->
        <xsl:when test="contains(@root, ' ')">
            <!-- Pitch Class -->
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="substring-before(@root, ' ')"/>
            <xsl:text>}</xsl:text>
            <!-- Accidental -->
            <xsl:text>^</xsl:text>
            <xsl:call-template name="accidentals">
                <xsl:with-param name="accidental"><xsl:value-of select="substring-after(@root, ' ')"/></xsl:with-param>
            </xsl:call-template>
            <!-- prevent "double superscript" error -->
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <!-- There is not an accidental -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="@root"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Mode (augmented, major, minor, half-diminished, diminished, etc.) -->
    <xsl:if test="@mode">
        <xsl:choose>
            <!-- There is a two part mode -->
            <xsl:when test="contains(@mode, ' ')">
                <!-- Lower Mode -->
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="substring-before(@mode, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <!-- Raise to be in line with bps -->
                <xsl:text>^</xsl:text>
                <!-- Higher Mode -->
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="substring-after(@mode, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <!-- prevent "double superscript" error -->
                <xsl:text>{}</xsl:text>
            </xsl:when>
            <!-- There is a single mode -->
            <xsl:otherwise>
                <xsl:call-template name="chordsymbols">
                    <xsl:with-param name="mode"><xsl:value-of select="@mode"/></xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Bass Position Symbol -->
    <xsl:if test="@bps">
        <!-- Consideration: Even if it is not standard practice, -->
        <!-- will anyone ever want more than two bps numbers?    -->
        <xsl:choose>
            <!-- We use a space to delineate the breaking point of the bps -->
            <!-- e.g. for 6/4 we write "6 4" -->
            <xsl:when test="contains(@bps, ' ')">
                <xsl:text>^{</xsl:text>
                <xsl:value-of select="substring-before(@bps, ' ')"/>
                <xsl:text>}</xsl:text>
                <xsl:text>_{</xsl:text>
                <xsl:value-of select="substring-after(@bps, ' ')"/>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <!-- If there is no space, then we only need a superscript -->
            <xsl:otherwise>
                <xsl:text>^{</xsl:text>
                <xsl:value-of select="@bps"/>
                <xsl:text>}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Suspended -->
    <xsl:if test="@suspended = 'yes'">
        <!-- Consideration: should we make "sus" localized/customizable? -->
        <xsl:text>\text{sus}</xsl:text>
    </xsl:if>
    <!-- Chord Alterations -->
    <xsl:if test="./*">
        <xsl:choose>
            <!-- Turning off parentheses is usually for showing why parenthesization clarifies meaning. -->
            <xsl:when test="@parentheses = 'no'">
                <xsl:text>\left.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\left(</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- We only use a smallmatrix if we have more than one alteration         -->
        <!-- Using smallmatrix with a single entry makes the alteration too small. -->
        <xsl:if test="count(*) > 1">
            <xsl:text>\begin{smallmatrix}</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="*"/>
        <xsl:if test="count(*) > 1">
            <xsl:text>\end{smallmatrix}</xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@parentheses = 'no'">
                <xsl:text>\right.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>\right)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <!-- Alternate Bass Note (e.g. C/G) -->
    <xsl:if test="@bass">
        <!-- Resizes based on components of chord -->
        <xsl:text>\middle/</xsl:text>
        <xsl:choose>
            <!-- Bass note has an accidental -->
            <xsl:when test="contains(@bass, ' ')">
                <!-- Pitch Class -->
                <xsl:text>\text{</xsl:text>
                <xsl:value-of select="substring-before(@bass, ' ')"/>
                <xsl:text>}</xsl:text>
                <!-- Accidental -->
                <xsl:text>^{</xsl:text>
                <xsl:call-template name="accidentals">
                    <xsl:with-param name="accidental"><xsl:value-of select="substring-after(@bass, ' ')"/></xsl:with-param>
                </xsl:call-template>
                <xsl:text>}</xsl:text>
            </xsl:when>
            <!-- Bass note does not have an accidental -->
            <xsl:otherwise>
                <!-- Pitch Class -->
                <xsl:text>\text{</xsl:text>
                <xsl:value-of select="@bass"/>
                <xsl:text>}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <xsl:text>\right.</xsl:text>
    <xsl:call-template name="end-inline-math"/>
</xsl:template>

<!-- Chord Alteration -->
<!-- Put a break after each alteration that is not the last -->
<xsl:template match="chord/alteration">
    <xsl:text>\text{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <!-- Separate alterations -->
    <xsl:if test="following-sibling::*">
        <xsl:text>\\</xsl:text>
    </xsl:if>
</xsl:template>

<!--                 -->
<!-- Musical Symbols -->
<!--                 -->

<!-- Accidentals -->

<!-- TODO: If requested, add semi- and sesqui- versions of sharp and flat -->
<!-- (Easy with LilyPond in LaTeX) -->
<!-- (For HTML ,there are Unicode characters, though font support may be iffy) -->

<!-- Double-Sharp -->
<xsl:template match="doublesharp">
    <xsl:call-template name="doublesharp"/>
</xsl:template>

<!-- Sharp -->
<xsl:template match="sharp">
    <xsl:call-template name="sharp"/>
</xsl:template>

<!-- Natural -->
<xsl:template match="natural">
    <xsl:call-template name="natural"/>
</xsl:template>

<!-- Flat -->
<xsl:template match="flat">
    <xsl:call-template name="flat"/>
</xsl:template>

<!-- Double-Flat -->
<xsl:template match="doubleflat">
    <xsl:call-template name="doubleflat"/>
</xsl:template>

<!-- Insert the correct accidental -->
<!-- (For use in <n> and <chord>)  -->
<xsl:template name="accidentals">
    <xsl:param name="accidental"/>
    <xsl:choose>
        <xsl:when test="$accidental = 'doubleflat'">
            <xsl:call-template name="doubleflat"/>
        </xsl:when>
        <xsl:when test="$accidental = 'flat'">
            <xsl:call-template name="flat"/>
        </xsl:when>
        <xsl:when test="$accidental = 'natural'">
            <xsl:call-template name="natural"/>
        </xsl:when>
        <xsl:when test="$accidental = 'sharp'">
            <xsl:call-template name="sharp"/>
        </xsl:when>
        <xsl:when test="$accidental = 'doublesharp'">
            <xsl:call-template name="doublesharp"/>
        </xsl:when>
        <!-- For unknown accidentals, use the given value wrapped in \text{} -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$accidental"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Fall-Back values for Accidentals -->

<!-- Double-Sharp -->
<xsl:template name="doublesharp">
    <xsl:text>[DOUBLESHARP]</xsl:text>
</xsl:template>

<!-- Sharp -->
<xsl:template name="sharp">
    <xsl:text>[SHARP]</xsl:text>
</xsl:template>

<!-- Natural -->
<xsl:template name="natural">
    <xsl:text>[NATURAL]</xsl:text>
</xsl:template>

<!-- Flat -->
<xsl:template name="flat">
    <xsl:text>[FLAT]</xsl:text>
</xsl:template>

<!-- Double-Flat -->
<xsl:template name="doubleflat">
    <xsl:text>[DOUBLEFLAT]</xsl:text>
</xsl:template>

<!-- Insert the correct chord symbol -->
<!-- (For use in <chord>)  -->
<xsl:template name="chordsymbols">
    <xsl:param name="mode"/>
    <xsl:choose>
        <xsl:when test="$mode = 'augmented'">
            <xsl:call-template name="augmentedchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'major'">
            <xsl:call-template name="majorchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'minor'">
            <xsl:call-template name="minorchordsymbol"/>
        </xsl:when>
        <xsl:when test="$mode = 'halfdiminished'">
            <xsl:text>^</xsl:text>
            <xsl:call-template name="halfdiminishedchordsymbol"/>
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <xsl:when test="$mode = 'diminished'">
            <xsl:text>^</xsl:text>
            <xsl:call-template name="diminishedchordsymbol"/>
            <xsl:text>{}</xsl:text>
        </xsl:when>
        <!-- For unknown chord symbols, use the given value wrapped in \text{} -->
        <!-- e.g. mode="maj" will use \text{maj}                               -->
        <xsl:otherwise>
            <xsl:text>\text{</xsl:text>
            <xsl:value-of select="$mode"/>
            <xsl:text>}</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Chord Symbols -->

<!-- Augmented -->
<xsl:template name="augmentedchordsymbol">
    <xsl:text>{+}</xsl:text>
</xsl:template>

<!-- Major -->
<xsl:template name="majorchordsymbol">
    <xsl:text>{\Delta}</xsl:text>
</xsl:template>

<!-- Minor -->
<xsl:template name="minorchordsymbol">
    <xsl:text>{-}</xsl:text>
</xsl:template>

<!-- Half Diminished -->
<xsl:template name="halfdiminishedchordsymbol">
    <xsl:text>\text{\o}</xsl:text>
</xsl:template>

<!-- Diminished -->
<xsl:template name="diminishedchordsymbol">
    <xsl:text>{\circ}</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Cross-References -->
<!-- ################ -->

<!-- The logic of the visible text of a cross-reference is all  -->
<!-- here in the common routines. That text and the target node -->
<!-- is then sent to templates that are output-format-specific. -->

<!-- The actual manufacture of a (active) link is delegated  -->
<!-- to implementations, see abstract (null) implementations -->
<!-- at the end of the "utilities" section below             -->

<!-- Match on:                                       -->
<!--     @ref, no list: the most frequent case       -->
<!--     @ref, a list: mostly for bibliography lists -->
<!--     @first, @last: a range                      -->
<!--     @provisional: author convenience            -->
<!--     remainder: error check                      -->

<!-- Primary case, no separators in @ref -->
<xsl:template match="xref[@ref and not(contains(normalize-space(@ref), ' ')) and  not(contains(normalize-space(@ref), ','))]">
    <!-- sanitize, check, and resolve the reference -->
    <xsl:variable name="ref" select="normalize-space(@ref)" />
    <xsl:variable name="target" select="id($ref)" />
    <!-- Determine style of visible text in link -->
    <xsl:variable name="text-style">
        <xsl:apply-templates select="." mode="get-text-style" />
    </xsl:variable>
    <!-- if target is a bibliography item, generic -->
    <!-- text template only makes a number, we add -->
    <!-- brackets before link manufacture          -->
    <xsl:variable name="b-is-biblio-target" select="boolean($target/self::biblio)" />
    <!-- form text of the clickable, wrap biblio target -->
    <!-- since xref-text outputs just a number          -->
    <xsl:variable name="text">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>[</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="xref-text" >
            <xsl:with-param name="target" select="$target" />
            <xsl:with-param name="text-style" select="$text-style" />
            <!-- pass content as an RTF, test vs. empty string, use copy-of -->
            <xsl:with-param name="custom-text">
                <xsl:apply-templates />
            </xsl:with-param>
        </xsl:apply-templates>
        <!-- a bibliography citation (only) may have extra @detail          -->
        <!-- maybe the detail should migrate to content of a xref to biblio -->
        <xsl:if test="@detail">
            <xsl:choose>
                <xsl:when test="$b-is-biblio-target">
                    <xsl:text>,</xsl:text>
                    <xsl:call-template name="nbsp-character"/>
                    <!-- this info should not be in an attribute! -->
                    <xsl:apply-templates select="@detail" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>MBX:WARNING: &lt;xref @detail="<xsl:value-of select="@detail" />" /&gt; only implemented for single references to &lt;biblio&gt; elements</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:variable>
    <!-- Send the text representation for link and target to a    -->
    <!-- format-specific and target-specific link manufacture.    -->
    <!-- This depends primarly on the $target, but the context is -->
    <!-- holds the location of the link.  Example: a link in      -->
    <!-- display mathematics (rendered by MathJax for HTML)       -->
    <!-- requires radically different constructions as a knowl,   -->
    <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
    <!-- xref-text in \text{} for receipt in display mathematics. -->
    <!-- NB: could a xref with title text have math in it and mess-up here? -->
    <xsl:apply-templates select="." mode="xref-link">
        <xsl:with-param name="target" select="$target" />
        <xsl:with-param name="content" select="$text" />
    </xsl:apply-templates>
</xsl:template>

<!-- A range given by @first, @last            -->
<!-- Makes one chunk of text, linked to @first -->
<!-- Requires same type for targets, since     -->
<!-- type only occurs once in text             -->
<!-- Equations look like (4.2)-(4.8)           -->
<!-- Bibliography looks like [6-14]            -->
<xsl:template match="xref[@first and @last]">
    <!-- sanitize, check, and resolve the two references -->
    <xsl:variable name="ref-one" select="normalize-space(@first)" />
    <xsl:variable name="target-one" select="id($ref-one)" />
    <xsl:variable name="ref-two" select="normalize-space(@last)" />
    <xsl:variable name="target-two" select="id($ref-two)" />
    <!-- Determine style of visible text in link -->
    <xsl:variable name="text-style-one">
        <xsl:apply-templates select="." mode="get-text-style" />
    </xsl:variable>
    <!-- Adjust/set style for end of range          -->
    <!-- Basically supress text manufacture of type -->
    <!-- Also, no content is passed with @last      -->
    <xsl:variable name="text-style-two">
        <xsl:choose>
            <!-- do not replicate type name -->
            <xsl:when test="$text-style-one = 'type-global'">
                <xsl:text>global</xsl:text>
            </xsl:when>
            <xsl:when test="$text-style-one = 'type-local'">
                <xsl:text>local</xsl:text>
            </xsl:when>
            <!-- pass through 'global', 'local', 'title', 'phrase-global' -->
            <xsl:otherwise>
                <xsl:value-of select="$text-style-one" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- enforce @first, @last point to same kind of element, -->
    <!-- since we implicitly recycle the type-name of @first  -->
    <!-- Schematron: possible by inserting id() into XPath test? -->
    <!-- TODO: (2017-07-24) convert to a fatal error after some time? -->
    <xsl:if test="not(local-name($target-one) = local-name($target-two))">
        <xsl:message terminate="no">MBX:ERROR:   &lt;xref @first="<xsl:value-of select="$ref-one" />" @last="<xsl:value-of select="$ref-two" />" /&gt; references two elements with different tags (<xsl:value-of select="local-name($target-one)" /> vs. <xsl:value-of select="local-name($target-two)" />), so are incompatible as endpoints of a range.  Rewrite using two &lt;xref&gt; elements</xsl:message>
    </xsl:if>
    <!-- courtesy check that range is not out-of-order               -->
    <!-- NB: different schemes for "exercise" can make this look odd -->
    <xsl:if test="count($target-one/preceding::*) > count($target-two/preceding::*)">
        <xsl:message>MBX:WARNING: &lt;xref @first="<xsl:value-of select="$ref-one" />" @last="<xsl:value-of select="$ref-two" />" /&gt; references two elements that appear to be in the wrong order</xsl:message>
    </xsl:if>
    <!-- Biblio check assumes targets are equal       -->
    <!-- If target is a bibliography item, generic    -->
    <!-- text template only makes numbers, we add     -->
    <!-- brackets and detail before link manufacture  -->
    <!-- Content passes with @first, not with @second -->
    <xsl:variable name="b-is-biblio-target" select="boolean($target-one/self::biblio)" />
    <!-- Compose two text parts with an ndash, perhaps wrappped -->
    <xsl:variable name="text">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>[</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="xref-text" >
            <xsl:with-param name="target" select="$target-one" />
            <xsl:with-param name="text-style" select="$text-style-one" />
            <!-- pass content as an RTF, test vs. empty string, use copy-of -->
            <xsl:with-param name="custom-text">
                <xsl:apply-templates />
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:call-template name="ndash-character"/>
        <xsl:apply-templates select="." mode="xref-text" >
            <xsl:with-param name="target" select="$target-two" />
            <xsl:with-param name="text-style" select="$text-style-two" />
        </xsl:apply-templates>
        <xsl:if test="$b-is-biblio-target">
            <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:variable>
    <!-- Send the text representation for link and target to a    -->
    <!-- format-specific and target-specific link manufacture.    -->
    <!-- This depends primarly on the $target, but the context is -->
    <!-- holds the location of the link.  Example: a link in      -->
    <!-- display mathematics (rendered by MathJax for HTML)       -->
    <!-- requires radically different constructions as a knowl,   -->
    <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
    <!-- xref-text in \text{} for receipt in display mathematics. -->
    <!-- NB: could a xref with title text have math in it and mess-up here? -->
    <xsl:apply-templates select="." mode="xref-link">
        <xsl:with-param name="target" select="$target-one" />
        <xsl:with-param name="content" select="$text" />
    </xsl:apply-templates>
</xsl:template>

<!-- A comma-, or space-separated list is unusual, -->
<!-- outside of a list of bibliography items.  For -->
<!-- other items we just mimic this case.          -->
<xsl:template match="xref[@ref and (contains(normalize-space(@ref), ' ') or contains(normalize-space(@ref), ','))]">
    <!-- Determine style of visible text in link -->
    <xsl:variable name="text-style">
        <xsl:apply-templates select="." mode="get-text-style" />
    </xsl:variable>
    <!-- commas to blanks, normalize, add trailing blank for parsing   -->
    <!-- initialize with empty previous node, recurse through the list -->
    <xsl:variable name="normalized-ref-list"
        select="concat(normalize-space(str:replace(@ref,',', ' ')), ' ')" />
    <xsl:apply-templates select="." mode="process-ref-list">
        <xsl:with-param name="previous-target" select="/.." />
        <xsl:with-param name="ref-list" select="$normalized-ref-list" />
        <xsl:with-param name="text-style" select="$text-style" />
    </xsl:apply-templates>
</xsl:template>

<!-- $ref-list must always have a trailing blank, if non-empty      -->
<!-- $previous-target serves two purposes:                          -->
<!--     empty signals start of the list, so no separator           -->
<!--     type-checking to preserve a consistent list (unimplmented) -->
<!-- $text-style is set on first call, then just pass-through       -->
<!-- Wrapping for bibiography list is based on first, last element  -->
<!-- No content overrides are allowed, since unclear jut how        -->
<!-- TODO: improve checking to avoid goofy results -->
<xsl:template match="xref" mode="process-ref-list">
    <xsl:param name="previous-target" select="/.." />
    <xsl:param name="ref-list" select="' '" />
    <xsl:param name="text-style" select="''" />
    <!-- split list at first blank, later recurse on $trailing -->
    <xsl:variable name="ref" select="substring-before($ref-list, ' ')" />
    <xsl:variable name="trailing" select="substring-after($ref-list, ' ')" />
    <!-- now work with one $ref and the configured $text-style -->
    <!-- get the target as a node -->
    <xsl:variable name="target" select="id($ref)" />
    <!-- bibiographic targets are special -->
    <xsl:variable name="b-is-biblio-target" select="$target/self::biblio" />
    <!-- if starting, begin bibliography list wrapping -->
    <xsl:if test="not($previous-target) and $b-is-biblio-target">
        <xsl:text>[</xsl:text>
    </xsl:if>
    <!-- output a seperator, if not just starting -->
    <!-- protect text in a math display           -->
    <xsl:if test="$previous-target">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:text>, </xsl:text>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:if>
    <!-- create the visual/clickable/readable text      -->
    <!-- no content is passed, so no override in effect -->
    <xsl:variable name="text">
        <xsl:if test="parent::mrow">
            <xsl:text>\text{</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="xref-text">
            <xsl:with-param name="target" select="$target" />
            <xsl:with-param name="text-style" select="$text-style" />
        </xsl:apply-templates>
        <xsl:if test="parent::mrow">
            <xsl:text>}</xsl:text>
        </xsl:if>
    </xsl:variable>
    <!-- Send the text representation for link and target to a    -->
    <!-- format-specific and target-specific link manufacture.    -->
    <!-- This depends primarly on the $target, but the context is -->
    <!-- holds the location of the link.  Example: a link in      -->
    <!-- display mathematics (rendered by MathJax for HTML)       -->
    <!-- requires radically different constructions as a knowl,   -->
    <!-- or as a hyperlink.  LaTeX barely cares.  We do wrap the  -->
    <!-- xref-text in \text{} for receipt in display mathematics. -->
    <!-- NB: could a xref with title text have math in it and mess-up here? -->
    <xsl:apply-templates select="." mode="xref-link">
        <xsl:with-param name="target" select="$target" />
        <xsl:with-param name="content" select="$text" />
    </xsl:apply-templates>
    <!-- check if we have exhausted the list, -->
    <!-- so check bibliography wrapping       -->
    <xsl:if test="not($trailing) and $b-is-biblio-target">
        <xsl:text>]</xsl:text>
    </xsl:if>
    <!-- recurse into next reference in the list -->
    <xsl:if test="$trailing">
        <xsl:apply-templates select="." mode="process-ref-list">
            <xsl:with-param name="previous-target" select="$target" />
            <xsl:with-param name="ref-list" select="$trailing" />
            <xsl:with-param name="text-style" select="$text-style" />
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Provisional cross-references -->
<!-- A convenience for authors in early stages of writing -->
<!-- Appear both inline and moreso in author tools        -->
<!-- N.B. (2020-06-07) The "assembly" phase will *replace*-->
<!-- these, and so this template may never be hit         -->
<!-- (or only rarely?)                                    -->
<xsl:template match="xref[@provisional]">
    <xsl:variable name="inline-warning" select="string(@provisional)"/>
    <xsl:variable name="margin-warning">
        <xsl:text>Provisional xref</xsl:text>
    </xsl:variable>
    <xsl:call-template name="inline-warning">
        <xsl:with-param name="warning" select="$inline-warning" />
    </xsl:call-template>
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning" select="$margin-warning" />
    </xsl:call-template>
</xsl:template>

<!-- Warnings for a high-frequency mistake -->
<xsl:template match="xref[not(@ref) and not(@first and @last) and not(@provisional)]">
    <xsl:message>MBX:WARNING: A cross-reference (&lt;xref&gt;) must have a @ref attribute, a @first/@last attribute pair, or a @provisional attribute</xsl:message>
    <xsl:apply-templates select="." mode="location-report" />
    <xsl:call-template name="inline-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref without ref, first/last, or provisional attribute (check spelling)</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">
            <xsl:text>xref, no recognized attribute</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- ######################### -->
<!-- Cross-Reference Utilities -->
<!-- ######################### -->

<!-- Parse, analyze switches, attributes -->
<!--   global:      5.2                  -->
<!--   type-global: Theorem 5.2          -->
<!--   title:       Smith's Theorem      -->
<xsl:template match="xref" mode="get-text-style">
    <xsl:choose>
        <!-- local specification is override of global  -->
        <!-- new @text attribute first, and if so, bail -->
        <xsl:when test="@text='global'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='local'">
            <xsl:text>local</xsl:text>
        </xsl:when>
        <xsl:when test="@text='hybrid'">
            <xsl:text>hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-global'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-local'">
            <xsl:text>type-local</xsl:text>
        </xsl:when>
        <xsl:when test="@text='type-hybrid'">
            <xsl:text>type-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='phrase-global'">
            <xsl:text>phrase-global</xsl:text>
        </xsl:when>
        <xsl:when test="@text='phrase-hybrid'">
            <xsl:text>phrase-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="@text='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <xsl:when test="@text='custom'">
            <xsl:text>custom</xsl:text>
        </xsl:when>
        <!-- old (deprecated, 2017-07-25) autoname attribute -->
        <xsl:when test="@autoname='no'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="@autoname='yes'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="@autoname='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <!-- otherwise, global setting via attribute/switch  -->
        <!-- New scheme is set from docinfo attribute        -->
        <!-- No setting in docinfo yields empty string for   -->
        <!-- $xref-text-style, so we drop into legacy scheme -->
        <!-- for the default, which is 'yes'/'type-global'   -->
        <xsl:when test="$xref-text-style='global'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='local'">
            <xsl:text>local</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='hybrid'">
            <xsl:text>hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-global'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-local'">
            <xsl:text>type-local</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='type-hybrid'">
            <xsl:text>type-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='phrase-global'">
            <xsl:text>phrase-global</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='phrase-hybrid'">
            <xsl:text>phrase-hybrid</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <xsl:when test="$xref-text-style='custom'">
            <xsl:text>custom</xsl:text>
        </xsl:when>
        <!-- use this when choose goes away
        <xsl:if test="not($xref-text-style = '')">
            <xsl:value-of select="$xref-text-style" />
        </xsl:if>
        -->
        <!-- legacy-autoname is a pass-thru of old autoname  -->
        <!-- except with no command-line, no docinfo, then   -->
        <!-- a 'unset' will appear here to activate new      -->
        <!-- default this could move later to the "otherwise"-->
        <xsl:when test="$legacy-autoname='unset'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='no'">
            <xsl:text>global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='yes'">
            <xsl:text>type-global</xsl:text>
        </xsl:when>
        <xsl:when test="$legacy-autoname='title'">
            <xsl:text>title</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG:    NO TEXT STYLE DETERMINED</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- The text that will be visible and clickable    -->
<!-- Bibliography items return a naked number,      -->
<!-- caller is responsible for adjusting text with  -->
<!-- brackets prior to shipping to link manufacture -->
<xsl:template match="xref" mode="xref-text">
    <xsl:param name="target" />
    <xsl:param name="text-style" />
    <xsl:param name="custom-text" select="''" />
    <!-- an equation target is exceptional -->
    <xsl:variable name="b-is-equation-target" select="$target/self::mrow or $target/self::men" />
    <!-- a bibliography target is exceptional -->
    <xsl:variable name="b-is-biblio-target" select="boolean($target/self::biblio)" />
    <!-- a contributor target is exceptional -->
    <xsl:variable name="b-is-contributor-target" select="boolean($target/self::contributor)"/>
    <!-- recognize content s potential override -->
    <xsl:variable name="b-has-content" select="not($custom-text = '')" />
    <!-- check some situations that would lead to ineffective -->
    <!-- cross-references due to empty text                   -->
    <xsl:choose>
        <xsl:when test="$text-style = 'title'">
            <xsl:variable name="the-title">
                <xsl:apply-templates select="$target" mode="title-xref"/>
            </xsl:variable>
            <xsl:if test="$the-title = ''">
                <xsl:message>
                    <xsl:text>PTX:WARNING:    </xsl:text>
                    <xsl:text>An &lt;xref&gt; wants to build text using a title to identify the target, but the target (which has @xml:id "</xsl:text>
                    <xsl:value-of select="@ref"/>
                    <xsl:text>") has no title, not even a default title.</xsl:text>
                </xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:if>
        </xsl:when>
        <xsl:when test="$text-style = 'custom'">
            <xsl:if test="not($b-has-content)">
                <xsl:message>
                    <xsl:text>PTX:WARNING:    </xsl:text>
                    <xsl:text>An &lt;xref&gt; wants to use custom text to describe the target, but no custom text was provided as the content of the "xref".</xsl:text>
                </xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
        </xsl:when>
        <!-- Any other case of a cross-reference employs a number, or parts -->
        <!-- of a number for the target.  The signal of being numberless is -->
        <!-- an empty result for the modal "number" template.  But it is    -->
        <!-- subtler than that, especially for equations that can have      -->
        <!-- "symbolic" tags via @tag, and the number/no-number dichotomy   -->
        <!-- is complicated by element names and attributes.                -->
        <!-- A cross-reference to a contributor is an exception.            -->
        <xsl:otherwise>
            <xsl:variable name="the-number">
                <xsl:apply-templates select="$target" mode="xref-number">
                    <xsl:with-param name="xref" select="." />
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:if test="($the-number = '') and not($b-is-contributor-target)">
                <xsl:message>
                    <xsl:text>PTX:WARNING:    </xsl:text>
                    <xsl:text>An &lt;xref&gt; wants to build text using a number to identify the target, but the target (which has @xml:id "</xsl:text>
                    <xsl:value-of select="@ref"/>
                    <xsl:text>") does not have a number. You could try 'text="title"' or 'text="custom"' on the "xref".</xsl:text>
                </xsl:message>
                <xsl:apply-templates select="." mode="location-report"/>
            </xsl:if>
        </xsl:otherwise>
    </xsl:choose>
    <!-- Start massive "choose" for exceptions and ten general styles -->
    <xsl:choose>
        <xsl:when test="$b-is-contributor-target">
            <xsl:apply-templates select="$target/personname" />
        </xsl:when>
        <!-- equations are different -->
        <!-- custom or full number   -->
        <xsl:when test="$b-is-equation-target">
            <!-- "custom" style replaces the number -->
            <xsl:choose>
                <xsl:when test="$text-style = 'custom'">
                    <xsl:copy-of select="$custom-text"/>
                </xsl:when>
                <!-- prefixing with content is anomalous -->
                <xsl:otherwise>
                    <xsl:if test="$b-has-content">
                        <xsl:copy-of select="$custom-text"/>
                        <xsl:apply-templates select="." mode="xref-text-separator"/>
                    </xsl:if>
                    <xsl:text>(</xsl:text>
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                    <xsl:text>)</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- bibliography override       -->
        <!-- number only, consumer wraps -->
        <!-- warn about useless content override (use as @detail?) -->
        <xsl:when test="$b-is-biblio-target">
            <xsl:apply-templates select="$target" mode="xref-number">
                <xsl:with-param name="xref" select="." />
            </xsl:apply-templates>
        </xsl:when>
        <!-- now not an equation or bibliography target -->
        <!-- custom text is additional, as prefix, with no type -->
        <xsl:when test="$text-style = 'global'">
            <xsl:if test="$b-has-content">
                <xsl:copy-of select="$custom-text" />
                <xsl:apply-templates select="." mode="xref-text-separator"/>
            </xsl:if>
            <xsl:apply-templates select="$target" mode="xref-number">
                <xsl:with-param name="xref" select="." />
            </xsl:apply-templates>
        </xsl:when>
        <!-- custom text is additional, as prefix, with no type -->
        <xsl:when test="$text-style = 'local'">
            <xsl:if test="$b-has-content">
                <xsl:copy-of select="$custom-text" />
                <xsl:apply-templates select="." mode="xref-text-separator"/>
            </xsl:if>
            <xsl:apply-templates select="$target" mode="serial-number" />
        </xsl:when>
        <xsl:when test="$text-style = 'type-global'">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- usual, default case -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$text-style = 'type-local'">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:when>
                <!-- usual, default case -->
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- special case for phrase options and list items of anonymous lists        -->
        <!-- catch this first and provide no text at all (could provide busted text?) -->
        <!-- anonymous lists live in "p", but this is an unreliable indication        -->
        <xsl:when test="($text-style = 'phrase-global' or $text-style = 'phrase-hybrid') and ($target/self::li and not($target/ancestor::list or $target/ancestor::objectives or $target/ancestor::outcomes or $target/ancestor::exercise))">
            <xsl:message>MBX:WARNING: a cross-reference to a list item of an anonymous list ("<xsl:apply-templates select="$target" mode="serial-number" />") with 'phrase-global' and 'phrase-hybrid' styles for the xref text will yield no text at all, and possibly create unpredictable results in output</xsl:message>
        </xsl:when>
        <xsl:when test="$text-style = 'phrase-global' or $text-style = 'phrase-hybrid'">
            <!-- no content override in this case -->
            <!-- maybe we can relax this somehow? -->
            <xsl:if test="$b-has-content">
                <xsl:message>MBX:WARNING: providing content ("<xsl:value-of select="." />") for an "xref" element is ignored for 'phrase-global' and 'phrase-hybrid' styles for xref text</xsl:message>
                <xsl:apply-templates select="." mode="location-report" />
            </xsl:if>
            <!-- type-local first, no matter what    -->
            <!-- for each of the two phrase styles   -->
            <xsl:apply-templates select="$target" mode="type-name" />
            <xsl:apply-templates select="." mode="xref-text-separator"/>
            <xsl:apply-templates select="$target" mode="serial-number" />
            <!-- climb up tree to find highest matching structure numbers -->
            <!-- we pass through the two styles so reaction can occur     -->
            <!-- For example for the target Theorem 37.8 of an article,   -->
            <!-- phrase-global: "of Section 37" always                    -->
            <!-- phrase-hybrid: "of Section 37" only if necessary         -->
            <xsl:apply-templates select="$target" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="." />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="/.." />
                <xsl:with-param name="target-structure-number">
                    <xsl:apply-templates select="$target" mode="structure-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="($text-style = 'hybrid') or ($text-style = 'type-hybrid')">
            <xsl:choose>
                <!-- content override of type-prefix -->
                <!-- or addtion to plain number      -->
                <xsl:when test="$b-has-content">
                    <xsl:copy-of select="$custom-text" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                </xsl:when>
                <!-- no override, use type as prefix -->
                <xsl:when test="$text-style = 'type-hybrid'">
                    <xsl:apply-templates select="$target" mode="type-name" />
                    <xsl:apply-templates select="." mode="xref-text-separator"/>
                </xsl:when>
                <!-- just a plain number, do nothing at all -->
                <xsl:otherwise />
            </xsl:choose>
            <!-- For example for the target Theorem 37.8 of an article, -->
            <!-- hybrid: 8 or if necessary, 37.8                        -->
            <!-- type-hybrid: Theorem 8 or if necessary, Theorem 37.8   -->
            <xsl:apply-templates select="$target" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="." />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="/.." />
                <xsl:with-param name="target-structure-number">
                    <xsl:apply-templates select="$target" mode="structure-number" />
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$text-style = 'title'">
            <xsl:choose>
                <!-- 2020-02-18: a content override of a title is now  -->
                <!-- deprecated (since there is now a "custom" option  -->
                <!-- for text).  But it still "works", with warnings   -->
                <!-- here.  Clean this up to complete the deprecation. -->
                <!-- (We don't do this with other deprecations since   -->
                <!-- we can get here by a variety of routes.)          -->
                <xsl:when test="$b-has-content">
                    <xsl:message>
                        <xsl:text>PTX:WARNING:    </xsl:text>
                        <xsl:text>An &lt;xref&gt; requests a 'title' as its text but also provides alternate content.  The construction is deprecated as of 2020-02-18.  Instead, specify that xref/@text should be 'custom', either globally or on a per-xref basis.</xsl:text>
                    </xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                    <xsl:copy-of select="$custom-text" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="title-xref"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:when test="$text-style = 'custom'">
            <!-- use the content, do not include a number, a warning -->
            <!-- if the content is empty is provided elsewhere       -->
            <xsl:copy-of select="$custom-text" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:message>MBX:BUG:  NO XREF TEXT GENERATED</xsl:message>
        </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="." mode="latex-page-number">
        <xsl:with-param name="target" select="$target"/>
    </xsl:apply-templates>
</xsl:template>

<!-- "xref text" like "Theorem 4.5" benefits from a non-breaking   -->
<!-- space to keep the pieces together and discourage line-breaks  -->
<!-- in the middle.  This is less relevant when used as a "reason" -->
<!-- inside of display mathematics *and* it does not play nicely   -->
<!-- with WeBWorK's PGML, so this template handles the necessary   -->
<!-- exception for "xref" immediately inside of an "mrow".         -->
<xsl:template match="xref" mode="xref-text-separator">
    <xsl:choose>
        <xsl:when test="parent::mrow">
            <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="nbsp-character"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- This is a hook to add page numbers to the end of the    -->
<!-- xref text in LaTeX output via a \pageref{}, optionally. -->
<!-- Default for this hook is to do nothing.                 -->
<xsl:template match="xref" mode="latex-page-number"/>


<!-- ###################### -->
<!-- Smart Cross-References -->
<!-- ###################### -->

<!-- We climb the tree upward (ancestors) until we hit    -->
<!-- the "mathbook" element, and then quit and assess.    -->
<!-- The "xref" that started all this is used for the     -->
<!-- eventual "hybrid" schemes, to see how close it is.   -->
<!-- We record the oldest ancestor (highest) with a       -->
<!-- *number* that is the *structure number* of the       -->
<!-- target of the cross-reference.  So we know the       -->
<!-- element (and its type) that originates the bulk      -->
<!-- of the target's number.                              -->
<!--                                                      -->
<!-- There is one subtlety.  Usually one, and only one,   -->
<!-- ancestor has the matching number, so we could halt   -->
<!-- once found.  However, the immediately older ancestor -->
<!-- can have the same number.  The "objective" element   -->
<!-- is this way, it shares numbering with its containing -->
<!-- division.  So we track through all the ancestors.    -->
<!--                                                      -->
<!-- To see if a xref is close to its target, we add the  -->
<!-- *single* xref node to the subtree of the (highest)   -->
<!-- node that provides the target's structure number.    -->
<!-- By comparing the sizes of these node-sets, we can    -->
<!-- determine if the xref lies outside the subtree and   -->
<!-- then stick with global numbers.                      -->
<!--                                                      -->
<!-- $text-style                                          -->
<!--   gets passed through, in order to consolidate       -->
<!-- $xref                                                -->
<!--   gets passed through for eventual membership test   -->
<!-- $target                                              -->
<!--   gets passed through for producing hybrid numbers   -->
<!-- $highest-match                                       -->
<!--   starts empty and is updated, if it finishes        -->
<!--   empty then the target is high in the tree          -->
<!--   or a match is a root for the structure number      -->
<!-- $target-structure-number                             -->
<!--   is produced once as a string, and passed through   -->
<!--                                                      -->
<!-- Result is a string that completes the xref text      -->
<!--                                                      -->
<xsl:template match="*" mode="smart-xref-text">
    <xsl:param name="text-style" />
    <xsl:param name="xref" />
    <xsl:param name="target" />
    <xsl:param name="highest-match" select="/.." />
    <xsl:param name="target-structure-number" />
    <!-- step up immediately, else test on  -->
    <!-- structure numbers is vacuous       -->
    <xsl:variable name="parent" select="parent::*" />
    <xsl:variable name="parent-number">
        <xsl:apply-templates select="$parent" mode="number" />
    </xsl:variable>
    <xsl:choose>
        <!-- quit at the top, and examine highest-match,    -->
        <!-- and for phrase-hybrid, we do a membership test -->
        <xsl:when test="$parent/self::mathbook|$parent/self::pretext">
            <xsl:variable name="requires-global">
                <xsl:choose>
                    <!-- no match, already high up tree, so no  -->
                    <!-- qualification is needed in either case -->
                    <xsl:when test="not($highest-match)">
                        <xsl:text>false</xsl:text>
                    </xsl:when>
                    <!-- now have a match, so for phrase-global -->
                    <!-- we will always print the global info   -->
                    <xsl:when test="$text-style='phrase-global'">
                        <xsl:text>true</xsl:text>
                    </xsl:when>
                    <!-- now have a match, so for all other styles -->
                    <!-- we check to see if xref is in subtree     -->
                    <xsl:otherwise>
                        <xsl:variable name="target-tree-size" select="count($highest-match/descendant-or-self::*)" />
                        <xsl:variable name="xref-union-tree-size" select="count(($xref | $highest-match/descendant-or-self::*))" />
                        <xsl:value-of select="$xref-union-tree-size = $target-tree-size + 1" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- now know local/global, write trailing portion of text -->
            <!-- here based on the style and the global requirement    -->
            <!-- NB: the "choose" is mirrored in the more specific template, next -->
            <!-- Question:  why does "phrase-global" come through here?           -->
            <xsl:choose>
                <!-- phrase styles may need remainder of phrase -->
                <xsl:when test="(($text-style='phrase-global') or ($text-style='phrase-hybrid')) and ($requires-global = 'true')">
                    <!-- connector, internationalize -->
                    <xsl:text> of </xsl:text>
                    <xsl:apply-templates select="$highest-match" mode="type-name" />
                    <xsl:call-template name="nbsp-character"/>
                    <xsl:apply-templates select="$highest-match" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <!-- hybrid styles need number for remainder -->
                <xsl:when test="($text-style='hybrid') or ($text-style='type-hybrid')">
                    <xsl:choose>
                        <xsl:when test="$requires-global = 'true'">
                            <xsl:apply-templates select="$target" mode="xref-number">
                                <xsl:with-param name="xref" select="." />
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$target" mode="serial-number" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <!-- possible missing implementation bug in numbering -->
        <xsl:when test="$parent-number = '[NUM]'">
            <xsl:message>MBX:BUG:     Looks like a [<xsl:value-of select="local-name($parent)" />] element has an ambiguous number, found while making cross-reference text</xsl:message>
        </xsl:when>
        <!-- no match, just recurse, and preserve $highest-match -->
        <xsl:when test="not($parent-number = $target-structure-number)">
            <xsl:apply-templates select="$parent" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="$xref" />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="$highest-match" />
                <xsl:with-param name="target-structure-number" select="$target-structure-number" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- a match, record in updated $highest-match -->
        <xsl:when test="$parent-number = $target-structure-number">
            <xsl:apply-templates select="$parent" mode="smart-xref-text">
                <xsl:with-param name="text-style" select="$text-style" />
                <xsl:with-param name="xref" select="$xref" />
                <xsl:with-param name="target" select="$target"/>
                <xsl:with-param name="highest-match" select="$parent" />
                <xsl:with-param name="target-structure-number" select="$target-structure-number" />
            </xsl:apply-templates>
        </xsl:when>
        <!-- impossible to get here -->
    </xsl:choose>
</xsl:template>

<!-- A hybrid scheme for a list item is only for list items         -->
<!-- of an ordered list, we drop the list number (structure number) -->
<!-- when xref and target are both inside the same list.            -->
<!-- No need to recurse.  $target is context, allowing a match.     -->

<xsl:template match="list//li" mode="smart-xref-text">
    <xsl:param name="text-style" />
    <xsl:param name="xref" />
    <xsl:param name="target" />

    <xsl:variable name="targets-list" select="$target/ancestor::list" />
    <xsl:variable name="xrefs-list"   select="$xref/ancestor::list" />

    <!-- To be a local xref, the "xref" must live in some "list", and -->
    <!-- it must be the same "list" as the "li" (which is in a list   -->
    <!-- due to the match).  We use the negation to keep the logic    -->
    <!-- the same as in the more general template, above              -->
    <xsl:variable name="requires-global" select="not((count($xrefs-list) = 1) and (count($targets-list|$xrefs-list) = 1))" />

    <!-- This "choose" largely matches above, and so maybe  -->
    <!-- could be consolidated into a parameterized template -->
    <xsl:choose>
        <!-- phrase styles may need remainder of phrase -->
        <xsl:when test="(($text-style='phrase-global') or ($text-style='phrase-hybrid')) and ($requires-global = 'true')">
            <!-- connector, internationalize -->
            <xsl:text> of </xsl:text>
            <xsl:apply-templates select="$targets-list" mode="type-name" />
            <xsl:call-template name="nbsp-character"/>
            <xsl:apply-templates select="$targets-list" mode="xref-number">
                <xsl:with-param name="xref" select="." />
            </xsl:apply-templates>
        </xsl:when>
        <!-- hybrid styles need number for remainder -->
        <xsl:when test="($text-style='hybrid') or ($text-style='type-hybrid')">
            <xsl:choose>
                <xsl:when test="$requires-global = 'true'">
                    <xsl:apply-templates select="$target" mode="xref-number">
                        <xsl:with-param name="xref" select="." />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$target" mode="serial-number" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<!-- This is an abstract template, to accomodate -->
<!-- hard-coded HTML numbers and for LaTeX the   -->
<!-- \ref and \label mechanism                   -->
<xsl:template match="*" mode="xref-number">
    <xsl:text>[XREFNUM]</xsl:text>
</xsl:template>

<!-- This is a base implementation for the xref-link -->
<!-- template, which just repeats the content, with  -->
<!-- an indication that this needs to be overridden  -->
<!--   context -                                     -->
<!--      an xref usually, typically its parent      -->
<!--      is inspected to vary link style            -->
<!--   content -                                     -->
<!--     an RTF of the visual text,                  -->
<!--     suitable for location of the link           -->
<!--   target -                                      -->
<!--     the target of the link, so the right        -->
<!--     identification can be produced              -->
<!--  implementation is based on location            -->
<xsl:template match="*" mode="xref-link">
    <xsl:param name="target" />
    <xsl:param name="content" />
    <xsl:text>[LINK: </xsl:text>
    <xsl:copy-of select="$content" />
    <xsl:text>]</xsl:text>
</xsl:template>

<!-- For cross-references in books with parts, we only     -->
<!-- want a part number in the cross-reference when the    -->
<!-- "xref" and the "$target" are "far apart," so the part -->
<!-- number is necessary to disambiguate the result.  This -->
<!-- utility uses the target as context and the xref as a  -->
<!-- parameter.  It evaluates to 'true' if and only if the -->
<!-- two nodes cross a part boundary *and* the target lies -->
<!-- inside a part.                                        -->
<!-- NB: "ancestor-or-self" is not used here               -->
<!--   (a) the $xref is not a part                         -->
<!--   (b) if the target is a part, its number will be     -->
<!--       its serial number, and will not need a prefix,  -->
<!--       so this will return false                       -->
<xsl:template match="*" mode="crosses-part-boundary">
    <xsl:param name="xref" select="/.." />
    <xsl:choose>
        <!-- if parts are not structural, no need -->
        <xsl:when test="$parts='absent' or $parts='decorative'">
            <xsl:value-of select="false()" />
        </xsl:when>
        <!-- if target is not in a part, no need -->
        <xsl:when test="not(ancestor::part)">
            <xsl:value-of select="false()" />
        </xsl:when>
        <!-- xref can't be in target's part, so necessary -->
        <xsl:when test="not($xref/ancestor::part)">
            <xsl:value-of select="true()" />
        </xsl:when>
        <!-- target and xref both in parts.  Same one? -->
        <xsl:otherwise>
            <xsl:value-of select="count(ancestor::part|$xref/ancestor::part) = 2" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- #################### -->
<!-- Common Constructions -->
<!-- #################### -->

<!-- With no special formatting, "PreTeXt" can be in -common -->
<!-- Use of "pretext" as a root container should get higher  -->
<!-- priority when used with /, or as a variable             -->
<xsl:template match="pretext">
    <xsl:text>PreTeXt</xsl:text>
</xsl:template>

<!-- We place the 13 Latin abbreviations here since they -->
<!-- are fairly basic.  The final period is implemented  -->
<!-- as a named template, so we can override it in the   -->
<!-- LaTeX conversion and get reasonable behavior (i.e.  -->
<!-- not confused as the end of a sentence).             -->

<!-- See: Chicago Manual of Style, 15e, 15.44, 15.55     -->
<!-- See: Bringhurst, 4e, 5.4.4                          -->

<xsl:template name="abbreviation-period">
    <xsl:text>.</xsl:text>
</xsl:template>

<!-- anno Domini, in the year of the Lord -->
<!-- CMOS, Bringurst 5.4.4, no periods    -->
<xsl:template match="ad">
    <xsl:text>AD</xsl:text>
</xsl:template>
<!-- ante meridiem, before midday      -->
<!-- CMOS, Bringurst 5.4.4, no periods -->
<xsl:template match="am">
    <xsl:text>AM</xsl:text>
</xsl:template>
<!-- before Christ                     -->
<!-- CMOS, Bringurst 5.4.4, no periods -->
<xsl:template match="bc">
    <xsl:text>BC</xsl:text>
</xsl:template>
<!-- circa, about                         -->
<!-- CMOS, ca. preferable (c. is century) -->
<!-- "circa" deprecated 2018-12-30        -->
<xsl:template match="ca">
    <xsl:text>ca</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- exempli gratia, for example -->
<xsl:template match="eg">
    <xsl:text>e.g</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- et alia, and others -->
<xsl:template match="etal">
    <xsl:text>et al</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- et caetera, and the rest -->
<xsl:template match="etc">
    <xsl:text>etc</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- id est, in other words -->
<xsl:template match="ie">
    <xsl:text>i.e</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- nota bene, note well -->
<!-- CMOS, no periods     -->
<xsl:template match="nb">
    <xsl:text>NB</xsl:text>
</xsl:template>
<!-- post meridiem, after midday       -->
<!-- CMOS, Bringurst 5.4.4, no periods -->
<xsl:template match="pm">
    <xsl:text>PM</xsl:text>
</xsl:template>
<!-- post scriptum, after what has been written -->
<!-- CMOS, no periods                           -->
<xsl:template match="ps">
    <xsl:text>PS</xsl:text>
</xsl:template>
<!-- versus, against                 -->
<!-- CMOS, v. only in legal contexts -->
<xsl:template match="vs">
    <xsl:text>vs</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>
<!-- videlicet, namely -->
<xsl:template match="viz">
    <xsl:text>viz</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>

<!-- ################## -->
<!-- Special Characters -->
<!-- ################## -->

<!-- Dashes and hyphens - worth reviewing       -->
<!-- http://www.cs.tut.fi/~jkorpela/dashes.html -->

<xsl:template name="nbsp-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'nbsp'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="nbsp">
    <xsl:call-template name="nbsp-character"/>
</xsl:template>

<xsl:template name="ndash-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'ndash'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="ndash">
    <xsl:call-template name="ndash-character"/>
</xsl:template>

<!-- An mdash may have thin space around it, otherwise it        -->
<!-- should have none.  It might be difficult to enforce this    -->
<!-- (we could!), but we don't.  Instead, we make the thin-space -->
<!-- version a publisher option.  So we need two base characters -->
<!-- as abstract templates and do everything else here.          -->

<xsl:template name="mdash-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'mdash'"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="thin-space-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'thin-space'"/>
    </xsl:call-template>
</xsl:template>

<!-- The variable, surrounding space. This approach is   -->
<!-- executed once, so not local to template for "mdash" -->
<xsl:variable name="emdash-space-char">
    <xsl:choose>
        <xsl:when test="$emdash-space='none'">
            <xsl:text />
        </xsl:when>
        <xsl:when test="$emdash-space='thin'">
            <xsl:call-template name="thin-space-character"/>
        </xsl:when>
    </xsl:choose>
</xsl:variable>

<xsl:template match="mdash">
    <xsl:value-of select="$emdash-space-char"/>
    <xsl:call-template name="mdash-character"/>
    <xsl:value-of select="$emdash-space-char"/>
</xsl:template>

<!-- ################### -->
<!-- Reserved Characters -->
<!-- ################### -->

<!-- If a markup languge reserves some characters,        -->
<!-- then we have to provide special handling.            -->
<!-- These are the *union* of all these characters        -->
<!-- implemented in a totally ugly fashion so that if     -->
<!-- these templates are not overridden we hear about it. -->
<!-- These are just for "normal" text, not mathematics    -->
<!-- in LaTeX syntax, nor to function as special          -->
<!-- characters themselves                                -->

<!-- #################### -->
<!-- In transition.  Empty elements for simple, ASCII,  -->
<!-- "first 128", characters will eventually be deprecated  -->
<!-- in favor of text()-processing which will make  -->
<!-- replacements as needed, via a per-conversion hook  -->
<!-- placed into the generic "text()" template. -->
<!--  -->
<!-- Otherwise, a conversion only needs to implement a  -->
<!-- named template for a particular character whn an  -->
<!-- escaped version, or a better Unicode version, is  -->
<!-- necessary or desired. -->
<!-- #################### -->

<!-- These XML and LaTeX reserved characters all have natural     -->
<!-- keyboard equivalents which will suffice in most conversions, -->
<!-- so we implement default versions in U+00-U+7F.               -->


<!-- Less Than -->
<xsl:template name="less-character">
    <xsl:text>&lt;</xsl:text>
</xsl:template>

<!-- Greater Than -->
<xsl:template name="greater-character">
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<!--       -->
<!-- LaTeX -->
<!--       -->

<!-- # $ % ^ & _ { } ~ \ -->

<!-- Number Sign, Hash, Octothorpe -->
<xsl:template name="hash-character">
    <xsl:text>#</xsl:text>
</xsl:template>

<!-- Dollar sign -->
<xsl:template name="dollar-character">
    <xsl:text>$</xsl:text>
</xsl:template>

<!-- Percent sign -->
<xsl:template name="percent-character">
    <xsl:text>%</xsl:text>
</xsl:template>

<!-- Circumflex  -->
<xsl:template name="circumflex-character">
    <xsl:text>^</xsl:text>
</xsl:template>

<!-- Ampersand -->
<xsl:template name="ampersand-character">
    <xsl:text>&amp;</xsl:text>
</xsl:template>

<!-- Underscore -->
<xsl:template name="underscore-character">
    <xsl:text>_</xsl:text>
</xsl:template>

<!-- Left Brace -->
<xsl:template name="lbrace-character">
    <xsl:text>{</xsl:text>
</xsl:template>

<!-- Right Brace -->
<xsl:template name="rbrace-character">
    <xsl:text>}</xsl:text>
</xsl:template>

<!-- Tilde -->
<xsl:template name="tilde-character">
    <xsl:text>~</xsl:text>
</xsl:template>

<!-- Backslash -->
<xsl:template name="backslash-character">
    <xsl:text>\</xsl:text>
</xsl:template>

<!-- ################ -->
<!-- Other Characters -->
<!-- ################ -->

<!-- These are characters which may be reserved in certain          -->
<!-- conversions (such as star/asterisk/* in Markdown), or          -->
<!-- have fancier left/right versions (like double quote marks),    -->
<!-- or look really bad if faked from a keyboard (double brackets), -->
<!-- or lack an ASCII equivalent (like per-mille).  So we leave     -->
<!-- them undefined here as named templates with warnings and       -->
<!-- alarm bells, so that if a new conversion does not have an      -->
<!-- implementation, that will be discovered early in development.  -->

<xsl:template name="warn-unimplemented-character">
    <xsl:param name="char-name"/>
     <xsl:message>PTX:ERROR:   the character named "<xsl:value-of select="$char-name"/>" needs an implementation in the current conversion</xsl:message>
     <xsl:text>[[[</xsl:text>
     <xsl:value-of select="$char-name"/>
     <xsl:text>]]]</xsl:text>
</xsl:template>



<!-- Asterisk -->
<!-- Centered as a character, not an exponent -->
<xsl:template name="asterisk-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'asterisk'"/>
    </xsl:call-template>
</xsl:template>

<!-- Left Single Quote -->
<xsl:template name="lsq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'lsq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="lsq">
    <xsl:call-template name="lsq-character"/>
</xsl:template>

<!-- Right Single Quote -->
<xsl:template name="rsq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rsq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rsq">
    <xsl:call-template name="rsq-character"/>
</xsl:template>

<!-- Left (Double) Quote -->
<xsl:template name="lq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'lq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="lq">
    <xsl:call-template name="lq-character"/>
</xsl:template>

<!-- Right (Double) Quote -->
<xsl:template name="rq-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rq'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rq">
    <xsl:call-template name="rq-character"/>
</xsl:template>

<!-- Left Bracket -->
<xsl:template name="lbracket-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'lbracket'"/>
    </xsl:call-template>
</xsl:template>

<!-- Right Bracket -->
<xsl:template name="rbracket-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rbracket'"/>
    </xsl:call-template>
</xsl:template>

<!-- Left Double Bracket -->
<xsl:template name="ldblbracket-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'ldblbracket'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="ldblbracket">
    <xsl:call-template name="ldblbracket-character"/>
</xsl:template>

<!-- Right Double Bracket -->
<xsl:template name="rdblbracket-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rdblbracket'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rdblbracket">
    <xsl:call-template name="rdblbracket-character"/>
</xsl:template>

<!-- Left Angle Bracket -->
<xsl:template name="langle-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'langle'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="langle">
    <xsl:call-template name="langle-character"/>
</xsl:template>

<!-- Right Angle Bracket -->
<xsl:template name="rangle-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'rangle'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="rangle">
    <xsl:call-template name="rangle-character"/>
</xsl:template>

<!-- Ellipsis (dots), for text, not math -->
<xsl:template name="ellipsis-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'ellipsis'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="ellipsis">
    <xsl:call-template name="ellipsis-character"/>
</xsl:template>

<!-- Midpoint -->
<!-- A centered dot used sometimes like a decorative dash -->
<xsl:template name="midpoint-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'midpoint'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="midpoint">
    <xsl:call-template name="midpoint-character"/>
</xsl:template>

<!-- Swung Dash -->
<!-- A decorative dash, like a tilde, but bigger, and centered -->
<xsl:template name="swungdash-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'swungdash'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="swungdash">
    <xsl:call-template name="swungdash-character"/>
</xsl:template>

<!-- Per Mille -->
<!-- Or, per thousand, like a percent sign -->
<xsl:template name="permille-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'permille'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="permille">
    <xsl:call-template name="permille-character"/>
</xsl:template>

<!-- Pilcrow -->
<!-- Often used to mark the start of a paragraph -->
<xsl:template name="pilcrow-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'pilcrow'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="pilcrow">
    <xsl:call-template name="pilcrow-character"/>
</xsl:template>

<!-- Section Mark -->
<!-- The stylized double-S to indicate section numbers -->
<xsl:template name="section-mark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'section-mark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="section-mark">
    <xsl:call-template name="section-mark-character"/>
</xsl:template>

<!-- Minus -->
<!-- A hyphen/dash for use in text as subtraction or negation-->
<xsl:template name="minus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'minus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="minus">
    <xsl:call-template name="minus-character"/>
</xsl:template>

<!-- Times -->
<!-- A "multiplication sign" symbol for use in text -->
<xsl:template name="times-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'times'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="times">
    <xsl:call-template name="times-character"/>
</xsl:template>

<!-- Slash -->
<!-- Forward slash, or virgule (see solidus) -->
<xsl:template name="slash-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'slash'"/>
    </xsl:call-template>
</xsl:template>

<!-- Solidus -->
<!-- Fraction bar, not as steep as a forward slash -->
<xsl:template name="solidus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'solidus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="solidus">
    <xsl:call-template name="solidus-character"/>
</xsl:template>

<!-- Obelus -->
<!-- A "division" symbol for use in text -->
<xsl:template name="obelus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'obelus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="obelus">
    <xsl:call-template name="obelus-character"/>
</xsl:template>

<!-- Plus/Minus -->
<!-- The combined symbol -->
<xsl:template name="plusminus-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'plusminus'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="plusminus">
    <xsl:call-template name="plusminus-character"/>
</xsl:template>

<!-- Backtick -->
<!-- Accent grave, as a text character -->
<xsl:template name="backtick-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'backtick'"/>
    </xsl:call-template>
</xsl:template>

<!-- Copyright -->
<!-- Bringhurst: on baseline (i.e. not superscript) -->
<xsl:template name="copyright-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'copyright'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="copyright">
    <xsl:call-template name="copyright-character"/>
</xsl:template>

<!-- Phonomark -->
<!-- copyright on sound recordings                 -->
<!-- Bringhurst: counterpart copyright on baseline -->
<xsl:template name="phonomark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'phonomark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="phonomark">
    <xsl:call-template name="phonomark-character"/>
</xsl:template>

<!-- Copyleft -->
<!-- Bringhurst: counterpart copyright on baseline -->
<xsl:template name="copyleft-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'copyleft'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="copyleft">
    <xsl:call-template name="copyleft-character"/>
</xsl:template>

<!-- Registered -->
<!-- Bringhurst: should be superscript -->
<xsl:template name="registered-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'registered'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="registered">
    <xsl:call-template name="registered-character"/>
</xsl:template>

<!-- Trademark -->
<!-- Bringhurst: should be superscript -->
<xsl:template name="trademark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'trademark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="trademark">
    <xsl:call-template name="trademark-character"/>
</xsl:template>

<!-- Servicemark -->
<!-- Bringhurst: counterpart trademark should be superscript -->
<xsl:template name="servicemark-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'servicemark'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="servicemark">
    <xsl:call-template name="servicemark-character"/>
</xsl:template>

<!-- Coordinates, Temperature, English distance -->
<!-- Intended for simple non-technical uses, without too -->
<!-- much overhead.  The SI unit markup would be better  -->
<!-- suited for scientific or technical work.            -->

<!-- Degree -->
<xsl:template name="degree-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'degree'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="degree">
    <xsl:call-template name="degree-character"/>
</xsl:template>

<!-- Prime -->
<xsl:template name="prime-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'prime'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="prime">
    <xsl:call-template name="prime-character"/>
</xsl:template>

<!-- Double Prime -->
<xsl:template name="dblprime-character">
    <xsl:call-template name="warn-unimplemented-character">
        <xsl:with-param name="char-name" select="'dblprime'"/>
    </xsl:call-template>
</xsl:template>
<xsl:template match="dblprime">
    <xsl:call-template name="dblprime-character"/>
</xsl:template>


<!-- Dots
http://tex.stackexchange.com/questions/19180/which-dot-character-to-use-in-which-context

Swung Dash
http://andrewmccarthy.ie/2014/11/06/swung-dash-in-latex/
 -->
<!-- ######### -->
<!-- Groupings -->
<!-- ######## -->

<!-- Characters with left and right variants naturally       -->
<!-- give rise to tags with begin and end variants           -->
<!-- We implement these here with Result Tree Fragments      -->
<!-- as a polymorphic technique for the actual characters    -->
<!-- LaTeX quotes are odd, so we override "q" and "sq" there -->

<xsl:template match="q">
    <xsl:call-template name="lq-character"/>
    <xsl:apply-templates />
    <xsl:call-template name="rq-character"/>
</xsl:template>

<xsl:template match="sq">
    <xsl:call-template name="lsq-character"/>
    <xsl:apply-templates />
    <xsl:call-template name="rsq-character"/>
</xsl:template>

<xsl:template match="dblbrackets">
    <xsl:call-template name="ldblbracket-character"/>
    <xsl:apply-templates />
    <xsl:call-template name="rdblbracket-character"/>
</xsl:template>

<xsl:template match="angles">
    <xsl:call-template name="langle-character"/>
    <xsl:apply-templates />
    <xsl:call-template name="rangle-character"/>
</xsl:template>

<!-- ########## -->
<!-- XML Syntax -->
<!-- ########## -->

<!-- So we can write knowledgeably about XML in documentation -->
<!-- NB: we can use RTFs to keep this in -common since the    -->
<!-- content of each element is so simple                     -->

<!-- A tag, with angle brackets and monospace font -->
<xsl:template match="tag">
    <xsl:variable name="the-element">
        <c>
            <xsl:text>&lt;</xsl:text>
            <xsl:apply-templates />
            <xsl:text>&gt;</xsl:text>
        </c>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($the-element)/*" />
</xsl:template>

<!-- An empty tag, with angle brackets and monospace font -->
<xsl:template match="tage">
    <xsl:variable name="the-element">
        <c>
            <xsl:text>&lt;</xsl:text>
            <xsl:apply-templates />
            <xsl:text>/&gt;</xsl:text>
        </c>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($the-element)/*" />
</xsl:template>

<!-- An attribute, with @ and monospace font -->
<xsl:template match="attr">
    <xsl:variable name="the-attribute">
        <c>
            <xsl:text>@</xsl:text>
            <xsl:apply-templates />
        </c>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($the-attribute)/*" />
</xsl:template>


<!-- ############ -->
<!-- Conveniences -->
<!-- ############ -->

<!-- Conveniences, which can be overridden in format-specific conversions -->
<!-- TODO: kern, etc. into LaTeX, HTML versions -->
<xsl:template match="webwork[not(child::node() or @*)]">
    <xsl:text>WeBWorK</xsl:text>
</xsl:template>

<!-- ##############-->
<!-- Prophylactics -->
<!-- ############# -->

<!-- We nullify certain elements here that should only be active -->
<!-- in some formats, and templates there can override these     -->

<xsl:template match="instruction" />

<!-- ################### -->
<!-- Errors and Warnings -->
<!-- ################### -->

<!-- Sometimes we want a big warning as part of  -->
<!-- every use of some conversion.  This is it.  -->
<!-- Feed a linefeed in if you want line breaks. -->
<!-- Designed for an 80 column terminal.         -->
<xsl:template name="banner-warning">
    <xsl:param name="warning" />
    <xsl:message>********************************************************************************</xsl:message>
        <xsl:message><xsl:value-of select="$warning" /></xsl:message>
    <xsl:message>********************************************************************************</xsl:message>
</xsl:template>

<!-- We search up the tree, looking for something -->
<!-- an author will recognize, and then report it -->
<!-- Useful for warnings that do not contain any  -->
<!-- identifying information themselves           -->
<xsl:template match="*|@*" mode="location-report">
    <xsl:choose>
        <xsl:when test="@xml:id or title">
            <!-- print information about location -->
            <xsl:message>
                <xsl:text>             located within: </xsl:text>
                <xsl:if test="@xml:id">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="@xml:id" />
                    <xsl:text>" (xml:id)</xsl:text>
                </xsl:if>
                <xsl:if test="@xml:id and title">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:if test="title">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="title" />
                    <xsl:text>" (title)</xsl:text>
                </xsl:if>
            </xsl:message>
        </xsl:when>
        <xsl:when test="mathbook|pretext">
            <!-- at root, fail with no action -->
        </xsl:when>
        <xsl:otherwise>
            <!-- pop up a level and try again -->
            <xsl:apply-templates select="parent::*[1]" mode="location-report" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Debugging info -->
<!-- @xml:base attribute of xinclude scheme -->
<!-- @xml:id - self-explanatory             -->
<!-- title - if there is one                -->
<xsl:template match="*" mode="debug-location">
    <xsl:if test="$b-debug">
        <xsl:message>
            <xsl:text>MBX:DEBUG:   </xsl:text>
            <xsl:text>f: </xsl:text>
            <xsl:choose>
                <xsl:when test="@xml:base">
                    <xsl:value-of select="@xml:base" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>|e: </xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>|i: </xsl:text>
            <xsl:value-of select="@xml:id" />
            <xsl:text>|t: </xsl:text>
            <xsl:apply-templates select="." mode="title-simple" />
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- ############### -->
<!-- Global Warnings -->
<!-- ############### -->

<!-- Checks for errors that would be time-consuming -->
<!-- if done repeatedly, so a pre-processing step   -->
<!-- Calling context should be "mathbook" element   -->
<xsl:template match="mathbook|pretext" mode="generic-warnings">
    <xsl:apply-templates select="." mode="literate-programming-warning" />
    <xsl:apply-templates select="." mode="xinclude-warnings" />
    <xsl:apply-templates select="." mode="xmlid-warning" />
    <xsl:apply-templates select="." mode="text-element-warning" />
    <xsl:apply-templates select="." mode="subdivision-structure-warning" />
</xsl:template>

<!-- Literate Programming support is half-baked, 2017-07-21 -->
<xsl:template match="mathbook|pretext" mode="literate-programming-warning">
    <xsl:if test="$document-root//fragment">
        <xsl:call-template name="banner-warning">
            <xsl:with-param name="warning">
                <xsl:text>  Literate Programming support is incomplete&#xa;</xsl:text>
                <xsl:text>&#xa;</xsl:text>
                <xsl:text>    1.  Code generation is functional, but does not respect indentation&#xa;</xsl:text>
                <xsl:text>    2.  LaTeX generation is functional, could be improved, 2020-11-11&#xa;</xsl:text>
                <xsl:text>    2.  HTML generation is functional, could be improved, 2020-11-11&#xa;</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Using the modular  xinclude  scheme at the top level,      -->
<!-- and forgetting the command-line switch is a common mistake -->
<!-- The following is not perfect, but reasonably effective     -->
<xsl:template match="mathbook|pretext" mode="xinclude-warnings">
    <xsl:if test="book and not(book/chapter or book/part/chapter)">
        <xsl:message>
            <xsl:text>MBX:WARNING:    </xsl:text>
            <xsl:text>Your &lt;book&gt; does not have any chapters.  Maybe you forgot the '--xinclude' switch on your 'xsltproc' command line?</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:if test="article and not(article/p) and not(article/section) and not(article/worksheet)">
        <xsl:message>
            <xsl:text>MBX:WARNING:    </xsl:text>
            <xsl:text>Your &lt;article&gt; does not have any sections or worksheets, nor any top-level paragraphs.  Maybe you forgot the '--xinclude' switch on your 'xsltproc' command line?</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- We warn about bad xml:id.  Our limits: -->
<!-- 26 Latin letters (upper, lower case),  -->
<!-- 10 digits, hyphen/dash, underscore     -->
<!-- TODO: Added 2016-10-29, make into a fatal error later -->
<!-- Unique UI id's added 2017-09-25 as fatal error -->
<!-- NB: internal IDs for LaTeX use colons with @xml:id,  -->
<!-- but this may not be necessary to achieve uniqueness  -->
<xsl:template match="mathbook|pretext" mode="xmlid-warning">
    <xsl:variable name="xmlid-characters" select="concat('-_', &SIMPLECHAR;)" />
    <xsl:for-each select="$document-root//@xml:id">
        <xsl:if test="not(translate(., $xmlid-characters, '') = '')">
            <xsl:message>
                <xsl:text>MBX:WARNING:    </xsl:text>
                <xsl:text>The @xml:id "</xsl:text>
                <xsl:value-of select="." />
                <xsl:text>" is invalid.  Use only letters, numbers, hyphens and underscores.</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- unique HTML id's in use for PreTeXt-provided UI -->
        <xsl:if test="(. = 'masthead') or
                      (. = 'content') or
                      (. = 'primary-navbar') or
                      (. = 'sidebar-left') or
                      (. = 'sidebar-right') or
                      (. = 'toc') or
                      (. = 'logo-link')">
            <xsl:message terminate="yes">
                <xsl:text>MBX:FATAL:   </xsl:text>
                <xsl:text>The @xml:id "</xsl:text>
                <xsl:value-of select="." />
                <xsl:text>" is invalid since it will conflict with a unique HTML id in use by the user interface.  Please use a different string.  Quitting...</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- index.html is built automatically, so preclude a clash -->
        <!-- Not terminating until 2019-07-10 deprecation expires   -->
        <xsl:if test=". = 'index'">
            <xsl:message terminate="no">
                <xsl:text>MBX:ERROR:   </xsl:text>
                <xsl:text>The @xml:id "</xsl:text>
                <xsl:value-of select="."/>
                <xsl:text>" is invalid since it will conflict with the construction of an automatic HTML "index.html" page.  Use some alternative for the real index - sorry.</xsl:text>
            </xsl:message>
        </xsl:if>
    </xsl:for-each>
</xsl:template>


<!-- Elements should never happen like this, so we     -->
<!-- can match on them and offer pretty good advice    -->
<!-- Last: since both summary and specifics.  We       -->
<!-- can't catch with a template, since we don't apply -->
<!-- templates in the places where elements are banned -->
<!-- c, cline; unstructured cd, pre                    -->
<!-- prompt, input, output for sage, console, program  -->
<xsl:template match="mathbook|pretext" mode="text-element-warning">
    <xsl:variable name="bad-elements" select="$document-root//c/*|$document-root//cline/*|$document-root//cd[not(cline)]/*|$document-root//pre[not(cline)]/*|$document-root//prompt/*|$document-root//input/*|$document-root//output/*" />
    <xsl:if test="$bad-elements">
        <xsl:message>
            <xsl:text>MBX:WARNING: </xsl:text>
            <xsl:text>There are apparent XML elements in locations that should be text only (</xsl:text>
            <xsl:value-of select="count($bad-elements)" />
            <xsl:text> times).</xsl:text>
        </xsl:message>
    </xsl:if>
    <xsl:for-each select="$bad-elements">
        <xsl:message>
            <xsl:text>MBX:WARNING: </xsl:text>
            <xsl:text>There is an apparent XML element (&lt;</xsl:text>
            <xsl:value-of select="local-name(.)" />
            <xsl:text>&gt;) inside an &lt;</xsl:text>
            <xsl:value-of select="local-name(parent::*)" />
            <xsl:text>&gt; element, which should only contain text.  Using an escaped "less than" ('&amp;lt;') might be the solution, or using a CDATA section.</xsl:text>
        </xsl:message>
        <xsl:apply-templates select="." mode="location-report" />
    </xsl:for-each>
</xsl:template>

<!-- New authors often begin a subdivision with some material,     -->
<!-- then begin a run of further subdivisions.  This preliminary   -->
<!-- material belongs in an introduction (or is for a conclusion). -->
<!-- This test is not exhaustive, but will catch most cases.       -->
<xsl:template match="mathbook|pretext" mode="subdivision-structure-warning">
    <xsl:for-each select="./book/chapter">
        <xsl:if test="p and section">
            <xsl:message>
                <xsl:text>MBX:WARNING: </xsl:text>
                <xsl:text>A chapter containing sections needs to have other content inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="./article/section|./book/chapter/section">
        <xsl:if test="p and subsection">
            <xsl:message>
                <xsl:text>MBX:WARNING: </xsl:text>
                <xsl:text>A section containing subsections needs to have other content inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="./article/section/subsection|./book/chapter/section/subsection">
        <xsl:if test="p and subsubsection">
            <xsl:message>
                <xsl:text>MBX:WARNING: </xsl:text>
                <xsl:text>A subsection containing subsubsections needs to have other content inside an &lt;introduction&gt; and/or  &lt;conclusion&gt;.</xsl:text>
            </xsl:message>
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- ############ -->
<!-- Deprecations -->
<!-- ############ -->

<!-- Generic deprecation message for uniformity    -->
<!-- occurrences is a node-list of "problem" nodes -->
<!-- A message string like "'foo'" cannot contain  -->
<!-- a single quote, even if entered as &apos;.    -->
<!-- If despearate, concatentate with $apos.       -->
<!-- A &#xa; can be used if necessary, but only    -->
<!-- rarely do we bother.                          -->
<xsl:template name="deprecation-message">
    <xsl:param name="occurrences" />
    <xsl:param name="date-string" />
    <xsl:param name="message" />
    <xsl:if test="$occurrences">
        <xsl:message>
            <xsl:text>MBX:DEPRECATE: (</xsl:text>
            <xsl:value-of select="$date-string" />
            <xsl:text>) </xsl:text>
            <xsl:value-of select="$message" />
            <xsl:text> (</xsl:text>
            <xsl:value-of select="count($occurrences)" />
            <xsl:text> time</xsl:text>
            <xsl:if test="count($occurrences) > 1">
                <xsl:text>s</xsl:text>
            </xsl:if>
            <xsl:text>)</xsl:text>
            <!-- once verbosity is implemented -->
            <!-- <xsl:text>, set log.level to see more details</xsl:text> -->
        </xsl:message>
        <xsl:for-each select="$occurrences">
            <xsl:apply-templates select="." mode="location-report" />
        </xsl:for-each>
        <xsl:message>
            <xsl:text>--------------</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<!-- pass in a condition, true is a problem        -->
<!-- may need to move variables from specific      -->
<!-- conversion and into -common file              -->
<!-- A message string like "'foo'" cannot contain  -->
<!-- a single quote, even if entered as &apos;.    -->
<!-- If despearate, concatentate with $apos.       -->
<!-- A &#xa; can be used if necessary, but only    -->
<!-- rarely do we bother.                          -->
<xsl:template name="parameter-deprecation-message">
    <xsl:param name="incorrect-use" select="false()" />
    <xsl:param name="date-string" />
    <xsl:param name="message" />
    <xsl:if test="$incorrect-use">
        <xsl:message>
            <xsl:text>MBX:DEPRECATE: (</xsl:text>
            <xsl:value-of select="$date-string" />
            <xsl:text>) </xsl:text>
            <xsl:value-of select="$message" />
            <!-- once verbosity is implemented -->
            <!-- <xsl:text>, set log.level to see more details</xsl:text> -->
        </xsl:message>
        <xsl:message>
            <xsl:text>--------------</xsl:text>
        </xsl:message>
    </xsl:if>
</xsl:template>

<xsl:template match="*" mode="deprecation-warnings">
    <!-- Older deprecations at the top of this list, -->
    <!-- so author will see new at the tail end.     -->
    <!-- Comments without implementations have moved -->
    <!-- to Schematron rules after residing here for -->
    <!-- at least 16 months (one year plus grace)    -->
    <!--  -->
    <!-- 2014-05-04  @filebase has been replaced in function by @xml:id -->
    <!-- 2014-06-25  xref once had cite as a variant -->
    <!-- 2015-01-28  once both circum and circumflex existed, circumflex won -->
    <!--  -->
    <!-- These have been outright removed since they simply became confusing -->
    <!-- 2017-07-05  top-level items that should have captions, but don't -->
    <!-- 2017-07-05  sidebyside items that do not have captions, so ineffective -->
    <!--  -->
    <!-- 2015-02-08  naked tikz, asymptote, sageplot are no longer accomodated -->
    <!-- 2015-02-20  tikz element is entirely abandoned -->
    <!-- 2017-12-22  latex-image-code element is entirely abandoned -->
    <!--  -->
    <!-- Active deprecations follow -->
    <!--  -->
    <!-- 2015-03-13  paragraph is renamed more accurately to paragraphs           -->
    <!-- 2017-07-16  removed all backwards compatibility and added empty template -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//paragraph" />
        <xsl:with-param name="date-string" select="'2015-03-13'" />
        <xsl:with-param name="message" select="'the &quot;paragraph&quot; element is deprecated and any contained content will silently not appear, replaced by functional equivalent &quot;paragraphs&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-03-17  various indicators of table rearrangement -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//tgroup" />
        <xsl:with-param name="date-string" select="'2015-03-17'" />
        <xsl:with-param name="message" select="'tables are done quite differently, the &quot;tgroup&quot; element is indicative'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//tgroup/thead/row/entry|$document-root//tgroup/tbody/row/entry" />
        <xsl:with-param name="date-string" select="'2015-03-17'" />
            <xsl:with-param name="message" select="'tables are done quite differently, the &quot;entry&quot; element should be replaced by the &quot;cell&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2015-06-26  chunking became a general thing -->
    <xsl:if test="$html.chunk.level != ''">
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2015-06-26'" />
        <xsl:with-param name="message" select="'the  html.chunk.level  parameter has been replaced by simply  chunk.level  and now applies more generally'" />
            <xsl:with-param name="incorrect-use" select="($html.chunk.level != '')" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- 2015-12-12  empty labels on an ordered list was a bad idea -->
     <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//ol[@label='']" />
        <xsl:with-param name="date-string" select="'2015-12-12'" />
        <xsl:with-param name="message" select="'an ordered list (&lt;ol&gt;) may not have empty labels, and numbering will be unpredictable.  Switch to an unordered list  (&lt;ul&gt;)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-04-07  'plural' option for @autoname discarded -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//xref[@autoname='plural']" />
        <xsl:with-param name="date-string" select="'2016-04-07'" />
        <xsl:with-param name="message" select="'a &lt;xref&gt; element may not have an @autoname attribute set to plural.  There is no replacement, perhaps use content in the &lt;xref&gt;.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-05-23  Require parts of a letter to be structured (could be relaxed) -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//letter/frontmatter/from[not(line)] | $document-root//letter/frontmatter/to[not(line)] | $document-root//letter/backmatter/signature[not(line)]" />
        <xsl:with-param name="date-string" select="'2016-05-23'" />
        <xsl:with-param name="message" select="'&lt;to&gt;, &lt;from&gt;, and &lt;signature&gt; of a letter must be structured as a sequence of &lt;line&gt;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-05-23  line breaks are not XML-ish, some places allow "line" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//br" />
        <xsl:with-param name="date-string" select="'2016-05-23'" />
        <xsl:with-param name="message" select="'&lt;br&gt; can no longer be used to create multiline output; you may use &lt;line&gt; elements in select situations'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-07-31  ban @height attribute, except within webwork problems -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//image[@height and not(ancestor::*[self::webwork])]" />
        <xsl:with-param name="date-string" select="'2016-07-31'" />
        <xsl:with-param name="message" select="'@height attribute on &lt;image&gt; is no longer effective and will be ignored, except within a WeBWorK exercise'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2016-07-31  widths of images must be expressed as percentages -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//image[@width and not(contains(@width, '%'))]" />
        <xsl:with-param name="date-string" select="'2016-07-31'" />
        <xsl:with-param name="message" select="'@width attribute on &lt;image&gt; must be expressed as a percentage'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-02-05  hyphen-minus replaces hyphen; 2018-12-01 use keyboard hyphen -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//hyphen" />
        <xsl:with-param name="date-string" select="'2017-02-05'" />
        <xsl:with-param name="message" select="'use the keyboard hyphen character as a direct replacement for &lt;hyphen/&gt;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-05  a sidebyside cannot have a caption -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//sidebyside[caption]" />
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'a &lt;sidebyside&gt; cannot have a &lt;caption&gt;.  Place the &lt;sidebyside&gt; inside a &lt;figure&gt;, employing the &lt;caption&gt;, which will be the functional equivalent.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-05  sidebyside cannot be cross-referenced anymore, so not knowlizable -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2017-07-05'" />
        <xsl:with-param name="message" select="'the  html.knowl.sidebyside  parameter is now obsolete and will be ignored'" />
        <xsl:with-param name="incorrect-use" select="($html.knowl.sidebyside != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-14  index specification and production reworked -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//index-part" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'the &quot;index-part&quot; element is deprecated, replaced by functional equivalent &quot;index&quot;'" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//index[not(main) and not(index-list)]" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'a &quot;index&quot; element is deprecated, replaced by functional equivalent &quot;idx&quot;'" />
    </xsl:call-template>
    <!--  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//index[main]" />
        <xsl:with-param name="date-string" select="'2017-07-14'" />
        <xsl:with-param name="message" select="'a &quot;index&quot; element with &quot;main&quot; and &quot;sub&quot; headings is deprecated, replaced by functional equivalent &quot;idx&quot; with &quot;h&quot; headings'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-14  cosmetic replacement of WW image/@tex_size by image/@tex-size -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//@tex_size" />
        <xsl:with-param name="date-string" select="'2017-07-18'" />
        <xsl:with-param name="message" select="'the &quot;tex_size&quot; attribute is deprecated, replaced by functional equivalent &quot;tex-size&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-25  replacement of three xref/@autoname attributes by @text -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//xref[@autoname='no']" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;no&quot;  by functional equivalent  text=&quot;global&quot;'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//xref[@autoname='yes']" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;yes&quot;  by functional equivalent  text=&quot;type-global&quot;'" />
    </xsl:call-template>
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//xref[@autoname='title']" />
        <xsl:with-param name="date-string" select="'2017-07-25'" />
        <xsl:with-param name="message" select="'the &quot;xref/autoname&quot; attribute is deprecated, replace  autoname=&quot;title&quot;  by functional equivalent  text=&quot;title&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-07-25  deprecate intentional autoname without new setting -->
    <xsl:if test="not($autoname = '') and not(//docinfo/cross-references)">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-07-25'" />
            <xsl:with-param name="message" select="'the  autoname  parameter is deprecated, but is still effective since  &quot;docinfo/cross-references/@text&quot;  has not been set.  The following parameter values equate to the attribute values: &quot;no&quot; is &quot;global&quot;, &quot;yes&quot; is &quot;type-global&quot;, &quot;title&quot; is &quot;title&quot;'" />
            <xsl:with-param name="incorrect-use" select="not($autoname = '') and not(//docinfo/cross-references)" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- 2017-07-25  deprecate intentional autoname also with new setting -->
    <xsl:if test="not($autoname = '') and //docinfo/cross-references">
        <xsl:call-template name="parameter-deprecation-message">
            <xsl:with-param name="date-string" select="'2017-07-25'" />
            <xsl:with-param name="message" select="'the  autoname  parameter is deprecated, and is being overidden by a  &quot;docinfo/cross-references/@text&quot;  and so is totally ineffective and can be removed'" />
                <xsl:with-param name="incorrect-use" select="not($autoname = '') and //docinfo/cross-references" />
        </xsl:call-template>
    </xsl:if>
    <!--  -->
    <!-- 2017-08-04  repurpose task block for division of project-like -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//task[parent::chapter or parent::appendix or parent::section or parent::subsection or parent::subsubsection or parent::paragraphs or parent::introduction or parent::conclusion]" />
        <xsl:with-param name="date-string" select="'2017-08-04'" />
        <xsl:with-param name="message" select="'the &quot;task&quot; element is no longer used as a child of a top-level division, but is instead being used to divide the other &quot;project-like&quot; elements.  It can be replaced by a functional equivalent: &quot;project&quot;, &quot;activity&quot;, &quot;exploration&quot;, or &quot;investigation&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-09-10  deprecate title-less paragraphs, outside of sidebyside -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//paragraphs[not(title) and not(parent::sidebyside)]" />
        <xsl:with-param name="date-string" select="'2017-09-10'" />
        <xsl:with-param name="message" select="'the &quot;paragraphs&quot; element (outside of a &quot;sidebyside&quot;) now requires a &quot;title&quot; (but you can xref individual &quot;p&quot; now, if that is your purpose)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-11-09  WeBWorK images now with widths as percentages, only on an enclosing sidebyside -->
    <!-- 2020-11-04  One-panel sidebysides not necessary, so now only warn about old attributes     -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//webwork//image[@height or @tex-size]" />
        <xsl:with-param name="date-string" select="'2017-11-09'" />
        <xsl:with-param name="message" select="'an &quot;image&quot; within a &quot;webwork&quot; now has its size given by just a &quot;width&quot; attribute expressed as a percentage, including the percent sign (so in particular do not use &quot;height&quot; or &quot;tex-size&quot;)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-11-09  Assemblages have been rationalized, warn about captioned items -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//assemblage//*[caption]" />
        <xsl:with-param name="date-string" select="'2017-11-09'" />
        <xsl:with-param name="message" select="'an &quot;assemblage&quot; should not contain any items with a &quot;caption&quot;.  You can instead place the content in a bare &quot;sidebyside&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-12-07  "c" content totally escaped for LaTeX -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//c/@latexsep|$document-root//cd/@latexsep" />
        <xsl:with-param name="date-string" select="'2017-12-07'" />
        <xsl:with-param name="message" select="'the &quot;@latexsep&quot; attribute on the &quot;c&quot; and &quot;cd&quot; elements is no longer necessary.  It is being ignored, and can be removed'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-12-21  remove sage/@copy -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//sage/@copy" />
        <xsl:with-param name="date-string" select="'2017-12-21'" />
        <xsl:with-param name="message" select="'@copy on a &quot;sage&quot; element is deprecated, use the xinclude mechanism with common code in an external file'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2017-12-21  remove image/@copy -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//image/@copy" />
        <xsl:with-param name="date-string" select="'2017-12-21'" />
        <xsl:with-param name="message" select="'@copy on an &quot;image&quot; element is deprecated, possibly use the xinclude mechanism with common source code in an external file'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-02-04  geogebra-applet gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//geogebra-applet" />
        <xsl:with-param name="date-string" select="'2018-02-04'" />
        <xsl:with-param name="message" select="'the &quot;geogebra-applet&quot; element has been removed, investigate newer &quot;interactive&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-02-05  booktitle becomes pubtitle -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//booktitle" />
        <xsl:with-param name="date-string" select="'2018-02-05'" />
        <xsl:with-param name="message" select="'the &quot;booktitle&quot; element has been replaced by the functionally equivalent &quot;pubtitle&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-04-06  jsxgraph absorbed into interactive -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//jsxgraph" />
        <xsl:with-param name="date-string" select="'2018-04-06'" />
        <xsl:with-param name="message" select="'the &quot;jsxgraph&quot; element has been deprecated, but remains functional, rework with the &quot;interactive&quot; element'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-05-02  paragraphs purely as a lightweight division -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//sidebyside/paragraphs" />
        <xsl:with-param name="date-string" select="'2018-04-06'" />
        <xsl:with-param name="message" select="'a &quot;paragraphs&quot; can no longer appear within a &quot;sidebyside&quot;, replace with a &quot;stack&quot; containing multiple elements, such as &quot;p&quot;'" />
    </xsl:call-template>
    <!-- 2018-05-18  WeBWorK refactor no longer needs setup/var elements for static representations-->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//webwork/setup/var" />
        <xsl:with-param name="date-string" select="'2018-05-18'" />
        <xsl:with-param name="message" select="'&quot;var&quot; elements in a &quot;webwork/setup&quot; no longer do anything; you may delete them from source'" />
    </xsl:call-template>
    <!-- 2018-07-04  "solution-list" generator element replaced by "solutions" division -->
    <!-- 2020-08-31  element, controlling switches, supporting templates, removed/deactivated -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//solution-list" />
        <xsl:with-param name="date-string" select="'2020-08-31'" />
        <xsl:with-param name="message" select="'the &quot;solution-list&quot; element has been removed (deprecated since 2018-07-04), please switch to using the improved &quot;solutions&quot; division in your back matter (and elsewhere)'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-09-26  appendix subdivision confusion resolved -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$root/article/backmatter/appendix/section" />
        <xsl:with-param name="date-string" select="'2018-09-26'" />
        <xsl:with-param name="message" select="'the first division of an &quot;appendix&quot; of an &quot;article&quot; should be a &quot;subsection&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-11-07  obsolete exercise component switches -->
    <!-- Still exists in "Variable Bad Bank" for use here  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2018-11-07'" />
        <xsl:with-param name="message" select="'the  *.text.*  parameters that control the visibility of components of exercises and projects have been removed and replaced by a greater variety of  exercise.*.*  and  project.*  parameters'" />
            <xsl:with-param name="incorrect-use" select="not(($exercise.text.statement = '') and ($exercise.text.hint = '') and ($exercise.text.answer = '') and ($exercise.text.solution = '') and ($project.text.hint = '') and ($project.text.answer = '') and ($project.text.solution = '') and ($task.text.hint = '') and ($task.text.answer = '') and ($task.text.solution = ''))"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2018-11-07  obsolete backmatter exercise component switches -->
    <!-- Still exists in "Variable Bad Bank" for use here            -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2018-11-07'" />
        <xsl:with-param name="message" select="'the  exercise.backmatter.*  parameters that control the visibility of components of exercises and projects in the back matter have been removed and replaced by the &quot;solutions&quot; element, which is much more versatile'"/>
            <xsl:with-param name="incorrect-use" select="not(($exercise.backmatter.statement = '') and ($exercise.backmatter.hint = '') and ($exercise.backmatter.answer = '') and ($exercise.backmatter.solution = ''))" />
    </xsl:call-template>
    <!--  -->
    <!-- 2018-12-30  circa shortened to ca -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//circa" />
        <xsl:with-param name="date-string" select="'2018-12-30'" />
        <xsl:with-param name="message" select="'the &quot;circa&quot; element has been replaced by the functionally equivalent &quot;ca&quot;'" />
    </xsl:call-template>
    <!--                                                     -->
    <!-- LaTeX's 10 reserved characters: # $ % ^ & _ { } ~ \ -->
    <!--                                                     -->
    <!--  -->
    <!-- 2019-02-06  hash gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//hash" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;hash&quot; element is no longer necessary, simply replace with a bare &quot;#&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  dollar gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//dollar" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;dollar&quot; element is no longer necessary, simply replace with a bare &quot;$&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  percent gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//percent" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;percent&quot; element is no longer necessary, simply replace with a bare &quot;%&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  circumflex gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//circumflex" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;circumflex&quot; element is no longer necessary, simply replace with a bare &quot;^&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  ampersand gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//ampersand" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;ampersand&quot; element is no longer necessary, simply replace with a bare &quot;&amp;&quot; character (properly escaped, i.e. &quot;&amp;amp;&quot;)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  underscore gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//underscore" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;underscore&quot; element is no longer necessary, simply replace with a bare &quot;_&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  lbrace gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//lbrace" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;lbrace&quot; element is no longer necessary, simply replace with a bare &quot;{&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  rbrace gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//rbrace" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;rbrace&quot; element is no longer necessary, simply replace with a bare &quot;}&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  tilde gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//tilde" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;tilde&quot; element is no longer necessary, simply replace with a bare &quot;~&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  backslash gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//backslash" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;backslash&quot; element is no longer necessary, simply replace with a bare &quot;\&quot; character'"/>
    </xsl:call-template>
    <!--                           -->
    <!-- Nine unnecessary elements -->
    <!--                           -->
    <!--  -->
    <!-- 2019-02-06  less gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//less" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;less&quot; element is no longer necessary, simply replace with a bare &quot;&lt;&quot; character (properly escaped, i.e. &quot;&amp;lt;&quot;)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  greater gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//greater" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;greater&quot; element is no longer necessary, simply replace with a bare &quot;&gt;&quot; character (possibly escaped, i.e. &quot;&amp;gt;&quot;)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  lbracket gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//lbracket" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;lbracket&quot; element is no longer necessary, simply replace with a bare &quot;[&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  rbracket gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//rbracket" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;rbracket&quot; element is no longer necessary, simply replace with a bare &quot;]&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  asterisk gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//asterisk" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;asterisk&quot; element is no longer necessary, simply replace with a bare &quot;*&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  slash gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//slash" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;slash&quot; element is no longer necessary, simply replace with a bare &quot;/&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  backtick gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//backtick" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;backtick&quot; element is no longer necessary, simply replace with a bare &quot;`&quot; character'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  braces gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//braces" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;braces&quot; element is no longer necessary, simply replace with bare &quot;{&quot; and &quot;}&quot; characters'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-06  brackets gone -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//brackets" />
        <xsl:with-param name="date-string" select="'2019-02-06'" />
        <xsl:with-param name="message" select="'the &quot;brackets&quot; element is no longer necessary, simply replace with bare &quot;[&quot; and &quot;]&quot; characters'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-10  obsolete  html.css.file  removed -->
    <!-- Still exists in "Variable Bad Bank" for use here  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-02-10'" />
        <xsl:with-param name="message" select="'the obsolete  html.css.file  parameter has been removed, please use html.css.colorfile to choose a color scheme'" />
            <xsl:with-param name="incorrect-use" select="($html.css.file != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-12  "terms" necessary to structure a "glossary"     -->
    <!-- Never in the schema, but a warning here as a public service -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//glossary[not(terms)]" />
        <xsl:with-param name="date-string" select="'2019-02-12'" />
        <xsl:with-param name="message" select="'a &quot;glossary&quot; needs to have its &quot;defined-term&quot; structured within a &quot;terms&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-20  "todo" items now in comments -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//todo" />
        <xsl:with-param name="date-string" select="'2019-02-20'" />
        <xsl:with-param name="message" select="'a &quot;todo&quot; element is no longer effective.  Replace with an XML comment whose first four non-whitespace characters spell &quot;todo&quot; (with no spaces)'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-20  replace author-tools with author.tools              -->
    <!-- Still exists and is respected, move to Variable Bad Bank later  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-02-20'" />
        <xsl:with-param name="message" select="'the  author-tools  parameter has been replaced by the functionally equivalent  author.tools'" />
            <xsl:with-param name="incorrect-use" select="not($author-tools = '')"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-02-23  "rename/@lang" replaced by (optional) rename/@xml:lang -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$docinfo//rename[@lang]" />
        <xsl:with-param name="date-string" select="'2019-02-20'" />
        <xsl:with-param name="message" select="'the &quot;@lang&quot; attribute of &quot;rename&quot; has been replaced by &quot;@xml:lang&quot;, and is now optional if your document only uses one language'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-03-07  replace latex.watermark with watermark.text         -->
    <!-- Still exists and is respected, move to Variable Bad Bank later  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-03-07'" />
        <xsl:with-param name="message" select="'the  latex.watermark  parameter has been replaced by  watermark.text  which is effective in HTML as well as LaTeX'" />
            <xsl:with-param name="incorrect-use" select="($latex.watermark != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-03-07  replace latex.watermark.scale with watermark.scale  -->
    <!-- Still exists and is respected, move to Variable Bad Bank later  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-03-07'" />
        <xsl:with-param name="message" select="'the  latex.watermark.scale  parameter has been replaced by  watermark.scale  which is effective in HTML as well as LaTeX'" />
            <xsl:with-param name="incorrect-use" select="($latex.watermark.scale != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-04-02  "mathbook" replaced by "pretext" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="/mathbook" />
        <xsl:with-param name="date-string" select="'2019-04-02'" />
        <xsl:with-param name="message" select="'the &quot;mathbook&quot; top-level element has been replaced by the functionally equivalent &quot;pretext&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-04-14  analytics ID are now a publisher option -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$docinfo/analytics" />
        <xsl:with-param name="date-string" select="'2019-04-14'" />
        <xsl:with-param name="message" select="'site-specific ID for HTML analytics services (Statcounter, Google) provided within &quot;docinfo/analytics&quot; are now options supplied by publishers as command-line options.  See the Publishers Guide for specifics.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2019-04-14  Google search ID is now a publisher option -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$docinfo/search" />
        <xsl:with-param name="date-string" select="'2019-04-14'" />
        <xsl:with-param name="message" select="'site-specific ID for HTML search services (Google) is no longer provided within &quot;docinfo/search&quot;.  Please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'"/>
    </xsl:call-template>
    <!--  -->
    <!-- 2017-08-25  once deprecated named lists to be captioned lists -->
    <!-- 2019-06-28  deprecated captioned lists to be titled lists     -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//list[caption and not(title)]" />
        <xsl:with-param name="date-string" select="'2017-06-28'" />
        <xsl:with-param name="message" select="'the &quot;list&quot; element is back to requiring a &quot;title&quot;, an existing &quot;caption&quot; will be used in its place'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-06-28  deprecated captioned lists to be titled lists     -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//list[title and caption]" />
        <xsl:with-param name="date-string" select="'2019-06-28'" />
        <xsl:with-param name="message" select="'the &quot;list&quot; element is back to requiring a &quot;title&quot;, only.  So an existing &quot;caption&quot; will be ignored when a &quot;title&quot; is supplied'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-06-28  deprecated captioned tables to be titled tables  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//table[caption]" />
        <xsl:with-param name="date-string" select="'2019-06-28'" />
        <xsl:with-param name="message" select="'the &quot;table&quot; element needs a &quot;title&quot;, not a &quot;caption&quot;.  An existing &quot;caption&quot; will be used instead.  Both will display below the &quot;tabular&quot;'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-07-10  @xml:id = 'index' deprecated in favor of publisher's @ref  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//*[@xml:id = 'index']" />
        <xsl:with-param name="date-string" select="'2019-07-10'" />
        <xsl:with-param name="message" select="'an element should no longer have an @xml:id equal to &quot;index&quot; as a way to create an HTML index.html page.  See the Publishers Guides chapter on the HTML conversion for instructions.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-11-28  deprecated docinfo analytics in favor of publisher's file  -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$docinfo/analytics" />
        <xsl:with-param name="date-string" select="'2019-11-28'" />
        <xsl:with-param name="message" select="'use of the docinfo/analytics element has been deprecated.  Existing elements are being respected, but please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.&#xa;  * For StatCounter this is a cosmetic change.&#xa;  * Google Classic has been deprecated by Google and will not be supported.&#xa;  * Google Universal has been replaced, your ID may continue to work.&#xa;  * Google Global Site Tag is fully supported, try your Universal ID.&#xa;'" />
    </xsl:call-template>
    <!-- And switches for analytics  -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-11-28'" />
        <xsl:with-param name="message" select="'use of string parameters for analytics configuration has been deprecated.  Existing switches are being respected, but please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.&#xa;  * For StatCounter this is a cosmetic change.&#xa;  * Google Classic has been deprecated by Google and will not be supported.&#xa;  * Google Universal has been replaced, your ID may continue to work.&#xa;  * Google Global Site Tag is fully supported, try your Universal ID.&#xa;'" />
            <xsl:with-param name="incorrect-use" select="($html.statcounter.project != '') or ($html.statcounter.security != '') or ($html.google-classic != '') or ($html.google-universal != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2019-11-29  deprecated Google search via string parameter -->
    <!-- see 2019-04-14 for docinfo deprecation                    -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2019-11-29'" />
        <xsl:with-param name="message" select="'Google search is no longer specified with a string parameter.  Please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
            <xsl:with-param name="incorrect-use" select="$html.google-search != ''" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-03-13  deprecated setup element in a webwork -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//webwork/setup" />
        <xsl:with-param name="date-string" select="'2020-03-13'" />
        <xsl:with-param name="message" select="'the &quot;setup&quot; element in a &quot;webwork&quot; is no longer necessary, simply use &quot;pg-code&quot;'"/>
    </xsl:call-template>
    <!--  -->
    <!--  -->
    <!-- 2020-05-10  permalinks (their style actually) are now controlled by Javascript -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-05-10'" />
        <xsl:with-param name="message" select="'the  html.permalink  parameter is now obsolete and will be ignored as this is now controlled by Javascript'" />
        <xsl:with-param name="incorrect-use" select="($html.permalink != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-05-29  HTML calculator model controlled by publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-05-29'" />
        <xsl:with-param name="message" select="'the  html.calculator  parameter has been replaced by the  html/calculator/@model  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($html.calculator != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-11-04  *warning* about one-panel "sidebyside" -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//sidebyside[not(parent::interactive) and count(*[not(&METADATA-FILTER;)]) = 1]" />
        <xsl:with-param name="date-string" select="'2020-11-04'" />
        <xsl:with-param name="message" select="'this is a temporary *warning*, which we plan to remove around 2021-01-30.  A &quot;sidebyside&quot; is no longer necessary to hold, or provide layout control, for single instances of &quot;image&quot;,  &quot;video&quot;,  &quot;tabular&quot;, and similar.  Try removing the &quot;sidebyside&quot; and moving any layout control onto the remaining object.'" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-11-22  LaTeX print option controlled by publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-11-22'" />
        <xsl:with-param name="message" select="'the  latex.print  parameter has been replaced by the  latex/@print  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($latex.print != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-11-22  LaTeX sideness option controlled by publisher file -->
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-11-22'" />
        <xsl:with-param name="message" select="'the  latex.sides  parameter has been replaced by the  latex/@sides  entry in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($latex.sides != '')" />
    </xsl:call-template>
    <!--  -->
    <!-- 2020-11-22  deprecate HTML base URL in docinfo -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$docinfo/html/baseurl/@href" />
        <xsl:with-param name="date-string" select="'2020-11-22'" />
        <xsl:with-param name="message" select="'the &quot;baseurl/@href&quot; element in the &quot;docinfo&quot; has been replaced and is now specified in the publisher file with &quot;html/baseurl/@href&quot;, as documented in the PreTeXt Guide.'"/>
    </xsl:call-template>
    <!-- 2020-11-23  directory.images replaced by publisher file specification -->
    <!-- Reverse this soon, hot fix -->
    <!--     
    <xsl:call-template name="parameter-deprecation-message">
        <xsl:with-param name="date-string" select="'2020-11-23'" />
        <xsl:with-param name="message" select="'the  directory.images  parameter has been replaced by specification of two directories in the publisher file.  We will attempt to honor your selection.  But please switch to using the Publishers File for configuration, as documented in the PreTeXt Guide.'" />
        <xsl:with-param name="incorrect-use" select="($directory.images != '')" />
    </xsl:call-template>
 -->
    <!--  -->
    <!-- 2021-01-07  deprecate sidebyside within a webwork -->
    <xsl:call-template name="deprecation-message">
        <xsl:with-param name="occurrences" select="$document-root//webwork//sidebyside" />
        <xsl:with-param name="date-string" select="'2021-01-07'" />
        <xsl:with-param name="message" select="'a &quot;sidebyside&quot; as a descendant of a &quot;webwork&quot; has been replaced and now &quot;image&quot; and &quot;tabular&quot; elements should be used directly.'"/>
    </xsl:call-template>
</xsl:template>

<!-- Miscellaneous -->

<!-- A "pagebreak" should have limited availability, -->
<!-- so we explicitly kill it here.                  -->
<xsl:template match="pagebreak"/>

<!-- ToDo's are silent unless requested as part of an -->
<!-- author's report, then marginal.  They exist in   -->
<!-- source as prefixed comments, and that prefix     -->
<!-- suffices as part of the output                   -->
<xsl:template match="comment()[translate(substring(normalize-space(string(.)), 1, 4), &UPPERCASE;, &LOWERCASE;) = 'todo']">
    <xsl:call-template name="margin-warning">
        <xsl:with-param name="warning">
            <xsl:call-template name="strip-leading-whitespace">
                <xsl:with-param name="text">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<!-- Converter information for header, generic -->
<!-- params are strings to make comment lines in target file    -->
<!-- "copy-of" supresses output-escaping of HTML/XML characters -->
<xsl:template name="converter-blurb">
    <xsl:param name="lead-in" />
    <xsl:param name="lead-out" />
    <xsl:copy-of select="$lead-in" /><xsl:text>********************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*       Generated from PreTeXt source      *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:if test="$b-debug-datedfiles">
    <xsl:copy-of select="$lead-in" /><xsl:text>*       on </xsl:text>  <xsl:value-of select="date:date-time()" />
                                                                      <xsl:text>       *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*   A recent stable commit (2020-08-09):   *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>* 98f21740783f166a773df4dc83cab5293ab63a4a *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    </xsl:if>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*         https://pretextbook.org          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>*                                          *</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
    <xsl:copy-of select="$lead-in" /><xsl:text>********************************************</xsl:text><xsl:copy-of select="$lead-out" /><xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- We issue specialized blurbs with appropriate comment lines -->
<xsl:template name="converter-blurb-text">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="''" />
        <xsl:with-param name="lead-out" select="''" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-latex">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'%'" />
        <xsl:with-param name="lead-out" select="'%'" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-html">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in">
            <xsl:text disable-output-escaping='yes'>&lt;!--</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="lead-out">
            <xsl:text disable-output-escaping='yes'>--&gt;</xsl:text>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-python">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'#'" />
        <xsl:with-param name="lead-out" select="'#'" />
    </xsl:call-template>
</xsl:template>

<xsl:template name="converter-blurb-perl">
    <xsl:call-template name="converter-blurb">
        <xsl:with-param name="lead-in"  select="'#'" />
        <xsl:with-param name="lead-out" select="'#'" />
    </xsl:call-template>
</xsl:template>

<!-- WeBWorK's editor is not monospaced, so the right border       -->
<!-- looks ragged.  We effectively rubout the right margin,        -->
<!-- then translate all asterisks to octothorpes.  The left margin -->
<!-- becomes three octothorpes to not be confused with metadata    -->
<!-- This can revert to  -perl  if the editor changes              -->
<xsl:template name="converter-blurb-webwork">
    <xsl:variable name="blurb">
        <xsl:call-template name="converter-blurb">
            <xsl:with-param name="lead-in"  select="'##'" />
            <xsl:with-param name="lead-out" select="'XXX'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="str:replace(str:replace($blurb, '*XXX', ''), '*', '#')" />
</xsl:template>

<!-- ################# -->
<!-- Percent Utilities -->
<!-- ################# -->

<!-- Take as input a node set of attributes -->
<!-- of percentages (with '%' at the end)   -->
<!-- Check that sum is under 100%           -->
<xsl:template name="cap-width-at-one-hundred-percent">
    <xsl:param name="nodeset" />
    <xsl:param name="cap" select="100" />
    <xsl:if test="$nodeset">
        <xsl:if test="substring-before($nodeset[1], '%')&gt;$cap">
            <xsl:message terminate="yes">MBX:FATAL:   percentage attributes sum to over 100%</xsl:message>
        </xsl:if>
        <xsl:call-template name="cap-width-at-one-hundred-percent">
            <xsl:with-param name="nodeset" select="$nodeset[position()&gt;1]" />
            <xsl:with-param name="cap" select="$cap - substring-before($nodeset[1], '%')" />
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- Take a string as input    -->
<!-- Abort if not in the form  -->
<!-- \s*[0-9]*\.?[0-9]*\s*%\s* -->
<!-- Normalize to              -->
<!-- [0-9]*\.?[0-9]*%          -->
<xsl:template name="normalize-percentage">
    <xsl:param name="percentage" />
    <xsl:variable name="stripped-percentage" select="normalize-space($percentage)"/>
    <xsl:if test="substring($stripped-percentage,string-length($stripped-percentage)) != '%'">
        <xsl:message terminate="yes">MBX:FATAL:   expecting a percentage ending in '%'; got <xsl:value-of select="$stripped-percentage"/></xsl:message>
    </xsl:if>
    <xsl:variable name="percent" select="normalize-space(substring($stripped-percentage,1,string-length($stripped-percentage) - 1))"/>
    <xsl:if test="number($percent) != $percent">
        <xsl:message terminate="yes">MBX:FATAL:   expecting a numerical value preceding '%'; got <xsl:value-of select="$percent"/></xsl:message>
    </xsl:if>
    <xsl:value-of select="concat($percent,'%')" />
</xsl:template>

<!-- ######## -->
<!-- Bad Bank -->
<!-- ######## -->

<!-- This where old elements go to die.        -->
<!-- Deprecated, then totally discarded later. -->
<!-- When discarded, move to Schematron rules. -->

<!-- #################################### -->
<!-- Deprecations, in Chronological Order -->
<!-- #################################### -->

<!-- Deprecated 2018-12-30           -->
<!-- Simultaneously changed to "ca." -->
<xsl:template match="circa">
 <xsl:text>ca</xsl:text>
    <xsl:call-template name="abbreviation-period"/>
</xsl:template>

<!-- Ten laTeX empty elements -->
<!-- Deprecated 2019-02-06    -->
<!-- # $ % ^ & _ { } ~ \      -->

<xsl:template match="hash">
    <xsl:call-template name="hash-character"/>
</xsl:template>
<xsl:template match="ampersand">
    <xsl:call-template name="ampersand-character"/>
</xsl:template>
<xsl:template match="dollar">
    <xsl:call-template name="dollar-character"/>
</xsl:template>
<xsl:template match="percent">
    <xsl:call-template name="percent-character"/>
</xsl:template>
<xsl:template match="circumflex">
    <xsl:call-template name="circumflex-character"/>
</xsl:template>
<xsl:template match="underscore">
    <xsl:call-template name="underscore-character"/>
</xsl:template>
<xsl:template match="lbrace">
    <xsl:call-template name="lbrace-character"/>
</xsl:template>
<xsl:template match="rbrace">
    <xsl:call-template name="rbrace-character"/>
</xsl:template>
<xsl:template match="tilde">
    <xsl:call-template name="tilde-character"/>
</xsl:template>
<xsl:template match="backslash">
    <xsl:call-template name="backslash-character"/>
</xsl:template>

<!-- Nine unnecessary elements -->
<!-- Deprecated 2019-02-06     -->
<!-- <, >, [, ], *, /, `,      -->
<!--   braces and brackets     -->
<xsl:template match="less">
    <xsl:call-template name="less-character"/>
</xsl:template>
<xsl:template match="greater">
    <xsl:call-template name="greater-character"/>
</xsl:template>
<xsl:template match="lbracket">
    <xsl:call-template name="lbracket-character"/>
</xsl:template>
<xsl:template match="rbracket">
    <xsl:call-template name="rbracket-character"/>
</xsl:template>
<xsl:template match="asterisk">
    <xsl:call-template name="asterisk-character"/>
</xsl:template>
<xsl:template match="slash">
    <xsl:call-template name="slash-character"/>
</xsl:template>
<xsl:template match="backtick">
    <xsl:call-template name="backtick-character"/>
</xsl:template>
<xsl:template match="braces">
    <xsl:call-template name="lbrace-character"/>
    <xsl:apply-templates />
    <xsl:call-template name="rbrace-character"/>
</xsl:template>
<xsl:template match="brackets">
    <xsl:call-template name="lbracket-character"/>
    <xsl:apply-templates />
    <xsl:call-template name="rbracket-character"/>
</xsl:template>

<!-- ############################## -->
<!-- Killed, in Chronological Order -->
<!-- ############################## -->

<!-- 2017-07-16  killed, from 2015-03-13 deprecation -->
<xsl:template match="paragraph" />

<!-- 2019-02-20  deprecated and killed simultaneously -->
<xsl:template match="todo"/>


<!-- Sometimes this template is useful to see which    -->
<!-- templates are not implemented at all in some new  -->
<!-- (basic) conversion building just on this -common. -->
<!-- Maybe "dead-ending" is preferable (remove the     -->
<!-- apply-templates) and/or maybe a lower priority    -->
<!-- will work better.                                 -->

<!--
<xsl:template match="*" priority="0">
    <xsl:message>[<xsl:value-of select="local-name(.)"/>]</xsl:message>
    <xsl:apply-templates/>
</xsl:template>
-->

</xsl:stylesheet>
