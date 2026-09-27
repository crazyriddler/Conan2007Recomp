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

#define GlossMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2688, 0x10)
#define NormalMapUVScale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2672, 0x10)
#define Use_Foam_Texture vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3248, 0x10)
#define Use_Level_Heightmap vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3232, 0x10)
#define alpha_value vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3200, 0x10)
#define ambient_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2656, 0x10)
#define cameraNearFar vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3024, 0x10)
#define crest_curve_power vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3296, 0x10)
#define crestfoam_uv_scale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3280, 0x10)
#define diffuse_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2608, 0x10)
#define diffuse_uv_scroll_speed vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3328, 0x10)
#define distance_fade_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3424, 0x10)
#define distance_fade_position vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3408, 0x10)
#define distance_fade_radius_max vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3456, 0x10)
#define distance_fade_radius_min vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3440, 0x10)
#define dynamic_reflection_brightness vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3392, 0x10)
#define dynamic_reflection_perturbation vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3376, 0x10)
#define eyePosition vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2992, 0x10)
#define foam_uv_attenuation vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3312, 0x10)
#define foam_uvset_scale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3264, 0x10)
#define fresnel_power vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2624, 0x10)
#define g_CloudInfo vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3040, 0x10)
#define g_EnvCubeMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 12)
#define g_EnvCubeMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 76)
#define g_EnvCubeMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 140)
#define g_EnvCubeMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 204)
#define g_FoamMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 16)
#define g_FoamMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 80)
#define g_FoamMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 144)
#define g_FoamMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 208)
#define g_FoamMapTexture2_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 20)
#define g_FoamMapTexture2_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 84)
#define g_FoamMapTexture2_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 148)
#define g_FoamMapTexture2_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 212)
#define g_FogTable_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 48)
#define g_FogTable_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 112)
#define g_FogTable_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 176)
#define g_FogTable_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 240)
#define g_GlossMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 8)
#define g_GlossMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 72)
#define g_GlossMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 136)
#define g_GlossMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 200)
#define g_LevelHeightMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 4)
#define g_LevelHeightMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 68)
#define g_LevelHeightMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 132)
#define g_LevelHeightMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 196)
#define g_LightCookie0_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 24)
#define g_LightCookie0_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 88)
#define g_LightCookie0_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 152)
#define g_LightCookie0_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 216)
#define g_LightCookie1_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 28)
#define g_LightCookie1_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 92)
#define g_LightCookie1_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 156)
#define g_LightCookie1_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 220)
#define g_LightCookie2_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 32)
#define g_LightCookie2_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 96)
#define g_LightCookie2_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 160)
#define g_LightCookie2_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 224)
#define g_LightCookie3_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 36)
#define g_LightCookie3_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 100)
#define g_LightCookie3_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 164)
#define g_LightCookie3_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 228)
#define g_LightingPassCount vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2704, 0x10)
#define g_MatWorldToLevelHeightMap(INDEX) select((INDEX) < 64, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (192 + min(INDEX, 63)) * 16, 0x10), 0.0)
#define g_NormalMapTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 0)
#define g_NormalMapTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 64)
#define g_NormalMapTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 128)
#define g_NormalMapTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 192)
#define g_ParallelLightEnabled vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2720, 0x10)
#define g_ParallelLightShadowTexture_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 40)
#define g_ParallelLightShadowTexture_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 104)
#define g_ParallelLightShadowTexture_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 168)
#define g_ParallelLightShadowTexture_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 232)
#define g_ParallelLights(INDEX) select((INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (0 + min(INDEX, 255)) * 16, 0x10), 0.0)
#define g_ReflectionMap_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 44)
#define g_ReflectionMap_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 108)
#define g_ReflectionMap_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 172)
#define g_ReflectionMap_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 236)
#define g_SceneAmbient vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3056, 0x10)
#define g_ShadowMapTextureAtlas_Texture2DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 52)
#define g_ShadowMapTextureAtlas_Texture3DDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 116)
#define g_ShadowMapTextureAtlas_TextureCubeDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 180)
#define g_ShadowMapTextureAtlas_SamplerDescriptorIndex vk::RawBufferLoad<uint>(g_PushConstants.SharedConstants + 244)
#define g_SpotLightEnabled(INDEX) select((INDEX) < 85, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (171 + min(INDEX, 84)) * 16, 0x10), 0.0)
#define g_SpotLights(INDEX) select((INDEX) < 232, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (24 + min(INDEX, 231)) * 16, 0x10), 0.0)
#define g_WaterLevel vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3168, 0x10)
#define g_WaveMaxAmplitude vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3184, 0x10)
#define g_fTime vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2976, 0x10)
#define g_heightMapMaxZ vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3152, 0x10)
#define g_heightMapMinZ vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3136, 0x10)
#define g_mProjectionToWorld(INDEX) select((INDEX) < 78, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (178 + min(INDEX, 77)) * 16, 0x10), 0.0)
#define g_mReflectionViewProjection(INDEX) select((INDEX) < 74, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (182 + min(INDEX, 73)) * 16, 0x10), 0.0)
#define g_mWorldView(INDEX) select((INDEX) < 81, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + (175 + min(INDEX, 80)) * 16, 0x10), 0.0)
#define reflection_factor vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2592, 0x10)
#define shallow_water_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3344, 0x10)
#define sky_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3216, 0x10)
#define sky_reflectscale vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3360, 0x10)
#define specular_color vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2576, 0x10)
#define specular_power vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2560, 0x10)
#define use_bumpmap vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 2640, 0x10)
#define viewVector vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + 3008, 0x10)
#define CONST_REL(INDEX) select((uint)(INDEX) < 256, vk::RawBufferLoad<float4>(g_PushConstants.PixelShaderConstants + min((uint)(INDEX), 255) * 16, 0x10), 0.0)

#else

cbuffer PixelShaderConstants : register(b1, space4)
{
	float4 g_PixelShaderConstantsArr[256] : packoffset(c0);
};

