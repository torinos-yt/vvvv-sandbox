
Texture2D texture2d <string uiname="Texture";>;
float Scale = 1;
float fall;

SamplerState linearSampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : LAYERVIEWPROJECTION;	
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct gsout
{
	float4 pos: SV_POSITION;
};

struct vs2gs
{
	float4 PosWVP: SV_Position;
};

vs2gs VS()
{
	vs2gs output;
	output.PosWVP  = float4(0,0,0,1);
	return output;
}

[maxvertexcount(30)]
void Fallof(point vs2gs input[1], inout LineStream<gsout> outstream){
	float s = Scale; 
	gsout o;
	for(int i = 0; i < 5; i++){
		o.pos = float4(sin(radians((360/4) * i + 45)) * s, -fall / 2, cos(radians((360/4) * i + 45)) * s, 1);
		o.pos = mul(mul(o.pos, tW), tVP);
		outstream.Append(o);
	}
	outstream.RestartStrip();
	
	for(i = 0; i < 5; i++){
		o.pos = float4(sin(radians((360/4) * i + 45)) * s, fall / 2, cos(radians((360/4) * i + 45)) * s, 1);
		o.pos = mul(mul(o.pos, tW), tVP);
		outstream.Append(o);
	}
	outstream.RestartStrip();
	
	o.pos = mul(mul(float4(0, fall/2, 0, 1), tW), tVP);
	outstream.Append(o);
	o.pos = mul(mul(float4(0, -fall/2, 0, 1), tW), tVP);
	outstream.Append(o);
	outstream.RestartStrip();
	
	o.pos = mul(mul(float4(-.2, -fall/2 + .2, 0, 1), tW), tVP);
	outstream.Append(o);
	o.pos = mul(mul(float4(0, -fall/2, 0, 1), tW), tVP);
	outstream.Append(o);
	o.pos = mul(mul(float4(.2, -fall/2 + .2, 0, 1), tW), tVP);
	outstream.Append(o);
	
	outstream.RestartStrip();
	
}


float4 PS(gsout In): SV_Target
{
	float4 col = float4(1,1,0,1);
	return col;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, Fallof() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




