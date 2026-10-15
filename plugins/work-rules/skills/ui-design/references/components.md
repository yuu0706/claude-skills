# 部品の雛形

各部品の最小の HTML と CSS を示す。CSS は `tokens.css` の変数だけを使う。
既存のテーマ定義（MUI・Tailwind の `@theme`・既存の `:root` 変数）があるプロジェクトでは、ここの CSS を持ち込まず、構造と配置の考え方だけを使う。
画面文言（ラベル・見出し・空状態の文）は Skill `ui-text` に従う。下の例の文言は構造を示すための仮置きである。

## 0. 前提: 層の順と状態の置き場所

CSS は `@layer` で勝ち負けを先に決める。詳細度を上げて勝ちにいかない。`!important` を書かない。

```css
@layer tokens, base, components, features, utilities;
/* tokens.css は @layer tokens に、部品は components に、機能ごとの指定は features に入れる */
```

開閉の状態は `<html>` の data 属性の1か所に集める。各機能はこの属性を読むだけにする（SKILL.md 8節 型B）。

```html
<html lang="ja" data-sidebar="open" data-drawer="closed" data-panel="closed">
```

```js
// ui-state.js: 開閉の状態を書くのはこの関数だけ。各機能は属性を読むか、変化を購読する
const KEYS = ["sidebar", "drawer", "panel"];
export function setUi(key, value) {
  if (!KEYS.includes(key)) throw new Error(`unknown ui key: ${key}`);
  document.documentElement.dataset[key] = value;
  document.dispatchEvent(new CustomEvent("ui:change", { detail: { key, value } }));
}
export function getUi(key) {
  return document.documentElement.dataset[key];
}
```

```js
// breakpoints.js: 画面幅の境目は tokens.css の --bp-* から読む。px を JS に直書きしない（型F）
export function bp(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(`--bp-${name}`).trim();
}
export function matchBelow(name) {
  return window.matchMedia(`(max-width: calc(${bp(name)} - 0.02px))`);
}
```

## 1. ページ見出しと主要な操作

見出し行の左に「何の画面か（対象）」、右端に主要な操作を置く。スクロール前に必ず見える。

```html
<header class="page-header">
  <div class="page-header__title">
    <nav class="breadcrumb" aria-label="パンくず"><a href="/requests">申請</a></nav>
    <h1>申請 #1042 <span class="badge badge--warning">承認待ち</span></h1>
  </div>
  <div class="page-header__actions">
    <button class="btn btn--secondary" type="button">差し戻す</button>
    <button class="btn btn--primary" type="button">承認する</button>
  </div>
</header>
```

```css
@layer components {
  .page-header {
    position: sticky;
    top: 0;
    z-index: var(--z-sticky);
    min-height: var(--header-h); /* 6節の .split の高さの計算と合わせる。自然な高さ（パンくず1行と h1）より大きい値にして揃える */
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: var(--space-4);
    padding: var(--space-3) var(--space-page-x);
    background: var(--color-bg);
    border-bottom: 1px solid var(--color-border);
  }
  .page-header h1 {
    margin: 0;
    font-size: var(--text-xl);
    font-weight: var(--weight-bold);
    line-height: var(--leading-tight);
  }
  .breadcrumb { font-size: var(--text-sm); color: var(--color-text-muted); }
  .page-header__actions { display: flex; gap: var(--space-2); flex-shrink: 0; }
}
```

## 2. 画面下に固定する操作バー

長い詳細や入力の画面で使う。見出し行と操作バーの両方に同じ主要な操作を置かない。どちらか1か所にする。

```html
<div class="action-bar" role="region" aria-label="操作">
  <span class="action-bar__status">3件を選択中</span>
  <button class="btn btn--secondary" type="button">既読にする</button>
  <button class="btn btn--primary" type="button">承認する</button>
</div>
```

```css
@layer components {
  .action-bar {
    position: sticky;
    bottom: 0;
    z-index: var(--z-sticky);
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: var(--space-2);
    padding: var(--space-3) var(--space-page-x);
    background: var(--color-bg-subtle);
    border-top: 1px solid var(--color-border);
  }
  .action-bar__status { margin-right: auto; font-size: var(--text-sm); color: var(--color-text-muted); }
}
```

## 3. ボタン3種

