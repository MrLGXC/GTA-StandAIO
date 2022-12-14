--倒卖狗不得好死,给你妈凑买棺材板的钱呢是吧？-- 
--jinx Scirpt中文区翻译: lu_zi / BlackMist 臣服 -- 
util.require_natives("natives-1663599433-uno")
local response = false
local localVer = 3.3
local currentVer
async_http.init("raw.githubusercontent.com", "/Prisuhm/JinxScript/main/JinxScriptVersion", function(output)
    currentVer = tonumber(output)
    response = true
    if localVer ~= currentVer then
        util.toast("新版本已推送,更新脚本来获取最新版本.")
        menu.action(menu.my_root(), "更新此脚本", {}, "点击后会导致全英文,等Jinx中文区更新", function()
            async_http.init('raw.githubusercontent.com','/Prisuhm/JinxScript/main/JinxScript.lua',function(a)
                local err = select(2,load(a))
                if err then
                    util.toast("脚本下载失败,请稍后重试,如果这种情况继续发生,请通过 Github 手动更新.")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(a)
                f:close()
                util.toast("更新成功,请重启脚本:)")
                util.restart_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end) 
async_http.dispatch()
repeat 
    util.yield()
until response


local function player_toggle_loop(root, pid, menu_name, command_names, help_text, callback)
    return menu.toggle_loop(root, menu_name, command_names, help_text, function()
        if not players.exists(pid) then util.stop_thread() end
        callback()
    end)
end

local spawned_objects = {}

local function BitTest(bits, place)
    return (bits & (1 << place)) ~= 0
end

local function IsPlayerUsingOrbitalCannon(player)
    return BitTest(memory.read_int(memory.script_global((2657589 + (player * 466 + 1) + 427))), 0) -- Global_2657589[PLAYER::PLAYER_ID() /*466*/].f_427), 0
end

local function IsPlayerFlyingAnyDrone(player)
   return BitTest(memory.read_int(memory.script_global(1853910 + (player * 862 + 1) + 267 + 365)), 26) -- Global_1853910[PLAYER::PLAYER_ID() /*862*/].f_267.f_365, 26
end

local function IsPlayerUsingGuidedMissile(player)
    return (memory.read_int(memory.script_global(2657589 + 1 + (player * 466) + 321 + 10)) ~= -1 and IsPlayerFlyingAnyDrone(player)) -- Global_2657589[PLAYER::PLAYER_ID() /*466*/].f_321.f_10 
end

local function IsPlayerInRcBandito(player)
    return BitTest(memory.read_int(memory.script_global(1853348 + (player * 834 + 1) + 267 + 348)), 29)  -- Global_1853348[PLAYER::PLAYER_ID() /*834*/].f_267.f_348, 29
end

local function IsPlayerInRcTank(player)
    return BitTest(memory.read_int(memory.script_global(1853348 + (player * 834 + 1) + 267 + 428 + 2)), 16) -- Global_1853910[PLAYER::PLAYER_ID() /*862*/].f_267.f_428.f_2
end

local function get_spawn_state(pid)
    return memory.read_int(memory.script_global(((2657589 + 1) + (pid * 466)) + 232)) -- Global_2657589[PLAYER::PLAYER_ID() /*466*/].f_232
end

local function get_interior_player_is_in(pid)
    return memory.read_int(memory.script_global(((2657589 + 1) + (pid * 466)) + 245)) -- Global_2657589[bVar0 /*466*/].f_245
end

local function is_player_in_interior(pid)
    return (memory.read_int(memory.script_global(2657589 + 1 + (pid * 466) + 245)) ~= 0)
end

local function IsPlayerInKosatka(player)
    return BitTest(memory.read_int(memory.script_global(1853910 + (player * 862 + 1 ) + 267 + 479)), 2) -- Global_1853910[PLAYER::PLAYER_ID() /*862*/].f_267.f_479, 2
end


local function setBit(addr, bitIndex)
    memory.write_int(addr, memory.read_int(addr) | (1<<bitIndex))
end

local function clearBit(addr, bitIndex)
    memory.write_int(addr, memory.read_int(addr) & ~(1<<bitIndex))
end

local function request_model(hash, timeout)
    timeout = timeout or 3
    STREAMING.REQUEST_MODEL(hash)
    local end_time = os.time() + timeout
    repeat
        util.yield()
    until STREAMING.HAS_MODEL_LOADED(hash) or os.time() >= end_time
    return STREAMING.HAS_MODEL_LOADED(hash)
end

local function BlockSyncs(pid, callback)
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "on")
        end
    end
    util.yield(10)
    callback()
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "off")
        end
    end
end

local All_business_properties = {
    -- Clubhouses
    "罗伊洛文斯坦大道 1334 号",
    "佩罗海滩 7 号",
    "艾尔金大街 75 号",
    "68 号公路 101 号",
    "佩立托大道 1 号",
    "阿尔冈琴大道 47 号",
    "资本大道 137 号",
    "克林顿大街 2214 号",
    "霍伊克大街 1778 号",
    "东约书亚路 2111 号",
    "佩立托大道 68 号",
    "戈马街 4 号",
    -- 设施
    "塞诺拉大沙漠设施",
    "68 号公路设施",
    "沙滩海岸设施",
    "戈多山设施",
    "佩立托湾设施",
    "桑库多湖设施",
    "桑库多河设施",
    "荣恩风力发电场设施",
    "兰艾水库设施",
    -- 游戏厅
    "像素彼得 - 佩立托湾",
    "奇迹神所 - 葡萄籽",
    "仓库 - 戴维斯",
    "八位元 - 好麦坞",
    "请投币 - 罗克福德山",
    "游戏末日 - 梅萨",
}
local small_warehouses = {
    [1] = "太平洋鱼饵仓储", 
    [2] = "白寡妇车库", 
    [3] = "赛尔托瓦单元", 
    [4] = "便利店车库", 
    [5] = "法拍车库", 
    [9] = "码头 400 号工作仓库", 
}

local medium_warehouses = {
    [7] = "翘臀内衣外景场地", 
    [10] = "GEE 仓库", 
    [11] = "洛圣都海事大厦 3 号楼", 
    [12] = "火车站仓库", 
    [13] = "透心凉辅楼仓库",
    [14] = "废弃的工厂直销店", 
    [15] = "折扣零售商店", 
    [21] = "旧发电站", 
}

local large_warehouses = {
    [6] = "希罗汽油工厂",  
    [8] = "贝尔吉科仓库", 
    [16] = "物流仓库", 
    [17] = "达内尔兄弟仓库", 
    [18] = "家具批发市场", 
    [19] = "柏树仓库", 
    [20] = "西好麦坞外景场地", 
    [22] = "沃克父子仓库"
}


local weapon_stuff = {
    {"烟花", "weapon_firework"}, 
    {"原子能枪", "weapon_raypistol"},
    {"邪恶冥王", "weapon_raycarbine"},
    {"电磁步枪", "weapon_railgun"},
    {"红色激光", "vehicle_weapon_enemy_laser"},
    {"绿色激光", "vehicle_weapon_player_laser"},
    {"天煞机炮", "vehicle_weapon_player_lazer"},
    {"火箭炮", "weapon_rpg"},
    {"制导火箭发射器", "weapon_hominglauncher"},
    {"紧凑型电磁脉冲发射器", "weapon_emplauncher"},
    {"信号弹", "weapon_flaregun"},
    {"霰弹枪", "weapon_bullpupshotgun"},
    {"电击枪", "weapon_stungun"},
    {"催泪瓦斯", "weapon_smokegrenade"},
}

local proofs = {
    bullet = {name="子弹",on=false},
    fire = {name="火烧",on=false},
    explosion = {name="爆炸",on=false},
    collision = {name="撞击",on=false},
    melee = {name="近战",on=false},
    steam = {name="蒸汽",on=false},
    drown = {name="溺水",on=false},
}


local visual_stuff = {
    {"提升亮度", "AmbientPush"},
    {"提升饱和度", "rply_saturation"},
    {"提升曝光度", "LostTimeFlash"},
    {"雾之夜", "casino_main_floor_heist"},
    {"正常雾天", "Forest"},
    {"大雾天", "nervousRON_fog"},
    {"黄昏天", "MP_Arena_theme_evening"},
    {"暖色调", "mp_bkr_int01_garage"},
    {"死气沉沉", "MP_deathfail_night"},
    {"石化", "stoned"},
    {"水下", "underwater"},
}

local modded_vehicles = {
    "dune2",
    "tractor",
    "dilettante2",
    "asea2",
    "cutter",
    "mesa2",
    "jet",
    "policeold1",
    "policeold2",
    "armytrailer2",
    "towtruck",
    "towtruck2",
    "cargoplane",
}

local modded_weapons = {
    "weapon_railgun",
    "weapon_stungun",
    "weapon_digiscanner",
}

local doors = {
    "v_ilev_ta_door",
    "v_ilev_247door",
    "v_ilev_247door_r",
    "v_ilev_lostdoor",
    "v_ilev_bs_door",
    "v_ilev_cs_door01",
    "v_ilev_cs_door01_r",
    "v_ilev_gc_door03",
    "v_ilev_gc_door04",
    "v_ilev_clothmiddoor",
    "v_ilev_clothmiddoor"
}

local interiors = {
    {"安全空间 [挂机室]", {x=-158.71494, y=-982.75885, z=149.13135}},
    {"酷刑室", {x=147.170, y=-2201.804, z=4.688}},
    {"矿道", {x=-595.48505, y=2086.4502, z=131.38136}},
    {"欧米茄车库", {x=2330.2573, y=2572.3005, z=46.679367}},
    {"50车位车库", {x=520.0, y=-2625.0, z=-50.0}},
    {"服务器机房", {x=2474.0847, y=-332.58887, z=92.9927}},
    {"角色捏脸房间", {x=402.91586, y=-998.5701, z=-99.004074}},
    {"Lifeinvader 大楼", {x=-1082.8595, y=-254.774, z=37.763317}},
    {"竞速结束车库", {x=405.9228, y=-954.1149, z=-99.6627}},
    {"被摧毁的医院", {x=304.03894, y=-590.3037, z=43.291893}},
    {"花园银行体育场", {x=-256.92334, y=-2024.9717, z=30.145584}},
    {"Split Sides 喜剧俱乐部", {x=-430.00974, y=261.3437, z=83.00648}},
    {"录音 A 工作室", {x=-1010.6883, y=-49.127754, z=-99.40313}},
    {"巴哈马酒吧", {x=-1394.8816, y=-599.7526, z=30.319544}},
    {"看门人之家", {x=-110.20285, y=-8.6156025, z=70.51957}},
    {"费蓝德医生之家", {x=-1913.8342, y=-574.5799, z=11.435149}},
    {"杜根房子", {x=1395.2512, y=1141.6833, z=114.63437}},
    {"弗洛伊德公寓", {x=-1156.5099, y=-1519.0894, z=10.632717}},
    {"麦克家", {x=-813.8814, y=179.07889, z=72.15914}},
    {"富兰克林家（旧）", {x=-14.239959, y=-1439.6913, z=31.101551}},
    {"富兰克林家（新）", {x=7.3125067, y=537.3615, z=176.02803}},
    {"崔佛家", {x=1974.1617, y=3819.032, z=33.436287}},
    {"莱斯斯家", {x=1273.898, y=-1719.304, z=54.771}},
    {"莱斯特的纺织厂", {x=713.5684, y=-963.64795, z=30.39534}},
    {"莱斯特的纺织厂办事处", {x=707.2138, y=-965.5549, z=30.412853}},
    {"冰毒实验室", {x=1391.773, y=3608.716, z=38.942}},
    {"致幻剂实验室", {x=484.69, y=-2625.36, z=-49}},
    {"停尸房实验室", {x=495.0, y=-2560.0, z=-50.0}},
    {"人道实验室", {x=3625.743, y=3743.653, z=28.69009}},
    {"汽车旅馆客房", {x=152.2605, y=-1004.471, z=-99.024}},
    {"警察局", {x=443.4068, y=-983.256, z=30.689589}},
    {"太平洋标准银行金库", {x=263.39627, y=214.39891, z=101.68336}},
    {"布莱恩郡银行", {x=-109.77874, y=6464.8945, z=31.626724}}, -- credit to fluidware for telling me about this one
    {"龙舌兰酒吧", {x=-564.4645, y=275.5777, z=83.074585}},
    {"废料厂车库", {x=485.46396, y=-1315.0614, z=29.2141}},
    {"失落摩托帮", {x=980.8098, y=-101.96038, z=74.84504}},
    {"范吉利克珠宝店", {x=-629.9367, y=-236.41296, z=38.057056}},
    {"机场休息室", {x=-913.8656, y=-2527.106, z=36.331566}},
    {"停尸房", {x=240.94368, y=-1379.0645, z=33.74177}},
    {"联盟保存处", {x=1.298771, y=-700.96967, z=16.131021}},
    {"军事基地瞭望塔", {x=-2357.9187, y=3249.689, z=101.45073}},
    {"事务所内部", {x=-1118.0181, y=-77.93254, z=-98.99977}},
    {"事务所车库", {x=-1071.0494, y=-71.898506, z=-94.59982}},
    {"恐霸内部", {x=-1421.015, y=-3012.587, z=-80.000}},
    {"地堡内部", {x=899.5518,y=-3246.038, z=-98.04907}},
    {"IAA 办公室", {x=128.20, y=-617.39, z=206.04}},
    {"FIB 顶层", {x=135.94359, y=-749.4102, z=258.152}},
    {"FIB 47层", {x=134.5835, y=-766.486, z=234.152}},
    {"FIB 49层", {x=134.635, y=-765.831, z=242.152}},
    {"大公鸡", {x=-31.007448, y=6317.047, z=40.04039}},
    {"脱衣舞俱乐部DJ位置", {x=121.398254, y=-1281.0024, z=29.480522}},
}