#define CONST_REL(INDEX) select((uint)(INDEX) < 256, g_PixelShaderConstantsArr[min((uint)(INDEX), 255)], 0.0)
#define GlossMapUVScale g_PixelShaderConstantsArr[168]
#define NormalMapUVScale g_PixelShaderConstantsArr[167]
#define Use_Foam_Texture g_PixelShaderConstantsArr[203]
#define Use_Level_Heightmap g_PixelShaderConstantsArr[202]
#define alpha_value g_PixelShaderConstantsArr[200]
#define ambient_factor g_PixelShaderConstantsArr[166]
#define cameraNearFar g_PixelShaderConstantsArr[189]
#define crest_curve_power g_PixelShaderConstantsArr[206]
#define crestfoam_uv_scale g_PixelShaderConstantsArr[205]
#define diffuse_color g_PixelShaderConstantsArr[163]
#define diffuse_uv_scroll_speed g_PixelShaderConstantsArr[208]
#define distance_fade_factor g_PixelShaderConstantsArr[214]
#define distance_fade_position g_PixelShaderConstantsArr[213]
#define distance_fade_radius_max g_PixelShaderConstantsArr[216]
#define distance_fade_radius_min g_PixelShaderConstantsArr[215]
#define dynamic_reflection_brightness g_PixelShaderConstantsArr[212]
#define dynamic_reflection_perturbation g_PixelShaderConstantsArr[211]
#define eyePosition g_PixelShaderConstantsArr[187]
#define foam_uv_attenuation g_PixelShaderConstantsArr[207]
#define foam_uvset_scale g_PixelShaderConstantsArr[204]
#define fresnel_power g_PixelShaderConstantsArr[164]
#define g_CloudInfo g_PixelShaderConstantsArr[190]
#define g_LightingPassCount g_PixelShaderConstantsArr[169]
#define g_MatWorldToLevelHeightMap(INDEX) CONST_REL(192 + (INDEX))
#define g_ParallelLightEnabled g_PixelShaderConstantsArr[170]
#define g_ParallelLights(INDEX) CONST_REL(0 + (INDEX))
#define g_SceneAmbient g_PixelShaderConstantsArr[191]
#define g_SpotLightEnabled(INDEX) CONST_REL(171 + (INDEX))
#define g_SpotLights(INDEX) CONST_REL(24 + (INDEX))
#define g_WaterLevel g_PixelShaderConstantsArr[198]
#define g_WaveMaxAmplitude g_PixelShaderConstantsArr[199]
#define g_fTime g_PixelShaderConstantsArr[186]
#define g_heightMapMaxZ g_PixelShaderConstantsArr[197]
#define g_heightMapMinZ g_PixelShaderConstantsArr[196]
#define g_mProjectionToWorld(INDEX) CONST_REL(178 + (INDEX))
#define g_mReflectionViewProjection(INDEX) CONST_REL(182 + (INDEX))
#define g_mWorldView(INDEX) CONST_REL(175 + (INDEX))
#define reflection_factor g_PixelShaderConstantsArr[162]
#define shallow_water_color g_PixelShaderConstantsArr[209]
#define sky_color g_PixelShaderConstantsArr[201]
#define sky_reflectscale g_PixelShaderConstantsArr[210]
#define specular_color g_PixelShaderConstantsArr[161]
#define specular_power g_PixelShaderConstantsArr[160]
#define use_bumpmap g_PixelShaderConstantsArr[165]
#define viewVector g_PixelShaderConstantsArr[188]

cbuffer SharedConstants : register(b2, space4)
{
	uint g_EnvCubeMapTexture_Texture2DDescriptorIndex : packoffset(c0.w);
	uint g_EnvCubeMapTexture_Texture3DDescriptorIndex : packoffset(c4.w);
	uint g_EnvCubeMapTexture_TextureCubeDescriptorIndex : packoffset(c8.w);
	uint g_EnvCubeMapTexture_SamplerDescriptorIndex : packoffset(c12.w);
	uint g_FoamMapTexture_Texture2DDescriptorIndex : packoffset(c1.x);
	uint g_FoamMapTexture_Texture3DDescriptorIndex : packoffset(c5.x);
	uint g_FoamMapTexture_TextureCubeDescriptorIndex : packoffset(c9.x);
	uint g_FoamMapTexture_SamplerDescriptorIndex : packoffset(c13.x);
	uint g_FoamMapTexture2_Texture2DDescriptorIndex : packoffset(c1.y);
	uint g_FoamMapTexture2_Texture3DDescriptorIndex : packoffset(c5.y);
	uint g_FoamMapTexture2_TextureCubeDescriptorIndex : packoffset(c9.y);
	uint g_FoamMapTexture2_SamplerDescriptorIndex : packoffset(c13.y);
	uint g_FogTable_Texture2DDescriptorIndex : packoffset(c3.x);
	uint g_FogTable_Texture3DDescriptorIndex : packoffset(c7.x);
	uint g_FogTable_TextureCubeDescriptorIndex : packoffset(c11.x);
	uint g_FogTable_SamplerDescriptorIndex : packoffset(c15.x);
	uint g_GlossMapTexture_Texture2DDescriptorIndex : packoffset(c0.z);
	uint g_GlossMapTexture_Texture3DDescriptorIndex : packoffset(c4.z);
	uint g_GlossMapTexture_TextureCubeDescriptorIndex : packoffset(c8.z);
	uint g_GlossMapTexture_SamplerDescriptorIndex : packoffset(c12.z);
	uint g_LevelHeightMapTexture_Texture2DDescriptorIndex : packoffset(c0.y);
	uint g_LevelHeightMapTexture_Texture3DDescriptorIndex : packoffset(c4.y);
	uint g_LevelHeightMapTexture_TextureCubeDescriptorIndex : packoffset(c8.y);
	uint g_LevelHeightMapTexture_SamplerDescriptorIndex : packoffset(c12.y);
	uint g_LightCookie0_Texture2DDescriptorIndex : packoffset(c1.z);
	uint g_LightCookie0_Texture3DDescriptorIndex : packoffset(c5.z);
	uint g_LightCookie0_TextureCubeDescriptorIndex : packoffset(c9.z);
	uint g_LightCookie0_SamplerDescriptorIndex : packoffset(c13.z);
	uint g_LightCookie1_Texture2DDescriptorIndex : packoffset(c1.w);
	uint g_LightCookie1_Texture3DDescriptorIndex : packoffset(c5.w);
	uint g_LightCookie1_TextureCubeDescriptorIndex : packoffset(c9.w);
	uint g_LightCookie1_SamplerDescriptorIndex : packoffset(c13.w);
	uint g_LightCookie2_Texture2DDescriptorIndex : packoffset(c2.x);
	uint g_LightCookie2_Texture3DDescriptorIndex : packoffset(c6.x);
	uint g_LightCookie2_TextureCubeDescriptorIndex : packoffset(c10.x);
	uint g_LightCookie2_SamplerDescriptorIndex : packoffset(c14.x);
	uint g_LightCookie3_Texture2DDescriptorIndex : packoffset(c2.y);
	uint g_LightCookie3_Texture3DDescriptorIndex : packoffset(c6.y);
	uint g_LightCookie3_TextureCubeDescriptorIndex : packoffset(c10.y);
	uint g_LightCookie3_SamplerDescriptorIndex : packoffset(c14.y);
	uint g_NormalMapTexture_Texture2DDescriptorIndex : packoffset(c0.x);
	uint g_NormalMapTexture_Texture3DDescriptorIndex : packoffset(c4.x);
	uint g_NormalMapTexture_TextureCubeDescriptorIndex : packoffset(c8.x);
	uint g_NormalMapTexture_SamplerDescriptorIndex : packoffset(c12.x);
	uint g_ParallelLightShadowTexture_Texture2DDescriptorIndex : packoffset(c2.z);
	uint g_ParallelLightShadowTexture_Texture3DDescriptorIndex : packoffset(c6.z);
	uint g_ParallelLightShadowTexture_TextureCubeDescriptorIndex : packoffset(c10.z);
	uint g_ParallelLightShadowTexture_SamplerDescriptorIndex : packoffset(c14.z);
	uint g_ReflectionMap_Texture2DDescriptorIndex : packoffset(c2.w);
	uint g_ReflectionMap_Texture3DDescriptorIndex : packoffset(c6.w);
	uint g_ReflectionMap_TextureCubeDescriptorIndex : packoffset(c10.w);
	uint g_ReflectionMap_SamplerDescriptorIndex : packoffset(c14.w);
	uint g_ShadowMapTextureAtlas_Texture2DDescriptorIndex : packoffset(c3.y);
	uint g_ShadowMapTextureAtlas_Texture3DDescriptorIndex : packoffset(c7.y);
	uint g_ShadowMapTextureAtlas_TextureCubeDescriptorIndex : packoffset(c11.y);
	uint g_ShadowMapTextureAtlas_SamplerDescriptorIndex : packoffset(c15.y);
	DEFINE_SHARED_CONSTANTS();
};

