---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Admin.
--- DateTime: 2023/10/13 19:02
---


local ES_EnhanceSuccessTips = Class("Common.Framework.UserWidget")


local function GetInt(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsIntSimple(BlackBoard,Key)
    return Value
end

local function GetString(BlackBoard, Key)
    local Value,Result =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(BlackBoard,Key)
    return Value
end




function ES_EnhanceSuccessTips:OnTipsInitialize(TipsText, TipsBrush, NewCountDownTime, Blackboard, Owner)
    local ItemId = GetInt(Blackboard, "ItemId")

    -- 物品图标
    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, ItemId, "ItemIcon",
        GameDefine.NItemSubTable.Ingame, "ES_EnhanceSuccessTips:OnTipsInitialize")
    if IsExistIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self.Image_Item:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
    end

    -- 物品等级
    local ItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, ItemId, "ItemLevel",
        GameDefine.NItemSubTable.Ingame, "ES_EnhanceSuccessTips:OnTipsInitialize")
    if IsFindItemLevel then
        local BgTex2D = self.EquipmentLvBgArr:Get(ItemLevel)
        if BgTex2D then
            self.Image_BG:SetBrushFromSoftTexture(BgTex2D, false)
        end
    end

    -- 如果是头包甲需要展示等级
    local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(self, ItemId, "ItemType",
        GameDefine.NItemSubTable.Ingame, "ES_EnhanceSuccessTips:OnTipsInitialize")
        
    if IsFindTempItemType then
        local CurrentItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, ItemId, "ItemLevel",
            GameDefine.NItemSubTable.Ingame, "ES_EnhanceSuccessTips:OnTipsInitialize")
        local PickupSetting = UE.UPickupManager.GetGPSSeting(self)

        if IsFindItemLevel and PickupSetting then
            local EnhanceId = GetString(Blackboard, "EnhanceAttributeId")
            local EnhanceData = UE.UEnhancementSettings.GetAttributeDataById(self, EnhanceId)
            if EnhanceData then
                    self.EnhanceName:SetText(EnhanceData.EnhanceName)
                    self.Size_Perk:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(EnhanceData
                    .EnhanceIconSoft)
                    if EnhanceIconSoftPtr then
                        self.ImgIcon_Perk:SetBrushFromSoftTexture(EnhanceIconSoftPtr)
                    end
    
                    local EnhanceIBgSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(EnhanceData.EnhanceBgSoft)
                    if EnhanceIBgSoftPtr then
                        self.ImgBG_Perk:SetBrushFromSoftTexture(EnhanceIBgSoftPtr)
                    end
                -- end

            end

        end
    end
end

return ES_EnhanceSuccessTips
