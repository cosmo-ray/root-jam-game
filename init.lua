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

local TV_TXT_X = 60
local TV_TXT_Y = 140

local TV_BOTTOM = 330

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

local TRIANGLE_HATE = 1
local R_TRIANGLE_HATE = 2
local TRIANGLE_W_HATE = 3
local R_TRIANGLE_W_HATE = 4
local SQUARE_HATE = 5
local BIG_HATE = 6

local function hate_idx_to_string(hate_idx)
   if hate_idx == TRIANGLE_HATE then
      return "triangle"
   elseif hate_idx == R_TRIANGLE_HATE then
      return "inv tri"
   elseif hate_idx == TRIANGLE_W_HATE then
      return "wrongly col"
   elseif hate_idx == R_TRIANGLE_W_HATE then
      return "invert wrong"
   elseif hate_idx == SQUARE_HATE then
      return "square"
   elseif hate_idx == BIG_HATE then
      return "THE BIG"
   end
end

local function compute_total_hate()
   return hates_array[TRIANGLE_HATE] + hates_array[R_TRIANGLE_HATE]
      + hates_array[TRIANGLE_W_HATE] + hates_array[R_TRIANGLE_W_HATE]
      + hates_array[SQUARE_HATE] + hates_array[BIG_HATE]
end

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

local menu_resultat = 0
local menu_is_on = false
local menu_options = nil
local menu_txt_objs = {}

local last_agresor = 0

local function handle_menu(wid, eves)
   if yevIsKeyDown(eves, Y_UP_KEY) == true then
      menu_resultat = menu_resultat - 1
      if menu_resultat < 0 then
	 menu_resultat = #menu_options - 1
      end
      ywCanvasObjSetPos(menu_rectangle_cur, 25, 25 + menu_resultat * 20)
   elseif yevIsKeyDown(eves, Y_DOWN_KEY) == true then
      menu_resultat = menu_resultat + 1
      if menu_resultat > #menu_options - 1 then
	 menu_resultat = 0
      end
      ywCanvasObjSetPos(menu_rectangle_cur, 25, 25 + menu_resultat * 20)
   elseif yevIsKeyDown(eves, Y_ENTER_KEY) == true then
      ywCanvasRemoveObj(wid, menu_rectangle_bg)
      ywCanvasRemoveObj(wid, menu_rectangle_txts_bg)
      ywCanvasRemoveObj(wid, menu_rectangle_cur)
      for i,v in ipairs(menu_txt_objs) do
	 ywCanvasRemoveObj(wid, v)
      end
      menu_txt_objs = {}
      menu_is_on = false
      return true
   end
   return false
end

local function mk_menu(wid, options)
   menu_is_on = true
   menu_resultat = 0
   menu_txt_objs = {}
   menu_rectangle_bg = ywCanvasNewRectangle(wid, 20, 20, 500, 20 * #options + 10,
				       "rgba: 120 120 120 200")
   menu_rectangle_txts_bg = ywCanvasNewRectangle(wid, 25, 25, 490, 20 * #options,
					   "rgba: 255 255 255 200")
   menu_rectangle_cur = ywCanvasNewRectangle(wid, 25, 25, 490, 20,
					   "rgba: 200 200 200 200")
   menu_options = options
   for i,v in ipairs(options) do
      print(i, v)
      menu_txt_objs[i] = ywCanvasNewTextByStr(wid, 26, 26 + (i - 1) * 20, v)
   end
end

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
   ywCanvasClearArray(wid, npcs_printable)
   local x = SCEEN_RIGHT + 5
   local y = SCREEN_NPCS_Y + 5
   local npcs_len = yeLen(npcs)

   for i = 0, npcs_len - 1 do
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
      yePushBack(npcs_printable, co)
   end
end

local function bar_cur(bar)
   return yeGetIntAt(bar, BAR_CUR)
end

local TIMED_TXT_CANVASOBJ = 0
local TIMED_TXT_TIME = 1

local function timed_txt_dec(wid, name, nb)
   local tt = Entity.wrapp(wid)[name]
   if yIsNil(tt) then
      return
   end
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

local function mk_timed_txt(wid, name, x, y, timer, txt, color)
   Entity.wrapp(wid)[name] = nil
   local ret = Entity.new_array(wid, name)

   ret[TIMED_TXT_CANVASOBJ] = ywCanvasNewTextByStr(wid, x, y, txt)
   if yIsNNil(color) then
      ywCanvasSetStrColor(ret[TIMED_TXT_CANVASOBJ], color)
   end
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
   if cur > max then
      bar[BAR_CUR] = max
   elseif cur < 0 then
      bar[BAR_CUR] = 0
   else
      bar[BAR_CUR] = cur
   end

   ywCanvasRemoveObj(wid, bar[BAR_FG_RECT])
   bar[BAR_FG_RECT] = ywCanvasNewRectangle(
      wid, x + 3, y + 3,
      (w - 6) * cur / max,
      h - 6, bar[BAR_COLOR]:to_string())
