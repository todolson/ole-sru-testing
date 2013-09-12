<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="/*[local-name()='searchRetrieveResponse']">
    <xsl:if test="not(*[local-name()='version'])">
      <xsl:message terminate="yes">
        <xsl:text>ERROR: &lt;version&gt; expected but not found</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="*[local-name()='version']">
    <xsl:copy-of select="text()"/>
  </xsl:template>
</xsl:stylesheet>
