
local Layer =
{
  LayerNPC = 8,              -- NPC所在层
  LayerPlayer = 9,           -- 玩家所在层
  LayerMonster = 10,         -- 怪物/NPC所在层
  LayerHideObj = 11 ,        -- 摄像机碰撞后需隐藏的物体所在层
  LayerCharacter = 12,       -- 角色
  LayerCameraCollider = 16,  -- camera collider 
  LayerPlot = 13,
  LayerUI = 20,              -- UI所在层
  LayerUICharacter = 21,     -- UI上的生物所在层
  LayerEffect = 23,          -- 特效
}



local ResourceLoadType =
{
    Default = 0,
    Persistent = 1,      -- 永驻内存的资源
    Cache = bit.lshift (1,1) ,       -- Asset需要缓存

    UnLoad = bit.lshift (1,4) ,       -- 利用www加载并且处理后是否立即unload

    -- 加载方式
    LoadBundleFromFile= bit.lshift (1,6) ,       -- 利用AssetBundle.LoadFromFile加载
    LoadBundleFromWWW = bit.lshift (1,7) ,       -- 利用WWW 异步加载 AssetBundle
}

--已经作废 由cfg.skill.AnimType代替
local AnimType =
{
    Stand = "stand",
    Jump = "jump",
    JumpLoop = "jumploop",
    JumpEnd = "jumpend",
    Run = "run",
    Walk="walk",
    Idle = "idle",

    IdleFight = "standfight",
--    JumpFight = "jumpfight",
--    JumpLoopFight = "jumpfightloop",
--    JumpEndFight = "jumpfightend",
    RunFight = "runfight",



    GetUp = "qishen",
    Death = "death",

    StartRide="ride",
    StandRide="stand_ride",
    RunRide="riding",

--    Fly="flying",
--    StandFly="stand_fly",

    PullSword = "pullsword",
    Inlayersword = "inlayersword",

    Born = "born",
    Dying = "dying",
    Hit   = "hit",
    Mining = "minine"

}
local PetAnimType =
{
    Idle = "Idle",
    Run = "Run",
    Tiaoxin = "tiaoxin",
    Attack = "PG01",
}


local WeaponCollider = "WeaponCollider"

return
{
  ResourceLoadType = ResourceLoadType,
  Layer            = Layer,
  AnimType         = AnimType,
  PetAnimType      = PetAnimType,
  WeaponCollider   = WeaponCollider,
}