end

local function bar_dec_from_hateidx(wid, hate_idx, nb)
   if hate_idx == TRIANGLE_HATE then
      return bar_dec(wid, "t_hp", nb)
   elseif hate_idx == R_TRIANGLE_HATE then
      return bar_dec(wid, "rt_hp", nb)
   elseif hate_idx == TRIANGLE_W_HATE then
      return bar_dec(wid, "tw_hp", nb)
   elseif hate_idx == R_TRIANGLE_W_HATE then
      return bar_dec(wid, "rtw_hp", nb)
   elseif hate_idx == SQUARE_HATE then
      return bar_dec(wid, "s_hp", nb)
   elseif hate_idx == BIG_HATE then
      return bar_dec(wid, "wolf-bar", nb)
   end
end

local turn_consumer_txt_cnt = 0
local score = 0

local function show_consumption(wid, who, howmuch)
   ycoRepushObj(
      wid, who,
      ywCanvasNewTextByStr(wid, 20 + yAnd(turn_consumer_txt_cnt, 1) * 240,
			   WIN_H - 100 + (math.floor(turn_consumer_txt_cnt / 2) * 15),
			   who .. " consume " .. howmuch))
   bar_dec(wid, "=earth-hp-r", howmuch)

   turn_consumer_txt_cnt = turn_consumer_txt_cnt + 1

end

local turn_cnt = 0

