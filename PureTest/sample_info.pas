unit sample_info;

{$macro on}

interface

uses
{$ifdef WINDOWS}
  Windows,
{$endif}
  Vulkan,
  LabMath,
  Classes;

type
  TTextureObject = record
    sampler: TVkSampler;
    image: TVkImage;
    imageLayout: TVkImageLayout;
    mem: TVkDeviceMemory;
    view: TVkImageView;
    tex_width, tex_height: TVkInt32;
  end;

  TSwapChainBuffer = record
    image: TVkImage;
    view: TVkImageView;
  end;

  TLayerProperties = record
    properties: TVkLayerProperties;
    extensions: array of TVkExtensionProperties;
  end;

  PSampleInfo = ^TSampleInfo;
  TSampleInfo = record
{$if defined(WINDOWS)}
{$define APP_NAME_STR_LEN:=80}
    connection: TVkHINSTANCE;// hInstance - Windows Instance
    name: array[0..APP_NAME_STR_LEN - 1] of AnsiChar;// Name to put on the window/icon
    window: HWND;// hWnd - window handle
{$elseif (defined(VK_USE_PLATFORM_IOS_MVK) or defined(VK_USE_PLATFORM_MACOS_MVK))}
    window: Pointer;
{$elseif defined(__ANDROID__)}
    fpCreateAndroidSurfaceKHR: PFN_vkCreateAndroidSurfaceKHR;
{$elseif defined(VK_USE_PLATFORM_WAYLAND_KHR)}
    wl_display *display;
    wl_registry *registry;
    wl_compositor *compositor;
    wl_surface *window;
    wl_shell *shell;
    wl_shell_surface *shell_surface;
{$else}
    connection: Pxcb_connection_t;
    screen: Pxcb_screen_t;
    window: xcb_window_t;
    atom_wm_delete_window: Pxcb_intern_atom_reply_t;
{$endif} // WIN32
    surface: TVkSurfaceKHR;
    prepared: Boolean;
    use_staging_buffer: Boolean;
    save_images: Boolean;

    instance_layer_names: array of String;
    instance_extension_names: array of String;
    instance_layer_properties: array of TLayerProperties;
    instance_extension_properties: array of TVkExtensionProperties;
    inst: TVkInstance;
    device_extension_names: array of String;
    device_extension_properties: array of TVkExtensionProperties;
    gpus: array of TVkPhysicalDevice;
    device: TVkDevice;
    graphics_queue: TVkQueue;
    present_queue: TVkQueue;
    graphics_queue_family_index: TVkUInt32;
    present_queue_family_index: TVkUInt32;
    gpu_props: TVkPhysicalDeviceProperties;
    queue_props: array of TVkQueueFamilyProperties;
    memory_properties: TVkPhysicalDeviceMemoryProperties;

    framebuffers: array of TVkFramebuffer; // PVkFramebuffer
    width, height: TVkInt32;
    format: TVkFormat;

    swapchainImageCount: TVkUInt32;
    swap_chain: TVkSwapchainKHR;
    buffers: array of TSwapChainBuffer;
    imageAcquiredSemaphore: TVkSemaphore;

    cmd_pool: TVkCommandPool;

    depth: record
      format: TVkFormat;
      image: TVkImage;
      mem: TVkDeviceMemory;
      view: TVkImageView;
    end;

    textures: array of TTextureObject;

    uniform_data: record
      buf: TVkBuffer;
      mem: TVkDeviceMemory;
      buffer_info: TVkDescriptorBufferInfo;
    end;

    texture_data: record
      image_info: TVkDescriptorImageInfo;
    end;
    stagingMemory: TVkDeviceMemory;
    stagingImage: TVkImage;

    vertex_buffer: record
      buf: TVkBuffer;
      mem: TVkDeviceMemory;
      buffer_info: TVkDescriptorBufferInfo;
    end;
    vi_binding: TVkVertexInputBindingDescription;
    vi_attribs: array[0..1] of TVkVertexInputAttributeDescription;

    Projection: TLabMat;
    View: TLabMat;
    Model: TLabMat;
    Clip: TLabMat;
    MVP: TLabMat;

    cmd: TVkCommandBuffer;// Buffer for initialization commands
    pipeline_layout: TVkPipelineLayout;
    desc_layout: array of TVkDescriptorSetLayout;
    pipelineCache: TVkPipelineCache;
    render_pass: TVkRenderPass;
    pipeline: TVkPipeline;

    shaderStages: array[0..1] of TVkPipelineShaderStageCreateInfo;

    desc_pool: TVkDescriptorPool;
    desc_set: array of TVkDescriptorSet;

    //dbgCreateDebugReportCallback: TPFN_vkCreateDebugReportCallbackEXT;
    //dbgDestroyDebugReportCallback: TPFN_vkDestroyDebugReportCallbackEXT;
    //dbgBreakCallback: TPFN_vkDebugReportMessageEXT;
    debug_report_callbacks: array of TVkDebugReportCallbackEXT;

    current_buffer: TVkUInt32;
    queue_family_count: TVkUInt32;

    viewport: TVkViewport;
    scissor: TVkRect2D;
  end;

  procedure process_command_line_args(var info: TSampleInfo);
  function memory_type_from_properties(
    var info: TSampleInfo;
    const typeBits: TVkUInt32;
    const requirements_mask: TVkFlags;
    const typeIndex: PVkUInt32
  ): Boolean;

  function init_global_extension_properties(var layer_props: TLayerProperties): TVkResult;
  function init_global_layer_properties(var info: TSampleInfo): TVkResult;
  procedure init_instance_extension_names(var info: TSampleInfo);
  procedure init_device_extension_names(var info: TSampleInfo);
  function init_instance(var info: TSampleInfo; const app_short_name: String): TVkResult;
  function init_enumerate_device(var info: TSampleInfo; const gpu_count: TVkUInt32 = 1): TVkResult;
  procedure init_window_size(var info: TSampleInfo; const default_width, default_height: TVkInt32);
  procedure init_connection(var info: TSampleInfo);
  procedure init_window(var info: TSampleInfo);
  procedure init_swapchain_extension(var info: TSampleInfo);
  function init_device(var info: TSampleInfo): TVkResult;
  procedure init_command_pool(var info: TSampleInfo);
  procedure init_command_buffer(var info: TSampleInfo);
  procedure execute_begin_command_buffer(var info: TSampleInfo);
  procedure init_device_queue(var info: TSampleInfo);
  procedure init_swap_chain(
    var info: TSampleInfo;
    const usageFlags: TVkImageUsageFlags = TVkImageUsageFlags(
      TVkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
    )
  );
  procedure init_depth_buffer(var info: TSampleInfo);
  procedure init_uniform_buffer(var info: TSampleInfo);
  procedure init_descriptor_and_pipeline_layouts(
    var info: TSampleInfo;
    const use_texture: Boolean;
    const descSetLayoutCreateFlags: TVkDescriptorSetLayoutCreateFlags = 0
  );
  procedure init_renderpass(
    var info: TSampleInfo;
    const include_depth: Boolean;
    const clear: Boolean = true;
    const finalLayout: TVkImageLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
  );
  procedure init_shaders(
    var info: TSampleInfo;
    const vertShaderBinary: PVkUInt8; const vertShaderSize: TVkUInt32;
    const fragShaderBinary: PVkUInt8; const fragShaderSize: TVkUInt32
  );
  procedure init_framebuffers(var info: TSampleInfo; const include_depth: Boolean);
  procedure init_vertex_buffer(
    var info: TSampleInfo;
    const vertexData: Pointer;
    const dataSize: TVkUInt32;
    const dataStride: TVkUInt32;
    const use_texture: Boolean
  );
  procedure init_descriptor_pool(var info: TSampleInfo; const use_texture: Boolean);
  procedure init_descriptor_set(var info: TSampleInfo; const use_texture: Boolean);
  procedure init_pipeline_cache(var info: TSampleInfo);
  procedure init_pipeline(var info: TSampleInfo; const include_depth: TVkBool32; const include_vi: TVkBool32 = VK_TRUE);

  procedure init_viewports(var info: TSampleInfo);
  procedure init_scissors(var info: TSampleInfo);

  procedure destroy_pipeline(var info: TSampleInfo);
  procedure destroy_pipeline_cache(var info: TSampleInfo);
  procedure destroy_descriptor_pool(var info: TSampleInfo);
  procedure destroy_vertex_buffer(var info: TSampleInfo);
  procedure destroy_framebuffers(var info: TSampleInfo);
  procedure destroy_shaders(var info: TSampleInfo);
  procedure destroy_renderpass(var info: TSampleInfo);
  procedure destroy_descriptor_and_pipeline_layouts(var info: TSampleInfo);
  procedure destroy_uniform_buffer(var info: TSampleInfo);
  procedure destroy_depth_buffer(var info: TSampleInfo);
  procedure destroy_swap_chain(var info: TSampleInfo);
  procedure destroy_command_buffer(var info: TSampleInfo);
  procedure destroy_command_pool(var info: TSampleInfo);
  procedure destroy_device(var info: TSampleInfo);
  procedure destroy_window(var info: TSampleInfo);
  procedure destroy_instance(var info: TSampleInfo);

const
  NUM_SAMPLES = VK_SAMPLE_COUNT_1_BIT;
  NUM_DESCRIPTOR_SETS = 1;
  NUM_VIEWPORTS = 1;
  NUM_SCISSORS = NUM_VIEWPORTS;
  //Amount of time, in nanoseconds, to wait for a command buffer to complete
  FENCE_TIMEOUT = 100000000;

  VK_DYNAMIC_STATE_BEGIN_RANGE = VK_DYNAMIC_STATE_VIEWPORT;
  VK_DYNAMIC_STATE_END_RANGE = VK_DYNAMIC_STATE_STENCIL_REFERENCE;
  VK_DYNAMIC_STATE_RANGE_SIZE = (TVkFlags(VK_DYNAMIC_STATE_STENCIL_REFERENCE) - TVkFlags(VK_DYNAMIC_STATE_VIEWPORT) + 1);

implementation

procedure process_command_line_args(var info: TSampleInfo);
begin
end;

