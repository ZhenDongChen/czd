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

        if (SluaClass.instance.update != null)
           SluaClass.instance.update.call();


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
    }

}