local station_name = {
    ["布莱恩郡之声"] = "RADIO_11_TALK_02", 
    ["蓝色方舟"] = "RADIO_12_REGGAE",
    ["全球电台"] = "RADIO_13_JAZZ",
    ["飞莲电台"] = "RADIO_14_DANCE_02",
    ["真相 91.1"] = "RADIO_15_MOTOWN",
    ["实验室电台"] = "RADIO_20_THELAB",
    ["明镜公园之音"] = "RADIO_16_SILVERLAKE",
    ["103.2 空间"] = "RADIO_17_FUNK",
    ["好麦坞大道电台"] = "RADIO_18_90S_ROCK",
    ["金发洛圣都 97.8 电台"] = "RADIO_21_DLC_XM17",
    ["洛圣都地下电台"] = "RADIO_22_DLC_BATTLE_MIX1_RADIO",
    ["iFruit 电台"] = "RADIO_23_DLC_XM19_RADIO",
    ["自电台(如果该玩家没有设置自电台,将自动切换为 MOTOMAMI 洛圣都电台)"] = "RADIO_19_USER",
    ["洛圣都摇滚台"] = "RADIO_01_CLASS_ROCK",
    ["无止境流行乐电台"] = "RADIO_02_POP",
    ["洛圣都广播电台"] = "RADIO_03_HIPHOP_NEW",
    ["X 频道"] = "RADIO_04_PUNK",
    ["西海岸谈话电台"] = "RADIO_05_TALK_01",
    ["叛逆电台"] = "RADIO_06_COUNTRY", 
    ["灵魂之蜡电台"] = "RADIO_07_DANCE_01",
    ["东洛电台"] = "RADIO_08_MEXICAN",
    ["西海岸经典"] = "RADIO_09_HIPHOP_OLD",
    ["媒体播放器"] = "RADIO_36_AUDIOPLAYER",
    ["音乐柜"] = "RADIO_35_DLC_HEI4_MLR",
    ["库尔特 FM"] = "RADIO_34_DLC_HEI4_KULT",
    ["放松依旧洛圣都"] = "RADIO_27_DLC_PRHEI4",
}

local values = {
    [0] = 0,
    [1] = 50,
    [2] = 88,
    [3] = 160,
    [4] = 208,
}

local unreleased_vehicles = {
    "virtue",
    "powersurge",
    "broadway",
    "panthere",
    "issi8",
    "everon2",
    "eudora",
    "boor"
}

local launch_vehicle = {"向上", "向前", "向后", "向下", "翻滚"}
local invites = {"游艇", "办公室", "会所", "办公室车库", "载具改装铺", "公寓"}
local style_names = {"正常", "半冲刺", "反向", "无视红绿灯", "避开交通", "极度避开交通", "有时超车"}
local drivingStyles = {786603, 1074528293, 8388614, 1076, 2883621, 786468, 262144, 786469, 512, 5, 6}
local interior_stuff = {0, 233985, 169473, 169729, 169985, 170241, 177665, 177409, 185089, 184833, 184577, 163585, 167425, 167169}
local stinkers = {0x1394640, 0xCB7CFF2, 0x4A5C95B, 0xC76C9E2, 0xB7EC980, 0xC121CAD, 0x919B57F, 0xC682AB5, 0x3280B78, 0xC2590C9, 0xBB6BAE6, 0xA1FA84B, 0x101D84E, 0xCA6E931, 0x691AC07, 0xAA87C21, 0x988DB36, 0x6AE10E2, 0x71D0AF9, 0xB93038B}

local self = menu.list(menu.my_root(), "自我选项", {}, "")
local players_list = menu.list(menu.my_root(), "玩家选项", {}, "")
local session = menu.list(menu.my_root(), "聊天选项", {}, "")
local vehicles = menu.list(menu.my_root(), "载具选项", {}, "")
local missions = menu.list(menu.my_root(), "任务选项", {}, "")
local weapons = menu.list(menu.my_root(), "武器选项", {}, "")
local visuals = menu.list(menu.my_root(), "视觉效果", {}, "")
local funfeatures = menu.list(menu.my_root(), "娱乐功能", {}, "")
local teleport = menu.list(menu.my_root(), "传送选项", {}, "")
local detections = menu.list(menu.my_root(), "作弊检测", {}, "")
local bailOnAdminJoin = false
local protections = menu.list(menu.my_root(), "保护选项", {}, "")
menu.toggle(protections, "R*开发人员加入反应", {}, "", function(on)
    bailOnAdminJoin = on
end)

local int_min = -2147483647
local int_max = 2147483647

local menus = {}
local function player_list(pid)
    if NETWORK.NETWORK_IS_SESSION_ACTIVE()then 
        menus[pid] = menu.list(players_list, players.get_name(pid), {}, "", function()
            menu.trigger_commands("jinxscript " .. players.get_name(pid))
        end)
    end
end

local function handle_player_list(pid) -- thanks to dangerman and aaron for showing me how to delete players properly
    local ref = menus[pid]
    if not players.exists(pid) then
        if ref then
            menu.delete(ref)
            menus[pid] = nil
        end
    end
end

players.on_join(player_list)
players.on_leave(handle_player_list)

