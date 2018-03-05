{$ifdef Win32}
  {$define Platform_Windows}
{$endif}
{$ifdef Win64}
  {$define Platform_Windows}
{$endif}
{$ifdef WinCE}
  {$define Platform_Windows}
{$endif}
{$ifdef Platform_Windows}
  {$define VK_USE_PLATFORM_WIN32_KHR}
{$endif}
{$ifdef Platform_Android}
  {$define VK_USE_PLATFORM_ANDROID_KHR}
{$endif}
{$ifdef Platform_Linux}
  {$define VK_USE_PLATFORM_XCB_KHR}
{$endif}
{$implicitexceptions off}
{$modeswitch advancedrecords}
