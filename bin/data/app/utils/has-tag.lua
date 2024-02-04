local includes = require('utils.functional').includes

return function(tag, x)
	local tags = x.params.tags
	return (tags and includes(tag, tags))
end
