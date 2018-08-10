-- test functions to emulate JavaScript chai

function assert(condition_as_string, description)
   local success, rval = pcall(loadstring("return ("..condition_as_string..")"))
   if not success then
      error(string.format("test %s fails due to exception %s", description, condition_as_string))
   end
   if not rval then
      error(string.format("test %s fails because %s is false", description, condition_as_string))
   end
end

function describe(description_of_tests, test_function) -- batch of tests
   test_function()
end

function it(description_of_test, test_function) -- single test
   test_function()
end

return {
   assert = assert,
   describe = describe,
   it = it
}
