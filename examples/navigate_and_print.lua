-- To run the example make sure the Microsoft Edge Webdriver server is running
-- The server executable can be obtained following the instructions at: https://learn.microsoft.com/en-us/microsoft-edge/webdriver-chromium/?tabs=c-sharp
-- The server executable is available here (direct link) but need to download the right version as mentioned in the instructions: https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/


-- This example opens the Edge browse by creating a new session and then goes to google.com
-- After that it gets the PDF print for the page. The PDF data is written to the file test.pdf

PORT = 9515	-- This is the port where the webdriver server is listening. This should be changed if it is listening at another port. When the webdriver executable is run then it shows the port number


local wd = require("luawebdriver")
local conn = wd.new(PORT,"MicrosoftEdge")

local stat,msg = conn:gotoURL({ body = { url = "http://google.com"} })

-- Get the page source
local page_source = conn:getPageSource().value

-- Print the page
local prnt = conn:printPage({body="{}"}).value	-- So print parameters given. See here for the allowed list: https://www.w3.org/TR/webdriver/#dfn-print-page

local mime = require("mime")
local pdf = mime.unb64(prnt)

local f = io.open("test.pdf","w+b")
f:write(pdf)
f:close()

-- All Done