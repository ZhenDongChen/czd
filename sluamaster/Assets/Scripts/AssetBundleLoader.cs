using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System;



class CachedResource
{
    public UnityEngine.Object Obj;
    public float LastUseTime;
}

public class AssetBundleLoader 
{

    private const string m_dependencyPath = "config/dependency";
    public static AssetBundleLoader Instance = new AssetBundleLoader();

    private readonly Dictionary<string, CachedResource> _generalCachedBundles = new Dictionary<string, CachedResource>(); //一般策略模式

    private readonly Dictionary<string, List<string>> m_Dependencies = new Dictionary<string, List<string>>();



    private void LoadDependencyConfig(string path)
    {
        //Util.LogColor("red", "LoadDependencyConfig:" + path);
        string dataPath = GetApplicationPath();
        dataPath = dataPath + "/" + m_dependencyPath;
        if (!File.Exists(dataPath))
        {
            return;
        }

        FileStream fs = new FileStream(dataPath, FileMode.Open, FileAccess.Read);
        BinaryReader br = new BinaryReader(fs);

        int size = br.ReadInt32();
        string resname;
        string depname;

        for (int i = 0; i < size; i++)
        {
            resname = br.ReadString();
            int count = br.ReadInt32();
            if (!m_Dependencies.ContainsKey(resname))
                m_Dependencies[resname] = new List<string>();
            //Debug.Log(sfxname + "  " + count);
            for (int j = 0; j < count; ++j)
            {
                depname = br.ReadString();
                m_Dependencies[resname].Add(depname);
            }
        }
        br.Close();
        fs.Close();
    }

    public GameObject LoadUIAssetBundle(string assetbundleName)
    {
        string assetBundlePath = GetApplicationPath() + "ui/" + assetbundleName + ".bundle";
        return  LoadAssetBundle(assetBundlePath, assetbundleName); 
    }

    public GameObject LoadCharacterBundle()
    {
        return null;
    }

    public GameObject LoadSceneBundle()
    {
        return null;
    }




    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    public GameObject LoadAssetBundle(string assetbundleNamePath,string bundlename)
    {
      
        if (!File.Exists(assetbundleNamePath))
        {
            Debug.Log("not Exists File");
            return null;
        }
        LoadDependencyConfig(m_dependencyPath);
        List<string> assetbundleDepencies = new List<string>();
       // m_Dependencies.TryGetValue("ui/"+bundlename + ".bundle", out assetbundleDepencies);

        //todo:这一块要遍历字典，out是空的
        LoadBundleAllDenpencies("ui/" + bundlename + ".bundle",  assetbundleDepencies);


        foreach (var item in assetbundleDepencies)
        {
            Debug.Log(item);
        }

       // DoTask(assetbundleDepencies);



        AssetBundle temptarget = AssetBundle.LoadFromFile(assetbundleNamePath);

        GameObject targetObject = temptarget.LoadAsset<GameObject>(bundlename);

        GameObject initObjec = GameObject.Instantiate(targetObject) as GameObject;

        return null;
    }

    List<string> LoadBundleAllDenpencies(string bundlename, List<string> allassetbundledenpencies)
    {
        
        List<string> outdengpencies = new List<string>();
        m_Dependencies.TryGetValue(bundlename, out outdengpencies);
       
        if (outdengpencies != null)
        {
            allassetbundledenpencies.AddRange(outdengpencies);
            foreach (var item in outdengpencies)
            {
                LoadBundleAllDenpencies(item, allassetbundledenpencies);
            }
           
        }

        return allassetbundledenpencies;
    }

    void DoTask(List<string> denpencies)
    {
        foreach (string item in denpencies)
        {
            SluaManager.Instance.StartCoroutine(LoadBundleFromWWW(item));
        }
        
    }

    IEnumerator LoadBundleFromWWW(string path)
    {
        string assetbundlePath = GetApplicationPath() + "/" + path;

        AssetBundleCreateRequest assetbundle = AssetBundle.LoadFromFileAsync(assetbundlePath);
        //WWW www = new WWW(assetbundlePath);
        yield return assetbundle;
        UnityEngine.Object obj = null;
        if (assetbundle.isDone)
        {
            var objs = assetbundle.assetBundle.LoadAllAssets();
            if (objs.Length > 0)
            {
                obj = objs[0];
            }
        }

      ///  GameObject objt = GameObject.Instantiate(obj) as GameObject;
    

                
    }



    public GameObject LoadAssetBundleSyn(string assetbundler, Action func)
    {
        //AssetBundle.LoadFromFileAsync();
        return null;
    }


    string GetApplicationPath()
    {
        string path = string.Empty;

        switch (Application.platform)
        {
            case RuntimePlatform.Android:
                path = string.Format("{0}/../../dist/android/", Application.dataPath);
                break;
            case RuntimePlatform.IPhonePlayer:
                path = string.Format("{0}/../../dist/ios/",Application.dataPath);
                break;
            case RuntimePlatform.WindowsPlayer:
            case RuntimePlatform.WindowsEditor:
                path = string.Format("{0}/../../GameWindows/", Application.dataPath);
                break;
        }
        return path;


    }





}
