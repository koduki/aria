## input:

- agentはエージェント名の判定用
- user_interactionは必須？ それ以外のインタラクションはエージェント次第

```json
{
  control: {
    agent: "windows_oerator"
  },
  interactions: {
    user_interaction: "実行して良いよ",
    task: "{エージェントに実行させるコマンドなど}"
  }
}
```

## output:

- agentはエージェント名の判定用
- finishはエージェントの一連の処理が完了したことの確認
- interactionsの中はエージェント毎に自由

```json
{
  control: {
    agent: "windows_oerator",
    finish: false
  },
  interactions: {
    exec_result: "タスクの実行結果",
    thinking: "エージェント の思考経路",
    task: "エージェントが次に実行するタスク",
    request: "ユーザへの許可や追加情報のリクエスト"
  }
}
```