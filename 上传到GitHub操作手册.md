# 上传到 GitHub 操作手册

本手册对应本目录已经创建好的本地 Git 仓库（分支 `main`，已完成首次提交）。下面每一步都可以直接复制执行。命令在 **PowerShell** 中运行，除非特别说明。

---

## 0. 当前状态

已经完成的事情：

| 项目 | 状态 |
|---|---|
| 本地仓库 | 已创建，分支 `main` |
| 首次提交 | 已完成，38 个文件 |
| 作者信息 | 已写入本仓库：`TaiChiyy <ytaichi369@gmail.com>` |
| `.gitignore` | 已排除 `results/`、`.matlab_prefs/`、`*.fig` 等 |
| `.gitattributes` | 已统一换行符并把二进制标记为 binary |

先确认一下：

```powershell
git log --oneline
git status
```

`git status` 应显示 `working tree clean`（或只有未跟踪的运行产物，那些会被忽略，不会出现在这里）。

---

## 1. 在 GitHub 上创建空仓库

1. 打开 https://github.com/new
2. **Repository name** 填一个名字，例如 `3D-Acoustics-Field-Calculate`
3. **Description** 可选，例如 `KRAKEN / KRAKENC / BELLHOP3D 计算浅海三维声场`
4. **公开性**：
   - `Public`：任何人可见。注意仓库内含第三方可执行文件，见第 6 节。
   - `Private`：仅自己可见。
5. **不要**勾选 `Add a README file`、`.gitignore`、`license` —— 本地已经有这些内容，勾了会造成两边历史不一致，首次推送会报冲突。
6. 点 `Create repository`。

创建后页面会给出仓库地址，形如：

```text
https://github.com/<你的用户名>/3D-Acoustics-Field-Calculate.git
```

---

## 2. 配置身份与凭据

### 2.1 作者身份

本仓库已经配置过。若想对所有仓库生效（推荐），再执行一次全局配置：

```powershell
git config --global user.name "TaiChiyy"
git config --global user.email "ytaichi369@gmail.com"
git config --global init.defaultBranch main
```

检查：

```powershell
git config --global --list
```

### 2.2 推送凭据：GitHub 不接受账号密码

从 2021 年起，`git push` 时**不能输入 GitHub 登录密码**。两种可用方式：

#### 方式 A：Personal Access Token（PAT，HTTPS，最快上手）

1. 打开 https://github.com/settings/tokens
2. `Generate new token` → 建议选 `Fine-grained token`
3. 权限：`Repository access` 选你要推送的仓库；`Permissions` → `Contents` 设为 `Read and write`
4. 生成后**立刻复制** token（页面只显示一次）
5. 首次 `git push` 时会弹出登录框：
   - `Username`：你的 GitHub 用户名
   - `Password`：**粘贴 token**，不是账号密码

Windows 上 Git 自带凭据管理器，会把 token 保存下来，后续推送不再询问。

#### 方式 B：SSH 密钥（一次配置，长期免登录）

```powershell
# 1) 生成密钥（一路回车即可，邮箱换成你的）
ssh-keygen -t ed25519 -C "ytaichi369@gmail.com"

# 2) 启动 ssh-agent 并加入私钥
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519

# 3) 打印公钥，整段复制
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

4. 打开 https://github.com/settings/keys → `New SSH key` → 粘贴公钥 → 保存
5. 测试：

```powershell
ssh -T git@github.com
```

看到 `Hi <用户名>! You've successfully authenticated` 即成功。

> 注意：`.ssh` 目录里的 `id_ed25519`（**没有** `.pub` 的那个）是私钥，永远不要提交或分享。

---

## 3. 关联远程仓库并推送

把下面的地址换成你自己的：

```powershell
git remote add origin https://github.com/<用户名>/<仓库名>.git
git remote -v
git push -u origin main
```

- `-u` 的作用：把本地 `main` 与远程 `origin/main` 绑定，之后直接 `git push` 即可。
- 用 SSH 方式的话，地址写成 `git@github.com:<用户名>/<仓库名>.git`。

推送成功后刷新 GitHub 页面，就能看到全部文件。

如果推送时报 `src refspec main does not match any`，说明本地分支名不是 `main`，执行：

