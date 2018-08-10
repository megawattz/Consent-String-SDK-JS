--[[*
   * Number of bits for encoding the version integer
   * Expected to be the same across versions
--]]
local versionNumBits = 6;

--[[*
   * Definition of the consent string encoded format
   *
   * From https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/Draft_for_Public_Comment_Transparency%20%26%20Consent%20Framework%20-%20cookie%20and%20vendor%20list%20format%20specification%20v1.0a.pdf
--]]

local vendorVersionMap = {
   -- Version 1
   [1] = {
      version = 1,
      metadataFields = {'version', 'created', 'lastUpdated', 'cmpId',
			'cmpVersion', 'consentScreen', 'vendorListVersion'},
      fields = {
	 { name = 'version', datatype = 'int', numBits = 6 },
	 { name = 'created', datatype = 'date', numBits = 36 },
	 { name = 'lastUpdated', datatype = 'date', numBits = 36 },
	 { name = 'cmpId', datatype = 'int', numBits = 12 },
	 { name = 'cmpVersion', datatype = 'int', numBits = 12 },
	 { name = 'consentScreen', datatype = 'int', numBits = 6 },
	 { name = 'consentLanguage', datatype = 'language', numBits = 12 },
	 { name = 'vendorListVersion', datatype = 'int', numBits = 12 },
	 { name = 'purposeIdBitString', datatype = 'bits', numBits = 24 },
	 { name = 'maxVendorId', datatype = 'int', numBits = 16 },
	 { name = 'isRange', datatype = 'bool', numBits = 1 },
	 {
	    name = 'vendorIdBitString',
	    datatype = 'bits',
	    numBits = function(decodedObject) return decodedObject.maxVendorId end,
	    validator = function(decodedObject) return decodedObject.isRange end,
	 },
	 {
	    name = 'defaultConsent',
	    datatype = 'bool',
	    numBits = 1,
	    validator = function(decodedObject) return decodedObject.isRange end,
	 },
	 {
	    name = 'numEntries',
	    numBits = 12,
	    datatype = 'int',
	    validator = function(decodedObject) return decodedObject.isRange end,
	 },
	 {
	    name = 'vendorRangeList',
	    datatype = 'list',
	    listCount = function(decodedObject) return decodedObject.numEntries end,
	    validator = function(decodedObject) return decodedObject.isRange end,
	    fields = {
	       {
		  name = 'isRange',
		  datatype = 'bool',
		  numBits = 1,
	       },
	       {
		  name = 'startVendorId',
		  datatype = 'int',
		  numBits = 16,
	       },
	       {
		  name = 'endVendorId',
		  datatype = 'int',
		  numBits = 16,
		  validator = function(decodedObject) return decodedObject.isRange end,
	       },
	    },
	 },
      },
   },
};

return {
   vendorVersionMap = vendorVersionMap
}
