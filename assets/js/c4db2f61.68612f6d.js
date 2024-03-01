"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[120],{32100:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Constructs a new `Event` object","params":[],"returns":[{"desc":"The `Event` object","lua_type":"Event"}],"function_type":"static","tags":["Static"],"source":{"line":70,"path":"src/Event/init.lua"}},{"name":"destroy","desc":"Deconstructs the `Event` object","params":[],"returns":[],"function_type":"method","source":{"line":87,"path":"src/Event/init.lua"}},{"name":"connect","desc":"Connects a callback to the event which is invoked when the event is fired\\n\\n```lua\\nlocal event = Event.new()\\nevent:connect(function(...)\\n\\tprint(\\"The event fired and passed the values:\\", ...)\\nend)\\nevent:fire(1, 2, 3)\\n```","params":[{"name":"callback","desc":"The callback to connect to the event","lua_type":"(...any) -> ()"}],"returns":[{"desc":"An event connection that can be disconnected","lua_type":"EventConnection"}],"function_type":"method","source":{"line":129,"path":"src/Event/init.lua"}},{"name":"disconnect","desc":"Disconnects a callback from the event\\n\\n:::caution\\nThis is called automatically when an EventConnection is disconnected. It\'s not necessary to call this manually\\n:::","params":[{"name":"eventConnection","desc":"The connection to disconnect from the event","lua_type":"EventConnection"}],"returns":[],"function_type":"method","source":{"line":148,"path":"src/Event/init.lua"}},{"name":"fire","desc":"Fires the event with the given arguments\\n\\n```lua\\nevent:fire(\\"Hello, world!\\")\\n```","params":[{"name":"...","desc":"The values to pass to the event\'s callbacks","lua_type":"any"}],"returns":[],"function_type":"method","source":{"line":167,"path":"src/Event/init.lua"}}],"properties":[{"name":"className","desc":"Static property that defines the class name of the `NetworkEvent` object","lua_type":"string","tags":["Static"],"source":{"line":44,"path":"src/Event/init.lua"}}],"types":[{"name":"EventConnection","desc":"An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `Event:connect` method.\\nThis `EventConnection` object can be used to disconnect the callback from the event\\n\\n```lua\\nprint(connection.connected) -- true\\nconnection:disconnect()\\nprint(connection.connected) -- false\\n```","fields":[{"name":"connected","lua_type":"boolean","desc":""},{"name":"disconnect","lua_type":"() -> ()","desc":""}],"source":{"line":29,"path":"src/Event/init.lua"}},{"name":"Self","desc":"","lua_type":"Event","source":{"line":35,"path":"src/Event/init.lua"}}],"name":"Event","desc":"A signal implementation that wraps Roblox\'s BindableEvent\\n\\n```lua\\nlocal event = Event.new()\\nlocal connection = event:connect(function(value)\\n\\tprint(\\"The event fired and passed the value:\\", value)\\nend)\\nevent:fire(\\"Hello, world!\\")\\nconnection:disconnect()\\nevent:destroy()\\n```","source":{"line":60,"path":"src/Event/init.lua"}}')}}]);