<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="@*|node()" mode="identity">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="identity"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[local-name()='recordData'][1]">
    <!-- only copy children, not recordData node -->
    <xsl:apply-templates select="*" mode="identity"/>
  </xsl:template>
  
  <xsl:template match="*[local-name()='diagnostics']">
    <xsl:apply-templates select="@*|node()"/>
    <xsl:message terminate="yes">Terminating XSLT processing</xsl:message>
  </xsl:template>
  
  <xsl:template match="*[local-name()='diagnostic']">
    <xsl:message>
      <xsl:text>DIAGNOSTIC: </xsl:text>
      <xsl:value-of select="uri"/> 
      <xsl:text> </xsl:text>
      <xsl:value-of select="message"/></xsl:message>
  </xsl:template>
  
</xsl:stylesheet>
