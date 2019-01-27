using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
public class BuildAssetBundle 
{

    public static Dictionary<string, string> allbundlesName = new Dictionary<string, string>();

    static Dictionary<string, string> m_assetScenes = new Dictionary<string, string>();
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

    [MenuItem("Tools/BuildScence")]
    static void BuildScenceAsset()
    {
        string targetPath = Application.dataPath + "/Scene";
        GetAssetsRecursively(targetPath, "*.unity", "sence/", null, "bundle",ref m_assetScenes);
        SetAssetbundleNameDenpency(m_assetScenes, new string[] { ".shader" }, "shader/");
        SetAssetbundleNameDenpency(m_assetScenes, new string[] { ".mat" }, "Materil/");
        SetAssetbundleNameDenpency(m_assetScenes, new string[] { ".jpg" }, "Texture/");
        SetAssetbundleNameDenpency(m_assetScenes, new string[] { ".png" }, "Texture/");
        SetAssetBundleName(m_assetScenes);
        BuildAssetBundles(BuildTarget.StandaloneWindows64);
    }

    [MenuItem("Tools/Build Character")]
    static void BuildCharacterAsset()
    {
        string targetBuildPath = Application.dataPath + "/AssetBundleFloder/Character";
        GetAssetsRecursively(targetBuildPath , "*.prefab","ui/", null,"bundle",ref allbundlesName);
        SetAssetbundleNameDenpency(allbundlesName,new string[] { ".shader" }, "shader/");
        SetAssetbundleNameDenpency(allbundlesName, new string[] { ".mat" }, "Materil/");
        SetAssetbundleNameDenpency(allbundlesName, new string[] { ".jpg" }, "Texture/");
        SetAssetbundleNameDenpency(allbundlesName, new string[] { ".png" }, "Texture/");
        SetAssetBundleName(allbundlesName);
        BuildAssetBundles(BuildTarget.StandaloneWindows64);
        //AssetDatabase.get
    }

    /// <summary>
    /// 获取所有的bundle资源的绝对路径
    /// </summary>
    /// <param name="srcFolder">查找的文件路径</param>
    /// <param name="searchPattern">查找文件的类型</param>
    /// <param name="dstFolder">bundle文件的分类文件夹</param>
    /// <param name="prefix">前缀</param>
    /// <param name="suffix">后缀</param>
    /// <param name="assets">所有资源的路径</param>
   static void GetAssetsRecursively(string srcFolder,string searchPattern, string dstFolder, string prefix, string suffix, ref Dictionary<string, string> assets)
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
                Debug.Log(dstFile);
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

