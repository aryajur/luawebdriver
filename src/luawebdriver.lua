-- Module for sending commands to the webdriver server
-- Endpoints documentation: https://www.w3.org/TR/webdriver/#endpoints

-- Load the HTTP client and JSON libraries
local http = require("socket.http")
local json = require("dkjson")
local ltn12 = require("ltn12")
local tu = require("tableUtils")

local getmetatable = getmetatable
local setmetatable = setmetatable
local type = type
local table = table
local pairs = pairs

--local print = print


-- Create the module table here
local M = {}
package.loaded[...] = M
if setfenv and type(setfenv) == "function" then
	setfenv(1,M)	-- Lua 5.1
else
	_ENV = M		-- Lua 5.2+
end

_VERSION = "1.23.08.10"

local function postRequest(endpoint,jsonBody)
	local response_body = {}
	-- Send a POST request to start a new session
	local _, status_code, headers, status_line = http.request {
		url = endpoint,
		method = "POST",
		headers = {
			["Content-Type"] = "application/json",
			["Content-Length"] = #jsonBody
		},
		source = ltn12.source.string(jsonBody),
		sink = ltn12.sink.table(response_body)
	}
	--print(status_code,headers,status_line)
	-- Check the status code for errors
	if status_code ~= 200 then
		return nil,"Request failed: " .. (status_line or "").." Code: "..(status_code or "")
	end

	-- Decode the response body from JSON to a Lua table
	return json.decode(table.concat(response_body))
end

local function request(endpoint,method)
	local response_body = {}
	-- Send a POST request to start a new session
	local _, status_code, headers, status_line = http.request {
		url = endpoint,
		method = method,
		sink = ltn12.sink.table(response_body)
	}

	-- Check the status code for errors
	if status_code ~= 200 then
		return nil,"Request failed: " .. status_line
	end

	-- Decode the response body from JSON to a Lua table
	return json.decode(table.concat(response_body))	
end

local meta

