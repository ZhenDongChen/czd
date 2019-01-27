using System;
using UnityEngine;

public class Commoand
{



    public virtual void ExcuteType(Enum temp)
    {
        Debug.Log(temp.ToString());
    }
}