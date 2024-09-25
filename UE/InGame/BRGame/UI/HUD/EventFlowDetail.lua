--
-- 战斗界面 - 事件流水(击杀/治疗/复活)
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.12
--

local EventFlowDetail = Class("Common.Framework.UserWidget")
local testProfile = require("Common.Utils.InsightProfile")

local Collapsed = UE.ESlateVisibility.Collapsed
local SelfHitTestInvisible = UE.ESlateVisibility.SelfHitTestInvisible

-------------------------------------------- Init/Destroy ------------------------------------
function EventFlowDetail:OnInit()
    self.DefaultTextureNone = self.ImgSource0.Brush.ResourceObject

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.IfPlayAnimation = false
	UserWidget.OnInit(self)
end

function EventFlowDetail:OnDestroy()
	UserWidget.OnDestroy(self)
end
-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------
function EventFlowDetail:InitDetailData(InFlowData)
    print("EventFlowDetail:InitDetailData")
    testProfile.Begin("EventFlowDetail:InitDetailData")
    -- 名字信息
    local TargetName = InFlowData.CauseName
    if not InFlowData.CauseName or InFlowData.CauseName == "" then -- 无攻击者昵称时需要用配置表里的 描述信息
        local GameplayTags = UE.UBlueprintGameplayTagLibrary.BreakGameplayTagContainer(InFlowData.Tags)
        for i = 0, GameplayTags:Length() do
            local TagName = UE.UBlueprintGameplayTagLibrary.GetDebugStringFromGameplayTag(GameplayTags:GetRef(i))
            local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.EventFlowCfg, TagName)
            if cfg and cfg.DetailDesc then
                TargetName = cfg.DetailDesc
            end
        end
    end
    testProfile.End("EventFlowDetail:InitDetailData")
    self.bIfSelfDamage = InFlowData.PlayerId == InFlowData.ReceiverPlayerId or -1 == InFlowData.PlayerId
    self.Type = InFlowData.Type
    self.Cause_Bg_Color = self:GetTargetColor(InFlowData.CauserTeamId,InFlowData.CauserTeamIndex)
    self.Receive_Bg_Color = self:GetTargetColor(InFlowData.ReceiverTeamId,InFlowData.ReceiverTeamIndex)
    self.CauseIsTeam = self.Cause_Bg_Color ~= UIHelper.LinearColor.White
    self.ReceiveIsTeam = self.Cause_Bg_Color ~= UIHelper.LinearColor.White
    self:UpdateText(self.TxtCaster,TargetName, self.Cause_Bg_Color, true)
    self:UpdateText(self.TxtInjurers,InFlowData.ReceiverName, self.Receive_Bg_Color)


    -- 设置结果
    self:UpdateResultImage(InFlowData.bDying,InFlowData.bKilled)

    -- 穿透(烟/墙...) / 击中部位
    local Tags =InFlowData.Tags
    self:UpdateImage(self.ImgThrough, self.ThroughTexture,Tags)
    self:UpdateImage(self.ImgPart, self.PartTexture,Tags)


    self:UpdateImgBg_TeamKill()

    -- 来源信息(枪/技能/投掷物...)
    self:UpdateSourceInfo(Tags,InFlowData.ItemId)

    -- 设置角色头像
    self:UpdataAvatarByHeroId(self.BP_AvatarCaster.ImgAvatar, InFlowData.CauserHeroId)
    self:UpdataAvatarByHeroId(self.BP_AvatarInjurers.ImgAvatar, InFlowData.ReceiverHeroId)
    
    -- 设置自杀UI折叠
    self:HideSelfDemageUI()

    self:SetRenderOpacity(1)
    self:SetVisibility(SelfHitTestInvisible)

    if self.Root then
        local DistTextDir = UE.FVector2D(0)
        self.Root:SetRenderTranslation(DistTextDir)
    end

    -- 进场动画
    if self.CauseIsTeam then
        self:VXE_HUD_EventFlowdetail_Ourside_In()
    else
        self:VXE_HUD_EventFlowdetail_Enemy_In()
    end
    local OffSetPos = self.Slot:GetPosition()
    --print("EventFlowDetail >> InitDetailData OffSetPos:", OffSetPos, "InFlowData.Type:", InFlowData.Type, GetObjectName(self))
end

