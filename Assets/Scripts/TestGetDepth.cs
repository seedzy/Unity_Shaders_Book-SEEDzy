using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
//[ExecuteInEditMode]
public class TestGetDepth : MonoBehaviour
{
    CommandBuffer cmds;
    //public Material DiffuseMat;
    public Camera cam;
    //public RenderTexture retss;
    RenderTexture ret;
    MeshRenderer renderer;
    void Start()
    {
        
    }
    private void OnEnable()
    {


    }
    // Update is called once per frame
    void Update()
    {
        
    }

    void OnClearn(Camera cam) {
        if(cmds!=null)
           cam.RemoveAllCommandBuffers();
    }

    private void OnWillRenderObject()
    {
        cmds = new CommandBuffer();
        //cmds.name = "blitss";
        //renderer = this.GetComponent<MeshRenderer>();

        // int Temp = Shader.PropertyToID("_SoloTexture");
        // cmds.GetTemporaryRT(Temp, -1, -1, 0, FilterMode.Bilinear,RenderTextureFormat.RHalf);
        // if (cmds != null)
        //     OnClearn(cam);
        //
        // cmds.Blit(BuiltinRenderTextureType.Depth,Temp);
        
        cmds.SetGlobalTexture("_DepthTex", BuiltinRenderTextureType.Depth);
        cam.AddCommandBuffer(CameraEvent.AfterDepthTexture, cmds);
        //ret = RenderTexture.GetTemporary(Screen.width, Screen.height, 16, RenderTextureFormat.ARGB32);
        //cmds.SetRenderTarget(ret);
        //cmds.ClearRenderTarget(true, true, Color.gray);
        //cmds.DrawRenderer(renderer, DiffuseMat,0);
        //retss = ret;

        //Shader.SetGlobalTexture("_Textures", ret);
        /*
        cmds.Blit(BuiltinRenderTextureType.CurrentActive, Temp);
        cmds.SetGlobalTexture("_Textures", Temp);
        cam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmds);
        */
        
        


    }

    private void OnPreRender()
    {
        Debug.Log("OnPreRender");
    }
    private void OnPostRender()
    {
        Debug.Log("OnPostRender");
    }
}