function memory_type_from_properties(var info: TSampleInfo;
  const typeBits: TVkUInt32; const requirements_mask: TVkFlags;
  const typeIndex: PVkUInt32
): Boolean;
  var tb: TVkUInt32;
  var i: TVkUInt32;
begin
  tb := typeBits;
  // Search memtypes to find first index with those properties
  for i := 0 to info.memory_properties.memoryTypeCount - 1 do
  begin
    if (tb and 1) = 1 then
    begin
      // Type is available, does it match user properties?
      if (info.memory_properties.memoryTypes[i].propertyFlags and requirements_mask) = requirements_mask then
      begin
        typeIndex^ := i;
        Exit(True);
      end;
    end;
    tb := tb shr 1;
  end;
  // No memory types matched, return failure
  Result := False;
end;

function init_global_extension_properties(var layer_props: TLayerProperties): TVkResult;
  var instance_extensions: PVkExtensionProperties;
  var instance_extension_count: TVkUInt32;
  var layer_name: PVkChar;
begin
  layer_name := @layer_props.properties.layerName;
  repeat
    Result := vk.EnumerateInstanceExtensionProperties(layer_name, @instance_extension_count, nil);
    if (Result > VK_SUCCESS) then Exit;
    if (instance_extension_count = 0) then Exit(VK_SUCCESS);
    //layer_props.extensions.resize(instance_extension_count);
    SetLength(layer_props.extensions, instance_extension_count);
    instance_extensions := @layer_props.extensions[0];
    Result := vk.EnumerateInstanceExtensionProperties(layer_name, @instance_extension_count, instance_extensions);
  until Result <> VK_INCOMPLETE;
end;

function init_global_layer_properties(var info: TSampleInfo): TVkResult;
  var instance_layer_count: TVkUInt32;
  var vk_props: array of TVkLayerProperties;
  var i: TVkInt32;
  var layer_props: TLayerProperties;
begin
{$ifdef __ANDROID__}
  // This place is the first place for samples to use Vulkan APIs.
  // Here, we are going to open Vulkan.so on the device and retrieve function pointers using
  // vulkan_wrapper helper.
  if (!InitVulkan()) {
      LOGE("Failied initializing Vulkan APIs!");
      return VK_ERROR_INITIALIZATION_FAILED;
  }
  LOGI("Loaded Vulkan APIs.");
{$endif}

  {
   * It's possible, though very rare, that the number of
   * instance layers could change. For example, installing something
   * could include new layers that the loader would pick up
   * between the initial query for the count and the
   * request for VkLayerProperties. The loader indicates that
   * by returning a VK_INCOMPLETE status and will update the
   * the count parameter.
   * The count parameter will be updated with the number of
   * entries loaded into the data pointer - in case the number
   * of layers went down or is smaller than the size given.
  }
  repeat
    Result := vk.EnumerateInstanceLayerProperties(@instance_layer_count, nil);
    if (Result > VK_SUCCESS) then Exit;
    if (instance_layer_count = 0) then Exit(VK_SUCCESS);
    SetLength(vk_props, instance_layer_count);
    Result := vk.EnumerateInstanceLayerProperties(@instance_layer_count, @vk_props[0]);
  until (Result <> VK_INCOMPLETE);

  {
   * Now gather the extension list for each instance layer.
  }
  for i := 0 to instance_layer_count - 1 do
  begin
    layer_props.properties := vk_props[i];
    Result := init_global_extension_properties(layer_props);
    if (Result > VK_SUCCESS) then Exit;
    SetLength(info.instance_layer_properties, Length(info.instance_layer_properties) + 1);
    info.instance_layer_properties[High(info.instance_layer_properties)] := layer_props;
  end;
end;

procedure init_instance_extension_names(var info: TSampleInfo);
begin
  //info.instance_extension_names.push_back(VK_KHR_SURFACE_EXTENSION_NAME);
  SetLength(info.instance_extension_names, Length(info.instance_extension_names) + 1);
  info.instance_extension_names[High(info.instance_extension_names)] := VK_KHR_SURFACE_EXTENSION_NAME;
{$if defined(__ANDROID__)}
  info.instance_extension_names.push_back(VK_KHR_ANDROID_SURFACE_EXTENSION_NAME);
{$elseif defined(WINDOWS)}
  //info.instance_extension_names.push_back(VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
  SetLength(info.instance_extension_names, Length(info.instance_extension_names) + 1);
  info.instance_extension_names[High(info.instance_extension_names)] := VK_KHR_WIN32_SURFACE_EXTENSION_NAME;
{$elseif defined(VK_USE_PLATFORM_IOS_MVK)}
  info.instance_extension_names.push_back(VK_MVK_IOS_SURFACE_EXTENSION_NAME);
{$elseif defined(VK_USE_PLATFORM_MACOS_MVK)}
  info.instance_extension_names.push_back(VK_MVK_MACOS_SURFACE_EXTENSION_NAME);
{$elseif defined(VK_USE_PLATFORM_WAYLAND_KHR)}
  info.instance_extension_names.push_back(VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME);
{$else}
  info.instance_extension_names.push_back(VK_KHR_XCB_SURFACE_EXTENSION_NAME);
{$endif}
end;

procedure init_device_extension_names(var info: TSampleInfo);
begin
  //info.device_extension_names.push_back(VK_KHR_SWAPCHAIN_EXTENSION_NAME);
  SetLength(info.device_extension_names, Length(info.device_extension_names) + 1);
  info.device_extension_names[High(info.device_extension_names)] := VK_KHR_SWAPCHAIN_EXTENSION_NAME;
end;

function init_instance(var info: TSampleInfo; const app_short_name: String): TVkResult;
  var app_info: TVkApplicationInfo;
  var inst_info: TVkInstanceCreateInfo;
  var inst_commands: TVulkanCommands;
  var new_vk: TVulkan;
begin
  FillChar(app_info, SizeOf(app_info), 0);
  app_info.sType := VK_STRUCTURE_TYPE_APPLICATION_INFO;
  app_info.pNext := nil;
  app_info.pApplicationName := PVkChar(app_short_name);
  app_info.applicationVersion := 1;
  app_info.pEngineName := PVkChar(app_short_name);
  app_info.engineVersion := 1;
  app_info.apiVersion := VK_API_VERSION_1_0;

  FillChar(inst_info, SizeOf(inst_info), 0);
  inst_info.sType := VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  inst_info.pNext := nil;
  inst_info.flags := 0;
  inst_info.pApplicationInfo := @app_info;
  inst_info.enabledLayerCount := Length(info.instance_layer_names);
  if Length(info.instance_layer_names) > 0 then
  begin
    inst_info.ppEnabledLayerNames := @info.instance_layer_names[0];
  end
  else
  begin
    inst_info.ppEnabledLayerNames := nil;
  end;
  inst_info.enabledExtensionCount := Length(info.instance_extension_names);
  inst_info.ppEnabledExtensionNames := @info.instance_extension_names[0];

  Result := vk.CreateInstance(@inst_info, nil, @info.inst);
  LoadVulkanInstanceCommands(vk.Commands.GetInstanceProcAddr, info.inst, inst_commands);
  new_vk := TVulkan.Create(inst_commands);
  vk.Free;
  vk := new_vk;
  assert(Result = VK_SUCCESS);
end;

function init_enumerate_device(var info: TSampleInfo; const gpu_count: TVkUInt32 = 1): TVkResult;
  var avail_count: TVkUInt32;
begin
  Result := vk.EnumeratePhysicalDevices(info.inst, @avail_count, nil);
  assert(avail_count > 0);
  SetLength(info.gpus, avail_count);

  Result := vk.EnumeratePhysicalDevices(info.inst, @avail_count, @info.gpus[0]);
  assert((Result = VK_SUCCESS) and (avail_count >= gpu_count));

  vk.GetPhysicalDeviceQueueFamilyProperties(info.gpus[0], @info.queue_family_count, nil);
  assert(info.queue_family_count >= 1);

  SetLength(info.queue_props, info.queue_family_count);
  vk.GetPhysicalDeviceQueueFamilyProperties(info.gpus[0], @info.queue_family_count, @info.queue_props[0]);
  assert(info.queue_family_count >= 1);

  // This is as good a place as any to do this
  vk.GetPhysicalDeviceMemoryProperties(info.gpus[0], @info.memory_properties);
  vk.GetPhysicalDeviceProperties(info.gpus[0], @info.gpu_props);
end;

procedure init_window_size(var info: TSampleInfo; const default_width, default_height: TVkInt32);
begin
{$ifdef __ANDROID__}
  AndroidGetWindowSize(&info.width, &info.height);
{$else}
  info.width := default_width;
  info.height := default_height;
{$endif}
end;

procedure init_connection(var info: TSampleInfo);
begin
{$if defined(VK_USE_PLATFORM_XCB_KHR)}
  const xcb_setup_t *setup;
  xcb_screen_iterator_t iter;
  int scr;

  info.connection = xcb_connect(NULL, &scr);
  if (info.connection == NULL || xcb_connection_has_error(info.connection)) {
      std::cout << "Unable to make an XCB connection\n";
      exit(-1);
  }

  setup = xcb_get_setup(info.connection);
  iter = xcb_setup_roots_iterator(setup);
  while (scr-- > 0) xcb_screen_next(&iter);

  info.screen = iter.data;
{$elseif defined(VK_USE_PLATFORM_WAYLAND_KHR)}
  info.display = wl_display_connect(nullptr);

  if (info.display == nullptr) {
      printf(
          "Cannot find a compatible Vulkan installable client driver "
          "(ICD).\nExiting ...\n");
      fflush(stdout);
      exit(1);
  }

  info.registry = wl_display_get_registry(info.display);
  wl_registry_add_listener(info.registry, &registry_listener, &info);
  wl_display_dispatch(info.display);
{$endif}
end;

{$if defined(WINDOWS)}
procedure run(const info: PSampleInfo);
begin
 {Placeholder for samples that want to show dynamic content}
end;

function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  var info: PSampleInfo;
begin
  info := PSampleInfo(Pointer(GetWindowLongPtr(hWnd, GWLP_USERDATA)));
  case (uMsg) of
    WM_CLOSE: PostQuitMessage(0);
    WM_PAINT:
    begin
      run(info);
      Exit(0);
    end;
  end;
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
end;

