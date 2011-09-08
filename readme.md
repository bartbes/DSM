## Dynamic State Manager ##

Dynamic State Manager is a simple class-based state manager that uses Class Commons to provide abstracted classes.

### Example ###

Using DSM is easy, here is an example with Slither.

	require "slither"
	require "dsm"

	local state = State("count")

	function state:load()
		self.timer = 0
	end

	function state:update(dt)
		self.timer = self.timer + dt
	end

	function state:draw()
		love.graphics.print(tostring(self.timer), 50, 50)
	end

	State.register(love)
	State.switch("count")

### Reference Manual ###

The *State* class has 2 important 'static' functions.

	State.switch(name) -- Switches to the state named by its argument.
	State.register(table, callbackname) -- Catches and forwards the callback indicated.

However, State.register has a special form (as shown in the example),
if only the love table is passed, it automatically registers the standard
love callbacks. (So it is equivalent to calling State.register(love, "update"), etc.)

A state object always has two callbacks, load, when the state gets switched to, and unload,
when the state gets switched from. Other callbacks have to be registered with State.register.

One of the things I can recommend is subclassing State for similar states, i.e. create a GameState,
if you have multiple game states, and/or a MenuState that allows you to both create new menus quickly,
as well as have centralized menu code.