util.toast("坏b< " .. SOCIALCLUB.SC_ACCOUNT_INFO_GET_NICKNAME() .. " >欢迎使用JinxScript!\n" .. "官方Discord: https://discord.gg/hjs5S93kQv \n中文QQ交流群: 296512882") 
local function player(pid) 
    for _, rid in ipairs (stinkers) do
            if players.get_rockstar_id(pid) == rid and get_spawn_state(pid) ~= 0 then 
            menu.trigger_commands("kick " .. players.get_name(pid))
        end
    end

    if pid ~= players.user() and players.get_rockstar_id(pid) == 0xCB2A48C then
        util.toast(lang.get_string(0xD251C4AA, lang.get_current()):gsub("{(.-)}", {player = players.get_name(pid), reason = "JinxScript 开发者 \n(有可能是虚假ID,小心!)"}), TOAST_DEFAULT)
    end

    if pid ~= players.user() and players.get_rockstar_id(pid) == 0xAE8F8C2 then
        util.toast(lang.get_string(0xD251C4AA, lang.get_current()):gsub("{(.-)}", {player = players.get_name(pid), reason = "Based Gigachad\n(它们非常有实力! 谨慎行事!)"}), TOAST_DEFAULT)
    end

    menu.divider(menu.player_root(pid), "Jinx Script")
    local bozo = menu.list(menu.player_root(pid), "Jinx Script", {"JinxScript"}, "\n* 点击打开尊贵的Jinx脚本玩家选项\n* 免费的大爹级原创综合开源脚本\n* 作者: Prisuhm\n")

    local friendly = menu.list(bozo, "友好", {}, "")
    menu.action(friendly, "给他/她升级", {}, "给予该玩家17万RP经验,可从1级提升至25级.\n一名玩家只能用一次嗷", function()
        util.trigger_script_event(1 << pid, {697566862, pid, 5, 0, 1, 1, 1})
        for i = 0, 9 do
            util.trigger_script_event(1 << pid, {697566862, pid, 0, i, 1, 1, 1})
            util.trigger_script_event(1 << pid, {697566862, pid, 1, i, 1, 1, 1})
            util.trigger_script_event(1 << pid, {697566862, pid, 2, i, 1, 1, 1})
            util.trigger_script_event(1 << pid, {697566862, pid, 10, i, 1, 1, 1})
        end
        for i = 0, 1 do
            util.trigger_script_event(1 << pid, {697566862, pid, 2, i, 1, 1, 1})
            util.trigger_script_event(1 << pid, {697566862, pid, 6, i, 1, 1, 1})
        end
        for i = 0, 19 do
            util.trigger_script_event(1 << pid, {697566862, pid, 4, i, 1, 1, 1})
        end
        for i = 0, 99 do
            util.trigger_script_event(1 << pid, {697566862, pid, 9, i, 1, 1, 1})
            util.yield()
        end
    end)

    local rpwarning
     rpwarning = menu.action(friendly, "循环给予经验收藏品", {}, "循环收藏品功能,不要用在绿玩身上.", function(click_type)
        menu.show_warning(rpwarning, click_type, "警告:这可能会导致封禁,后果自负.", function()
            local rp_loop = menu.list(friendly, "循环给予收藏品", {}, "")
            menu.delete(rpwarning)
            local rp_delay = 500
            menu.slider(rp_loop, "延迟", {"givedelay"}, "", 0, 2500, 500, 10, function(amount)
                rp_delay = amount
            end)

            menu.toggle_loop(rp_loop, "启用循环", {}, "每个收藏品会给玩家1000RP经验.", function()
                util.trigger_script_event(1 << pid, {697566862, pid, 4, -1, 1, 1, 1})
                util.yield(rp_delay)
            end)
            menu.trigger_command(rp_loop)
        end)
    end)

    local player_jinx_army = {}
    local army_player = menu.list(friendly, "宠物猫Jinx军队", {}, "整点小猫哄着你玩玩?\n删不掉的时候觉得烦的话换战局\n能少生成就少生成吧")
    menu.click_slider(army_player, "生成宠物猫Jinx军队", {}, "", 1, 256, 30, 1, function(val)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        pos.y = pos.y - 5
        pos.z = pos.z + 1
        local jinx = util.joaat("a_c_cat_01")
        request_model(jinx)
        for i = 1, val do
            player_jinx_army[i] = entities.create_ped(28, jinx, pos, 0)
            ENTITY.SET_ENTITY_INVINCIBLE(player_jinx_army[i], true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(player_jinx_army[i], true)
            PED.SET_PED_COMPONENT_VARIATION(player_jinx_army[i], 0, 0, 1, 0)
            TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(player_jinx_army[i], ped, 0, -0.3, 0, 7.0, -1, 10, true)
            util.yield()
        end 
    end)

    menu.action(army_player, "清除Jinx宠物猫", {}, "有几只清不掉的时候你就傻了 嘿嘿\n追着你喵喵叫 嘿嘿", function()
        for i, ped in ipairs(entities.get_all_peds_as_handles()) do
            if PED.IS_PED_MODEL(ped, util.joaat("a_c_cat_01")) then
                entities.delete_by_handle(ped)
            end
        end
    end)

    local trolling = menu.list(bozo, "恶搞选项", {}, "")
    
    local radio = menu.list(trolling, "更换广播电台", {}, "")
    local stations = {}
    for station, name in pairs(station_name) do
        stations[#stations + 1] = station
    end
    menu.list_action(radio, "广播电台", {}, "", stations, function(index, value)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = players.get_position(players.user())
        local player_veh = PED.GET_VEHICLE_PED_IS_IN(ped)

        if not PED.IS_PED_IN_VEHICLE(ped, player_veh, false) then
            util.toast("玩家不在载具中. :/")
        return end
        local radio_name = station_name[value]
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then 

            if not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
                util.toast("未能成功更换玩家电台. :/")
            return end

            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(player_veh)
            if not PED.IS_PED_IN_VEHICLE(players.user_ped(), player_veh, false) then
                ENTITY.SET_ENTITY_VISIBLE(players.user_ped(), false)
                menu.trigger_commands("tpveh" .. players.get_name(pid))
                util.yield(250)
                AUDIO.SET_VEH_RADIO_STATION(player_veh, radio_name)
                util.yield(750)
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(players.user_ped(), pos, false, false, false)
            else
                util.yield(250)
                AUDIO.SET_VEH_RADIO_STATION(player_veh, radio_name)
            end
        end
    end)

    control_veh = player_toggle_loop(trolling, pid, "控制玩家载具", {}, "必须在陆地上的载具才能使用该功能.", function(toggle)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player_veh = PED.GET_VEHICLE_PED_IS_IN(ped)
        local class = VEHICLE.GET_VEHICLE_CLASS(player_veh)
        if not players.exists(pid) then util.stop_thread() end

        if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(pid)) > 1000.0 
        and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
            util.toast("离得太远了. :/")
            menu.set_value(control_veh, false)
        return end

        if class == 15 then
            util.toast("玩家在直升机上 :/")
            menu.set_value(control_veh, false)
        return end
        
        if class == 16 then
            util.toast("玩家在飞机上. :/")
            menu.set_value(control_veh, false)
        return end

        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            if PAD.IS_CONTROL_PRESSED(0, 34) then
                while not PAD.IS_CONTROL_RELEASED(0, 34) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 7, 100)
                    util.yield()
                end
            elseif PAD.IS_CONTROL_PRESSED(0, 35) then
                while not PAD.IS_CONTROL_RELEASED(0, 35) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 8, 100)
                    util.yield()
                end
            elseif PAD.IS_CONTROL_PRESSED(0, 32) then
                while not PAD.IS_CONTROL_RELEASED(0, 32) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 23, 100)
                    util.yield()
                end
            elseif PAD.IS_CONTROL_PRESSED(0, 33) then
                while not PAD.IS_CONTROL_RELEASED(0, 33) do
                    TASK.TASK_VEHICLE_TEMP_ACTION(ped, PED.GET_VEHICLE_PED_IS_IN(ped), 28, 100)
                    util.yield()
                end
            end
        else
            util.toast("玩家不在载具中. :/")
            menu.set_value(control_veh, false)
        end
        util.yield()
        
    end)
    menu.action(trolling, "弹射玩家", {}, "警告:这可能会导致崩溃出现,但概率极低.主要是由于垃圾邮件,所以请不要乱扔垃圾.", function()																																																	   
        local mdl = util.joaat("boxville3")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(mdl)
                    
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            util.toast("玩家在载具中. :/")
        return end
        
        if TASK.IS_PED_WALKING(ped) then
            boxville = entities.create_vehicle(mdl, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 2.0, 0.0), ENTITY.GET_ENTITY_HEADING(ped))
            ENTITY.SET_ENTITY_VISIBLE(boxville, false)
            util.yield(250)
            local force
            repeat
                if boxville ~= 0 and ENTITY.DOES_ENTITY_EXIST(boxville)then
                    ENTITY.APPLY_FORCE_TO_ENTITY(boxville, 1, 0.0, 0.0, 25.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
                end
                util.yield()
                pos = ENTITY.GET_ENTITY_COORDS(ped)
            until pos.z > 10000.0
            util.yield(100)
            if boxville ~= 0 and ENTITY.DOES_ENTITY_EXIST(boxville) then 
                entities.delete_by_handle(boxville)
            end
        else
            util.toast("玩家必须在行走时才能发挥作用. :/")
        end
    end)

    menu.action_slider(trolling, "发射玩家载具", {"launchvehicle"}, "已被大部分菜单阻挡.", launch_vehicle, function(index, value)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            util.toast("玩家不在载具中. :/")
            return
        end

        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            util.yield()
        end

        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
            util.toast("未能获得对载具的控制权\n可能是作弊者开启了防护 :/")
            return
        end

        switch value do
            case "Launch Up":
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0.0, 100000.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
                break
            case "Launch Forward":
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 100000.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
                break
            case "Launch Backwards":
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, -100000.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
                break
            case "Launch Down":
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0.0, -100000.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
                break
            case "Slingshot":
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0.0, 100000.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 100000.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
                break
            end
        end)
     
    menu.click_slider(trolling, "虚假抢钱", {}, "", 0, 2147483647, 0, 1000, function(amount)
        util.trigger_script_event(1 << pid, {548471420, players.user(), 532932991, amount, 0, 0, 0, 0, 0, 0, pid, players.user(), 0, 0})
        util.trigger_script_event(1 << players.user(), {548471420, players.user(), 532932991, amount, 0, 0, 0, 0, 0, 0, pid, players.user(), 0, 0})
    end)

    player_toggle_loop(trolling, pid, "电死这个杂种", {tase}, "来自雷电法王杨永信的电疗\n拯救网瘾少年的任务就交给你了", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        for i = 1, 50 do
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 1, pos.x, pos.y, pos.z, 0, true, util.joaat("weapon_stungun"), players.user_ped(), false, true, 1.0)
        end
        util.yield()
    end)
    
    local griefing = menu.list(bozo, "坏逼选项", {}, "你是个坏b,你不干净了。")
    local glitch_player_list = menu.list(griefing, "鬼畜玩家", {"glitchdelay"}, "")
    local object_stuff = {
        names = {
            "摩天轮",
            "UFO",
            "水泥搅拌车",
            "脚手架",
            "车库门",
            "保龄球",
            "足球",
            "橘子",
            "特技坡道",

        },
        objects = {
            "prop_ld_ferris_wheel",
            "p_spinning_anus_s",
            "prop_staticmixer_01",
            "prop_towercrane_02a",
            "des_scaffolding_root",
            "prop_sm1_11_garaged",
            "stt_prop_stunt_bowling_ball",
            "stt_prop_stunt_soccer_ball",
            "prop_juicestand",
            "stt_prop_stunt_jump_l",
        }
    }

    local object_hash = util.joaat("prop_ld_ferris_wheel")
    menu.list_select(glitch_player_list, "物体", {"glitchplayer"}, "选择鬼畜玩家使用的物体.", object_stuff.names, 1, function(index)
        object_hash = util.joaat(object_stuff.objects[index])
    end)

    menu.slider(glitch_player_list, "物体生成延迟", {"spawndelay"}, "", 150, 3000, 150, 10, function(amount)
        delay = amount
    end)

    local glitchPlayer
    glitchPlayer = player_toggle_loop(glitch_player_list, pid, "鬼畜玩家", {"glitchplayer"}, "被具有实体垃圾邮件保护功能的菜单所阻止.", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        if not players.exists(pid) then 
            util.toast("玩家不存在. :/")
            menu.set_value(glitchPlayer_toggle, false)
        util.stop_thread() end

        if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(pid)) > 1000.0 
        and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
            util.toast("玩家离得太远. :/")
            menu.set_value(glitchPlayer_toggle, false)
        return end

        local glitch_hash = object_hash
        local poopy_butt = util.joaat("rallytruck")
        request_model(glitch_hash)
        request_model(poopy_butt)
        local stupid_object = entities.create_object(glitch_hash, pos)
        local glitch_vehicle = entities.create_vehicle(poopy_butt, pos, 0)
        ENTITY.SET_ENTITY_VISIBLE(stupid_object, false)
        ENTITY.SET_ENTITY_VISIBLE(glitch_vehicle, false)
        ENTITY.SET_ENTITY_INVINCIBLE(stupid_object, true)
        ENTITY.SET_ENTITY_COLLISION(stupid_object, true, true)
        ENTITY.APPLY_FORCE_TO_ENTITY(glitch_vehicle, 1, 0.0, 10, 10, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
        util.yield(delay)
        entities.delete_by_handle(stupid_object)
        entities.delete_by_handle(glitch_vehicle)
        util.yield(delay)     
    end)

    local glitchVehCmd
    glitchVehCmd = player_toggle_loop(griefing, pid, "鬼畜载具", {"glitchvehicle"}, "在所有的菜单上都能工作,并且不会被检测.", function() -- credits to soul reaper for base concept
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
        local veh_model = players.get_vehicle_model(pid)
        local ped_hash = util.joaat("a_m_m_acult_01")
        local object_hash = util.joaat("prop_ld_ferris_wheel")
        request_model(ped_hash)
        request_model(object_hash)
        
        if not players.exists(pid) then 
            util.toast("玩家不存在. :/")
            menu.set_value(glitchPlayer_toggle, false)
        util.stop_thread() end

        if not PED.IS_PED_IN_VEHICLE(ped, player_veh, false) then 
            util.toast("玩家不在车内. :/")
            menu.set_value(glitchVehCmd, false)
        return end

        if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(pid)) > 1000.0 
        and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
            util.toast("玩家离得太远. :/")
            menu.set_value(glitchVehCmd, false)
        return end

        if not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
            util.toast("没有座位了. :/")
            menu.set_value(glitchVehCmd, false)
        return end

        local seat_count = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(veh_model)
        local glitch_obj = entities.create_object(object_hash, pos)
        local glitched_ped = entities.create_ped(26, ped_hash, pos, 0)
        local things = {glitched_ped, glitch_obj}
        
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(glitch_obj)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(glitched_ped)

        ENTITY.ATTACH_ENTITY_TO_ENTITY(glitch_obj, glitched_ped, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)

        for i, spawned_objects in ipairs(things) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(spawned_objects)
            ENTITY.SET_ENTITY_VISIBLE(spawned_objects, false)
            ENTITY.SET_ENTITY_INVINCIBLE(spawned_objects, true)
        end

        for i = 0, seat_count -1 do
            if VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(player_veh) then
                local emptyseat = i
                for l = 1, 25 do
                    PED.SET_PED_INTO_VEHICLE(glitched_ped, player_veh, emptyseat)
                    ENTITY.SET_ENTITY_COLLISION(glitch_obj, true, true)
                    util.yield()
                end
            end
        end
        if glitched_ped ~= nil then
            entities.delete_by_handle(glitched_ped) 
        end
        if glitch_obj ~= nil then 
            entities.delete_by_handle(glitch_obj)
        end
    end)

    local glitchforcefield
    glitchforcefield = player_toggle_loop(griefing, pid, "大范围力场", {"forcefield"}, "被具有实体垃圾邮件保护功能的菜单所阻止.", function()
        local glitch_hash = util.joaat("p_spinning_anus_s")
        request_model(glitch_hash)

        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        
        if not players.exists(pid) then 
            util.toast("玩家并不存在. :/")
            menu.set_value(glitchPlayer_toggle, false)
        util.stop_thread() end

        if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(pid)) > 1000.0 
        and v3.distance(pos, players.get_cam_pos(players.user())) > 1000.0 then
            util.toast("玩家离得太远. :/")
            menu.set_value(glitchPlayer, false)
        return end

        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            util.toast("玩家在载具里. :/")
            menu.set_value(glitchforcefield, false)
        return end

        local stupid_object = entities.create_object(glitch_hash, pos)
        ENTITY.SET_ENTITY_VISIBLE(stupid_object, false)
        util.yield()
        entities.delete_by_handle(stupid_object)
        util.yield()    
    end)

    local gravity = menu.list(griefing, "重力玩家", {}, "在所有菜单上都能使用,但可以被检测到,对开启无敌的玩家失效.") -- hi 2t1 luatards
    local force = 1.00
    menu.slider_float(gravity, "重力倍数", {"force"}, "", 0, 100, 100, 10, function(value)
        force = value / 100
    end)

    local gravitate
    gravitate = player_toggle_loop(gravity, pid, "开启重力", {"gravitate"}, "", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local player_veh = PED.GET_VEHICLE_PED_IS_IN(ped)

        if not players.exists(pid) then 
            util.toast("玩家并不存在. :/")
            menu.set_value(glitchPlayer_toggle, false)
        util.stop_thread() end

        for i, interior in ipairs(interior_stuff) do
            if players.is_godmode(pid) and (not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped)) and get_spawn_state(pid) ~= 0 and get_interior_player_is_in(pid) == interior then
                util.toast("玩家处于无敌模式. :/")
                menu.set_value(gravitate, false)
            return end
        end

        FIRE.ADD_EXPLOSION(players.get_position(pid), 29, force, false, true, 0.0, true)
    end)

    menu.action(griefing, "布娃娃", {"ragdoll"}, "", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local player_veh = PED.GET_VEHICLE_PED_IS_IN(ped)

        if not players.exists(pid) then 
            util.toast("玩家不存在. :/")
            menu.set_value(glitchPlayer_toggle, false)
        util.stop_thread() end

        for _, id in ipairs(interior_stuff) do
            if players.is_godmode(pid) and (not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped)) and get_spawn_state(pid) ~= 0 and get_interior_player_is_in(pid) == id then
                util.toast("玩家是无敌模式. :/")
                menu.set_value(gravitate, false)
            return end
        end

        FIRE.ADD_EXPLOSION(players.get_position(pid), 29, 0.60, false, true, 0.0, true)
    end)

    menu.action(griefing,  "踢出室内", {}, "强制将玩家踢出室内.", function() -- very innovative!
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local glitch_hash = util.joaat("p_spinning_anus_s")
        local poopy_butt = util.joaat("brickade2")
        request_model(glitch_hash)
        request_model(poopy_butt)
        for _, id in ipairs(interior_stuff) do
            if get_interior_player_is_in(pid) == id then
                util.toast("玩家不在室内. :/")
            return end
        end
        for i = 1, 5 do
            local stupid_object = entities.create_object(glitch_hash, pos)
            local glitch_vehicle = entities.create_vehicle(poopy_butt, pos, 0)
            ENTITY.SET_ENTITY_VISIBLE(stupid_object, false)
            ENTITY.SET_ENTITY_VISIBLE(glitch_vehicle, false)
            ENTITY.SET_ENTITY_INVINCIBLE(glitch_vehicle, true)
            ENTITY.SET_ENTITY_COLLISION(stupid_object, true, true)
            ENTITY.APPLY_FORCE_TO_ENTITY(glitch_vehicle, 1, 0.0, 10, 10, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
            util.yield(500)
            entities.delete_by_handle(stupid_object)
            entities.delete_by_handle(glitch_vehicle)
            util.yield(500)     
        end
    end)
    

    local freeze = menu.list(griefing, "冻结", {}, "冻住之后想想办法干他屁眼")															   
    player_toggle_loop(freeze, pid, "暴力冻结", {}, "", function()
        util.trigger_script_event(1 << pid, {-93722397, pid, 0, 0, 0, 0, 0})
        util.yield(500)
    end)

    player_toggle_loop(freeze, pid, "仓库冻结", {}, "", function()
        util.trigger_script_event(1 << pid, {434937615, pid, 0, 1, 0, 0})
        util.yield(500)
    end)

    player_toggle_loop(freeze, pid, "模型冻结", {}, "基础冻结方式,已被大部分菜单阻挡.", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    end)
    
    local inf_loading = menu.list(griefing, "无限加载屏幕", {}, "\n你可真不是个人\n禁止使用该功能欺负绿玩\n我觉得你可以尝试使用《绿玩保护崩溃》\n")
    menu.action(inf_loading, "传送邀请", {}, "已被大部分菜单阻挡.", function()
        util.trigger_script_event(1 << pid, {879177392, pid, 0, 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    end)

    menu.action(inf_loading, "公寓邀请", {}, "已被大部分菜单阻挡.", function()
        util.trigger_script_event(1 << pid, {434937615, pid, 0, 1, id})
    end)
        
    menu.action_slider(inf_loading, "资产邀请", {}, "单击以选择样式", invites, function(index, name)
        switch name do
            case "Yacht":
                util.trigger_script_event(1 << pid, {-1891171016, pid, 1})
                util.toast("游艇邀请已发送")
            break
            case "Office":
                util.trigger_script_event(1 << pid, {-1891171016, pid, 2})
                util.toast("办公室邀请已发送")
            break
            case "Clubhouse":
                util.trigger_script_event(1 << pid, {-1891171016, pid, 3})
                util.toast("会所邀请已发送")
            break
            case "Office Garage":
                util.trigger_script_event(1 << pid, {-1891171016, pid, 4})
                util.toast("办公室车库邀请已发送")
            break
            case "Custom Auto Shop":
                util.trigger_script_event(1 << pid, {-1891171016, pid, 5})
                util.toast("载具改装铺邀请已发送")
            break
            case "Apartment":
                util.trigger_script_event(1 << pid, {-1891171016, pid, 6})
                util.toast("公寓邀请已发送")
            break
        end
    end)

        
    player_toggle_loop(griefing, pid, "使该玩家黑屏", {"blackscreen"}, "\n你可真不是个人\n禁止使用该功能欺负绿玩\n我觉得你可以尝试使用《绿玩保护崩溃》\n", function()
        util.trigger_script_event(1 << pid, {879177392, pid, math.random(1, 32), 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
        util.yield(1000)
    end)

    
    local cage = menu.list(griefing, "困住玩家", {}, "")
    menu.action(cage, "电击笼子", {"electriccage"}, "你确定你要当雷电法王杨永信吗?\n做个人吧!", function()
        local number_of_cages = 6
        local elec_box = util.joaat("prop_elecbox_12")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        pos.z -= 0.5
        request_model(elec_box)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(2.5)
            obj_pos:add(pos)
            for offs_z = 1, 5 do
                local electric_cage = entities.create_object(elec_box, obj_pos)
                spawned_objects[#spawned_objects + 1] = electric_cage
                ENTITY.SET_ENTITY_ROTATION(electric_cage, 90.0, 0.0, angle, 2, 0)
                obj_pos.z += 0.75
                ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
            end
        end
    end)

    menu.action(cage, "集装箱笼子", {"containercage"}, "", function()
        local container_hash = util.joaat("prop_container_ld_pu")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        pos.z -= 1
        local container = entities.create_object(container_hash, pos, 0)
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    menu.action(cage, "载具笼子", {"vehiclecage"}, "", function()
        local container_hash = util.joaat("boxville3")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        local container = entities.create_vehicle(container_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 2.0, 0.0), ENTITY.GET_ENTITY_HEADING(ped))
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.SET_ENTITY_VISIBLE(container, false)
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    menu.action(cage, "删除所有生成的笼子", {"clearcages"}, "", function()
        local entitycount = 0
        for i, object in ipairs(spawned_objects) do
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false)
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
            entities.delete_by_handle(object)
            spawned_objects[i] = nil
            entitycount += 1
        end
        util.toast("删除了 " .. entitycount .. "个已生成的笼子")
    end)

    menu.action(griefing, "杀死室内玩家", {}, "这崽种不在公寓里则没法使用\n你可以尝试用公寓邀请给他拉到一个公寓\n再来试试这个功能", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)

        for i, interior in ipairs(interior_stuff) do
            if get_interior_player_is_in(pid) == interior then
                util.toast("这崽种不在家啊,求求你回去看提示:/")
            return end
            if get_interior_player_is_in(pid) ~= interior then
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 1, pos.x, pos.y, pos.z, 1000, true, util.joaat("weapon_stungun"), players.user_ped(), false, true, 1.0)
            end
        end
    end)

    menu.action(griefing, "给这傻逼送进监狱", {"arrest"}, "已被大部分菜单阻挡.", function()
        local my_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
        local my_ped = PLAYER.GET_PLAYER_PED(players.user())
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(my_ped, 1628.5234, 2570.5613, 45.56485, true, false, false, false)
        menu.trigger_commands("givesh " .. players.get_name(pid))
        menu.trigger_commands("summon " .. players.get_name(pid))
        menu.trigger_commands("invisibility on")
        menu.trigger_commands("otr")
        util.yield(5000)
        menu.trigger_commands("invisibility off")
        menu.trigger_commands("otr")
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(my_ped, my_pos)
    end)

    player_toggle_loop(griefing, pid, "声音骚扰", {}, "你真坏\n不过我喜欢", function()
        util.trigger_script_event(1 << pid, {-1891171016, pid, math.random(1, 6)})
        util.yield()
    end)

    menu.action(griefing, "破坏室内状态", {}, "玩家必须在一个公寓内,可通过重新加入战局取消.", function(s)
        if players.is_in_interior(pid) then
            util.trigger_script_event(1 << pid, {2956049686, pid, pid, pid, pid, math.random(int_min, int_max), pid})
        else
            util.toast("玩家不在室内. :/")
        end
    end)

    local antimodder = menu.list(bozo, "反作弊者", {}, "")
    local kill_godmode = menu.list(antimodder, "击杀无敌玩家", {}, "")
    menu.action(kill_godmode, "击杀无敌玩家", {""}, "适用于小菜单", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos.x, pos.y, pos.z + 1, pos.x, pos.y, pos.z, 99999, true, util.joaat("weapon_stungun"), players.user_ped(), false, true, 1.0)
    end)

    menu.slider_text(kill_godmode, "压死无敌玩家", {}, "嘎嘎好用 嘎嘎权威 强烈推荐", {"Khanjali", "APC"}, function(index, veh)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        local vehicle = util.joaat(veh)
        request_model(vehicle)

        switch veh do
            case "Khanjali":
            height = 2.8
            offset = 0
            break
            case "APC":
            height = 3.4
            offset = -1.5
            break
        end

        if TASK.IS_PED_STILL(ped) then
            distance = 0
        elseif not TASK.IS_PED_STILL(ped) then
            distance = 3
        end

        local vehicle1 = entities.create_vehicle(vehicle, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, offset, distance, height), ENTITY.GET_ENTITY_HEADING(ped))
        local vehicle2 = entities.create_vehicle(vehicle, pos, 0)
        local vehicle3 = entities.create_vehicle(vehicle, pos, 0)
        local vehicle4 = entities.create_vehicle(vehicle, pos, 0)
        local spawned_vehs = {vehicle4, vehicle3, vehicle2, vehicle1}
        ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle2, vehicle1, 0, 0, 3, 0, 0, 0, -180, 0, false, true, false, 0, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle3, vehicle1, 0, 3, 3, 0, 0, 0, -180, 0, false, true, false, 0, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle4, vehicle1, 0, 3, 0, 0, 0, 0, 0, 0, false, true, false, 0, true)
        ENTITY.SET_ENTITY_VISIBLE(vehicle1, false)
        util.yield(5000)
        for i = 1, #spawned_vehs do
            entities.delete_by_handle(spawned_vehs[i])
        end
    end)   

    player_toggle_loop(kill_godmode, pid, "炸死无敌玩家", {}, "已被大部分菜单阻挡.", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        if not PED.IS_PED_DEAD_OR_DYING(ped) and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) then
            util.trigger_script_event(1 << pid, {113023613, pid, 1771544554, math.random(0, 9999)})
            FIRE.ADD_OWNED_EXPLOSION(players.user_ped(), pos, 2, 50, true, false, 0.0)
        end
    end)

    player_toggle_loop(antimodder, pid, "移除玩家无敌", {}, "已被大部分菜单阻挡.", function()
        util.trigger_script_event(1 << pid, {113023613, pid, 1771544554, math.random(0, 9999)})
    end)

    player_toggle_loop(antimodder, pid, "移除无敌玩家武器", {}, "已被大部分菜单阻挡.", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(players.user(), ped) and players.is_godmode(pid) then
            util.trigger_script_event(1 << pid, {113023613, pid, 1771544554, math.random(0, 9999)})
        end
    end)

    player_toggle_loop(antimodder, pid, "移除载具无敌", {}, "已被大部分菜单阻挡.", function()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) and not PED.IS_PED_DEAD_OR_DYING(ped) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            ENTITY.SET_ENTITY_CAN_BE_DAMAGED(veh, true)
            ENTITY.SET_ENTITY_INVINCIBLE(veh, false)
            ENTITY.SET_ENTITY_PROOFS(veh, false, false, false, false, false, 0, 0, false)
        end
    end)

    local tp_player = menu.list(bozo, "传送玩家到", {}, "已被大部分菜单阻挡.")
    local clubhouse = menu.list(tp_player, "摩托帮会所", {}, "")
    local facility = menu.list(tp_player, "设施", {}, "")
    local arcade = menu.list(tp_player, "游戏厅", {}, "")
    local warehouse = menu.list(tp_player, "仓库", {}, "")
    local cayoperico = menu.list(tp_player, "佩里科岛", {}, "")
    local interiors = menu.list(tp_player, "室内", {}, "") -- thx to aaron for sending me the labels and their numbers for most of the interiors <3

    for id, name in pairs(All_business_properties) do
        if id <= 12 then
            menu.action(clubhouse, name, {}, "", function()
                util.trigger_script_event(1 << pid, {879177392, pid, id, 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, math.random(1, 10)})
            end)
        elseif id > 12 and id <= 21 then
            menu.action(facility, name, {}, "", function()
                util.trigger_script_event(1 << pid, {879177392, pid, id, 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
            end)
        elseif id > 21 then
            menu.action(arcade, name, {}, "", function() 
                util.trigger_script_event(1 << pid, {879177392, pid, id, 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1})
            end)
        end
    end

    local small = menu.list(warehouse, "小型仓库", {}, "")
    local medium = menu.list(warehouse, "中型仓库", {}, "")
    local large = menu.list(warehouse, "大型仓库", {}, "")

    for id, name in pairs(small_warehouses) do
        menu.action(small, name, {}, "", function()
            util.trigger_script_event(1 << pid, {434937615, pid, 0, 1, id})
        end)
    end

    for id, name in pairs(medium_warehouses) do
        menu.action(medium, name, {}, "", function()
            util.trigger_script_event(1 << pid, {434937615, pid, 0, 1, id})
        end)
    end

    for id, name in pairs(large_warehouses) do
        menu.action(large, name, {}, "", function()
            util.trigger_script_event(1 << pid, {434937615, pid, 0, 1, id})
        end)
    end

    menu.action(tp_player, "公寓邀请", {}, "已被大部分菜单阻挡.", function()
        util.trigger_script_event(1 << pid, {-168599209, players.user(), pid, -1, 1, 1, 0, 1, 0}) 
    end)
	
    menu.action(cayoperico, "佩里科岛(有过场动画)", {"tpcayo"}, "已被大部分菜单阻挡.", function()
        util.trigger_script_event(1 << pid, {-93722397, pid, 0, 0, 3, 1})
    end)

    menu.action(cayoperico, "佩里科岛(无过场动画)", {"tpcayo2"}, "已被大部分菜单阻挡.", function()
        util.trigger_script_event(1 << pid, {-93722397, pid, 0, 0, 4, 1})
    end)

    menu.action(cayoperico, "离开佩里科岛", {"cayoleave"}, "已被大部分菜单阻挡.\n玩家必须在佩里科岛才能触发此事件", function()
        util.trigger_script_event(1 << pid, {-93722397, pid, 0, 0, 3})
    end)

    menu.action(cayoperico, "从佩里科岛踢出", {"cayokick"}, "已被大部分菜单阻挡.", function()
        util.trigger_script_event(1 << pid, {-93722397, pid, 0, 0, 4, 0})
    end)

    local interior_tps = {
        [70] = "地堡", -- 70 thru 80 are bunkers
        [81] = "机动作战中心",
        [83] = "机库", -- 83 thru 87 are hangars
        [88] = "复仇者",
        [89] = "设施", -- 89 thru 97 are facilities
        [102] = "夜总会车库",-- 102 thru 111 are garages
        [117] = "恐霸",
        [122] = "竞技场工作室",
        [123] = "名钻赌场",
        [124] = "顶层公寓",
        [128] = "游戏厅车库", -- 128 thru 133 are garages
        [146] = "夜总会",
        [147] = "虎鲸",
        [149] = "改装铺", -- 149 thru 153 are auto shops
        [155] = "事务所",
    }

    for id, name in pairs(interior_tps) do
        menu.action(interiors, name, {""}, "已被大部分菜单阻挡.", function()
            util.trigger_script_event(1 << pid, {1268038438, pid, id, 1, 0, 1, 1130429716, -1001012850, 1106067788, 0, 0, 1, 2123789977, 1, -1})
        end)
    end

    
    if bailOnAdminJoin then
        if players.is_marked_as_admin(pid) then
            util.toast(players.get_name(pid) .. "这他妈的傻逼是真的R*管理员,哥检测到了,先帮你跑路.")
            menu.trigger_commands("quickbail")
            return
        end
    end
end


players.on_join(player)
players.dispatch_on_join()

local unlocks = menu.list(self, "解锁选项")
menu.toggle_loop(unlocks, "解锁 50 车位车库", {}, "", function()
    if memory.read_byte(memory.script_global(262145 + 32688)) ~= 0 then-- thx aero for this global <3
        memory.write_byte(memory.script_global(262145 + 32688), 0) 
    end

    if memory.read_byte(memory.script_global(262145 + 32702)) ~= 1 then
        memory.write_byte(memory.script_global(262145 + 32702), 1)  
    end
end)

menu.toggle_loop(unlocks, "解锁出租车任务", {}, "", function() -- credit to sapphire for all of this <3
    if memory.read_byte(memory.script_global(262145 + 33770)) ~= 1 then
        memory.write_byte(memory.script_global(262145 + 33770), 1)
    return end
end)

menu.action(unlocks, "解锁洛圣都毒品战 DLC 内容", {}, "", function()
    for i = 33974, 34112, 1 do
        memory.write_byte(memory.script_global(262145 + i), 1)  
    end
end)

menu.action(unlocks, "解锁圣诞和新年礼物", {}, "更改为发放礼物的战局.", function()
    memory.write_byte(memory.script_global(262145 + 33915), 1)  
    memory.write_byte(memory.script_global(262145 + 33916), 1)  
end)

menu.toggle_loop(self, "快速重生", {"fastrespawn"}, "", function()
    local ped_ptr = entities.handle_to_pointer(players.user_ped())
    local gwobaw = memory.script_global(2672505 + 1684 + 756) -- Global_2672505.f_1684.f_756
    if entities.get_health(ped_ptr) < 100 then
        GRAPHICS.ANIMPOSTFX_STOP_ALL()
        memory.write_int(gwobaw, memory.read_int(gwobaw) | 1 << 1)
    end
end,
    function()
    local gwobaw = memory.script_global(2672505 + 1684 + 756)
    memory.write_int(gwobaw, memory.read_int(gwobaw) &~ (1 << 1)) 
end)

local roll_speed = nil
menu.list_select(self, "战斗翻滚速度", {}, "", {"默认", "1.25x", "1.5x", "1.75x", "2x"}, 1, function(index, value)
roll_speed = index
util.create_tick_handler(function()
    switch value do
        case "1.25x":
            STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_SHOOTING_ABILITY"), 115, true)
            break
        case "1.5x":
            STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_SHOOTING_ABILITY"), 125, true)
            break
        case "1.75x":
            STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_SHOOTING_ABILITY"), 135, true)
            break
        case "2x":
            STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_SHOOTING_ABILITY"), 150, true)
            break
        end
        return roll_speed == index
    end)
end)


local climb_speed = nil
menu.list_select(self, "攀爬速度", {}, "", {"默认", "1.25x", "1.5x", "2x",}, 1, function(index, value)
climb_speed = index
util.create_tick_handler(function()
    if TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 1) then
        switch value do
            case "1.25x":
                PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
                util.yield(150)
                break
            case "1.5x":
                PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
                util.yield(75)
                break
            case "2x":
                PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
                util.yield(50)
                break
            end
        end
        return climb_speed == index
    end)
end)

menu.toggle_loop(self, "武装玩家", {"ghostarmedplayers"}, "对手持武器的玩家启用幽灵模式.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if WEAPON.IS_PED_ARMED(ped, 7) or TASK.GET_IS_TASK_ACTIVE(ped, 199) or TASK.GET_IS_TASK_ACTIVE(ped, 128) 
        or IsPlayerUsingGuidedMissile(pid) or IsPlayerInRcTank(pid) or IsPlayerInRcBandito(pid) or IsPlayerFlyingAnyDrone(pid) then
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, true)
        else
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, false)
        end
    end
