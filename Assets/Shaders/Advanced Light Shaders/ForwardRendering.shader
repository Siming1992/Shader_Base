// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'


Shader"Advanced Light/ForwardRendering"{
    Properties{
        _Diffuse("Diffuse" , Color) = (1,1,1,1)
        _Specular("Specular" , Color ) = (1,1,1,1)
        _Gloss("Gloss" , Range(8,255)) = 20
    }
    SubShader{
        // Base Pass
        Pass{
            Tags{
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            // 保证我们在Shader中使用光照衰减等变量可以被正确赋值，这是不可缺少的
            #pragma multi_compile_fwdbase
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
                // 我们希望环境光计算一次即可，因此在后面的Additional Pass中就不会再计算这个部分，与之类似的还有物体的自发光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 每一个光源有五个属性：位置，方向，颜色，强度，和衰减
                // 我们使用——_WorldSpaceLightPos0来得到方向光方向（位置对于平行光没有意义）-位置，方向
				fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 使用_LightColor0来得到方向光的颜色和强度（_LightColor0已经是颜色和强度相乘后的结果）-颜色，强度
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                
                // 由于平行光可以认为是没有衰减的，因此这里我们直接领衰减值为1.0
                fixed atten = 1.0;
                fixed3 color = ambient + diffuse + specular;
                return fixed4(color * atten,1);
            }
            
            ENDCG
        }
        Pass{
            Tags{
                "LightMode" = "ForwardAdd"
            }
            // 同BassPass不同，我们使用了Blend命令开启和设置了混合模式，这是因为，我们希望AdditionalPass计算的到的光照结果可以再帧缓存中与之前的光照结果进行叠加
            // 如果没有使用Blend命令的话，AdditionalPass会直接覆盖掉之前的光照结果 Blend One One不是必须的，常见的还有Blend SrcAlpha One
            Blend One One
            
            CGPROGRAM
            //#pragma multi_compile_fwdadd
			#pragma multi_compile_fwdadd
            #pragma vertex vert 
            #pragma fragment frag
            #include "Lighting.cginc"
            // 包含 unity_WorldToLight _LightTexture0
			#include "AutoLight.cginc"
            
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
                // 这里去掉了Base Pass中环境光，自发光，注定点光照，SH光照部分，并添加了对不同光源的类型支持
				fixed3 worldNormal = normalize(i.worldNormal);
				// 通过使用#ifdef指令判断是否定义了USING_DIRECTIONAL_LIGHT来判断，如果当前钱箱渲染Pass处理的光源是平行光，unity底层就会定义USING_DIRECTIONAL_LIGHT
				// 如果判断是平行光的话，光源方向直接由_WorldSpaceLightPos0.xyz得到，如果是点光源或聚光灯，那么_WorldSpaceLightPos0.xyz表示的是世界空间下的位置，
				// 而想得到光源方向的话，我们就要用这个位置减去世界空间下的顶点位置。
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				// 我们可以使用数学表达式来计算给定相对于点光源和聚光灯的衰减，但这些计算往往涉及开根号，除法等计算相对较大的操作，因此unity选择使用了一张纹理作为查找表(Lookup Table,LUT)
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    fixed atten = tex2D(_LightTexture0 , dot(lightCoord , lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif
                
                fixed3 color = diffuse + specular;
                return fixed4(color * atten,1);
            }
            ENDCG
        }
    }
}