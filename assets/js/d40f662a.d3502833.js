"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[171],{79144:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Constructs a new `NetworkValue` object.","params":[{"name":"name","desc":"The name of the `NetworkValue` instance which must match on the client and server","lua_type":"string"},{"name":"parent","desc":"The parent of the `NetworkValue` instance","lua_type":"Instance"},{"name":"value","desc":"The initial value of the `NetworkValue` instance","lua_type":"any?"}],"returns":[{"desc":"","lua_type":"NetworkValue\\r\\n"}],"function_type":"static","tags":["Static"],"source":{"line":94,"path":"src/Connection/NetworkValue.lua"}},{"name":"destroy","desc":"Deconstructs the `NetworkValue` object.","params":[],"returns":[],"function_type":"method","source":{"line":117,"path":"src/Connection/NetworkValue.lua"}},{"name":"connect","desc":"Connects a callback that\'s called when the value of the `NetworkValue` object changes.\\n\\n\\n```lua\\nlocal healthValue = NetworkValue.new(\\"PlayerHealth\\", workspace, 100)\\n\\nhealthValue:connect(function(value)\\n\\tprint(\\"The players health changed to:\\", value)\\nend)\\n```","params":[{"name":"callback","desc":"The callback to be called when the value of the `NetworkValue` object changes","lua_type":"(value: any?) -> ()"}],"returns":[{"desc":"","lua_type":"EventConnection\\r\\n"}],"function_type":"method","source":{"line":155,"path":"src/Connection/NetworkValue.lua"}},{"name":"getValue","desc":"Returns the value of the `NetworkValue` object. If called on the server and a player is specified, the value for that specific player is returned.\\n\\n\\n:::note\\nThe player parameter is ignored on the client. The value returned is always the value of the `NetworkValue` object on the server,\\nwether that is the global value or the value set specifically for the local player.\\n:::\\n\\n```lua\\n-- Server\\nserverValue:setValue(80)\\nserverValue:setValue(50, player1)\\n\\nserverValue:getValue() -- 80\\nserverValue:getValue(player1) -- 50\\n\\n-- Player1 Client\\nclientValue:getValue() -- 50\\n\\n-- Other Client(s)\\nclientValue:getValue() -- 80\\n```","params":[{"name":"player","desc":"The player to get the value for","lua_type":"Player?"}],"returns":[{"desc":"","lua_type":"any?\\r\\n"}],"function_type":"method","source":{"line":186,"path":"src/Connection/NetworkValue.lua"}},{"name":"setValue","desc":"Sets the value of the `NetworkValue` object. If a player is specified, the value for that specific player is set.\\n\\n\\n```lua\\nlocal healthValue = NetworkValue.new(\\"PlayerHealth\\", workspace, 100)\\n\\nhealthValue:setValue(80)\\nhealthValue:setValue(50, player1)\\n```","params":[{"name":"value","desc":"The value to set","lua_type":"any?"},{"name":"player","desc":"The player to set the value for","lua_type":"Player?"}],"returns":[],"function_type":"method","realm":["Server"],"source":{"line":220,"path":"src/Connection/NetworkValue.lua"}}],"properties":[{"name":"className","desc":"Static property that defines the class name `NetworkValue`.","lua_type":"string","tags":["Static"],"source":{"line":53,"path":"src/Connection/NetworkValue.lua"}}],"types":[{"name":"EventConnection","desc":"An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `NetworkValue:connect` method.\\nThis `EventConnection` object can be used to disconnect the callback from the event.\\n\\n```lua\\nprint(connection.connected) -- true\\nconnection:disconnect()\\nprint(connection.connected) -- false\\n```","fields":[{"name":"connected","lua_type":"boolean","desc":""},{"name":"disconnect","lua_type":"() -> ()","desc":""}],"source":{"line":38,"path":"src/Connection/NetworkValue.lua"}},{"name":"Self","desc":"","lua_type":"NetworkValue","source":{"line":44,"path":"src/Connection/NetworkValue.lua"}}],"name":"NetworkValue","desc":"An object that wraps Roblox\'s `RemoteEvent` and synchronizes values between the server and client. Values can be set by the server and are automatically\\nupdated on the client. Values can be set for everybody or for a specific player.\\n\\n:::note\\nNetwork values are intended to be paired. A `NetworkValue` object should be initialized on the server first, then on the client,\\notherwise an error will occur.\\n\\nAny type of Roblox object such as an Enum, Instance, or others can be passed as a parameter when a `NetworkValue` is updated,\\nas well as Luau types such as numbers, strings, and booleans. `NetworkValue` shares its limitations with Roblox\'s `RemoteEvent` class.\\n:::\\n\\n```lua\\n-- Server\\nlocal serverValue = NetworkValue.new(\\"PlayerHealth\\", workspace, 100)\\n\\n-- Client\\nlocal clientValue = NetworkValue.new(\\"PlayerHealth\\", workspace)\\n\\nprint(\\"The players health is:\\", clientValue:getValue()) -- 100\\nclientValue.changed:connect(function(value)\\n\\tprint(\\"The players health changed to:\\", value)\\nend)\\n```","source":{"line":81,"path":"src/Connection/NetworkValue.lua"}}')}}]);