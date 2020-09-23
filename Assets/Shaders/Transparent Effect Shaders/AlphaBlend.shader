
// 透明度混合可以得到真正的半透明效果，他会使当前片元的透明度作为混合银子，与已经存在的颜色缓冲中的颜色进行混合，得到新的颜色。
// 但是，透明度混合需要关闭深度写入，这使得我们要非常小心物体的渲染顺序

Shader"Transparent Effect/AlphaBlend"{
    Properties{
        _Color ("Main Tint" , Color) = (1,1,1,1)
        _MainTex ("Main Tex" , 2D) = "white"{}
        _AlphaScale ("Alpha Scale" , Range(0,1)) = 0.5
    }
    SubShader{
        Tags{
            "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"
        }
        Pass{
            Tags{
                "LightModle" = "ForwardBase"
            }
            Cull Front
            ZWrite Off
            // Blend Off 关闭混合
            // Blend SrcFactor DstFactor 开启混合，并设置混合因子。
            // 源颜色（该片元产生的颜色）会乘以SrcFactor，而目标颜色（已经存在于颜色缓存的颜色）会乘以DstFactor，然后把两者相加在存入颜色缓冲中
            // newDstColor = SrcAlpha * SrcColor + (1 - SrcAlpha) * DstColor
            Blend SrcAlpha OneMinusSrcAlpha  
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            
            #include "Lighting.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaScale;
            
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };
            
            v2f vert(a2v v)
            {
                v2f o ;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld , v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);    
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed4 texColor = tex2D(_MainTex , i.uv);    
                
                fixed3 albedo = texColor.rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal , worldLightDir));
                
                return fixed4(ambient + diffuse , _AlphaScale);
            }
            ENDCG
        }
        
        Pass{
            Tags{
                "LightModle" = "ForwardBase"
            }
            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha  
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            
            #include "Lighting.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaScale;
            
            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };
            
            v2f vert(a2v v)
            {
                v2f o ;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld , v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);    
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed4 texColor = tex2D(_MainTex , i.uv);    
                
                fixed3 albedo = texColor.rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal , worldLightDir));
                
                return fixed4(ambient + diffuse , _AlphaScale);
            }
            ENDCG
        }
    }
}