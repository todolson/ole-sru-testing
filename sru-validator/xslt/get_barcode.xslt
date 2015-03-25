<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:m="http://www.loc.gov/MARC21/slim">
  
  <xsl:output method="text"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="circulation">
    <xsl:if test="not(itemId)">
      <xsl:message terminate="yes">
        <xsl:text>circulation/itemId does not exist; no barcode is present</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="//circulation[1]/itemId">
    <xsl:value-of select="concat(text(), '&#x0a;')"/>
  </xsl:template>
  
</xsl:stylesheet>
