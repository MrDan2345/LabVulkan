@echo off
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t sphere_vs.txt -o sphere_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S tesc -t sphere_tcs.txt -o sphere_tcs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S tese -t sphere_tes.txt -o sphere_tes.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t sphere_ps.txt -o sphere_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t screen_vs.txt -o screen_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t light_ps.txt -o light_ps.spv
pause
