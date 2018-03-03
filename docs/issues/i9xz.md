# #i9xz - handle old issue files

|**Issue**||
|---|---|
|Status|in progress<!-- any of "new", "in progress", "end" http://redmine.jp/tech_note/issue_statuses/ -->|
|Priority|Normal<!-- "high" or "normal" or "low"-->|
|Assignee|owner<!-- your name -->|
|Category|icol<!-- optional -->|
|Target version|future<!-- optional, any of git tags recommended -->|
|Start date|2018-03-03|
|Due date|2018-03-31|
|% Done|10%|
|worked|1hours|

## Description

icol はファイルベースである以上、理論上際限なく検索対象ファイルが増えるのでありそうなった場合、相当の処理時間がかかってしまう恐れがある  
今は稼働開始直後でファイル数も少ないのだからともかく、何らかの手を打っておかないと将来遅くて使い物にならなくなる  

一案として、下記のように不要な古いファイルを隔離して通常の検索対象ファイル数を相対的に減らすことを思案した

```
root
└── docs/
    └── issues/
        └── old/
            └── old1.md
```

デフォルトでは `old/` を検索対象に含めず、オプション引数で含めるようスイッチすればよい  
難点は、デフォルトで検索対象とならないファイルの存在を受忍しなければならなくなること。当たり前だが。  
検索が早くなることと引き換えになる

だがそもそもここまで頑張るくらいなら redmine に移行したほうが良いのでは？
遅いのが我慢できなくなるほど扱う情報量が増えたのなら "light" を冠する当ツールの趣旨となじまず、その役目の終わりと考えてもよいのではないか

## Related to

|**ID**|**Subject**|
|---|---|
|||<!--OTHER_ISSUE;;-->

## History

`old1.end.md` のように、 status が end となったものについてはファイル名に識別子を設けることでこの条件以外の検索の効率化に寄与するのではないか  
ファイル名で除外できてしまえば、ファイルの中身 `|Status|end` を評価するコストはかからない。  
New or in progress が最もよく使う且つデフォルトの条件なのでこのような施策は効果的である可能性が高い  

---
*this document has been generated & accessed from computer program, named "icol"*
