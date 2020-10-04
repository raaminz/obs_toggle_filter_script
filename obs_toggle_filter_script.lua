-- MIT License
--
-- Copyright (c) Ramin Zare
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

obs = obslua
settings = {}
--Change this variable to support more than one change
totalSetting = 1

function script_description()
	return [[
	This script tries to enbale or disable a filter when switching between the scenes.

	One scenario would be when you have only one video source like camera that is used 
	in different scenes and you want to have different filtes 
	in each scene.

	If you want to use multiple settings, update the global variable "totalSetting" in this script.
]]
end

function script_properties()
	local props = obs.obs_properties_create()

	for i = 1 , totalSetting
	do
		add_default_properties(props, i)
	end
	
	return props
end


function add_default_properties(props,numOfSetting)
	local scenes = obs.obs_frontend_get_scenes()
	local sceneSelected = obs.obs_properties_add_list(props, "scene_selected"..numOfSetting , numOfSetting .. " - When this scene switched", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)

	if scenes ~= nil then
		for _, scene in ipairs(scenes) do
			local scene_name = obs.obs_source_get_name(scene)
			obs.obs_property_list_add_string(sceneSelected, scene_name, scene_name)
		end
	end

	local selectedSource = obs.obs_properties_add_list(props, "source_selected"..numOfSetting,numOfSetting .. " - Under this source", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
        -- iterate over all the sources
        for _, source in ipairs(sources) do
            local name = obs.obs_source_get_name(source)
            obs.obs_property_list_add_string(selectedSource, name, name)
        end
	end

	obs.source_list_release(scenes)
	obs.source_list_release(sources)

	obs.obs_properties_add_text(props, "fiter_name"..numOfSetting,numOfSetting .. " - Make this filter", obs.OBS_TEXT_DEFAULT)
	local enableTheFilter =  obs.obs_properties_add_list(props, "enable_filter"..numOfSetting,numOfSetting .. " - Action: ", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(enableTheFilter, "Visible", "Visible")
	obs.obs_property_list_add_string(enableTheFilter, "Invisible","Invisible")
end

-- Script hook that is called whenver the script settings change
function script_update(_settings)	
	settings = _settings
end

-- Script hook that is called when the script is loaded
function script_load(settings)
	obs.obs_frontend_add_event_callback(handle_event)
end

function handle_event(event)
	if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
		for n = 1,totalSetting
		do
			handle_scene_change(n)
		end	
	end
end

function handle_scene_change(settingNumber)
	local sceneSelected = obs.obs_data_get_string(settings, "scene_selected"..settingNumber)
	local sourceSelected = obs.obs_data_get_string(settings, "source_selected"..settingNumber)
	local filterName = obs.obs_data_get_string(settings, "fiter_name"..settingNumber)
	local enableFilter = obs.obs_data_get_string(settings , "enable_filter"..settingNumber);

	local enablefilterBool = enableFilter == "Visible";
	if sceneSelected ~= nil and sourceSelected ~= nil and filterName ~= nil and enableFilter ~= nil then
		local currentScene = obs.obs_frontend_get_current_scene()
		if(obs.obs_source_get_name(currentScene) ~= sceneSelected)then
			enablefilterBool = not enablefilterBool
		end
		local allSources =	obs.obs_enum_sources()
			local foundSource 
			if allSources ~= nil then
				for _, source in ipairs(allSources) do
					if( sourceSelected == obs.obs_source_get_name(source)) then
						local filter_id = obs.obs_source_get_filter_by_name(source,filterName)
						if(filter_id ~= nil and obs.obs_source_get_type(filter_id) == obs.OBS_SOURCE_TYPE_FILTER) then
							obs.obs_source_set_enabled(filter_id, enablefilterBool)
							break
						end
					end
				end
			end
		obs.source_list_release(allSources)	
	end
end
