#define CONAN_RECOMP 1
#ifndef SHADER_COMMON_H_INCLUDED
#define SHADER_COMMON_H_INCLUDED

#define SPEC_CONSTANT_R11G11B10_NORMAL  (1 << 0)
#define SPEC_CONSTANT_ALPHA_TEST        (1 << 1)

#ifdef CONAN_RECOMP
    // Alpha test converted to alpha-to-coverage (foliage antialiasing option).
    #define SPEC_CONSTANT_ALPHA_TO_COVERAGE (1 << 3)
    #define SPEC_CONSTANT_SOFT_PARTICLE_RGBA (1 << 4)
    #define SPEC_CONSTANT_SOFT_PARTICLE_ALPHA (1 << 5)
#endif
#ifdef UNLEASHED_RECOMP
    #define SPEC_CONSTANT_BICUBIC_GI_FILTER (1 << 2)
    #define SPEC_CONSTANT_ALPHA_TO_COVERAGE (1 << 3)
    #define SPEC_CONSTANT_REVERSE_Z         (1 << 4)
#endif

// SPIR-V vertex input locations, shared with reblue's host input-layout
// builder. A semantic missing here gets no location from the emitter.
#define REBLUE_VERTEX_INPUT_LOCATIONS(X) \
    X(Position,  0,  0) \
    X(Position,  1,  1) \
    X(Position,  2,  2) \
    X(Position,  3,  3) \
    X(Position,  4,  4) \
    X(Normal,    0,  5) \
    X(Tangent,   0,  6) \
    X(TexCoord,  0,  7) \
    X(TexCoord,  1,  8) \
    X(TexCoord,  2,  9) \
    X(Color,     0, 10)

// SPEC_CONSTANTS_ONLY keeps the HLSL below out of host C++ TUs, which IntelliSense would otherwise parse.
#if (!defined(__cplusplus) || defined(__INTELLISENSE__)) && !defined(SHADER_COMMON_SPEC_CONSTANTS_ONLY)

#define FLT_MIN asfloat(0xff7fffff)
#define FLT_MAX asfloat(0x7f7fffff)

#ifdef __spirv__

struct PushConstants
{
    uint64_t VertexShaderConstants;
    uint64_t PixelShaderConstants;
    uint64_t SharedConstants;
};

[[vk::push_constant]] ConstantBuffer<PushConstants> g_PushConstants;

#ifdef REBLUE_RECOMP
// 256-bit boolean register file (BD bool addresses reach ~158), then per-usage 16-bit-pair swap masks.
#define g_Booleans(i)              vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 256 + (i)*4)
#define g_SwappedTexcoords         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 288)
#define g_HalfPixelOffset          vk::RawBufferLoad<float2>(g_PushConstants.SharedConstants + 292)
#define g_AlphaThreshold           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 300)
#define g_SwappedNormals           vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 304)
#define g_SwappedBinormals         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 308)
#define g_SwappedTangents          vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 312)
#define g_SwappedBlendWeights      vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 316)
#define g_SwappedPositions         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 320)
#define g_SintTexcoords            vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 324)
#define g_ShadowPcfScale           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 328)
#elif defined(CONAN_RECOMP)
// Conan layout (tools/xenosrecomp/patches): c16-c17 = the 256-bit Xenos bool file
// (VS 0..127, PS 128..255, LSB-first per dword like SHADER_CONSTANT_BOOL_*),
// c18 = misc, c19-c26 = the 32 Xenos loop constants (SHADER_CONSTANT_LOOP_00..31:
// count bits 0-7, start bits 8-15, signed step bits 16-23; VS i0-15 = 0-15,
// PS i0-15 = 16-31).
#define g_Booleans(i)              vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 256 + (i)*4)
#define g_SwappedTexcoords         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 288)
#define g_HalfPixelOffset          vk::RawBufferLoad<float2>(g_PushConstants.SharedConstants + 292)
#define g_AlphaThreshold           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 300)
#define g_LoopConstant(i)          vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 304 + (i)*4)
#define g_ScreenXform              vk::RawBufferLoad<float4>(g_PushConstants.SharedConstants + 432)
#define g_SpecConstantsRuntime     vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 448)
#else
#define g_Booleans                 vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 256)
#define g_SwappedTexcoords         vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 260)
#define g_HalfPixelOffset          vk::RawBufferLoad<float2>(g_PushConstants.SharedConstants + 264)
#define g_AlphaThreshold           vk::RawBufferLoad<float>(g_PushConstants.SharedConstants + 272)
#endif