#endif
	#define Use_Dynamic_Reflections BOOL_BIT(130)
	#define Use_EnvCubeMap_Texture BOOL_BIT(129)
	#define Use_Gloss_Texture BOOL_BIT(128)

#ifndef __spirv__
[shader("pixel")]
#endif
void main(
	in float4 iPos : SV_Position,
	in float4 iTexCoord0 : TEXCOORD0,
	in float4 iTexCoord1 : TEXCOORD1,
	in float4 iTexCoord2 : TEXCOORD2,
	in float4 iTexCoord3 : TEXCOORD3,
	in float4 iTexCoord4 : TEXCOORD4,
	in float4 iTexCoord5 : TEXCOORD5,
	in float4 iTexCoord6 : TEXCOORD6,
	in float4 iTexCoord7 : TEXCOORD7,
	in float4 iTexCoord8 : TEXCOORD8,
	in float4 iTexCoord9 : TEXCOORD9,
	in float4 iTexCoord10 : TEXCOORD10,
	in float4 iTexCoord11 : TEXCOORD11,
	in float4 iTexCoord12 : TEXCOORD12,
	in float4 iTexCoord13 : TEXCOORD13,
	in float4 iTexCoord14 : TEXCOORD14,
	in float4 iTexCoord15 : TEXCOORD15,
	in float4 iColor0 : COLOR0,
	in float4 iColor1 : COLOR1,
#ifdef __spirv__
	in bool iFace : SV_IsFrontFace
#else
	in uint iFace : SV_IsFrontFace
#endif
,
	out float4 oC0 : SV_Target0)
{
	float4 c252 = asfloat(uint4(0x0, 0x0, 0x0, 0x0));
	float4 c253 = asfloat(uint4(0x0, 0x3F800000, 0x3F000000, 0x40400000));
	float4 c254 = asfloat(uint4(0x3F13BB63, 0x3FB8AA3B, 0xBF800000, 0x3FC00000));
	float4 c255 = asfloat(uint4(0x40000000, 0x0, 0x0, 0x0));

	float4 r0 = iTexCoord0;
	float4 r1 = iTexCoord1;
	float4 r2 = iTexCoord2;
	float4 r3 = iTexCoord3;
	float4 r4 = iTexCoord4;
	float4 r5 = iColor0;
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
	float2 pixelCoord = 0.0;
	CubeMapData cubeMapData = (CubeMapData)0;

	r1.w = dot(r1.zxy, r1.zxy);
	r2.xyzw = r0.wwww * g_mProjectionToWorld(3).wxyz;
	ps = clamp(rcp(NormalMapUVScale.x), FLT_MIN, FLT_MAX);
	r5.z = ps;
	r6.xyzw = r0.zzzz * g_mProjectionToWorld(2).wxyz + r2.xyzw;
	r2.xy = diffuse_uv_scroll_speed.xy * g_fTime.xx;
	ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
	r2.w = ps;
	r1.xy = r2.ww * r1.xy;
	ps = clamp(rcp(NormalMapUVScale.y), FLT_MIN, FLT_MAX);
	r5.w = ps;
	r6.xyzw = r0.yyyy * g_mProjectionToWorld(1).wxyz + r6.xyzw;
	r7.xyzw = r0.xxxx * g_mProjectionToWorld(0).wxyz + r6.xyzw;
	r5.xy = r1.xy * c253.zz;
	ps = clamp(rcp(r7.x), FLT_MIN, FLT_MAX);
	r1.w = ps;
	r5.zw = r5.zw * r1.ww;
	r6.xy = r5.wz * r7.zy + r2.yx;
	r5.xy = r5.wz * r7.zy + r5.yx;
// conan_tfetch slot=0 mag=3 min=3 mip=3 aniso=7
	pixelCoord = getPixelCoord(g_NormalMapTexture_Texture2DDescriptorIndex, r5.yx);
	r5.xyz = tfetch2D(g_NormalMapTexture_Texture2DDescriptorIndex, g_NormalMapTexture_SamplerDescriptorIndex, r5.yx, float2(0, 0)).xyz;
// conan_tfetch slot=0 mag=3 min=3 mip=3 aniso=7
	pixelCoord = getPixelCoord(g_NormalMapTexture_Texture2DDescriptorIndex, r6.yx);
	r6.xyz = tfetch2D(g_NormalMapTexture_Texture2DDescriptorIndex, g_NormalMapTexture_SamplerDescriptorIndex, r6.yx, float2(0, 0)).xyz;
	r2.z = dot(r3.zxy, r3.zxy);
	r8.xyz = r6.xyz * c255.xxx + c254.zzz;
	r9.xyz = r5.xyz * c255.xxx + c254.zzz;
	r5.x = r2.w * r1.z;
	ps = clamp(rsqrt(abs(r2.z)), FLT_MIN, FLT_MAX);
	r2.z = ps;
	r1.z = dot(r4.zxy, r4.zxy);
	r6.xyz = r2.zzz * r3.zxy;
	ps = clamp(rsqrt(abs(r1.z)), FLT_MIN, FLT_MAX);
	r1.z = ps;
	r5.yzw = r1.zzz * r4.zxy;
	r2.z = dot(r9.zxy, r9.zxy);
	r1.z = dot(r8.zxy, r8.zxy);
	ps = clamp(rsqrt(abs(r2.z)), FLT_MIN, FLT_MAX);
	r2.z = ps;
	r3.xyz = r9.xyz * r2.zzz;
	ps = clamp(rsqrt(abs(r1.z)), FLT_MIN, FLT_MAX);
	r1.z = ps;
	r3.xyz = r8.xyz * r1.zzz + r3.xyz;
	r13.xyz = r7.yzw * r1.www;
	r7.xyz = -r13.xyz + eyePosition.xyz;
	r1.w = dot(r3.zxy, r3.zxy);
	r1.z = dot(r7.zxy, r7.zxy);
	ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
	r1.w = ps;
	r4.xyz = r3.xyz * r1.www;
	r3.xy = r4.yy * r5.zw;
	ps = clamp(rsqrt(abs(r1.z)), FLT_MIN, FLT_MAX);
	r1.z = ps;
	r7.xyz = r7.xyz * r1.zzz;
	r3.z = dot(r4.zy, r5.xy) + c253.x;
	r3.xyz = r4.xxx * r6.yzx + r3.xyz;
	r5.z = select(use_bumpmap.x > 0.0, r3.z, r5.x);
	r1.zw = r4.zz * r1.xy + r3.xy;
	r5.xy = select(use_bumpmap.xx > 0.0, r1.zw, r1.xy);
	if (!Use_Gloss_Texture)
	{
		ps = max(c253.y, c253.y);
		r5.w = ps;
	}
	else
	{
		ps = clamp(rcp(GlossMapUVScale.x), FLT_MIN, FLT_MAX);
		r1.z = ps;
		ps = clamp(rcp(GlossMapUVScale.y), FLT_MIN, FLT_MAX);
		r1.w = ps;
		r1.zw = r13.yx * r1.wz + r2.yx;
// conan_tfetch slot=2 mag=3 min=3 mip=3 aniso=7
		r5.w = tfetch2D(g_GlossMapTexture_Texture2DDescriptorIndex, g_GlossMapTexture_SamplerDescriptorIndex, r1.wz, float2(0, 0)).x;
	}
	ps = clamp(rcp(crestfoam_uv_scale.x), FLT_MIN, FLT_MAX);
	r2.z = ps;
	r1.yz = r1.yx * foam_uv_attenuation.yx;
	ps = clamp(rcp(crestfoam_uv_scale.y), FLT_MIN, FLT_MAX);
	r2.w = ps;
	r1.xw = r13.xy * r2.zw + r2.xy;
	r1.xw = r1.yz * c253.zz + r1.wx;
// conan_tfetch slot=5 mag=3 min=3 mip=3 aniso=7
	r2.xyz = tfetch2D(g_FoamMapTexture2_Texture2DDescriptorIndex, g_FoamMapTexture2_SamplerDescriptorIndex, r1.wx, float2(0, 0)).xyz;
	r1.x = r13.z + -g_WaterLevel.x;
	ps = clamp(rcp(g_WaveMaxAmplitude.x), FLT_MIN, FLT_MAX);
	r0.y = ps;
	r2.xyz = r2.xyz + -diffuse_color.xyz;
	ps = max(r1.x, r1.x);
	r1.x = dot(-r7.zxy, r5.zxy);
	ps = saturate(r0.y * ps);
	r0.y = ps;
	r1.x = r1.x + r1.x;
	ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
	r0.y = ps;
	r3.xyz = -r1.xxx * r5.xyz + -r7.xyz;
	ps = crest_curve_power.x * r0.y;
	r1.w = ps;
	r1.x = dot(r3.zxy, r3.zxy);
	ps = exp2(r1.w);
	r1.w = ps;
	r2.yzw = r2.xyz * r1.www + diffuse_color.xyz;
	ps = clamp(rsqrt(abs(r1.x)), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r10.xyz = r3.xyz * r1.xxx;
	p0 = Use_Level_Heightmap.x != 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r3.xyz = r13.zzz * g_MatWorldToLevelHeightMap(2).wxy + g_MatWorldToLevelHeightMap(3).wxy;
		r3.xyz = r13.yyy * g_MatWorldToLevelHeightMap(1).wxy + r3.xyz;
		r3.xyz = r13.xxx * g_MatWorldToLevelHeightMap(0).wxy + r3.xyz;
		ps = clamp(rcp(r3.x), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r1.xw = r3.zy * r0.xx;
// conan_tfetch slot=1 mag=3 min=3 mip=3 aniso=7
		r0.x = tfetch2D(g_LevelHeightMapTexture_Texture2DDescriptorIndex, g_LevelHeightMapTexture_SamplerDescriptorIndex, r1.wx, float2(0, 0)).x;
		r1.x = g_heightMapMaxZ.x + -g_heightMapMinZ.x;
		r0.x = r1.x * r0.x + g_heightMapMinZ.x;
		r0.x = -r0.x + r13.z;
		r0.x = max(r0.x, c253.x);
		r3.xy = -r0.xx * c254.xy;
		p0 = Use_Foam_Texture.x == 0.0;
		ps = p0 ? 0.0 : 1.0;
		ps = exp2(r3.y);
		r1.x = ps;
		ps = exp2(r3.x);
		r0.x = ps;
		if (p0)
		{
			r8.xyz = max(c253.yyy, c253.yyy);
			ps = max(r1.x, r1.x);
			r3.w = ps;
		}
		else
		{
			ps = clamp(rcp(foam_uvset_scale.x), FLT_MIN, FLT_MAX);
			r3.x = ps;
			ps = clamp(rcp(foam_uvset_scale.y), FLT_MIN, FLT_MAX);
			r3.y = ps;
			r1.yz = r13.yx * r3.yx + r1.yz;
// conan_tfetch slot=4 mag=3 min=3 mip=3 aniso=7
			r8.xyzw = tfetch2D(g_FoamMapTexture_Texture2DDescriptorIndex, g_FoamMapTexture_SamplerDescriptorIndex, r1.zy, float2(0, 0)).xyzw;
			r3.w = r1.x * r8.w;
		}
		r4.yzw = -r2.yzw + shallow_water_color.xyz;
		ps = c253.y - r0.x;
		r0.y = ps;
		r0.y = saturate(min(r0.y, alpha_value.x));
		ps = -alpha_value.x - -r0.y;
		r4.x = ps;
		r2.yzw = r4.yzw * r1.xxx + r2.yzw;
		r2.x = r4.x * r1.x + alpha_value.x;
	}
	else
	{
		ps = -abs(r0.x) > 0.0;
		r3.w = ps;
		r8.xyz = -abs(r0.xxx) > c253.xxx;
		ps = max(alpha_value.x, alpha_value.x);
		r2.x = ps;
	}
	p0 = g_LightingPassCount.x == 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		if (Use_Dynamic_Reflections)
		{
			r1.xyz = r13.zzz * g_mReflectionViewProjection(2).wxy + g_mReflectionViewProjection(3).wxy;
			r3.xy = r5.zz * g_mWorldView(2).xz;
			r3.xy = r5.yy * g_mWorldView(1).xz + r3.xy;
			r1.xyz = r13.yyy * g_mReflectionViewProjection(1).wxy + r1.xyz;
			r1.yzw = r13.xxx * g_mReflectionViewProjection(0).wxy + r1.xyz;
			r3.xz = r5.xx * g_mWorldView(0).xz + r3.xy;
			r3.y = r3.z * c254.z;
			ps = clamp(rcp(r1.y), FLT_MIN, FLT_MAX);
			r1.x = ps;
			r1.yz = r3.xy * dynamic_reflection_perturbation.xx + r1.zw;
			r1.xy = r1.zy * r1.xx;
// conan_tfetch slot=11 mag=3 min=3 mip=3 aniso=7
			r1.xyz = tfetch2D(g_ReflectionMap_Texture2DDescriptorIndex, g_ReflectionMap_SamplerDescriptorIndex, r1.yx, float2(0, 0)).xyz;
			r1.xyz = r1.xyz * reflection_factor.xxx;
			r9.xyz = r1.xyz * dynamic_reflection_brightness.xxx;
		}
		else
		{
			if (Use_EnvCubeMap_Texture)
			{
				r1.xyzw = cube(r10.xyzz, cubeMapData);
				r3.z = max(r1.w, r1.w);
				ps = clamp(rcp(abs(r1.z)), FLT_MIN, FLT_MAX);
				r3.x = ps;
				r3.xy = r1.yx * r3.xx + c254.ww;
// conan_tfetch slot=3 mag=3 min=3 mip=3 aniso=7
				r1.xyz = tfetchCube(g_EnvCubeMapTexture_TextureCubeDescriptorIndex, g_EnvCubeMapTexture_SamplerDescriptorIndex, r3.xyz, cubeMapData).xyz;
				r1.xyz = r1.xyz + -sky_color.xyz;
				r9.xyz = r1.xyz * sky_reflectscale.xxx + sky_color.xyz;
			}
			else
			{
				r9.xyz = max(sky_color.xyz, sky_color.xyz);
			}
		}
	}
	else
	{
		r9.xyz = -abs(r0.xxx) > c253.xxx;
	}
	r1.xy = r13.xy + -distance_fade_position.xy;
	r1.y = dot(r1.xy, r1.xy) + c253.x;
	r1.x = distance_fade_radius_max.x + -distance_fade_radius_min.x;
	ps = sqrt(abs(r1.y));
	r1.y = ps;
	r1.y = r1.y + -distance_fade_radius_min.x;
	ps = clamp(rcp(r1.x), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r1.x = saturate(r1.y * r1.x);
	r1.y = r1.x * r1.x;
	ps = -abs(r0.x) > 0.0;
	r3.x = ps;
	r1.x = -r1.x * c255.x + c253.w;
	r1.x = r1.y * r1.x;
	p0 = g_LightingPassCount.x == 0.0;
	ps = p0 ? 0.0 : 1.0;
	r6.z = -r1.x * distance_fade_factor.x + c253.y;
	if (p0)
	{
		r1.xyz = r8.xyz * g_SceneAmbient.xyz;
		r3.xyz = r1.xyz * ambient_factor.xxx;
	}
	else
	{
		r3.yz = -abs(r0.xx) > c253.xx;
	}
	int aLSave0 = aL;
	uint loopConst0 = g_LoopConstant(16);
	[loop] for (uint loopIt0 = 0; loopIt0 < LOOP_COUNT(loopConst0); loopIt0++)
	{
		aL = LOOP_START(loopConst0) + int(loopIt0) * LOOP_STEP(loopConst0);
	}
	aL = aLSave0;
	p0 = g_SpotLightEnabled(0).x > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r4.xyzw = r13.zzzz * g_SpotLights(2).wxyz + g_SpotLights(3).wxyz;
		r1.xyz = -r13.xyz + g_SpotLights(7).xyz;
		r4.xyzw = r13.yyyy * g_SpotLights(1).wxyz + r4.xyzw;
		r4.xyzw = r13.xxxx * g_SpotLights(0).zyxw + r4.wzyx;
		r0.x = dot(r1.zxy, r1.zxy);
		ps = g_SpotLights(5).z * r0.x;
		r1.w = ps;
		ps = clamp(log2(abs(r1.w)), FLT_MIN, FLT_MAX);
		r1.w = ps;
		r1.w = r1.w * g_SpotLights(5).w;
		ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r1.xyz = r1.xyz * r0.xxx;
		ps = saturate(exp2(r1.w));
		r0.x = ps;
		r0.x = -r0.x + c253.y;
		p0 = -r4.w > 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = -abs(r0.x) > 0.0;
			r0.x = ps;
		}
		ps = clamp(rcp(r4.w), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r11.xyz = r4.xyz * r0.yyy;
		r4.xy = saturate(max(r11.zy, r11.zy));
		r6.xy = r4.yx * g_SpotLights(9).yx + g_SpotLights(9).wz;
// conan_tfetch slot=6 mag=3 min=3 mip=3 aniso=7
		r4.yzw = tfetch2D(g_LightCookie0_Texture2DDescriptorIndex, g_LightCookie0_SamplerDescriptorIndex, r11.zy, float2(0, 0)).xyz;
// conan_tfetch slot=13 mag=3 min=3 mip=3 aniso=7
		r1.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r6.yx, float2(0, 0)).x;
		r4.x = saturate(dot(r1.zxy, r5.zxy));
		r0.y = saturate(dot(r1.zxy, r10.zxy));
		r1.x = max(r11.x, c253.x);
		ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r1.x = r1.w > r1.x;
		ps = r1.x != 0.0;
		r1.x = ps;
		r1.x = select(-r6.y > 0.0, c253.y, r1.x);
		r1.x = select(-abs(g_SpotLights(6).x) >= 0.0, abs(c253.y), r1.x);
		r1.xyz = r1.xxx * r4.yzw;
		r1.xyz = r1.xyz * g_SpotLights(4).xyz;
		r4.yzw = r1.xyz * r0.xxx;
		r1.yzw = r4.yzw * r5.www;
		ps = specular_power.x * r0.y;
		r1.x = ps;
		r4.xyz = r4.yzw * r4.xxx;
		p0 = g_SpotLightEnabled(1).x > 0.0;
		ps = p0 ? 0.0 : 1.0;
		r3.xyz = r4.xyz * r8.xyz + r3.xyz;
		r1.yzw = r1.yzw * specular_color.xyz;
		ps = exp2(r1.x);
		r1.x = ps;
		r9.xyz = r1.yzw * r1.xxx + r9.xyz;
		if (p0)
		{
			r4.xyzw = r13.zzzz * g_SpotLights(12).wxyz + g_SpotLights(13).wxyz;
			r1.xyz = -r13.xyz + g_SpotLights(17).xyz;
			r4.xyzw = r13.yyyy * g_SpotLights(11).wxyz + r4.xyzw;
			r4.xyzw = r13.xxxx * g_SpotLights(10).zyxw + r4.wzyx;
			r0.x = dot(r1.zxy, r1.zxy);
			ps = g_SpotLights(15).z * r0.x;
			r1.w = ps;
			ps = clamp(log2(abs(r1.w)), FLT_MIN, FLT_MAX);
			r1.w = ps;
			r1.w = r1.w * g_SpotLights(15).w;
			ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
			r0.x = ps;
			r1.xyz = r1.xyz * r0.xxx;
			ps = saturate(exp2(r1.w));
			r0.x = ps;
			r0.x = -r0.x + c253.y;
			p0 = -r4.w > 0.0;
			ps = p0 ? 0.0 : 1.0;
			if (p0)
			{
				ps = -abs(r0.x) > 0.0;
				r0.x = ps;
			}
			ps = clamp(rcp(r4.w), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r11.xyz = r4.xyz * r0.yyy;
			r4.xy = saturate(max(r11.zy, r11.zy));
			r6.xy = r4.yx * g_SpotLights(19).yx + g_SpotLights(19).wz;
// conan_tfetch slot=7 mag=3 min=3 mip=3 aniso=7
			r4.yzw = tfetch2D(g_LightCookie1_Texture2DDescriptorIndex, g_LightCookie1_SamplerDescriptorIndex, r11.zy, float2(0, 0)).xyz;
// conan_tfetch slot=13 mag=3 min=3 mip=3 aniso=7
			r1.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r6.yx, float2(0, 0)).x;
			r4.x = saturate(dot(r1.zxy, r5.zxy));
			r0.y = saturate(dot(r1.zxy, r10.zxy));
			r1.x = max(r11.x, c253.x);
			ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
			r0.y = ps;
			r1.x = r1.w > r1.x;
			ps = r1.x != 0.0;
			r1.x = ps;
			r1.x = select(-r6.y > 0.0, c253.y, r1.x);
			r1.x = select(-abs(g_SpotLights(16).x) >= 0.0, abs(c253.y), r1.x);
			r1.xyz = r1.xxx * r4.yzw;
			r1.xyz = r1.xyz * g_SpotLights(14).xyz;
			r4.yzw = r1.xyz * r0.xxx;
			r1.yzw = r4.yzw * r5.www;
			ps = specular_power.x * r0.y;
			r1.x = ps;
			r4.xyz = r4.yzw * r4.xxx;
			p0 = g_SpotLightEnabled(2).x > 0.0;
			ps = p0 ? 0.0 : 1.0;
			r3.xyz = r4.xyz * r8.xyz + r3.xyz;
			r1.yzw = r1.yzw * specular_color.xyz;
			ps = exp2(r1.x);
			r1.x = ps;
			r9.xyz = r1.yzw * r1.xxx + r9.xyz;
			if (p0)
			{
				r4.xyzw = r13.zzzz * g_SpotLights(22).wxyz + g_SpotLights(23).wxyz;
				r1.xyz = -r13.xyz + g_SpotLights(27).xyz;
				r4.xyzw = r13.yyyy * g_SpotLights(21).wxyz + r4.xyzw;
				r4.xyzw = r13.xxxx * g_SpotLights(20).zyxw + r4.wzyx;
				r0.x = dot(r1.zxy, r1.zxy);
				ps = g_SpotLights(25).z * r0.x;
				r1.w = ps;
				ps = clamp(log2(abs(r1.w)), FLT_MIN, FLT_MAX);
				r1.w = ps;
				r1.w = r1.w * g_SpotLights(25).w;
				ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
				r0.x = ps;
				r1.xyz = r1.xyz * r0.xxx;
				ps = saturate(exp2(r1.w));
				r0.x = ps;
				r0.x = -r0.x + c253.y;
				p0 = -r4.w > 0.0;
				ps = p0 ? 0.0 : 1.0;
				if (p0)
				{
					ps = -abs(r0.x) > 0.0;
					r0.x = ps;
				}
				ps = clamp(rcp(r4.w), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r11.xyz = r4.xyz * r0.yyy;
				r4.xy = saturate(max(r11.zy, r11.zy));
				r6.xy = r4.yx * g_SpotLights(29).yx + g_SpotLights(29).wz;
// conan_tfetch slot=8 mag=3 min=3 mip=3 aniso=7
				r4.yzw = tfetch2D(g_LightCookie2_Texture2DDescriptorIndex, g_LightCookie2_SamplerDescriptorIndex, r11.zy, float2(0, 0)).xyz;
// conan_tfetch slot=13 mag=3 min=3 mip=3 aniso=7
				r1.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r6.yx, float2(0, 0)).x;
				r4.x = saturate(dot(r1.zxy, r5.zxy));
				r0.y = saturate(dot(r1.zxy, r10.zxy));
				r1.x = max(r11.x, c253.x);
				ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
				r0.y = ps;
				r1.x = r1.w > r1.x;
				ps = r1.x != 0.0;
				r1.x = ps;
				r1.x = select(-r6.y > 0.0, c253.y, r1.x);
				r1.x = select(-abs(g_SpotLights(26).x) >= 0.0, abs(c253.y), r1.x);
				r1.xyz = r1.xxx * r4.yzw;
				r1.xyz = r1.xyz * g_SpotLights(24).xyz;
				r4.yzw = r1.xyz * r0.xxx;
				r1.yzw = r4.yzw * r5.www;
				ps = specular_power.x * r0.y;
				r1.x = ps;
				r4.xyz = r4.yzw * r4.xxx;
				p0 = g_SpotLightEnabled(3).x > 0.0;
				ps = p0 ? 0.0 : 1.0;
				r3.xyz = r4.xyz * r8.xyz + r3.xyz;
				r1.yzw = r1.yzw * specular_color.xyz;
				ps = exp2(r1.x);
				r1.x = ps;
				r9.xyz = r1.yzw * r1.xxx + r9.xyz;
				if (p0)
				{
					r4.xyzw = r13.zzzz * g_SpotLights(32).wxyz + g_SpotLights(33).wxyz;
					r1.xyz = -r13.xyz + g_SpotLights(37).xyz;
					r4.xyzw = r13.yyyy * g_SpotLights(31).wxyz + r4.xyzw;
					r4.xyzw = r13.xxxx * g_SpotLights(30).zyxw + r4.wzyx;
					r0.x = dot(r1.zxy, r1.zxy);
					ps = g_SpotLights(35).z * r0.x;
					r1.w = ps;
					ps = clamp(log2(abs(r1.w)), FLT_MIN, FLT_MAX);
					r1.w = ps;
					r1.w = r1.w * g_SpotLights(35).w;
					ps = clamp(rsqrt(abs(r0.x)), FLT_MIN, FLT_MAX);
					r0.x = ps;
					r1.xyz = r1.xyz * r0.xxx;
					ps = saturate(exp2(r1.w));
					r0.x = ps;
					r0.x = -r0.x + c253.y;
					p0 = -r4.w > 0.0;
					ps = p0 ? 0.0 : 1.0;
					if (p0)
					{
						ps = -abs(r0.x) > 0.0;
						r0.x = ps;
					}
					ps = clamp(rcp(r4.w), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r11.xyz = r4.xyz * r0.yyy;
					r4.xy = saturate(max(r11.zy, r11.zy));
					r6.xy = r4.yx * g_SpotLights(39).yx + g_SpotLights(39).wz;
// conan_tfetch slot=9 mag=3 min=3 mip=3 aniso=7
					r4.yzw = tfetch2D(g_LightCookie3_Texture2DDescriptorIndex, g_LightCookie3_SamplerDescriptorIndex, r11.zy, float2(0, 0)).xyz;
// conan_tfetch slot=13 mag=3 min=3 mip=3 aniso=7
					r1.w = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r6.yx, float2(0, 0)).x;
					r4.x = saturate(dot(r1.zxy, r5.zxy));
					r0.y = saturate(dot(r1.zxy, r10.zxy));
					r1.x = max(r11.x, c253.x);
					ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
					r0.y = ps;
					r1.x = r1.w > r1.x;
					ps = r1.x != 0.0;
					r1.x = ps;
					r1.x = select(-r6.y > 0.0, c253.y, r1.x);
					r1.x = select(-abs(g_SpotLights(36).x) >= 0.0, abs(c253.y), r1.x);
					r1.xyz = r1.xxx * r4.yzw;
					r1.xyz = r1.xyz * g_SpotLights(34).xyz;
					r4.yzw = r1.xyz * r0.xxx;
					r1.yzw = r4.yzw * r5.www;
					r4.xyz = r4.yzw * r4.xxx;
					ps = specular_power.x * r0.y;
					r1.x = ps;
					r3.xyz = r4.xyz * r8.xyz + r3.xyz;
					r1.yzw = r1.yzw * specular_color.xyz;
					ps = exp2(r1.x);
					r1.x = ps;
					r9.xyz = r1.yzw * r1.xxx + r9.xyz;
				}
			}
		}
	}
	p0 = g_ParallelLightEnabled.x > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r11.z = max(g_ParallelLights(14).w, g_ParallelLights(14).w);
		ps = max(g_ParallelLights(15).z, g_ParallelLights(15).z);
		r1.z = ps;
		r11.y = max(g_ParallelLights(13).w, g_ParallelLights(13).w);
		ps = max(g_ParallelLights(14).z, g_ParallelLights(14).z);
		r4.z = ps;
		r11.x = max(g_ParallelLights(12).w, g_ParallelLights(12).w);
		ps = max(g_ParallelLights(13).z, g_ParallelLights(13).z);
		r4.y = ps;
		r1.xy = max(g_ParallelLights(23).wz, g_ParallelLights(23).wz);
		ps = max(g_ParallelLights(12).z, g_ParallelLights(12).z);
		r4.x = ps;
		r12.xy = max(g_ParallelLights(14).xy, g_ParallelLights(14).xy);
		ps = max(g_ParallelLights(23).y, g_ParallelLights(23).y);
		r6.y = ps;
		r12.zw = max(g_ParallelLights(13).xy, g_ParallelLights(13).xy);
		ps = max(g_ParallelLights(23).x, g_ParallelLights(23).x);
		r6.x = ps;
		r15.xyz = max(g_ParallelLights(15).wxy, g_ParallelLights(15).wxy);
		ps = max(g_ParallelLights(12).y, g_ParallelLights(12).y);
		r0.x = ps;
		r1.w = dot(g_ParallelLights(19).zxy, g_ParallelLights(19).zxy);
		ps = clamp(rcp(r0.w), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r0.z = r0.y * r0.z;
		ps = max(g_ParallelLights(12).x, g_ParallelLights(12).x);
		r0.y = ps;
		r0.w = g_ParallelLights(16).z > r0.z;
		ps = clamp(rsqrt(abs(r1.w)), FLT_MIN, FLT_MAX);
		r1.w = ps;
		r14.xyz = r1.www * g_ParallelLights(19).xyz;
		p0 = r0.w != 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = max(g_ParallelLights(11).z, g_ParallelLights(11).z);
			r1.z = ps;
		}
		if (p0)
		{
			r4.z = max(g_ParallelLights(10).z, g_ParallelLights(10).z);
			ps = max(g_ParallelLights(10).w, g_ParallelLights(10).w);
			r11.z = ps;
		}
		if (p0)
		{
			r4.y = max(g_ParallelLights(9).z, g_ParallelLights(9).z);
			ps = max(g_ParallelLights(9).w, g_ParallelLights(9).w);
			r11.y = ps;
		}
		if (p0)
		{
			r4.x = max(g_ParallelLights(8).z, g_ParallelLights(8).z);
			ps = max(g_ParallelLights(8).w, g_ParallelLights(8).w);
			r11.x = ps;
		}
		if (p0)
		{
			r6.xy = max(g_ParallelLights(22).xy, g_ParallelLights(22).xy);
			ps = max(g_ParallelLights(22).w, g_ParallelLights(22).w);
			r1.x = ps;
		}
		if (p0)
		{
			r12.xy = max(g_ParallelLights(10).xy, g_ParallelLights(10).xy);
			ps = max(g_ParallelLights(22).z, g_ParallelLights(22).z);
			r1.y = ps;
		}
		if (p0)
		{
			r0.xy = max(g_ParallelLights(8).yx, g_ParallelLights(8).yx);
			ps = max(g_ParallelLights(9).y, g_ParallelLights(9).y);
			r12.w = ps;
		}
		if (p0)
		{
			r15.xyz = max(g_ParallelLights(11).wxy, g_ParallelLights(11).wxy);
			ps = max(g_ParallelLights(9).x, g_ParallelLights(9).x);
			r12.z = ps;
		}
		r0.w = g_ParallelLights(16).y > r0.z;
		p0 = r0.w != 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = max(g_ParallelLights(7).z, g_ParallelLights(7).z);
			r1.z = ps;
		}
		if (p0)
		{
			r4.z = max(g_ParallelLights(6).z, g_ParallelLights(6).z);
			ps = max(g_ParallelLights(6).w, g_ParallelLights(6).w);
			r11.z = ps;
		}
		if (p0)
		{
			r4.y = max(g_ParallelLights(5).z, g_ParallelLights(5).z);
			ps = max(g_ParallelLights(5).w, g_ParallelLights(5).w);
			r11.y = ps;
		}
		if (p0)
		{
			r4.x = max(g_ParallelLights(4).z, g_ParallelLights(4).z);
			ps = max(g_ParallelLights(4).w, g_ParallelLights(4).w);
			r11.x = ps;
		}
		if (p0)
		{
			r6.xy = max(g_ParallelLights(21).xy, g_ParallelLights(21).xy);
			ps = max(g_ParallelLights(21).w, g_ParallelLights(21).w);
			r1.x = ps;
		}
		if (p0)
		{
			r12.xy = max(g_ParallelLights(6).xy, g_ParallelLights(6).xy);
			ps = max(g_ParallelLights(21).z, g_ParallelLights(21).z);
			r1.y = ps;
		}
		if (p0)
		{
			r0.xy = max(g_ParallelLights(4).yx, g_ParallelLights(4).yx);
			ps = max(g_ParallelLights(5).y, g_ParallelLights(5).y);
			r12.w = ps;
		}
		if (p0)
		{
			r15.xyz = max(g_ParallelLights(7).wxy, g_ParallelLights(7).wxy);
			ps = max(g_ParallelLights(5).x, g_ParallelLights(5).x);
			r12.z = ps;
		}
		r0.z = g_ParallelLights(16).x > r0.z;
		p0 = r0.z != 0.0;
		ps = p0 ? 0.0 : 1.0;
		if (p0)
		{
			ps = max(g_ParallelLights(3).z, g_ParallelLights(3).z);
			r1.z = ps;
		}
		if (p0)
		{
			r4.z = max(g_ParallelLights(2).z, g_ParallelLights(2).z);
			ps = max(g_ParallelLights(2).w, g_ParallelLights(2).w);
			r11.z = ps;
		}
		if (p0)
		{
			r4.y = max(g_ParallelLights(1).z, g_ParallelLights(1).z);
			ps = max(g_ParallelLights(1).w, g_ParallelLights(1).w);
			r11.y = ps;
		}
		if (p0)
		{
			r4.x = max(g_ParallelLights(0).z, g_ParallelLights(0).z);
			ps = max(g_ParallelLights(0).w, g_ParallelLights(0).w);
			r11.x = ps;
		}
		if (p0)
		{
			r6.xy = max(g_ParallelLights(20).xy, g_ParallelLights(20).xy);
			ps = max(g_ParallelLights(20).w, g_ParallelLights(20).w);
			r1.x = ps;
		}
		if (p0)
		{
			r12.xy = max(g_ParallelLights(2).xy, g_ParallelLights(2).xy);
			ps = max(g_ParallelLights(20).z, g_ParallelLights(20).z);
			r1.y = ps;
		}
		if (p0)
		{
			r0.xy = max(g_ParallelLights(0).yx, g_ParallelLights(0).yx);
			ps = max(g_ParallelLights(1).y, g_ParallelLights(1).y);
			r12.w = ps;
		}
		if (p0)
		{
			r15.xyz = max(g_ParallelLights(3).wxy, g_ParallelLights(3).wxy);
			ps = max(g_ParallelLights(1).x, g_ParallelLights(1).x);
			r12.z = ps;
		}
		r11.x = dot(r13.zxy, r11.zxy);
		r0.z = dot(r13.zy, r12.xz) + c253.x;
		r0.w = dot(r13.zy, r12.yw) + c253.x;
		r11.yz = r13.xx * r0.yx + r0.zw;
		r11.xyz = r11.xyz + r15.xyz;
		r0.w = dot(r13.zxy, r4.zxy);
		ps = clamp(rcp(r11.x), FLT_MIN, FLT_MAX);
		r0.x = ps;
		r0.yz = saturate(r11.yz * r0.xx);
		r0.yz = r0.yz * r6.xy;
		r1.xyz = r0.zyw + r1.xyz;
