--[[
This project uses the FreeBSD license, the license text follows:
	Copyright 2011 Bart van Strien. All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are
	permitted provided that the following conditions are met:

	   1. Redistributions of source code must retain the above copyright notice, this list of
	      conditions and the following disclaimer.

	   2. Redistributions in binary form must reproduce the above copyright notice, this list
	      of conditions and the following disclaimer in the documentation and/or other materials
	      provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR IMPLIED
	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	The views and conclusions contained in the software and documentation are those of the
	authors and should not be interpreted as representing official policies, either expressed
	or implied, of Bart van Strien.
]]

assert(common and common.class, "This library requires a Class Commons implementation.")

-- Store the registered states in a weak table
-- so when the state gets garbage collected,
-- it actually does.
local states = setmetatable({}, {__mode = "v"})

-- Store our current state, useful.
local curstate = nil

-- The State class (it isn't a class yet, though)
local State = {}

-- A table that will create wrappers for us
-- (go metatables!)
local Catcher = {}

-- First, a generic empty function, the default
-- callback.
function State.empty() end

-- We always use load and unload as entry and exit
-- points of our state, so define those (as empty).
State.load = State.empty
State.unload = State.empty

-- On the creation of a state, store it.
function State:init(name)
	assert(name, "This state needs a name!")
	states[name] = self
end

-- Switch to another state, by name.
-- Meaning unload the current one (if any),
-- then change curstate and load that.
-- Pass on all arguments.
function State.switch(name, ...)
	assert(states[name], "The state " .. tostring(name) .. " doesn't exist.")
	if curstate then
		curstate:unload()
	end
	curstate = states[name]
	curstate:load(...)
end

-- Register a callback, this puts in
-- a redirect, to the state manager, and
-- it creates a default handler (State.empty).
function State.register(table, callback)
	-- Special case, if you call this as 'State.register(love)'
	-- it will register the default love callbacks.
	if table == love and not callback then
		for i, v in ipairs{
			"update", "draw", "focus", "quit",
			"joystickpressed", "joystickreleased",
			"mousepressed", "mousereleased",
			"keypressed", "keyreleased"} do
			State.register(love, v)
		end
		return
	end
	if table and callback then
		-- Ask the Catcher for a nice trampoline.
		-- Yes, this actually generates a function!
		table[callback] = Catcher[callback]
		-- Set the default (empty) handler.
		State[callback] = State.empty
	end
end

-- Here's our metatable magic.
setmetatable(Catcher, { __index = function(self, name)
	-- Let's just return a closure, that
	-- does nothing but a tail call to our
	-- state's handler.
	return function(...)
		return curstate[name](curstate, ...)
	end
end})

-- Last, but not least, turn State into
-- a class, using Class Commons.
_G.State = common.class("State", State)