procedure init_window(var info: TSampleInfo);
  var win_class: WNDCLASSEX;
  var wr: TRect;
begin
  assert(info.width > 0);
  assert(info.height > 0);

  info.connection := GetModuleHandle(nil);
  info.name := 'Sample';

  // Initialize the window class structure:
  win_class.cbSize := sizeof(WNDCLASSEX);
  win_class.style := CS_HREDRAW or CS_VREDRAW;
  win_class.lpfnWndProc := @WndProc;
  win_class.cbClsExtra := 0;
  win_class.cbWndExtra := 0;
  win_class.hInstance := info.connection;  // hInstance
  win_class.hIcon := LoadIcon(0, IDI_APPLICATION);
  win_class.hCursor := LoadCursor(0, IDC_ARROW);
  win_class.hbrBackground := HBRUSH(GetStockObject(WHITE_BRUSH));
  win_class.lpszMenuName := nil;
  win_class.lpszClassName := info.name;
  win_class.hIconSm := LoadIcon(0, IDI_WINLOGO);
  // Register window class:
  if RegisterClassEx(@win_class) = 0 then
  begin
    // It didn't work, so try to give a useful error:
    WriteLn('Unexpected error trying to start the application!');
    Halt;
  end;
  // Create window with the registered class:
  wr :=  Rect(0, 0, info.width, info.height);
  AdjustWindowRect(wr, WS_OVERLAPPEDWINDOW, False);
  info.window := CreateWindowEx(
    0,
    info.name, // class name
    info.name, // app name
    WS_OVERLAPPEDWINDOW or WS_VISIBLE or WS_SYSMENU,
    100, 100, // x/y coords
    wr.right - wr.left, // width
    wr.bottom - wr.top, // height
    0, // handle to parent
    0, // handle to menu
    info.connection, // hInstance
    nil // no extra parameters
  );
  if (info.window = 0) then
  begin
    // It didn't work, so try to give a useful error:
    WriteLn('Cannot create a window in which to draw!');
    Halt;
  end;
  SetWindowLongPtr(info.window, GWLP_USERDATA, LONG_PTR(@info));
end;

procedure destroy_window(var info: TSampleInfo);
begin
  vk.DestroySurfaceKHR(info.inst, info.surface, nil);
  DestroyWindow(info.window);
end;
{$elseif defined(VK_USE_PLATFORM_IOS_MVK) or defined(VK_USE_PLATFORM_MACOS_MVK)}
procedure destroy_window(var info: TSampleInfo);
begin
  info.window := nil;
end;
{$elseif defined(__ANDROID__)}
procedure init_window(var info: TSampleInfo);
begin

end;

procedure destroy_window(var info: TSampleInfo);
begin

end;
{$elseif defined(VK_USE_PLATFORM_WAYLAND_KHR)}
procedure init_window(var info: TSampleInfo);
begin
  assert(info.width > 0);
  assert(info.height > 0);

  info.window = wl_compositor_create_surface(info.compositor);
  if (!info.window) {
      printf("Can not create wayland_surface from compositor!\n");
      fflush(stdout);
      exit(1);
  }

  info.shell_surface = wl_shell_get_shell_surface(info.shell, info.window);
  if (!info.shell_surface) {
      printf("Can not get shell_surface from wayland_surface!\n");
      fflush(stdout);
      exit(1);
  }

  wl_shell_surface_add_listener(info.shell_surface, &shell_surface_listener, &info);
  wl_shell_surface_set_toplevel(info.shell_surface);
end;

procedure destroy_window(var info: TSampleInfo);
begin
    wl_shell_surface_destroy(info.shell_surface);
    wl_surface_destroy(info.window);
    wl_shell_destroy(info.shell);
    wl_compositor_destroy(info.compositor);
    wl_registry_destroy(info.registry);
    wl_display_disconnect(info.display);
end;
{$else}
procedure init_window(var info: TSampleInfo);
begin
  assert(info.width > 0);
  assert(info.height > 0);

  uint32_t value_mask, value_list[32];

  info.window = xcb_generate_id(info.connection);

  value_mask = XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK;
  value_list[0] = info.screen->black_pixel;
  value_list[1] = XCB_EVENT_MASK_KEY_RELEASE | XCB_EVENT_MASK_EXPOSURE;

  xcb_create_window(info.connection, XCB_COPY_FROM_PARENT, info.window, info.screen->root, 0, 0, info.width, info.height, 0,
                    XCB_WINDOW_CLASS_INPUT_OUTPUT, info.screen->root_visual, value_mask, value_list);

  /* Magic code that will send notification when window is destroyed */
  xcb_intern_atom_cookie_t cookie = xcb_intern_atom(info.connection, 1, 12, "WM_PROTOCOLS");
  xcb_intern_atom_reply_t *reply = xcb_intern_atom_reply(info.connection, cookie, 0);

  xcb_intern_atom_cookie_t cookie2 = xcb_intern_atom(info.connection, 0, 16, "WM_DELETE_WINDOW");
  info.atom_wm_delete_window = xcb_intern_atom_reply(info.connection, cookie2, 0);

  xcb_change_property(info.connection, XCB_PROP_MODE_REPLACE, info.window, ( *reply).atom, 4, 32, 1,
                      &( *info.atom_wm_delete_window).atom);
  free(reply);

  xcb_map_window(info.connection, info.window);

  // Force the x/y coordinates to 100,100 results are identical in consecutive
  // runs
  const uint32_t coords[] = {100, 100};
  xcb_configure_window(info.connection, info.window, XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y, coords);
  xcb_flush(info.connection);

  xcb_generic_event_t *e;
  while ((e = xcb_wait_for_event(info.connection))) {
      if ((e->response_type & ~0x80) == XCB_EXPOSE) break;
  }
end;

procedure destroy_window(var info: TSampleInfo);
begin
  vk.DestroySurfaceKHR(info.inst, info.surface, NULL);
  xcb_destroy_window(info.connection, info.window);
  xcb_disconnect(info.connection);
end;
{$endif}

procedure init_swapchain_extension(var info: TSampleInfo);
  var res: TVkResult;
{$ifdef WINDOWS}
  var createInfo: TVkWin32SurfaceCreateInfoKHR;
{$endif}
  var pSupportsPresent: array of TVkBool32;
  var surfFormats: array of TVkSurfaceFormatKHR;
  var i, formatCount: TVkUInt32;
begin
// Construct the surface description:
{$if defined(WINDOWS)}
  FillChar(createInfo, sizeof(createInfo), 0);
  createInfo.sType := VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
  createInfo.pNext := nil;
  createInfo.hinstance_ := info.connection;
  createInfo.hwnd_ := info.window;
  res := vk.CreateWin32SurfaceKHR(info.inst, @createInfo, nil, @info.surface);
{$elseif defined(__ANDROID__)}
  GET_INSTANCE_PROC_ADDR(info.inst, CreateAndroidSurfaceKHR);
  VkAndroidSurfaceCreateInfoKHR createInfo;
  createInfo.sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
  createInfo.pNext = nullptr;
  createInfo.flags = 0;
  createInfo.window = AndroidGetApplicationWindow();
  res = info.fpCreateAndroidSurfaceKHR(info.inst, &createInfo, nullptr, &info.surface);
{$elseif defined(VK_USE_PLATFORM_IOS_MVK)}
  VkIOSSurfaceCreateInfoMVK createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK;
  createInfo.pNext = NULL;
  createInfo.flags = 0;
  createInfo.pView = info.window;
  res = vk.CreateIOSSurfaceMVK(info.inst, &createInfo, NULL, &info.surface);
{$elseif defined(VK_USE_PLATFORM_MACOS_MVK)}
  VkMacOSSurfaceCreateInfoMVK createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK;
  createInfo.pNext = NULL;
  createInfo.flags = 0;
  createInfo.pView = info.window;
  res = vk.CreateMacOSSurfaceMVK(info.inst, &createInfo, NULL, &info.surface);
{$elseif defined(VK_USE_PLATFORM_WAYLAND_KHR)}
  VkWaylandSurfaceCreateInfoKHR createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR;
  createInfo.pNext = NULL;
  createInfo.display = info.display;
  createInfo.surface = info.window;
  res = vk.CreateWaylandSurfaceKHR(info.inst, &createInfo, NULL, &info.surface);
{$else}
  VkXcbSurfaceCreateInfoKHR createInfo = {};
  createInfo.sType = VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR;
  createInfo.pNext = NULL;
  createInfo.connection = info.connection;
  createInfo.window = info.window;
  res = vk.CreateXcbSurfaceKHR(info.inst, &createInfo, NULL, &info.surface);
{$endif}  // __ANDROID__  && _WIN32
  assert(res = VK_SUCCESS);

  // Iterate over each queue to learn whether it supports presenting:
  // VkBool32 *pSupportsPresent = (VkBool32 *)malloc(info.queue_family_count * sizeof(VkBool32));
  SetLength(pSupportsPresent, info.queue_family_count);
  for i := 0 to info.queue_family_count - 1 do
  begin
    vk.GetPhysicalDeviceSurfaceSupportKHR(info.gpus[0], i, info.surface, @pSupportsPresent[i]);
  end;

  // Search for a graphics and a present queue in the array of queue
  // families, try to find one that supports both
  info.graphics_queue_family_index := High(TVkUInt32);
  info.present_queue_family_index := High(TVkUInt32);
  for i := 0 to info.queue_family_count - 1 do
  begin
    if ((info.queue_props[i].queueFlags and TVkFlags(VK_QUEUE_GRAPHICS_BIT)) <> 0) then
    begin
      if (info.graphics_queue_family_index = High(TVkUInt32)) then info.graphics_queue_family_index := i;
      if (pSupportsPresent[i] = VK_TRUE) then
      begin
        info.graphics_queue_family_index := i;
        info.present_queue_family_index := i;
        break;
      end;
    end;
  end;

  if (info.present_queue_family_index = High(TVkUInt32)) then
  begin
    // If didn't find a queue that supports both graphics and present, then
    // find a separate present queue.
    for i := 0 to info.queue_family_count - 1 do
    if (pSupportsPresent[i] = VK_TRUE) then
    begin
      info.present_queue_family_index := i;
      break;
    end;
  end;
  //free(pSupportsPresent);

  // Generate error if could not find queues that support graphics
  // and present
  if (info.graphics_queue_family_index = High(TVkUInt32))
  or (info.present_queue_family_index = High(TVkUInt32)) then
  begin
    WriteLn('Could not find a queues for both graphics and present');
    Halt;
  end;

  // Get the list of VkFormats that are supported:
  res := vk.GetPhysicalDeviceSurfaceFormatsKHR(info.gpus[0], info.surface, @formatCount, nil);
  assert(res = VK_SUCCESS);
  //VkSurfaceFormatKHR *surfFormats = (VkSurfaceFormatKHR *)malloc(formatCount * sizeof(VkSurfaceFormatKHR));
  SetLength(surfFormats, formatCount);
  res := vk.GetPhysicalDeviceSurfaceFormatsKHR(info.gpus[0], info.surface, @formatCount, @surfFormats[0]);
  assert(res = VK_SUCCESS);
  // If the format list includes just one entry of VK_FORMAT_UNDEFINED,
  // the surface has no preferred format.  Otherwise, at least one
  // supported format will be returned.
  if (formatCount = 1) and (surfFormats[0].format = VK_FORMAT_UNDEFINED) then
  begin
    info.format := VK_FORMAT_B8G8R8A8_UNORM;
  end
  else
  begin
    assert(formatCount >= 1);
    info.format := surfFormats[0].format;
  end;
  //free(surfFormats);
