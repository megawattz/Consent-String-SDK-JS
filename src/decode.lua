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
   vendorIdBitString,
   vendorRangeList,
   cmpVersion,
   consentScreen,
   cmpId,
   vendorListVersion,
   purposeIdBitString,
   maxVendorId,
   created,
   lastUpdated,
   isRange,
   defaultConsent,
   consentLanguage = bits.decodeFromBase64(consentString)
   
   local decoded = bits.decodeFromBase64(consentString);
   utils.reveal("consentStringDecoded:"..utils.as_string(decoded))
   
   --utils.reveal("from list consentStringData-2:"..utils.as_string(consentStringData));

   --utils.reveal("vendorRangeList:"..utils.as_string(vendorRangeList))
   
   local consentStringData = {
      version = decoded.version,
      cmpId = decoded.cmpId,
      vendorListVersion = decoded.vendorListVersion,
      allowedPurposeIds = bits.decodeBitsToIds(purposeIdBitString),
      maxVendorId = decoded.maxVendorId,
      created = decoded.created,
      lastUpdated = decoded.lastUpdated,
      cmpVersion = decoded.cmpVersion,
      consentScreen = decoded.consentScreen,
      consentLanguage = decoded.consentLanguage,
   };
   
   utils.reveal("isRange:"..utils.as_string(decoded.isRange))
   
   if decoded.isRange then
      local idMap = bits.reduce(decoded.vendorRangeList, function(acc, ise)
				   local isRange, startVendorId, endVendorId =
				      ise.isRange, ise.endVendorId, ise.startVendorId
				   
				   local lastVendorId = utils.iftrue(isRange, endVendorId, startVendorId)
				   
				   for i = startVendorId, lastVendorId, 1 do
				      acc[i] = true
				   end
				   
				   return acc
						 end, {});
      
      consentStringData.allowedVendorIds = {};

      utils.reveal("idMap:"..utils.as_string(idMap))
      
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

   --utils.reveal(string.format("Decode:%s=%s", consentString, utils.as_string(consentStringData)))
   
   return consentStringData;
end

return {
   decodeConsentString = decodeConsentString
}

