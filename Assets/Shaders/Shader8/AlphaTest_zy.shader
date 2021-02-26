Shader "Unity Shaders Book/Chapter 8/Alpha Test_zy"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CutOff ("Alpha_CutOff",Range(0,1)) = 0.5
        
        
    }
    SubShader
    {
        //renderType：? ignoreProjector：当前shader不会受到投影器影响(Projectors)
        //通常使用透明度测试都应使用这三个标签
        Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _CutOff;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //模型空间顶点法线转世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //纹理偏移缩放
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //顶点模型空间坐标转世界
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldNormalDir = normalize(i.worldNormal);
                //获得世界空间坐标点到光源处方向
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //alpha剔除
                clip(col.a - _CutOff);
                //反射率？
                //fixed3 albedo
                
                
                return col;
            }
            ENDCG
        }
    }
}
