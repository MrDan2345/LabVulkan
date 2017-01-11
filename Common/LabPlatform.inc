{$ifdef Win32}
  {$define Windows}
{$endif}
{$ifdef Win64}
  {$define Windows}
{$endif}
{$ifdef WinCE}
  {$define Windows}
{$endif}
{$ifdef Windows}
  {$define VK_USE_PLATFORM_WIN32_KHR}
{$endif}
{$ifdef Android}
  {$define VK_USE_PLATFORM_ANDROID_KHR}
{$endif}
{$ifdef Linux}
  {$define VK_USE_PLATFORM_XCB_KHR}
{$endif}
{$implicitexceptions off}
{$modeswitch advancedrecords}
