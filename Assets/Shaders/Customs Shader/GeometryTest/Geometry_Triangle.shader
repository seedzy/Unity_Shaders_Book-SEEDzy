﻿Shader "SEEDzy/Custom/Geometry_Triangle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GrassCol("三角形颜色", Color) = (1,1,1,1)
        _GrassButtomCol("三角形底部颜色", Color) = (1,1,1,1)
        _GrassColOffset("三角形颜色偏移",Range(0, 5)) = 1
        
        _GrassHei("三角形高度", float) = 1
        _GrassHeiOffset("三角形高度偏差", float) = 0.1
        _GrassWid("三角形宽度", Range(0, 1)) = 1
        _GrassBend("弯曲程度", Range(0, 1)) = 1
        _GrassAmount("密度", Range(0, 10)) = 5

        _WindMap("摇晃法线贴图", 2D) = "white" {}
        _WindFrequency("摇晃频率", vector) = (1, 1, 0,0)
        _WindStrength("摇晃强度", float) = 1
        
        _Test("test", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #define segment 3

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _GrassHei;
            fixed4 _GrassCol;
            fixed4 _GroundCol;
            float _GrassWid;
            fixed4 _GrassButtomCol;
            float _GrassColOffset;
            float _GrassBend;
            float _GrassAmount;
            float _GrassHeiOffset;
            float _Test;

            sampler2D _WindMap;
            float4 _WindMap_ST;

            float2 _WindFrequency;

            float _WindStrength;


            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 tangent : TEXCOORD3;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD2;
            };



            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }


            float rand(float3 co)
	        {
		        return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	        }
            
            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);

                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
                    t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
                    t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
                );
            }



            g2f PerTriangle(float3 pos,float2 uv)
            {
                g2f o;
                o.vertex = UnityObjectToClipPos(pos);
                o.uv = uv;
                return  o;
            }
            
            //设置单次操作最大顶点输出数，尽量低于20
            [maxvertexcount(30)]
            void geom(point v2g input,inout TriangleStream<g2f> triStream)
            {
                //float3 pos = input[0].vertex.xyz;

                /////////////////////////////////////////////////////////////////////////////////////
                
                
                /////////////////////////////////////////////////////////////////////////////////////



                
                // float3 bnormal = cross(input[0].normal,input[0].tangent) * input[0].tangent.w;
                //
                // //切线空间转模型
                // float3x3 tangentToObject =
                // float3x3(
                //     input[0].tangent.x, bnormal.x, input[0].normal.x,
                //     input[0].tangent.y, bnormal.y, input[0].normal.y,
                //     input[0].tangent.z, bnormal.z, input[0].normal.z
                // );

                //float3 worldPos = mul(unity_ObjectToWorld, mul(tangentToObject, float4(pos.xyz, 1));

                float4 randPos[10];
                // for(int i = 0; i< 10; i++)
                // {
                //     randPos[i].x = rand(pos.xxx + float3(1, 1, 1) * i);
                //     randPos[i].y = rand(pos.yyy + float3(1, 1, 1) * i);
                //     randPos[i].z = rand(pos.zzz + float3(1, 1, 1) * i);
                //     //距离
                //     randPos[i].w = 0.5 * _GrassAmount - rand(randPos[i].xyz) * _GrassAmount;
                //     
                //     randPos[i].xyz = normalize(randPos[i].xyz);
                //     randPos[i].y = 0;
                // }

                for(int i = 0; i< 10; i++)
                {
                    //根据三角形位置生成一个随机旋转矩阵
                    float3x3 faceRotationMatrix = AngleAxis3x3(rand(randPos[i].xyz) * UNITY_TWO_PI,float3(0, 1, 0));

                    float3x3 bendMatrix = AngleAxis3x3(rand(randPos[i].zyx) * UNITY_TWO_PI * 0.5 * _GrassBend, float3(1, 0, 0));

                    //--------------------------------------------------摇晃---------------------------------------------------------------------------
                    //
                    float3 worldPos = mul(unity_ObjectToWorld,  float4(randPos[i].xyz, 1));
                    //应用图片偏移缩放
                    //float2 uv = TRANSFORM_TEX(worldPos.xz, _WindMap) + _WindFrequency * _Time.y;
                    //基于模型空间坐标采样
                    //float2 windSample = (tex2Dlod(_WindMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;

                    float dirZ = sin(worldPos.x * _Test + _Time.y * _WindFrequency.y);
                    dirZ = sin(worldPos.x);
                    
                    //根据采样构建偏移方向
                    //float3 wind = normalize(float3(windSample.x, windSample.y, 0));
                    //float3 wind = normalize(float3(dirZ, 0, 0));
                    
                    //生成摇晃旋转矩阵
                    float3x3 windRotation = AngleAxis3x3(UNITY_PI * dirZ * _WindStrength, float3(1, 0, 0));
                    //-----------------------------------------------------------------------------------------------------------------------------
                    
                    //合并矩阵，先旋转再转换，顺序不能错
                    float3x3 tranRotaMatrix = mul(mul(windRotation, faceRotationMatrix), bendMatrix);
                    //float3x3 tranRotaMatrix = mul(faceRotationMatrix, bendMatrix);
                    // //创建一个没有不参与摇晃的矩阵用于三角形的两个基准点
                    // float3x3 transformationMatrixFacing = mul(tangentToObject, faceRotationMatrix);

                    //tranRotaMatrix = mul(tranRotaMatrix,
                    
                    //随机一个高度
                    float randHei = rand(randPos[i].yzw);

                    float3 leftButtomPos = randPos[i].xyz * randPos[i].w + pos + mul(faceRotationMatrix, float3(_GrassWid,0,0));
                    float3 rightButtomPos = randPos[i].xyz * randPos[i].w + pos + mul(faceRotationMatrix, float3(-_GrassWid,0,0));
                    float3 topPos = randPos[i].xyz * randPos[i].w + pos + mul(tranRotaMatrix, float3(0, _GrassHei * (randHei * _GrassHeiOffset + 1), 0));

                    triStream.Append(PerTriangle(leftButtomPos, float2(0, 0)));
                    triStream.Append(PerTriangle(rightButtomPos, float2(1, 0)));
                    triStream.Append(PerTriangle(topPos, float2(0.5,1)));
                    
                    triStream.RestartStrip();
                }

            
            }

            fixed4 frag (g2f i) : SV_Target
            {
                float offset = smoothstep(0, _GrassColOffset,i.uv.y);
                fixed3 finCol = offset* _GrassCol + (1 - offset) * _GrassButtomCol;
                return fixed4(finCol.rgb, 1);
            }
            ENDCG
        }
    }
}