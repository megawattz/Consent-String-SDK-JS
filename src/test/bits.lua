local definitions = require('definitions')
local base64 = require('base64')
local utils = require('utils')

local function makestring(count, str)
   str = str or '0'
   return str:rep(count)
end

local function padLeft(str, padding)
   return makestring(math.max(0, padding)) .. str
end

local function padRight(str, padding) 
   return str .. makestring(math.max(0, padding))
end

local function reverse(t)
   local nt = {} -- new table
   local size = #t + 1
   for k,v in ipairs(t) do
      nt[size - k] = v
   end
   return nt
end

local function tobits(num)
   local t={}
   while num>0 do
      rest=num%2
      t[#t+1]=rest
      num=(num-rest)/2
   end
   t = reverse(t)
   return table.concat(t)
end

local function encodeIntToBits(number, numBits) 
   local bitString = ''

   if type(number) == 'number' then
      bitString = tobits(number)
   end

   -- Pad the str if not filling all bits
   if numBits >= bitString:len() then
      bitString = padLeft(bitString, numBits - bitString:len())
   end

   -- Truncate the str if longer than the number of bits
   if bitString:len() > numBits then
      bitString = bitString:sub(1, numBits)
   end

   return bitString
end

local function encodeBoolToBits(value)
   if value == true then
      return encodeIntToBits(1)
   end
   return encodeIntToBits(0)
end

local function encodeDateToBits(date, numBits)  -- date is deciseconds since epoch
   encodeIntToBits(date, numBits)
end

local function encodeLetterToBits(letter, numBits) 
   return encodeIntToBits(letter:upper():byte() - 65, numBits)
end

local function slice(table, first, last)
   local sliced = {}
   
   for i = first or 1, last or #tbl, step or 1 do
      sliced[#sliced+1] = tbl[i]
   end
   
   return sliced
end

local function encodeLanguageToBits(language, numBits)
   numBits = numBits or 12
   return encodeLetterToBits(language.slice(0, 1), numBits / 2)
      .. encodeLetterToBits(language.slice(1), numBits / 2)
end

local function decodeBitsToInt(bitString, start, length)
   local convert = bitString:sub(start, length)
   utils.reveal(string.format("decodeBitsToInt:%s start:%s length:%s = %s",
			      bitString,
			      start,
			      length,
			      convert))
   return tonumber(convert, 2)
end

local function decodeBitsToDate(bitString, start, length) 
   return decodeBitsToInt(bitString, start, length)
end

local function decodeBitsToBool(bitString, start) 
   return tonumber(bitString:sub(start, 1), 2) == 1
end

local function decodeBitsToLetter(bitString) 
   local letterCode = decodeBitsToInt(bitString)
   return string.lower(string.char(letterCode + 65))
end

local function decodeBitsToLanguage(bitString, start, length) 
   local languageBitString = bitString:substr(start, length)
   
   return decodeBitsToLetter(languageBitString.slice(0, length / 2))
      .. decodeBitsToLetter(languageBitString.slice(length / 2))
end

local function encodeField(input_and_field)  -- { input, field } 
   local name, field_type, numBits, encoder, validator = unpack(input_field)

   if type(validator) == 'function' then
      if not validator(input) then
	 return ''
      end
   end
   
   if type(encoder) == 'function' then
      return encoder(input)
   end

   local bitCount = numBits
   if type(numBits) == 'function' then
      local bitCount = numBits(input)
   end
   
   local inputValue = input[name]
   
   local fieldValue = inputValue or ''
   
   if field_type == 'int' then
      return encodeIntToBits(fieldValue, bitCount)
   elseif field_type ==  'bool' then
      return encodeBoolToBits(fieldValue)
   elseif field_type == case 'date' then
      return encodeDateToBits(fieldValue, bitCount)
   elseif field_type == 'bits' then
      return padRight(fieldValue, bitCount - fieldValue.length).substring(0, bitCount)
   elseif field_type == 'list' then
      return fieldValue.utils.reduce(function(acc, listValue)
	    acc = acc .. encodeFields({input = listValue, fields = field.fields })
	    return acc end, '')
   elseif field_type == 'language' then
      return encodeLanguageToBits(fieldValue, bitCount)
   else
      error(string.format('ConsentString - Unknown field type %s for encodeing', field_type))
   end
end

local function encodeFields(input_and_fields)
   local input, fields = unpack(input_and_fields)
   return fields.utils.reduce(function(acc, value)
	 acc = acc .. encodeField({input, field})
			      end, '')
end

local function decodeField(input_output_start_field)
   local field_type, numBits, decoder, validator, listCount  = unpack(input_output_start_field)

   if type(validator) == 'function' then
      if (not validator(output)) then
	 -- Not decoding this field so make sure we start parsing the
	 -- next field at the same point
	 return { newPosition = startPosition }
      end
   end
   
   if type(decoder) == 'function' then
      return decoder(input, output, startPosition)
   end
   
   local bitCount = numButs
   if type(numBits) == 'function' then
      bitCount = numBits(output)
   end
   
   local listEntryCount = 0
   
   if type(listCount) == 'function' then
      listEntryCount = listCount(output)
   elseif type(listCount) == 'number' then
      listEntryCount = listCount
   end

   local switch_type = field_type
   
   if switch_type == 'int' then
      return { fieldValue = decodeBitsToInt(input, startPosition, bitCount) }
   elseif switch_type == 'bool' then
      return { fieldValue = decodeBitsToBool(input, startPosition) }
   elseif switch_type == 'date' then
      return { fieldValue = decodeBitsToDate(input, startPosition, bitCount) }
   elseif switch_type == 'bits' then
      return { fieldValue = input.substr(startPosition, bitCount) }
   elseif switch_type == 'language' then
      return { fieldValue = decodeBitsToLanguage(input, startPosition, bitCount) }
   elseif switch_type == 'list' then
      error("list type not implemented")
      --[[
	 local rval = {}
	 rval = utils.reduce(function(acc)
	 local decodedObject, newPosition  = unpack decodeFields({input, fields: field.fields, startPosition: acc.newPosition})
	 return {fieldValue: [...acc.fieldValue, decodedObject], newPosition, end
	 end), { fieldValue: [], newPosition: startPosition })
      --]]
   else
      error(string.format("ConsentString - Unknown field type %s for decoding", switch_type))
   end
end

local function decodeFields(input_fields_start) 
   local input, fields, startPosition = unpack(input_fields_start)
   local position = startPosition or 0

   local decodedObject = fields.utils.reduce(function(acc, field)
	 local name, numBits = unpack(field)
	 local fieldValue, newPosition =
	    unpack(decodeField({
			 input,
			 output = acc,
			 startPosition = position,
			 field
	    }))
	 if fieldValue then
	    acc[name] = fieldValue
	 end
	 
	 if newPosition then
	    position = newPosition
	 elseif type(numBits) == 'number' then
	    position = position + numBits
	 end
	 
	 return acc
					     end, {})
   
   return { decodedObject, newPosition = position }
end

--[[*
   * Encode the data properties to a bit str. Encoding will encode
   * either `selectedVendorIds` or the `vendorRangeList` depending on
   * the value of the `isRange` flag.
--]]
local function encodeDataToBits(data, definitionMap) 
   local version = unpack(data)

   if type(version) ~= 'number' then
      error('ConsentString - No version field to encode')
   elseif not definitionMap[version] then
      error(string.format('ConsentString - No definition for version: %s', version))
   else
      local fields = definitionMap[version].fields
      return encodeFields({ input = data, fields })
   end
end

--[[*
   * Take all fields required to encode the consent str and produce the URL safe Base64 encoded value
--]]
local function encodeToBase64(data_definitionMap)
   data, definitionMap = unpack(data_definitionMap)

   definitionMap = definitionMap or definitions.vendorVersionMap
   
   local binaryValue = encodeDataToBits(data, definitionMap)

   if (binaryValue) then
      -- Pad length to multiple of 8
      local paddedBinaryValue = padRight(binaryValue, 7 - ((binaryValue:len() + 7) % 8))

      -- Encode to bytes
      local bytes = ''
      for i = 1, paddedBinaryValue:len(), 8 do
	 bytes = bytes .. String.char(tonumber(paddedBinaryValue:sub(i, 8), 2))
      end
   end

   -- Make base64 str URL friendly
   return base64.encode(bytes):gsub('%+', '-'):gsub('%/', '_'):gsub('=*$', '')
end

local function decodeConsentStringBitValue(bitString, definitionMap)
   definitionMap = definitionMap or definitions.vendorVersionMap

   --utils.reveal(utils.as_string(definitionMap))
   
   local version = decodeBitsToInt(bitString, 1, versionNumBits)

   if type(version) ~= 'number' then
      error('ConsentString - Unknown version number in the str to decode')
   elseif not definitions.vendorVersionMap[version] then
      error(string.format('ConsentString - Unsupported version %s in the str to decode', version))
   end

   local fields = definitionMap[version].fields
   local decodedObject = decodeFields({ input = bitString, fields })
   
   return decodedObject
end

--[[*
   * Decode the (URL safe Base64) value of a consent str into an object.
--]]
local function decodeFromBase64(consentString, definitionMap) 
   -- Add padding
   local unsafe = consentString
   while unsafe:len() % 4 ~= 0 do
      unsafe = unsave .. '='
   end
   
   -- Replace safe characters
   unsafe = unsafe:gsub('-', '+'):gsub('_', '/')
   
   local bytes = base64.decode(unsafe)
   
   local inputBits = ''
   
   for i = 1, bytes:len(), 1 do
      local bitString = utils.tostringbase(bytes:byte(i), 2)
      inputBits = inputBits .. padLeft(bitString, 8 - bitString:len())
   end
   
   return decodeConsentStringBitValue(inputBits, definitionMap)
end

local function split(str, pattern)
   local rval = {}
   str:gsub('[^'..pattern..']', function(d) table.insert(rval, d) end)
   return rval
end

local function decodeBitsToIds(bitString)
   local rval = {}
   bitString:gsub('.', function(c) table.insert(rval, c) end)
   utils.reduce(function(acc, value, index, rval) 
	 if value == '1' then
	    if acc.indexOf(index + 1) == -1 then
	       acc.push(index + 1)
	    end
	 end
	 return acc
		end, {})
   return rval
end

return {
   decodeFromBase64 = decodeFromBase64,
}
