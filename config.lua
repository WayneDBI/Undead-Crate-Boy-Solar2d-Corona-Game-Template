--calculate the aspect ratio of the device:
local aspectRatio = display.pixelHeight / display.pixelWidth

application = {
   content = {
      width = aspectRatio > 1.5 and 320 or math.floor( 480 / aspectRatio ),
      height = aspectRatio < 1.5 and 480 or math.floor( 320 * aspectRatio ),
      scale = "letterBox",
      fps = 60,

      imageSuffix = {
         ["@2x"] = 1.3,
         ["@4x"] = 3.0,
      },
   },
}