local fs_functions = {}

local function route()
	if ngx.var.mode == "honeypot" then
		ngx.var.target = "snare:80"
		return
	end
	if ngx.var.mode == "block" then
		return ngx.exit(ngx.HTTP_UNAUTHORIZED)
	end
end

function fs_functions.check_list(ip)
        local redis = require "resty.redis"
        local red = redis:new()
        red:set_timeouts(1000, 1000, 1000) -- 1 sec

        local ok, err = red:connect("redis", 6379)
        if not ok then
--                ngx.say("failed to connect: ", err)
--              failing open:
		return
        end
      
        local res, err = red:hget(ip, "list")
        if not res then
--		ngx.say("failed to check list", err)
--              failing open:
		return
        end

        if res == ngx.null then
--        	ngx.say("ip wasn't known")
        	return
	elseif res == "black" then
--		ngx.log(ngx.STDERR, "ip is in blacklist")
		route()
	elseif res == "white" then
		return "white"
        end
end

function fs_functions.list(ip, list)
	local redis = require "resty.redis"
	local red = redis:new()
	red:set_timeouts(1000, 1000, 1000) -- 1 sec

	local ok, err = red:connect("redis", 6379)
	if not ok then
--		ngx.say("failed to connect: ", err)
		return
	end

	ok, err = red:hset(ip,"list",list)
	if not ok then
--		ngx.say("failed to set ip: ", err)
		return
	end

	result = red:expire(ip, 600)
	if result ~= 1 then
--		ngx.log(ngx.STDERR, "error setting expiration")
		return
	end

	if list == "black" then
		route()
	end
--	ngx.say("set result: ", ok)
end

function fs_functions.confirm_googlebot(ip)
	local resolver = require "resty.dns.resolver"
	local r, err = resolver:new{
		nameservers = {"8.8.8.8", {"8.8.4.4", 53} },
		retrans = 5,  -- 5 retransmissions on receive timeout
		timeout = 2000,  -- 2 sec
	}

	if not r then
		ngx.log(ngx.STDERR, 'failed to instantiate the resolver')
		return
	end

	local answer, err = r:reverse_query(ip)
	if not answer then
		ngx.log(ngx.STDERR, 'failed to query the DNS server')
		return
	end
	if answer.errcode then
		ngx.log(ngx.STDERR, 'there was an errcode')
		ngx.log(ngx.STDERR, answer.errcode)
		return
	end
        ptrdname = answer[1].ptrdname
	if string.find(ptrdname, "googlebot.com", -13) then
		return	
	elseif string.find(ptrdname, "google.com", -10) then
 		return
	else
		return false
	end
end

function fs_functions.add_context(output_json)
	output_json["original_request_headers"] = ngx.req.get_headers()
	--workaround because HTTP/2 not supported yet: https://github.com/openresty/lua-nginx-module#ngxreqraw_header
	if ngx.req.http_version() ~= 2.0 then
		output_json["original_request_headers"]["raw"] = ngx.req.raw_header()
	end
	output_json["original_request_headers"]["http_version"] = ngx.req.http_version()
	output_json["original_request_headers"]["method"] = ngx.req.get_method()
	output_json["original_request_headers"]["uri_args"] = ngx.req.get_uri_args()
	output_json["original_request_headers"]["ip_address"] = ngx.var.remote_addr
-- use below instead of line above in order to not disclose IP addresses of your visitors for public demos, etc.
--	output_json["original_request_headers"]["ip_address"] = "123.123.123.123"

	return output_json
end

return fs_functions
