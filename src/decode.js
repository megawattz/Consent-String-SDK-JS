const {
  decodeBitsToIds,
  decodeFromBase64,
} = require('./utils/bits');

const utils = require('./utils/utils')

/**
 * Decode consent data from a web-safe base64-encoded string
 *
 * @param {string} consentString
 */
function decodeConsentString(consentString) {
  const {
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
    consentLanguage,
  } = decodeFromBase64(consentString);

    const stuff = decodeFromBase64(consentString);
    //utils.reveal("consentString:"+consentString)
    //utils.reveal("purposeIdBitString:"+utils.as_string(stuff))
    
    const consentStringData = {
    version,
    cmpId,
    vendorListVersion,
    allowedPurposeIds: decodeBitsToIds(purposeIdBitString),
    maxVendorId,
    created,
    lastUpdated,
    cmpVersion,
    consentScreen,
    consentLanguage,
  };

    //utils.reveal("vendorRangeList:"+utils.as_string(vendorRangeList))
    
    if (isRange) {
	/* eslint no-shadow: off */
    const idMap = vendorRangeList.reduce((acc, { isRange, startVendorId, endVendorId }) => {
      const lastVendorId = isRange ? endVendorId : startVendorId;

      for (let i = startVendorId; i <= lastVendorId; i += 1) {
        acc[i] = true;
      }

      return acc;
    }, {});

    consentStringData.allowedVendorIds = [];

    for (let i = 1; i <= maxVendorId; i += 1) {
      if (
        (defaultConsent && !idMap[i]) ||
        (!defaultConsent && idMap[i])
      ) {
        if (consentStringData.allowedVendorIds.indexOf(i) === -1) {
          consentStringData.allowedVendorIds.push(i);
        }
      }
    }
  } else {
    consentStringData.allowedVendorIds = decodeBitsToIds(vendorIdBitString);
  }

    //utils.reveal(utils.sprintf("Decode:%s=%s", consentString, utils.as_string(consentStringData)))
    
  return consentStringData;
}

module.exports = {
  decodeConsentString,
};
