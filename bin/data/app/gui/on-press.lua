local renderer = require('gui.renderer')
local pd = require('pd')

return function(btn)
	if not renderer.patch then
		return
	end

	local patchId = renderer.patch.id

	if btn.id == 'save' then
		local patchId = renderer.patch.id
		print("patchId: " .. patchId)
		pd.queue(patchId, 'menusave')
	elseif btn.id == 'edit' then
		pd.queue(patchId, 'editmode', (btn.on and '1' or '0'))
	elseif (btn.id == 'redo' or btn.id == 'undo' or btn.id == 'copy' or btn.id == 'paste') then
		pd.queue(patchId, btn.id)
	elseif btn.id == 'clear' then
		pd.delete(patchId)
	end
end
