@echo off
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S vert -t light_vs.txt -o light_vs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S tesc -t light_tcs.txt -o light_tcs.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S tese -t light_tes.txt -o light_tes.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -DMULTISAMPLED=0 -t light_ps.txt -o light_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -DMULTISAMPLED=1 -t light_ps.txt -o light_ps_ms.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S comp -t cs.txt -o cs.spv
pause
