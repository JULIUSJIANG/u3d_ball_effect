// 用于解决粒子陷入地面时切边的问题
Shader "Jiang/ParticleSystemFoldAdd"
{
    Properties
    {
        _Color ("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _MainTex ("Texture", 2D) = "white" {}
        _GroundY ("Ground Y", Float) = 0.0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        Cull Off
		ZWrite Off
		ZTest On
		Blend SrcAlpha One

        Pass
        {
            Name "main"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _GroundY;
            float4 _Color;

            struct appdata
            {
                float4 color: COLOR;
                float4 vertex : POSITION;
                float4 normal: NORMAL;
                float4 tangent: TANGENT;
                float4 uv : TEXCOORD0;
                float4 texCoord1: TEXCOORD1;
            };

            struct v2f
            {
                float4 color: COLOR;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // 核心的变换逻辑
            void foldInGround (float3 cObjectPosCenter, in out float4 pos, in out float2 uv) {
                float3 cObjectPosCenterWorld = mul (unity_ObjectToWorld, float4 (cObjectPosCenter, 1.0));

                // 相机各个参数到世界坐标、模型坐标的转换
                float3 cCameraPosCenter = float3 (0, 0, 0);
                float3 cCameraPosCenterWorld = mul (unity_CameraToWorld, float4 (cCameraPosCenter, 1.0));
				float3 cCameraPosCenterObject = mul (unity_WorldToObject, float4 (cCameraPosCenterWorld, 1.0));
                // 右
                float3 cCameraPosRight = float3 (-1, 0, 0);
				float3 cCameraPosRightWorld = mul (unity_CameraToWorld, float4 (cCameraPosRight, 1.0));
                float3 cCameraVecRightWorld = normalize (cCameraPosRightWorld - cCameraPosCenterWorld);
				float3 cCameraPosRightObject = mul (unity_WorldToObject, float4 (cCameraPosRightWorld, 1.0));
                float3 cCameraVecRightObject = normalize (cCameraPosRightObject - cCameraPosCenterObject);
                // 上
				float3 cCameraPosUp = float3 (0, 1, 0);
				float3 cCameraPosUpWorld = mul (unity_CameraToWorld, float4 (cCameraPosUp, 1.0));
                float3 cCameraVecUpWorld = normalize (cCameraPosUpWorld - cCameraPosCenterWorld);
				float3 cCameraPosUpObject = mul (unity_WorldToObject, float4 (cCameraPosUpWorld, 1.0));
                float3 cCameraVecUpObject = normalize (cCameraPosUpObject - cCameraPosCenterObject);
                // 前
                float3 cCameraPosForward = float3 (0, 0, 1);
				float3 cCameraPosForwardWorld = mul (unity_CameraToWorld, float4 (cCameraPosForward, 1.0));
                float3 cCameraVecForwardWorld = normalize (cCameraPosForwardWorld - cCameraPosCenterWorld);
				float3 cCameraPosForwardObject = mul (unity_WorldToObject, float4 (cCameraPosForwardWorld, 1.0));
                float3 cCameraVecForwardObject = normalize (cCameraPosForwardObject - cCameraPosCenterObject);

                // 该值即为基础广告牌
				float3 cObjectPosVertexBillboard = cObjectPosCenter + cCameraVecRightObject * pos.x + cCameraVecUpObject * pos.y + cCameraVecForwardObject * pos.z;
                float3 cObjectPosVertexBillboardWorld = mul (unity_ObjectToWorld, float4 (cObjectPosVertexBillboard, 1.0));

                //【水平相关】
                float3 hVecTempZ = cCameraPosForwardWorld - cCameraPosCenterWorld;
                hVecTempZ.y = 0.0;
                hVecTempZ = normalize (hVecTempZ);
                float3 hVecTempY = float3 (0, 1, 0);
                float3 hVecTempX = cross (hVecTempY, hVecTempZ);
                hVecTempX = normalize (hVecTempX);
                float3 hObjectcPosVertexWorld = float3 (cObjectPosVertexBillboardWorld);
                float3 hObjectcPosVertexWorldRelCenter = hObjectcPosVertexWorld - cObjectPosCenterWorld;
                float hZ = abs (dot (hObjectcPosVertexWorldRelCenter, hVecTempZ));
                float hY = abs (dot (hObjectcPosVertexWorldRelCenter, hVecTempY));
                float hRadiusWorld = sqrt (pow (hZ, 2.0) + pow (hY, 2.0));
                float hHeight = cObjectPosCenterWorld.y - _GroundY;
                float hOffsetWorld = sqrt (abs (pow (hRadiusWorld, 2) - pow (hHeight, 2)));
                hObjectcPosVertexWorld = float3 (cObjectPosCenterWorld.x, _GroundY, cObjectPosCenterWorld.z) + dot (hVecTempX, hObjectcPosVertexWorldRelCenter) * hVecTempX - hOffsetWorld * hVecTempZ;
                float2 hTexcoord = uv;

                //【垂直相关】
                float vJudge = step (0.66, uv.y);
                float3 vObjectPosVertexWorld = cObjectPosVertexBillboardWorld;
                float2 vTexcoord = uv;

                //【折线相关】
                float mOffset = hZ / hY * hHeight;
                float mLen = sqrt (pow (hZ, 2.0) + pow (hY, 2.0));
                float3 mObjectcPosVertexWorld = float3 (cObjectPosCenterWorld.x, _GroundY, cObjectPosCenterWorld.z) + dot (hVecTempX, hObjectcPosVertexWorldRelCenter) * hVecTempX - mOffset * hVecTempZ;
                float2 mTexcoord = float2 (uv.x, (hRadiusWorld - mLen * hHeight / hY) / (hRadiusWorld * 2.0));

                // 相机参数合法
                float jCameraValid =  step (_GroundY, _WorldSpaceCameraPos.y)       // 地面以上
                                    * step (0.0, cCameraVecUpWorld.y)               // 相机的 “上” 指向天
                                    * step (abs (cCameraVecRightWorld.y), 0.01);    // 不倾斜
                // 是高位顶点
                float jVer = step (abs (uv.y - 1.0), 0.1);
                // 是折线顶点 - 下
                float jMiddle = step (abs (uv.y - 0.5), 0.1);
                // 是低位顶点
                float jHor = step (abs (uv.y - 0.0), 0.1);
                // 下半区陷入地面
                float jCutLow = step (cObjectPosVertexBillboardWorld.y, _GroundY) * step (_GroundY, cObjectPosCenterWorld.y);
                // 上半区陷入地面
                float jCutHigh = step (cObjectPosCenterWorld.y, _GroundY) * step (_GroundY, cObjectPosCenterWorld.y + cObjectPosCenterWorld.y - cObjectPosVertexBillboardWorld.y);
                // 确实发生切割
                float jCut = sign (jCutLow + jCutHigh);
                // 有正交需要
                float jOrth =     jHor                          // 低位顶点
                                * jCut                       // 陷入地面
                                * (1.0 - unity_OrthoParams.w);  // 没开正交

                // 经过折叠的采样坐标
                float2 cTexcoord = 
                    jCameraValid * (
                        jVer * (
                            vTexcoord
                        )
                        +
                        jMiddle * (
                            jCut * (
                                mTexcoord
                            )
                            +
                            (1.0 - jCut) * (
                                float2 (vTexcoord.x, 0.0)
                            )
                        )
                        +
                        jHor * (
                            jCutHigh * (
                                float2 (hTexcoord.x, 1.0)
                            )
                            + 
                            (1.0 - jCutHigh) * (
                                hTexcoord
                            )
                        )
                    )
                    +
                    (1.0 - jCameraValid) * (
                        jVer * (
                            vTexcoord
                        )
                        +
                        jMiddle * (
                            float2 (vTexcoord.x, 0.0)
                        )
                        +
                        jHor * (
                            hTexcoord
                        )
                    );
				uv.xy = TRANSFORM_TEX (cTexcoord, _MainTex);

                // 经过折叠的世界坐标
                float3 cPosVertexWorld = 
                    jCameraValid * (
                        jVer * (
                            vObjectPosVertexWorld
                        )
                        +
                        jMiddle * (
                            jCut * (
                                mObjectcPosVertexWorld
                            )
                            +
                            (1.0 - jCut) * (
                                cObjectPosVertexBillboardWorld
                            )
                        )
                        +
                        jHor * (
                            jCut * (
                                hObjectcPosVertexWorld
                            )
                            +
                            (1.0 - jCut) * (
                                cObjectPosVertexBillboardWorld
                            )
                        )
                    )
                    +
                    (1.0 - jCameraValid) * (
                        cObjectPosVertexBillboardWorld
                    );
                
                //【正交相关】
                float3 oPosVertexWorldRelCenter = cPosVertexWorld - cObjectPosCenterWorld;
                float3 oPosShadowAnchor = cObjectPosCenterWorld + dot (oPosVertexWorldRelCenter, cCameraVecRightWorld) * cCameraVecRightWorld + dot (oPosVertexWorldRelCenter, cCameraVecUpWorld) * cCameraVecUpWorld;
                float3 oVecAnchorToCamera = _WorldSpaceCameraPos - oPosShadowAnchor;
                oVecAnchorToCamera = normalize (oVecAnchorToCamera);
                float oYCount = (_GroundY - oPosShadowAnchor.y) / oVecAnchorToCamera.y;
                float3 oPosVertexWorld =  oPosShadowAnchor + oYCount * oVecAnchorToCamera;
                // 经过正交的世界坐标
                cPosVertexWorld = 
                    jOrth * (
                        oPosVertexWorld
                    )
                    +
                    (1.0 - jOrth) * (
                        cPosVertexWorld
                    );

                float4 cPosVertex = mul (unity_WorldToObject, float4 (cPosVertexWorld, 1.0));
                pos = UnityObjectToClipPos (cPosVertex);
            }

            v2f vert (appdata v)
            {
                v2f o;
                
                float3 normal = v.normal.xyz;
                float3 tangent = v.tangent.xyz;
                float3 bnormal = cross(normal, tangent) * v.tangent.w;
                bnormal = normalize (bnormal);

                float3 position = v.vertex.xyz;
                float3 center = float3 (v.uv.z, v.uv.w, v.texCoord1.x);
                float3 posRelative = position - center;

                float normalDot = dot (normal, posRelative);
                float tangentDot = dot (tangent, posRelative);
                float bnormalDot = dot (bnormal, posRelative);

                // 局部坐标
                float3 posPrivate = float3 (- tangentDot, bnormalDot, normalDot);

                o.color = v.color;
                o.vertex = float4 (posPrivate, 1.0);
                o.uv = v.uv;
                foldInGround (center, o.vertex, o.uv);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D (_MainTex, i.uv) * i.color * _Color * 2.0;
            }
            ENDCG
        }
    }
}
 