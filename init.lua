local R_LIFE_POS_X = 70
local R_LIFE_POS_Y = 550
local R_LIFE_POS_W = 200
local R_LIFE_POS_H = 30

local WIN_W = 1024
local WIN_H = 600

local SCEEN_RIGHT = WIN_W / 2
local SCREEN_NPCS_Y = 150

local T_COLOR = 0xffff10ff

local RT_COLOR = 0x10ffffff

local TV_PIXS =
"     *    " ..
"**********" ..
"*########*" ..
"*########*" ..
"*########*" ..
"**********"

local tv_txt_x = 60
local tv_txt_y = 140

local TRIANGLE_PIXS =
"         " ..
"    #    " ..
"   ###   " ..
"  #####  " ..
" ####### " ..
"         "

local SQUARE_PIXS =
"         " ..
" ####### " ..
" ####### " ..
" ####### " ..
" ####### " ..
"         "

local TYPE_SQUARE = 0
local TYPE_TRIANGLE = 1

local BAR_BG_RECT = 0
local BAR_FG_RECT = 1
local BAR_X = 2
local BAR_Y = 3
local BAR_W = 4
local BAR_H = 5
local BAR_MAX = 6
local BAR_CUR = 7
local BAR_COLOR = 8

local NPC_TYPE = 0
local NPC_INVERSED = 1
local NPC_GOOD_COL = 2
local NPC_HAVE_CHANGE_INVERSE = 3

local function mk_npc(wid, npc_type, in_out, good_color)
   local ret = Entity.new_array(yeGet(wid, "npcs"))

   ret[NPC_TYPE] = npc_type
   ret[NPC_INVERSED] = in_out
   ret[NPC_GOOD_COL] = good_color
   ret[NPC_HAVE_CHANGE_INVERSE] = 0
   return ret
end

function print_all_npc(wid)
   local npcs = Entity.wrapp(yeGet(wid, "npcs"))
   local npcs_printable = Entity.wrapp(yeGet(wid, "npcs_p"))
   ywCanvasClearArray(npcs_printable)
   local x = SCEEN_RIGHT + 5
   local y = SCREEN_NPCS_Y + 5

   for i = 0, yeLen(npcs) - 1 do
      local n = npcs[i]
      local pixs = TRIANGLE_PIXS
      local info = nil

      if n[NPC_TYPE] < TYPE_TRIANGLE then
	 pixs = SQUARE_PIXS
      end
      if n[NPC_INVERSED] < 1 then
	 if n[NPC_GOOD_COL] < 1 then
	    info = "t_w_info"
	 else
	    info = "t_info"
	 end
      else
	 if n[NPC_GOOD_COL] < 1 then
	    info = "rt_w_info"
	 else
	    info = "rt_info"
	 end
      end
      local co = ywCanvasNewHeadacheImg(wid, x, y, Entity.new_string(pixs), yeGet(wid, info))
      x = x + 40
      if x > WIN_W - 40 then
	 x = SCEEN_RIGHT + 5
	 y = y + 40
      end
      yePushBack(npcs_printable)
   end
end

local function bar_cur(bar)
   return yeGetIntAt(bar, BAR_CUR)
end

local TIMED_TXT_CANVASOBJ = 0
local TIMED_TXT_TIME = 1

local function timed_txt_dec(wid, name, nb)
   local tt = Entity.wrapp(wid)[name]
   local t = tt[TIMED_TXT_TIME]:to_int()

   t = t - nb
   if t < 0 then
      ywCanvasRemoveObj(wid, tt[TIMED_TXT_CANVASOBJ])
      tt[TIMED_TXT_CANVASOBJ] = nil
      return false
   else
      tt[TIMED_TXT_TIME] = t
      return true
   end
end

local function mk_timed_txt(wid, name, x, y, timer, txt)
   local ret = Entity.new_array(wid, name)

   ret[TIMED_TXT_CANVASOBJ] = ywCanvasNewTextByStr(wid, x, y, txt)
   ret[TIMED_TXT_TIME] = timer
   return ret
end

local function mk_bar(wid, color, name, x, y, w, h, max)
   local ret = Entity.new_array(wid, name)

   ret[BAR_BG_RECT] = ywCanvasNewRectangle(wid, x, y, w, h, "rgba: 0 0 0 255")
   ret[BAR_FG_RECT] = ywCanvasNewRectangle(wid, x + 3, y + 3, w - 6, h - 6, color)
   ret[BAR_X] = x
   ret[BAR_Y] = y
   ret[BAR_W] = w
   ret[BAR_H] = h
   ret[BAR_MAX] = max
   ret[BAR_CUR] = max
   ret[BAR_COLOR] = color
   return ret
end

local function bar_dec(wid, bar_name, to_sub)
   local bar = wid[bar_name]
   local x = bar[BAR_X]:to_int()
   local y = bar[BAR_Y]:to_int()
   local w = bar[BAR_W]:to_int()
   local h = bar[BAR_H]:to_int()
   local max = bar[BAR_MAX]:to_int()
   local cur = bar[BAR_CUR]:to_int()

   cur = cur - to_sub
   bar[BAR_CUR] = cur

   ywCanvasRemoveObj(wid, bar[BAR_FG_RECT])
   bar[BAR_FG_RECT] = ywCanvasNewRectangle(
      wid, x + 3, y + 3,
      w * cur / max,
      h - 6, bar[BAR_COLOR]:to_string())