end;

function init_device(var info: TSampleInfo): TVkResult;
  var queue_info: TVkDeviceQueueCreateInfo;
  var queue_priorities: TVkFloat;
  var device_info: TVkDeviceCreateInfo;
begin
  FillChar(queue_info, sizeof(queue_info), 0);
  queue_priorities := 0;
  queue_info.sType := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
  queue_info.pNext := nil;
  queue_info.queueCount := 1;
  queue_info.pQueuePriorities := @queue_priorities;
  queue_info.queueFamilyIndex := info.graphics_queue_family_index;

  FillChar(device_info, sizeof(device_info), 0);
  device_info.sType := VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  device_info.pNext := nil;
  device_info.queueCreateInfoCount := 1;
  device_info.pQueueCreateInfos := @queue_info;
  device_info.enabledExtensionCount := Length(info.device_extension_names);
  if device_info.enabledExtensionCount > 0 then
  begin
    device_info.ppEnabledExtensionNames := @info.device_extension_names[0];
  end
  else
  begin
    device_info.ppEnabledExtensionNames := nil;
  end;
  device_info.pEnabledFeatures := nil;

  Result := vk.CreateDevice(info.gpus[0], @device_info, nil, @info.device);
  assert(Result = VK_SUCCESS);
end;

procedure init_command_pool(var info: TSampleInfo);
  var res: TVkResult;
  var cmd_pool_info: TVkCommandPoolCreateInfo;
begin
  FillChar(cmd_pool_info, sizeof(cmd_pool_info), 0);
  cmd_pool_info.sType := VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
  cmd_pool_info.pNext := nil;
  cmd_pool_info.queueFamilyIndex := info.graphics_queue_family_index;
  cmd_pool_info.flags := TVkFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT);
  res := vk.CreateCommandPool(info.device, @cmd_pool_info, nil, @info.cmd_pool);
  assert(res = VK_SUCCESS);
end;

procedure init_command_buffer(var info: TSampleInfo);
  var res: TVkResult;
  var cmd: TVkCommandBufferAllocateInfo;
begin
  FillChar(cmd, sizeof(cmd), 0);
  cmd.sType := VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
  cmd.pNext := nil;
  cmd.commandPool := info.cmd_pool;
  cmd.level := VK_COMMAND_BUFFER_LEVEL_PRIMARY;
  cmd.commandBufferCount := 1;
  res := vk.AllocateCommandBuffers(info.device, @cmd, @info.cmd);
  assert(res = VK_SUCCESS);
end;

procedure execute_begin_command_buffer(var info: TSampleInfo);
  var res: TVkResult;
  var cmd_buf_info: TVkCommandBufferBeginInfo;
begin
  // DEPENDS on init_command_buffer()
  FillChar(cmd_buf_info, sizeof(cmd_buf_info), 0);
  cmd_buf_info.sType := VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
  cmd_buf_info.pNext := nil;
  cmd_buf_info.flags := 0;
  cmd_buf_info.pInheritanceInfo := nil;
  res := vk.BeginCommandBuffer(info.cmd, @cmd_buf_info);
  assert(res = VK_SUCCESS);
end;

procedure init_device_queue(var info: TSampleInfo);
begin
  vk.GetDeviceQueue(info.device, info.graphics_queue_family_index, 0, @info.graphics_queue);
  if (info.graphics_queue_family_index = info.present_queue_family_index) then
  begin
    info.present_queue := info.graphics_queue;
  end
  else
  begin
    vk.GetDeviceQueue(info.device, info.present_queue_family_index, 0, @info.present_queue);
  end;
end;

procedure init_swap_chain(var info: TSampleInfo; const usageFlags: TVkImageUsageFlags);
  var res: TVkResult;
  var surfCapabilities: TVkSurfaceCapabilitiesKHR;
  var presentModeCount: TVkUInt32;
  var presentModes: array of TVkPresentModeKHR;
  var swapchainExtent: TVkExtent2D;
  var swapchainPresentMode: TVkPresentModeKHR;
  var desiredNumberOfSwapChainImages: TVkUInt32;
  var preTransform: TVkSurfaceTransformFlagBitsKHR;
  var compositeAlpha: TVkCompositeAlphaFlagBitsKHR;
  var compositeAlphaFlags: array[0..3] of TVkCompositeAlphaFlagBitsKHR;
  var swapchain_ci: TVkSwapchainCreateInfoKHR;
  var queueFamilyIndices: array[0..1] of TVkUInt32;
  var swapchainImages: array of TVkImage;
  var sc_buffer: TSwapChainBuffer;
  var color_image_view: TVkImageViewCreateInfo;
  var i: TVkUInt32;
begin
  // DEPENDS on info.cmd and info.queue initialized
  res := vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(info.gpus[0], info.surface, @surfCapabilities);
  assert(res = VK_SUCCESS);

  res := vk.GetPhysicalDeviceSurfacePresentModesKHR(info.gpus[0], info.surface, @presentModeCount, nil);
  assert(res = VK_SUCCESS);
  //VkPresentModeKHR *presentModes = (VkPresentModeKHR *)malloc(presentModeCount * sizeof(VkPresentModeKHR));
  SetLength(presentModes, presentModeCount);
  assert(Length(presentModes) > 0);
  res := vk.GetPhysicalDeviceSurfacePresentModesKHR(info.gpus[0], info.surface, @presentModeCount, @presentModes[0]);
  assert(res = VK_SUCCESS);

  // width and height are either both 0xFFFFFFFF, or both not 0xFFFFFFFF.
  if (surfCapabilities.currentExtent.width = $FFFFFFFF) then
  begin
    // If the surface size is undefined, the size is set to
    // the size of the images requested.
    swapchainExtent.width := info.width;
    swapchainExtent.height := info.height;
    if (swapchainExtent.width < surfCapabilities.minImageExtent.width) then
    begin
      swapchainExtent.width := surfCapabilities.minImageExtent.width;
    end
    else if (swapchainExtent.width > surfCapabilities.maxImageExtent.width) then
    begin
      swapchainExtent.width := surfCapabilities.maxImageExtent.width;
    end;

    if (swapchainExtent.height < surfCapabilities.minImageExtent.height) then
    begin
      swapchainExtent.height := surfCapabilities.minImageExtent.height;
    end
    else if (swapchainExtent.height > surfCapabilities.maxImageExtent.height) then
    begin
      swapchainExtent.height := surfCapabilities.maxImageExtent.height;
    end;
  end
  else
  begin
    // If the surface size is defined, the swap chain size must match
    swapchainExtent := surfCapabilities.currentExtent;
  end;

  // The FIFO present mode is guaranteed by the spec to be supported
  // Also note that current Android driver only supports FIFO
  swapchainPresentMode := VK_PRESENT_MODE_FIFO_KHR;

  // Determine the number of VkImage's to use in the swap chain.
  // We need to acquire only 1 presentable image at at time.
  // Asking for minImageCount images ensures that we can acquire
  // 1 presentable image as long as we present it before attempting
  // to acquire another.
  desiredNumberOfSwapChainImages := surfCapabilities.minImageCount;

  if surfCapabilities.supportedTransforms and TVkFlags(VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR) > 0 then
  begin
    preTransform := VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
  end
  else
  begin
    preTransform := surfCapabilities.currentTransform;
  end;

  // Find a supported composite alpha mode - one of these is guaranteed to be set
  compositeAlpha := VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
  compositeAlphaFlags[0] := VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
  compositeAlphaFlags[1] := VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR;
  compositeAlphaFlags[2] := VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR;
  compositeAlphaFlags[3] := VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;
  for i := 0 to High(compositeAlphaFlags) do
  begin
    if surfCapabilities.supportedCompositeAlpha and TVkFlags(compositeAlphaFlags[i]) > 0 then
    begin
      compositeAlpha := compositeAlphaFlags[i];
      break;
    end;
  end;

  //VkSwapchainCreateInfoKHR swapchain_ci = {};
  FillChar(swapchain_ci, sizeof(swapchain_ci), 0);
  swapchain_ci.sType := VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
  swapchain_ci.pNext := nil;
  swapchain_ci.surface := info.surface;
  swapchain_ci.minImageCount := desiredNumberOfSwapChainImages;
  swapchain_ci.imageFormat := info.format;
  swapchain_ci.imageExtent.width := swapchainExtent.width;
  swapchain_ci.imageExtent.height := swapchainExtent.height;
  swapchain_ci.preTransform := preTransform;
  swapchain_ci.compositeAlpha := compositeAlpha;
  swapchain_ci.imageArrayLayers := 1;
  swapchain_ci.presentMode := swapchainPresentMode;
  swapchain_ci.oldSwapchain := VK_NULL_HANDLE;
{$ifndef __ANDROID__}
  swapchain_ci.clipped := VK_TRUE;
{$else}
  swapchain_ci.clipped := VK_FALSE;
{$endif}
  swapchain_ci.imageColorSpace := VK_COLORSPACE_SRGB_NONLINEAR_KHR;
  swapchain_ci.imageUsage := usageFlags;
  swapchain_ci.imageSharingMode := VK_SHARING_MODE_EXCLUSIVE;
  swapchain_ci.queueFamilyIndexCount := 0;
  swapchain_ci.pQueueFamilyIndices := nil;
  //uint32_t queueFamilyIndices[2] = {(uint32_t)info.graphics_queue_family_index, (uint32_t)info.present_queue_family_index};
  queueFamilyIndices[0] := info.graphics_queue_family_index;
  queueFamilyIndices[1] := info.present_queue_family_index;
  if (info.graphics_queue_family_index <> info.present_queue_family_index) then
  begin
    // If the graphics and present queues are from different queue families,
    // we either have to explicitly transfer ownership of images between the
    // queues, or we have to create the swapchain with imageSharingMode
    // as VK_SHARING_MODE_CONCURRENT
    swapchain_ci.imageSharingMode := VK_SHARING_MODE_CONCURRENT;
    swapchain_ci.queueFamilyIndexCount := 2;
    swapchain_ci.pQueueFamilyIndices := queueFamilyIndices;
  end;

  res := vk.CreateSwapchainKHR(info.device, @swapchain_ci, nil, @info.swap_chain);
  assert(res = VK_SUCCESS);

  res := vk.GetSwapchainImagesKHR(info.device, info.swap_chain, @info.swapchainImageCount, nil);
  assert(res = VK_SUCCESS);

  //VkImage *swapchainImages = (VkImage *)malloc(info.swapchainImageCount * sizeof(VkImage));
  SetLength(swapchainImages, info.swapchainImageCount);
  assert(Length(swapchainImages) > 0);
  res := vk.GetSwapchainImagesKHR(info.device, info.swap_chain, @info.swapchainImageCount, @swapchainImages[0]);
  assert(res = VK_SUCCESS);

  for i := 0 to info.swapchainImageCount - 1 do
  begin
    FillChar(color_image_view, sizeof(color_image_view), 0);
    color_image_view.sType := VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    color_image_view.pNext := nil;
    color_image_view.format := info.format;
    color_image_view.components.r := VK_COMPONENT_SWIZZLE_R;
    color_image_view.components.g := VK_COMPONENT_SWIZZLE_G;
    color_image_view.components.b := VK_COMPONENT_SWIZZLE_B;
    color_image_view.components.a := VK_COMPONENT_SWIZZLE_A;
    color_image_view.subresourceRange.aspectMask := TVkFlags(VK_IMAGE_ASPECT_COLOR_BIT);
    color_image_view.subresourceRange.baseMipLevel := 0;
    color_image_view.subresourceRange.levelCount := 1;
    color_image_view.subresourceRange.baseArrayLayer := 0;
    color_image_view.subresourceRange.layerCount := 1;
    color_image_view.viewType := VK_IMAGE_VIEW_TYPE_2D;
    color_image_view.flags := 0;

    sc_buffer.image := swapchainImages[i];

    color_image_view.image := sc_buffer.image;

    res := vk.CreateImageView(info.device, @color_image_view, nil, @sc_buffer.view);
    //info.buffers.push_back(sc_buffer);
    SetLength(info.buffers, Length(info.buffers) + 1);
    info.buffers[High(info.buffers)] := sc_buffer;
    assert(res = VK_SUCCESS);
  end;
  //free(swapchainImages);
  info.current_buffer := 0;
  //if (NULL != presentModes) {
  //    free(presentModes);
  //}
