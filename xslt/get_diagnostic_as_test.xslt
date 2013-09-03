<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>

  <xsl:template match="*[local-name()='diagnostic']">
    <xsl:apply-templates select="*" mode="diagnostic"/>
  </xsl:template>
  
  <!-- 
    NOTE: Output format is used by test script to set shell variables
  -->
  <xsl:template match="*" mode="diagnostic">
    <xsl:value-of select="concat(local-name(),'=',text(),'&#x0a;')"/>
  </xsl:template>
  
</xsl:stylesheet>
