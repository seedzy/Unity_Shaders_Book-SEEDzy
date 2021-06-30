Shader "SEEDzy/Custom/SPMCloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_BumpMap ("视差图", 2D) = "white" {}
        _HeightOffset("Hei", float) = 0.15
        _StepLayers("层数", Range(0, 1024)) = 16
        _Alpha("A", Range(0,1)) = 0.5
        [HDR]
        _Color("color", Color) = (1, 1, 1, 1)
        
        _AlphaSwitch("AlphaSwi", Range(-5,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent-50" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HeightOffset;
            float _StepLayers;
            float _Alpha;
            fixed4 _Color;
            float _AlphaSwitch;
            
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
                float4 pos : SV_POSITION;
            };



            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) + float2(frac(_Time.y * 0.1), 0);;
                o.uv2 = v.uv;
                TANGENT_SPACE_ROTATION;
                o.tangentViewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                float3 tangentViewDir = normalize(-i.tangentViewDir);
                //田间偏移比例
                tangentViewDir.xy *= _HeightOffset;
                //
                // //为什么能抗狗牙？
                tangentViewDir.z = abs(tangentViewDir.z) + 0.4;
                
                //这又是要干嘛
                float3 uv = float3(i.uv, 0);
                float3 uv2 = float3(i.uv2, 0);

                //每层高度
                float perHei = 1 / _StepLayers;
                
                // sample the texture
                float4 samplerHei = tex2D(_MainTex, uv2.xy);

                fixed4 finCol = samplerHei;
                
                //每层间UV偏移量
                float2 minOffset = tangentViewDir.xy / (tangentViewDir.z * _StepLayers);

                //用uv.z存储当前层的高度(深度)
                while (samplerHei.r > uv.z)
                {
                    //大于则进入下一层的采样点
                    uv.xy += minOffset;
                
                    //下一次高度为上一层加层高
                    uv.z += perHei;
                
                    samplerHei = tex2Dlod(_MainTex, float4(uv.xy, 0 ,0)) * finCol;
                 }

                fixed4 finiCol = tex2D(_MainTex, uv.xy)* finCol;// * _LightColor0;

                
                return fixed4(finiCol.xyz + _Color, smoothstep(_AlphaSwitch, 1 ,_Alpha * finiCol.r));
            }
            ENDCG
        }
    }
}
