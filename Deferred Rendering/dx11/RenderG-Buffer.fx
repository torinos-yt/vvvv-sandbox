Texture2D coltex <string uiname="Texture";>;
Texture2D BumpTex <string uiname="Bump Texture";>;
Texture2D spectex <string uiname = "Specular Map";>;
Texture2D roughtex <string uiname = "Roughness Map";>;

bool IsBump = true;
float bumps<string uiname = "BumpMap Strength"; float uimin = 0.0; float uimax = 5.0;> = 1;

SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;	
	float4x4 tV : VIEW;
	float4x4 ptV;
	float4x4 ptVP;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tWIT: WORLDLAYERINVERSETRANSPOSE;
	float4x4 ptW;
	float4x4 texW;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
	float3 Norm : NORMAL;
	float3 tangent : TANGENT;
};

struct VS_INTNB
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
	float3 Norm : NORMAL;
};

struct vs2ps
{
    float4 PosWVP: SV_Position;
	float4 PosW : TEXCOORD1;
	float4 velocity : TEXCOORD2;
    float4 uv: TEXCOORD0;
	float3 tangent : TEXCOORD3;
	float3 NormW : NORMAL;
};

struct vs2pstnb
{
    float4 PosWVP: SV_Position;
	float4 PosW : TEXCOORD1;
	float4 velocity : TEXCOORD2;
    float4 uv: TEXCOORD0;
	float3 NormW : NORMAL;
};

struct PSout{
	float4 color : SV_Target0;
	float4 normal : SV_Target1;
	float4 specrough : SV_Target2;
	float4 position : SV_Target3;
	float4 posvel : SV_Target4;
};

vs2ps VS(VS_IN input)
{
    vs2ps output;
    output.PosWVP  = mul(input.PosO,mul(tW,tVP));
	float4 PosW = mul(input.PosO, tW);
	float4 velocity = mul(input.PosO, ptW);
	output.PosW = PosW;
	output.velocity = velocity;
    output.uv = mul(input.TexCd, texW);;
	output.NormW = normalize(mul(input.Norm, (float3x3)tWIT));
	output.tangent = normalize(mul(input.tangent, (float3x3)tW).xyz);
    return output;
}

vs2pstnb VS_TNB(VS_INTNB input)
{
    vs2pstnb output;
    output.PosWVP  = mul(input.PosO,mul(tW,tVP));
	float4 PosW = mul(input.PosO, tW);
	float4 velocity = mul(input.PosO, ptW);
	output.PosW = PosW;
	output.velocity = velocity;
    output.uv = mul(input.TexCd, texW);
	output.NormW = normalize(mul(input.Norm, (float3x3)tWIT));
    return output;
}




PSout PS(vs2ps In)
{
	PSout gbuffer;
	
    gbuffer.color = float4(coltex.Sample(linearSampler, In.uv.xy).rgb, 1);
	
	float3 norm = In.NormW;
	gbuffer.normal = float4(normalize(norm), 1);
	
	float3 spec = spectex.Sample(linearSampler, In.uv.xy).rgb;
	float rough = roughtex.Sample(linearSampler, In.uv.xy).r;
	gbuffer.specrough = float4(spec, rough);
	
	gbuffer.position = In.PosW;
	float4 posV = mul(In.PosW, tVP);
	float4 vel = mul(In.velocity, ptVP);
	float2 possc = posV.xy / posV.w;
	float2 velxy = possc - (vel / vel.w).xy;
	velxy *= .5;
	velxy += .5;
	
	gbuffer.posvel.zw = velxy;
	gbuffer.posvel = float4(posV.xy, velxy);
	
	if(IsBump){
		float3 bnormal = normalize(cross(In.NormW, In.tangent));
		float3 nmap = BumpTex.Sample(linearSampler, In.uv.xy).xyz;
		nmap = nmap * 2.0 - 1.0;
		gbuffer.normal = float4(normalize(norm + (nmap.x * In.tangent + nmap.y * bnormal) * bumps), 1);
	}
    return gbuffer;
}

PSout PS_TNB(vs2pstnb In)
{
	PSout gbuffer;
	
    gbuffer.color = float4(coltex.Sample(linearSampler, In.uv.xy).rgb, 1);
	
	float3 norm = In.NormW;
	gbuffer.normal = float4(normalize(norm), 1);
	
	float3 spec = spectex.Sample(linearSampler, In.uv.xy).rgb;
	float rough = roughtex.Sample(linearSampler, In.uv.xy).r;
	gbuffer.specrough = float4(spec, rough);
	
	gbuffer.position = In.PosW;
	float4 posV = mul(In.PosW, tVP);
	float4 vel = mul(In.velocity, ptVP);
	float2 possc = posV.xy / posV.w;
	float2 velxy = possc - (vel / vel.w).xy;
	velxy *= .5;
	velxy += .5;
	
	gbuffer.posvel.zw = velxy;
	gbuffer.posvel = float4(posV.xy, velxy);
	
	if(IsBump){
		float3 p_dx = ddx(In.PosW.xyz);
		float3 p_dy = ddy(In.PosW.xyz);

		float2 tc_dx = ddx(In.uv.xy);
		float2 tc_dy = ddy(In.uv.xy);

		float3 t = normalize( tc_dy.y * p_dx - tc_dx.y * p_dy );
		float3 b = normalize( tc_dy.x * p_dx - tc_dx.x * p_dy ); 

		float3 n = normalize(In.NormW);
		float3 x = cross(n, t);
		t = cross(x, n);
		t = normalize(t);

		x = cross(b, n);
		b = cross(n, x);
		b = normalize(b);
		
		float3 nmap = BumpTex.Sample(linearSampler, In.uv.xy).xyz;
		nmap = nmap * 2.0 - 1.0;
		gbuffer.normal = float4(normalize(norm + (nmap.x * t + nmap.y * b) * bumps), 1);
	}
    return gbuffer;
}





technique10 GBuffer
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

technique10 GBufferNoTangent
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_TNB() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_TNB() ) );
	}
}