// conan_tfetch slot=13 mag=3 min=3 mip=3 aniso=7
		r0.y = tfetch2D(g_ShadowMapTextureAtlas_Texture2DDescriptorIndex, g_ShadowMapTextureAtlas_SamplerDescriptorIndex, r1.yx, float2(0, 0)).x;
		r0.x = r1.z * r0.x;
		r0.x = max(r0.x, c253.x);
		r0.x = r0.y > r0.x;
		p0 = abs(g_ParallelLights(18).z) > 0.0;
		ps = p0 ? 0.0 : 1.0;
		r0.y = r0.x != c253.x;
		ps = max(c253.y, c253.y);
		r0.x = ps;
		r0.w = select(-r1.y > 0.0, c253.y, r0.y);
		if (p0)
		{
			r0.xy = r13.yx * g_CloudInfo.xx + g_CloudInfo.yy;
// conan_tfetch slot=10 mag=3 min=3 mip=3 aniso=7
			r0.xyz = tfetch2D(g_ParallelLightShadowTexture_Texture2DDescriptorIndex, g_ParallelLightShadowTexture_SamplerDescriptorIndex, r0.yx, float2(0, 0)).xyz;
		}
		else
		{
			r0.yz = max(c253.yy, c253.yy);
		}
		r1.w = saturate(dot(r14.zxy, r5.zxy));
		r0.xzw = r0.xyz * r0.www;
		r0.y = saturate(dot(r14.zxy, r10.zxy));
		r0.xzw = r0.xzw * g_ParallelLights(17).xyz;
		ps = clamp(log2(r0.y), FLT_MIN, FLT_MAX);
		r0.y = ps;
		r1.xyz = r0.xzw * r5.www;
		r4.xyz = r0.xzw * r1.www;
		ps = specular_power.x * r0.y;
		r0.x = ps;
		r3.xyz = r4.xyz * r8.xyz + r3.xyz;
		r0.yzw = r1.xyz * specular_color.xyz;
		ps = exp2(r0.x);
		r0.x = ps;
		r9.xyz = r0.yzw * r0.xxx + r9.xyz;
	}
	r0.x = saturate(dot(r7.zxy, r5.zxy));
	ps = c253.y - r0.x;
	r0.x = ps;
	ps = clamp(log2(abs(r0.x)), FLT_MIN, FLT_MAX);
	r0.x = ps;
	r0.x = r0.x * fresnel_power.x;
	p0 = g_LightingPassCount.x != 0.0;
	ps = p0 ? 0.0 : 1.0;
	ps = exp2(r0.x);
	r0.x = ps;
	if (p0)
	{
		ps = c253.y - r0.x;
		r0.w = ps;
		r0.xyz = r0.www * r9.xyz;
	}
	else
	{
		r1.xyz = r9.xyz + -r2.yzw;
		ps = c253.y - r2.x;
		r1.w = ps;
		r0.xyzw = r1.xyzw * r0.xxxx + r2.yzwx;
	}
	r1.x = Use_Foam_Texture.x * Use_Level_Heightmap.x;
	p0 = abs(r1.x) > 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
		r1.xyzw = r3.xyzw + -r0.xyzw;
		r0.xyzw = r1.xyzw * r3.wwww + r0.xyzw;
	}
	r1.xyz = r13.xyz + -eyePosition.xyz;
	r1.y = dot(r1.zxy, viewVector.zxy);
	ps = cameraNearFar.y - cameraNearFar.x;
	r1.x = ps;
	r1.y = r1.y + -cameraNearFar.x;
	ps = clamp(rcp(r1.x), FLT_MIN, FLT_MAX);
	r1.x = ps;
	r1.x = saturate(r1.y * r1.x);
	ps = -abs(r0.x) > 0.0;
	r1.y = ps;
