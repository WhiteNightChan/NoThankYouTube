# NoThankYouTube User Guide

NoThankYouTube（NTYT）の現在の設定・Rule・Optionの使い方をまとめたユーザー向けガイドです。

本書は、現在実装済みの機能だけを対象とします。Roadmap上の将来候補や未実装機能は含めません。

---

# 1. Settings の構成

NoThankYouTube の Settings は、次の順で表示されます。

```text
Global
Channel
General
Video
Post
Playlist
Option
Import Settings
Export Settings
Version
```

`Version` は情報表示専用で、設定変更は行いません。

---

# 2. List の考え方

NTYT には現在 15 個の List があります。

## Global

```text
Global Block
Global Allow
```

Video / Post / Playlist のすべてに適用されます。

Global は、

```text
General Target
OR
Channel Identity
```

を対象にします。

つまり、content 本文側と channel 側のどちらかが Rule に一致すれば Match します。

## Channel

```text
Channel Block
Channel Allow
```

Video / Post / Playlist の Channel Identity を対象にします。

Channel Identity では、利用可能な以下の channel 情報を独立した候補として扱います。

```text
Channel ID
Channel Name
Handle
```

複数 creator が存在する場合も、一つだけを代表 channel として選ぶのではなく、利用可能な creator を対象として評価します。

## General

```text
General Block
General Allow
```

content の主要なテキストを対象にします。

```text
Video    → Title
Post     → Content
Playlist → Title
```

Channel Identity は General に暗黙では含まれません。

## Video

```text
Video / Title
Video / Channel
Video / ID
```

Video のみが対象です。

`Video / ID` は Video ID の完全一致用です。

## Post

```text
Post / Content
Post / Channel
Post / ID
```

Community Post のみが対象です。

`Post / ID` は Post ID の完全一致用です。

## Playlist

```text
Playlist / Title
Playlist / Channel
Playlist / ID
```

Normal Playlist と Mix の両方が対象です。

`Playlist / ID` は Playlist ID の完全一致用です。

---

# 3. Block / Allow の優先順位

NTYT の Filtering priority は次の順です。

```text
Option Block
>
Allow
>
Rule Block
>
Keep
```

重要なのは、**Allow より Block Option の方が強い**ことです。

たとえば `Block Shorts` が On で、その content が Shorts と確認された場合、Allow Rule が一致していても Shorts は Block されます。

一方、通常の Rule Block に対しては Allow が優先されます。

---

# 4. Plain Rule

最も簡単な Rule は、普通の文字列です。

```text
ASMR
```

通常の Plain Rule は、List の `Case Sensitive` と `Exact Match` の設定に従います。

## Case Sensitive

```text
On  → 大文字・小文字を区別
Off → 大文字・小文字を区別しない
```

## Exact Match

```text
On  → 候補全体と完全一致
Off → 部分一致
```

たとえば `Exact Match = Off` の List に、

```text
ASMR
```

を入れた場合、title が

```text
Relaxing ASMR for Sleep
```

でも一致します。

---

# 5. ID List

以下の List は Plain Rule の挙動が固定です。

```text
Video / ID
Post / ID
Playlist / ID
```

固定設定は、

```text
Case Sensitive = On
Exact Match    = On
```

です。

そのため Video ID を Block したい場合は、

```text
dQw4w9WgXcQ
```

のように ID をそのまま追加します。

この固定設定は Regex や `ch` / `ctn` Modifier には引き継がれません。

---

# 6. Regex

Rule 全体を Regex として書くこともできます。

```text
/ASMR/
```

case-insensitive にしたい場合は、

```text
/ASMR/i
```

とします。

使用できる Regex flag は現在 `i` のみです。

例:

```text
/^(?:Foo|Bar)$/
/game(?:play|stream)/i
```

Regex には List-wide の `Case Sensitive` / `Exact Match` は適用されません。

つまり `Exact Match = On` の List でも、Regex に自動で `^` や `$` が追加されることはありません。

完全一致させたい場合は Regex 自身で指定します。

