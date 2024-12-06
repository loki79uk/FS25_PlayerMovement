-- ============================================================= --
-- PLAYER MOVEMENT MOD - loki_79
-- ============================================================= --
PlayerMovement = {}
PlayerMovement.name = g_currentModName
PlayerMovement.path = g_currentModDirectory

PlayerMovement.SETTINGS = {}
PlayerMovement.CONTROLS = {}

addModEventListener(PlayerMovement)

PlayerMovement.menuItems = {
	'walkingMultiplier',
	'runningMultiplier',
	'jumpMultiplier',
	'showDebug',
}

PlayerMovement.menuItemGroups = {
	walkingSpeed = 'walkingMultiplier',
	fallingSpeed = 'walkingMultiplier',
	swimmingSpeed = 'walkingMultiplier',
	crouchingSpeed = 'walkingMultiplier',
	runningSpeed = 'runningMultiplier',
	swimmingSprintSpeed = 'runningMultiplier',
	acceleration = 'runningMultiplier',
	deceleration = 'runningMultiplier',
	jumpForce = 'jumpMultiplier',
}

PlayerMovement.walkingMultiplier = 1
PlayerMovement.runningMultiplier = 1
PlayerMovement.jumpMultiplier = 1
	
PlayerMovement.walkingSpeed = 7
PlayerMovement.runningSpeed = 15
PlayerMovement.fallingSpeed = 4
PlayerMovement.swimmingSpeed = 4
PlayerMovement.swimmingSprintSpeed = 10
PlayerMovement.crouchingSpeed = 4
PlayerMovement.gravity = 9.81
PlayerMovement.jumpForce = 5.5
PlayerMovement.acceleration = 50
PlayerMovement.deceleration = 40
PlayerMovement.showDebug = false

function debugPrint(str)
	if PlayerMovement.showDebug then
		print("[PlayerMovement] " .. str)
	end
end

function PlayerMovement.updateValue(variable, class, value, noPrint)
	
	local function compareFloats(a, b)
		local epsilon = 0.001
		return math.abs(1.0*a - 1.0*b) < epsilon
	end
	
	local group = PlayerMovement.menuItemGroups[variable]
	local multiplier = PlayerMovement[group] or 1
	local newValue = multiplier * PlayerMovement[variable]
	
	if not compareFloats(class[value], newValue) then
		class[value] = newValue
		if not noPrint then
			debugPrint(value .. " = " .. newValue)
		end
	end
	
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
	
			-- UPDATE ALL THE VALUES IF NEEDED
			PlayerMovement.updateValue('walkingSpeed', PlayerStateWalk, 'MAXIMUM_WALK_SPEED')
			PlayerMovement.updateValue('runningSpeed', PlayerStateWalk, 'MAXIMUM_RUN_SPEED')
			PlayerMovement.updateValue('fallingSpeed', PlayerStateFall, 'MAXIMUM_MOVE_SPEED')
			PlayerMovement.updateValue('crouchingSpeed', PlayerStateCrouch, 'MAXIMUM_MOVE_SPEED')
			PlayerMovement.updateValue('swimmingSpeed', PlayerStateSwim, 'MAXIMUM_MOVE_SPEED')
			PlayerMovement.updateValue('swimmingSprintSpeed', PlayerStateSwim, 'MAXIMUM_SPRINT_SPEED')
			PlayerMovement.updateValue('gravity', PlayerMover, 'GRAVITY')
			PlayerMovement.updateValue('jumpForce', PlayerStateJump, 'JUMP_UPFORCE')
			PlayerMovement.updateValue('acceleration', PlayerMover, 'ACCELERATION')
			PlayerMovement.updateValue('deceleration', PlayerMover, 'DECELERATION')
		
			PlayerMovement.initialised = true
		end
		

		-- SHOW THE SPEED IN F1 MENU
		if PlayerMovement.showDebug then
			g_currentMission:addExtraPrintText(g_i18n:getText("ui_player_speed") .. string.format(": %.2f ", player.getSpeed() or 0) .. " m/s")
		end
		
		-- UPDATE THE JUMP SPEED TO ALWAYS MATCH THE RUNNING/WALKING SPEED
		if player.graphicsState.isRunning then
			PlayerMovement.updateValue('runningSpeed', PlayerStateJump, 'MAXIMUM_MOVE_SPEED', true)
		else
			PlayerMovement.updateValue('walkingSpeed', PlayerStateJump, 'MAXIMUM_MOVE_SPEED', true)
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
PlayerMovement.SETTINGS.walkingMultiplier = {
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {0.8,1.0,1.2,1.5,1.75,2.0,2.5,3.0},
	['strings'] = {
		"80%",
		"100%",
		"120%",
		"150%",
		"175%",
		"200%",
		"250%",
		"300%",
	}
}

PlayerMovement.SETTINGS.runningMultiplier = {
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {0.8,1.0,1.2,1.5,1.75,2.0,2.5,3.0},
	['strings'] = {
		"80%",
		"100%",
		"120%",
		"150%",
		"175%",
		"200%",
		"250%",
		"300%",
	}
}

