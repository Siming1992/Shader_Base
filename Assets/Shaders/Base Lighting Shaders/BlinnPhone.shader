
// Blinn模型没有使用反射方向，而是引入一个新的失量h，h通过视角方向 v 和 光照方向 l 相加后在归一化得到
// h = v + l / ｜v + l｜
// Blinn模型计算高光反射公式如下 C_Specular = (C_Light * M_Specular) * max (0,dot(n , h)) m_gloss

Shader"BaseLight/BlinnPhone"
{
    Properties{
        _Diffuse("Diffuse" , Color) = (1,1,1,1)
        _Specular("Specular" , Color) = (1,1,1,1)
        _Gloss("Gloss" , Range(8 , 255)) = 20
    }
    SubShader{
        Pass{
            Tags{
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "Lighting.cginc"
            
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
            v2f vert(a2v v)
            {
                v2f o ;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
				fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                
                //blinn         C_Specular = (C_Light * M_Specular) * max (0, dot(n , h)) m_gloss
                //高光反射模型    C_specular = (C_light * M_specular) * max (0, dot(v * r)) m_gloss
                //fixed3 reflectDir = normalize(reflect(-worldLightDir,i.worldNormal));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(mul(worldNormal , halfDir)),_Gloss);
                
                fixed3 color = ambient + diffuse + specular;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}