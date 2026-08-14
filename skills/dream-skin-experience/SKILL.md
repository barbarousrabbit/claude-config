---
name: dream-skin-experience
description: Record what was just learned in this repository - a fault and its root cause, a measurement, a workaround, a rule that should bind future work. Use after fixing a non-obvious bug, after finishing a task that took more than one attempt, after any measurement, and whenever the user says 记录 / 记住 / remember / 写进经验. Also use when deciding where a piece of knowledge belongs.
---

# Recording experience

A fix that took two hours to find and five lines to apply is worth more written down than
applied. The expensive part was the diagnosis, and only writing preserves it.
一个花两小时找到、五行就能改完的修复，写下来比改掉更值钱。贵的是诊断过程，而只有写下来
才留得住它。

## Record when / 什么时候记

- A bug is fixed and the cause was not obvious from the symptom.
- Something was measured. Numbers decay from memory within a day and get re-guessed later.
- An approach failed for a reason worth not repeating — **failed attempts are content**,
  not noise. Three failed measurement approaches are why entry 21 exists.
  失败的尝试是内容，不是噪声。
- A rule was agreed with the user, or a decision was made that future work must respect.
- The user says 记录 / 记住 / remember.

Do not record: what the code already says, what git history already shows, or anything
that only mattered inside one conversation.
不要记：代码本身已经写明的、git 历史已经能查到的、只在一次对话里有意义的。

## Where it goes / 记到哪

The tier is decided by **who needs it**, not by who found it.
分层由**谁需要它**决定，而不是由谁发现它决定。

| Kind of knowledge | File |
|---|---|
| A rule everyone must follow, in any theme | `AGENTS.md` + `AGENTS.zh-CN.md` |
| How a Codex UI area is built, which selector owns it | `docs/skin-ui-map.md` + mirror |
| A fault: symptom, root cause, fix, regression check | `docs/skin-troubleshooting.md` + mirror |
| A decision true for one skin only | `themes/<theme>/NOTES.md` + mirror |
| What an asset is and where it came from | `themes/<theme>/ASSETS.md` + mirror |

The most common mistake is filing a theme-specific number as a general rule. A wash
alpha, a palette value, a focus point and a viewport baseline are all theme-specific:
they were measured against one design and mean nothing against another.
最常见的错误是把某个主题的数值当作通用规则记下来。洗淡 Alpha、调色板、焦点、视口基线
全都是主题专有的：它们是针对一套设计测出来的，换一套就没有意义。

## Shape of a fault entry / 故障条目的形状

Append to `docs/skin-troubleshooting.md` as the next number, with these subheadings:

```text
## N. One line naming the symptom as the user would describe it

### Symptom
### What actually happened
### Current fix
### Regression checks
```

Write what was actually observed, with the real numbers and the real error text. A
paraphrased error message cannot be searched for by the next person who hits it.
写实际观察到的东西，用真实数值和真实报错原文。被转述过的报错，下一个撞上它的人搜不到。

## Non-negotiable when writing / 写的时候不能省的

1. **English file first, then carry it to `.zh-CN.md`.** The English one is the source of
   truth. Same headings, same order, same tables, same code blocks.
   先写英文，再带到 `.zh-CN.md`。英文是真相源，标题、顺序、表格、代码块都要一致。
2. **A ```text block is reproduced byte-for-byte** in both files, never translated.
   Error messages and commands are payloads, not prose.
3. **Run the gate**, every time:

   ```powershell
   python scripts\check-translations.py
   ```

   It fails on a divergent heading tree, a differing code-block or table count, or an
   edited verbatim block. Exit code 1 means the pair is broken — fix it now, not later.

4. Numbers carry their source. `29 ms` alone is folklore; `29 ms, measured by toggling
   document.adoptedStyleSheets, two runs` is evidence.
   数字要带来源。孤零零的 `29 ms` 是传说；`29 ms，切换 document.adoptedStyleSheets 实测两轮`
   才是证据。

## Then commit it / 然后提交

Experience that stays in the working tree is lost when the machine changes. Push it with
the change it came from, not "later".
留在工作区里的经验会随着换机器而消失。跟着产生它的那次改动一起推上去，不要「回头再说」。
