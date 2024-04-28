// manual version of raylib default shader
// modified for scan line effect
#version 330
in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;


const vec2 size = vec2(960, 540);   // render size
const float samples = 8.0;          // pixels per axis; higher = bigger glow, worse performance
const float quality = 8; 	        // lower = smaller glow, better quality

uniform sampler2D texture0;
uniform vec4 colDiffuse;

void main()
{
    finalColor = texture(texture0, fragTexCoord) * fragColor;

    float y = floor(fragTexCoord.y * size.y);
    if ( mod(y,4) == 3 ) {
		finalColor /= 2;
	}

	// "borrowed" from bloom.fs in examples
	vec4 sum = vec4(0);
    vec2 sizeFactor = vec2(1)/size*quality;

    const int range = 2;            // should be = (samples - 1)/2;

    for (int x = -range; x <= range; x++)
    {
        for (int y = -range; y <= range; y++)
        {
            sum += texture(texture0, fragTexCoord + vec2(x, y)*sizeFactor);
        }
    }

    // Calculate final fragment color
    finalColor = ((sum/(samples*samples)) + finalColor)*colDiffuse;

}