end;

procedure init_depth_buffer(var info: TSampleInfo);
  var res: TVkResult;
  var pass: Boolean;
  var image_info: TVkImageCreateInfo;
  var depth_format: TVkFormat;
  var props: TVkFormatProperties;
  var mem_alloc: TVkMemoryAllocateInfo;
  var view_info: TVkImageViewCreateInfo;
  var mem_reqs: TVkMemoryRequirements;
begin
  FillChar(image_info, sizeof(image_info), 0);
  // allow custom depth formats
{$if defined(__ANDROID__)}
  // Depth format needs to be VK_FORMAT_D24_UNORM_S8_UINT on Android.
  info.depth.format := VK_FORMAT_D24_UNORM_S8_UINT;
{$elseif defined(VK_USE_PLATFORM_IOS_MVK)}
  if (info.depth.format = VK_FORMAT_UNDEFINED) then info.depth.format := VK_FORMAT_D32_SFLOAT;
{$else}
  if (info.depth.format = VK_FORMAT_UNDEFINED) then info.depth.format := VK_FORMAT_D16_UNORM;
{$endif}

  depth_format := info.depth.format;
  vk.GetPhysicalDeviceFormatProperties(info.gpus[0], depth_format, @props);
  if props.linearTilingFeatures and TVkFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT) > 0 then
  begin
    image_info.tiling := VK_IMAGE_TILING_LINEAR;
  end
  else if props.optimalTilingFeatures and TVkFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT) > 0 then
  begin
    image_info.tiling := VK_IMAGE_TILING_OPTIMAL;
  end
  else
  begin
    // Try other depth formats?
    Write('depth_format '); Write(depth_format); WriteLn(' Unsupported.');
    Halt;
  end;

  image_info.sType := VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
  image_info.pNext := nil;
  image_info.imageType := VK_IMAGE_TYPE_2D;
  image_info.format := depth_format;
  image_info.extent.width := info.width;
  image_info.extent.height := info.height;
  image_info.extent.depth := 1;
  image_info.mipLevels := 1;
  image_info.arrayLayers := 1;
  image_info.samples := NUM_SAMPLES;
  image_info.initialLayout := VK_IMAGE_LAYOUT_UNDEFINED;
  image_info.queueFamilyIndexCount := 0;
  image_info.pQueueFamilyIndices := nil;
  image_info.sharingMode := VK_SHARING_MODE_EXCLUSIVE;
  image_info.usage := TVkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT);
  image_info.flags := 0;

  FillChar(mem_alloc, sizeof(mem_alloc), 0);
  mem_alloc.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  mem_alloc.pNext := nil;
  mem_alloc.allocationSize := 0;
  mem_alloc.memoryTypeIndex := 0;

  FillChar(view_info, sizeof(view_info), 0);
  view_info.sType := VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
  view_info.pNext := nil;
  view_info.image := VK_NULL_HANDLE;
  view_info.format := depth_format;
  view_info.components.r := VK_COMPONENT_SWIZZLE_R;
  view_info.components.g := VK_COMPONENT_SWIZZLE_G;
  view_info.components.b := VK_COMPONENT_SWIZZLE_B;
  view_info.components.a := VK_COMPONENT_SWIZZLE_A;
  view_info.subresourceRange.aspectMask := TVkFlags(VK_IMAGE_ASPECT_DEPTH_BIT);
  view_info.subresourceRange.baseMipLevel := 0;
  view_info.subresourceRange.levelCount := 1;
  view_info.subresourceRange.baseArrayLayer := 0;
  view_info.subresourceRange.layerCount := 1;
  view_info.viewType := VK_IMAGE_VIEW_TYPE_2D;
  view_info.flags := 0;

  if (depth_format = VK_FORMAT_D16_UNORM_S8_UINT)
  or (depth_format = VK_FORMAT_D24_UNORM_S8_UINT)
  or (depth_format = VK_FORMAT_D32_SFLOAT_S8_UINT) then
  begin
    view_info.subresourceRange.aspectMask := view_info.subresourceRange.aspectMask or TVkFlags(VK_IMAGE_ASPECT_STENCIL_BIT);
  end;

  // Create image
  res := vk.CreateImage(info.device, @image_info, nil, @info.depth.image);
  assert(res = VK_SUCCESS);

  vk.GetImageMemoryRequirements(info.device, info.depth.image, @mem_reqs);

  mem_alloc.allocationSize := mem_reqs.size;
  // Use the memory properties to determine the type of memory required
  pass := memory_type_from_properties(info, mem_reqs.memoryTypeBits, TVkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), @mem_alloc.memoryTypeIndex);
  assert(pass);

  // Allocate memory
  res := vk.AllocateMemory(info.device, @mem_alloc, nil, @info.depth.mem);
  assert(res = VK_SUCCESS);

  // Bind memory
  res := vk.BindImageMemory(info.device, info.depth.image, info.depth.mem, 0);
  assert(res = VK_SUCCESS);

  // Create image view
  view_info.image := info.depth.image;
  res := vk.CreateImageView(info.device, @view_info, nil, @info.depth.view);
  assert(res = VK_SUCCESS);
end;

procedure init_uniform_buffer(var info: TSampleInfo);
  var res: TVkResult;
  var pass: Boolean;
  var fov: TVkFloat;
  var buf_info: TVkBufferCreateInfo;
  var mem_reqs: TVkMemoryRequirements;
  var alloc_info: TVkMemoryAllocateInfo;
  var pData: PVkUInt8;