[[vk::constant_id(0)]] const uint g_SpecConstants = 0;

#define g_SpecConstants() g_SpecConstants

#else

#ifdef REBLUE_RECOMP
#define DEFINE_SHARED_CONSTANTS() \
    uint4 g_BooleansArr[2] : packoffset(c16); \
    uint g_SwappedTexcoords : packoffset(c18.x); \
    float2 g_HalfPixelOffset : packoffset(c18.y); \
    float g_AlphaThreshold : packoffset(c18.w); \
    uint g_SwappedNormals : packoffset(c19.x); \
    uint g_SwappedBinormals : packoffset(c19.y); \
    uint g_SwappedTangents : packoffset(c19.z); \
    uint g_SwappedBlendWeights : packoffset(c19.w); \
    uint g_SwappedPositions : packoffset(c20.x); \
    uint g_SintTexcoords : packoffset(c20.y); \
    float g_ShadowPcfScale : packoffset(c20.z);

#define g_Booleans(i) (g_BooleansArr[(i) / 4][(i) % 4])
#elif defined(CONAN_RECOMP)
#define DEFINE_SHARED_CONSTANTS() \
    uint4 g_BooleansArr[2] : packoffset(c16); \
    uint g_SwappedTexcoords : packoffset(c18.x); \
    float2 g_HalfPixelOffset : packoffset(c18.y); \
    float g_AlphaThreshold : packoffset(c18.w); \
    uint4 g_LoopConstantsArr[8] : packoffset(c19); \
    float4 g_ScreenXform : packoffset(c27);     uint g_SpecConstantsRuntime : packoffset(c28.x); float g_PixelPosScale : packoffset(c28.y); float g_ShadowAtlasTexelScale : packoffset(c28.z); float g_ShadowSoftness : packoffset(c28.w); float2 g_SoftParticleW : packoffset(c29.x); float g_SoftParticleDistance : packoffset(c29.z); float g_SoftParticleTexelScale : packoffset(c29.w); uint g_SoftParticleDepth : packoffset(c30.x);

#define g_Booleans(i) (g_BooleansArr[(i) / 4][(i) % 4])
#define g_LoopConstant(i) (g_LoopConstantsArr[(i) / 4][(i) % 4])
#else
#define DEFINE_SHARED_CONSTANTS() \
    uint g_Booleans : packoffset(c16.x); \
    uint g_SwappedTexcoords : packoffset(c16.y); \
    float2 g_HalfPixelOffset : packoffset(c16.z); \
    float g_AlphaThreshold : packoffset(c17.x);
#endif

uint g_SpecConstants();

#endif

#if defined(REBLUE_RECOMP) || defined(CONAN_RECOMP)
// Test Xenos boolean register N in the unified VS(0..127)/PS(128..255) file.
#define BOOL_BIT(n) ((g_Booleans((n) / 32u) & (1u << ((n) & 31u))) != 0)
#endif

#ifdef CONAN_RECOMP
// xenos::LoopConstant: aL = start + iteration * step.
// Macros take the 32-bit loop constant value: g_LoopConstant(id), or a literal
// from the shader's definition table (defi).
#define LOOP_COUNT(c) ((c) & 0xFFu)
#define LOOP_START(c) int(((c) >> 8) & 0xFFu)
#define LOOP_STEP(c)  (int((c) << 8) >> 24)
#endif

#ifdef CONAN_RECOMP
// Bit 31 of a texture descriptor index = the fetch constant's RGB sign is GAMMA:
// Xenos returns linear values, converted with its piecewise-linear curve
// (xenos::PWLGammaToLinear, applied after filtering like the Xenia/ReXGlue
// Xenos backend).
// Bits 16-27 = host scale of a texture rendered larger than its guest size
// (render_scale resolve targets, 8.8 fixed point, 0 = 1:1): texel offsets and
// filter weights stay in guest texels, like on Xenos. SRV indices use bits 0-14.
#define TEX_INDEX(i) ((i) & 0x7FFFu)
#define TEX_SCALE(i) ((((i) >> 16) & 0xFFFu) ? float(((i) >> 16) & 0xFFFu) / 256.0 : 1.0)
float3 conanPwlGammaToLinear(float3 g)
{
    g = saturate(g);
    float3 hi = select(g >= 192.0 / 255.0, 8.0 / 1024.0, 4.0 / 1024.0);
    float3 lo = select(g >= 64.0 / 255.0, 2.0 / 1024.0, 1.0 / 1024.0);
    float3 scale = select(g >= 96.0 / 255.0, hi, lo);
    float3 offset = select(g >= 96.0 / 255.0, select(g >= 192.0 / 255.0, -1024.0, -256.0),
                           select(g >= 64.0 / 255.0, -64.0, 0.0));
    float3 l = g * ((255.0 * 1024.0) * scale) + offset;
    l += trunc(l * scale);
    return l * (1.0 / 1023.0);
}
float4 conanGamma(uint resourceDescriptorIndex, float4 value)
{
    if (resourceDescriptorIndex & 0x80000000u)
        value.rgb = conanPwlGammaToLinear(value.rgb);
    return value;
}
#else
#define TEX_INDEX(i) (i)
#define TEX_SCALE(i) 1.0
#define conanGamma(i, v) (v)
#endif

