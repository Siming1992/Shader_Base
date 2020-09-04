// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader"BaseLight/DiffuseVertexLevel"
{
    Properties{
        _Diffuse ("Diffuse",Color) = (1,1,1,1)
    }
    SubShader{
        Pass{
            Tags{
                "LightMode" = "ForwardBase"     //只有定义了正确的lightmode，才能得到unity的内置光照变量，比如_LightColor0
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            fixed4 _Diffuse;
            struct a2v {
                float4 vertex : POSITION;   //模型坐标
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;   //裁剪坐标
                fixed3 color : COLOR;
            };
            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rbg * _Diffuse.rbg * saturate(dot(worldNormal,worldLight));
                o.color = ambient + diffuse;
                return o;
            }
            fixed4 frag(v2f i):SV_Target{
                return fixed4(i.color,1.0);
            }
            ENDCG
        }
    }
}