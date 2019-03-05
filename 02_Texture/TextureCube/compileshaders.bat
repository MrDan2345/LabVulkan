@echo off
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t vs.txt -o vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t ps.txt -o ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t gen_cube_map_vs.txt -o gen_cube_map_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t gen_cube_map_ps.txt -o gen_cube_map_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t gen_irradiance_map_ps.txt -o gen_irradiance_map_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t gen_prefiltered_map_ps.txt -o gen_prefiltered_map_ps.spv
pause