Texture2D<float4> g_Texture2DDescriptorHeap[] : register(t0, space0);
Texture3D<float4> g_Texture3DDescriptorHeap[] : register(t0, space1);
TextureCube<float4> g_TextureCubeDescriptorHeap[] : register(t0, space2);
SamplerState g_SamplerDescriptorHeap[] : register(s0, space3);

uint2 getTexture2DDimensions(Texture2D<float4> texture)
{
    uint2 dimensions;
    texture.GetDimensions(dimensions.x, dimensions.y);
    return dimensions;
}

// Texel grid the guest shader addresses (the guest texture size).
float2 getGuestTexture2DDimensions(uint resourceDescriptorIndex, Texture2D<float4> texture)
{
    return float2(getTexture2DDimensions(texture)) / TEX_SCALE(resourceDescriptorIndex);
}

float4 tfetch2DBicubic(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset);

float4 tfetch2D(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset)
{
#ifdef CONAN_RECOMP
    // Bit 28: smooth (cubic B-spline) magnification, set by the host for small
    // textures of blended effects (particles, glows) - bilinear magnification
    // of those shows diamond/block patterns at high render resolutions.
    if (resourceDescriptorIndex & 0x10000000u)
        return conanGamma(resourceDescriptorIndex, tfetch2DBicubic(resourceDescriptorIndex, samplerDescriptorIndex, texCoord, offset));
#endif
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    return conanGamma(resourceDescriptorIndex, texture.Sample(g_SamplerDescriptorHeap[samplerDescriptorIndex], texCoord + offset / getGuestTexture2DDimensions(resourceDescriptorIndex, texture)));
}

float2 getWeights2D(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset)
{
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    return select(isnan(texCoord), 0.0, frac(texCoord * getGuestTexture2DDimensions(resourceDescriptorIndex, texture) + offset - 0.5));
}

#ifdef REBLUE_RECOMP
// Bilinear-filtered shadow compare over the four neighboring depth texels.
float shadowCmp2D(uint resourceDescriptorIndex, float2 texCoord, float ref)
{
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    int2 dimensions = int2(getTexture2DDimensions(texture));
    float2 coord = texCoord * dimensions - 0.5;
    float2 weights = frac(coord);
    int2 base = int2(floor(coord));
    int2 c0 = clamp(base, int2(0, 0), dimensions - 1);
    int2 c1 = clamp(base + 1, int2(0, 0), dimensions - 1);
    float4 taps = float4(
        texture.Load(int3(c0, 0)).x,
        texture.Load(int3(c1.x, c0.y, 0)).x,
        texture.Load(int3(c0.x, c1.y, 0)).x,
        texture.Load(int3(c1, 0)).x) > ref;
    return lerp(lerp(taps.x, taps.y, weights.x), lerp(taps.z, taps.w, weights.x), weights.y);
}
#endif

float w0(float a)
{
    return (1.0f / 6.0f) * (a * (a * (-a + 3.0f) - 3.0f) + 1.0f);
}

float w1(float a)
{
    return (1.0f / 6.0f) * (a * a * (3.0f * a - 6.0f) + 4.0f);
}

float w2(float a)
{
    return (1.0f / 6.0f) * (a * (a * (-3.0f * a + 3.0f) + 3.0f) + 1.0f);
}

float w3(float a)
{
    return (1.0f / 6.0f) * (a * a * a);
}

float g0(float a)
{
    return w0(a) + w1(a);
}

float g1(float a)
{
    return w2(a) + w3(a);
}

float h0(float a)
{
    return -1.0f + w1(a) / (w0(a) + w1(a)) + 0.5f;
}

float h1(float a)
{
    return 1.0f + w3(a) / (w2(a) + w3(a)) + 0.5f;
}