```powershell
git branch -M main
git push -u origin main
```

---

## 4. 日常使用

```powershell
# 查看改动
git status
git diff

# 提交
git add -A
git commit -m "说明这次改了什么"

# 推送
git push
```

查看历史：

```powershell
git log --oneline --graph --decorate -20
```

只提交部分文件：

```powershell
git add run_3d_field.m private/f3_read_shd.m
git commit -m "修正 SHD 读取器的记录偏移"
```

---

## 5. 常见问题

| 现象 | 原因与处理 |
|---|---|
| `remote origin already exists` | 已有远程地址。改用 `git remote set-url origin <新地址>` |
| `failed to push some refs` / `rejected` | 远程已有本地没有的提交（例如建仓库时勾了 README）。先 `git pull --rebase origin main` 再 `git push` |
| 推送卡住或超时 | 文件太大。检查是否误提交了 `results/`、`*.fig`、`*.mat`：`git ls-files | Select-String -Pattern 'results/'` |
| 不想让某个已提交的文件继续被跟踪 | `git rm --cached <文件>`，并把规则写进 `.gitignore` |
| 提示 `dubious ownership` | 执行 `git config --global --add safe.directory <仓库路径>` |
| 推送后想撤销 | `git revert <commit>` 生成一个反向提交，比改历史安全 |
| 需要强制覆盖远程（危险） | `git push --force-with-lease`，仅在自己的分支上用 |

备份与迁移：整个仓库（含历史）就是 `.git` 目录，复制整个文件夹即可；也可以 `git clone <地址>` 到新机器。

---

## 6. 关于本仓库的三个重要提醒

### 6.1 不要上传 `.matlab_prefs/`

该目录里有 `matlabPkey.p12`、`thisMatlab.pem`，属于本机密钥/证书材料。`.gitignore` 已经排除它，且 `*.p12`、`*.pem` 也在排除规则内。如果哪天要改成公开仓库，先确认：

```powershell
git ls-files | Select-String -Pattern 'matlab_prefs|\.p12$|\.pem$'
```

**没有任何输出**才安全。若曾经提交过，需要清理历史，而不仅仅是删除文件。

### 6.2 仓库内含第三方可执行文件

`Kraken/kraken.exe`、`Kraken/field.exe`、`Krakenc/krakenc.exe`、`Krakenc/field.exe`、`Bellhop3D/bellhop3d.exe` 来自 Acoustics Toolbox，再分发需遵守其许可（见 `LICENSE.AcousticsToolbox`）。

- 改成 **Private** 仓库最稳妥。
- 保持 Public 的话，建议在 README 中写清来源、版本和许可，本目录 README 已包含来源说明与 SHA-256 校验值。
- 若不希望分发二进制，可执行 `git rm --cached Kraken/*.exe Krakenc/*.exe Bellhop3D/*.exe` 后提交，并在 `.gitignore` 中加入 `*.exe`。

### 6.3 结果数据不入库

`results/`、`latest_result.txt`、`validation/*.mat`、`*.fig` 都已忽略。这意味着：

- 别人 clone 后**看不到**你的历史运行结果，需要自己运行 `run_all_3d_fields()` 生成；
- 如果希望展示结果，建议只挑 1–2 张 `field_3d.png` / `model_comparison.png` 复制到 `docs/` 或 `figures/` 目录再提交，不要放开整个 `results/`；
- README 与 `RESULTS.md` 中引用的 `results/run_...` 路径只在你本机存在，别人复现时以自己新生成的目录为准（README 已加说明）。

---

## 7. 后续可选操作

```powershell
# 给当前提交打标签（例如发布一个版本）
git tag -a v1.0 -m "首个可复现版本"
git push origin v1.0

# 新建分支做实验，不影响 main
git switch -c feature/gaussian-beam
# ... 修改、提交 ...
git push -u origin feature/gaussian-beam   # 之后可在 GitHub 上发起 Pull Request
```

GitHub 上还建议做两件事：

1. 在仓库 `Settings` → `About` 填 Description 和 Topics（如 `ocean-acoustics`、`matlab`、`kraken`、`bellhop`）。
2. 如需引用信息，在仓库根目录加 `CITATION.cff`。
