## 環境構築

## リソース操作

各環境(`/staging/`, `/production/`, `/production/admin/`)で以下コマンドを実施して操作.
初回のみ (init コマンドは)

```
terraform init
```

```
terraform plan
terraform apply
```

## その他コマンド

### フォーマットを整える

```
terraform fmt
```

### console でローカル変数やリソース属性の参照をする

```
terraform console
```

### リソースの確認など (aws CLI コマンド)

lightsail の料金プランの確認
https://aws.amazon.com/jp/lightsail/pricing/

```
aws lightsail get-bundles
```

例

```
> local.instance_name
"stg-my-app"
> aws_lightsail_instance.my-app.availability_zone
(known after apply)
> upper(local.instance_name)
"STG-my-app"
> var.environment
"stg"
> var.project_name
"my-app"
```

exit で console から抜ける

### その他
guidesフォルダに忘れた際のリソースを書いている。

よりわかりやすくするために今後編集する。