end, function()
    for _, pid in ipairs(players.list(false, true, true)) do
        NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, false)
    end
end)

local orb = menu.list(self, "反天基炮")
ghost_tgl = menu.toggle_loop(orb, "幽灵模式", {"ghostorb"}, "自动对使用天基炮的玩家开启幽灵模式.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if IsPlayerUsingOrbitalCannon(pid) and TASK.GET_IS_TASK_ACTIVE(ped, 135) 
        and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), cam_pos) > 300 
        and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), cam_pos) < 400 then
            util.toast(players.get_name(pid) .. " 正在用天基炮瞄准你.")
        end
       if IsPlayerUsingOrbitalCannon(pid) then
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, true)
        else
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, false)
        end
    end
end, function()
    for _, pid in ipairs(players.list(false, true, true)) do
        NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, false)
    end
end)

local annoy = menu.list(orb, "防御模式", {}, "快速显示你的名字并将其从使用天基炮的玩家的选择列表中删除.")
local orb_delay = 1000
menu.list_select(annoy, "延迟", {}, "对于使用天基炮玩家来说,你的名字会以何种速度闪动.", {"慢速", "中速", "快速"}, 1, function(index, value)
switch value do
    case "慢速":
        orb_delay = 1000
        break
    case "中速":
        orb_delay = 500
        break
    case "快速":
        orb_delay = 100
        break
    end
end)

