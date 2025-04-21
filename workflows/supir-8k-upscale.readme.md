model:
- juggernaultXL_v9Rdphoto2Lightning (included)
- SUPIR-v0Q (included)
upcale_model:
- 4x_foolhardy_Remacri (included)
obs:
- Sampler: Choose "DPMPP2M" for more details, choose "EDM" to prevent excessive sharpening. The tile sampler  can give you a better result with longer time
- s_noise: If you want it to be more similar to the original image, lower it (for example, set it to 1 or 1.001); if you want to make the original image clearer, increase it (for example, set it to 1.01). Do not enter too large a value here!!!!
- ImpactInt: I set this value to 2000 to get a 2K resolution image in the first step, you can chage it.
- Tile Size/Tile Stride: If your video memory is small, you can halve these two values to 512 and 256
- Supir Conditioner: You can enter more precise prompt words to enhance the effect.
URL: https://openart.ai/workflows/seven947/1minute-8k-upscale/1IPTks1gL7v0EPmvsMcx
