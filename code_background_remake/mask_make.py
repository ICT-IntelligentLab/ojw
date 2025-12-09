import os
import cv2
import numpy as np
from PIL import Image
from rembg import remove

# --------------------------------------------
# YOLO标签: (cx, cy, w, h) → (x1, y1, x2, y2)
# --------------------------------------------
def yolo_to_xyxy(label, img_w, img_h):
    cx, cy, w, h = label
    cx *= img_w
    cy *= img_h
    w *= img_w
    h *= img_h

    x1 = int(cx - w / 2)
    y1 = int(cy - h / 2)
    x2 = int(cx + w / 2)
    y2 = int(cy + h / 2)

    x1 = max(0, x1)
    y1 = max(0, y1)
    x2 = min(img_w - 1, x2)
    y2 = min(img_h - 1, y2)

    return x1, y1, x2, y2


# --------------------------------------------
# 使用 rembg 对裁剪图生成 mask
# --------------------------------------------
def rembg_segmentation(crop_bgr):
    # BGR → RGB → PIL
    crop_rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
    crop_pil = Image.fromarray(crop_rgb)

    # rembg 输出 RGBA 图
    out_png = remove(crop_pil)

    # 提取 alpha 通道作为 mask（白=前景）
    alpha = out_png.split()[-1]
    mask = alpha.point(lambda x: 255 if x > 0 else 0)

    return np.array(mask)


# --------------------------------------------
# 处理单张图像
# --------------------------------------------
def process_one_image(img_path, label_path, save_mask_path):

    img = cv2.imread(img_path)
    if img is None:
        print("读取失败:", img_path)
        return

    H, W = img.shape[:2]
    full_mask = np.zeros((H, W), dtype=np.uint8)

    # 读取 txt 标签
    if not os.path.exists(label_path):
        print("标签不存在，跳过:", img_path)
        return

    with open(label_path, "r") as f:
        lines = f.readlines()

    for line in lines:
        cls, cx, cy, bw, bh = map(float, line.split())

        # 如果你只处理 person（class 0）
        if int(cls) != 0:
            continue

        x1, y1, x2, y2 = yolo_to_xyxy((cx, cy, bw, bh), W, H)

        crop = img[y1:y2, x1:x2]

        # rembg 裁剪分割
        mask_small = rembg_segmentation(crop)

        # resize 回原 bbox region 大小
        mask_resized = cv2.resize(mask_small, (x2 - x1, y2 - y1))

        # 覆盖到大 mask
        full_mask[y1:y2, x1:x2] = mask_resized

    cv2.imwrite(save_mask_path, full_mask)
    print("完成:", save_mask_path)


# --------------------------------------------
# 批处理主函数
# --------------------------------------------
def batch_process():

    img_dir = "rescue/images"
    label_dir = "rescue/labels"
    mask_dir = "rescue/masks"

    os.makedirs(mask_dir, exist_ok=True)

    for filename in os.listdir(img_dir):
        if not filename.lower().endswith((".jpg", ".jpeg", ".png")):
            continue

        img_path = os.path.join(img_dir, filename)
        label_name = filename.rsplit(".", 1)[0] + ".txt"
        label_path = os.path.join(label_dir, label_name)

        save_mask_path = os.path.join(mask_dir, filename.rsplit(".", 1)[0] + "_mask.png")

        process_one_image(img_path, label_path, save_mask_path)

    print("\n全部完成！")


# ----------- 开始执行 -----------
batch_process()