float4 tfetch2DBicubic(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float2 texCoord, float2 offset)
{
    Texture2D<float4> texture = g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)];
    SamplerState samplerState = g_SamplerDescriptorHeap[samplerDescriptorIndex];
    float2 dimensions = getGuestTexture2DDimensions(resourceDescriptorIndex, texture);
    
    float x = texCoord.x * dimensions.x + offset.x;
    float y = texCoord.y * dimensions.y + offset.y;

    x -= 0.5f;
    y -= 0.5f;
    float px = floor(x);
    float py = floor(y);
    float fx = x - px;
    float fy = y - py;

    float g0x = g0(fx);
    float g1x = g1(fx);
    float h0x = h0(fx);
    float h1x = h1(fx);
    float h0y = h0(fy);
    float h1y = h1(fy);

    float4 r =
        g0(fy) * (g0x * texture.Sample(samplerState, float2(px + h0x, py + h0y) / float2(dimensions)) +
            g1x * texture.Sample(samplerState, float2(px + h1x, py + h0y) / float2(dimensions))) +
        g1(fy) * (g0x * texture.Sample(samplerState, float2(px + h0x, py + h1y) / float2(dimensions)) +
            g1x * texture.Sample(samplerState, float2(px + h1x, py + h1y) / float2(dimensions)));

    return r;
}

float4 tfetch3D(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float3 texCoord)
{
    return conanGamma(resourceDescriptorIndex, g_Texture3DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)].Sample(g_SamplerDescriptorHeap[samplerDescriptorIndex], texCoord));
}

struct CubeMapData
{
	#ifdef REBLUE_RECOMP
    // BD's cube-shadow PCF issues up to 9 cube ops per shader (bd_mirror_cs_ps /
    // bd_glass_cs_ps); overflowing this array drops the stored directions and
    // every tfetchCube reads OOB -> point-light shadows vanish.
    float3 cubeMapDirections[9];
    #else
    float3 cubeMapDirections[2];
    #endif
    uint cubeMapIndex;
};

float4 tfetchCube(uint resourceDescriptorIndex, uint samplerDescriptorIndex, float3 texCoord, inout CubeMapData cubeMapData)
{
    return conanGamma(resourceDescriptorIndex, g_TextureCubeDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)].Sample(g_SamplerDescriptorHeap[samplerDescriptorIndex], cubeMapData.cubeMapDirections[texCoord.z]));
}

#ifdef REBLUE_RECOMP
// DEC3N normal decode; IA binds as R32_UINT so lane .x carries the raw bits (asuint recovers them).
float4 tfetchR11G11B10(float4 value)
{
    if (g_SpecConstants() & SPEC_CONSTANT_R11G11B10_NORMAL)
    {
        uint v = asuint(value.x);
        return float4(
            (v & 0x00000400 ? -1.0 : 0.0) + ((v & 0x3FF) / 1024.0),
            (v & 0x00200000 ? -1.0 : 0.0) + (((v >> 11) & 0x3FF) / 1024.0),
            (v & 0x80000000 ? -1.0 : 0.0) + (((v >> 22) & 0x1FF) / 512.0),
            0.0);
    }
    return value;
}

// Undo the engine bswap32 16-bit-pair swap (.yxwz) for any 16-bit-packed semantic flagged in the mask.
float4 swapFloats(uint swappedMask, float4 value, uint semanticIndex)
{
    return (swappedMask & (1u << semanticIndex)) != 0 ? value.yxwz : value;
}

// Recover X360 integer-cast-to-float TEXCOORDs from R16G16(B16A16)_UINT bindings (sign-extend low 16 bits).
float4 sintTexcoord(uint mask, float4 value, uint semanticIndex)
{
    if ((mask & (1u << semanticIndex)) != 0)
    {
        int4 si = (int4(asuint(value)) << 16) >> 16;
        return float4(si);
    }
    return value;
}
#else
float4 tfetchR11G11B10(uint4 value)
{
    if (g_SpecConstants() & SPEC_CONSTANT_R11G11B10_NORMAL)
    {
        return float4(
            (value.x & 0x00000400 ? -1.0 : 0.0) + ((value.x & 0x3FF) / 1024.0),
            (value.x & 0x00200000 ? -1.0 : 0.0) + (((value.x >> 11) & 0x3FF) / 1024.0),
            (value.x & 0x80000000 ? -1.0 : 0.0) + (((value.x >> 22) & 0x1FF) / 512.0),
            0.0);
    }
    else
    {
        return asfloat(value);
    }
}

