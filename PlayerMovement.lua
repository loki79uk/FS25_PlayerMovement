PlayerMovement = {}
PlayerMovement.name = g_currentModName
PlayerMovement.path = g_currentModDirectory

PlayerMovement.SETTINGS = {}

addModEventListener(PlayerMovement)

PlayerMovement.menuItems = {
	'walkingSpeed',
	'runningSpeed',
	'fallingSpeed',
	'swimmingSpeed',
	'swimmingSprintSpeed',
	'crouchingSpeed',
	'gravity',
	'jumpForce',
	'acceleration',
	'deceleration',
	'showDebug'
}

PlayerMovement.walkingSpeed = 4
PlayerMovement.runningSpeed = 7
PlayerMovement.fallingSpeed = 3
PlayerMovement.swimmingSpeed = 3
PlayerMovement.swimmingSprintSpeed = 5
PlayerMovement.crouchingSpeed = 3
PlayerMovement.gravity = 9.81
PlayerMovement.jumpForce = 5.5
PlayerMovement.acceleration = 30
PlayerMovement.deceleration = 20
PlayerMovement.showDebug = false

function debugPrint(str) 
	if PlayerMovement.showDebug then
		print(str)
	end
end


function PlayerMovement:loadMap(name)
	-- print("Load Mod: 'Player Movement Settings'")
	PlayerMovement.readSettings()
	
	addConsoleCommand("playerMovementLoadSettings", "Load Player Movement Settings from the local mod settings file", "readSettings", PlayerMovement)
	
end

function PlayerMovement:doUpdate(dt)
	
	local masterServer = g_masterServerConnection.masterServerCallbackTarget
	local isSaving = masterServer.isSaving
	local isLoadingMap = masterServer.isLoadingMap
	local isExitingGame = masterServer.isExitingGame
	local isSynchronizingWithPlayers = masterServer.isSynchronizingWithPlayers
	if isLoadingMap or isExitingGame or isSaving or isSynchronizingWithPlayers then
		return
	end
	
	PlayerMovement.startupTime = PlayerMovement.startupTime or 0
	if PlayerMovement.startupTime < 500 then
		PlayerMovement.startupTime = PlayerMovement.startupTime + dt
		-- debugPrint("wait for startup.." .. PlayerMovement.startupTime)
		return
	end
	
	-- Dedicated Server has no player
	if not g_localPlayer then
		debugPrint("Warning: no player ID")
		return
	end

	local player = g_localPlayer
	local isInVehicle = player:getIsInVehicle()
	local isControlled = player.isControlled
	local playerIsEntered = isControlled and not isInVehicle

	if playerIsEntered and not g_gui:getIsGuiVisible() then
	
		-- CHANGE GLOBAL VALUES ON FIRST RUN
		if not PlayerMovement.initialised then
			debugPrint("*** PlayerMovement - DEBUG ENABLED ***")
			PlayerMovement.initialised = true
		end
		
		-- UPDATE ALL THE VALUES IF NEEDED
		local function updateValue(variable, class, value, noPrint)
			
			local function compareFloats(a, b)
				local epsilon = 0.00001
				return math.abs((1.0*a) - (1.0*b)) < epsilon
			end
			
			if not compareFloats(class[value], PlayerMovement[variable]) then
				class[value] = PlayerMovement[variable]
				if not noPrint then
					debugPrint(value .. " = " .. PlayerMovement[variable])
				end
			end
			
		end
		updateValue('walkingSpeed', PlayerStateWalk, 'MAXIMUM_WALK_SPEED')
		updateValue('runningSpeed', PlayerStateWalk, 'MAXIMUM_RUN_SPEED')
		updateValue('fallingSpeed', PlayerStateFall, 'MAXIMUM_MOVE_SPEED')
		updateValue('crouchingSpeed', PlayerStateCrouch, 'MAXIMUM_MOVE_SPEED')
		updateValue('swimmingSpeed', PlayerStateSwim, 'MAXIMUM_MOVE_SPEED')
		updateValue('swimmingSprintSpeed', PlayerStateSwim, 'MAXIMUM_SPRINT_SPEED')
		updateValue('gravity', PlayerMover, 'GRAVITY')
		updateValue('jumpForce', PlayerStateJump, 'JUMP_UPFORCE')
		updateValue('acceleration', PlayerMover, 'ACCELERATION')
		updateValue('deceleration', PlayerMover, 'DECELERATION')
	
		-- SHOW THE SPEED IN F1 MENU
		if PlayerMovement.showDebug then
			g_currentMission:addExtraPrintText(g_i18n:getText("ui_player_speed") .. string.format(": %.2f ", player.getSpeed() or 0) .. " m/s")
		end
		
		-- UPDATE THE JUMP SPEED TO ALWAYS MATCH THE RUNNING/WALKING SPEED
		if player.graphicsState.isRunning then
			updateValue('runningSpeed', PlayerStateJump, 'MAXIMUM_MOVE_SPEED', true)
		else
			updateValue('walkingSpeed', PlayerStateJump, 'MAXIMUM_MOVE_SPEED', true)
		end
			

	end	
