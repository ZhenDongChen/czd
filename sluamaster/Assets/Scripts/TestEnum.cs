using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public enum testTemp
{
    temp1,
    temp2,
    temp3
}

public class TestEnum : MonoBehaviour
{

    // Use this for initialization
    void Start()
    {
        Commoand temp = new Commoand();
        temp.ExcuteType(testTemp.temp1);


        Debug.Log(testTemp.temp1);

    }

    // Update is called once per frame
    void Update()
    {

    }
}