```text
/^Example$/i
```

空 Regex は使用できません。

```text
//
```

ではなく、何でも Match させたい場合は明示的に、

```text
/.*/
```

を使用します。

---

# 7. Negative Matcher

Plain / Regex は `!` で否定できます。

```text
!game
!/game/i
```

`!` と matcher の間に空白は入れません。

```text
!game
```

は有効ですが、

```text
! game
```

は無効です。

---

# 8. Modifier

Modifier を Main Matcher の前に置くことで、一つの Rule 内で複数条件を AND できます。

基本形:

```text
${Modifier} MainMatcher
```

複数の Modifier も使用できます。

```text
${video} ${!shorts} ASMR
```

この Rule は概念上、

```text
Video
AND
NOT Shorts
AND
Main Matcher = ASMR
```

として評価されます。

Modifier は必ず Main Matcher より前に置きます。

有効:

```text
${video} ASMR
${ch: Example Channel} ASMR
${station} ${!ctn: game} /ASMR/i
```

無効:

```text
ASMR ${video}
/ASMR/i ${ch: Example Channel}
```

Modifier と Main Matcher の間には、1文字以上の水平空白が必要です。

---

# 9. `ch` Modifier

`ch` は Channel Identity を追加条件として使います。

```text
${ch: Example Channel} ASMR
```

概念上:

```text
Channel Identity matches "Example Channel"
AND
Main Matcher matches "ASMR"
```

です。

Regex も使用できます。

```text
${ch: /^(?:Channel A|Channel B)$/i} ASMR
```

Modifier 自体を否定する場合は、

```text
${!ch: Example Channel} ASMR
```

とします。

---

# 10. `ctn` Modifier

`ctn` は General Target を追加条件として使います。

```text
${ctn: game} livestream
```

General Target は content type によって次のように変わります。

```text
Video    → Title
Post     → Content
Playlist → Title
```

Regex も使用できます。

```text
${ctn: /game|gaming/i} livestream
```

---

# 11. Content Predicate Modifier

現在使用できる content predicate は次の7個です。

```text
${video}
${post}
${playlist}
${shorts}
${station}
${upcoming}
${current}
```

意味は以下です。

| Modifier | Match 対象 |
|---|---|
| `${video}` | Video |
| `${post}` | Post |
| `${playlist}` | Normal Playlist / Mix |
| `${shorts}` | Shorts |
| `${station}` | Station |
| `${upcoming}` | Upcoming Video |
| `${current}` | Current Live Video |

Shorts / Station / Ad-supported Free Movie は Video に含まれるため、`${video}` にも Match します。

---

# 12. Predicate の否定に関する重要な注意

Predicate の `!` は単純な NOT です。

```text
${!shorts}
```

は、

```text
Video AND NOT Shorts
```

という意味ではありません。

Post や Playlist は `${shorts}` に対して NoMatch なので、その否定である `${!shorts}` には Match します。

**「Shorts ではない Video」だけに限定したい場合は、必ず Video 条件も明示します。**

```text
${video} ${!shorts} MainMatcher
```

同様に、

```text
${video} ${!station} MainMatcher
```

のように書きます。

---

# 13. Rule は AND、List は OR

一つの Rule の中では、Main Matcher と Modifier はすべて AND です。

```text
${video} ${!shorts} ${ch: Example} ASMR
```

は、

```text
Video
AND
NOT Shorts
AND
Channel matches Example
AND
ASMR
```

です。

一方、同じ List に複数 Rule を入れた場合は OR として扱われます。

```text
Rule 1
OR
Rule 2
OR
Rule 3
```

どれか一つが Match すれば、その List は Match します。

---

# 14. Rule の例

## 特定 Channel の Video Title を Block

`Video / Title`:

```text
${ch: Example Channel} ASMR
```

## Shorts を除外して Video のみ Block

```text
${video} ${!shorts} ASMR
```

## Station だけを Block

Main Matcher も必須なので、対象 List に適した matcher と組み合わせます。