end

function PlayerMovement:update(dt)

	if PlayerMovement.stopError then
		if not PlayerMovement.printedError then
			PlayerMovement.printedError = true
			print("PlayerMovement - FATAL ERROR: " .. PlayerMovement.result)
		end
		return
	end
	
	local status, result = pcall(PlayerMovement.doUpdate, self, dt)

	if not status then
		PlayerMovement.stopError = true
		PlayerMovement.result = result
	end
end


--DEV
PlayerMovement.SETTINGS.showDebug = {
-- PlayerMovement.showDebug = false
	['default'] = 1,
	['values'] = {false, true},
	['strings'] = {
		g_i18n:getText("ui_off"),
		g_i18n:getText("ui_on")
	}
}

--PLAYER
PlayerMovement.SETTINGS.walkingSpeed = {
-- PlayerMovement.walkingSpeed = 4
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {2, 4, 8, 16, 32, 64},
	['strings'] = {
		"2 m/s",
		"4 m/s",
		"8 m/s",
		"16 m/s",
		"32 m/s",
		"64 m/s",
	}
}
PlayerMovement.SETTINGS.runningSpeed = {
-- PlayerMovement.runningSpeed = 7
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {4, 8, 16, 32, 64, 128},
	['strings'] = {
		"4 m/s",
		"8 m/s",
		"16 m/s",
		"32 m/s",
		"64 m/s",
		"128 m/s",
	}
}
PlayerMovement.SETTINGS.fallingSpeed = {
-- PlayerMovement.fallingSpeed = 3
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {2, 4, 8, 16, 32, 64},
	['strings'] = {
		"2 m/s",
		"4 m/s",
		"8 m/s",
		"16 m/s",
		"32 m/s",
		"64 m/s",
	}
}
PlayerMovement.SETTINGS.crouchingSpeed = {
-- PlayerMovement.crouchingSpeed = 3
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {2, 4, 8, 16, 32, 64},
	['strings'] = {
		"2 m/s",
		"4 m/s",
		"8 m/s",
		"16 m/s",
		"32 m/s",
		"64 m/s",
	}
}
PlayerMovement.SETTINGS.swimmingSpeed = {
-- PlayerMovement.swimmingSpeed = 3
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {2, 4, 8, 16, 32, 64},
	['strings'] = {
		"2 m/s",
		"4 m/s",
		"8 m/s",
		"16 m/s",
		"32 m/s",
		"64 m/s",
	}
}
PlayerMovement.SETTINGS.swimmingSprintSpeed = {
-- PlayerMovement.swimmingSprintSpeed = 5
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {4, 8, 16, 32, 64, 128},
	['strings'] = {
		"4 m/s",
		"8 m/s",
		"16 m/s",
		"32 m/s",
		"64 m/s",
		"128 m/s",
	}
}
PlayerMovement.SETTINGS.gravity = {
-- PlayerMovement.gravity = 9.81
	['default'] = 3,
	['permission'] = 'playerMovement',
	['values'] = {2,5,9.81,15,20,25,30,50},
	['strings'] = {
		"20%",
		"50%",
		"100%",
		"150%",
		"200%",
		"250%",
		"300%",
		"500%",
	}
}
PlayerMovement.SETTINGS.jumpForce = {
-- PlayerMovement.jumpForce = 5.5
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {2.75,5.5,11,27.5,55},
	['strings'] = {
		"50%",
		"100%",
		"200%",
		"500%",
		"1000%",
	}
}
PlayerMovement.SETTINGS.acceleration = {
-- PlayerMovement.acceleration = 16
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {8,16,24,32,40,48,64,80},
	['strings'] = {
		"50%",
		"100%",
		"150%",
		"200%",
		"250%",
		"300%",
		"400%",
		"500%",
	}
}
PlayerMovement.SETTINGS.deceleration = {
-- PlayerMovement.deceleration = 10
	['default'] = 3,
	['permission'] = 'playerMovement',
	['values'] = {5,10,15,20,25,30,40,50},
	['strings'] = {
		"50%",
		"100%",
		"150%",
		"200%",
		"250%",
		"300%",
		"400%",
		"500%",
	}
}