local annoy_tgl
annoy_tgl = menu.toggle_loop(annoy, "启用", {}, "", function()
    if menu.get_value(ghost_tgl) then
        menu.set_value(annoy_tgl, false)
        util.toast("请不要同时启用防御模式和幽灵模式 ;)")
    return end
    
    for _, pid in ipairs(players.list(false, true, true)) do
       if IsPlayerUsingOrbitalCannon(pid) then
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, true)
            util.yield(orb_delay)
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, false)
            util.yield(orb_delay)
        else
            NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, false)
        end
    end
end, function()
    for _, pid in ipairs(players.list(false, true, true)) do
        NETWORK.SET_REMOTE_PLAYER_AS_GHOST(pid, false)
    end
end)

menu.toggle_loop(self, "友好的AI", {""}, "AI不会瞄准你.", function()
    PED.SET_PED_RESET_FLAG(players.user_ped(), 124, true)
end)

menu.toggle_loop(self, "自动接受并加入游戏", {}, "将自动接受游戏邀请.", function() -- credits to soulreaper for sending me this :D
    local message_hash = HUD.GET_WARNING_SCREEN_MESSAGE_HASH()
    if message_hash == 15890625 or message_hash == -398982408 or message_hash == -587688989 then
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1.0)
        util.yield(50)
    end
end)

local proofsList = menu.list(self, "伤害免疫", {}, "")
local immortalityCmd = menu.ref_by_path("Self>Immortality")
for _,data in pairs(proofs) do
    menu.toggle(proofsList, data.name, {data.name:lower().."proof"}, "让您免疫"..data.name:lower().."的伤害.", function(toggle)
        data.on = toggle
    end)
end
util.create_tick_handler(function()
    local local_player = players.user_ped()
    if not menu.get_value(immortalityCmd) then
        ENTITY.SET_ENTITY_PROOFS(local_player, proofs.bullet.on, proofs.fire.on, proofs.explosion.on, proofs.collision.on, proofs.melee.on, proofs.steam.on, false, proofs.drown.on)
    end
end)

menu.toggle_loop(missions, "达克斯冷却", {}, "移除达克斯工作的冷却时间", function() -- thx icedoomfist for the state name <3
    STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_XM22JUGGALOWORKCDTIMER"), -1, true)
end)

menu.toggle_loop(missions, "禁用阻止实体轰炸", {}, "将在任务中自动禁用阻止实体轰炸,防止任务卡关.", function()
    local EntitySpam = menu.ref_by_path("Online>Protections>Block Entity Spam>Block Entity Spam")
    if NETWORK.NETWORK_IS_ACTIVITY_SESSION() == true then
        if not menu.get_value(EntitySpam) then return end
        menu.trigger_command(EntitySpam, "off")
    else
        if menu.get_value(EntitySpam) then return end
        menu.trigger_command(EntitySpam, "on")
    end
end)

menu.action(missions, "清理敌人", {}, "", function()
    local counter = 0
    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
        if HUD.GET_BLIP_COLOUR(HUD.GET_BLIP_FROM_ENTITY(ped)) == 1 or TASK.GET_IS_TASK_ACTIVE(ped, 352) then -- shitty way to go about it but hey, it works (most of the time).
            ENTITY.SET_ENTITY_HEALTH(ped, 0)
            counter += 1
            util.yield()
        end
    end
    if counter == 0 then
        util.toast("没有发现敌人. :/")
    else
        util.toast("已清理 ".. tostring(counter) .." 个敌人.")
    end
end)

