local cjson = require("cjson")
local fs_functions = require "/srv/www/floodspark/fs_functions"
local http = require "resty.http"
local httpc = http.new()

ip = ngx.var.remote_addr

if fs_functions.check_list(ip) ~= "white" then
	output_json = {}
	if (ngx.var.http_user_agent ~= nil) then
		uas = string.lower(ngx.var.http_user_agent)
        	if string.match(uas, "google") then
			real = fs_functions.confirm_googlebot(ip)
			if real == false then
				output_json["googlebot.fake"] = true
			else
				fs_functions.list(ip, "white")
				return
			end
		end
		if string.match(uas, "wget") then
                	output_json["tool.wget"] = true
        	end
        	if string.match(uas, "curl") then
                	output_json["tool.curl"] = true
        	end
	end

	--we only report baddies. If desired to also report legit traffic...
	--be wary of below because it just checks if output_json was populated...
	--with ANYTHING. If populated, it's assumed it has data about a baddie
	if next(output_json) ~= nil then
        	output_json = cjson.encode(output_json)
		ngx.log(ngx.STDERR, output_json)

	-- abandoned below because of HTTP2 issue known to Resty folks
	--      res = ngx.location.capture(
	--              '/logstash',
	--              { version = 1.0,  method = ngx.HTTP_POST, body = output_json }
	--      )
        	res, err = httpc:request_uri("http://elk:5045", {method = "POST", body = output_json})
        	fs_functions.list(ip, "black")
	end
end
