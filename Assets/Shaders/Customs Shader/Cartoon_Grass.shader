Shader "Unlit/Cartoon_Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EffectRadius("角色影响半径",Range(0,10)) = 1
        _EffectStrength("影响强度",float) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _playerPos;
            float _EffectRadius;
            float3 _EffectStrength;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                float4 worldPos = mul(unity_ObjectToWorld,v.vertex);

                //计算玩家和顶点在世界坐标下的距离
                float dis = distance(_playerPos,worldPos);

                //角色的影响程度随距离变化，当距离大于半径时，值被缩放到 1，结果就是无影响，值小于1时值被限制到 > 0,结果是影响逐渐增强
                //节约了一次if判断，妙啊
                float effectPow = 1 - saturate(dis/_EffectRadius);

                //player到顶点的方向向量
                float3 player2VertDir = normalize(worldPos - _playerPos);

                //合成作用力
                float3 effectForce = effectPow * player2VertDir * _EffectStrength;

                //需要加一道限制吗？？？
                //float3 effectForce = clamp(effectPow * player2VertDir * _EffectStrength,-0.8,0.8);
                
              
                
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
