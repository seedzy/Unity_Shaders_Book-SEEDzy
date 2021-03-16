Shader "Unity Shaders Book/Chapter 11/SEEDzy/BillBoarding"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Main Tint", Color) = (1,1,1,1)
        _VerticalBillBoarding("修改广告牌的朝向，是表面法线面向摄像机还是保持z轴不变的朝向摄像机",Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "DisableBatching" = "True"}

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Zwrite off
            Cull off
            Blend SrcAlpha oneMinusSrcAlpha
        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_ST;
            //修改广告牌的朝向，是表面法线面向摄像机还是保持z轴不变的朝向摄像机
            float _VerticalBillBoarding;
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };



            v2f vert (appdata v)
            {
                v2f o;
                //摄像机模型空间坐标
                float3 camObjPos = mul(unity_WorldToObject,_WorldSpaceCameraPos);
                //模型空间下法线应该处于的方向
                float3 normalObjDir = camObjPos - v.vertex;

                normalObjDir.y *= _VerticalBillBoarding;

                normalObjDir = normalize(normalObjDir);

                fixed3 upDir;

                //调整up的朝向，当法线朝向y正方向时若up方向也为y正方向叉乘会出错，因此要换一个方向
                if(abs(normalObjDir.y) > 0.999)
                {
                    upDir = fixed3(0,0,1);
                }
                else
                    upDir = fixed3(0,1,0);

                
                

                
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                return col;
            }
            ENDCG
        }
    }
}
