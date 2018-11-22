using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SLua;
using System.IO;

public class Sluamr 
{
    public static Sluamr instance = new Sluamr();
    private readonly LuaSvr lua = new LuaSvr();

    public void Init()
    {
        LuaState.main.loaderDelegate = LoaderFile;
        CreateTable();
        lua.init((progress) =>
        {

        }, SluaStart);
    }


    public LuaTable CreateTable()
    {
        return new LuaTable(LuaSvr.mainState); 
    }

    byte[] LoaderFile(string name, ref string outputFileName)
    {
        byte[] tempStr = null;
        string path = Application.dataPath + "/../../../" + "SluaTestCode/" + name+".lua";

        if (File.Exists(path))
        {
            Debug.Log("file is Exists");
            tempStr = File.ReadAllBytes(path);
        }
        return tempStr;
    }
    // Use this for initialization
    void SluaStart()
    {
        SLua.LuaTable main = (LuaTable)LuaSvr.mainState.doFile("main");

        (main["init"] as LuaFunction).call();

        (main["uodate"] as LuaFunction).call();
    }


   
}
