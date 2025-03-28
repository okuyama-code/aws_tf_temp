# boto3（AWS SDK）とosモジュールをインポート
import boto3  # AWSのサービス（EC2など）を操作するためのライブラリ
import os  # 環境変数を取得するためのモジュール

# Lambda関数のメイン処理
def lambda_handler(event, context):
    # """
    # AWS Lambdaが呼び出されたときに実行される関数
    # - EC2インスタンスを停止する
    # """

    # EC2サービスに接続するクライアントを作成
    ec2 = boto3.client('ec2')  # boto3を使ってEC2サービスにアクセスできるようにする

    # 環境変数 "INSTANCE_ID" から、停止対象のEC2インスタンスのIDを取得
    instance_id = os.environ['INSTANCE_ID']

    # どのインスタンスを停止するのかログ（出力）に記録
    print(f"Stopping EC2 instance: {instance_id}")

    # EC2インスタンスを停止
    ec2.stop_instances(InstanceIds=[instance_id])

    # 処理の結果を返す
    return {
        'statusCode': 200,  # HTTPステータスコード（200は成功）
        'body': f"Instance {instance_id} is stopping."  # メッセージを返す
    }
