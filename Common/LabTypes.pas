unit LabTypes;

interface

uses
  Vulkan;

type
  TLabClass = class (TInterfacedObject)
  protected
    class var _VulkanPtr: ^TVulkan;
    class var _VulkanInstance: TVkInstance;
  public
    class constructor CreateClass;
    class function Vulkan: TVulkan;// inline;
    class function VulkanInstance: TVkInstance;// inline;
  end;

implementation

//TLabClass BEGIN
class constructor TLabClass.CreateClass;
begin
  _VulkanPtr := @vk;
  _VulkanInstance := 0;
end;

class function TLabClass.Vulkan: TVulkan;
begin
  Result := _VulkanPtr^;
end;

class function TLabClass.VulkanInstance: TVkInstance;
begin
  Result := _VulkanInstance;
end;
//TLabClass END

end.
