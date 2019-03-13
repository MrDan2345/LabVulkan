@echo off
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t screen_vs.txt -o screen_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t -DMULTISAMPLED=0 env_ps.txt -o env_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t -DMULTISAMPLED=1 env_ps.txt -o env_ps_ms.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t cube_map_vs.txt -o cube_map_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t gen_cube_map_ps.txt -o gen_cube_map_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t gen_irradiance_map_ps.txt -o gen_irradiance_map_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t gen_prefiltered_map_ps.txt -o gen_prefiltered_map_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t brdflut_vs.txt -o brdflut_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t brdflut_ps.txt -o brdflut_ps.spv
pause
