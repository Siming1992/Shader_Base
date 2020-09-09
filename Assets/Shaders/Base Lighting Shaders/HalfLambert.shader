
// 广义半兰伯特光照模型 C_diffuse = (C_light * M_diffuse) * (a（ n * l）+ b);
// 绝大多数情况下a.b的值均为0。5 ， 即 C_diffuse = (C_light * M_diffuse) * (0.5（ n * l）+ 0.5);

Shader"BaseLight/HalfLambert"
{
    Properties{
        _Diffuse ("Diffuse" , Color) = (1,1,1,1) 
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
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL; 
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;  
            };
            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul((float3x3)unity_ObjectToWorld,v.normal));
                return o;
            }
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed halfLambert = dot(worldLightDir, i.worldNormal) * 0.5f + 0.5f;
                
                fixed3 diffuse = _LightColor0 * _Diffuse *halfLambert;
                fixed3 color = ambient + diffuse;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}