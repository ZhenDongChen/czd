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

    private List<DirectoryInfo> allTargetDirecotInfos = new List<DirectoryInfo>();
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
        string path = Application.dataPath + "/SluaTestCode/" + name;

        if (File.Exists(path))
        {
            tempStr = File.ReadAllBytes(path);
        }
        return tempStr;
    }
    // Use this for initialization
    void SluaStart()
    {
        string path = Application.dataPath + "/SluaTestCode";
        //DirectoryInfo directorInfo = new DirectoryInfo(path);
        //FileInfo[] targetFileInfo = directorInfo.GetFiles();

        //foreach (FileInfo item in targetFileInfo)
        //{
        //    Debug.Log(item.FullName);
        //}
        //DirectoryInfo[] FileDirectors = directorInfo.GetDirectories();

        //foreach (DirectoryInfo item in FileDirectors)
        //{
        //    Debug.Log(item.FullName);
        //}


       allTargetDirecotInfos =this.GetAllDIrectorsInfo(path);

        for (int i = 0; i < allTargetDirecotInfos.Count; i++)
        {
            Debug.Log(allTargetDirecotInfos[i].FullName);
            if (allTargetDirecotInfos[i].Name== "SluaTestCode")
            {
                FileInfo[] allFileInfos =  allTargetDirecotInfos[i].GetFiles();
                for (int j = 0; j < allFileInfos.Length; j++)
                {
                    if (!allFileInfos[j].Name.Contains(".meta"))
                    {
                        Debug.Log(allFileInfos[j].Name);
                        luaState.doFile(allFileInfos[j].Name);
                    }
                }
               
            }
        }
        luaState.doFile("map_main.lua");

       init =  luaState.getFunction("init");
       update = luaState.getFunction("Update");

      
        



    }

    /// <summary>
    /// 获取目标文件所有的目录的信息
    /// </summary>
    /// <param name="path"></param>
    /// <returns></returns>
    List<DirectoryInfo> GetAllDIrectorsInfo(string path)
    {
        List<DirectoryInfo> allFileDirectors_list = new List<DirectoryInfo>();

        DirectoryInfo temp = new DirectoryInfo(path);

        string targetpath = path + "/..";

        DirectoryInfo targetpathDirectorinfo = new DirectoryInfo(targetpath);

        foreach (DirectoryInfo item in targetpathDirectorinfo.GetDirectories())
        {
            Debug.Log("DirectoryInfo" + item.Name);
            if (item.Name == "SluaTestCode")
            {
                allFileDirectors_list.Add(item);
            }
        }

        DirectoryInfo[] allDirectorInfos = temp.GetDirectories();

        foreach (DirectoryInfo item in allDirectorInfos)
        {
            allFileDirectors_list.Add(item);
        }
        return allFileDirectors_list;
    }




   
}