function dsr_Action(wid, eves)
   wid = Entity.wrapp(wid)

   -- bar_dec(wid, "wolf-bar", 2)
   if menu_is_on == true then
      ret = handle_menu(wid, eves)
      if ret then
	 timed_txt_dec(wid, "tv-txt", 1)
	 timed_txt_dec(wid, "dmg-txt", 1)

	 local end_tv_txt = ""
	 local end_info_txt = ""
	 print("menu_resultat: ", menu_resultat)
	 timed_txt_dec(wid, "tv-txt", 1)
	 timed_txt_dec(wid, "dmg-txt", 1)
	 if menu_resultat == 0 then
	    local sucess = (yAnd(yuiRand(), 3) == 3)
	    local nb = 1 + (yuiRand() % 8)
	    print("sucess: ", sucess)
	    end_tv_txt = "TV show about a BIG\n"..
	       "suffering from not been accepted\n" ..
	       "by other because he's too big"
	    if sucess == false then
	       hates_array[BIG_HATE] = hates_array[BIG_HATE] - nb
	       end_info_txt = "TV show piss peoples:\nhate increase: " .. nb
	    else
	       hates_array[BIG_HATE] = hates_array[BIG_HATE] + nb
	       end_info_txt = "more empathi troward us:\nhate reduce: " .. nb
	    end
	 elseif menu_resultat == 1 then
	    local r = yuiRand() % 5
	    if r == 0 then
	       end_tv_txt = "TV reportage:\nabout a child been abuse\n" ..
		  "by his " .. hate_idx_to_string(last_agresor) .. " parent"
	    elseif r == 1 then
	       end_tv_txt = "TV news:\nabout a group of\n" ..
		  hate_idx_to_string(last_agresor) .. "\nwho create a reign of terror\n" ..
		  "in they city"
	    elseif r == 2 then
	       end_tv_txt = "Politicals talk:\nsomeone theorise that\n" ..
		  hate_idx_to_string(last_agresor) .. "\nare replacing the cultur of our contry"
	    elseif r == 3 then
	       end_tv_txt = "TV news: some\n" ..
		  hate_idx_to_string(last_agresor) .. "\nare trying to replace very famous\nwork of art\nbecause they find it offensive"
	    else
	       end_tv_txt = "TV reportage:\babout a " ..
		  hate_idx_to_string(last_agresor) .. "\nwinning a competition\n" ..
		  "due to genetic advatage"
	    end
	 elseif menu_resultat == 2 then
	    big_consume = big_consume + 2
	    hates_array[BIG_HATE] = hates_array[BIG_HATE] + 20
	    end_tv_txt = "BIG increase they share on root"
	 elseif menu_resultat == 3 then
	    small_triangle_consume = small_triangle_consume - 1
	    small_i_triangle_consume = small_i_triangle_consume - 1
	    square_consume = square_consume - 1
	    end_tv_txt = "SMALL increase they share on root"
	    hates_array[BIG_HATE] = hates_array[BIG_HATE] + 20
	 end
	 local target_hate = yuiRand() % compute_total_hate(hates_array)
	 last_agresor = yuiRand() % 5 + 1
	 local tot_v = 0
	 local target = 0
	 for i,v in ipairs(hates_array) do
	    tot_v = tot_v + v
	    if target_hate < tot_v then
	       target = i
	       break
	    end
	 end
	 local nb_dmg = 1 + yuiRand() % 20
	 bar_dec_from_hateidx(wid, target, nb_dmg)
	 end_tv_txt = end_tv_txt .. "\n" .. hate_idx_to_string(last_agresor) ..
	    "\ncommit crime against\n" .. hate_idx_to_string(target)
	 end_info_txt = end_info_txt .. "\n" .. hate_idx_to_string(target) .. " recive\n" ..
	    nb_dmg .. " dmg"
	 mk_timed_txt(wid, "tv-txt", TV_TXT_X, TV_TXT_Y - 10, 15, end_tv_txt)
	 mk_timed_txt(wid, "dmg-txt", TV_TXT_X + 280, TV_TXT_Y, 15, end_info_txt, "rgba: 255 0 0 255")
      else
	 return
      end
   end
   timed_txt_dec(wid, "tv-txt", 1)
   timed_txt_dec(wid, "dmg-txt", 1)
   if turn_cnt % 15 == 0 then
      print("NEW ACTION")
      if turn_cnt > 30 then
	 turn_cnt = turn_cnt + 1
	 mk_menu(wid, {"try to reduce BIG hatred", "reuse last events: present " .. hate_idx_to_string(last_agresor) .. " as dangerous for socity", "increase BIG root share",
	 "decrease smal share"})
      elseif turn_cnt == 15 then
	 mk_timed_txt(wid, "tv-txt", TV_TXT_X, TV_TXT_Y, 14,
		      "NEW LAW\ndecrase SR access to triangles"..
		      "\nReaction:\nBig strike against, THE BIG !!!")
	 mk_timed_txt(wid, "dmg-txt", TV_TXT_X + 300, TV_TXT_Y, 14, "peoples are\nangry against us\ndmg deal: " .. 25, "rgba: 255 0 0 255")
	 small_triangle_consume = 3
	 small_i_triangle_consume = 3
	 bar_dec(wid, "wolf-bar", 25)
      elseif turn_cnt == 30 then
	 local target = yuiRand() % 4 + R_TRIANGLE_HATE
	 local src = yuiRand() % 5 + 1
	 while src == target do
	    src = yuiRand() % 5 + 1
	 end
	 local hate_atk = "a " .. hate_idx_to_string(src) .. " attack\na " .. hate_idx_to_string(target) .. "\nout of pure hate"
	 local deal_txt = hate_idx_to_string(target) .. " recive 4 dmg"

	 mk_timed_txt(wid, "tv-txt", TV_TXT_X, TV_TXT_Y, 15,
		      "new big strike against\nTHE BIG !!!\n".. hate_atk)
	 mk_timed_txt(wid, "dmg-txt", TV_TXT_X + 300, TV_TXT_Y, 15, "peoples are\nangry against us\ndmg deal: " .. 13 .. "\n" .. deal_txt, "rgba: 255 0 0 255")
	 bar_dec(wid, "wolf-bar", 13)
	 bar_dec_from_hateidx(wid, target, 4)
	 last_agresor = src
      end
   end
   turn_cnt = turn_cnt + 1
   ycoRepushObj(
      wid, "my-score",
      ywCanvasNewTextByStr(wid, SCEEN_RIGHT + 300, 10, "score: " .. score))

   ycoRepushObj(
      wid, "heal-hp-earth",
      ywCanvasNewTextByStr(wid, 300, WIN_H - 40, "square root heal " .. -13))

   turn_consumer_txt_cnt = 0
   show_consumption(wid, "BIG ONES", big_consume)
   show_consumption(wid, "plain triangle", small_triangle_consume)
   show_consumption(wid, "invers triangle", small_i_triangle_consume)
   show_consumption(wid, "all squares", square_consume)

   bar_dec(wid, "=earth-hp-r", -13)

   if yevIsKeyDown(eves, Y_Q_KEY) == true then
      return ygCallFuncOrQuit(wid, "quit")
   end
   if bar_cur(yeGet(wid, "wolf-bar")) < 1 then
      print("YOU LOSE !")
      return ygCallFuncOrQuit(wid, "die")
   end

   if bar_cur(wid["=earth-hp-r"]) < 1 then
      return ygCallFuncOrQuit(wid, "die")
   end

   score = score + big_consume
   print_all_npc(wid)
   if turn_cnt == 1 then
      y_stop_head(wid, 0, 0,
		  "HELLO, and welcom to this very incomplet game\n"..
		  "My goal was to make a game where you play\nsome ultra rich peoples (THE BIG)\n"..
		  "You control TV, On the bottom of the screen, there is the\n" ..
		  "root life, it's the life of the earth\n" ..
		  "but also what every one need to live, and as sure\nevery one consume it\n" ..
		  "you goal is to consume as much as posible of this energy\n" ..
		  "while keeping other from consuming too much\nor earth will be dead\n"..
		  "your weapon is to use TV to protect yourself\nfrom having everyone\n" ..
		  "hating you, to do that\nyou must redirect peoples hate troward themself\n"..
		  "so they leave you alone")
   end

