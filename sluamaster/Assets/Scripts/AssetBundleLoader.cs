using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System;

public class AssetBundleLoader 
{


    public static AssetBundleLoader Instance = new AssetBundleLoader();



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

        AssetBundle temptarget = AssetBundle.LoadFromFile(assetbundleNamePath);

        GameObject targetObject = temptarget.LoadAsset<GameObject>(bundlename);

        GameObject initObjec = GameObject.Instantiate(targetObject) as GameObject;

        return initObjec;
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
