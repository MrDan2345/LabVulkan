@echo off
pushd %~dp0
set SCRIPT_DIR=%~dp0
call :compile_shaders vert %SCRIPT_DIR%*_vs.txt
call :compile_shaders frag %SCRIPT_DIR%*_ps.txt
call :compile_shaders tesc %SCRIPT_DIR%*_tcs.txt
call :compile_shaders tese %SCRIPT_DIR%*_tes.txt
call :compile_shaders geom %SCRIPT_DIR%*_gs.txt
call :compile_shaders comp %SCRIPT_DIR%*_cs.txt
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -DMULTISAMPLED=0 -t light_ps.txt -o light_ps.spv
"%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S frag -DMULTISAMPLED=1 -t light_ps.txt -o light_ps_ms.spv
popd
pause
goto :eof

:compile_shaders
for %%X in ("%~2") do (
  call "%VULKAN_SDK%/Bin32/glslangValidator.exe" -V -S %~1 -t %%~nxX -o %%~nX.spv
)
goto :eof