menu.action(missions, "将拾取物传送到自己", {}, "", function()
    local counter = 0
    local pos = players.get_position(players.user())
    for _, pickup in ipairs(entities.get_all_pickups_as_handles()) do
        ENTITY.SET_ENTITY_COORDS(pickup, pos, false, false, false, false)
        counter += 1
        util.yield()
    end
    if counter == 0 then
        util.toast("没有发现可捡拾物. :/")
    else
        util.toast("已传送 ".. tostring(counter) .." 个拾取物.")
    end
end)

local modifier = 1.00
menu.slider_float(weapons, "近战伤害修改", {"meleedamage"}, "", 100, 1000, 100, 10, function(value)
    modifier = value / 100
    PLAYER.SET_PLAYER_MELEE_WEAPON_DAMAGE_MODIFIER(players.user(), modifier)
end)
	
local language_codes_by_enum = {
    [0]= "en-us",
    [1]= "fr-fr",
    [2]= "de-de",
    [3]= "it-it",
    [4]= "es-es",
    [5]= "pt-br",
    [6]= "pl-pl",
    [7]= "ru-ru",
    [8]= "ko-kr",
    [9]= "zh-tw",
    [10] = "ja-jp",
    [11] = "es-mx",
    [12] = "zh-cn"
}

local my_lang = lang.get_current()

function encode_for_web(text)
	return string.gsub(text, "%s", "+")
end


function get_iso_version_of_lang(lang_code)
    lang_code = string.lower(lang_code)
    if lang_code ~= "zh-cn" and lang_code ~= "zh-tw" then
        return string.split(lang_code, '-')[1]
    else
        return lang_code
    end
end

local iso_my_lang = get_iso_version_of_lang(my_lang)

local do_translate = false
menu.toggle(session, "翻译聊天 [测试版]", {"nextton"}, "\n《 启动/关闭翻译 》\n该功能无法翻译自己发送的\n只能翻译其他人发送的消息\n会将消息自动发送在聊天\n并且其他人无法看见.\n", function(on)
    do_translate = on
end, false)

local only_translate_foreign = true
menu.toggle(session, "只翻译不同游戏语言", {"nextforeignonly"}, "仅翻译来自不同游戏语言的用户的消息,从而节省 API 调用。 您应该保持此状态,以防止 Google 暂时阻止您的请求.", function(on)
    only_translate_foreign = on
end, true)

local players_on_cooldown = {}

chat.on_message(function(sender, reserved, text, team_chat, networked, is_auto)
    if do_translate and networked and players.user() ~= sender then
        local encoded_text = encode_for_web(text)
        local player_lang = language_codes_by_enum[players.get_language(sender)]
        local player_name = players.get_name(sender)
        if only_translate_foreign and player_lang == my_lang then
            return
        end
        -- credit to the original chat translator for the api code
        local translation
        if players_on_cooldown[sender] == nil then
            async_http.init("translate.googleapis.com", "/translate_a/single?client=gtx&sl=auto&tl=" .. iso_my_lang .."&dt=t&q=".. encoded_text, function(data)
		    	translation, original, source_lang = data:match("^%[%[%[\"(.-)\",\"(.-)\",.-,.-,.-]],.-,\"(.-)\"")
                if source_lang == nil then 
                    util.toast("无法翻译 来自 " .. player_name)
                    return
                end
                players_on_cooldown[sender] = true
                if get_iso_version_of_lang(source_lang) ~= iso_my_lang then
                    chat.send_message(string.gsub(player_name .. ': \"' .. translation .. '\"', "%+", " "), team_chat, true, false)
                end
                util.yield(1000)
                players_on_cooldown[sender] = nil
		    end, function()
                util.toast("无法翻译 来自 " .. player_name)
            end)
		    async_http.dispatch()
        else
            util.toast(player_name .. "发送了一条信息,在翻译的冷却时间内. 如果该玩家在聊天中乱发垃圾信息,请考虑踢掉他,以防止被谷歌翻译暂时停止.")
        end
    end
end)

menu.toggle_loop(weapons, "最大自瞄范围", {}, "手柄的辅助瞄准功能开启后,将有无限的范围.", function()
    PLAYER.SET_PLAYER_LOCKON_RANGE_OVERRIDE(players.user(), 99999999.0)
end)

local weapon_thing = menu.list(weapons, "弹药类型", {}, "改变你的枪射出的子弹.")
for id, data in pairs(weapon_stuff) do
    local name = data[1]
    local weapon_name = data[2]
    local a = false
    menu.toggle(weapon_thing, name, {}, "", function(toggle)
        a = toggle
        while a do
            local weapon = util.joaat(weapon_name)
            projectile = weapon
            while not WEAPON.HAS_WEAPON_ASSET_LOADED(projectile) do
                WEAPON.REQUEST_WEAPON_ASSET(projectile, 31, false)
                util.yield(10)
            end
            local inst = v3.new()
            if PED.IS_PED_SHOOTING(PLAYER.PLAYER_PED_ID()) then
                if not WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(PLAYER.PLAYER_PED_ID(), memory.addrof(inst)) then
                    v3.set(inst,CAM.GET_FINAL_RENDERED_CAM_ROT(2))
                    local tmp = v3.toDir(inst)
                    v3.set(inst, v3.get(tmp))
                    v3.mul(inst, 1000)
                    v3.set(tmp, CAM.GET_FINAL_RENDERED_CAM_COORD())
                    v3.add(inst, tmp)
                end
                local x, y, z = v3.get(inst)
                local wpEnt = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(PLAYER.PLAYER_PED_ID(), false)
                local wpCoords = ENTITY.GET_ENTITY_BONE_POSTION(wpEnt, ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(wpEnt, "gun_muzzle"))
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(wpCoords.x, wpCoords.y, wpCoords.z, x, y, z, 1, true, weapon, PLAYER.PLAYER_PED_ID(), true, false, 1000.0)
            end
            util.yield()
        end
        local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
        MISC.CLEAR_AREA_OF_PROJECTILES(pos, 999999, 0)
    end)
end

menu.toggle_loop(weapons, "快速更换武器", {"fasthands"}, "更快地更换你的武器.", function()
    if TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 56) then
        PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
    end
end)

menu.toggle_loop(weapons, "锁定玩家", {}, "允许您使用武装载具上的制导导弹发射器锁定玩家.", function()
    for _, pid in ipairs(players.list(true, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        PLAYER.ADD_PLAYER_TARGETABLE_ENTITY(players.user(), ped)
        ENTITY.SET_ENTITY_IS_TARGET_PRIORITY(ped, false, 400.0)    
    end
end, function()
    for _, pid in ipairs(players.list(true, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        PLAYER.REMOVE_PLAYER_TARGETABLE_ENTITY(players.user(), ped)
    end
end)

for id, data in pairs(visual_stuff) do
    local visual_name = data[1]
    local visual_thing = data[2]
    local visual = false
    local visual_toggle
    visual_toggle = menu.toggle(visuals, visual_name, {""}, "", function(toggled)
        visual = toggled
        if not menu.get_value(visual_toggle) then
            GRAPHICS.ANIMPOSTFX_STOP_ALL()
        return end

        while visual do
            GRAPHICS.SET_TIMECYCLE_MODIFIER(visual_thing)
            menu.trigger_commands("shader off")
            util.yield(250)
        end
        GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
    end)
end 

local veh_jump = menu.list(vehicles, "载具跳跃")
local force = 25.00
menu.slider_float(veh_jump, "跳跃倍率", {"jumpiness"}, "", 0, 10000, 2500, 100, function(value)
    force = value / 100
end)
menu.toggle_loop(veh_jump, "启动", {"vehiclejump"}, "按空格键跳跃.", function()
    local veh = entities.get_user_vehicle_as_handle()
    if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) and PAD.IS_CONTROL_JUST_RELEASED(0, 102) then
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, force/1.5, force, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
        repeat
            util.yield()
        until not ENTITY.IS_ENTITY_IN_AIR(veh)
    end
end)

local deformation = 1.00
menu.slider_float(vehicles, "载具变形", {"deformation"}, "", 0, 10000, 100, 100, function(value)
    deformation = value / 100
    menu.trigger_commands("vhdeformationmult " .. deformation)
end)

local seat_id = -1
local moved_seat = menu.click_slider(vehicles, "更换载具座位", {}, "", 1, 1, 1, 1, function(seat_id)
    TASK.TASK_WARP_PED_INTO_VEHICLE(players.user_ped(), entities.get_user_vehicle_as_handle(), seat_id - 2)
end)

menu.on_tick_in_viewport(moved_seat, function()
    if not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
        moved_seat.max_value = 0
    return end

    if not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
        moved_seat.max_value = 0
    return end
    
    moved_seat.max_value = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(entities.get_user_vehicle_as_handle()))
end)

menu.toggle_loop(vehicles, "快速热启动", {""}, "", function()
    if not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(entities.get_user_vehicle_as_handle()) and TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 150) then
        PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
    end
end)

menu.toggle_loop(vehicles, "快速上下车", {"fastvehcleenter"}, "更快地进入载具.", function()
    if (TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 160) or TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 167) or TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 165)) and not TASK.GET_IS_TASK_ACTIVE(players.user_ped(), 195) then
        PED.FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
    end
end)


menu.toggle_loop(vehicles, "在下车时关闭无敌模式", {""}, "", function()
    if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(entities.get_user_vehicle_as_handle()) then
        if not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
            ENTITY.SET_ENTITY_CAN_BE_DAMAGED(PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true), true)
        end
    end
end)

menu.toggle_loop(vehicles, "发射轮船", {}, "按Ctrl键和W键进行转盘操作.", function(toggled)
    local veh = entities.get_user_vehicle_as_handle()
    if veh == 0 then return end
    local CAutomobile = entities.handle_to_pointer(veh)
    local CHandlingData = memory.read_long(CAutomobile + 0x0918)
    if util.is_key_down(0x57) and util.is_key_down(0x11) then 
       memory.write_float(CHandlingData + 0x00EC, -0.25)
    else
       memory.write_float(CHandlingData + 0x00EC, 0.5)
    end
end)

menu.toggle_loop(vehicles, "绕过防锁定", {}, "绕过锁定限制.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local veh = PED.GET_VEHICLE_PED_IS_USING(ped)
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON_SYNCED(veh, true)
        end
    end
end)

local headlamp = menu.list(funfeatures, "头灯", {}, "别人看不到的本地娱乐功能.")
local distance = 25.0
menu.slider_float(headlamp, "距离", {"distance"}, "光照距离.", 100, 10000, 1500, 100, function(value)
    distance = value / 100
end)

local brightness = 10.0
menu.slider_float(headlamp, "亮度", {"brightness"}, "光亮强度.", 100, 10000, 1000, 100, function(value)
    brightness = value / 100
end)

local radius = 15.0
menu.slider_float(headlamp, "半径", {"radius"}, "光束半径.", 100, 5000, 2000, 100, function(value)
    radius = value / 100
end)

local color = {r = 1, g = 235/255, b = 190/255, a = 0}
menu.colour(headlamp, "颜色", {"colour"}, "", color, true, function(value)
    color = value 
end)

menu.toggle_loop(headlamp, "开启", {"headlamp"}, "", function()
    local head_pos = PED.GET_PED_BONE_COORDS(players.user_ped(), 31086, 0.0, 0.0, 0.0)
    local cam_rot = players.get_cam_rot(players.user())
    GRAPHICS.DRAW_SPOT_LIGHT(head_pos, cam_rot:toDir(), math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), distance * 1.5, brightness, 0.0, radius, distance)
end)

menu.toggle(funfeatures, "停电", {"poweroutage"}, "", function(toggled)
    GRAPHICS.SET_ARTIFICIAL_LIGHTS_STATE(toggled)
end)

menu.toggle(funfeatures, "停电 2", {"blackout"}, "", function(toggled)
    menu.trigger_commands("time 1")
    GRAPHICS.SET_ARTIFICIAL_LIGHTS_STATE(toggled)
    if toggled then
        GRAPHICS.SET_TIMECYCLE_MODIFIER("dlc_island_vault")
    else
        GRAPHICS.SET_TIMECYCLE_MODIFIER("DEFAULT")
    end
end)