主要（青の塗り）・副（枠線）・破壊的（赤の文字、確認後に赤の塗り）の3種だけを使う。1つの画面で主要のボタンは1つにする。

```html
<button class="btn btn--primary" type="button">保存する</button>
<button class="btn btn--secondary" type="button">
  <svg class="icon" viewBox="0 0 24 24" aria-hidden="true"><!-- Lucide の線のアイコン --></svg>書き出す
</button>
<button class="btn btn--danger" type="button">削除する</button>
```

```css
@layer components {
  .btn {
    display: inline-flex;
    align-items: center;
    gap: var(--space-1);
    height: var(--control-h-md);
    padding: 0 var(--space-3);
    font: inherit;
    font-size: var(--text-md);
    font-weight: var(--weight-medium);
    border: 1px solid transparent;
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: background-color var(--duration-fast) var(--easing);
  }
  .btn:focus-visible { outline: 2px solid var(--color-focus-ring); outline-offset: 2px; }
  .btn:disabled { color: var(--color-text-disabled); background: var(--color-bg-subtle); border-color: var(--color-border); cursor: not-allowed; }
  .btn--primary { color: var(--color-text-on-accent); background: var(--color-accent); }
  .btn--primary:hover:not(:disabled) { background: var(--color-accent-hover); }
  .btn--secondary { color: var(--color-text); background: var(--color-bg); border-color: var(--color-border); }
  .btn--secondary:hover:not(:disabled) { background: var(--color-bg-hover); }
  .btn--danger { color: var(--color-danger); background: var(--color-bg); border-color: var(--color-border); }
  .btn--danger:hover:not(:disabled) { color: var(--color-text-on-accent); background: var(--color-danger); }
  .btn--sm { height: var(--control-h-sm); padding: 0 var(--space-2); font-size: var(--text-sm); }
  .icon { width: var(--icon-sm); height: var(--icon-sm); stroke: currentColor; fill: none; }
}
```

## 4. 表

一覧は表にする。カードを並べない。行の高さは `--row-h`、数値の列は右寄せにする。行ごとの操作は右端の列に置く。

- **折り返してよいのは件名などの本文の列だけにする。** 名前・状態・金額・日付の列は `nowrap` を付けて折り返させない。バッジは部品の側で折り返さない。
- **狭い画面（`--bp-md` 未満）では、表を横スクロールの箱（`overflow-x: auto`）に入れ、列を折り返させない。** 6節の `.split__list` がその箱になる。単独で置くときは `.table-wrap` で包む。
- **列が5つを超えるなら、狭い画面では優先度の低い列を CSS で畳む。** `hidden` 属性や JS で消さない（SKILL.md 8節 型C）。畳む列に `col-optional` を付ける。

```html
<div class="table-wrap">
<table class="table">
  <thead>
    <tr><th>件名</th><th class="nowrap">申請者</th><th class="nowrap">状態</th><th class="num">金額</th><th class="nowrap col-optional">申請日</th><th><span class="visually-hidden">操作</span></th></tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="/requests/1042">出張旅費の精算</a></td>
      <td class="nowrap">山田太郎</td>
      <td class="nowrap"><span class="badge badge--warning">承認待ち</span></td>
      <td class="num">12,800</td>
      <td class="nowrap col-optional">2026-10-14</td>
      <td class="row-actions"><button class="btn btn--secondary btn--sm" type="button">承認する</button></td>
    </tr>
  </tbody>
</table>
</div>
```

