Shader "Unity Shaders Book/Chapter 10/SEEDzy/Reflection" 
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        //反射颜色
        _ReflectColor("Reflect Color",Color) = (1,1,1,1)
        //反射量
        _ReflectAmount("Reflect Amount",Range(0,1)) = 1
        //模拟环境映射纹理
        _CubeMap("Reflection CubeMap",Cube) = "_SkyBox"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            #pragma multi_compile_fwdbase	
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldReflectDir : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
                
            };

            fixed4 _Color;
            fixed4 _ReflectColor;
            float _ReflectAmount;
            samplerCUBE _CubeMap;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                //获得世界空间下视角方向
                float3 worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                //通过视角方向计算反射进入摄像机的光线方向
                o.worldReflectDir = reflect(-worldViewDir,o.worldNormal);
                //计算阴影纹理坐标
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldLightDir, worldNormalDir)) * _Color;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                //使用入射光线方向对CubeMap进行采样
                fixed3 reflect = texCUBE(_CubeMap,i.worldReflectDir).rgb * _ReflectColor.rgb;

                return fixed4(ambient + lerp(diffuse,reflect,_ReflectAmount),1);

            }
            ENDCG
        }
    }
}
