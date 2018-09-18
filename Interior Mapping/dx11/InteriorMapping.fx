//@author: vux
//@help: template for standard shaders
//@tags: template
//@credits: 

Texture2D texture2d <string uiname="Texture";>;

SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};


Texture2D Floor;
Texture2D Roof;
Texture2D Wall;
Texture2D Wall2;


static float eps = .01;
static float3 WallInterval = float3(4,4,4) - eps;


 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : LAYERVIEWPROJECTION;	
	float4x4 tVI : VIEWINVERSE;	
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tWI : WORLDINVERSE;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_Position;
    float4 TexCd: TEXCOORD0;
	float4 poso : TEXCOORD1;
};

vs2ps VS(VS_IN input)
{
    vs2ps output;
    output.PosWVP  = mul(input.PosO,mul(tW,tVP));
    output.TexCd = input.TexCd;
	output.poso = input.PosO;
    return output;
}




float4 PS(vs2ps In): SV_Target
{
	
	float3 campos = mul(tVI[3].xyz, (float3x3)tWI) + tWI[3].xyz;
	float3 vdir = In.poso.xyz - campos;
	
	float3 corner = floor(In.poso.xyz * WallInterval);
	float3 wall = corner + step(float3(0,0,0), vdir);
	float3 c = corner;
	wall /= WallInterval;
	corner /= WallInterval;
	
	float3 rayFrac = (float3(wall.x, wall.y, wall.z) - campos) / vdir;
	
	float2 planeXY = (campos + rayFrac.z * vdir).xy;
	float2 planeXZ = (campos + rayFrac.y * vdir).xz*4;
	float2 planeZY = (campos + rayFrac.x * vdir).zy;
	
	planeXY = (planeXY - corner.xy) * WallInterval.xy;
	float4 wallXYColour = Wall.Sample(linearSampler, planeXY);
	//float4 wallXYColour = 0.8 * Wall1Color;
	
	planeZY = (planeZY - corner.zy) * WallInterval.zy;
	float4 wallZYColour = Wall2.Sample(linearSampler, planeZY);
	//float4 wallZYColour = Wall1Color;
	
	float4 f = Floor.Sample(linearSampler, planeXZ);
	float4 r = Roof.Sample(linearSampler, planeXZ);
	float4 verticalColour = lerp(f, r, step(0, vdir.y));
	
	float xVSz = step(rayFrac.x, rayFrac.z);
	float4 col = lerp(wallXYColour, wallZYColour, xVSz);
	float rayFrac_xVSz = lerp(rayFrac.z, rayFrac.x, xVSz);
	float xzVSy = step(rayFrac_xVSz, rayFrac.y);
	col = lerp(verticalColour, col, xzVSy);
	
    //return col;
	return float4(col);
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




