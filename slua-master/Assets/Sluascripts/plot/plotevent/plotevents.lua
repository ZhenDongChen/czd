local PlotEvents = {

    --Director
    ["PlotDirector.PlotEventCameraTransform"]       = require("plot.plotevent.director.cameratransform"),
    ["PlotDirector.PlotEventCameraPath"]            = require("plot.plotevent.director.camerapath"),

    --相机相关
    ["PlotDirector.PlotEventCameraShock"]           = require("plot.plotevent.director.camerashock"),
    ["PlotDirector.PlotEventCameraMask"]            = require("plot.plotevent.director.cameramask"),
    ["PlotDirector.PlotEventCameraParameter"]       = require("plot.plotevent.director.cameraparameter"),
    ["PlotDirector.PlotEventCameraEffectBlinkEye"]  = require("plot.plotevent.director.cameraeffectblinkeye"),
    ["PlotDirector.PlotEventCameraFollow"]          = require("plot.plotevent.director.camerafollow"),

    --背景音乐、声音
    ["PlotDirector.PlotEventBackMusic"]             = require("plot.plotevent.director.backmusic"),
    ["PlotDirector.PlotEventBackSound"]             = require("plot.plotevent.director.sound"),

    --全局控制
    ["PlotDirector.PlotEventTimeScaleSet"]          = require("plot.plotevent.director.timescaleset"),
    ["PlotDirector.PlotEventTimeScaleCurve"]        = require("plot.plotevent.director.timescalecurve"),

    --Object相关
    ["PlotDirector.PlotEventObjectCreate"]          = require("plot.plotevent.object.object.objectcreate"),
    ["PlotDirector.PlotEventObjectLoad"]            = require("plot.plotevent.object.object.objectload"),
    ["PlotDirector.PlotEventObjectDestroy"]         = require("plot.plotevent.object.object.objectdestroy"),
    ["PlotDirector.PlotEventObjectParent"]          = require("plot.plotevent.object.object.objectparent"),
    ["PlotDirector.PlotEventObjectUnParent"]        = require("plot.plotevent.object.object.objectunparent"),
    ["PlotDirector.PlotEventObjectShowHide"]        = require("plot.plotevent.object.object.objectshowhide"),
    ["PlotDirector.PlotEventObjectTransform"]       = require("plot.plotevent.object.object.objecttransform"),
    ["PlotDirector.PlotEventObjectPath"]            = require("plot.plotevent.object.object.objectpath"),
    ["PlotDirector.PlotEventObjectSpecialCreate"]   = require("plot.plotevent.object.object.objectspecialcreate"),
    ["PlotDirector.PlotEventEventSequence"]         = require("plot.plotevent.object.eventsequence"),
    ["PlotDirector.PlotEventObjectSound"]           = require("plot.plotevent.object.sound.objectsound"),
    ["PlotDirector.PlotEventObjectShock"]           = require("plot.plotevent.object.object.objectshock"),

    --Script相关
    ["PlotDirector.PlotEventScriptLoadDestroy"]     = require("plot.plotevent.object.script.scriptloaddestroy"),
    ["PlotDirector.PlotEventScriptEnable"]          = require("plot.plotevent.object.script.scriptenable"),
    ["PlotDirector.PlotEventScriptParameter"]       = require("plot.plotevent.object.script.scriptparameter"),
    ["PlotDirector.PlotEventScripEventCurve"]       = require("plot.plotevent.object.script.scriptcurve"),
    --CgChangeShader
    ["PlotDirector.PlotEventChangeShader"]          = require("plot.plotevent.object.script.changeshader"),

    --Animator相关
   -- ["PlotDirector.PlotEventAnimatorAdd"]           = require("plot.plotevent.object.animator.animatoradd"),
    ["PlotDirector.PlotEventAnimatorPlay"]          = require("plot.plotevent.object.animator.animatorplay"),
   -- ["PlotDirector.PlotEventAnimatorPlayMulti"]     = require("plot.plotevent.object.animator.animatorplaymulti"),
   -- ["PlotDirector.PlotEventAnimatorParameter"]     = require("plot.plotevent.object.animator.animatorparameter"),
   -- ["PlotDirector.PlotEventAnimatorParameterMulti"]= require("plot.plotevent.object.animator.animatorparametermulti"),
   -- ["PlotDirector.PlotEventAnimatorCurve"]         = require("plot.plotevent.object.animator.animatorcurve"),
   -- ["PlotDirector.PlotEventAnimatorCurveMulti"]    = require("plot.plotevent.object.animator.animatorcurvemulti"),
    ["PlotDirector.PlotEventAnimatorSpeed"]         = require("plot.plotevent.object.animator.animatorspeed"),


   --对话相关
    ["PlotDirector.PlotEventTalk"]                  = require("plot.plotevent.talk.talk"),
    ["PlotDirector.PlotEventScreenWords"]           = require("plot.plotevent.talk.screenwords"),
    ["PlotDirector.PlotEventTalkSound"]             = require("plot.plotevent.talk.talksound"),
    ["PlotDirector.PlotEventChapterUI"]             = require("plot.plotevent.talk.chapterui"),
    --游戏命令
    ["PlotDirector.PlotEventGameActorAction"]       = require("plot.plotevent.gamelogic.characteraction"),
    ["PlotDirector.PlotEventGameCommand"]           = require("plot.plotevent.gamelogic.gamecommand"),

}

return PlotEvents
