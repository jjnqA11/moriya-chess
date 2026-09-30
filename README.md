# 🎲 Mệnh Cờ

> Game chiến thuật bàn cờ 2 người được phát triển bằng **Godot Engine** và **GDScript**.
> Điểm đặc trưng của Mệnh Cờ là **người tung xúc xắc không sử dụng số điểm mình vừa tung**, mà số điểm đó sẽ trở thành số ô di chuyển cho **đối thủ**.

---

## 📌 Thông tin dự án

* **Tên:** Mệnh Cờ
* **Engine:** Godot Engine
* **Ngôn ngữ:** GDScript
* **Thể loại:** Game chiến thuật bàn cờ
* **Chế độ:** PvE và Local 2 Players
* **Nền tảng:** PC
* **Phiên bản:** **v2.1**

---

# 🆕 Mệnh Cờ v2.1

Phiên bản 2.1 là phiên bản tái cấu trúc và tiếp tục phát triển dự án sau khi project cũ gặp vấn đề về cấu hình.

Bản 2.1 tập trung vào việc hoàn thiện **core gameplay**, hệ thống **quân cờ**, **xúc xắc**, **quân dự bị**, cùng các phản hồi trực quan khi người chơi thao tác.

Mục tiêu của phiên bản này là tạo ra một nền tảng gameplay ổn định trước khi tiếp tục hoàn thiện AI, UI/UX và các thành phần trình bày của game.

---

## ♟️ Bàn cờ

* Sử dụng duy nhất một bàn cờ **6 × 8**.
* Loại bỏ các biến thể bàn cờ khác để giảm phạm vi dự án.
* Các quân cờ được quản lý bằng hệ thống vị trí trên bàn cờ.
* Có kiểm tra vị trí hợp lệ.
* Có kiểm tra ô trống và quân địch.
* Có hệ thống xác định các nước đi hợp lệ.
* Hỗ trợ chọn quân và hiển thị các ô có thể di chuyển.

---

# 🎲 Cơ chế xúc xắc

Đây là cơ chế đặc trưng của Mệnh Cờ.

### Một lượt chơi

Mỗi lượt kéo dài **40 giây**:

```text
⏱️ 30 giây
   ↓
Suy nghĩ và thực hiện nước đi

🎲 10 giây
   ↓
Tung xúc xắc

➡️ Điểm xúc xắc được trao cho đối thủ
```

Người chơi **không sử dụng số điểm mà mình vừa tung**.

Ví dụ:

```text
Người chơi A tung 🎲 = 5

→ Người chơi A không nhận 5 điểm

→ Người chơi B nhận 5 điểm
→ Người chơi B được sử dụng 5 điểm để di chuyển
```

Cơ chế này khiến việc tung xúc xắc vừa là hành động kết thúc lượt, vừa ảnh hưởng trực tiếp đến nước đi tiếp theo của đối thủ.

---

## 🤖 PvE

Khi chơi với Bot:

* Bot sẽ tung xúc xắc trước.
* Số điểm Bot tung được sẽ trở thành số điểm di chuyển của người chơi.
* Người chơi sử dụng số điểm đó để thực hiện lượt của mình.
* Sau khi người chơi kết thúc lượt, hệ thống tiếp tục chuyển sang lượt của Bot.

Phiên bản 2.1 đã có **Bot Easy** để kiểm tra gameplay PvE.

Bot Easy hiện chủ yếu phục vụ mục đích kiểm thử core gameplay và chưa hướng tới mức độ thông minh cao.

---

# 👥 Local 2 Players

Mệnh Cờ hỗ trợ:

> **2 người chơi trên cùng một máy tính.**

Người chơi có thể lựa chọn ai là người đi trước.

Sau khi xác định người đi trước:

* Người chơi đầu tiên thực hiện lượt.
* Cuối lượt người chơi đó tung xúc xắc.
* Điểm xúc xắc được chuyển cho đối thủ.
* Đối thủ sử dụng số điểm đó trong lượt tiếp theo.

Không sử dụng:

* ❌ Online multiplayer
* ❌ Server
* ❌ Database
* ❌ Tài khoản
* ❌ Hệ thống mạng

---

# 🔄 Quân dự bị — Reserve

Mệnh Cờ có hệ thống **quân dự bị** nằm ngoài bàn cờ.

