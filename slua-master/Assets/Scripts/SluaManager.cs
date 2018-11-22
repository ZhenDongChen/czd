using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SLua;
using System.IO;

public class SluaManager : MonoBehaviour
{
   

    void Start()
    {
        Sluamr.instance.Init();
    }
 
}
