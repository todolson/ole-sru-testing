<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml"/>
  
  <xsl:param name="outfile_base" select="'record_data'"/>
  
  <xsl:template match="@*|node()">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:template>
  
  <xsl:template match="@*|node()" mode="identity">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="identity"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[local-name()='recordData']">
    <xsl:variable name="recNum" select="../*[local-name()='recordPosition']"/>
    <xsl:result-document href="{$outfile_base}_{$recNum}.xml">
      <!-- only copy children, not recordData node -->
      <xsl:apply-templates select="*" mode="identity"/>
    </xsl:result-document>
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