-- HELPER FUNCTIONS
function PlayerMovement.setValue(id, value)
	PlayerMovement[id] = value
end

function PlayerMovement.getValue(id)
	return PlayerMovement[id]
end

function PlayerMovement.getStateIndex(id, value)
	local value = value or PlayerMovement.getValue(id) 
	local values = PlayerMovement.SETTINGS[id].values
	if type(value) == 'number' then
		local index = PlayerMovement.SETTINGS[id].default
		local initialdiff = math.huge
		for i, v in pairs(values) do
			local currentdiff = math.abs(v - value)
			if currentdiff < initialdiff then
				initialdiff = currentdiff
				index = i
			end 
		end
		return index
	else
		for i, v in pairs(values) do
			if value == v then
				return i
			end 
		end
	end
	print(id .. " USING DEFAULT")
	return PlayerMovement.SETTINGS[id].default
end

-- READ/WRITE SETTINGS
function PlayerMovement.writeSettings()

	local key = "playerMovementSettings"
	local userSettingsFile = Utils.getFilename("modSettings/PlayerMovement.xml", getUserProfileAppPath())
	
	local xmlFile = createXMLFile("settings", userSettingsFile, key)
	if xmlFile ~= 0 then
	
		local function setXmlValue(id)
			
			if not id or not PlayerMovement.SETTINGS[id] then
				return
			end
			if PlayerMovement.SETTINGS[id].serverOnly and g_server == nil then
				return
			end

			local xmlValueKey = "playerMovementSettings." .. id .. "#value"
			local value = PlayerMovement.getValue(id)
			if type(value) == 'number' then
				setXMLFloat(xmlFile, xmlValueKey, value)
			elseif type(value) == 'boolean' then
				setXMLBool(xmlFile, xmlValueKey, value)
			end
		end
		
		for _, id in pairs(PlayerMovement.menuItems) do
			setXmlValue(id)
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)
	end
end

function PlayerMovement.readSettings()

	local userSettingsFile = Utils.getFilename("modSettings/PlayerMovement.xml", getUserProfileAppPath())
	
	if not fileExists(userSettingsFile) then
		print("CREATING user settings file: "..userSettingsFile)
		PlayerMovement.writeSettings()
		return
	end
	
	local xmlFile = loadXMLFile("playerMovementSettings", userSettingsFile)
	if xmlFile ~= 0 then
	
		local function getXmlValue(id)
			local setting = PlayerMovement.SETTINGS[id]
			if setting then
				local xmlValueKey = "playerMovementSettings." .. id .. "#value"
				local value = PlayerMovement.getValue(id)
				local value_string = tostring(value)
				if hasXMLProperty(xmlFile, xmlValueKey) then
				
					if type(value) == 'number' then
						value = getXMLFloat(xmlFile, xmlValueKey) or value
						
						if value == math.floor(value) then
							value_string = tostring(value)
						else
							value_string = string.format("%.3f", value)
						end
						
					elseif type(value) == 'boolean' then
						value = getXMLBool(xmlFile, xmlValueKey) or false
						value_string = tostring(value)
					end

					if g_server == nil and type(value) == 'number' then
						-- print("CLIENT - restrict to closest value")
						value = setting.values[PlayerMovement.getStateIndex(id, value)]
					end
					PlayerMovement.setValue(id, value)
					return value_string
				end
			end
			return "MISSING"
		end
		
		print("PLAYER MOVEMENT SETTINGS")
		for _, id in pairs(PlayerMovement.menuItems) do
			local valueString = getXmlValue(id)
			print("  " .. id .. ": " .. valueString)
		end

		delete(xmlFile)
	end
	
end

function PlayerMovement:onMenuOptionChanged(state, menuOption)
	
	local id = menuOption.id
	local setting = PlayerMovement.SETTINGS
	local value = setting[id].values[state]
	
	if value ~= nil then
		PlayerMovement.setValue(id, value)
	end

	PlayerMovement.writeSettings()
end