PlayerMovement.SETTINGS.jumpMultiplier = {
	['default'] = 2,
	['permission'] = 'playerMovement',
	['values'] = {0.8,1.0,1.2,1.5,1.75,2.0,2.5,3.0},
	['strings'] = {
		"80%",
		"100%",
		"120%",
		"150%",
		"175%",
		"200%",
		"250%",
		"300%",
	}
}

-- HELPER FUNCTIONS
local inGameMenu = g_gui.screenControllers[InGameMenu]
local settingsPage = inGameMenu.pageSettings
local settingsLayout = settingsPage.generalSettingsLayout

PlayerMovementControls = {}
PlayerMovementControls.name = settingsPage.name

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

function PlayerMovement.addMenuOption(id)
	
	local function updateFocusIds(element)
		if not element then
			return
		end
		element.focusId = FocusManager:serveAutoFocusId()
		for _, child in pairs(element.elements) do
			updateFocusIds(child)
		end
	end
	
	local original
	if #PlayerMovement.SETTINGS[id].values == 2 then
		original = settingsPage.checkWoodHarvesterAutoCutBox
	else
		original = settingsPage.multiVolumeVoiceBox
	end
	local options = PlayerMovement.SETTINGS[id].strings
	local callback = "onMenuOptionChanged"

	local menuOptionBox = original:clone(settingsLayout)
	if not menuOptionBox then
		print("could not create menu option box")
		return
	end
	menuOptionBox.id = id .. "box"
	
	local menuOption = menuOptionBox.elements[1]
	if not menuOption then
		print("could not create menu option")
		return
	end
	
	menuOption.id = id
	menuOption.target = PlayerMovementControls

	menuOption:setCallback("onClickCallback", callback)
	menuOption:setDisabled(false)

	local toolTip = menuOption.elements[1]
	toolTip:setText(g_i18n:getText("tooltip_playermovement_" .. id))

	local setting = menuOptionBox.elements[2]
	setting:setText(g_i18n:getText("setting_playermovement_" .. id))
	
	menuOption:setTexts({unpack(options)})
	menuOption:setState(PlayerMovement.getStateIndex(id))
	
	PlayerMovement.CONTROLS[id] = menuOption
	
	updateFocusIds(menuOptionBox)
	table.insert(settingsPage.controlsList, menuOptionBox)

	return menuOption
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

function PlayerMovement:loadMap(name)
	-- print("Load Mod: 'Player Movement Settings'")
	PlayerMovement.readSettings()
	addConsoleCommand("playerMovementLoadSettings", "Load Player Movement Settings from the local mod settings file", "readSettings", PlayerMovement)
	
end

-- MENU CALLBACK
function PlayerMovementControls.onMenuOptionChanged(self, state, menuOption)
	
	local id = menuOption.id
	local setting = PlayerMovement.SETTINGS
	local value = setting[id].values[state]
	
	if value ~= nil then
		debugPrint("SET " .. id .. " = " .. tostring(value))
		PlayerMovement.setValue(id, value)
	end
	
	PlayerMovement.writeSettings()
	PlayerMovement.initialised = false
end

local sectionTitle = nil
for idx, elem in ipairs(settingsLayout.elements) do
	if elem.name == "sectionHeader" then
		sectionTitle = elem:clone(settingsLayout)
		break
	end
end
if sectionTitle then
	sectionTitle:setText(g_i18n:getText("menu_PlayerMovement_TITLE"))
else
	local title = TextElement.new()
	title:applyProfile("fs25_settingsSectionHeader", true)
	title:setText(g_i18n:getText("menu_PlayerMovement_TITLE"))
	title.name = "sectionHeader"
	settingsLayout:addElement(title)
end

sectionTitle.focusId = FocusManager:serveAutoFocusId()
table.insert(settingsPage.controlsList, sectionTitle)
PlayerMovement.CONTROLS[sectionTitle.name] = sectionTitle

for _, id in pairs(PlayerMovement.menuItems) do
	PlayerMovement.addMenuOption(id)
end
settingsLayout:invalidateLayout()

-- Allow keyboard navigation of menu options
FocusManager.setGui = Utils.appendedFunction(FocusManager.setGui, function(_, gui)
	if gui == "ingameMenuSettings" then
		-- Let the focus manager know about our custom controls now (earlier than this point seems to fail)
		for _, control in pairs(PlayerMovement.CONTROLS) do
			if not control.focusId or not FocusManager.currentFocusData.idToElementMapping[control.focusId] then
				if not FocusManager:loadElementFromCustomValues(control, nil, nil, false, false) then
					Logging.warning("Could not register control %s with the focus manager", control.id or control.name or control.focusId)
				end
			end
		end
		-- Invalidate the layout so the up/down connections are analyzed again by the focus manager
		local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
		settingsPage.generalSettingsLayout:invalidateLayout()
	end
end)

InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, function()
	
	local isAdmin = g_currentMission:getIsServer() or g_currentMission.isMasterUser
	
	for _, id in pairs(PlayerMovement.menuItems) do
	
		local menuOption = PlayerMovement.CONTROLS[id]
		menuOption:setState(PlayerMovement.getStateIndex(id))
	
		menuOption:setDisabled(not isAdmin)

	end
end)
