// 由于法线纹理中存储的法线是切线空间下的方向，因此我们通常有两种选择，一种是在世界空间下进行光照计算，一种是在世界空间下进行光照计算

// 从效率上来说，在法线空间中计算往往要优于在世界空间中计算，因为我们可以在顶点着色器中就完成对光照方向和视角方向的计算，而在世界空间中
// 计算需要先对法线文理进行采样，，所以变换过程需要在片元着色器中实现，这意味着我们要在片元着色器中进行一次矩阵操作

// 从通用角度上来说，在世界空间中计算要优于在法线空间中计算，因为有时我们需要在世界空间下进行一些计算，例如在使用Cubemap进行环境映射时，
// 我们需要使用世界空间下的反射方向对Cubemap进行采样

Shader"BaseTexture/NormalMapTangentSpace"{
    Properties{
        _Color ("Color Tint" , Color) = (1,1,1,1)
        _MainTex ("Main Tex" , 2D) = "white" {}
        // "bump"是unity内置的发现纹理，当没有提供任何法显纹理时，"bump"就对应了模型自带的法线信息
        _BumpMap ("NroMal Map" , 2D) = "bump" {}
        _BumpScale ("Bump Scale" , float) = 1.0
        _Specular ("Specular" , Color) = (1,1,1,1)
        _Gloss ("Gloss" , Range (8.0 , 256)) = 20
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

            fixed4 _Color ;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //tangent类型是float4，因为w分量用来决定切线空间中的第三个坐标轴-副切线的方向性
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;                
            };
            struct v2f{
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o ;
                o.pos = UnityObjectToClipPos(v.vertex);
                //o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw; 
                //o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw; 
                //TANGENT_SPACE_ROTATION
                float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz)) * v.tangent.w;
                float3x3 rotation = float3x3(v.tangent.xyz , binormal , v.normal);
                
                o.lightDir = mul(rotation , ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation , ObjSpaceViewDir(v.vertex));
                return o;
            }            
            fixed4 frag(v2f i):SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);  // 此时packedNormal.xyz = (0.5,0.5,1)
                fixed3 tangentNormal;
                // 发现纹理中存储的是经过映射后得到的像素值，因此我们需要把它们映射回来，如果我们没有在unity里把法线文理的类型设置为"Normal Map"，就需要在代码中手动进行这个过程
                // tangentNormal.xy = (packedNormal.xy * 2 -1) * _BumpScale;
                // 因为都是单位矢量，所以z分量可以通过xz计算而得，由于我们使用的是切线空间下的法线纹理，所以可以保证法线方向的z分量为正
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                
                // 在unity中，问了方便unity对法线文理的存储进行优化，我们通常会把法线纹理的纹理类型标识成Normal Map ， untiy会根据不同平台来选择不同的压缩方法,同时对xy * 2 - 1
                tangentNormal = UnpackNormal(packedNormal);     // 此时tangentNormal.xyz = (0,0,1)
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy , tangentNormal.xy)));
                
                fixed3 albedo = tex2D(_MainTex,i.uv.xy) * _Color;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.xyz * albedo * max(0 , dot(tangentLightDir,tangentNormal ));
                
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.xyz * _Specular.xyz * pow(max(0,dot( halfDir , tangentNormal)),_Gloss );
                
                return fixed4(ambient + diffuse + specular,1);
            }
            ENDCG
        }
    }
}
