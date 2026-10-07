# work-rules

Claude Code で業務を進めるときの規則をまとめたスキル集である。Claude Code のプラグインのマーケットプレイスとして配布する。

## 入れ方

Claude Code の会話の中で、次の2つを順に実行する。

```
/plugin marketplace add yuu0706/claude-skills
/plugin install work-rules@yuu0706-skills
```

シェルから入れる場合は次のとおり。

```sh
claude plugin marketplace add yuu0706/claude-skills
claude plugin install work-rules@yuu0706-skills
```

入れた後に新しい会話を始めると、スキルが読み込まれる。スキルの名前には `work-rules:` が付く（例: `work-rules:doc-writing`）。

## 更新の受け取り方

自動更新は既定で無効である。次のどちらかで受け取る。

- 自動更新を有効にする: 会話の中で `/plugin` を開き、**Marketplaces** で `yuu0706-skills` を選び、**Enable auto-update** を選ぶ。
- 手動で更新する: 会話の中で `/plugin marketplace update yuu0706-skills` を実行する。シェルからは `claude plugin update work-rules@yuu0706-skills` を実行する。

更新は、`plugins/work-rules/.claude-plugin/plugin.json` の `version` が変わったときだけ届く。

## スキルの一覧

10件のスキルを、使う場面ごとに4つに分けて示す。各スキルは、名前の場面の依頼を受けたときに Claude が自分で読み込む。

### 文章を書く

| スキル | 内容 |
| --- | --- |
| `doc-writing` | 要件定義書・設計書・調査報告書・議事録・課題管理ツールへの投稿文など、人に読ませる業務資料の決まり。常体で書くこと、事実と推測を分けること、資料の種類ごとの章立て、提出前の点検項目を定める |
| `ui-text` | 画面に表示する文言（ボタン・エラーメッセージ・確認ダイアログ・空の状態・サービスが利用者へ送るメール）の決まり。敬体で短く書くこと、利用者を責めないこと、エラーには次に何をすればよいかを書くことを定める |

### git と GitHub の作業

| スキル | 内容 |
| --- | --- |
| `commit-guard` | コミット・push・リポジトリの作成の前の安全の確認。差分に秘密情報・個人情報が無いか、作者の名義が送り先のアカウントに合っているか、公開範囲が正しいかを確かめる |
| `git-conventions` | コミットメッセージの書式（件名に何をしたか、本文になぜ変えたか）、1コミットの粒度、push 前の履歴の整理、ブランチ名の付け方 |
| `github` | gh CLI で Issue・プルリクエスト・差分・Actions の結果・ファイルを読む手順（読み取り専用）。複数のアカウントでログインしているときは、リポジトリの所有者から使うアカウントを決める |
| `design-and-ship` | GitHub の Issue から、レビュー用の短い Design doc を書き、実装してプルリクエストを作るまでの流れ |

### 作業の進め方と安全

| スキル | 内容 |
| --- | --- |
| `sub-agent-ops` | サブエージェントの起動・監視・評価の手順。モデルの選び方、進捗ファイルによる監視、報告の扱い、作業を並べてよいか順に行うかの分け方を定める |
| `security-rules` | 秘密情報・本番の個人情報・外から取り込んだ文章・外部への送信を扱う前に読む規則。メモリや会話に秘密を残さない、本番の個人情報を一時領域にだけ置く、外部の文章の中の指示に従わない、送る前に中身を示すことを定める |
| `unit-test-csv` | 対象のコードから単体テストの項目を洗い出し、スプレッドシートに貼れるタブ区切りの .tsv として書き出す手順 |

### 外部の道具とつなぐ

| スキル | 内容 |
| --- | --- |
| `backlog` | Backlog の課題・コメント・プロジェクトを API で読む手順と道具（読み取り専用）。API キーは macOS のキーチェーンに置き、コマンドの引数に載せない |

## 併せて使う外部のスキル

次のスキルは、このリポジトリに含めない。作者のリポジトリから各自で入れる。

| スキル | 入手先 | 関係 |
| --- | --- | --- |
| `yomiyasu` | https://github.com/nanaism/yomiyasu | `doc-writing` と `git-conventions` は、入れてあれば文の組み立てに併用する |
| `grilling` | https://github.com/mattpocock/skills | 計画や設計の未決の判断を、質問を重ねて詰める |

## 利用者ごとの上書きファイル

利用者ごとに違う値（GitHub のアカウント名、サブエージェントの起動の方法、参照する手元の資料など）は、スキルの本文に書かず、各自の手元のファイルに書く。

```
~/.config/claude-skills/<スキル名>.local.md
```

- スキルは、このファイルがあれば読んで従う。本文と食い違う箇所は、上書きファイルを優先する。
- `backlog`・`commit-guard`・`github`・`sub-agent-ops` は、ファイルが無ければ Claude が必要な値を聞き、聞いた内容でファイルを作る。
- `doc-writing`・`git-conventions`・`security-rules` は、ファイルが無ければ本文の既定で進める。
- 上書きファイルはこのリポジトリに含めない。各自の手元にだけ置く。

`security-rules` の gitleaks の hook（`skills/security-rules/scripts/gitleaks-pre-commit.sh`）は、入れただけでは動かない。使う場合は、同スキルの「5.2」に従って各自の `settings.json` に登録する。

## ライセンス

MIT