// conan_tfetch slot=12 mag=3 min=3 mip=3 aniso=7
	r1.xyzw = tfetch2D(g_FogTable_Texture2DDescriptorIndex, g_FogTable_SamplerDescriptorIndex, r1.xy, float2(0, 0)).xyzw;
	r2.x = -r1.w + c253.y;
	ps = max(r6.z, r6.z);
	r0.xyz = r6.zzz * r0.xyz;
	ps = r0.w * ps;
	r0.w = ps;
	r0.xyz = r0.xyz * r2.xxx;
	p0 = g_LightingPassCount.x != 0.0;
	ps = p0 ? 0.0 : 1.0;
	if (p0)
	{
	}
	else
	{
		r0.xyz = r1.xyz * r1.www + r0.xyz;
	}
	oC0.xyzw = max(r0.xyzw, r0.xyzw);
	[branch] if (g_SpecConstants() & (SPEC_CONSTANT_SOFT_PARTICLE_RGBA | SPEC_CONSTANT_SOFT_PARTICLE_ALPHA))	{		float conanSceneZ = g_Texture2DDescriptorHeap[g_SoftParticleDepth].Load(int3(iPos.xy * g_SoftParticleTexelScale, 0)).x;
		float conanFade = saturate((rcp(conanSceneZ * g_SoftParticleW.x + g_SoftParticleW.y) - rcp(iPos.z * g_SoftParticleW.x + g_SoftParticleW.y)) / g_SoftParticleDistance);
		if (g_SpecConstants() & SPEC_CONSTANT_SOFT_PARTICLE_RGBA) oC0 *= conanFade; else oC0.w *= conanFade;
	}	[branch] if (g_SpecConstants() & SPEC_CONSTANT_ALPHA_TEST)	{		clip(oC0.w - g_AlphaThreshold);
	}	else if (g_SpecConstants() & SPEC_CONSTANT_ALPHA_TO_COVERAGE)	{		oC0.w *= 1.0 + computeMipLevel(pixelCoord) * 0.25;
		oC0.w = 0.5 + (oC0.w - g_AlphaThreshold) / max(fwidth(oC0.w), 1e-6);
	}	return;
}
#ifndef __spirv__
#ifdef CONAN_RECOMP
uint g_SpecConstants() { return g_SpecConstantsRuntime; }
#else
uint g_SpecConstants() { return 0; }
#endif
#endif
