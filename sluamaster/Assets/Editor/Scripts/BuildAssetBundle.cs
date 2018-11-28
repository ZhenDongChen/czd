﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
public class BuildAssetBundle 
{

    public static Dictionary<string, string> allbundlesName = new Dictionary<string, string>();


    public static string StandardlizePath(string path)
    {
        string pathReplace = path.Replace(@"\", @"/");
        string pathLower = pathReplace.ToLower();
        return pathLower;
    }

    [MenuItem("Tools/BuildWindos")]
    static void BuildAssetBundleWindows()
    {
        string targetBuildPath = Application.dataPath + "";
    }

    [MenuItem("Tools/Build Character")]
    static void BuildCharacterAsset()
    {
        string targetBuildPath = Application.dataPath + "/AssetBundleFloder/Character";
        GetAssetsRecursively(targetBuildPath , "*.prefab","ui/", null,"bundle",ref allbundlesName);
        SetAssetBundleName(allbundlesName);
        BuildAssetBundles(BuildTarget.StandaloneWindows64);
        //AssetDatabase.get
    }

    /// <summary>
    /// 
    /// </summary>
   static void GetAssetsRecursively(string srcFolder,string searchPattern, string dstFolder,  string prefix, string suffix, ref Dictionary<string, string> assets)
    {
        string searchFolder = StandardlizePath(srcFolder);
        if (!Directory.Exists(searchFolder))
            return;

        string srcDir = searchFolder;

        DirectoryInfo directoryInfo = new DirectoryInfo(srcFolder);

        FileInfo[] allFiles = directoryInfo.GetFiles();

        string dstFile;

        string[] files = Directory.GetFiles(srcFolder, searchPattern);

        foreach (string item in files)
        {
            string srcFile = StandardlizePath(item);

            if (!File.Exists(srcFile))
                continue;

            if (string.IsNullOrEmpty(prefix))
            {
                dstFile = Path.Combine(dstFolder, string.Format("{0}.{1}", Path.GetFileNameWithoutExtension(srcFile), suffix));
            }
            else
            {
                dstFile = Path.Combine(dstFolder, string.Format("{0}_{1}.{2}", prefix, Path.GetFileNameWithoutExtension(srcFile), suffix));
            }
            dstFile = StandardlizePath(dstFile);
            Debug.Log("Add"+srcFile);
            assets[srcFile] = dstFile;
        }

        string[] dirs = Directory.GetDirectories(searchFolder);
        foreach (string oneDir in dirs)
        {
            GetAssetsRecursively(oneDir, searchPattern, dstFolder, prefix, suffix, ref assets);
        }


    }

    static void SetAssetBundleName(Dictionary<string, string> assets)
    {

        AssetImporter importer = null;
        foreach (KeyValuePair<string,string> item in assets)
        {
            string tempstring = StandardlizePath(item.Key);
            Debug.Log(item.Key);
            if (!File.Exists(tempstring))
            {
                Debug.Log("this file is not exsist "+ item.Key);
                return;
            }
            importer = AssetImporter.GetAtPath("assets" + item.Key.Substring(Application.dataPath.Length));
            if (importer.assetBundleName == null || importer.assetBundleName != item.Value)
            {
                importer.assetBundleName = item.Value;
            }
        }
    }

    static void BuildAssetBundles(BuildTarget target, BuildAssetBundleOptions options = BuildAssetBundleOptions.DeterministicAssetBundle | BuildAssetBundleOptions.ChunkBasedCompression)
    {
        string dir = GetBundleSaveDir(target);

        Directory.CreateDirectory(Path.GetDirectoryName(dir));

        if (!Directory.Exists(dir))
            Debug.LogError("director is not exsist"+dir);
        BuildPipeline.BuildAssetBundles(dir, options,target);

    }

    public static string GetBundleSaveDir(BuildTarget target)
    {
        string path = string.Empty;
        switch (target)
        {
            case BuildTarget.Android:
                path = string.Format("{0}/../../{1}/", Application.dataPath, GetPlatfomrPath(target));
                break;
            case BuildTarget.StandaloneWindows64:
                path = string.Format("{0}/../../{1}/", Application.dataPath, GetPlatfomrPath(target));
                break;
            case BuildTarget.iOS:
                path = string.Format("{0}/../../{1}/", Application.dataPath, GetPlatfomrPath(target));
                break;
        }
        return path;

    }

    static string GetPlatfomrPath(BuildTarget target)
    {
        string platformPath = string.Empty;
        switch (target)
        {
            case BuildTarget.Android:
                platformPath = "dist/android";
                break;
            case BuildTarget.iOS:
                platformPath = "dist/ios";
                break;
            default:
                {
                    platformPath = "GameWindows";
                }
                break;
        }
        return platformPath;
    }

}