end



function dsr_Action(wid, eves)
   wid = Entity.wrapp(wid)
   bar_dec(wid, "wolf-bar", 2)
   bar_dec(wid, "=earth-hp-r", 1)
   timed_txt_dec(wid, "test-txt", 1)
   if yevIsKeyDown(eves, Y_Q_KEY) == true then
      return ygCallFuncOrQuit(wid, "quit")
   end
   if bar_cur(wid["=earth-hp-r"]) < 1 then
      return ygCallFuncOrQuit(wid, "die")
   end
   print_all_npc(wid)
end

function dsr_init(wid)
   wid = Entity.wrapp(wid)
   print("DSR INIT !")

   wid.background = "rgba: 255 255 255 255"
   wid.action = Entity.new_func(dsr_Action)
   ywSetTurnLengthOverwrite(100000)

   local ret = ywidNewWidget(wid, "canvas")
   ywCanvasNewVSegment(wid, SCEEN_RIGHT, 0, 1000, "rgba: 0 0 0 255")
   ywCanvasNewHSegment(wid, SCEEN_RIGHT, SCREEN_NPCS_Y, WIN_W / 2, "rgba: 0 0 0 255")

   yeCreateArray(wid, "npcs")
   yeCreateArray(wid, "npcs_p")

   mk_bar(wid, "rgba: 100 255 100 155", "=earth-hp-r", R_LIFE_POS_X, R_LIFE_POS_Y,
	  R_LIFE_POS_W, R_LIFE_POS_H, 100)
   mk_bar(wid, "rgba: 100 255 200 155", "wolf-bar", SCEEN_RIGHT + 30, 110, 300, 20, 250)
   local triangle_info = Entity.new_array(wid, "t_info")
   triangle_info.mapping = {}
   yeCreateInt(T_COLOR, triangle_info.mapping, "#")
   ywSizeCreate(2, 3, triangle_info, 'pix_per_char')
   ywSizeCreate(9, 6, triangle_info, 'size')
   wid.all_tris = Entity.new_array()

   local rev_tri_info = Entity.new_array(wid, "rt_info")
   rev_tri_info.mapping = {}
   yeCreateInt(RT_COLOR, rev_tri_info.mapping, " ")
   ywSizeCreate(3, 3, rev_tri_info, 'pix_per_char')
   ywSizeCreate(9, 6, rev_tri_info, 'size')

   local ret_tri_wrong_info = Entity.new_copy(rev_tri_info, wid, "rt_w_info")
   yeCreateIntAt(T_COLOR, ret_tri_wrong_info.mapping, " ", 0)

   local tri_wrong_info = Entity.new_copy(triangle_info, wid, "t_w_info")
   yeCreateIntAt(RT_COLOR, tri_wrong_info.mapping, "#", 0)

   mk_npc(wid, TYPE_SQUARE, true, true)
   mk_npc(wid, TYPE_SQUARE, true, false)
   mk_npc(wid, TYPE_SQUARE, false, true)
   mk_npc(wid, TYPE_SQUARE, false, false)
   mk_npc(wid, TYPE_TRIANGLE, true, false)
   mk_npc(wid, TYPE_TRIANGLE, true, true)

   local big_1 = ywCanvasNewHeadacheImg(wid, SCEEN_RIGHT + 20, 10,
					Entity.new_string(TRIANGLE_PIXS),
					yeGet(wid, "t_info"))
   ywCanvasForceSizeXY(big_1, 80, 100)
   local big_0 = ywCanvasNewHeadacheImg(wid, SCEEN_RIGHT + 160, 10,
					Entity.new_string(TRIANGLE_PIXS),
					yeGet(wid, "rt_info"))
   ywCanvasForceSizeXY(big_0, 60, 80)

   local tv_info = Entity.new_array(wid, "tv_info")
   tv_info.mapping = {}
   yeCreateInt(0x000000ff, tv_info.mapping, "*")
   yeCreateInt(0x9999992f, tv_info.mapping, "#")
   ywSizeCreate(2, 3, tv_info, 'pix_per_char')
   ywSizeCreate(10, 6, tv_info, 'size')

   local tv = ywCanvasNewHeadacheImg(wid, 30, 20,
				     Entity.new_string(TV_PIXS),
				     yeGet(wid, "tv_info"))
   ywCanvasForceSizeXY(tv, 300, 300)

   mk_timed_txt(wid, "test-txt", tv_txt_x, tv_txt_y, 50, "je test de mettre du txt !!!")
   return ret
end

function init_dsr(mod)
   mod = Entity.wrapp(mod)
   local init = Entity.new_array()

   init.name = "depleted-square-root"
   init.callback = Entity.new_func(dsr_init)

   mod["starting widget"] = Entity.new_array()
   mod["starting widget"]["<type>"] = "depleted-square-root"
   ywidAddSubType(init)
   return mod
end
