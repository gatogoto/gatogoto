#!/usr/bin/lua

--[[
    zlib License
    (C) 2021 Nelson "darltrash" Lopez

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.
    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.
]]

--[[
    Welcome, wanderer!

    Yes, i know the big chunky text above is scary but dont worry!
    it basically means you can do whatever with the code AS LONG AS YOU KEEP THE BIG CHUNKY TEXT ON TOP INTACT
    and AS LONG AS YOU STATE THAT YOU DID NOT MAKE THE ORIGINAL CODE.

    Sooo...
    I wish you have fun inspecting this code! Sadly it's not complete and it's an aaaabsolute mess,
    so please apologize me and open an issue about bugs you find.

    If you think of a cool feature that should be on GATOGOTO, send me a PR so we can discuss it ;)
]]

local OPINSTR = function (self, what)
	if self:expect(#what == 3, "Three arguments required :O") then
		return
	end

	if self:expect(what[1].type == "variable", "Expected argument 1 to be a variable name :/") then
		return
	end

	local t, a = what[2].type, what[2].data
	if self:expect(not ((t == "section") or (t == "word")),
		"Expected argument 2 to be either a variable or a number; got %s :/", t) then
		return
	end
	if t == "variable" then
		if self.expect(self.variables[a], "Variable '%s' not found or NULL! :(", what[2].orig) then
			return
		end
		a = self.variables[a]
	end

	local t, b = what[3].type, what[3].data
	if self:expect(not ((t == "section") or (t == "word")),
		"Expected argument 3 to be either a variable or a number; got %s :/", t) then
		return
	end
	if t == "variable" then
		if self.expect(self.variables[b], "Variable '%s' not found or NULL! :(", what[3].orig) then
			return
		end
		b = self.variables[b]
	end

	return a, b
end

local INSTRUCTIONS = {
    add = function(self, what)
		local a, b = OPINSTR(self, what)
        self.variables[what[1].data] = a + b
    end,

	sub = function(self, what)
        local a, b = OPINSTR(self, what)
        self.variables[what[1].data] = a - b
    end,

	mul = function(self, what)
        local a, b = OPINSTR(self, what)
        self.variables[what[1].data] = a * b
    end,

	div = function(self, what)
		local a, b = OPINSTR(self, what)
        self.variables[what[1].data] = a / b
    end,

	pow = function(self, what)
        local a, b = OPINSTR(self, what)
        self.variables[what[1].data] = a ^ b
    end,

	mod = function(self, what)
        local a, b = OPINSTR(self, what)
        self.variables[what[1].data] = a % b
    end,

    set = function(self, what)
        if self:expect(#what == 2, "Two arguments required :O") then
            return
        end
        if self:expect(what[1].type == "variable", "Expected argument 1 to be a variable name :/") then
            return
        end

        local t = what[2].type
        if self:expect(not ((t == "section") or (t == "word")),
            "Expected argument 2 to be either a variable, a string, a number or a boolean; got %s :/", t) then
            return
        end

        if t == "variable" then
            self.variables[what[1].data] = self.variables[what[2].data]
            return
        end
        self.variables[what[1].data] = what[2].data
    end,

    meow = function(self, what)
        local d = ""
        for k, v in ipairs(what) do
            local a = ""
            if v.type == "variable" then
                a = self.variables[v.data]

                if not a then
                    self:fail("Variable '%s' not found or NULL! :(", v.orig)
                    break
                end
            elseif v.type == "bool" or v.type == "number" then
                a = v.orig
            elseif v.type == "string" then
                a = v.data
            else
                self:fail("Cant print %s :(", v.type)
                break
            end

            d = d .. a .. ", "
        end

        if not self.__ERROR then
            print(d:sub(1, #d - 2))
        end
    end,

    ["goto"] = function(self, what)
        if self:expect(#what == 1, "Only one argument required :O") then
            return
        end

        local where = self.currentLine
        what = what[1]

        if what.type == "section" then
            where = self.sections[what.data]

            if self:expect(where, "Could not find section '%s' :(", what.data) then
                return
            end
        elseif what.type == "number" then
            where = self.currentLine + what.data
        else
            self:fail("Cannot goto into %s :(", what.type)
        end

        self.currentLine = where

        if self:expect(where > 0 and where < #self.lines, "Cannot goto into line %s, it's out of bounds! :/",
            where) then
            return
        end
    end
}

local gatogoto = setmetatable({
    VERSION = "0.1 ALPHA",

    _ = {
        validityAssert = function(self, line)
            local o = line:gsub('^%s*(.-)%s*$', '%1')
            if #o == 0 then
                self:fail("EXPECTED_NAME: The label is blank!")
            end

            if #(o:gsub("^[A-Za-z_][A-za-z0-9_]*$", "")) > 0 then
                self:fail("UNEXPECTED_CHAR: Only letters and numbers (that arent the first character) are allowed")
            end

            return o
        end,

        processWord = function(self, capt)
            local captStart = capt:sub(1, 1)
            if captStart == ":" then
                return {
                    type = "section",
                    data = self._.validityAssert(self, capt:sub(2)),
                    orig = capt
                }

            elseif captStart == "$" then
                return {
                    type = "variable",
                    data = self._.validityAssert(self, capt:sub(2)),
                    orig = capt
                }

            elseif captStart == '"' then
                return {
                    type = "string",
                    data = capt:sub(2, #capt - 1),
                    orig = capt
                }

            elseif tonumber(capt) then
                return {
                    type = "number",
                    data = tonumber(capt),
                    orig = capt
                }

            elseif capt == "YES" or capt == "NO" then
                return {
                    type = "bool",
                    data = (capt == "YES"),
                    orig = capt
                }

            else
                return {
                    type = "word",
                    data = self._.validityAssert(self, capt),
                    orig = capt
                }

            end
        end,

        processWords = function(self, line, callmode)
            local line = line:gsub('^%s*(.-)%s*$', '%1')
            local data = {}
            local capt = ""
            local inst

            for c in line:gmatch(".") do
                if c == " " then
                    if #capt > 0 then
                        if callmode and not inst then
                            inst = self._.processWord(self, capt)
                        else
                            table.insert(data, self._.processWord(self, capt))
                        end
                    end
                    capt = ""
                else
                    capt = capt .. c
                end
            end
            table.insert(data, self._.processWord(self, capt))

            return data, inst
        end,

        processLine = function(self, tabs, line, linenum)
            local lineStart = line:sub(1, 1)
            if lineStart == "#" or #line == 0 then
                return {
                    type = "blank"
                }
            end

            if lineStart == ":" then
                if self.sections[line] ~= nil then
                    self:fail("Section already exists!")
                end
                self.sections[line:sub(2)] = linenum

                return {
                    type = "section",
                    name = self._.validityAssert(self, line:sub(2))
                }
            else
                if lineStart == "$" then
                    self:fail("Cannot call variable! use the 'set' instruction to set variables")
                end
                local data, inst = self._.processWords(self, line, true)
                return {
                    type = "call",
                    data = data,
                    inst = inst
                }
            end
            return line
        end
    },

    fail = function(self, str, ...)
        self.__ERROR = "[" .. (self.currentLine or "UNK") .. "] " .. (self.__STATE or "UNK") .. ": " .. str:format(...)
    end,

    expect = function(self, what, str, ...)
        if not what then
            self:fail(str, ...)
            return true
        end
    end,

    parse = function(self, str)
        self.__STATE = "PAR"

        local capt = ""
        local tabs = 0
        self.currentLine = 1

        for c in str:gmatch('.') do
            if c == "\n" then
                table.insert(self.lines,
                    self._.processLine(self, tabs, capt:gsub('^%s*(.-)%s*$', '%1'), self.currentLine))
                capt = ""
                tabs = 0
                self.currentLine = self.currentLine + 1
            elseif c == "\t" then
                tabs = tabs + 1
            else
                capt = capt .. c
            end
        end

        self.currentLine = 1
        self.__STATE = "UNK"
        return self.__ERROR
    end,

    next = function(self)
        self.currentLine = self.currentLine + 1
        return true
    end,

    run = function(self)
        self.__STATE = "RUN"

        local st = self.lines[self.currentLine]
        if not st then
            return false
        end

        if st.type == "call" then
            local inst = self.instructions[st.inst.data]
            if not inst then
                self:fail("Instruction '%s' not found!", st.inst.data)
                return false, self.__ERROR
            end
            inst(self, st.data)
        end

        self.__STATE = "UNK"
        self:next()

        return self.__ERROR == nil, self.__ERROR
    end
}, {
    __call = function(self)
        return setmetatable({
            __STATE = "UNK",
            __ERROR = nil,
            variables = {},
            sections = {},
            instructions = setmetatable({}, {
                __index = INSTRUCTIONS
            }),

            currentLine = 1,
            lines = {}
        }, {
            __index = self
        })
    end
})

if ... then -- If loaded like a library
	return gatogoto -- Return the metatable
end
-- Otherwise...

-- It's funny how i call these "easteries" as in easter eggs when you are reading this, it makes the whole easter egg useless.
local easteries = {
	"... possibly trains too", "... sometimes", "headaches included!", "... yeah, another one", "Sponsored by Maid Shandows Legends!",
    "OC DO NOT STEAL!!!", "... listen to jacob collier", '"futile, Futile, FUTILE!"', "Why does this even exist?"
}

local msg = ""
math.randomseed(os.time())
if math.random(100)>90 then
    msg = easteries[math.random(#easteries)]
end

print([[

GATOGOTO: An esoteric programming language about cats.]] .. "\n" .. msg .. [[


Currently this language does not have a proper CLI tool, i am sorry :(
]])
