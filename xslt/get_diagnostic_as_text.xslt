<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  
  <xsl:param name="fatal" select="false()"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="/">
    <xsl:if test="not(//diagnostic) and $fatal">
      <xsl:message terminate="yes">
        <xsl:text>Diagnostic messaged expected but not found</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates/>
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
