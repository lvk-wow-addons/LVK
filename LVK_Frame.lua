local frame = CreateFrame("Frame")

function frame:OnUpdate(sinceLastUpdate)
    LVK:AdvanceTimer(sinceLastUpdate)
end
frame:SetScript("OnUpdate", frame.OnUpdate)