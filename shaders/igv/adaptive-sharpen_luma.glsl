//!HOOK MAIN
//!BIND HOOKED
//!DESC Adaptive sharpen (luma, contrast-adaptive) - soft strength 0.5 with overshoot clamp
// 2026-08-22: 修复视觉异常 - 原强度 1.2 导致边缘过冲(halo)，改为 0.55 并抑制负向过冲

vec4 hook() {
    vec3 c = HOOKED_texOff(0).rgb;
    float l  = dot(c, vec3(0.2126, 0.7152, 0.0722));
    float l1 = dot(HOOKED_texOff(vec2(-1.0, -1.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l2 = dot(HOOKED_texOff(vec2( 0.0, -1.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l3 = dot(HOOKED_texOff(vec2( 1.0, -1.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l4 = dot(HOOKED_texOff(vec2(-1.0,  0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l6 = dot(HOOKED_texOff(vec2( 1.0,  0.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l7 = dot(HOOKED_texOff(vec2(-1.0,  1.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l8 = dot(HOOKED_texOff(vec2( 0.0,  1.0)).rgb, vec3(0.2126, 0.7152, 0.0722));
    float l9 = dot(HOOKED_texOff(vec2( 1.0,  1.0)).rgb, vec3(0.2126, 0.7152, 0.0722));

    float blur = (l1 + l2 + l3 + l4 + l6 + l7 + l8 + l9) * 0.125;
    float edge = abs(l - blur);

    // 强度：原 1.2 太猛 -> 0.55；边缘因子从 4.0 -> 6.0（更陡的过渡，弱边缘更少锐化）
    float str = clamp(edge * 6.0, 0.0, 1.0) * 0.55;
    float sharp = l + (l - blur) * str;

    // 过冲抑制：钳制到 [0.75, 1.25] 区间，防 halo / 亮边
    float ratio = sharp / max(l, 1e-4);
    ratio = clamp(ratio, 0.75, 1.25);

    c *= ratio;
    return vec4(c, HOOKED_texOff(0).a);
}
