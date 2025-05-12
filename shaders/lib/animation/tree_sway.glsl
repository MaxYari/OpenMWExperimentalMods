uniform mat4 osg_ViewMatrixInverse;
uniform mat4 osg_ViewMatrix;
uniform float osg_SimulationTime;

vec3 windDirection = vec3(1.0,0.0,0.0);

vec3 calcDisplacement(vec3 origin, float frequency, float amplitude)
{
    float toggleMultiplier = step(0.05,length(origin));
    vec4 pivot = vec4(origin,1.0);

    //vec4 pivotInWorld = osg_ViewMatrixInverse * modelToView(pivot);         
    
    vec3 lever = vec3((gl_Vertex - pivot).xyz);
    
    vec3 animatedOffset = windDirection * (sin(1.0*osg_SimulationTime*frequency)+1)/2*amplitude;
    vec3 baseOffset = windDirection*0.1;
    
    vec3 displacement = (baseOffset + animatedOffset) * length(lever) * toggleMultiplier;
    
    return displacement;
}

vec4 swayTree(vec4 vert)
{
    // vert is gl_Vertex

    vec2 uv1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vec2 uv2 = (gl_TextureMatrix[2] * gl_MultiTexCoord2).xy;
    vec2 uv3 = (gl_TextureMatrix[3] * gl_MultiTexCoord3).xy;
    vec2 uv4 = (gl_TextureMatrix[4] * gl_MultiTexCoord4).xy;
    vec2 uv5 = (gl_TextureMatrix[5] * gl_MultiTexCoord5).xy;

    vec3 weirdUe5Offset = vec3(1.0,0.0,1.0);

    // Here "depth" is hierarchy depth. For a leaf mesh - 0 is the leaf itself, 1 is a brach, 2 is a trunk.
    // For a trunk, 0 is the trunk itself, 1 is nothing, 2 is also nothing :)
    vec3 depth2Origin = vec3(uv1,uv2.x) - weirdUe5Offset;
    vec3 depth1Origin = (vec3(uv2.y,uv3) - weirdUe5Offset)*-1.0;
    vec3 depth0Origin = vec3(uv4,uv5.x) - weirdUe5Offset; 
    vec3 trunkOrigin = vec3(0.0,0.0,0.0);  
    vec3 branchOrigin = vec3(0.0,0.0,0.0);
    vec3 leafOrigin = vec3(0.0,0.0,0.0);

    if (length(depth2Origin) <= 0.05 && length(depth1Origin) <= 0.05) {
        // We are a trunk vertex
        trunkOrigin = depth0Origin;
    } else if (length(depth2Origin) <= 0.05) {
        // We are a branch vertex
        branchOrigin = depth0Origin;
        trunkOrigin = depth1Origin;
    } else {
        // We are a leaf vertex
        leafOrigin = depth0Origin;
        branchOrigin = depth1Origin;
        trunkOrigin = depth2Origin;
    }
        
    
    // Amount of ofsset/rotation is weighted by a distance from the pivot point
    vec4 worldPos =  osg_ViewMatrixInverse * modelToView(vert); 
    
    worldPos.xyz += calcDisplacement(trunkOrigin, 1.0, 0.2); 
    worldPos.xyz += calcDisplacement(branchOrigin, 2.0, 0.1); 
    worldPos.xyz += calcDisplacement(leafOrigin, 20.0, 0.1); 
    
    vec4 newViewPos = osg_ViewMatrix * worldPos;    
    return newViewPos;
}

