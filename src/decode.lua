local bits = require('bits')
local utils = require('utils')

--[[*
    * Decode consent data from a web-safe base64-encoded string
    *
    * @param {string} consentString
    --]]
function decodeConsentString(consentString)
   local
      version,
   cmpId,
   vendorListVersion,
   purposeIdBitString,
   maxVendorId,
   created,
   lastUpdated,
   isRange,
   defaultConsent,
   vendorIdBitString,
   vendorRangeList,
   cmpVersion,
   consentScreen,
   consentLanguage
      = bits.decodeFromBase64(consentString);

   utils.reveal("purposeIdBitString:"..utils.as_string{bits.decodeFromBase64(consentString)} )
   
   local consentStringData = {
      version = version,
      cmpId = cmpId,
      vendorListVersion = vendorListVersion,
      allowedPurposeIds = bits.decodeBitsToIds(purposeIdBitString),
      maxVendorId = maxVendorId,
      created = created,
      lastUpdated = lastUpdated,
      cmpVersion = cmpVersion,
      consentScreen = consentScreen,
      consentLanguage = consentLanguage,
   };
   
   utils.reveal("lua decodeFromBase64:"..utils.as_string(consentStringData));
   
   if isRange then
      local idMap = bits.reduce(vendorRangeList, function(acc, isrange_startvendorid_endvendorid)
				   local isRange, startVendorId, endVendorId = unpack(isrange_startvendorid_endvendorid)
				   local lastVendorId = utils.iftrue(isRange, endVendorId, startVendorId)
				   
				   for i = startVendorId, lastVendorId, 1 do
				      acc[i] = true
				   end
				   
				   return acc
						 end, {});
      
      consentStringData.allowedVendorIds = {};
      
      for i = 1, maxVendorId, 1 do
	 if (defaultConsent and not idMap[i]) or (not defaultConsent and idMap[i]) then
	    if not utils.find(consentStringData.allowedVendorIds, i) then
	       table.insert(consentStringData.allowedVendorIds, i)
	    end
	 end
      end
   else 
	 consentStringData.allowedVendorIds = bits.decodeBitsToIds(vendorIdBitString);
   end
   
   return consentStringData;
end

return {
   decodeConsentString = decodeConsentString
}

