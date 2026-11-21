import math
from pathlib import Path
from PIL import Image, ImageSequence


def gif_to_spritesheet(gif_path: Path, output_root: Path, columns: int = None):
    base_name = gif_path.stem
    # Tạo folder riêng theo tên từng file GIF: output_root/<tên_gif>/
    target_dir = output_root / base_name
    target_dir.mkdir(parents=True, exist_ok=True)

    with Image.open(gif_path) as im:
        frames = []
        durations = []

        for frame in ImageSequence.Iterator(im):
            frames.append(frame.convert("RGBA"))
            duration_ms = frame.info.get("duration", 100)
            if duration_ms <= 0:
                duration_ms = 100
            durations.append(duration_ms / 1000.0)

    total_frames = len(frames)
    if total_frames == 0:
        raise ValueError("File GIF không có frame nào.")

    frame_w, frame_h = frames[0].size
    if columns is None:
        columns = math.ceil(math.sqrt(total_frames))
    rows = math.ceil(total_frames / columns)

    sprite_sheet = Image.new("RGBA", (columns * frame_w, rows * frame_h), (0, 0, 0, 0))
    png_path = target_dir / f"{base_name}.png"
    txt_path = target_dir / f"{base_name}.txt"

    with open(txt_path, "w", encoding="utf-8") as f:
        f.write(f"# columns={columns},rows={rows},total={total_frames}\n")
        f.write("# index,x,y,width,height,duration_sec\n")

        for idx, (frame, dur) in enumerate(zip(frames, durations)):
            col = idx % columns
            row = idx // columns
            x = col * frame_w
            y = row * frame_h

            sprite_sheet.paste(frame, (x, y))
            f.write(f"{idx},{x},{y},{frame_w},{frame_h},{dur:.4f}\n")

    sprite_sheet.save(png_path, "PNG")


def batch_convert_gifs(input_dir: str, output_root: str = "output", columns: int = None):
    in_path = Path(input_dir)
    out_path = Path(output_root)

    if not in_path.exists():
        print(f"Không tìm thấy thư mục: {in_path}")
        return

    # Lấy tất cả file .gif (không phân biệt chữ hoa/thường)
    gif_files = [
        f for f in in_path.iterdir()
        if f.is_file() and f.suffix.lower() == ".gif"
    ]

    if not gif_files:
        print("Không tìm thấy file GIF nào trong thư mục đầu vào.")
        return

    print(f"Tìm thấy {len(gif_files)} file GIF. Bắt đầu xử lý...\n")
    success_count = 0

    for gif_file in gif_files:
        try:
            gif_to_spritesheet(gif_file, out_path, columns)
            print(f"[OK] {gif_file.name} -> {out_path / gif_file.stem}/")
            success_count += 1
        except Exception as e:
            # Bắt lỗi từng file để 1 file hỏng không làm dừng cả tiến trình
            print(f"[LỖI] {gif_file.name}: {e}")

    print(f"\nHoàn tất: {success_count}/{len(gif_files)} file thành công.")


if __name__ == "__main__":
    # Bỏ toàn bộ file .gif vào thư mục "input_gifs" ngang hàng với file .py rồi chạy
    batch_convert_gifs(input_dir="input_gifs", output_root="output")