meta = {
	__index = function(t,k)
		-- end points as defined at: https://www.w3.org/TR/webdriver/#endpoints
		--[=[
		When calling an endpoint just call with the name in the name field of the endpoint entry.
		The parameters if required should be given in a named parameter table. For example:
		conn:gotoURL({body={url="http://google.com"}})
		For entries with POST method a body parameter is needed with a JSON encoded string or a lua table. If no body needs to be sent then an empty table should be given
		If the endpoint requires an additional parameter for example:
		{name = "getElementShadowRoot",method="GET",endpoint = [[/session/{session id}/element/{elementId}/shadow]]},
		requires {elementId} so the elementId parameter should be there in the named parameter table
		]=]
		local endPoints = {
			{name = "delete",method="DELETE",endpoint = [[/session/{session id}]]},
			{name = "status",method="GET",endpoint = [[/status]]},
			{name = "getTimeouts",method="GET",endpoint = [[/session/{session id}/timeouts]]},
			{name = "setTimeouts",method="POST",endpoint = [[/session/{session id}/timeouts]]},
			{name = "gotoURL",method="POST",endpoint = [[/session/{session id}/url]]},
			{name = "getURL",method="GET",endpoint = [[/session/{session id}/url]]},
			{name = "goBack",method="POST",endpoint = [[/session/{session id}/back]]},
			{name = "goForward",method="POST",endpoint = [[/session/{session id}/forward]]},
			{name = "refresh",method="POST",endpoint = [[/session/{session id}/refresh]]},
			{name = "getTitle",method="GET",endpoint = [[/session/{session id}/title]]},
			{name = "getWindowHnd",method="GET",endpoint = [[/session/{session id}/window]]},
			{name = "closeWindow",method="DELETE",endpoint = [[/session/{session id}/window]]},
			{name = "switchToWindow",method="POST",endpoint = [[/session/{session id}/window]]},
			{name = "getWindowHnds",method="GET",endpoint = [[/session/{session id}/window/handles]]},
			{name = "newWindow",method="POST",endpoint = [[/session/{session id}/window/new]]},
			{name = "switchToFrame",method="POST",endpoint = [[/session/{session id}/frame]]},
			{name = "switchToParentFrame",method="POST",endpoint = [[/session/{session id}/frame/parent]]},
			{name = "getWindowRect",method="GET",endpoint = [[/session/{session id}/window/rect]]},
			{name = "setWindowRect",method="POST",endpoint = [[/session/{session id}/window/rect]]},
			{name = "maximizeWindow",method="POST",endpoint = [[/session/{session id}/window/maximize]]},
			{name = "minimizeWindow",method="POST",endpoint = [[/session/{session id}/window/minimize]]},
			{name = "fullScreenWindow",method="POST",endpoint = [[/session/{session id}/window/fullscreen]]},
			{name = "getActiveElement",method="GET",endpoint = [[/session/{session id}/element/active]]},
			{name = "getElementShadowRoot",method="GET",endpoint = [[/session/{session id}/element/{elementId}/shadow]]},
			{name = "findElement",method="POST",endpoint = [[/session/{session id}/element]]},
			{name = "findElements",method="POST",endpoint = [[/session/{session id}/elements]]},
			{name = "findElementFromElement",method="POST",endpoint = [[/session/{session id}/element/{elementId}/element]]},
			{name = "findElementsFromElement",method="POST",endpoint = [[/session/{session id}/element/{elementId}/element]]},
			{name = "findElementFromShadowRoot",method="POST",endpoint = [[/session/{session id}/shadow/{shadowId}/element]]},
			{name = "findElementsFromShadowRoot",method="POST",endpoint = [[/session/{session id}/shadow/{shadowId}/elements]]},
			{name = "isElementSelected",method="GET",endpoint = [[/session/{session id}/element/{elementId}/selected]]},
			{name = "getElementAttribute",method="GET",endpoint = [[/session/{session id}/element/{elementId}/attribute/{name}]]},
			{name = "getElementProperty",method="GET",endpoint = [[/session/{session id}/element/{elementId}/property/{name}]]},
			{name = "getElementCSSValue",method="GET",endpoint = [[/session/{session id}/element/{elementId}/css/{propertyName}]]},
			{name = "getElementText",method="GET",endpoint = [[/session/{session id}/element/{elementId}/text]]},
			{name = "getElementTagName",method="GET",endpoint = [[/session/{session id}/element/{elementId}/name]]},
			{name = "getElementRect",method="GET",endpoint = [[/session/{session id}/element/{elementId}/rect]]},
			{name = "isElementEnabled",method="GET",endpoint = [[/session/{session id}/element/{elementId}/enabled]]},
			{name = "getComputedRole",method="GET",endpoint = [[/session/{session id}/element/{elementId}/computedrole]]},
			{name = "getComputedLabel",method="GET",endpoint = [[/session/{session id}/element/{elementId}/computedlabel]]},
			{name = "elementClick",method="POST",endpoint = [[/session/{session id}/element/{elementId}/click]]},
			{name = "elementClear",method="POST",endpoint = [[/session/{session id}/element/{elementId}/clear]]},
			{name = "elementSendKeys",method="POST",endpoint = [[/session/{session id}/element/{elementId}/value]]},
			{name = "getPageSource",method="GET",endpoint = [[/session/{session id}/source]]},
			{name = "executeScript",method="POST",endpoint = [[/session/{session id}/execute/sync]]},
			{name = "executeAsyncScript",method="POST",endpoint = [[/session/{session id}/execute/async]]},
			{name = "getAllCookies",method="GET",endpoint = [[/session/{session id}/cookie]]},
			{name = "getNamedCookie",method="GET",endpoint = [[/session/{session id}/cookie/{name}]]},
			{name = "addCookie",method="POST",endpoint = [[/session/{session id}/cookie]]},
			{name = "deleteCookie",method="DELETE",endpoint = [[/session/{session id}/cookie/{name}]]},
			{name = "deleteAllCookies",method="DELETE",endpoint = [[/session/{session id}/cookie]]},
			{name = "performActions",method="POST",endpoint = [[/session/{session id}/actions]]},
			{name = "releaseActions",method="DELETE",endpoint = [[/session/{session id}/actions]]},
			{name = "dismissAlert",method="POST",endpoint = [[/session/{session id}/alert/dismiss]]},
			{name = "acceptAlert",method="POST",endpoint = [[/session/{session id}/alert/accept]]},
			{name = "getAlertText",method="GET",endpoint = [[/session/{session id}/alert/text]]},
			{name = "sendAlertText",method="POST",endpoint = [[/session/{session id}/alert/text]]},
			{name = "takeScreenshot",method="GET",endpoint = [[/session/{session id}/screenshot]]},
			{name = "takeElementScreenshot",method="GET",endpoint = [[/session/{session id}]]},
			{name = "printPage",method="POST",endpoint = [[/session/{session id}/print]]},
		}
		local ep = tu.inArray(endPoints,k,function(v1,v2)
				return v1.name == v2
			end)
		if not ep then
			return function() return nil,"Invalid endpoint called." end
		end
		ep = endPoints[ep]
		if ep.method == "POST" then
			return function(conn,para)
				if ep.method == "POST" and not para.body then
					return nil,"This method needs a message body"
				end
				local endP = ep.endpoint
				endP = endP:gsub("%{session id%}",conn.sessionId)
				for k,v in pairs(para) do
					endP = endP:gsub("%{"..k.."%}",v)
				end
				endP = "http://127.0.0.1:"..conn.port..endP
				local body = para.body
				if type(para.body) == "table" then
					body = json.encode(para.body)
				end
				local stat,msg = postRequest(endP,body)
				if not stat then
					return nil,msg
				end
				return stat				
			end
		else
			return function(conn,para)
				local endP = ep.endpoint
				endP = endP:gsub("%{session id%}",conn.sessionId)
				if para and type(para) == "table" then
					for k,v in pairs(para) do
						endP = endP:gsub("%{"..k.."%}",v)
					end
				end
				endP = "http://127.0.0.1:"..conn.port..endP
				local stat,msg = request(endP,ep.method)
				if not stat then
					return nil,msg
				end
				return stat
			end		
		end
	end
}

-- Connect to the driver and returns the connection object as a new session
function new(port,browser,options)
	local conn = {}
	setmetatable(conn,meta)
	local capabilities = {
		browserName = browser
	}
	if type(options) == "table" then
		for k,v in pairs(options) do
			capabilities[k] = v
		end
	end
	-- Encode the capabilities as a JSON string
	local capabilities = json.encode({
		capabilities = capabilities
	})
	--print(capabilities)
	local server_url = "http://127.0.0.1:"..port
	local response_table,msg = postRequest(server_url .. "/session",capabilities)
	if not response_table then
		return nil,msg
	end
	-- Extract the session ID from the response table
	conn.sessionId = response_table.value.sessionId	
	conn.port = port
	
	return conn

end