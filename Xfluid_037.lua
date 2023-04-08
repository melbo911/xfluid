-- Xfluid / melbo @x-plane.org
local version   = 37

local lod       = 0
local lodMin    = 1.0
local lodMax    = 5.0
local carMax    = 5000   -- max car lod
local carMin    = 1000   -- min car lod
local carMult   = (carMax - carMin) / 4
local fpsMin    = 30
local fpsFrames = fpsMin
local fps       = 0
local fpsAvg    = fpsMin
local fpsCnt    = 0

dataref("fp","sim/time/framerate_period","readonly")
dataref("xp_paused","sim/time/paused","readonly")
dataref("lod_rat","sim/private/controls/reno/LOD_bias_rat","writable")
dataref("lod_cars","sim/private/controls/cars/lod_min","writable")          -- 0 - 15000

local isXP12
local visMin
local visMax
if XPLMFindDataRef("sim/private/controls/clip/override_far") ~= nil then
   isXP12 = true
   dataref("dsf_vis","sim/private/controls/clip/override_far","writable")
   --dataref("dsf_vis_override","sim/private/controls/geoid/override_vis_limit","writable")
   visMin  = 80000
   visMax  = 150000
else
   isXP12 = false
   dataref("dsf_vis","sim/private/controls/skyc/max_dsf_vis_ever","writable")
   visMin    = 20000
   visMax    = 40000
end
local visMult = (visMax - visMin) / 4 
dsf_vis = visMax


--dataref("draw_cars","sim/private/controls/reno/draw_cars_05","writable")    -- 0 - 4
--dataref("dens_cars","sim/private/controls/cars/density_factor","writable")  -- 2 - 3

-- MAIN start
lod_rat = 1

-- DataRefTool-Search-Filter    (lod_bias_rat|max_dsf_vis)

function getFPS()
  if ( xp_paused == 0 ) then
    if ( fpsCnt >= fpsFrames ) then
      fpsAvg = fps / fpsCnt
      if ( fpsAvg < 0 ) then
        fpsAvg = 0
      end
      fps = 0
      fpsCnt = 0
    else
      fps = fps + (1 /fp)
      fpsCnt = fpsCnt + 1
    end
  end
end

function makeAdjustment()

  getFPS()

  -- adjust target based on FPS 
  if (fpsAvg < fpsMin-2.8) then      -- fps debit
    lod = lod_rat + ((fpsMin - fpsAvg) / 500)
  elseif (fpsAvg > fpsMin-0.2) then  -- fps credit
    lod = lod_rat - ((fpsAvg - fpsMin) / 500)
  else
    lod = 0
  end
 
  if ( lod > 0 ) then

    -- stay within limits
    if ( lod > lodMax ) then
      lod = lodMax
    elseif ( lod < lodMin ) then
      lod = lodMin
    end

    -- set datarefs
    lod_rat     = lod 

    dsf_vis     = visMax - ((lod-1) * visMult)    -- 50000 - 20000    / 20000 - 80000
 
    lod_cars    = carMax - ((lod-1) * carMult)    -- 5000 - 1000

    --planes      = math.ceil(4 - ((lod-1) * 0.25))
    --apt_detail  = math.ceil(2 - ((lod-1) * 0.4))
    --obj_density = math.floor(6 - ((lod-1) * 1))
    --draw_cars   = math.floor(2 - ((lod-1) * 0.50))
    --draw_for    = math.floor(5 - ((lod-1) * 1.25))

  end

end

do_every_frame("makeAdjustment()")