function EventFlowDetail:UpdateImgBg_TeamKill()
    if self.ImgBg_TeamKill then
        if self.CauseIsTeam then
            self.ImgBg_TeamKill:SetColorAndOpacity(self.Cause_Bg_Color)
            self.ImgBg_TeamKill:SetVisibility(SelfHitTestInvisible)
        else
            self.ImgBg_TeamKill:SetVisibility(Collapsed)
        end
    end

    -- if self.ImgBg_TeamKill then
    --     if self.ReceiveIsTeam then
    --         self.ImgBg_TeamKill:SetColorAndOpacity(self.Receive_Bg_Color)
    --         self.ImgBg_TeamKill:SetVisibility(SelfHitTestInvisible)
    --     else
    --         self.ImgBg_TeamKill:SetVisibility(Collapsed)
    --    end
    -- end

end

function EventFlowDetail:UpdateDetailData(InFlowData, IndexNum)

    -- 下移动画
    if self.Root then
        local DistTextDir = UE.FVector2D(0)
        self.Root:SetRenderTranslation(DistTextDir)
    end

    self:VXE_HUD_EventFlowdetail_Down_Position()
    local OffSetPos = self.Slot:GetPosition()
    local OffSetY = self.Slot:GetSize().Y
    self.IndexNum = IndexNum
    OffSetPos.Y = OffSetY * IndexNum

    --self.Slot:SetPosition(OffSetPos)

    --print("EventFlowDetail >> UpdateDetailData OffSetPos:", OffSetPos, "InFlowData.Type:", InFlowData.Type, GetObjectName(self))
end

-- 设置流水的来源信息
function EventFlowDetail:UpdateSourceInfo(Tags,ItemId)
    -- 武器
    self.ImgSource0:SetVisibility(Collapsed)
    if ItemId and ItemId > 0 then
        local ItemSubTable = BattleUIHelper.SetImageTexture_ItemId(self.ImgSource0, ItemId, "FlowImage", self.DefaultTextureNone)
        self.ImgSource0:SetVisibility(ItemSubTable and SelfHitTestInvisible or Collapsed)
    end

    -- 其他直接读配置
    local GameplayTags = UE.UBlueprintGameplayTagLibrary.BreakGameplayTagContainer(Tags)
    self.ImgSource1:SetVisibility(Collapsed)
    for i = 1, GameplayTags:Length() do
        local TmpTag = GameplayTags:GetRef(i)
        local TagName = UE.UBlueprintGameplayTagLibrary.GetDebugStringFromGameplayTag(TmpTag)
        local cfg = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.EventFlowCfg, TagName)
        if cfg then
            self.ImgSource1:SetBrushFromSoftTexture(cfg.IconTexture, false)
            self.ImgSource1:SetVisibility(SelfHitTestInvisible)
        end
    end

    return false
end

function EventFlowDetail:UpdateText(TargetText,Str,Color)
    TargetText:SetText(Str)
    TargetText:SetColorAndOpacity(UIHelper.ToSlateColor_LC(Color))
end

function EventFlowDetail:OnAnimationFinished(Animation)
    if Animation == self.vx_eventflowdetail_ourside_in or  Animation == self.vx_eventflowdetail_ourside_out or Animation == self.vx_eventflowdetail_enemy_in
        or Animation == self.vx_eventflowdetail_enemy_out or Animation == self.vx_eventflowdetail_position or Animation == self.vx_eventflowdetail_position1 then
        self.IfPlayAnimation = false
        if self.Root then
            local DistTextDir = UE.FVector2D(0)
            self.Root:SetRenderTranslation(DistTextDir)
        end

        if Animation == self.vx_eventflowdetail_position1 or Animation == self.vx_eventflowdetail_position then
            local OffSetPos = self.Slot:GetPosition()
            local OffSetY = self.Slot:GetSize().Y
            OffSetPos.Y = OffSetY * self.IndexNum

            --print("EventFlowDetail >> OnAnimationFinished OffSetPos:", OffSetPos, GetObjectName(self))
            self.Slot:SetPosition(OffSetPos)
        elseif Animation == self.vx_eventflowdetail_enemy_out or Animation == self.vx_eventflowdetail_ourside_out then
            self:SetVisibility(Collapsed)
        end
    end
end