Người chơi có thể sử dụng cơ chế **Swap** để thay đổi quân đang có trên bàn với quân dự bị theo luật của game.

### Quy tắc Swap

* Mỗi lượt chỉ được **Swap 1 lần**.
* Khi Swap, **toàn bộ số điểm xúc xắc hiện có sẽ được sử dụng**.
* Ví dụ:

```text
🎲 Có 6 điểm
       ↓
     Swap
       ↓
🎲 Còn 0 điểm
```

Swap không tiêu tốn 1 điểm rồi giữ lại số điểm còn lại.

---

## 🔒 Giới hạn Swap

Mỗi lượt chỉ được thay quân dự bị **một lần**.

Sau khi đã Swap:

```text
❌ Không thể Swap lần thứ hai
```

Nếu cố thực hiện lần thứ hai, hệ thống hiển thị thông báo:

> ❌ Đã thay quân dự bị trong lượt này!

Quyền Swap sẽ được reset khi chuyển sang lượt mới.

---

## 🔁 Hướng Swap

Hệ thống hỗ trợ:

```text
Reserve → Board
Board → Reserve
```

Khi quân dự bị đã được sử dụng:

* Quân dự bị tương ứng được ẩn/khóa.
* Quân cũ được xử lý khỏi vị trí cũ theo luật Swap.
* Hệ thống cập nhật lại trạng thái quân trên bàn.

---

# 🖱️ Chọn quân & phản hồi trực quan

Phiên bản 2.1 đã phát triển hệ thống chọn quân nhằm giúp người chơi dễ nhận biết quân nào đang được thao tác.

Các chức năng gồm:

* Chọn quân trên bàn.
* Hiển thị trạng thái quân đang được chọn.
* Hiển thị các ô có thể di chuyển.
* Khi chọn quân khác, highlight cũ được xóa.
* Highlight quân dự bị được lọc dựa trên quân đang được chọn.
* Xử lý trạng thái chọn khi Swap không hợp lệ.
* Hủy trạng thái chọn/đánh dấu khi thao tác không thể thực hiện.

Mục tiêu là giảm tình trạng highlight cũ còn tồn tại sau khi người chơi thay đổi lựa chọn.

---

# ⭐ Điều kiện chiến thắng

Mục tiêu chính của người chơi là bắt quân **5 sao — Leader/Core (quân Mệnh)** của đối phương.

```text
⭐️⭐️⭐️⭐️⭐️
      ↓
   Quân Mệnh
      ↓
   Bị bắt = Thắng
```

Do đó, không nhất thiết phải tiêu diệt toàn bộ quân của đối phương.

---

# 🎨 UI / UX

UI/UX được xác định là một phần quan trọng của phiên bản phát triển hiện tại.

Các thành phần cần hướng tới:

* Giao diện bàn cờ.
* Hiển thị lượt chơi.
* Hiển thị thời gian.
* Hiển thị điểm xúc xắc.
* Hiển thị quân dự bị.
* Phản hồi khi chọn quân.
* Highlight nước đi.
* Thông báo hành động không hợp lệ.
* Hiệu ứng chuyển lượt.
* Animation.
* Hiệu ứng xúc xắc.

Phần UI được thiết kế tách biệt tương đối với core gameplay để thuận tiện cho việc phát triển song song.

---

# 🔊 Âm thanh

Dự án định hướng bổ sung:

* 🎵 Nhạc nền.
* 🔊 Hiệu ứng di chuyển quân.
* 🎲 Hiệu ứng tung xúc xắc.
* ⚔️ Hiệu ứng bắt quân.
* 🔄 Hiệu ứng Swap.
* 🏆 Âm thanh khi chiến thắng.

Âm thanh được sử dụng để tăng phản hồi cho các hành động của người chơi.

---

# 🧠 AI

Phiên bản 2.1 đã có nền tảng PvE và **Bot Easy** để kiểm thử.

Bot Easy hiện được sử dụng chủ yếu để:

* Kiểm tra lượt chơi.
* Kiểm tra luật di chuyển.
* Kiểm tra bắt quân.
* Kiểm tra điều kiện thắng.
* Kiểm tra cơ chế xúc xắc.
* Kiểm tra tương tác giữa Bot và người chơi.