例:

```text
${station} /.*/
```

## 特定 Channel 名または Channel ID を Channel Block

Regex 例:

```text
/^(?:UCxxxxxxxxxxxxxxxxxxxxxx|Example Channel)$/
```

## 複数の名前を完全一致で Block

```text
/^(?:Foo|Bar|Baz)$/i
```

---

# 15. Plain Escape

Plain Matcher 内では、

```text
\X
```

で `X` を literal として扱えます。

末尾が単独の `\` で終わる Rule は無効です。

Rule は必ず1行です。newline を含む Rule は無効です。

特殊構文が壊れている場合、NTYT はそれを普通の Plain Rule として勝手に解釈し直しません。

たとえば、

```text
壊れた Regex
不明な Modifier
```

は invalid Rule になります。

---

# 16. List の初期 Match Options

現在の default は以下です。

| List | Case Sensitive | Exact Match |
|---|---:|---:|
| Global Block | Off | Off |
| Global Allow | Off | Off |
| General Block | Off | Off |
| General Allow | Off | Off |
| Video / Title | Off | Off |
| Video / Channel | Off | On |
| Video / ID | On 固定 | On 固定 |
| Channel Block | Off | On |
| Channel Allow | Off | On |
| Post / Content | Off | Off |
| Post / Channel | Off | On |
| Post / ID | On 固定 | On 固定 |
| Playlist / Title | Off | Off |
| Playlist / Channel | Off | On |
| Playlist / ID | On 固定 | On 固定 |

必要に応じて、変更可能な List の `Case Sensitive` / `Exact Match` を調整できます。

---

# 17. Block Options

Option ページ前半の9項目は、Filtering の `Option Block` として動作します。

すべて default Off です。

表示順:

```text
Block Shorts
Block "From YouTube" Cell
Block Ad-Supported Free Movies
Block Station
Block Posts
Block Playlists
Block Mix
Block Horizontal Shelves
Block Cell Dividers
```

## Block Shorts

Shorts Video と、確認済みの Shorts Shelf を Block します。

## Block "From YouTube" Cell

確認済みの "From YouTube" presentation を Block します。

## Block Ad-Supported Free Movies

広告付き無料映画として確認された Video を Block します。

## Block Station

Station として確認された Video を Block します。

## Block Posts

Community Post を Block します。

## Block Playlists

Playlist family を Block します。Normal Playlist と Mix の両方が対象です。

## Block Mix

Playlist のうち Mix と確認されたものだけを Block します。

## Block Horizontal Shelves

対象となる Horizontal Shelf presentation を Block します。

## Block Cell Dividers

Cell Divider / spacing-only separator として確認された presentation を Block します。

---

# 18. Additional Options

Option ページ後半には、Filtering Rule とは独立した7個の Option があります。

すべて default Off で、互いに独立しています。

```text
Block Home Chip Bar
Block Search Chip Bar
Block Watch Page Chip Bar
Block Subscription Tab Chip Bar
Block Top Corner Rounding Below the Player
Block Pull-to-Fullscreen Gesture
Block Portrait Fullscreen
```

これらは通常の Rule / Allow / Option Block priority には参加しません。

## Block Home Chip Bar

Home に表示される Chip Bar を Block します。

## Block Search Chip Bar

Search に表示される Chip Bar を Block します。

## Block Watch Page Chip Bar

動画ページに表示される Chip Bar を Block します。

## Block Subscription Tab Chip Bar

登録チャンネルタブに表示される Chip Bar を Block します。

## Block Top Corner Rounding Below the Player

動画プレーヤー下の content 領域上端の丸みを Block します。

動画プレーヤー本体の rounded corners や、thumbnail / card 等の別の丸みは対象ではありません。

## Block Pull-to-Fullscreen Gesture

動画再生画面で、引っ張り操作によって fullscreen へ遷移する操作を Block します。

fullscreen 機能そのものを無効化する Option ではありません。

## Block Portrait Fullscreen

縦型 fullscreen への遷移を Block します。

横向き fullscreen は対象ではありません。

`Block Pull-to-Fullscreen Gesture` とは独立した Option です。

---

# 19. Rule List の操作

Rule List では、Rule の追加・編集・削除・検索・並び替えを行えます。

Rule は内部的に安定した identity を持つため、表示位置そのものが identity ではありません。

## Search

Search は保存されている raw Rule expression を対象にします。

検索中は並び替えできません。

## Reorder

検索していない通常状態では Rule を並び替えられます。

**Rule の表示順は Evaluator の priority ではありません。**

同一 List 内では OR なので、上の Rule が下の Rule より強い、という意味にはなりません。

---

# 20. Import Settings

`Import Settings` は NTYT の設定全体を Import します。

Import は **merge ではなく全置換** です。

つまり、選択した設定ファイルで現在の NTYT Settings を置き換えます。

Import 対象には現在、

```text
15 Lists
9 Block Options
7 Additional Options
```

が含まれます。

current format として完全に有効な Settings のみ Import できます。

壊れた設定を部分的に取り込んだり、自動修復して Import したりはしません。

---

# 21. Export Settings

`Export Settings` から現在の NTYT Settings を Property List として Export できます。

Export は現在 NTYT が受理している semantic Settings を出力します。

設定ファイルが一部劣化状態の場合は、受理できている有効な設定だけを Export する場合があります。

設定が使用不能な場合、Export は拒否されます。

---

# 22. Settings File を手動編集する場合

NTYT は設定読み込み時に自動修復を行いません。

未知・不正な値や壊れた構造がある場合、状態によっては Settings が読み取り専用になります。

そのため、plist を直接編集する場合はバックアップを取ることを推奨します。

canonical Settings file:

```text
Library/Preferences/com.whitenightchan.nothankyoutube.plist
```

現在の format version:

```text
schemaVersion = 1
syntaxVersion = 1
```

これらは Tweak の package Version とは別物です。

---

# 23. Filtering が安全に判定できない場合

NTYT は、対象であることを安全に確認できない content を推測で Block しません。

概念上は、

```text
安全に Block と確定
→ Block