float4 tfetchTexcoord(uint swappedTexcoords, float4 value, uint semanticIndex)
{
    return (swappedTexcoords & (1ull << semanticIndex)) != 0 ? value.yxwz : value;
}
#endif

float4 cube(float4 value, inout CubeMapData cubeMapData)
{
    uint index = cubeMapData.cubeMapIndex;
    cubeMapData.cubeMapDirections[index] = value.xyz;
    ++cubeMapData.cubeMapIndex;
    
    return float4(0.0, 0.0, 0.0, index);
}

float4 dst(float4 src0, float4 src1)
{
    float4 dest;
    dest.x = 1.0;
    dest.y = src0.y * src1.y;
    dest.z = src0.z;
    dest.w = src1.w;
    return dest;
}

float4 max4(float4 src0)
{
    return max(max(src0.x, src0.y), max(src0.z, src0.w));
}

float2 getPixelCoord(uint resourceDescriptorIndex, float2 texCoord)
{
    return getTexture2DDimensions(g_Texture2DDescriptorHeap[TEX_INDEX(resourceDescriptorIndex)]) * texCoord;
}

float computeMipLevel(float2 pixelCoord)
{
    float2 dx = ddx(pixelCoord);
    float2 dy = ddy(pixelCoord);
    float deltaMaxSqr = max(dot(dx, dx), dot(dy, dy));
    return max(0.0, 0.5 * log2(deltaMaxSqr));
}

#endif

#endif

#ifdef __spirv__

#define g_aBoneMatrices(INDEX) select((INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.VertexShaderConstants + (0 + min(INDEX, 255)) * 16, 0x10), 0.0)
#define g_mWorldToObject(INDEX) select((INDEX) < 96, vk::RawBufferLoad<float4>(g_PushConstants.VertexShaderConstants + (160 + min(INDEX, 95)) * 16, 0x10), 0.0)
#define g_mWorldViewProjection(INDEX) select((INDEX) < 92, vk::RawBufferLoad<float4>(g_PushConstants.VertexShaderConstants + (164 + min(INDEX, 91)) * 16, 0x10), 0.0)
#define CONST_REL(INDEX) select((uint)(INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.VertexShaderConstants + min((uint)(INDEX), 255) * 16, 0x10), 0.0)

#else

cbuffer VertexShaderConstants : register(b0, space4)
{
	float4 g_VertexShaderConstantsArr[256] : packoffset(c0);
};

#define CONST_REL(INDEX) select((uint)(INDEX) < 256, g_VertexShaderConstantsArr[min((uint)(INDEX), 255)], 0.0)
#define g_aBoneMatrices(INDEX) CONST_REL(0 + (INDEX))
#define g_mWorldToObject(INDEX) CONST_REL(160 + (INDEX))
#define g_mWorldViewProjection(INDEX) CONST_REL(164 + (INDEX))

cbuffer SharedConstants : register(b2, space4)
{
	DEFINE_SHARED_CONSTANTS();
};

#endif

