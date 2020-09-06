
// C_specular = (C_light * M_specular)max(0,v*r) m_gloss
// C_light 入射光线的颜色和强度   M_specular  材质的高光反射系数   v 视角方向    r 反射方向
// r 反射方向可由表面发现n和光源方向l计算得到 r = l - 2 (dot(n,l) * n)     Cg提供了计算反射方向的函数 reflect(i,n) i:入射方向，n:法线方向

Shader"BaseLight/SpecularVertexLevel"
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
                fixed3 color : COLOR;
            };
            v2f vert(a2v v)
            {
                v2f o ;
                o.pos = UnityObjectToClipPos(v.vertex);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                float3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                
                fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(mul(reflectDir,viewDir)),_Gloss);
                
                o.color = ambient + diffuse + specular;
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                return fixed4(i.color,1);
            }
            ENDCG
        }
    }
}