begin
    fov := LabDegToRad * 45;
    if (info.width > info.height) then
    begin
      fov *= info.height / info.width;
    end;
    info.Projection := LabMatProj(fov, info.width / info.height, 0.1, 100);
    info.View := LabMatView(LabVec3(-5, 3, -10), LabVec3, LabVec3(0, -1, 0));
    info.Model := LabMatIdentity;
    // Vulkan clip space has inverted Y and half Z.
    //info.Clip := glm::mat4(1.0f, 0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.5f, 0.0f, 0.0f, 0.0f, 0.5f, 1.0f);
    info.Clip := LabMat(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 0.5, 0,
      0, 0, 0.5, 1
    );

    info.MVP := info.Model * info.View * info.Projection * info.Clip;

    // VULKAN_KEY_START
    FillChar(buf_info, SizeOf(buf_info), 0);
    buf_info.sType := VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    buf_info.pNext := nil;
    buf_info.usage := TVkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT);
    buf_info.size := SizeOf(info.MVP);
    buf_info.queueFamilyIndexCount := 0;
    buf_info.pQueueFamilyIndices := nil;
    buf_info.sharingMode := VK_SHARING_MODE_EXCLUSIVE;
    buf_info.flags := 0;
    res := vk.CreateBuffer(info.device, @buf_info, nil, @info.uniform_data.buf);
    assert(res = VK_SUCCESS);

    vk.GetBufferMemoryRequirements(info.device, info.uniform_data.buf, @mem_reqs);

    FillChar(alloc_info, SizeOf(alloc_info), 0);
    alloc_info.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    alloc_info.pNext := nil;
    alloc_info.memoryTypeIndex := 0;

    alloc_info.allocationSize := mem_reqs.size;
    pass := memory_type_from_properties(
      info, mem_reqs.memoryTypeBits,
      TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
      @alloc_info.memoryTypeIndex
    );
    assert(pass);

    res := vk.AllocateMemory(info.device, @alloc_info, nil, @info.uniform_data.mem);
    assert(res = VK_SUCCESS);

    res := vk.BindBufferMemory(info.device, info.uniform_data.buf, info.uniform_data.mem, 0);
    assert(res = VK_SUCCESS);

    pData := nil;
    res := vk.MapMemory(info.device, info.uniform_data.mem, 0, mem_reqs.size, 0, PPVkVoid(@pData));
    assert(res = VK_SUCCESS);

    //memcpy(pData, &info.MVP, sizeof(info.MVP));
    Move(info.MVP, pData^, SizeOf(info.MVP));

    vk.UnmapMemory(info.device, info.uniform_data.mem);

    info.uniform_data.buffer_info.buffer := info.uniform_data.buf;
    info.uniform_data.buffer_info.offset := 0;
    info.uniform_data.buffer_info.range := SizeOf(info.MVP);
end;

procedure init_descriptor_and_pipeline_layouts(
  var info: TSampleInfo;
  const use_texture: Boolean;
  const descSetLayoutCreateFlags: TVkDescriptorSetLayoutCreateFlags
);
  var res: TVkResult;
  var layout_bindings: array[0..1] of TVkDescriptorSetLayoutBinding;
  var descriptor_layout: TVkDescriptorSetLayoutCreateInfo;
  var pPipelineLayoutCreateInfo: TVkPipelineLayoutCreateInfo;
begin
  layout_bindings[0].binding := 0;
  layout_bindings[0].descriptorType := VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
  layout_bindings[0].descriptorCount := 1;
  layout_bindings[0].stageFlags := TVkFlags(VK_SHADER_STAGE_VERTEX_BIT);
  layout_bindings[0].pImmutableSamplers := nil;

  if use_texture then
  begin
    layout_bindings[1].binding := 1;
    layout_bindings[1].descriptorType := VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    layout_bindings[1].descriptorCount := 1;
    layout_bindings[1].stageFlags := TVkFlags(VK_SHADER_STAGE_FRAGMENT_BIT);
    layout_bindings[1].pImmutableSamplers := nil;
  end;

  // Next take layout bindings and use them to create a descriptor set layout
  FillChar(descriptor_layout, SizeOf(descriptor_layout), 0);
  descriptor_layout.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
  descriptor_layout.pNext := nil;
  descriptor_layout.flags := descSetLayoutCreateFlags;
  if use_texture then descriptor_layout.bindingCount := 2 else descriptor_layout.bindingCount := 1;
  descriptor_layout.pBindings := layout_bindings;

  //info.desc_layout.resize(NUM_DESCRIPTOR_SETS);
  SetLength(info.desc_layout, NUM_DESCRIPTOR_SETS);

  res := vk.CreateDescriptorSetLayout(info.device, @descriptor_layout, nil, @info.desc_layout[0]);
  assert(res = VK_SUCCESS);

  // Now use the descriptor layout to create a pipeline layout
  FillChar(pPipelineLayoutCreateInfo, SizeOf(pPipelineLayoutCreateInfo), 0);
  pPipelineLayoutCreateInfo.sType := VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
  pPipelineLayoutCreateInfo.pNext := nil;
  pPipelineLayoutCreateInfo.pushConstantRangeCount := 0;
  pPipelineLayoutCreateInfo.pPushConstantRanges := nil;
  pPipelineLayoutCreateInfo.setLayoutCount := NUM_DESCRIPTOR_SETS;
  pPipelineLayoutCreateInfo.pSetLayouts := @info.desc_layout[0];

  res := vk.CreatePipelineLayout(info.device, @pPipelineLayoutCreateInfo, nil, @info.pipeline_layout);
  assert(res = VK_SUCCESS);
end;

procedure init_renderpass(
  var info: TSampleInfo;
  const include_depth: Boolean;
  const clear: Boolean;
  const finalLayout: TVkImageLayout
);
  var res: TVkResult;
  var attachments: array [0..1] of TVkAttachmentDescription;
  var color_reference: TVkAttachmentReference;
  var depth_reference: TVkAttachmentReference;
  var subpass: TVkSubpassDescription;
  var rp_info: TVkRenderPassCreateInfo;
begin
  // Need attachments for render target and depth buffer
  attachments[0].format := info.format;
  attachments[0].samples := NUM_SAMPLES;
  if clear then attachments[0].loadOp := VK_ATTACHMENT_LOAD_OP_CLEAR else attachments[0].loadOp := VK_ATTACHMENT_LOAD_OP_LOAD;
  attachments[0].storeOp := VK_ATTACHMENT_STORE_OP_STORE;
  attachments[0].stencilLoadOp := VK_ATTACHMENT_LOAD_OP_DONT_CARE;
  attachments[0].stencilStoreOp := VK_ATTACHMENT_STORE_OP_DONT_CARE;
  attachments[0].initialLayout := VK_IMAGE_LAYOUT_UNDEFINED;
  attachments[0].finalLayout := finalLayout;
  attachments[0].flags := 0;

  if include_depth then
  begin
    attachments[1].format := info.depth.format;
    attachments[1].samples := NUM_SAMPLES;
    if clear then attachments[1].loadOp := VK_ATTACHMENT_LOAD_OP_CLEAR else attachments[1].loadOp := VK_ATTACHMENT_LOAD_OP_LOAD;
    attachments[1].storeOp := VK_ATTACHMENT_STORE_OP_STORE;
    attachments[1].stencilLoadOp := VK_ATTACHMENT_LOAD_OP_LOAD;
    attachments[1].stencilStoreOp := VK_ATTACHMENT_STORE_OP_STORE;
    attachments[1].initialLayout := VK_IMAGE_LAYOUT_UNDEFINED;
    attachments[1].finalLayout := VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
    attachments[1].flags := 0;
  end;

  FillChar(color_reference, SizeOf(color_reference), 0);
  color_reference.attachment := 0;
  color_reference.layout := VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

  FillChar(depth_reference, SizeOf(depth_reference), 0);
  depth_reference.attachment := 1;
  depth_reference.layout := VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

  FillChar(subpass, SizeOf(subpass), 0);
  subpass.pipelineBindPoint := VK_PIPELINE_BIND_POINT_GRAPHICS;
  subpass.flags := 0;
  subpass.inputAttachmentCount := 0;
  subpass.pInputAttachments := nil;
  subpass.colorAttachmentCount := 1;
  subpass.pColorAttachments := @color_reference;
  subpass.pResolveAttachments := nil;
  if include_depth then subpass.pDepthStencilAttachment := @depth_reference else subpass.pDepthStencilAttachment := nil;
  subpass.preserveAttachmentCount := 0;
  subpass.pPreserveAttachments := nil;

  FillChar(rp_info, SizeOf(rp_info), 0);
  rp_info.sType := VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
  rp_info.pNext := nil;
  if include_depth then rp_info.attachmentCount := 2 else rp_info.attachmentCount := 1;
  rp_info.pAttachments := attachments;
  rp_info.subpassCount := 1;
  rp_info.pSubpasses := @subpass;
  rp_info.dependencyCount := 0;
  rp_info.pDependencies := nil;

  res := vk.CreateRenderPass(info.device, @rp_info, nil, @info.render_pass);
  assert(res = VK_SUCCESS);
end;

procedure init_shaders(
  var info: TSampleInfo;
  const vertShaderBinary: PVkUInt8; const vertShaderSize: TVkUInt32;
  const fragShaderBinary: PVkUInt8; const fragShaderSize: TVkUInt32
);
  var res: TVkResult;
  var moduleCreateInfo: TVkShaderModuleCreateInfo;
begin
  // If no shaders were submitted, just return
  if not Assigned(vertShaderBinary) and not Assigned(fragShaderBinary) then Exit;
  if Assigned(vertShaderBinary) then
  begin
    //std::vector<unsigned int> vtx_spv;
    info.shaderStages[0].sType := VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    info.shaderStages[0].pNext := nil;
    info.shaderStages[0].pSpecializationInfo := nil;
    info.shaderStages[0].flags := 0;
    info.shaderStages[0].stage := VK_SHADER_STAGE_VERTEX_BIT;
    info.shaderStages[0].pName := 'main';

    //retVal = GLSLtoSPV(VK_SHADER_STAGE_VERTEX_BIT, vertShaderText, vtx_spv);
    //assert(retVal);

    moduleCreateInfo.sType := VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    moduleCreateInfo.pNext := nil;
    moduleCreateInfo.flags := 0;
    moduleCreateInfo.codeSize := vertShaderSize;//vtx_spv.size() * sizeof(unsigned int);
    moduleCreateInfo.pCode := PVkUInt32(vertShaderBinary);//vtx_spv.data();
    res := vk.CreateShaderModule(info.device, @moduleCreateInfo, nil, @info.shaderStages[0].module);
    assert(res = VK_SUCCESS);
  end;

  if Assigned(fragShaderBinary) then
  begin
    //std::vector<unsigned int> frag_spv;
    info.shaderStages[1].sType := VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    info.shaderStages[1].pNext := nil;
    info.shaderStages[1].pSpecializationInfo := nil;
    info.shaderStages[1].flags := 0;
    info.shaderStages[1].stage := VK_SHADER_STAGE_FRAGMENT_BIT;
    info.shaderStages[1].pName := 'main';

    //retVal = GLSLtoSPV(VK_SHADER_STAGE_FRAGMENT_BIT, fragShaderText, frag_spv);
    //assert(retVal);

    moduleCreateInfo.sType := VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    moduleCreateInfo.pNext := nil;
    moduleCreateInfo.flags := 0;
    moduleCreateInfo.codeSize := fragShaderSize;//frag_spv.size() * sizeof(unsigned int);
    moduleCreateInfo.pCode := PVkUInt32(fragShaderBinary);//frag_spv.data();
    res := vk.CreateShaderModule(info.device, @moduleCreateInfo, nil, @info.shaderStages[1].module);
    assert(res = VK_SUCCESS);
  end;