#ifndef __spirv__
[shader("vertex")]
#endif
void main(
	[[vk::location(0)]] in float4 iPosition0 : POSITION0,
	[[vk::location(1)]] in uint4 iNormal0 : NORMAL0,
	[[vk::location(9)]] in uint4 iBlendIndices0 : BLENDINDICES0,
	[[vk::location(10)]] in float4 iBlendWeight0 : BLENDWEIGHT0,
	out precise float4 oPos : SV_Position,
	out float4 oTexCoord0 : TEXCOORD0,
	out float4 oTexCoord1 : TEXCOORD1,
	out float4 oTexCoord2 : TEXCOORD2,
	out float4 oTexCoord3 : TEXCOORD3,
	out float4 oTexCoord4 : TEXCOORD4,
	out float4 oTexCoord5 : TEXCOORD5,
	out float4 oTexCoord6 : TEXCOORD6,
	out float4 oTexCoord7 : TEXCOORD7,
	out float4 oTexCoord8 : TEXCOORD8,
	out float4 oTexCoord9 : TEXCOORD9,
	out float4 oTexCoord10 : TEXCOORD10,
	out float4 oTexCoord11 : TEXCOORD11,
	out float4 oTexCoord12 : TEXCOORD12,
	out float4 oTexCoord13 : TEXCOORD13,
	out float4 oTexCoord14 : TEXCOORD14,
	out float4 oTexCoord15 : TEXCOORD15,
	out float4 oColor0 : COLOR0,
	out float4 oColor1 : COLOR1)
{
	float4 c252 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c253 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c254 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c255 = asfloat(uint4(0xC0000000, 0x0, 0x40800000, 0x3F800000));

	oPos = 0.0;
	oTexCoord0 = 0.0;
	oTexCoord1 = 0.0;
	oTexCoord2 = 0.0;
	oTexCoord3 = 0.0;
	oTexCoord4 = 0.0;
	oTexCoord5 = 0.0;
	oTexCoord6 = 0.0;
	oTexCoord7 = 0.0;
	oTexCoord8 = 0.0;
	oTexCoord9 = 0.0;
	oTexCoord10 = 0.0;
	oTexCoord11 = 0.0;
	oTexCoord12 = 0.0;
	oTexCoord13 = 0.0;
	oTexCoord14 = 0.0;
	oTexCoord15 = 0.0;
	oColor0 = 0.0;
	oColor1 = 0.0;

	float4 r0 = 0.0;
	float4 r1 = 0.0;
	float4 r2 = 0.0;
	float4 r3 = 0.0;
	float4 r4 = 0.0;
	float4 r5 = 0.0;
	float4 r6 = 0.0;
	float4 r7 = 0.0;
	float4 r8 = 0.0;
	float4 r9 = 0.0;
	float4 r10 = 0.0;
	float4 r11 = 0.0;
	float4 r12 = 0.0;
	float4 r13 = 0.0;
	float4 r14 = 0.0;
	float4 r15 = 0.0;
	float4 r16 = 0.0;
	float4 r17 = 0.0;
	float4 r18 = 0.0;
	float4 r19 = 0.0;
	float4 r20 = 0.0;
	float4 r21 = 0.0;
	float4 r22 = 0.0;
	float4 r23 = 0.0;
	float4 r24 = 0.0;
	float4 r25 = 0.0;
	float4 r26 = 0.0;
	float4 r27 = 0.0;
	float4 r28 = 0.0;
	float4 r29 = 0.0;
	float4 r30 = 0.0;
	float4 r31 = 0.0;
	int a0 = 0;
	int aL = 0;
	bool p0 = false;
	float ps = 0.0;

	r8.xyzw = iPosition0.xyzw;
	r9.xyzw = tfetchR11G11B10(iNormal0).xwyz;
	r1.xyzw = iBlendIndices0.yzxw;
	r2.xyz = iBlendWeight0.zxy;
	r4.xyzw = r9.zxzw * r9.wxzw;
	ps = max(r1.z, r1.z);
	r0.y = ps;
	r0.x = saturate(dot(r9.wxz, r9.wxz));
	ps = c255.z * r0.y;
	r2.w = ps;
	r0.w = c255.w > r2.y;
	ps = c255.w - r0.x;
	r1.z = ps;
	r0.xyz = r4.yzy + r4.zww;
	ps = max(r2.w, r2.w);
	a0 = (int)clamp(floor(r2.w + 0.5), -256.0, 255.0);
	r0.xyz = r0.xyz * c255.xxx + c255.www;
	r3.xyz = r0.xxx * CONST_REL(2 + a0).xyz;
	ps = sqrt(abs(r1.z));
	r1.z = ps;
	r5.xyzw = r8.zzzz * CONST_REL(2 + a0).xyzw + CONST_REL(3 + a0).xyzw;
	r6.xyz = r1.zzz * r9.xwz;
	p0 = c255.y == 0.0 && r0.w != 0.0;
	r2.w = p0 ? 0.0 : c255.y + 1.0;
	ps = max(r4.x, r4.x);
	r4.w = r4.x + r6.x;
	ps = -r6.x + ps;
	r4.x = ps;
	r4.yz = r9.xx * r9.wz + -r6.zy;
	r10.xy = r9.xx * r9.wz + r6.zy;
	r5.xyzw = r8.yyyy * CONST_REL(1 + a0).xyzw + r5.xyzw;
	r7.xyzw = r8.xxxx * CONST_REL(0 + a0).zywx + r5.zywx;
	r6.xyzw = r4.xyzw + r4.xyzw;
	r4.xyz = r6.yyy * CONST_REL(2 + a0).xyz;
	ps = r10.x + r10.x;
	r0.w = ps;
	r5.xyz = r6.www * CONST_REL(2 + a0).xyz;
	ps = r10.y + r10.y;
	r1.z = ps;
	r3.xyz = r6.xxx * CONST_REL(1 + a0).xyz + r3.xyz;
	r3.xyz = r0.www * CONST_REL(0 + a0).xyz + r3.xyz;
	r5.xyz = r0.zzz * CONST_REL(1 + a0).xyz + r5.xyz;
	r4.xyz = r1.zzz * CONST_REL(1 + a0).xyz + r4.xyz;
	r4.xyz = r0.yyy * CONST_REL(0 + a0).xyz + r4.xyz;
	r5.xyz = r6.zzz * CONST_REL(0 + a0).xyz + r5.xyz;
	if (p0)
	{
		r4.xyz = r4.xyz * r2.yyy;
	}
	if (p0)
	{
		r5.xyz = r5.xyz * r2.yyy;
	}
	if (p0)
	{
		r3.xyz = r3.xyz * r2.yyy;
	}
	if (p0)
	{
		r7.xyzw = r7.xyzw * r2.yyyy;
	}
	p0 = r2.w == 0.0 && r2.z > 0.0;
	r2.w = p0 ? 0.0 : r2.w + 1.0;
	if (p0)
	{
		ps = c255.z * r1.x;
		r3.w = ps;
	}
	if (p0)
	{
		ps = max(r3.w, r3.w);
		a0 = (int)clamp(floor(r3.w + 0.5), -256.0, 255.0);
	}
	if (p0)
	{
		r10.xyz = r0.xxx * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r11.xyz = r6.www * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r12.xyz = r6.yyy * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r13.xyzw = r8.zzzz * CONST_REL(2 + a0).xyzw + CONST_REL(3 + a0).xyzw;
	}
	if (p0)
	{
		r13.xyzw = r8.yyyy * CONST_REL(1 + a0).xyzw + r13.xyzw;
	}
	if (p0)
	{
		r12.xyz = r1.zzz * CONST_REL(1 + a0).xyz + r12.xyz;
	}
	if (p0)
	{
		r11.xyz = r0.zzz * CONST_REL(1 + a0).xyz + r11.xyz;
	}
	if (p0)
	{
		r10.xyz = r6.xxx * CONST_REL(1 + a0).xyz + r10.xyz;
	}
	if (p0)
	{
		r10.xyz = r0.www * CONST_REL(0 + a0).xyz + r10.xyz;
	}
	if (p0)
	{
		r11.xyz = r6.zzz * CONST_REL(0 + a0).xyz + r11.xyz;
	}
	if (p0)
	{
		r12.xyz = r0.yyy * CONST_REL(0 + a0).xyz + r12.xyz;
	}
	if (p0)
	{
		r13.xyzw = r8.xxxx * CONST_REL(0 + a0).xyzw + r13.xyzw;
	}
	if (p0)
	{
		r7.xyzw = r13.zywx * r2.zzzz + r7.xyzw;
	}
	if (p0)
	{
		r4.xyz = r12.xyz * r2.zzz + r4.xyz;
	}
	if (p0)
	{
		r5.xyz = r11.xyz * r2.zzz + r5.xyz;
	}
	if (p0)
	{
		r3.xyz = r10.xyz * r2.zzz + r3.xyz;
	}
	p0 = r2.w == 0.0 && r2.x > 0.0;
	r2.w = p0 ? 0.0 : r2.w + 1.0;
	if (p0)
	{
		ps = c255.w - r2.x;
		r1.x = ps;
	}
	if (p0)
	{
		r1.x = r1.x + -r2.z;
		ps = c255.z * r1.y;
		r2.z = ps;
	}
	if (p0)
	{
		r1.x = r1.x + -r2.y;
		ps = max(r2.z, r2.z);
		a0 = (int)clamp(floor(r2.z + 0.5), -256.0, 255.0);
	}
	if (p0)
	{
		r10.xyz = r0.xxx * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r11.xyz = r6.www * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r12.xyz = r6.yyy * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r13.xyzw = r8.zzzz * CONST_REL(2 + a0).xyzw + CONST_REL(3 + a0).xyzw;
	}
	if (p0)
	{
		r13.xyzw = r8.yyyy * CONST_REL(1 + a0).xyzw + r13.xyzw;
	}
	if (p0)
	{
		r12.xyz = r1.zzz * CONST_REL(1 + a0).xyz + r12.xyz;
	}
	if (p0)
	{
		r11.xyz = r0.zzz * CONST_REL(1 + a0).xyz + r11.xyz;
	}
	if (p0)
	{
		r10.xyz = r6.xxx * CONST_REL(1 + a0).xyz + r10.xyz;
	}
	if (p0)
	{
		r10.xyz = r0.www * CONST_REL(0 + a0).xyz + r10.xyz;
	}
	if (p0)
	{
		r11.xyz = r6.zzz * CONST_REL(0 + a0).xyz + r11.xyz;
	}
	if (p0)
	{
		r12.xyz = r0.yyy * CONST_REL(0 + a0).xyz + r12.xyz;
	}
	if (p0)
	{
		r13.xyzw = r8.xxxx * CONST_REL(0 + a0).xyzw + r13.xyzw;
	}
	if (p0)
	{
		r7.xyzw = r13.zywx * r2.xxxx + r7.xyzw;
	}
	if (p0)
	{
		r4.xyz = r12.xyz * r2.xxx + r4.xyz;
	}
	if (p0)
	{
		r5.xyz = r11.xyz * r2.xxx + r5.xyz;
	}
	if (p0)
	{
		r3.xyz = r10.xyz * r2.xxx + r3.xyz;
	}
	p0 = r2.w == 0.0 && r1.x > 0.0;
	if (p0)
	{
		ps = c255.z * r1.w;
		r1.y = ps;
	}
	if (p0)
	{
		ps = max(r1.y, r1.y);
		a0 = (int)clamp(floor(r1.y + 0.5), -256.0, 255.0);
	}
	if (p0)
	{
		r11.xyz = r0.xxx * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r12.xyz = r6.www * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r2.xyz = r6.yyy * CONST_REL(2 + a0).xyz;
	}
	if (p0)
	{
		r10.xyzw = r8.zzzz * CONST_REL(2 + a0).xwyz + CONST_REL(3 + a0).xwyz;
	}
	if (p0)
	{
		r10.xyzw = r8.yyyy * CONST_REL(1 + a0).yxzw + r10.zxwy;
	}
	if (p0)
	{
		r2.xyz = r1.zzz * CONST_REL(1 + a0).xyz + r2.xyz;
	}
	if (p0)
	{
		r1.yzw = r0.zzz * CONST_REL(1 + a0).xyz + r12.xyz;
	}
	if (p0)
	{
		r6.xyw = r6.xxx * CONST_REL(1 + a0).xyz + r11.xyz;
	}
	if (p0)
	{
		r0.xzw = r0.www * CONST_REL(0 + a0).xyz + r6.xyw;
	}
	if (p0)
	{
		r1.yzw = r6.zzz * CONST_REL(0 + a0).xyz + r1.yzw;
	}
	if (p0)
	{
		r2.xyz = r0.yyy * CONST_REL(0 + a0).xyz + r2.xyz;
	}
	if (p0)
	{
		r6.xyzw = r8.xxxx * CONST_REL(0 + a0).zywx + r10.zxwy;
	}
	if (p0)
	{
		r7.xyzw = r6.xyzw * r1.xxxx + r7.xyzw;
	}
	if (p0)
	{
		r4.xyz = r2.xyz * r1.xxx + r4.xyz;
	}
	if (p0)
	{
		r5.xyz = r1.yzw * r1.xxx + r5.xyz;
	}
	if (p0)
	{
		r3.xyz = r0.xzw * r1.xxx + r3.xyz;
	}
	r0.xyzw = r7.zzzz * g_mWorldToObject(3).wzxy;
	ps = max(r8.w, r8.w);
	r9.x = ps;
	r0.xyzw = r7.xxxx * g_mWorldToObject(2).wzyx + r0.xywz;
	r0.xyzw = r7.yyyy * g_mWorldToObject(1).yxzw + r0.zwyx;
	r1.xyzw = r7.wwww * g_mWorldToObject(0).zywx + r0.zxwy;
	r0.xyzw = r1.zzzz * g_mWorldViewProjection(3).xyzw;
	r0.xyzw = r1.xxxx * g_mWorldViewProjection(2).xyzw + r0.xyzw;
	r0.xyzw = r1.yyyy * g_mWorldViewProjection(1).xyzw + r0.xyzw;
	r0.xyzw = r1.wwww * g_mWorldViewProjection(0).xyzw + r0.xyzw;
	oPos.xyzw = max(r0.xyzw, r0.xyzw);
	oTexCoord4.xy = max(r9.xy, r9.xy);
	oTexCoord1.xyz = max(r4.xyz, r4.xyz);
	oTexCoord2.xyz = max(r5.xyz, r5.xyz);
	oTexCoord3.xyz = max(r3.xyz, r3.xyz);
	oTexCoord0.xyzw = max(r0.xyzw, r0.xyzw);
#ifdef CONAN_RECOMP
	oPos.xy = oPos.xy * g_ScreenXform.xy + g_ScreenXform.zw * oPos.w;
#endif
	oPos.xy += g_HalfPixelOffset * oPos.w;
	return;
}