from diffusers import StableDiffusionInpaintPipeline
from PIL import Image
import torch
import os

# 初始化 inpainting pipeline
pipe = StableDiffusionInpaintPipeline.from_pretrained(
    "runwayml/stable-diffusion-inpainting",
    torch_dtype=torch.float16
)
pipe = pipe.to("cuda")  # 如果有 GPU 就改为 "cuda"

pipe.safety_checker = lambda images, clip_input: (images, False)

# 文件夹路径
input_folder = "rescue/images"
mask_folder = "rescue/masks"  # mask 存放在 output 文件夹
output_folder = "output_inpaint_default"
os.makedirs(output_folder, exist_ok=True)

# 输出分辨率
height = 640
width = 640

# 遍历 input 文件夹下所有 .jpg 图片
for filename in sorted(os.listdir(input_folder)):
    if filename.lower().endswith(".jpg"):
        input_path = os.path.join(input_folder, filename)
        mask_name = os.path.splitext(filename)[0] + "_mask.png"
        mask_path = os.path.join(mask_folder, mask_name)

        # 检查 mask 是否存在
        if not os.path.exists(mask_path):
            print(f"Mask not found for {filename}, skipping.")
            continue

        try:
            image = Image.open(input_path).convert("RGB")
            mask = Image.open(mask_path).convert("RGB")
        except Exception as e:
            print(f"Error opening {filename} or its mask: {e}")
            continue

        # 执行 inpainting
        result = pipe(
            prompt="natural background, seamless, photorealistic",
            image=image,
            mask_image=mask,
            height=height,
            width=width,
            num_inference_steps=50,#default 50
            guidance_scale=7.5,#default 7.5
            strength=1,#default 1
        ).images[0]

        # 保存结果
        output_path = os.path.join(output_folder, filename)
        result.save(output_path)
        print(f"Saved inpainted image: {output_path}")