AI có độ khó cao hơn, chẳng hạn **Medium**, sẽ được phát triển sau khi core gameplay ổn định.

---

# ❌ Những tính năng đã loại khỏi phạm vi

Để giữ phạm vi dự án phù hợp với thời gian phát triển, các thành phần sau **không còn nằm trong scope hiện tại**:

* ❌ Fusion
* ❌ Nhiều biến thể bàn cờ
* ❌ Nhiều layout/bản đồ khác nhau
* ❌ Online multiplayer
* ❌ Server
* ❌ Database
* ❌ Hệ thống tài khoản
* ❌ Các cơ chế phụ không cần thiết

Dự án tập trung vào một trải nghiệm bàn cờ duy nhất thay vì mở rộng quá nhiều tính năng.

---

# 🛠️ Công nghệ

| Thành phần           | Công nghệ             |
| -------------------- | --------------------- |
| Game Engine          | Godot Engine          |
| Ngôn ngữ             | GDScript              |
| Phiên bản phát triển | v2.1                  |
| Chế độ chơi          | PvE / Local 2 Players |
| Bàn cờ               | 6 × 8                 |
| Multiplayer          | Local                 |
| Network              | Không sử dụng         |

---

# 📂 Định hướng cấu trúc project

Project được tổ chức theo hướng tách các thành phần để thuận tiện cho việc phát triển và tích hợp:

```text
MoriyaChess/
├── scenes/
├── scripts/
├── assets/
│   ├── sprites/
│   ├── sounds/
│   └── music/
├── ui/
└── project.godot
```

Cấu trúc thực tế có thể tiếp tục thay đổi trong quá trình phát triển.

---

# 📜 Lịch sử phiên bản

## v2.1 — Core Gameplay Development

### Gameplay

* [x] Bàn cờ 6 × 8
* [x] Hệ thống quân cờ
* [x] Di chuyển quân
* [x] Bắt quân
* [x] Điều kiện thắng bằng quân 5 sao
* [x] Hệ thống lượt
* [x] Hệ thống xúc xắc
* [x] Điểm xúc xắc được chuyển cho đối thủ
* [x] Local 2 Players
* [x] PvE
* [x] Bot Easy

### Reserve

* [x] Quân dự bị
* [x] Reserve → Board
* [x] Board → Reserve
* [x] Giới hạn 1 Swap/lượt
* [x] Swap sử dụng toàn bộ điểm xúc xắc
* [x] Khóa quân dự bị đã sử dụng
* [x] Reset giới hạn Swap khi sang lượt mới

### UX

* [x] Chọn quân
* [x] Highlight nước đi
* [x] Xóa highlight cũ khi chọn quân khác
* [x] Highlight quân dự bị theo quân đang chọn
* [x] Xử lý trạng thái chọn khi Swap không hợp lệ
* [x] Thông báo hành động không hợp lệ

### Định hướng tiếp theo

* [ ] Bot Medium
* [ ] Hoàn thiện UI/UX
* [ ] Animation
* [ ] Sound Effect
* [ ] Background Music
* [ ] Hoàn thiện trải nghiệm Local 2 Players
* [ ] Kiểm thử và sửa lỗi

---

# 🎯 Mục tiêu của Mệnh Cờ

Mệnh Cờ hướng tới một game bàn cờ có luật chơi tương đối đơn giản nhưng tạo ra quyết định chiến thuật thông qua một cơ chế đặc biệt:

> **Bạn tung xúc xắc để quyết định đối thủ được đi bao nhiêu.**

Người chơi không chỉ phải suy nghĩ về nước đi hiện tại mà còn phải cân nhắc:

* Mình sẽ trao bao nhiêu điểm di chuyển cho đối thủ?
* Đối thủ có thể tận dụng số điểm đó như thế nào?
* Có nên sử dụng Swap?
* Quân Mệnh của đối phương đang ở đâu?
* Làm thế nào để bảo vệ quân Mệnh của mình?

---

## 📌 Trạng thái

**Current Version: `v2.1`**

> Phiên bản 2.1 tập trung vào việc xây dựng và kiểm thử core gameplay.
> Các thành phần UI/UX, AI và âm thanh tiếp tục được hoàn thiện trong các phiên bản tiếp theo.
