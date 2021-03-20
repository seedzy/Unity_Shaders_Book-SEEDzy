using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 继承类用于安全检查
/// </summary>
public class BrightnessSaturationAnd : PostEffectsBase
{
    [Range(0, 3)] public float _brightness = 1;
    [Range(0, 3)] public float _saturation = 1;
    [Range(0, 3)] public float _contrast = 1;
    
    
    public Shader bscShader;
    private Material bscMaterial;

    public Material material
    {
        get
        {
            bscMaterial = CheckShaderAndCreateMaterial(bscShader, bscMaterial);
            return bscMaterial;
        }
    }


/// <summary>
/// 通过Mat处理获取的RT
/// </summary>
/// <param name="src"></param>
/// <param name="dest"></param>
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material)
        {
            material.SetFloat("_Brightness",_brightness);
            material.SetFloat("_Saturation",_saturation);
            material.SetFloat("_Contrast",_contrast);
            Graphics.Blit(src,dest,material);
        }
        else
            Graphics.Blit(src,dest);
    }
}