function EventFlowDetail:OnAnimationStarted(Animation)

    if Animation == self.vx_eventflowdetail_ourside_in or  Animation == self.vx_eventflowdetail_ourside_out or Animation == self.vx_eventflowdetail_enemy_in
    or Animation == self.vx_eventflowdetail_enemy_out or Animation == self.vx_eventflowdetail_position then
        self.IfPlayAnimation = true
        if self.Root then
            local DistTextDir = UE.FVector2D(0)
            self.Root:SetRenderTranslation(DistTextDir)
        end
    end
end
-- 出场动画
function EventFlowDetail:HideDetailData()

    if self.Root then
        local DistTextDir = UE.FVector2D(0)
        self.Root:SetRenderTranslation(DistTextDir)
    end
    --self:SetVisibility(Collapsed)
    if self.CauseIsTeam then
        self:VXE_HUD_EventFlowdetail_Ourside_Out()
    else
        self:VXE_HUD_EventFlowdetail_Enemy_Out()
    end
end

function EventFlowDetail:HideSelfDemageUI()
    if self.bIfSelfDamage then
        self.TxtInjurers:SetVisibility(Collapsed)
        self.BP_AvatarInjurers:SetVisibility(Collapsed)
    else
        self.TxtInjurers:SetVisibility(SelfHitTestInvisible)
        self.BP_AvatarInjurers:SetVisibility(SelfHitTestInvisible)
    end
end

function EventFlowDetail:UpdataAvatarByHeroId(ImgAvatar, HeroId)
    local PawnConfig = UE.FGePawnConfig()
    local bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(HeroId,PawnConfig,self)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
        ImgAvatar:SetVisibility(SelfHitTestInvisible)
        print("EventFlowDetail >> UpdataAvatar SelfHitTestInvisible HeroId:", HeroId, GetObjectName(self), PawnConfig.Name,PawnConfig.Icon)
    else
        print("EventFlowDetail >> UpdataAvatar Collapsed HeroId:", HeroId, GetObjectName(self),PawnConfig.Name,PawnConfig.Icon)
        ImgAvatar:SetVisibility(Collapsed)
    end
    
end

function EventFlowDetail:UpdataAvatarByPawn(ImgAvatar, Pawn)
-- 设置玩家基础数据
    local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(Pawn)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        --local SlateBrushAsset = UE.UKismetSystemLibrary.LoadAsset_Blocking(PawnConfig.Icon)
        --self.ImgAvatar:SetBrushFromAsset(SlateBrushAsset)
        ImgAvatar:SetVisibility(SelfHitTestInvisible)
        ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
        print("EventFlowDetail >> UpdataAvatarByPawn, ", GetObjectName(self), GetObjectName(Pawn), PawnConfig.Name,PawnConfig.Icon)
    else
        ImgAvatar:SetVisibility(Collapsed)
    end
end

function EventFlowDetail:UpdateImage(InImageWidget, InConfigTexture,Tags)
    local AllConfigTags = InConfigTexture:Keys()
    local CurConfigTag = nil
    for i = 1, AllConfigTags:Length() do
        local TmpTag = AllConfigTags:GetRef(i)
        if UE.UBlueprintGameplayTagLibrary.MatchesAnyTags(TmpTag, Tags, true) then
            CurConfigTag = TmpTag
        end
    end

    local ConfigTexture = InConfigTexture:FindRef(CurConfigTag)
    if ConfigTexture then
        InImageWidget:SetBrushFromSoftTexture(ConfigTexture, false)
    end

    InImageWidget:SetVisibility(ConfigTexture and SelfHitTestInvisible or Collapsed)
end

-- 更新 result icon
function EventFlowDetail:UpdateResultImage(bDying, bKilled)
    local ResultIndex = bDying and 1 or (bKilled and 2 or 3)
    local ResultTexture = self.DyingDeadTexture:Get(ResultIndex)
    if ResultTexture then
        self.ImgResult:SetBrushFromSoftTexture(ResultTexture, false)
    end
    self.ImgResult:SetVisibility(ResultTexture and SelfHitTestInvisible or Collapsed)
end

function EventFlowDetail:GetTargetColor(TargetTeamId,TargetTeamIndex)
    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PC or not PC.PlayerState then
        return UIHelper.LinearColor.White
    end
    local SelfTeamId = PC.PlayerState:GetTeamInfo_Id()
    return SelfTeamId == TargetTeamId and MinimapHelper.GetTeamMemberColor(TargetTeamIndex) or UIHelper.LinearColor.White
end
-------------------------------------------- Callable ------------------------------------

return EventFlowDetail