local obj
menu.toggle(funfeatures, "力场", {}, "在你的脚上附着一个UFO,破坏路上的任何东西.", function(toggled)
    local mdl = util.joaat("p_spinning_anus_s")
    local playerpos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), false)
    request_model(mdl)
    if toggled then
        obj = entities.create_object(mdl, playerpos)
        ENTITY.SET_ENTITY_VISIBLE(obj, false)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(obj, players.user_ped(), 0, 0, 0, 0, 0, 0, 0, false, false, true, false, 0, false, 0)
    else
        if obj ~= nil then 
            entities.delete_by_handle(obj)
        end
    end
end)

local jesus_main = menu.list(funfeatures, "自动驾驶", {}, "使用前请先设置一个导航点.")
local style = 786603
menu.slider_text(jesus_main, "驾驶风格", {}, "点击以切换风格", style_names, function(index, value)
    style = value
end)

local jesus_toggle
jesus_toggle = menu.toggle_loop(jesus_main, "启用", {}, "", function(toggled)
    if toggled then
        local ped = players.user_ped()
        local my_pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player_veh = entities.get_user_vehicle_as_handle()

        if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then 
            util.toast("那你倒是先上车阿呆逼. :)")
        return end

        local jesus = util.joaat("u_m_m_jesus_01")
        request_model(jesus)

        
        jesus_ped = entities.create_ped(26, jesus, my_pos, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(jesus_ped, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(jesus_ped, true)
        PED.SET_PED_INTO_VEHICLE(ped, player_veh, -2)
        PED.SET_PED_INTO_VEHICLE(jesus_ped, player_veh, -1)
        PED.SET_PED_KEEP_TASK(jesus_ped, true)

        if HUD.IS_WAYPOINT_ACTIVE() then
            local pos = HUD.GET_BLIP_COORDS(HUD.GET_FIRST_BLIP_INFO_ID(8))
            TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(jesus_ped, player_veh, pos, 9999.0, style, 0.0)
        else
            util.toast("请先设置一个导航点. :/")
                menu.set_value(jesus_toggle, false)
        end
    else
        if jesus_ped ~= nil then 
            entities.delete_by_handle(jesus_ped)
        end
    end
end)

menu.toggle(funfeatures, "特斯拉自动驾驶", {}, "嘎嘎出事故\n整死你!!!!", function(toggled)
    local ped = players.user_ped()
    local playerpos = ENTITY.GET_ENTITY_COORDS(ped, false)
    local tesla_ai = util.joaat("u_m_y_baygor")
    local tesla = util.joaat("raiden")
    request_model(tesla_ai)
    request_model(tesla)
    if toggled then     
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            menu.trigger_commands("deletevehicle")
        end

        tesla_ai_ped = entities.create_ped(26, tesla_ai, playerpos, 0)
        tesla_vehicle = entities.create_vehicle(tesla, playerpos, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(tesla_ai_ped, true) 
        ENTITY.SET_ENTITY_VISIBLE(tesla_ai_ped, false)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(tesla_ai_ped, true)
        PED.SET_PED_INTO_VEHICLE(ped, tesla_vehicle, -2)
        PED.SET_PED_INTO_VEHICLE(tesla_ai_ped, tesla_vehicle, -1)
        PED.SET_PED_KEEP_TASK(tesla_ai_ped, true)
        VEHICLE.SET_VEHICLE_COLOURS(tesla_vehicle, 111, 111)
        VEHICLE.SET_VEHICLE_MOD(tesla_vehicle, 23, 8, false)
        VEHICLE.SET_VEHICLE_MOD(tesla_vehicle, 15, 1, false)
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(tesla_vehicle, 111, 147)
        menu.trigger_commands("performance")

        if HUD.IS_WAYPOINT_ACTIVE() then
            local pos = HUD.GET_BLIP_COORDS(HUD.GET_FIRST_BLIP_INFO_ID(8))
            TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(tesla_ai_ped, tesla_vehicle, pos, 20.0, 786603, 0)
        else
            TASK.TASK_VEHICLE_DRIVE_WANDER(tesla_ai_ped, tesla_vehicle, 20.0, 786603)
        end
    else
        if tesla_ai_ped ~= nil then 
            entities.delete_by_handle(tesla_ai_ped)
        end
        if tesla_vehicle ~= nil then 
            entities.delete_by_handle(tesla_vehicle)
        end
    end
end)

for index, data in pairs(interiors) do
    local location_name = data[1]
    local location_coords = data[2]
    menu.action(teleport, location_name, {}, "", function()
        menu.trigger_commands("doors on")
        menu.trigger_commands("nodeathbarriers on")
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(players.user_ped(), location_coords.x, location_coords.y, location_coords.z, false, false, false)
    end)
end

local finger_thing = menu.list(funfeatures, "手指枪 [B键]", {}, "向你所指的方向发射子弹.")
for id, data in pairs(weapon_stuff) do
    local name = data[1]
    local weapon_name = data[2]
    local projectile = util.joaat(weapon_name)
    while not WEAPON.HAS_WEAPON_ASSET_LOADED(projectile) do
        WEAPON.REQUEST_WEAPON_ASSET(projectile, 31, false)
        util.yield(10)
    end
    menu.toggle(finger_thing, name, {}, "", function(state)
        toggled = state
        while toggled do
            if memory.read_int(memory.script_global(4521801 + 930)) == 3 then
                memory.write_int(memory.script_global(4521801 + 935), NETWORK.GET_NETWORK_TIME())
                local inst = v3.new()
                v3.set(inst,CAM.GET_FINAL_RENDERED_CAM_ROT(2))
                local tmp = v3.toDir(inst)
                v3.set(inst, v3.get(tmp))
                v3.mul(inst, 1000)
                v3.set(tmp, CAM.GET_FINAL_RENDERED_CAM_COORD())
                v3.add(inst, tmp)
                local x, y, z = v3.get(inst)
                local fingerPos = PED.GET_PED_BONE_COORDS(players.user_ped(), 4089, 1.0, 0, 0)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(fingerPos, x, y, z, 1, true, projectile, 0, true, false, 500.0, players.user_ped(), 0)
            end
            util.yield(100)
        end
        local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
        MISC.CLEAR_AREA_OF_PROJECTILES(pos, 999999, 0)
    end)
end

local jinx_pet
jinx_toggle = menu.toggle_loop(funfeatures, "宠物猫J inx", {}, "招一只可爱的小猫咪\n跟着你喵喵叫\n好可爱我好喜欢！", function()
    if not jinx_pet or not ENTITY.DOES_ENTITY_EXIST(jinx_pet) then
        local jinx = util.joaat("a_c_cat_01")
        request_model(jinx)
        local pos = players.get_position(players.user())
        jinx_pet = entities.create_ped(28, jinx, pos, 0)
        PED.SET_PED_COMPONENT_VARIATION(jinx_pet, 0, 0, 1, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(jinx_pet, true)
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(jinx_pet)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(jinx_pet, players.user_ped(), 0, -0.3, 0, 7.0, -1, 1.5, true)
    util.yield(2500)
end, function()
    entities.delete_by_handle(jinx_pet)
    jinx_pet = nil
end)

local jinx_army = {}
local army = menu.list(funfeatures, "宠物猫 Jinx 军队", {}, "哈哈哈,招一堆傻猫\n叫的你头疼,甩都甩不掉")
menu.click_slider(army, "生成数量", {}, "选吧,多生成点,最多256只", 1, 256, 30, 1, function(val)
    local ped = players.user_ped()
    local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
    pos.y = pos.y - 5
    pos.z = pos.z + 1
    local jinx = util.joaat("a_c_cat_01")
    request_model(jinx)
     for i = 1, val do
        jinx_army[i] = entities.create_ped(28, jinx, pos, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(jinx_army[i], true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(jinx_army[i], true)
        PED.SET_PED_COMPONENT_VARIATION(jinx_army[i], 0, 0, 1, 0)
        TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(jinx_army[i], ped, 0, -0.3, 0, 7.0, -1, 10, true)
        util.yield()
     end 
end)

menu.action(army, "清除宠物猫 Jinx", {}, "把这烦人的傻猫都给他们清了", function()
    for i, ped in ipairs(entities.get_all_peds_as_handles()) do
        if PED.IS_PED_MODEL(ped, util.joaat("a_c_cat_01")) then
            entities.delete_by_handle(ped)
        end
    end
end)

menu.action(funfeatures, "找到 Jinx", {}, "\n将Jinx猫传送到你身边\n老叫傻猫来干嘛?\n", function()
    local ped = players.user_ped()
    local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
    if jinx_pet ~= nil then 
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(jinx_pet, pos, false, false, false)
    else
        util.toast("找不到你那只傻猫了. :/")
    end
end)


menu.toggle_loop(detections, "无敌模式", {}, "检测战局玩家是否在使用无敌.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        for i, interior in ipairs(interior_stuff) do
            if players.is_godmode(pid) and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_spawn_state(pid) == 99 and get_interior_player_is_in(pid) == interior then
                util.draw_debug_text(players.get_name(pid) .. "是无敌,很有可能是作弊者")
                break
            end
        end
    end 
end)

menu.toggle_loop(detections, "载具无敌模式", {}, "检测玩家载具是否在使用无敌.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
        local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
            for i, interior in ipairs(interior_stuff) do
                if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(player_veh) and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_spawn_state(pid) == 99 and get_interior_player_is_in(pid) == interior then
                    util.draw_debug_text(players.get_name(pid) .. "的载具处于无敌模式")
                    break
                end
            end
        end
    end 
end)

menu.toggle_loop(detections, "未发布的载具", {}, "检测是否有玩家在驾驶尚未发布的载具.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(pid)
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local PedID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1))
        for i, name in ipairs(unreleased_vehicles) do
            if modelHash == util.joaat(name) and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                util.draw_debug_text(players.get_name(PedID) .. " 正在驾驶未发布的载具 " .. "(" .. name .. ")")
            end
        end
    end
end)


menu.toggle_loop(detections, "隐藏武器", {}, "检测是否有玩家使用无法获得的武器.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        for i, hash in ipairs(modded_weapons) do
            local weapon_hash = util.joaat(hash)
            if WEAPON.HAS_PED_GOT_WEAPON(ped, weapon_hash, false) and (WEAPON.IS_PED_ARMED(ped, 7) or TASK.GET_IS_TASK_ACTIVE(ped, 8) or TASK.GET_IS_TASK_ACTIVE(ped, 9)) then
                util.toast(players.get_name(pid) .. " 使用隐藏的武器 " .. "(" .. hash .. ")")
                break
            end
        end
    end
end)

menu.toggle_loop(detections, "隐藏载具", {}, "检测是否有玩家正在使用无法获得的载具.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local modelHash = players.get_vehicle_model(pid)
        for i, name in ipairs(modded_vehicles) do
            if modelHash == util.joaat(name) then
                util.draw_debug_text(players.get_name(pid) .. " 正在驾驶隐藏载具")
                break
            end
        end
    end
end)

menu.toggle_loop(detections, "自由镜头检测", {}, "检测是否有玩家使用自由镜头(又称无碰撞)", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local ped_ptr = entities.handle_to_pointer(ped)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local oldpos = players.get_position(pid)
        util.yield()
        local currentpos = players.get_position(pid)
        local vel = ENTITY.GET_ENTITY_VELOCITY(ped)
        if not util.is_session_transition_active() and players.exists(pid)
        and get_interior_player_is_in(pid) == 0 and get_spawn_state(pid) ~= 0
        and not PED.IS_PED_IN_ANY_VEHICLE(ped, false) -- too many false positives occured when players where driving. so fuck them. lol.
        and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_DEAD_OR_DYING(ped)
        and not PED.IS_PED_CLIMBING(ped) and not PED.IS_PED_VAULTING(ped) and not PED.IS_PED_USING_SCENARIO(ped)
        and not TASK.GET_IS_TASK_ACTIVE(ped, 160) and not TASK.GET_IS_TASK_ACTIVE(ped, 2)
        and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(pid)) <= 395.0 -- 400 was causing false positives
        and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(ped) > 5.0 and not ENTITY.IS_ENTITY_IN_AIR(ped) and entities.player_info_get_game_state(ped_ptr) == 0
        and oldpos.x ~= currentpos.x and oldpos.y ~= currentpos.y and oldpos.z ~= currentpos.z 
        and vel.x == 0.0 and vel.y == 0.0 and vel.z == 0.0 then
            util.toast(players.get_name(pid) .. " 是无碰撞")
            break
        end
    end
end)

menu.toggle_loop(detections, "超级驾驶检测", {}, "检测是否有玩家在修改载具速度", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        local veh_speed = (ENTITY.GET_ENTITY_SPEED(vehicle)* 2.236936)
        local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
        if class ~= 15 and class ~= 16 and veh_speed >= 200 and (players.get_vehicle_model(pid) ~= util.joaat("oppressor") or players.get_vehicle_model(pid) ~= util.joaat("oppressor2")) then
            local PedID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1))
            util.toast(players.get_name(PedID) .. " 正在超级驾驶")
            break
        end
    end
end)

menu.toggle_loop(detections, "观看检测", {}, "检测是否有玩家在观看你.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        for i, interior in ipairs(interior_stuff) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            if not util.is_session_transition_active() and get_spawn_state(pid) ~= 0 and get_interior_player_is_in(pid) == interior
            and not NETWORK.NETWORK_IS_PLAYER_FADING(pid) and ENTITY.IS_ENTITY_VISIBLE(ped) and not PED.IS_PED_DEAD_OR_DYING(ped) then
                if v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_cam_pos(pid)) < 15.0 and v3.distance(ENTITY.GET_ENTITY_COORDS(players.user_ped(), false), players.get_position(pid)) > 20.0 then
                    util.toast(players.get_name(pid) .. " 正在观看你")
                    break
                end
            end
        end
    end
end)

