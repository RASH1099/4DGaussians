python - <<'PY'
import glob, os
from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

logdir = "/home/jiangzhenghan/project/4DGaussians/output/MeetingRoom/WhiteFoamCovers_thermal_down2x"  # 改成你的 Bacon_rgb_down2x 路径也行
event_files = glob.glob(os.path.join(logdir, "**", "events.out.tfevents.*"), recursive=True)

if not event_files:
    raise SystemExit("没找到 events.out.tfevents.* 文件")

min_t, max_t = None, None

for f in event_files:
    ea = EventAccumulator(f, size_guidance={
        "scalars": 0, "images": 0, "histograms": 0, "tensors": 0
    })
    ea.Reload()

    # 标量
    for tag in ea.Tags().get("scalars", []):
        for e in ea.Scalars(tag):
            t = e.wall_time
            min_t = t if min_t is None else min(min_t, t)
            max_t = t if max_t is None else max(max_t, t)

if min_t is None:
    raise SystemExit("events 里没找到标量记录（可能只写了别的类型或没写入成功）")

dur = max_t - min_t
h = int(dur // 3600)
m = int((dur % 3600) // 60)
s = int(dur % 60)

import datetime
print("start:", datetime.datetime.fromtimestamp(min_t))
print("end  :", datetime.datetime.fromtimestamp(max_t))
print(f"duration: {h}h {m}m {s}s")
PY
