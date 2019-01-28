using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System;



class ResourceLoadTask
{
    public uint Id;
    public int LoadType;
    public string Path;
    public Action<UnityEngine.Object> Actions;
    public List<string> Dependencies = new List<string>();

    public void Reset()
    {
        Id = 0;
        Path = string.Empty;
        Actions = null;
        Dependencies = null;
    }
}

class AssetLoadTask
{
    public string task;
    public AssetBundle ab;
}


class CachedResource
{
    public UnityEngine.Object Obj;
    public float LastUseTime;
}

public class AssetBundleLoader 
{

    private const string m_dependencyPath = "config/dependency";

    private const int m_DefaultMaxTaskCount = 50;
    public static AssetBundleLoader Instance = new AssetBundleLoader();

    private readonly Dictionary<string, CachedResource> _generalCachedBundles = new Dictionary<string, CachedResource>(); //一般策略模式

    private readonly Dictionary<string, List<string>> m_Dependencies = new Dictionary<string, List<string>>();

    private readonly Dictionary<string, AssetBundle> _assetLoaderCachedBundles = new Dictionary<string, AssetBundle>();





    private void LoadDependencyConfig(string path)
    {
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
            for (int j = 0; j < count; ++j)
            {
                depname = br.ReadString();
                m_Dependencies[resname].Add(depname);
            }
        }
        br.Close();
        fs.Close();
    }

    public GameObject LoadUIAssetBundle(string assetbundleName,Action complete )
    {
        string assetBundlePath = GetApplicationPath() + "ui/" + assetbundleName + ".bundle";
        return  LoadAssetBundle(assetBundlePath, assetbundleName, complete); 
    }

    private IEnumerator LoadScene(string secenceName,Action OnScenceOver)
    {
        string assetBundlePath = GetApplicationPath() + "sence/" + secenceName + ".bundle";
        if (!File.Exists(assetBundlePath))
        {
            Debug.Log("not Exists File");
            yield return null ;
        }

        LoadDependencyConfig(assetBundlePath);
        List<string> assetbundleDepencies = new List<string>();
        //todo:这一块要遍历字典，out是空的
        LoadBundleAllDenpencies("sence/" + secenceName.ToLower() + ".bundle", assetbundleDepencies);
        DoTask(assetbundleDepencies, OnScenceOver);

        AssetBundleCreateRequest temptarget = AssetBundle.LoadFromFileAsync(assetBundlePath);

        var bundle = temptarget.assetBundle;

        AsyncOperation asy = UnityEngine.SceneManagement.SceneManager.LoadSceneAsync(secenceName, UnityEngine.SceneManagement.LoadSceneMode.Single);
        

    }

    public GameObject LoadCharacterBundle()
    {
        return null;
    }

    public void  LoadSceneBundle(string sceneName,Action action)
    {
        SluaManager.Instance.StartCoroutine(LoadScene(sceneName, action));
    }


    public int AddTask(string file,Action<UnityEngine.Object> action )
    {

        CachedResource cacheResource;
        if (_generalCachedBundles.TryGetValue(file, out cacheResource))
        {
            cacheResource.LastUseTime = Time.realtimeSinceStartup;

            action(cacheResource.Obj);
            return 0;
        }
        return 1;
    }



    public GameObject LoadAssetBundle(string assetbundleNamePath,string bundlename,Action complete)
    {
      
        if (!File.Exists(assetbundleNamePath))
        {
            Debug.Log("not Exists File");
            return null;
        }
        LoadDependencyConfig(m_dependencyPath);
        List<string> assetbundleDepencies = new List<string>();
        //todo:这一块要遍历字典，out是空的
        LoadBundleAllDenpencies("ui/" + bundlename + ".bundle",  assetbundleDepencies);
        DoTask(assetbundleDepencies, complete);

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

    void DoTask(List<string> denpencies,Action complete)
    {
        foreach (string item in denpencies)
        {
            SluaManager.Instance.StartCoroutine(LoadFromFileAsync(item));
        }
        if (complete != null)
        {
            complete();
        }
       // Debug.Log("complete Load");
        
    }

    IEnumerator LoadFromFileAsync(string path)
    {
        string assetbundlePath = GetApplicationPath() + path;

        if (!_assetLoaderCachedBundles.ContainsKey(path))
        {
            AssetBundleCreateRequest assetbundle = AssetBundle.LoadFromFileAsync(assetbundlePath);
            //WWW www = new WWW(assetbundlePath);
         
            _assetLoaderCachedBundles.Add(path, assetbundle.assetBundle);
            yield return assetbundle;
        }
     
        //UnityEngine.Object obj = null;
        //if (assetbundle.isDone)
        //{
        //    var objs = assetbundle.assetBundle.LoadAllAssets();
        //    if (objs.Length > 0)
        //    {
        //        obj = objs[0];
        //    }
        //}

        //  assetbundle.assetBundle.Unload(true);
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
