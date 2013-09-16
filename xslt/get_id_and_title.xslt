<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:m="http://www.loc.gov/MARC21/slim">
  
  <xsl:output method="text"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="m:record">
    <xsl:value-of select="m:controlfield[@tag='001'][1]/text()"/>
    <xsl:text>&#x09;</xsl:text>    
    <xsl:value-of select="m:datafield[@tag='245'][1]/m:subfield[@code='a']/text()"/>
    <xsl:text>&#x0A;</xsl:text>    
  </xsl:template>
  
</xsl:stylesheet>
