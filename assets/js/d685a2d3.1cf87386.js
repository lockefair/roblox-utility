"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[311],{82837:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Constructs a new `NetworkEvent` object. The \'reliable\' parameter is defined by the server and ignored by the client.","params":[{"name":"name","desc":"The name of the `NetworkEvent` instance which must match on the client and server","lua_type":"string"},{"name":"parent","desc":"The parent of the `NetworkEvent` instance which must match on the client and server","lua_type":"Instance"},{"name":"unreliable","desc":"Whether or not the event should be reliable. Defaults to `false`","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"NetworkEvent\\r\\n"}],"function_type":"static","tags":["Static"],"source":{"line":97,"path":"src/Connection/NetworkEvent.lua"}},{"name":"destroy","desc":"Deconstructs the `NetworkEvent` object","params":[],"returns":[],"function_type":"method","source":{"line":122,"path":"src/Connection/NetworkEvent.lua"}},{"name":"connect","desc":"Connects a callback to the `NetworkEvent` which is invoked when\\nthe event is fired.\\n\\n\\n:::note\\nWhen connecting on the server, the first argument passed to the callback is always the player that fired the event.\\n:::\\n\\n```lua\\n-- Client\\nclientEvent:connect(function(...)\\n\\tprint(\\"The event fired and passed the values:\\", ...)\\nend)\\n\\n-- Server\\nserverEvent:connect(function(player, ...)\\n\\tprint(\\"The event was fired by \\" .. player .. \\" and passed the values:\\", ...)\\nend)\\n```","params":[{"name":"callback","desc":"The callback to be called when the event is fired","lua_type":"(...any) -> ()"}],"returns":[{"desc":"","lua_type":"EventConnection\\r\\n"}],"function_type":"method","source":{"line":189,"path":"src/Connection/NetworkEvent.lua"}},{"name":"fireServer","desc":"Fires the `NetworkEvent` on the client, passing the given arguments to the server\\n\\n\\n```lua\\nevent:fireServer(\\"Hello, server!\\")\\n```","params":[{"name":"...","desc":"The arguments to pass to the server","lua_type":"any"}],"returns":[],"function_type":"method","realm":["Client"],"source":{"line":206,"path":"src/Connection/NetworkEvent.lua"}},{"name":"fireClient","desc":"Fires the `NetworkEvent` on the server, passing the given arguments to the players client\\n\\n\\n```lua\\nevent:fireClient(player, \\"Hello, client!\\")\\n```","params":[{"name":"player","desc":"The player to fire the event to","lua_type":"Player"},{"name":"...","desc":"The arguments to pass to the client","lua_type":"any"}],"returns":[],"function_type":"method","realm":["Server"],"source":{"line":226,"path":"src/Connection/NetworkEvent.lua"}},{"name":"fireFilteredClients","desc":"Fires the `NetworkEvent` on the server, passing the given arguments to player clients that pass the given predicate check\\n\\n\\n```lua\\nevent:fireFilteredClients(function(player)\\n\\treturn player.Team == game.Teams.Heroes\\nend, \\"You win!\\")\\n```","params":[{"name":"predicate","desc":"The predicate to check against each player","lua_type":"(player: Player) -> boolean"},{"name":"...","desc":"The arguments to pass to the client","lua_type":"any"}],"returns":[],"function_type":"method","realm":["Server"],"source":{"line":250,"path":"src/Connection/NetworkEvent.lua"}},{"name":"fireAllClients","desc":"Fires the `NetworkEvent` on the server, passing the given arguments to all clients\\n\\n\\n```lua\\nevent:fireAllClients(1, 2, 3)\\n```","params":[{"name":"...","desc":"The arguments to pass to the clients","lua_type":"any"}],"returns":[],"function_type":"method","realm":["Server"],"source":{"line":275,"path":"src/Connection/NetworkEvent.lua"}}],"properties":[{"name":"className","desc":"Static property that defines the class name `NetworkEvent`","lua_type":"string","tags":["Static"],"source":{"line":55,"path":"src/Connection/NetworkEvent.lua"}}],"types":[{"name":"EventConnection","desc":"An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `NetworkEvent:connect` method.\\nThis `EventConnection` object can be used to disconnect the callback from the event.\\n\\n```lua\\nprint(connection.connected) -- true\\nconnection:disconnect()\\nprint(connection.connected) -- false\\n```","fields":[{"name":"connected","lua_type":"boolean","desc":""},{"name":"disconnect","lua_type":"() -> ()","desc":""}],"source":{"line":40,"path":"src/Connection/NetworkEvent.lua"}},{"name":"Self","desc":"","lua_type":"NetworkEvent","source":{"line":46,"path":"src/Connection/NetworkEvent.lua"}}],"name":"NetworkEvent","desc":"An object that wraps Roblox\'s remote events. It can be used to fire events between the server and client\\nwithout having to manage remote event instance lifecycles manually \u2013 initialization and deinitialization are handled for you.\\n\\n:::note\\nNetwork events are intended to be paired. A `NetworkEvent` object should be initialized on the server first, then on the client,\\notherwise an error will occur.\\n\\nAny type of Roblox object such as an Enum, Instance, or others can be passed as a parameter when a `NetworkEvent` is fired,\\nas well as Luau types such as numbers, strings, and booleans. `NetworkEvent` shares its limitations with Roblox\'s `RemoteEvent` class.\\n:::\\n\\n```lua\\n-- Server\\nlocal serverEvent = NetworkEvent.new(\\"MyNetworkEvent\\", workspace)\\n\\n-- Client\\nlocal clientEvent = NetworkEvent.new(\\"MyNetworkEvent\\", workspace)\\nclientEvent:connect(function(...)\\n\\tprint(\\"The event fired and passed the values:\\", ...) -- 1, 2, 3\\nend)\\n\\n-- Server\\nserverEvent:fireClient(player, 1, 2, 3)\\n```","source":{"line":84,"path":"src/Connection/NetworkEvent.lua"}}')}}]);