```css
@layer components {
  .table-wrap { overflow-x: auto; }
  .table { width: 100%; border-collapse: collapse; font-size: var(--text-sm); }
  .table th {
    position: sticky;
    top: 0; /* スクロールの箱（.split__list か .table-wrap）の上端。箱の中の座標なので、見出し行の高さを足さない */
    z-index: var(--z-sticky);
    height: var(--row-h);
    padding: 0 var(--space-3);
    text-align: left;
    font-weight: var(--weight-bold);
    color: var(--color-text-muted);
    background: var(--color-bg-subtle);
    border-bottom: 1px solid var(--color-border);
  }
  .table td { height: var(--row-h); padding: 0 var(--space-3); border-bottom: 1px solid var(--color-border-subtle); }
  .table tbody tr:hover { background: var(--color-bg-hover); }
  .table tr[aria-selected="true"] { background: var(--color-bg-selected); }
  .table .num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
  .table .nowrap { white-space: nowrap; }
  .table .row-actions { text-align: right; white-space: nowrap; }
  @media (max-width: 959.98px) { /* --bp-md */
    /* 狭い画面では件名の列も折り返さず、箱（.split__list か .table-wrap）の中で横にスクロールさせる。折り返すと件名が1〜2文字ずつの縦長になる */
    .table th, .table td { white-space: nowrap; }
    .table .col-optional { display: none; }
  }

  .badge { display: inline-flex; align-items: center; height: var(--badge-h); padding: 0 var(--space-2); font-size: var(--text-xs); font-weight: var(--weight-medium); white-space: nowrap; border-radius: var(--radius-full); }
  .badge--success { color: var(--color-success); background: var(--color-success-subtle); }
  .badge--warning { color: var(--color-warning); background: var(--color-warning-subtle); }
  .badge--danger { color: var(--color-danger); background: var(--color-danger-subtle); }
  .badge--neutral { color: var(--color-text-muted); background: var(--color-bg-subtle); }

  .visually-hidden { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
}
```

バッジの高さ `--badge-h`（20px）は、文字 12px と上下の余白 4px の和である（目安）。
枠線の 1px とフォーカスの輪の 2px、`.visually-hidden` の 1px は、直書きを許す例外とする。

## 5. フォーム

入力は1列にする。ラベルは入力欄の上に置く。送信の操作はフォームの末尾ではなく、見出し行か操作バーに置く（SKILL.md 2節）。

```html
<form class="form" id="profile-form">
  <div class="field">
    <label for="email">メールアドレス（必須）</label>
    <p class="field__help" id="email-help">通知の送り先になります。</p>
    <input id="email" type="email" required aria-describedby="email-help email-error">
    <p class="field__error" id="email-error" hidden>メールアドレスを入力してください。</p>
  </div>
</form>
```

```css
@layer components {
  .form { display: grid; gap: var(--space-4); max-width: var(--form-w); }
  .field { display: grid; gap: var(--space-1); }
  .field label { font-size: var(--text-md); font-weight: var(--weight-medium); }
  .field__help { margin: 0; font-size: var(--text-sm); color: var(--color-text-muted); }
  .field__error { margin: 0; font-size: var(--text-sm); color: var(--color-danger); }
  .field input, .field select, .field textarea {
    height: var(--control-h-md);
    padding: 0 var(--space-2);
    font: inherit;
    font-size: var(--text-md);
    color: var(--color-text);
    background: var(--color-bg);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-md);
  }
  .field textarea { height: auto; min-height: calc(var(--control-h-md) * 3); padding: var(--space-2); }
  .field input:focus-visible { outline: 2px solid var(--color-focus-ring); outline-offset: -1px; }
  .field input[aria-invalid="true"] { border-color: var(--color-danger); }
}
```

`.form` の上限 `--form-w`（480px）は、メールアドレスなど長めの1行の入力が切れない幅の目安である。

## 6. 一覧と詳細（2列）

左に一覧、右に選んだ項目の詳細を置く。`--bp-md` 未満では1列にし、詳細を一覧の代わりに表示する。
`.split` は見出し行（1節）の直下に置き、見出し行を除いた画面の高さにする。スクロールするのは `.split__list` と `.split__detail` の中だけで、ページは動かない。表の見出し行（4節の `th`）はこの箱の上端に留まる。
見出し行の h1 が折り返すと見出し行が `--header-h` より高くなり、その分だけページが動く（幅 390 の見本で 23px を観測）。`th` は箱の中に閉じ込めてあるため、動いても見出し行とは重ならない。h1 は折り返さない長さにする。

```html
<div class="split">
  <section class="split__list" aria-label="申請の一覧"><!-- 4. の表 --></section>
  <section class="split__detail" aria-label="申請の詳細">
    <dl class="props">
      <dt>申請者</dt><dd>山田太郎</dd>
      <dt>金額</dt><dd>12,800 円</dd>
    </dl>
  </section>
</div>
```

