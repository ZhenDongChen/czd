using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SLua;
using System.IO;
using System;

public class SluaManager : MonoBehaviour
{

    public static SluaManager Instance;

    public Dictionary<string, List<string>> ttt = new Dictionary<string, List<string>>();
    public Action sceneOver;

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        SluaClass.instance.Init();
        if (SluaClass.instance.init != null)
            SluaClass.instance.init.call();

       

       // List<string> aaa = new List<string>();
       // aaa.Add("aaaa");
       // aaa.Add("bbb");
       // ttt.Add("aaaaa", aaa);

<<<<<<< HEAD
       // List<string> nnn = new List<string>();

       // ttt.TryGetValue("aaaaa", out nnn);

       // foreach (var item in nnn)
       // {
       //     Debug.Log(item);
       // }
       //AssetBundleLoader.Instance.LoadUIAssetBundle("cube1");
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.A))
        {
            SluaClass.instance.Reset();
        }

        if (SluaClass.instance.update != null)
            SluaClass.instance.update.call();
        
           //SluaClass.instance.update.call();
=======

        // AssetBundleLoader.Instance.LoadUIAssetBundle("cube1", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("cube2", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("cube3", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("cube4", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("cube5", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("cube6", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("cube7", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("Athlete", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("Bridge", sceneOver);
        AssetBundleLoader.Instance.LoadUIAssetBundle("pillar", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("Renata", sceneOver);
        //AssetBundleLoader.Instance.LoadUIAssetBundle("Romana", sceneOver);

        //AssetBundleLoader.Instance.LoadSceneBundle("testSlua", sceneOver);
>>>>>>> d9face9b596ea63a2a0dd4ec2e244bc27018ec64
    }

}