end;

procedure init_framebuffers(var info: TSampleInfo; const include_depth: Boolean);
  var res: TVkResult;
  var attachments: array [0..1] of TVkImageView;
  var fb_info: TVkFramebufferCreateInfo;
  var i: TVkUInt32;
begin
  attachments[1] := info.depth.view;

  FillChar(fb_info, SizeOf(fb_info), 0);
  fb_info.sType := VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
  fb_info.pNext := nil;
  fb_info.renderPass := info.render_pass;
  if include_depth then fb_info.attachmentCount := 2 else fb_info.attachmentCount := 1;
  fb_info.pAttachments := attachments;
  fb_info.width := info.width;
  fb_info.height := info.height;
  fb_info.layers := 1;

  //uint32_t i;

  //(VkFramebuffer *)malloc(info.swapchainImageCount * sizeof(VkFramebuffer));
  //PVkFramebuffer(GetMemory(info.swapchainImageCount * SizeOf(VkFramebuffer)));
  SetLength(info.framebuffers, info.swapchainImageCount);

  for i := 0 to info.swapchainImageCount - 1 do
  begin
    attachments[0] := info.buffers[i].view;
    res := vk.CreateFramebuffer(info.device, @fb_info, nil, @info.framebuffers[i]);
    assert(res = VK_SUCCESS);
  end;
end;

procedure init_vertex_buffer(
  var info: TSampleInfo;
  const vertexData: Pointer;
  const dataSize: TVkUInt32;
  const dataStride: TVkUInt32;
  const use_texture: Boolean
);
  var res: TVkResult;
  var pass: Boolean;
  var buf_info: TVkBufferCreateInfo;
  var mem_reqs: TVkMemoryRequirements;
  var alloc_info: TVkMemoryAllocateInfo;
  var pData: PUInt8;
begin
  FillChar(buf_info, SizeOf(buf_info), 0);
  buf_info.sType := VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
  buf_info.pNext := nil;
  buf_info.usage := TVkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
  buf_info.size := dataSize;
  buf_info.queueFamilyIndexCount := 0;
  buf_info.pQueueFamilyIndices := nil;
  buf_info.sharingMode := VK_SHARING_MODE_EXCLUSIVE;
  buf_info.flags := 0;
  res := vk.CreateBuffer(info.device, @buf_info, nil, @info.vertex_buffer.buf);
  assert(res = VK_SUCCESS);

  vk.GetBufferMemoryRequirements(info.device, info.vertex_buffer.buf, @mem_reqs);

  FillChar(alloc_info, SizeOf(alloc_info), 0);
  alloc_info.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  alloc_info.pNext := nil;
  alloc_info.memoryTypeIndex := 0;

  alloc_info.allocationSize := mem_reqs.size;
  pass := memory_type_from_properties(
    info, mem_reqs.memoryTypeBits,
    TVkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
    @alloc_info.memoryTypeIndex
  );
  assert(pass);

  res := vk.AllocateMemory(info.device, @alloc_info, nil, @info.vertex_buffer.mem);
  assert(res = VK_SUCCESS);
  info.vertex_buffer.buffer_info.range := mem_reqs.size;
  info.vertex_buffer.buffer_info.offset := 0;

  res := vk.MapMemory(info.device, info.vertex_buffer.mem, 0, mem_reqs.size, 0, PPVkVoid(@pData));
  assert(res = VK_SUCCESS);

  //memcpy(pData, vertexData, dataSize);
  Move(vertexData^, pData^, dataSize);

  vk.UnmapMemory(info.device, info.vertex_buffer.mem);

  res := vk.BindBufferMemory(info.device, info.vertex_buffer.buf, info.vertex_buffer.mem, 0);
  assert(res = VK_SUCCESS);

  info.vi_binding.binding := 0;
  info.vi_binding.inputRate := VK_VERTEX_INPUT_RATE_VERTEX;
  info.vi_binding.stride := dataStride;

  info.vi_attribs[0].binding := 0;
  info.vi_attribs[0].location := 0;
  info.vi_attribs[0].format := VK_FORMAT_R32G32B32A32_SFLOAT;
  info.vi_attribs[0].offset := 0;
  info.vi_attribs[1].binding := 0;
  info.vi_attribs[1].location := 1;
  if use_texture then info.vi_attribs[1].format := VK_FORMAT_R32G32_SFLOAT else info.vi_attribs[1].format := VK_FORMAT_R32G32B32A32_SFLOAT;
  info.vi_attribs[1].offset := 16;
end;

procedure init_descriptor_pool(var info: TSampleInfo; const use_texture: Boolean);
  var res: TVkResult;
  var type_count: array [0..1] of TVkDescriptorPoolSize;
  var descriptor_pool: TVkDescriptorPoolCreateInfo;
begin
  type_count[0].type_ := VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
  type_count[0].descriptorCount := 1;
  if use_texture then
  begin
    type_count[1].type_ := VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    type_count[1].descriptorCount := 1;
  end;

  FillChar(descriptor_pool, SizeOf(descriptor_pool), 0);
  descriptor_pool.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
  descriptor_pool.pNext := nil;
  descriptor_pool.maxSets := 1;
  if use_texture then descriptor_pool.poolSizeCount := 2 else descriptor_pool.poolSizeCount := 1;
  descriptor_pool.pPoolSizes := type_count;

  res := vk.CreateDescriptorPool(info.device, @descriptor_pool, nil, @info.desc_pool);
  assert(res = VK_SUCCESS);
end;

procedure init_descriptor_set(var info: TSampleInfo; const use_texture: Boolean);
  var res: TVkResult;
  var alloc_info: array[0..0] of TVkDescriptorSetAllocateInfo;
  var writes: array[0..1] of TVkWriteDescriptorSet;
  var write_count: TVkUInt32;
begin
  alloc_info[0].sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
  alloc_info[0].pNext := nil;
  alloc_info[0].descriptorPool := info.desc_pool;
  alloc_info[0].descriptorSetCount := NUM_DESCRIPTOR_SETS;
  alloc_info[0].pSetLayouts := @info.desc_layout[0];

  //info.desc_set.resize(NUM_DESCRIPTOR_SETS);
  SetLength(info.desc_set, NUM_DESCRIPTOR_SETS);
  res := vk.AllocateDescriptorSets(info.device, alloc_info, @info.desc_set[0]);
  assert(res = VK_SUCCESS);

  FillChar(writes[0], SizeOf(writes[0]), 0);
  writes[0].sType := VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
  writes[0].pNext := nil;
  writes[0].dstSet := info.desc_set[0];
  writes[0].descriptorCount := 1;
  writes[0].descriptorType := VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
  writes[0].pBufferInfo := @info.uniform_data.buffer_info;
  writes[0].dstArrayElement := 0;
  writes[0].dstBinding := 0;

  if use_texture then
  begin
    FillChar(writes[1], SizeOf(writes[1]), 0);
    writes[1].sType := VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    writes[1].dstSet := info.desc_set[0];
    writes[1].dstBinding := 1;
    writes[1].descriptorCount := 1;
    writes[1].descriptorType := VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    writes[1].pImageInfo := @info.texture_data.image_info;
    writes[1].dstArrayElement := 0;
  end;
  if use_texture then write_count := 2 else write_count := 1;
  vk.UpdateDescriptorSets(info.device, write_count, @writes[0], 0, nil);
end;

procedure init_pipeline_cache(var info: TSampleInfo);
  var res: TVkResult;
  var pipelineCache: TVkPipelineCacheCreateInfo;
begin
  pipelineCache.sType := VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
  pipelineCache.pNext := nil;
  pipelineCache.initialDataSize := 0;
  pipelineCache.pInitialData := nil;
  pipelineCache.flags := 0;
  res := vk.CreatePipelineCache(info.device, @pipelineCache, nil, @info.pipelineCache);
  assert(res = VK_SUCCESS);
end;

procedure init_pipeline(var info: TSampleInfo; const include_depth: TVkBool32; const include_vi: TVkBool32);
  var res: TVkResult;
  var dynamicStateEnables: array [0..VK_DYNAMIC_STATE_RANGE_SIZE - 1] of TVkDynamicState;
  var dynamicState: TVkPipelineDynamicStateCreateInfo;
  var vi: TVkPipelineVertexInputStateCreateInfo;
  var ia: TVkPipelineInputAssemblyStateCreateInfo;
  var rs: TVkPipelineRasterizationStateCreateInfo;
  var cb: TVkPipelineColorBlendStateCreateInfo;
  var att_state: array [0..0] of TVkPipelineColorBlendAttachmentState;
  var vp: TVkPipelineViewportStateCreateInfo;
  var ds: TVkPipelineDepthStencilStateCreateInfo;
  var ms: TVkPipelineMultisampleStateCreateInfo;
  var pipeline: TVkGraphicsPipelineCreateInfo;