```css
@layer components {
  /* 高さを決めないと overflow: auto の箱にならず、th の sticky が効かない。--header-h は .page-header の min-height と同じ値 */
  .split { display: grid; grid-template-columns: minmax(var(--list-min-w), 2fr) 3fr; height: calc(100dvh - var(--header-h)); min-height: 0; }
  /* isolation で th の z-index を箱の中に閉じ込める。閉じ込めないと、ページが動いたときに th が .page-header（同じ --z-sticky）の上に描かれる */
  .split__list { overflow: auto; isolation: isolate; border-right: 1px solid var(--color-border); }
  .split__detail { overflow: auto; padding: var(--space-page-y) var(--space-page-x); }
  .split__detail p { max-width: var(--measure); }
  .props { display: grid; grid-template-columns: max-content 1fr; gap: var(--space-2) var(--space-6); margin: 0; font-size: var(--text-md); }
  .props dt { color: var(--color-text-muted); }
  .props dd { margin: 0; }
  @media (max-width: 959.98px) { /* --bp-md */
    .split { grid-template-columns: 1fr; }
    .split__list { border-right: 0; }
  }
}
```

一覧の最小幅 `--list-min-w`（320px）は、件名と状態のバッジが1行に収まる幅の目安である。

## 7. 空・読込・エラー

3つとも同じ場所（データが出るはずの場所）に出す。ページ全体を差し替えず、見出し行と操作はそのまま残す。

```html
<!-- 空: 次の操作を示すボタンを1つ置く -->
<div class="state" data-state="empty">
  <svg class="icon icon--md" viewBox="0 0 24 24" aria-hidden="true"><!-- Lucide inbox --></svg>
  <p class="state__title">承認待ちの申請はありません</p>
  <a class="btn btn--secondary" href="/requests?status=all">すべての申請を見る</a>
</div>

<!-- 読込: 表は行の形の骨組みを出す。全画面の回転アイコンにしない -->
<tbody aria-busy="true">
  <tr class="skeleton-row"><td colspan="5"><span class="skeleton"></span></td></tr>
</tbody>

<!-- エラー: 何が起きたかと次の操作。入力済みの内容は消さない -->
<div class="state state--error" role="alert" data-state="error">
  <p class="state__title">一覧を読み込めませんでした</p>
  <button class="btn btn--secondary" type="button">再読み込みする</button>
</div>
```

```css
@layer components {
  .state { display: grid; justify-items: center; gap: var(--space-2); padding: var(--space-12) var(--space-4); color: var(--color-text-muted); }
  .state__title { margin: 0; font-size: var(--text-md); color: var(--color-text); }
  .state--error .state__title { color: var(--color-danger); }
  .icon--md { width: var(--icon-md); height: var(--icon-md); }
  .skeleton-row td { height: var(--row-h); padding: 0 var(--space-3); }
  .skeleton { display: block; height: var(--space-3); border-radius: var(--radius-sm); background: var(--color-bg-hover); }
}
```

成功は、操作した場所の近くに短い通知（`--z-toast` の層）で出し、数秒で消す。画面を遷移させない。

## 8. 引き出し（狭い画面のナビ・横の面）

開閉は `setUi("drawer", "open")` で書き、CSS は `<html>` の属性だけを見る。部品が自分の `hidden` や `display` を JS で直接書き換えない（型B・型C）。

```css
@layer components {
  .drawer {
    position: fixed;
    inset: 0 auto 0 0;
    z-index: var(--z-drawer);
    width: var(--sidebar-w);
    background: var(--color-bg);
    box-shadow: var(--shadow-modal);
    transform: translateX(-100%);
    transition: transform var(--duration-normal) var(--easing);
  }
  :root[data-drawer="open"] .drawer { transform: translateX(0); }
  /* 覆いは引き出しと同じ層に置き、DOM で引き出しより前に書いて背後に回す */
  .scrim { position: fixed; inset: 0; z-index: var(--z-drawer); background: var(--color-scrim); display: none; }
  :root[data-drawer="open"] .scrim { display: block; }
}
```

```html
<div class="scrim"></div>
<nav class="drawer" aria-label="メインメニュー"><!-- ナビの項目 --></nav>
```

覆いと引き出しの前後は、同じ層の中の DOM の順で決める。z-index に 1 を足して調整しない。
ダイアログの覆いはダイアログと同じ `--z-modal` の層に置く。
