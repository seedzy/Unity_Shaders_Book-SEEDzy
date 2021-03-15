Shader "SEEDzy/Build PipeLine/Cartoon_Sea"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("Normal Map",2D) = "white" {}
        _Color("Color Tint",Color) = (1,1,1,1)
        _Alpha("Alpha",Range(0,100)) = 1
        _FelPow("菲涅尔强度",Range(0,100)) = 1
        _DiffusePow("漫反射强度",Range(0,1)) = 0.5
    	_BumpScale("凹凸程度",Range(0,1)) = 0.1
    }
    SubShader
    {
        //renderType：? ignoreProjector：当前shader不会受到投影器影响(Projectors)
        //通常使用透明度测试都应使用这三个标签
        Tags {"LightMode" = "ForwardBase" "RenderType"="Transparent" "Queue" = "Transparent" "previewType" = "shpere"}
        //该pass写入模型深度信息
        Pass
        {
            ZWrite On
            //设置颜色通道谢掩码
            ColorMask 0
        }
        
        
        
        Pass
        {
        	//Tags {"RenderType" = "Opaque" }
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha 
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            //色调
            fixed4 _Color;

            float _FelPow;
            float _DiffusePow;
            float _BumpScale;
            

            float _Alpha;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD1;
                float4 projPos : TEXCOORD2;
                float3 objPos : TEXCOORD3;
                float4 tangent : TEXCOORD4;
                UNITY_FOG_COORDS(5)
                UNITY_VERTEX_OUTPUT_STEREO
            };



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.objPos = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                
                o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.uv.xy * _BumpTex_ST.xy + _BumpTex_ST.zw * _Time.y;
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                //将裁剪空间坐标点映射至 (0 , w)
                o.projPos = ComputeScreenPos(o.pos);
                //经过这一步projPos变量最终存储范围在(0,w)的xy分量和存储顶点在view空间下深度值的z分量
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }

            //渐变色生成：https://sp4ghet.github.io/grad/
            fixed4 cosine_gradient(float x,  fixed4 phase, fixed4 amp, fixed4 freq, fixed4 offset){
                const float TAU = 2. * 3.14159265;
  				phase *= TAU;
  				x *= TAU;

  				return fixed4(
    				offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
    				offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
    				offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
    				offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
  				);
			}
            
            //获取摄像机深度纹理，变量名不能错啊！！！！！
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //渐变色相关----还不能放函数外初始化。。。。。
                const fixed4 phases = fixed4(0.28, 0.50, 0.07, 0.);
		        const fixed4 amplitudes = fixed4(4.02, 0.34, 0.65, 0.);
		        const fixed4 frequencies = fixed4(0.00, 0.48, 0.08, 0.);
		        const fixed4 offsets = fixed4(0.00, 0.16, 0.00, 0.);
                
                
                //通过摄像机深度纹理获得顶点深度
                //float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTex,i.projPos).r);
                //要解决部分平台兼容可使用如下
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos)));

                fixed depth_dif = saturate((sceneZ - i.projPos.z)/_Alpha);
                
                fixed4 gradientCol = cosine_gradient(1 - depth_dif,phases,amplitudes,frequencies,offsets);
                gradientCol = saturate(gradientCol);



            	
                fixed3 worldTangent = UnityObjectToWorldDir(i.tangent);
                fixed3 worldNormal = UnityObjectToWorldNormal(i.normal);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * i.tangent.w;
                float3 worldPos = mul(unity_ObjectToWorld,i.objPos);

            	float3 TtoW0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
				float3 TtoW1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
				float3 TtoW2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);
                // Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpTex, i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
				// Transform the narmal from tangent space to world space
				bump = half3(dot(TtoW0.xyz, bump), dot(TtoW1.xyz, bump), dot(TtoW2.xyz, bump));
                
                fixed3 worldNormalDir = normalize(worldNormal);
                float3 worldViewDir = -normalize(UnityWorldSpaceViewDir(worldPos));
                half3 worldReflectDir = reflect(worldViewDir,bump);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                
                

                //水面反射
                fixed4 reflectColHDR = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0,worldReflectDir);
                //将天空盒的HDR转常规RGB，如果有的话
                //fixed3 reflectCol = DecodeHDR(reflectColHDR,unity_SpecCube0_HDR);
                //漫反射
                fixed3 diffuse = _LightColor0 * (0.5 * dot(worldLightDir,bump) + 0.5) * _DiffusePow;
                
                //菲涅尔
				float f0 = 0.02;
                
    			float vReflect = f0 + (1-f0) * pow((1 - dot(-worldViewDir,bump)),_FelPow);
				vReflect = saturate(vReflect * 2.0);
    
				
                


                col.rgb = col.rgb * gradientCol.rgb;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                col.rgb = lerp(col , reflectColHDR , vReflect);
                
                return fixed4(col.rgb + diffuse, depth_dif);
            }
            ENDCG
        }
    }
}
