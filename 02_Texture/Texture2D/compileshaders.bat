@echo off
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t vs.txt -o vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t ps.txt -o ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t brdflut_vs.txt -o brdflut_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t brdflut_ps.txt -o brdflut_ps.spv
pause
