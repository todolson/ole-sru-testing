<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:m="http://www.loc.gov/MARC21/slim">
  
  <xsl:output method="text"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="m:datafield[@tag='245']/m:subfield[@code='a']">
    <xsl:value-of select="concat(text(), '&#x0A;')"/>
  </xsl:template>
  
</xsl:stylesheet>
