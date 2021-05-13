﻿Shader "SEEDzy/Custom/ParallaxCloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_BumpMap ("视差图", 2D) = "white" {}
        _HeightOffset("Hei", float) = 0.15
        _stepLayers("层数", Range(0, 32)) = 16
        _Alpha("A", Range(0,1)) = 0.5
        _Color("color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent-50" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            
            CGPROGRAM
            #define UNTIY_PASS_FORWARDBASE
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdbase
            #pragma target 3.0

            sampler2D _MainTex;
            float4 _MainTex_ST;
            // sampler2D _BumpMap;
            // float4 _BumpMap_ST;
            float _HeightOffset;
            float _StepLayers;
            float _Alpha;
            fixed4 _Color;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 tangentViewDir : TEXCOORD2;
                float3 normalDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                
                float4 pos : SV_POSITION;
            };



            v2f vert (appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex) + float2(frac(_Time.y * 0.1), 0);
                o.uv2 = v.texcoord;
                TANGENT_SPACE_ROTATION;
                o.tangentViewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                
                return o;
            }

            float4 frag (v2f i) : COLOR
            {
                float3 tangentViewDir = normalize(i.tangentViewDir);
                //干嘛的？
                tangentViewDir.xy *= _HeightOffset;
                
                //为什么能抗狗牙？
                tangentViewDir.z += 0.4;
                
                //这又是要干嘛
                float3 uv = float3(i.uv, 0);
                float3 uv2 = float3(i.uv2, 0);
                // sample the texture
                float4 MainCol = tex2D(_MainTex, uv2.xy);
                
                //层间距
                float3 minOffset = tangentViewDir / (tangentViewDir.z * _StepLayers);
                
                float finiNoise = tex2D(_MainTex, uv.xy).r * MainCol.r;
                
                float3 pre_uv = uv;

                
                
                while (finiNoise > uv.z)
                {
                    uv += minOffset;
                
                    finiNoise = tex2Dlod(_MainTex, float4(uv.xy, 0 ,0)).r * MainCol.r;
                 }
                
                float d1 = finiNoise - uv.z;
                float d2 = finiNoise - pre_uv.z;
                float w = d1 / (d1 - d2 + 0.00000001);
                uv = lerp(uv, pre_uv, w);
                half4 resultColor = tex2D(_MainTex, uv.xy) * MainCol;

                half rangClt = MainCol.a * resultColor.r + _Alpha * 0.75;
                half alpha = abs(smoothstep(rangClt, _Alpha, 1.0));
                alpha = alpha * alpha * alpha * alpha * alpha;
                return half4(resultColor.rgb * _Color.rgb * _LightColor0.rgb, alpha);
            }
            ENDCG
        }
    }
}