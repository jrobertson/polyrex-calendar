<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" indent="yes" />

<xsl:template match="calendar">

<html lang="en">

  <head>
    <title><xsl:value-of select="summary/year"/> Calendar | generated by Polrex-Calendar</title>
    <link rel="stylesheet" href="xlayout.css"/>
  </head>

  <body>
    <div id="wrap">
    <h1><xsl:value-of select="summary/year"/></h1>
      <xsl:apply-templates select="records"/>
    </div>
  </body>
</html>

</xsl:template>

<xsl:template match="records/month">
  <div class="table">
    <table border="1">
      <xsl:apply-templates select="summary"/>
      <tr><th>S</th><th>M</th><th>T</th><th>W</th><th>T</th><th>F</th><th>S</th></tr>
      <xsl:apply-templates select="records"/>
    </table>
  </div>
</xsl:template>

<xsl:template match="month/summary">
  <caption><xsl:value-of select="name"/></caption>
</xsl:template>

<xsl:template match="records/week">
  <xsl:apply-templates select="summary"/>  
  <xsl:element name="tr">
    <xsl:apply-templates select="records"/>
  </xsl:element>
</xsl:template>

<xsl:template match="week/summary">
  
</xsl:template>

<xsl:template match="records/day">
  <xsl:apply-templates select="summary"/>
  <xsl:apply-templates select="records"/>
</xsl:template>

<xsl:template match="day/summary">
  <td><xsl:value-of select="xday"/></td>
</xsl:template>

</xsl:stylesheet>