    /// <summary>
    /// 设置所有文件的bundle名字
    /// </summary>
    /// <param name="assets"></param>
    static void SetAssetBundleName(Dictionary<string, string> assets)
    {

        AssetImporter importer = null;
        foreach (KeyValuePair<string,string> item in assets)
        {
            string tempstring = StandardlizePath(item.Key);
           // Debug.Log(item.Key);
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

    /// <summary>
    /// 设置所有打包文件的依赖文件
    /// </summary>
    /// <param name="assets"></param>
    /// <param name="depFormat"></param>
    /// <param name="depPath"></param>
    /// <param name="bPrefix"></param>
    static void SetAssetbundleNameDenpency(Dictionary<string,string> assets,string[] depFormat,string depPath)
    {
        AssetImporter import = null;

        foreach (KeyValuePair<string,string> item in assets)
        {
            string temp = "Assets" + item.Key.Substring(Application.dataPath.Length);
           // Debug.Log(temp);//Debug.Log(dependencies);
            string[] dependencies = AssetDatabase.GetDependencies("Assets" + item.Key.Substring(Application.dataPath.Length));
            //Debug.Log(dependencies);
            foreach (string sdep in dependencies)
            {
               // Debug.Log("dependencies :"+sdep);
                foreach (var format in depFormat)
                {
                    if (sdep.EndsWith(format))
                    {
                       
                        import = AssetImporter.GetAtPath(sdep);
                        if (import == null) return;
                       // Debug.Log(string.Format("{0}{1}.bundle", depPath, Path.GetFileNameWithoutExtension(sdep.ToLower())));
                        string bundleName = string.Format("{0}{1}.bundle", depPath, Path.GetFileNameWithoutExtension(sdep.ToLower()));

                        if (import != null)
                        {
                            Debug.Log(string.Format("{0}:{1}", format, bundleName));
                            import.assetBundleName = bundleName;
                            
                        }
                    }
                }
            }
        }
    }

    /// <summary>
    /// 打包所有的bundle
    /// </summary>
    /// <param name="target"></param>
    /// <param name="options"></param>
    static void BuildAssetBundles(BuildTarget target, BuildAssetBundleOptions options = BuildAssetBundleOptions.DeterministicAssetBundle | BuildAssetBundleOptions.ChunkBasedCompression)
    {
        string dir = GetBundleSaveDir(target);

        Debug.Log(dir);
        Directory.CreateDirectory(Path.GetDirectoryName(dir));

        if (!Directory.Exists(dir))
            Debug.LogError("director is not exsist"+dir);
        BuildPipeline.BuildAssetBundles(dir, options,target);
        SaveDependency();

    }


    public static void SaveDependency()
    {
        string dir = GetBundleSaveDir(BuildTarget.StandaloneWindows64);
        //Debug.Log(dir.TrimEnd('/'));
        string depfile = dir.Substring(dir.TrimEnd('/').LastIndexOf("/") + 1);
        //Debug.Log(depfile.TrimEnd('/'));
        string path = GetBundleSavePath(BuildTarget.StandaloneWindows64, depfile.TrimEnd('/'));
       // Debug.Log(path);
        AssetBundle ab = AssetBundle.LoadFromFile(path);

        AssetBundleManifest mainfest = (AssetBundleManifest)ab.LoadAsset("AssetBundleManifest");

        ab.Unload(false);

        //保存所有的依赖文件
        Dictionary<string, List<string>> dic = new Dictionary<string, List<string>>();

        LoadOldDependency(BuildTarget.StandaloneWindows64, dic);

        foreach (string asset in mainfest.GetAllAssetBundles())
        {
            //Debug.Log("asset:"+asset);
            List<string> list = new List<string>();
            string[] deps = mainfest.GetDirectDependencies(asset); //获取每一个对象的直接依赖
            foreach (string dep in deps)
            {
               // Debug.Log("dep:"+dep);
                list.Add(dep);
            }
            //去重
            if (deps.Length > 0)
                dic[asset] = list;
            else if (dic.ContainsKey(asset))
                dic.Remove(asset);
        }

        WriteDependenceConfig(BuildTarget.StandaloneWindows64,dic);

    }

    static void LoadOldDependency(BuildTarget target, Dictionary<string, List<string>> dic)
    {
        string dataPath = GetBundleSavePath(target, "config/dependency");
        if (!File.Exists(dataPath))
        {
            return;
        }

        FileStream fs = new FileStream(dataPath, FileMode.Open, FileAccess.Read);
        BinaryReader br = new BinaryReader(fs);

        int size = br.ReadInt32();
        string resname;
        string textureBundleName;

        for (int i = 0; i < size; i++)
        {
            resname = br.ReadString();
            int count = br.ReadInt32();
            if (!dic.ContainsKey(resname))
                dic[resname] = new List<string>();
            for (int j = 0; j < count; ++j)
            {
                textureBundleName = br.ReadString();
                dic[resname].Add(textureBundleName);
            }
        }
        br.Close();
        fs.Close();
    }

    static void WriteDependenceConfig(BuildTarget target, Dictionary<string, List<string>> m_Denpendcies)
    {
        string fileName = GetBundleSaveDir(target) + "config/dependency";

        Directory.CreateDirectory(Path.GetDirectoryName(fileName));

        FileStream fs = new FileStream(fileName,FileMode.Create,FileAccess.ReadWrite);

        BinaryWriter w = new BinaryWriter(fs);

        w.Write(m_Denpendcies.Count);

        foreach (KeyValuePair<string,List<string>> item in m_Denpendcies)
        {
            w.Write(item.Key);
            w.Write(item.Value.Count);
            foreach (string s in item.Value)
            {
                w.Write(s);
            }
        }

        w.Close();
        fs.Close();

        if (true)
        {
            using (StreamWriter sw = File.CreateText(fileName + "text"))
            {
                sw.WriteLine("size = " + m_Denpendcies.Count);

                foreach (KeyValuePair<string, List<string>> pair in m_Denpendcies)
                {
                    sw.WriteLine(pair.Key);
                    sw.WriteLine(pair.Value.Count);
                    foreach (string s in pair.Value)
                    {
                        sw.WriteLine(s);
                    }
                }
                sw.Close();
            }

        }

    }

    public static string GetBundleSavePath(BuildTarget target,string relativePath)
    {
        string path = string.Empty;
        switch (target)
        {
            case BuildTarget.Android:
                path = string.Format("{0}/../../{1}/{2}", Application.dataPath, GetPlatfomrPath(target), relativePath);

                break;
            case BuildTarget.StandaloneWindows64:
                path = string.Format("{0}/../../{1}/{2}", Application.dataPath, GetPlatfomrPath(target), relativePath);
                break;
            case BuildTarget.iOS:
                path = string.Format("{0}/../../{1}/{2}", Application.dataPath, GetPlatfomrPath(target), relativePath);
                break;
        }
        return path;
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

    public  static string GetPlatfomrPath(BuildTarget target)
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
