using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SLua;
using System.IO;

public class SluaClass
{
    public static SluaClass instance = new SluaClass();
    public LuaState luaState = new LuaState(); //申明一个lua的状态机，就是相当一个协成

    public  LuaFunction init;
    public  LuaFunction update;

    private readonly LuaSvr lua = new LuaSvr();

    public void Init()
    {
        luaState.loaderDelegate = LoaderFile;
        lua.init(null,() =>
        {
            SluaStart();
        });
    }

    byte[] LoaderFile(string name, ref string outputFileName)
    {
        byte[] tempStr = null;
        string path = Application.dataPath + "/SluaTestCode/" + name+".lua";

        if (File.Exists(path))
        {
            tempStr = File.ReadAllBytes(path);
        }
        return tempStr;
    }
    // Use this for initialization
    void SluaStart()
    {
        luaState.doFile("main");

        init = luaState.getFunction("init");

        update = luaState.getFunction("Update");

        

    }




   
}
