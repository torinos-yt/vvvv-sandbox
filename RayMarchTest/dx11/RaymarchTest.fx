//@author: vux
//@help: template for standard shaders
//@tags: template
//@credits: 

#ifndef ITERATION
#define ITERATION 30
#endif

Texture2D texture2d <string uiname="Texture";>;

SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : LAYERVIEWPROJECTION;	
	float4x4 tVI : VIEWINVERSE;
	float4x4 tPI : PROJECTIONINVERSE;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tWI : WORLDINVERSE;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float3 size = 1;
};

float3 LightDir = normalize(float3(1.0,1.0,1.0));

float maxd<string uiname = "Max Distance";> = 500;
float mind<string uiname = "Min Distance";> = .01;

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct psinput
{
	float4 PosWVP : SV_Position;
	float2 uv : TEXCOORD0;
};

struct psout{
	float4 col : SV_Target;
	float depth : SV_Depth;
};

/* //sphere
float distfunc(float3 pos, float size){
	return length(pos) - size;
}
*/

/* //box
float distfunc(float3 rayPos, float size){
	return length(max(abs(rayPos) - size, 0.0));
}
*/

/* //torus
float distfunc(float3 rayPos, float3 size){
	float2 q = float2(length(rayPos.xz) - size.x, rayPos.y);
	return length(q) - size.y;
}
*/

/* //fractal
float distfunc(float3 rayPos, float3 size){

	
	float3 a1 = float3(1,1,1);
	float3 a2 = float3(-1,-1,1);
	float3 a3 = float3(1,-1,-1);
	float3 a4 = float3(-1,1,-1);
	
	float d;
	for(int n = 0; n < 20; n++){
		float3 c = a1;
		float minD = length(rayPos - a1);
		d = length(rayPos - a2); 
		if(d < minD) {
			c = a2; minD = d;
		}
		d = length(rayPos - a3); 
		if(d < minD) {
			c = a3; minD = d;
		}
		d = length(rayPos - a4); 
		if(d < minD) {
			c = a4; minD = d;
		}
		rayPos = size * rayPos - c * (size - 1.0);
	}
	
	return length(rayPos) * pow(abs(size.x), float(-n));
}
*/

float distfunc(float3 rayPos, float3 size){
	float3 p = fmod(rayPos, 2.0)-2.0*.5;
	//p = rayPos;
	
	float mr = .25, mxr = 1.0;
	float4 scale = size.x, p0 = float4(0.0, 0.59, -1.0, 0.0);
	float4 z = float4(p, 1.0);
	for(int n = 0; n < 8; n++){
		z.xyz = clamp(z.xyz, -0.94, 0.94) * 2 - z.xyz;
		z *= scale / clamp(dot(z.xyz, z.xyz), mr, mxr) * .97;
		z += p0;
	}
	
	float ds = (length(max(abs(z.xyz) - float3(.2,90.0,.8), 0.0)) - .7) / z.w;
	return ds;
}



float3 getNormal(float3 pos, float3 size){
	float ep = .001;
	return normalize(float3(
		distfunc(pos, size) - distfunc(float3(pos.x-ep, pos.y, pos.z), size),
		distfunc(pos, size) - distfunc(float3(pos.x, pos.y-ep, pos.z), size),
		distfunc(pos, size) - distfunc(float3(pos.x, pos.y, pos.z-ep), size)));
}

psinput VS(VS_IN input)
{
    psinput output;
    output.PosWVP  = input.PosO;
    output.uv = input.TexCd.xy;
    return output;
}

psout PS(psinput input)
{
	
	psout output;
	float mamb = .85;
	float4 color = mamb;
	
	float3 rayDir = normalize(mul(float4(mul(float4((input.uv*2.0-1.0)*float2(1,-1),0,1), tPI).xy,1,0), tVI).xyz);
	float3 rayPos = tVI[3].xyz;
	float total = 0;
	
	rayPos += rayDir * mind;
	
	for(int i = 0; i < ITERATION; i++){
		float d = distfunc(mul(float4(rayPos,1), tWI).xyz, size);
		if(d < 0.001){
			float3 normal = normalize(mul(float4(getNormal(mul(float4(rayPos,1), tWI).xyz, size),0), tW).xyz);
			color = float4((dot(LightDir, normal) * cAmb.xyz)+.35, 1);
			color += float4(normal*.09, 0);
			color = min(color, mamb);
			break;
		}
		if(total > maxd) break;
		rayPos += rayDir*d;
		total += d;
	}
	
	output.col = color;
	float4 posw = mul(float4(rayPos, 1), tVP);
	output.depth = posw.z / posw.w;
	
	return output;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




