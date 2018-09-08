
uniform sampler2D dirtTexture;
uniform sampler2D grassTexture;

vec4 grass = texture2D(u_diffuseTexture, _surface.diffuseTexcoord);

vec4 model4 = vec4(_surface.position, 1.0);
vec2 texcoord = _surface.diffuseTexcoord;

vec4 model_position = u_inverseModelTransform * u_inverseViewTransform * model4;
float4 a = texture2D(grassTexture, _surface.diffuseTexcoord );
float4 b = texture2D(dirtTexture, _surface.diffuseTexcoord * 0.0625);
if (model_position.y > 3.5) {
    _surface.diffuse = mix(a, b, 0.9);
} else {
    _surface.diffuse = grass;
}
