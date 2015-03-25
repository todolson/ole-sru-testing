<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>

  <!-- get namespace of document element -->
  <xsl:template match="/*">
    <xsl:value-of select="namespace-uri()"/>
  </xsl:template>
  
</xsl:stylesheet>