end

function dsr_init(wid)
   wid = Entity.wrapp(wid)
   print("DSR INIT !")

   -- INIT GLOBALS
   score = 0
   big_consume = 4
   small_triangle_consume = 4
   small_i_triangle_consume = 4
   square_consume = 2
   hates_array = {0, 5, 7, 4, 10, 25}

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
   mk_bar(wid, "rgba: 100 255 200 155", "wolf-bar", SCEEN_RIGHT + 30, 110, 300, 20, 300)
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

   for i = 0, 131 do
      local rand = yuiRand() % 100

      if rand < 8 then
	 mk_npc(wid, TYPE_SQUARE, false, true)
      else
	 local in_out = false
	 local goodcol = true
	 if rand % 2 == 0 then
	    in_out = true
	 end
	 if rand > 90 then
	    goodcol = false
	 end
	 mk_npc(wid, TYPE_TRIANGLE, in_out, goodcol)
      end
   end

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

   mk_timed_txt(wid, "tv-txt", TV_TXT_X, TV_TXT_Y, 15, "The News today oh boy !!!")

   -- everyone info part
   ywCanvasNewHeadacheImg(wid, 30, TV_BOTTOM,
			  Entity.new_string(TRIANGLE_PIXS),
			  yeGet(wid, "t_info"))
   mk_bar(wid, "rgba: 255 255 100 200", "t_hp", 65, TV_BOTTOM, 200, 22, 100)
   ywCanvasNewTextByStr(wid, 280, TV_BOTTOM, "< triangles")

   ywCanvasNewHeadacheImg(wid, 30, TV_BOTTOM + 30,
			  Entity.new_string(TRIANGLE_PIXS),
			  yeGet(wid, "rt_info"))
   mk_bar(wid, "rgba: 255 255 100 200", "rt_hp", 65, TV_BOTTOM + 30, 200, 22, 100)
   ywCanvasNewTextByStr(wid, 280, TV_BOTTOM + 30, "< inv tri")

   ywCanvasNewHeadacheImg(wid, 30, TV_BOTTOM + 60,
			  Entity.new_string(TRIANGLE_PIXS),
			  yeGet(wid, "t_w_info"))
   mk_bar(wid, "rgba: 255 255 100 200", "tw_hp", 65, TV_BOTTOM + 60, 200, 22, 100)
   ywCanvasNewTextByStr(wid, 280, TV_BOTTOM + 60, "< wrongly col")

   ywCanvasNewHeadacheImg(wid, 30, TV_BOTTOM + 90,
			  Entity.new_string(TRIANGLE_PIXS),
			  yeGet(wid, "rt_w_info"))
   mk_bar(wid, "rgba: 255 255 100 200", "rtw_hp", 65, TV_BOTTOM + 90, 200, 22, 100)
   ywCanvasNewTextByStr(wid, 280, TV_BOTTOM + 90, "< invert wrong")

   ywCanvasNewHeadacheImg(wid, 30, TV_BOTTOM + 120,
			  Entity.new_string(SQUARE_PIXS),
			  yeGet(wid, "t_info"))
   mk_bar(wid, "rgba: 255 255 100 200", "s_hp", 65, TV_BOTTOM + 120, 200, 22, 100)
   ywCanvasNewTextByStr(wid, 280, TV_BOTTOM + 120, "< square")

   --ywCanvasNewTextByStr(wid, 30, TV_BOTTOM + 150, "<->")
   --mk_bar(wid, "rgba: 255 255 100 200", "c_hp", 65, TV_BOTTOM + 150, 200, 22, 100)
   return ret
end

function init_dsr(mod)
   mod = Entity.wrapp(mod)
   local init = Entity.new_array()
   yePrint(mod["pre-load"])

   init.name = "depleted-square-root"
   init.callback = Entity.new_func(dsr_init)

   mod["starting widget"] = Entity.new_array()
   mod["starting widget"]["<type>"] = "depleted-square-root"
   ywidAddSubType(init)
   return mod
end
