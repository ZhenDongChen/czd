using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SLua;
using System.IO;

public class SluaManager : MonoBehaviour
{
   

    void Start()
    {

        

        SluaClass.instance.Init();
        if (SluaClass.instance.init != null)
            SluaClass.instance.init.call();
    }


     void Update()
    {
        if (SluaClass.instance.update != null)
            SluaClass.instance.update.call();
    }
}
