return function(fn, viewport)
	return function()

		of.pushMatrix()
		of.scale(viewport.scale, viewport.scale)
		of.translate(viewport.position() * -1)

		fn(viewport.scale)

		of.popMatrix()
	end
end

