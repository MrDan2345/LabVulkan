program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils,
  Classes,
  Vulkan,
  shader_data,
  cube_data,
  sample_info
  { you can add units after this };

var
  info: TSampleInfo;

procedure Main;
  var res: TVkResult;
  var clear_values: array [0..1] of TVkClearValue;
  var imageAcquiredSemaphore: TVkSemaphore;
  var imageAcquiredSemaphoreCreateInfo: TVkSemaphoreCreateInfo;
  var rp_begin: TVkRenderPassBeginInfo;
  var cmd_bufs: array [0..0] of TVkCommandBuffer;
  var fenceInfo: TVkFenceCreateInfo;
  var drawFence: TVkFence;
  var pipe_stage_flags: TVkPipelineStageFlags;
  var submit_info: array [0..0] of TVkSubmitInfo;
  var present: TVkPresentInfoKHR;
  const offsets: array [0..0] of TVkDeviceSize = (0);
  const depthPresent = VK_TRUE;
begin
  LoadVulkanLibrary;
  LoadVulkanGlobalCommands;
  FillChar(info, SizeOf(info), 0);
  process_command_line_args(info);
  init_global_layer_properties(info);
  init_instance_extension_names(info);
  init_device_extension_names(info);
  init_instance(info, 'Vulkan Sample');
  init_enumerate_device(info);
  init_window_size(info, 500, 500);
  init_connection(info);
  init_window(info);
  init_swapchain_extension(info);
  init_device(info);

  init_command_pool(info);
  init_command_buffer(info);
  execute_begin_command_buffer(info);
  init_device_queue(info);
  init_swap_chain(info);
  init_depth_buffer(info);
  init_uniform_buffer(info);
  init_descriptor_and_pipeline_layouts(info, false);
  init_renderpass(info, depthPresent = VK_TRUE);
  init_shaders(info, @Bin_vs, SizeOf(Bin_vs), @Bin_ps, SizeOf(Bin_ps));
  init_framebuffers(info, depthPresent = VK_TRUE);
  init_vertex_buffer(info, @g_vb_solid_face_colors_Data, sizeof(g_vb_solid_face_colors_Data), sizeof(g_vb_solid_face_colors_Data[0]), false);
  init_descriptor_pool(info, false);
  init_descriptor_set(info, false);
  init_pipeline_cache(info);
  init_pipeline(info, depthPresent);

  // VULKAN_KEY_START
  clear_values[0].color.float32[0] := 0.2;
  clear_values[0].color.float32[1] := 0.2;
  clear_values[0].color.float32[2] := 0.2;
  clear_values[0].color.float32[3] := 0.2;
  clear_values[1].depthStencil.depth := 1.0;
  clear_values[1].depthStencil.stencil := 0;

  imageAcquiredSemaphoreCreateInfo.sType := VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
  imageAcquiredSemaphoreCreateInfo.pNext := nil;
  imageAcquiredSemaphoreCreateInfo.flags := 0;

  res := vkCreateSemaphore(info.device, @imageAcquiredSemaphoreCreateInfo, nil, @imageAcquiredSemaphore);
  assert(res = VK_SUCCESS);

  // Get the index of the next available swapchain image:
  res := vkAcquireNextImageKHR(info.device, info.swap_chain, High(TVkUInt64){UINT64_MAX}, imageAcquiredSemaphore, VK_NULL_HANDLE, @info.current_buffer);
  // TODO: Deal with the VK_SUBOPTIMAL_KHR and VK_ERROR_OUT_OF_DATE_KHR
  // return codes
  assert(res = VK_SUCCESS);

  rp_begin.sType := VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
  rp_begin.pNext := nil;
  rp_begin.renderPass := info.render_pass;
  rp_begin.framebuffer := info.framebuffers[info.current_buffer];
  rp_begin.renderArea.offset.x := 0;
  rp_begin.renderArea.offset.y := 0;
  rp_begin.renderArea.extent.width := info.width;
  rp_begin.renderArea.extent.height := info.height;
  rp_begin.clearValueCount := 2;
  rp_begin.pClearValues := @clear_values;

  vkCmdBeginRenderPass(info.cmd, @rp_begin, VK_SUBPASS_CONTENTS_INLINE);

  vkCmdBindPipeline(info.cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, info.pipeline);
  vkCmdBindDescriptorSets(info.cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, info.pipeline_layout, 0, NUM_DESCRIPTOR_SETS, @info.desc_set[0], 0, nil);

  vkCmdBindVertexBuffers(info.cmd, 0, 1, @info.vertex_buffer.buf, @offsets);

  init_viewports(info);
  init_scissors(info);

  vkCmdDraw(info.cmd, 12 * 3, 1, 0, 0);
  vkCmdEndRenderPass(info.cmd);
  res := vkEndCommandBuffer(info.cmd);
  cmd_bufs[0] := info.cmd;

  fenceInfo.sType := VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
  fenceInfo.pNext := nil;
  fenceInfo.flags := 0;
  vkCreateFence(info.device, @fenceInfo, nil, @drawFence);

  pipe_stage_flags := TVkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
  FillChar(submit_info[0], SizeOf(submit_info[0]), 0);
  submit_info[0].pNext := nil;
  submit_info[0].sType := VK_STRUCTURE_TYPE_SUBMIT_INFO;
  submit_info[0].waitSemaphoreCount := 1;
  submit_info[0].pWaitSemaphores := @imageAcquiredSemaphore;
  submit_info[0].pWaitDstStageMask := @pipe_stage_flags;
  submit_info[0].commandBufferCount := 1;
  submit_info[0].pCommandBuffers := @cmd_bufs[0];
  submit_info[0].signalSemaphoreCount := 0;
  submit_info[0].pSignalSemaphores := nil;

  // Queue the command buffer for execution
  res := vkQueueSubmit(info.graphics_queue, 1, submit_info, drawFence);
  assert(res = VK_SUCCESS);

  // Now present the image in the window
  present.sType := VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
  present.pNext := nil;
  present.swapchainCount := 1;
  present.pSwapchains := @info.swap_chain;
  present.pImageIndices := @info.current_buffer;
  present.pWaitSemaphores := nil;
  present.waitSemaphoreCount := 0;
  present.pResults := nil;

  // Make sure command buffer is finished before presenting
  repeat
    res := vkWaitForFences(info.device, 1, @drawFence, VK_TRUE, FENCE_TIMEOUT);
  until (res <> VK_TIMEOUT);

  assert(res = VK_SUCCESS);
  res := vkQueuePresentKHR(info.present_queue, @present);
  assert(res = VK_SUCCESS);

  Sleep(5000);
  // VULKAN_KEY_END
  //if (info.save_images) write_ppm(info, '15-draw_cube');

  vkDestroySemaphore(info.device, imageAcquiredSemaphore, nil);
  vkDestroyFence(info.device, drawFence, nil);
  destroy_pipeline(info);
  destroy_pipeline_cache(info);
  destroy_descriptor_pool(info);
  destroy_vertex_buffer(info);
  destroy_framebuffers(info);
  destroy_shaders(info);
  destroy_renderpass(info);
  destroy_descriptor_and_pipeline_layouts(info);
  destroy_uniform_buffer(info);
  destroy_depth_buffer(info);
  destroy_swap_chain(info);
  destroy_command_buffer(info);
  destroy_command_pool(info);
  destroy_device(info);
  destroy_window(info);
  destroy_instance(info);
end;

begin
  Main;
end.

