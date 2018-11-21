@echo off
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t vs.txt -o vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t ps.txt -o ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t fullscreen_vs.txt -o fullscreen_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -t fullscreen_ps.txt -o fullscreen_ps.spv
pause