menu.toggle_loop(detections, "雷霆加入检测", {}, "检测是否有玩家使用了雷霆加入.", function()
    for _, pid in ipairs(players.list(false, true, true)) do
        if not util.is_session_transition_active() and get_spawn_state(pid) == 0 and players.get_script_host() == pid  then
            util.toast(players.get_name(pid) .. " 触发了检测(雷霆加入),现在已被归类为作弊者")
        end
    end
end)

local anti_mugger = menu.list(protections, "拦截劫匪")
menu.toggle_loop(anti_mugger, "自我拦截", {}, "防止自己被抢劫.", function() -- thx nowiry for improving my method :D
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local ped_netId = memory.script_local("am_gang_call", 63 + 10 + (0 * 7 + 1))
        local sender = memory.script_local("am_gang_call", 287)
        local target = memory.script_local("am_gang_call", 288)
        local player = players.user()

        util.spoof_script("am_gang_call", function()
            if (memory.read_int(sender) ~= player and memory.read_int(target) == player 
            and NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(memory.read_int(ped_netId)) 
            and NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(memory.read_int(ped_netId))) then
                local mugger = NETWORK.NET_TO_PED(memory.read_int(ped_netId))
                entities.delete_by_handle(mugger)
                util.toast("拦截到了劫匪,来自 " .. players.get_name(memory.read_int(sender)))
            end
        end)
    end
end)

menu.toggle_loop(anti_mugger, "他人拦截", {}, "防止他人被抢劫.", function()
    if NETWORK.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
        local ped_netId = memory.script_local("am_gang_call", 63 + 10 + (0 * 7 + 1))
        local sender = memory.script_local("am_gang_call", 287)
        local target = memory.script_local("am_gang_call", 288)
        local player = players.user()

        util.spoof_script("am_gang_call", function()
            if memory.read_int(target) ~= player and memory.read_int(sender) ~= player
            and NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(memory.read_int(ped_netId)) 
            and NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(memory.read_int(ped_netId)) then
                local mugger = NETWORK.NET_TO_PED(memory.read_int(ped_netId))
                entities.delete_by_handle(mugger)
                util.toast("拦截到了劫匪,来自 " .. players.get_name(memory.read_int(sender)) .. " 劫匪目标: " .. players.get_name(memory.read_int(target)))
            end
        end)
    end
end)


menu.toggle_loop(protections, "野兽防护", {}, "防止你被变成野兽,但也会阻止其他人的战局事件.", function()
    if util.spoof_script("am_hunt_the_beast", SCRIPT.TERMINATE_THIS_THREAD) then
        util.toast("检测到战局《猎杀野兽》事件,正在阻止...")
    end
end)

local anticage = menu.list(protections, "防笼子", {}, "让你无法被任何物体困住.")
local alpha = 160
menu.slider(anticage, "笼子透明度", {"cagealpha"}, "物体将具有的透明度量,设置为 0 可自动删除所有笼子.", 0, #values, 3, 1, function(amount)
    alpha = values[amount]
end)

menu.toggle_loop(anticage, "启用", {"anticage"}, "", function()
    local user = players.user_ped()
    local veh = PED.GET_VEHICLE_PED_IS_USING(user)
    local my_ents = {user, veh}
    for i, obj_ptr in ipairs(entities.get_all_objects_as_pointers()) do
        local net_obj = memory.read_long(obj_ptr + 0xd0)
        if net_obj == 0 or memory.read_byte(net_obj + 0x49) == players.user() then
            continue
        end
        local obj_handle = entities.pointer_to_handle(obj_ptr)
        CAM.SET_GAMEPLAY_CAM_IGNORE_ENTITY_COLLISION_THIS_UPDATE(obj_handle)
        for _, pid in ipairs(players.list(true, true, true)) do
            for i, data in ipairs(my_ents) do
                for i, door in ipairs(doors) do
                    if ENTITY.IS_ENTITY_TOUCHING_MODEL(data, util.joaat(door)) then 
                        repeat
                            util.yield()
                        until not ENTITY.IS_ENTITY_TOUCHING_ENTITY(data, util.joaat(door))
                    end
                    util.yield(250)
                    if ENTITY.IS_ENTITY_TOUCHING_ENTITY(data, obj_handle) and alpha > 0 then
                        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(obj_handle, data, false)
                        ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(data, obj_handle, false)
                        ENTITY.SET_ENTITY_ALPHA(obj_handle, alpha, false)
                        util.toast("拦截了笼子,来自: " .. players.get_name(entities.get_owner(obj_ptr)))
                    end
                    if data ~= 0 and ENTITY.IS_ENTITY_TOUCHING_ENTITY(data, obj_handle) and alpha == 0 then
                        util.toast("拦截了笼子,来自: " .. players.get_name(entities.get_owner(obj_ptr)))
                        entities.delete_by_handle(obj_handle)
                    end
                end
            end
        end
        SHAPETEST.RELEASE_SCRIPT_GUID_FROM_ENTITY(obj_handle)
    end
end)


menu.list_action(protections, "全部清理!", {}, "\n可清理周边一切\n其他玩家的个人载具除外.\n适用于掉帧卡顿时按一下\n小概率出现自崩\n", {"NPC", "载具", "物体", "可拾取物体", "绳索", "投掷物", "声音"}, function(index, name)
    util.toast("正在清理 "..name:lower().."...")
    local counter = 0
    switch index do
        case 1:
            for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                if ped ~= players.user_ped() and not PED.IS_PED_A_PLAYER(ped) then
                    entities.delete_by_handle(ped)
                    counter += 1
                    util.yield()
                end
            end
            break
        case 2:
            for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
                if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false) and DECORATOR.DECOR_GET_INT(vehicle, "Player_Vehicle") == 0 and NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
                    entities.delete_by_handle(vehicle)
                    counter += 1
                end
                util.yield()
            end
            break
        case 3:
            for _, object in ipairs(entities.get_all_objects_as_handles()) do
                entities.delete_by_handle(object)
                counter += 1
                util.yield()
            end
            break
        case 4:
            for _, pickup in ipairs(entities.get_all_pickups_as_handles()) do
                entities.delete_by_handle(pickup)
                counter += 1
                util.yield()
            end
            break
        case 5:
            local temp = memory.alloc(4)
            for i = 0, 101 do
                memory.write_int(temp, i)
                if PHYSICS.DOES_ROPE_EXIST(temp) then
                    PHYSICS.DELETE_ROPE(temp)
                    counter += 1
                end
                util.yield()
            end
            break
        case 6:
            local coords = players.get_position(players.user())
            MISC.CLEAR_AREA_OF_PROJECTILES(coords.x, coords.y, coords.z, 1000, 0)
            counter = "所有"
            break
        case 4:
            for i = 0, 99 do
                AUDIO.STOP_SOUND(i)
                util.yield()
            end
        break
    end
    util.toast("已清除 "..tostring(counter).." "..name:lower()..".")
end)

menu.action(protections, "清除区域", {"cleanse"}, "", function()
    local cleanse_entitycount = 0
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if ped ~= players.user_ped() and not PED.IS_PED_A_PLAYER(ped) then
            entities.delete_by_handle(ped)
            cleanse_entitycount += 1
            util.yield()
        end
    end
    util.toast("已清除 " .. cleanse_entitycount .. " Peds")
    cleanse_entitycount = 0
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false) and DECORATOR.DECOR_GET_INT(vehicle, "Player_Vehicle") == 0 and NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
            entities.delete_by_handle(vehicle)
            cleanse_entitycount += 1
            util.yield()
        end
    end
    util.toast("已清除 ".. cleanse_entitycount .." 载具")
    cleanse_entitycount = 0
    for _, object in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(object)
        cleanse_entitycount += 1
        util.yield()
    end
    util.toast("已清除 " .. cleanse_entitycount .. " 物体")
    cleanse_entitycount = 0
    for _, pickup in pairs(entities.get_all_pickups_as_handles()) do
        entities.delete_by_handle(pickup)
        cleanse_entitycount += 1
        util.yield()
    end
    util.toast("已清除 " .. cleanse_entitycount .. " 可拾取物体")
    local temp = memory.alloc(4)
    for i = 0, 100 do
        memory.write_int(temp, i)
        PHYSICS.DELETE_ROPE(temp)
    end
    util.toast("已清除所有绳索")
    local pos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    MISC.CLEAR_AREA_OF_PROJECTILES(pos, 400, 0)
    util.toast("已清除所有投掷物")
end)


local misc = menu.list(menu.my_root(), "其他选项", {}, "")
menu.hyperlink(misc, "Jinx脚本中文交流群", "https://jq.qq.com/?_wv=1027&k=Mh1p1Aty")
menu.hyperlink(menu.my_root(), "加入官方Discord", "https://discord.gg/hjs5S93kQv")
local credits = menu.list(misc, "鸣谢", {}, "")
local jinx = menu.list(credits, "Jinx", {}, "")
menu.hyperlink(jinx, "Tiktok", "https://www.tiktok.com/@bigfootjinx")
menu.hyperlink(jinx, "Twitter", "https://twitter.com/bigfootjinx")
menu.hyperlink(jinx, "Instagram", "https://www.instagram.com/bigfootjinx")
menu.hyperlink(jinx, "Youtube", "https://www.youtube.com/channel/UC-nkxad5MRDuyz7xstc-wHQ?sub_confirmation=1")
menu.action(credits, "ICYPhoenix", {}, "如果他没有将我的名字改为OP Jinx Lua,我将永远不会制作这个脚本或想过制作这个脚本", function()
end)
menu.action(credits, "Sapphire", {}, "当我第一次启动 Lua 以及开始学习Stand API和natives时,他处理了我所有的困难并帮助了很多人", function()
end)
menu.action(credits, "aaronlink127", {}, "帮助处理数学问题,还帮助处理自动更新程序和其他一些功能", function()
end)
menu.action(credits, "Ren", {}, "提出合理建议", function()
end)
menu.action(credits, "well in that case", {}, "用于制作Pluto并让我的部分代码看起来更好,运行更流畅", function()
end)
menu.action(credits, "jerry123", {}, "清理我的某些代码并告诉我可以改进的地方", function()
end)
menu.action(credits, "Scriptcat", {}, "从我制作这个脚本开始就陪着我,告诉我一些有用的 Lua 技巧,并教导我开始学习Stand API和natives", function()
end)
menu.action(credits, "ERR_NET_ARRAY", {}, "帮助编辑", function()
end)
menu.action(credits, "d6b.", {}, "给我赠送Discord Nitro", function()
end)

local translation = menu.list(credits, "翻译人员", {}, "translation")
menu.action(translation, "lu_zi / 鹿子", {}, "中文区翻译,翻译了太多版本于2022/9/4离开Jinx.", function()
end)
menu.action(translation, "BLackMist / 臣服", {}, "中文区翻译,目前Jinx翻译者.", function()
end)

util.keep_running()
