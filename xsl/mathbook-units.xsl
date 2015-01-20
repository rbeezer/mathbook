<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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

<!-- This file contains unit-related abbreviations,              -->
<!-- such as 'kilo' => 'k' and 'meter' => 'm'.                   -->
<!-- These are used by the quant/unit and quant/per elements     -->
<!-- for HMTL output, and possibly other places in the future.   -->
<!-- (For tex, the siunitx package knows \kilo, \meter, etc.)    -->
<!-- To Do: enable siunitx's \of{}. Trivial for LaTeX side, but  -->
<!-- for HTML side, would want CSS to control simultaneous       -->
<!-- subscript and superscript.                                  -->

<!-- Unit prefixes (the prefix attribute in a unit or per tag)   -->
<!-- SI prefixes                                                 -->
<xsl:variable name="prefixes">
    <prefix full='yocto'             short='y'/>
    <prefix full='zepto'             short='z'/>
    <prefix full='atto'              short='a'/>
    <prefix full='femto'             short='f'/>
    <prefix full='pico'              short='p'/>
    <prefix full='nano'              short='n'/>
    <prefix full='micro'             short='&#xb5;'/>
    <prefix full='milli'             short='m'/>
    <prefix full='centi'             short='c'/>
    <prefix full='deci'              short='d'/>
    <prefix full='deca'              short='da'/>
    <prefix full='deka'              short='da'/>
    <prefix full='hecto'             short='h'/>
    <prefix full='kilo'              short='k'/>
    <prefix full='mega'              short='M'/>
    <prefix full='giga'              short='G'/>
    <prefix full='tera'              short='T'/>
    <prefix full='peta'              short='P'/>
    <prefix full='exa'               short='E'/>
    <prefix full='zetta'             short='Z'/>
    <prefix full='yotta'             short='Y'/>
</xsl:variable>


<!-- Unit bases  (the base attribute in a unit or per tag)   -->
<xsl:variable name="bases">
<!-- SI fundamental units                                    -->
    <base full='ampere'            short='A'/>
    <base full='candela'           short='cd'/>
    <base full='kelvin'            short='K'/>
    <base full='gram'              short='g'/>
    <base full='meter'             short='m'/>
    <base full='metre'             short='m'/>
    <base full='mole'              short='mol'/>
    <base full='second'            short='s'/>

<!-- SI derived units and non-SI units with a simple relationship to SI units -->
    <!-- Radioactivity                                                        -->
    <base full='becquerel'         short='Bq'/>
    <base full='gray'              short='Gy'/>
    <base full='sievert'           short='Sv'/>

    <!-- Temperature                                                          -->
    <base full='degreeCelsius'     short='&#176;C'/>
    <base full='celsius'           short='&#176;C'/>

    <!-- Elecro-magnetic                                                      -->
    <base full='coulomb'           short='C'/>
    <base full='henry'             short='H'/>
    <base full='ohm'               short='&#8486;'/>
    <base full='siemens'           short='S'/>
    <base full='tesla'             short='T'/>
    <base full='volt'              short='V'/>
    <base full='weber'             short='Wb'/>

    <!-- Frequency and Catalytic Activity                                     -->
    <base full='hertz'             short='Hz'/>
    <base full='katal'             short='kat'/>

    <!-- Energy, Work, Power, Force                                           -->
    <base full='joule'             short='J'/>
    <base full='newton'            short='N'/>
    <base full='pascal'            short='Pa'/>
    <base full='watt'              short='W'/>

    <!-- Candela-related                                                      -->
    <base full='lumen'             short='lm'/>
    <base full='lux'               short='lx'/>

    <!-- Angle (2D and 3D)                                                    -->
    <base full='radian'            short='rad'/>
    <base full='steradian'         short='sr'/>
    <base full='degree'            short='&#176;'/>
    <base full='arcminute'         short='&#8242;'/>
    <base full='arcsecond'         short='&#8243;'/>

    <!-- Time                                                                 -->
    <base full='day'               short='d'/>
    <base full='hour'              short='h'/>
    <base full='minute'            short='min'/>

    <!-- Area                                                                 -->
    <base full='hectare'           short='ha'/>

    <!-- Volume                                                               -->
    <base full='liter'             short='L'/>
    <base full='litre'             short='l'/>

    <!-- Percent                                                              -->
    <base full='percent'           short='&#37;'/>

<!-- completely non-SI units; these are not part of the siunitx package, so they    -->
<!-- need siunitx='none'. The value of 'short' will be used as the macro output,    -->
<!-- unless something else is specified. This is necessary if the value of 'short'  -->
<!-- has unusual characters, as with Fahrenheit below.                              -->
    <!-- Temperature                                                                -->
    <base full='degreeFahrenheit'  short='&#176;F'  siunitx='\SIUnitSymbolDegree{F}' />
    <base full='fahrenheit'        short='&#176;F'  siunitx='\degreeFahrenheit'      />

    <!-- Weight, Force                                                              -->
    <base full='pound'             short='lb'       siunitx='none' />

    <!-- Length                                                                     -->
    <base full='foot'              short='ft'       siunitx='none' />
    <base full='inch'              short='in'       siunitx='none' />
    <base full='yard'              short='yd'       siunitx='none' />
    <base full='mile'              short='mi'       siunitx='none' />

    <!-- Speed                                                                      -->
    <base full='mileperhour'       short='mph'      siunitx='none' />

    <!-- Volume                                                                     -->
    <base full='gallon'            short='gal'      siunitx='none' />

</xsl:variable>



</xsl:stylesheet>
