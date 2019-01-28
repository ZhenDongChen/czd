using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SLua;
using System.IO;

public class SluaManager : MonoBehaviour
{

    public static SluaManager Instance;

    public Dictionary<string, List<string>> ttt = new Dictionary<string, List<string>>(); 

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
    }
}