begin
  FillChar(dynamicState, SizeOf(dynamicState), 0);
  FillChar(dynamicStateEnables, 0, SizeOf(dynamicStateEnables));

  dynamicState.sType := VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
  dynamicState.pNext := nil;
  dynamicState.pDynamicStates := @dynamicStateEnables;
  dynamicState.dynamicStateCount := 0;

  FillChar(vi, SizeOf(vi), 0);
  vi.sType := VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
  if include_vi > 0 then
  begin
    vi.pNext := nil;
    vi.flags := 0;
    vi.vertexBindingDescriptionCount := 1;
    vi.pVertexBindingDescriptions := @info.vi_binding;
    vi.vertexAttributeDescriptionCount := 2;
    vi.pVertexAttributeDescriptions := info.vi_attribs;
  end;
  ia.sType := VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
  ia.pNext := nil;
  ia.flags := 0;
  ia.primitiveRestartEnable := VK_FALSE;
  ia.topology := VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;

  rs.sType := VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
  rs.pNext := nil;
  rs.flags := 0;
  rs.polygonMode := VK_POLYGON_MODE_FILL;
  rs.cullMode := TVkFlags(VK_CULL_MODE_BACK_BIT);
  rs.frontFace := VK_FRONT_FACE_CLOCKWISE;
  rs.depthClampEnable := VK_FALSE;
  rs.rasterizerDiscardEnable := VK_FALSE;
  rs.depthBiasEnable := VK_FALSE;
  rs.depthBiasConstantFactor := 0;
  rs.depthBiasClamp := 0;
  rs.depthBiasSlopeFactor := 0;
  rs.lineWidth := 1;

  cb.sType := VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
  cb.flags := 0;
  cb.pNext := nil;

  att_state[0].colorWriteMask := $f;
  att_state[0].blendEnable := VK_FALSE;
  att_state[0].alphaBlendOp := VK_BLEND_OP_ADD;
  att_state[0].colorBlendOp := VK_BLEND_OP_ADD;
  att_state[0].srcColorBlendFactor := VK_BLEND_FACTOR_ZERO;
  att_state[0].dstColorBlendFactor := VK_BLEND_FACTOR_ZERO;
  att_state[0].srcAlphaBlendFactor := VK_BLEND_FACTOR_ZERO;
  att_state[0].dstAlphaBlendFactor := VK_BLEND_FACTOR_ZERO;
  cb.attachmentCount := 1;
  cb.pAttachments := att_state;
  cb.logicOpEnable := VK_FALSE;
  cb.logicOp := VK_LOGIC_OP_NO_OP;
  cb.blendConstants[0] := 1;
  cb.blendConstants[1] := 1;
  cb.blendConstants[2] := 1;
  cb.blendConstants[3] := 1;

  FillChar(vp, SizeOf(vp), 0);
  vp.sType := VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
  vp.pNext := nil;
  vp.flags := 0;
{$ifndef __ANDROID__}
  vp.viewportCount := NUM_VIEWPORTS;
  dynamicStateEnables[dynamicState.dynamicStateCount] := VK_DYNAMIC_STATE_VIEWPORT;
  Inc(dynamicState.dynamicStateCount);
  vp.scissorCount := NUM_SCISSORS;
  dynamicStateEnables[dynamicState.dynamicStateCount] := VK_DYNAMIC_STATE_SCISSOR;
  Inc(dynamicState.dynamicStateCount);
  vp.pScissors := nil;
  vp.pViewports := nil;
{$else}
  // Temporary disabling dynamic viewport on Android because some of drivers doesn't
  // support the feature.
  VkViewport viewports;
  viewports.minDepth = 0.0f;
  viewports.maxDepth = 1.0f;
  viewports.x = 0;
  viewports.y = 0;
  viewports.width = info.width;
  viewports.height = info.height;
  VkRect2D scissor;
  scissor.extent.width = info.width;
  scissor.extent.height = info.height;
  scissor.offset.x = 0;
  scissor.offset.y = 0;
  vp.viewportCount = NUM_VIEWPORTS;
  vp.scissorCount = NUM_SCISSORS;
  vp.pScissors = &scissor;
  vp.pViewports = &viewports;
{$endif}
  ds.sType := VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
  ds.pNext := nil;
  ds.flags := 0;
  ds.depthTestEnable := include_depth;
  ds.depthWriteEnable := include_depth;
  ds.depthCompareOp := VK_COMPARE_OP_LESS_OR_EQUAL;
  ds.depthBoundsTestEnable := VK_FALSE;
  ds.stencilTestEnable := VK_FALSE;
  ds.back.failOp := VK_STENCIL_OP_KEEP;
  ds.back.passOp := VK_STENCIL_OP_KEEP;
  ds.back.compareOp := VK_COMPARE_OP_ALWAYS;
  ds.back.compareMask := 0;
  ds.back.reference := 0;
  ds.back.depthFailOp := VK_STENCIL_OP_KEEP;
  ds.back.writeMask := 0;
  ds.minDepthBounds := 0;
  ds.maxDepthBounds := 0;
  ds.stencilTestEnable := VK_FALSE;
  ds.front := ds.back;

  ms.sType := VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
  ms.pNext := nil;
  ms.flags := 0;
  ms.pSampleMask := nil;
  ms.rasterizationSamples := NUM_SAMPLES;
  ms.sampleShadingEnable := VK_FALSE;
  ms.alphaToCoverageEnable := VK_FALSE;
  ms.alphaToOneEnable := VK_FALSE;
  ms.minSampleShading := 0;

  pipeline.sType := VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
  pipeline.pNext := nil;
  pipeline.layout := info.pipeline_layout;
  pipeline.basePipelineHandle := VK_NULL_HANDLE;
  pipeline.basePipelineIndex := 0;
  pipeline.flags := 0;
  pipeline.pVertexInputState := @vi;
  pipeline.pInputAssemblyState := @ia;
  pipeline.pRasterizationState := @rs;
  pipeline.pColorBlendState := @cb;
  pipeline.pTessellationState := nil;
  pipeline.pMultisampleState := @ms;
  pipeline.pDynamicState := @dynamicState;
  pipeline.pViewportState := @vp;
  pipeline.pDepthStencilState := @ds;
  pipeline.pStages := info.shaderStages;
  pipeline.stageCount := 2;
  pipeline.renderPass := info.render_pass;
  pipeline.subpass := 0;

  res := vk.CreateGraphicsPipelines(info.device, info.pipelineCache, 1, @pipeline, nil, @info.pipeline);
  assert(res = VK_SUCCESS);
end;

procedure init_viewports(var info: TSampleInfo);
begin
{$ifdef __ANDROID__}
// Disable dynamic viewport on Android. Some drive has an issue with the dynamic viewport
// feature.
{$else}
  info.viewport.height := info.height;
  info.viewport.width := info.width;
  info.viewport.minDepth := 0;
  info.viewport.maxDepth := 1;
  info.viewport.x := 0;
  info.viewport.y := 0;
  vk.CmdSetViewport(info.cmd, 0, NUM_VIEWPORTS, @info.viewport);
{$endif}
end;

procedure init_scissors(var info: TSampleInfo);
begin
{$ifdef __ANDROID__}
// Disable dynamic viewport on Android. Some drive has an issue with the dynamic scissors
// feature.
{$else}
  info.scissor.extent.width := info.width;
  info.scissor.extent.height := info.height;
  info.scissor.offset.x := 0;
  info.scissor.offset.y := 0;
  vk.CmdSetScissor(info.cmd, 0, NUM_SCISSORS, @info.scissor);
{$endif}
end;

procedure destroy_pipeline(var info: TSampleInfo);
begin
  vk.DestroyPipeline(info.device, info.pipeline, nil);
end;

procedure destroy_pipeline_cache(var info: TSampleInfo);
begin
  vk.DestroyPipelineCache(info.device, info.pipelineCache, nil);
end;

procedure destroy_descriptor_pool(var info: TSampleInfo);
begin
  vk.DestroyDescriptorPool(info.device, info.desc_pool, nil);
end;

procedure destroy_vertex_buffer(var info: TSampleInfo);
begin
  vk.DestroyBuffer(info.device, info.vertex_buffer.buf, nil);
  vk.FreeMemory(info.device, info.vertex_buffer.mem, nil);
end;

procedure destroy_framebuffers(var info: TSampleInfo);
  var i: TVkUInt32;
begin
  for i := 0 to info.swapchainImageCount - 1 do
  begin
    vk.DestroyFramebuffer(info.device, info.framebuffers[i], nil);
  end;
  SetLength(info.framebuffers, 0);
end;

procedure destroy_shaders(var info: TSampleInfo);
begin
  vk.DestroyShaderModule(info.device, info.shaderStages[0].module, nil);
  vk.DestroyShaderModule(info.device, info.shaderStages[1].module, nil);
end;

procedure destroy_renderpass(var info: TSampleInfo);
begin
  vk.DestroyRenderPass(info.device, info.render_pass, nil);
end;

procedure destroy_descriptor_and_pipeline_layouts(var info: TSampleInfo);
  var i: TVkInt32;
begin
  for i := 0 to NUM_DESCRIPTOR_SETS - 1 do vk.DestroyDescriptorSetLayout(info.device, info.desc_layout[i], nil);
  vk.DestroyPipelineLayout(info.device, info.pipeline_layout, nil);
end;

procedure destroy_uniform_buffer(var info: TSampleInfo);
begin
  vk.DestroyBuffer(info.device, info.uniform_data.buf, nil);
  vk.FreeMemory(info.device, info.uniform_data.mem, nil);
end;

procedure destroy_depth_buffer(var info: TSampleInfo);
begin
  vk.DestroyImageView(info.device, info.depth.view, nil);
  vk.DestroyImage(info.device, info.depth.image, nil);
  vk.FreeMemory(info.device, info.depth.mem, nil);
end;

procedure destroy_swap_chain(var info: TSampleInfo);
  var i: TVkUInt32;
begin
  for i := 0 to info.swapchainImageCount - 1 do
  begin
    vk.DestroyImageView(info.device, info.buffers[i].view, nil);
  end;
  vk.DestroySwapchainKHR(info.device, info.swap_chain, nil);
end;

procedure destroy_command_buffer(var info: TSampleInfo);
  var cmd_bufs: array [0..0] of TVkCommandBuffer;
begin
  cmd_bufs[0] := info.cmd;
  vk.FreeCommandBuffers(info.device, info.cmd_pool, 1, @cmd_bufs[0]);
end;

procedure destroy_command_pool(var info: TSampleInfo);
begin
  vk.DestroyCommandPool(info.device, info.cmd_pool, nil);
end;

procedure destroy_device(var info: TSampleInfo);
begin
  vk.DeviceWaitIdle(info.device);
  vk.DestroyDevice(info.device, nil);
end;

procedure destroy_instance(var info: TSampleInfo);
begin
  vk.DestroyInstance(info.inst, nil);
end;

end.
