Shader "SEEDzy/Build PipeLine/Cartoon_Sea"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("Normal Map",2D) = "white" {}
        _Color("Color Tint",Color) = (1,1,1,1)
        _Alpha("Alpha",Range(0,100)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha 
        
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            //色调
            fixed4 _Color;

            float _Alpha;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(3)
                float4 pos : SV_POSITION;
                float4 projPos : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                //将裁剪空间坐标点映射至 (0 , w)
                o.projPos = ComputeScreenPos(o.pos);
                //经过这一步projPos变量最终存储范围在(0,w)的xy分量和存储顶点在view空间下深度值的z分量
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //通过摄像机深度纹理获得顶点深度
                //float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTex,i.projPos).r);
                //要解决部分平台兼容可使用如下
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos)));
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                fixed depth_dif = saturate((sceneZ - i.projPos.z)/_Alpha);
                
                return fixed4(col.rgb * _Color.rgb, depth_dif);
            }
            ENDCG
        }
    }
}
