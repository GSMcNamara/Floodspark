local cjson = require("cjson")
local fs_functions = require "/srv/www/floodspark/fs_functions"
local http = require "resty.http"
local httpc = http.new()

ngx.req.read_body()
ip = ngx.var.remote_addr

if fs_functions.check_list(ip) ~= "white" then

	body = ngx.var.request_body
	input_json = {}
	-- for requests that lack a body (e.g. initial GET for the JS, etc)
	if body ~= nil then
		input_json = cjson.decode(body)
	end

	output_json = {}

	--tor check
	if input_json["screen.height"] ~= nil and input_json["window.innerHeight"] ~= nil then
		if input_json["screen.height"] == input_json["window.innerHeight"] then
			output_json["browser.tor"] = true  
		end
	end

	--incognito check
	if input_json["storage"] ~= nil then
		if tonumber(input_json["storage"]) < 120000000 then
			output_json["browser.chrome.incognito"] = true
		end
	end

	--Firefox private browsing check
	if input_json["browser.firefox.private"] == true then
		output_json["browser.firefox.private"] = true
	end

	--Chrome Selenium check
	if input_json["navigator.webdriver"] == true then
		output_json["browser.chrome.selenium"] = true
	end


	--POST results to Logstash/ELK
	--we only report baddies. If desired to also report legit traffic...
	--be wary of below because it just checks if output_json was populated...
	--with ANYTHING. If populated, it's assumed it has data about a baddie
	if next(output_json) ~= nil then
		output_json = cjson.encode(output_json)
	-- abandoned below because of HTTP2 issue known to Resty folks
	--	res = ngx.location.capture(
	--		'/logstash',
	--    		{ version = 1.0,  method = ngx.HTTP_POST, body = output_json }
	--	)
		res, err = httpc:request_uri("http://elk:5045", {method = "POST", body = output_json})
		fs_functions.list(ip, "black")
	end

	--if GET request, return Javascript
	if string.match(ngx.var.request_method, "GET") then
		local file = "/srv/www/floodspark/fs.js"
		local f = io.open(file, "rb")
		local content = f:read("*all")
		f:close()
		ngx.print(content)
	end
end
