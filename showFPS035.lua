-- show FPS 
-- version 0.35
-- (c) 2023 melbo @x-plane.org

if not SUPPORTS_FLOATING_WINDOWS then
    -- to make sure the script doesn't stop old FlyWithLua versions
    logMsg("imgui not supported by your FlyWithLua version")
    return
end

local PluginTitle = 'FPS/LOC'
local wnd_open = 0
local SFPS_wnd
local fps = 0
local fpsAvg = 0.0
local fpsCnt = 0
local fpsMin = 29
local hasHook = false
local winWidth = 162
--local winHeight = 65
local winHeight = 80

local localtime = os.date("%X")
local stime = os.time();
local slip = "---------[-]---------"

local isXP12
if XPLMFindDataRef("sim/private/controls/clip/override_far") ~= nil then
   isXP12 = true
   dataref("dsf_vis","sim/private/controls/clip/override_far","readonly")
else
   isXP12 = false
   dataref("dsf_vis","sim/private/controls/skyc/max_dsf_vis_ever","readonly")
end

dataref("lod_rat","sim/private/controls/reno/LOD_bias_rat","readonly")

-- define variables if not exist yet
if ( VR == nil ) then
  print("%% creating global variable VR")
  dataref("VR","sim/graphics/VR/enabled","readonly")
else
  print("%% using existing variable VR")
end
if ( FP == nil ) then
  print("%% creating global variable FP")
  dataref("FP","sim/time/framerate_period","readonly")
else
  print("%% using existing variable FP")
end
if ( PAUSED == nil ) then
  print("%% creating global variable PAUSED")
  dataref("PAUSED","sim/time/paused","readonly")
else
  print("%% using existing variable PAUSED")
end

dataref("planes","sim/private/controls/park/static_plane_density","readonly")
dataref("apt_detail","sim/private/controls/reno/draw_detail_apt_03","readonly")
dataref("obj_density","sim/private/controls/reno/draw_objs_06","readonly")
dataref("draw_cars","sim/private/controls/reno/draw_cars_05","readonly")
dataref("dens_cars","sim/private/controls/cars/density_factor","readonly")
dataref("lod_cars","sim/private/controls/cars/lod_min","readonly")
dataref("view_hdg","sim/graphics/view/view_heading","readonly")
dataref("slip_deg","sim/cockpit2/gauges/indicators/sideslip_degrees","readonly")

--if (XPLMFindDataRef("alpinehoist/heighthook") ~= nil) then
if (XPLMFindDataRef("alpinehoist/carried_load/height") ~= nil) then
  dataref("hook","alpinehoist/carried_load/height","readonly")
  dataref("jetlen","sim/flightmodel/misc/jett_len","readonly")  
  hasHook = true
  winHeight = winHeight + 20
end

-- functions start here ------------------------

function SFPS_ToggleWindow()
  if wnd_open == 0 then
    local frames = 1
    if ( VR == 1 ) then
       frames = 0
    end
    SFPS_wnd = float_wnd_create(winWidth, winHeight, frames, true)
    float_wnd_set_title(SFPS_wnd, PluginTitle)
    float_wnd_set_imgui_builder(SFPS_wnd, "SFPS_main_menu")
    float_wnd_set_onclose(SFPS_wnd, "SFPS_closed")
    wnd_open = 1
  else
    float_wnd_destroy(SFPS_wnd)
  end 
end

function SFPS_closed(wnd)
  wnd_open = 0
end

function SFPS_main_menu(wnd, x, y)
  if ( PAUSED < 2 ) then
    if ( os.time() > stime ) then
      fpsAvg = fps / fpsCnt
      if ( fpsAvg < 0 ) then
        fpsAvg = 0
      end
      fps = 0
      fpsCnt = 0
      stime = os.time()
      localtime = os.date("%X")
    else 
      fps = fps + (1 / FP) 
      fpsCnt = fpsCnt + 1
    end

    if ( fpsAvg >= fpsMin ) then
      imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00FF00)  -- green
    else
      imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF1E90FF)  -- red
    end
    imgui.TextUnformatted(string.format("FPS:%03.2f    %s HDG:%03d", fpsAvg, localtime, view_hdg))
    imgui.PopStyleColor()	 

    --imgui.TextUnformatted(string.format("LOD:%1.3f PLN:%d APT:%d CDEN:%d", lod_rat, planes, apt_detail,dens_cars))
    --imgui.TextUnformatted(string.format("VIS:%05d CAR:%d OBJ:%d CLOD:%d", dsf_vis, draw_cars, obj_density,lod_cars))

    if ( isXP12 ) then
      imgui.TextUnformatted(string.format("LOD:%1.3f  VIS:%06d CAR:%d", lod_rat, dsf_vis, lod_cars))
    else
      imgui.TextUnformatted(string.format("LOD:%1.3f   VIS:%05d CAR:%d", lod_rat, dsf_vis, lod_cars))
    end

    if ( slip_deg < 0.5 and slip_deg > -0.5 ) then
       n = 11
    else
       n = (11+math.floor(slip_deg/9))
    end
    if ( n > 21 ) then n = 21 end
    if ( n < 1 ) then n = 1 end
    imgui.TextUnformatted(string.format("%s%s%s",slip:sub(1,n-1), "O", slip:sub(n+1) ))
   
    imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF00FFFF)
    imgui.TextUnformatted(string.format("LOC:%.4f/%.4f", LATITUDE, LONGITUDE )) 
    imgui.PopStyleColor()    
    if ( hasHook ) then
      imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF1E90FF)  -- orange
      imgui.TextUnformatted(string.format("HOK:%.1f LEN:%02d", hook, jetlen ))   
      imgui.PopStyleColor()
    end
  end
end

-- 

add_macro("Show FPS", "SFPS_ToggleWindow()")
create_command("FlyWithLua/showFPS", "Show FPS", "SFPS_ToggleWindow()", "", "")

