-- Xfluid / melbo @x-plane.org
local version   = 39

local lod       = 0
local lodMin    = 1.0
local lodMax    = 5.0
local carMax    = 3000   -- max car lod
local carMin    = 1000   -- min car lod
local carMult   = (carMax - carMin) / 4
local fpsMin    = 30
local fpsFrames = fpsMin
local fps       = 0
local fpsAvg    = fpsMin
local fpsCnt    = 0

dataref("lod_rat","sim/private/controls/reno/LOD_bias_rat","writable")
dataref("lod_cars","sim/private/controls/cars/lod_min","writable")          -- 0 - 15000

-- define global variables if not exist yet
if ( FP == nil ) then
  print("%% creating global variable FP")
  dataref("FP","sim/time/framerate_period","readonly")
else
  print("%% using existing variable FP")
end

if ( VR == nil ) then
  print("%% creating global variable VR")
  dataref("VR","sim/graphics/VR/enabled","readonly")
else
  print("%% using existing variable VR")
end
if ( PAUSED == nil ) then
  print("%% creating global variable PAUSED")
  dataref("PAUSED","sim/time/paused","readonly")
else
  print("%% using existing variable PAUSED")
end

local isXP12
local visMin
local visMax
local visMult
if XPLMFindDataRef("sim/private/controls/clip/override_far") ~= nil then
  isXP12 = true
  dataref("dsf_vis","sim/private/controls/clip/override_far","writable")
  visMin  = 80000
  visMax  = 100000
else
  isXP12 = false
  dataref("dsf_vis","sim/private/controls/skyc/max_dsf_vis_ever","writable")
  visMin  = 20000
  visMax  = 40000
end
visMult = (visMax - visMin) / 4 

-- MAIN start
lod_rat = 1
dsf_vis = visMax

function getFPS()
  if ( PAUSED == 0 ) then
    if ( fpsCnt >= fpsFrames ) then
      fpsAvg = fps / fpsCnt
      if ( fpsAvg < 0 ) then
        fpsAvg = 0
      end
      fps = 0
      fpsCnt = 0
    else
      fps = fps + (1 /FP)
      fpsCnt = fpsCnt + 1
    end
  end
end

function makeAdjustment()

  getFPS()

  -- adjust target based on FPS 
  if (fpsAvg < fpsMin-2.7) then      -- fps debit
    lod = lod_rat + ((fpsMin - fpsAvg) / 800)
  elseif (fpsAvg > fpsMin-0.2) then  -- fps credit
    lod = lod_rat - ((fpsAvg - fpsMin) / 800)
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
    lod_rat       = lod 

    lod_cars      = carMax - ((lod-1) * carMult)   -- 3000 - 1000

    if ( isXP12 and VR == 0  ) then                -- extend view in 2D
      dsf_vis     = 0
    else
      dsf_vis   = visMax - ((lod-1) * visMult)     -- 50000 - 20000    / 150000 - 80000
    end

    --planes      = math.ceil(4 - ((lod-1) * 0.25))
    --apt_detail  = math.ceil(2 - ((lod-1) * 0.4))
    --obj_density = math.floor(6 - ((lod-1) * 1))
    --draw_cars   = math.floor(2 - ((lod-1) * 0.50))
    --draw_for    = math.floor(5 - ((lod-1) * 1.25))

  end

end

do_every_frame("makeAdjustment()")
