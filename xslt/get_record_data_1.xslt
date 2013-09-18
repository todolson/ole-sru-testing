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
  
  <xsl:template match="*[local-name()='records']">
    <!-- only process the first record -->
    <xsl:apply-templates select="*[local-name()='record'][1]"/>
  </xsl:template>
  
  <xsl:template match="*[local-name()='recordData']">
    <!-- only copy children, not recordData node -->
    <xsl:apply-templates select="*" mode="identity"/>
  </xsl:template>
  
  <xsl:template match="*[local-name()='diagnostics']">
    <xsl:apply-templates select="@*|node()"/>
    <xsl:message terminate="yes">Terminating XSLT processing</xsl:message>
  </xsl:template>
  
  <xsl:template match="*[local-name()='diagnostic']">
    <xsl:message>
      <xsl:text>DIAGNOSTIC: &#x0a;</xsl:text>
      <xsl:apply-templates select="*" mode="diagnostic"/>
    </xsl:message>
  </xsl:template>
  
  <xsl:template match="*" mode="diagnostic">
    <xsl:value-of select="concat(local-name(),'=',text(),'&#x0a;')"/>
  </xsl:template>
  
</xsl:stylesheet>
