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
  Windows
{$endif}
