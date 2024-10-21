# Judge

A tiny validation library for Lua.

```lua
local Judge = require("judge")

local MessageType = Judge.string().enum({ "ping", "pong" })

local ok, err = MessageType.validate("test")
if not ok then
  print(err) -- invalid value: expected one of ping, pong, got test
end

local Message = Judge.object({
  type = MessageType,
  text = Judge.string().optional()
})

print(Message.validate({
 type = "ping",
 text = "Hello world!",
}))
```
