Simple scripts for testing SRU in Kuali OLE


XML validation:

Note that the copies of the SRU 1.2 schema under xsd/search-ws 
have been modified so that thier `xs:import statements` refer
to sibling files in that directory. I originally tried to
address this with an XML catalog file and options to `xmllint`,
but could never get it to work.
