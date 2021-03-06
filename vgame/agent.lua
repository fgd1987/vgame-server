local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local socket = require "socket"
local message = require "message"
local msgid = require "msgId"
msgpack = require "msgpack.core"

local host

local CMD = {}
local client_fd ={}
local account = nil
local gate

local function send_response(package)
	data = msgpack.unpack(package)
	print(" resp ok : ", data.msgno)
	socket.write(client_fd, netpack.pack(package))
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function(msg, sz)
		return skynet.tostring(msg, sz)
	end,
	dispatch = function(_, _, msg)
		print("------------client dispatch------------")
		data = msgpack.unpack(msg)

		print("msgno = ",data.msgno);

		--[[
		module = math.floor(data.msgno / 100)
		opcode = data.msgno % 100
		print("msgno = ",data.msgno);
		local ok, result
		if msgid[module] then
			ok, result = pcall(skynet.call, msgid[module], "lua", "dispatch", opcode, data.msg)
			if ok then
				send_response(result)
			else
				print("role error")
			end
		else
			print("server receive error msg")
		end
		]]
	end
}

function CMD.start(_gate, fd, _account)
	client_fd = fd
	account = _account
	gate = _gate

	LOG_INFO("agent start  fd:"..client_fd)
	skynet.error("agent start account: "..account)
	skynet.call("usermgr", "lua", "enroll", account, skynet.self())

	skynet.call(gate, "lua", "forward", fd)

end


function CMD.disconnect(reason)
	print("client disconnect " .. client_fd)
	LOG_INFO("client disconnect  fd:"..client_fd)

	skynet.call("usermgr", "lua", "remove", account)  

	skynet.call(gate, "lua", "kick", client_fd)
	skynet.exit()
end

skynet.start(function()
	print("---start agent---")
	LOG_INFO("create agent")

	skynet.dispatch("lua", function(session, source, cmd, ...)
		print("---agent cmd ", cmd)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