確定できない / 必要情報が利用できない
→ Keep
```

を基本とします。

また、一つの metadata や分類が利用できないことだけを理由として、別の独立した情報まで推測して補完することはしません。

---

# 24. よく使う例

## Channel 名を完全一致で Block

`Channel Block`:

```text
Example Channel
```

default では `Exact Match = On` です。

## Channel ID と名前のどちらでも Block

`Channel Block`:

```text
/^(?:UCxxxxxxxxxxxxxxxxxxxxxx|Example Channel)$/
```

## Title に特定語が入る Video を Block

`Video / Title`:

```text
keyword
```

default は部分一致・case-insensitive です。

## 特定 Channel + 特定 Title 条件

`Video / Title`:

```text
${ch: Example Channel} keyword
```

## Shorts 以外の Video だけ

```text
${video} ${!shorts} keyword
```

`${!shorts}` だけでは Post / Playlist も Match し得るため、`${video}` を併記します。

## Current Live にだけ適用

```text
${current} keyword
```

## Upcoming Video にだけ適用

```text
${upcoming} keyword
```

## Playlist の Mix だけを一括 Block

Rule ではなく Option の、

```text
Block Mix
```

を使用できます。

---

# 25. まとめ

NTYT の基本的な使い分けは次の通りです。

```text
単純な文字列条件
→ Plain Rule

複雑な文字列条件
→ Regex

Channel 条件を追加
→ ${ch: ...}

content 本文側の追加条件
→ ${ctn: ...}

Video / Post / Playlist / Shorts / Station / Upcoming / Current 条件
→ Predicate Modifier

特定 presentation / content type をまとめて無効化
→ Option

通常 Rule より優先して残したい
→ Allow List

設定全体の移行
→ Import / Export
```

NTYT は、確認できない対象を推測で Block するのではなく、confirmed な条件だけを使って Filtering することを基本としています。
