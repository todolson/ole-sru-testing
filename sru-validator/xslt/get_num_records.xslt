<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  
  <xsl:param name="print_diag" select="true()"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="*[local-name()='searchRetrieveResponse']">
    <xsl:if test="not(*[local-name()='numberOfRecords'])">
      <xsl:message terminate="yes">
        <xsl:text>numberOfRecords is missing</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="*[local-name()='numberOfRecords']">
    <xsl:value-of select="concat(text(), '&#x0A;')"/>
  </xsl:template>
  
  <xsl:template match="*[local-name()='diagnostic']">
    <xsl:if test="$print_diag">
      <xsl:message>
        <xsl:text>DIAGNOSTIC: </xsl:text>
        <xsl:value-of select="uri"/> 
        <xsl:text> </xsl:text>
        <xsl:value-of select="message"/>
      </xsl:message>
    </xsl:if>
   </xsl:template>
  
</xsl:stylesheet>
