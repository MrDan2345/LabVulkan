@echo off
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t vs.txt -o vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t ps.txt -o ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S comp -t cs.txt -o cs.spv
pause
