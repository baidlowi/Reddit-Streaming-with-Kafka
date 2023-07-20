import json
import os
import findspark
findspark.init()
from pyspark.sql import SparkSession
from pyspark.sql.types import StringType, StructField, StructType, IntegerType, TimestampType
from pyspark.sql.functions import from_json, col, expr
from transform import get_relevance_mark


with open('terraform/terraform.tfstate') as f:
    config = data = json.load(f)

KAFKA_BOOTSTRAP_SERVER = config['outputs']['kafka_endpoint']['value'].replace('SASL_SSL://', '')
KAFKA_KEY = config['outputs']['kafka_api_key_id']['value']
KAFKA_SECRET = config['outputs']['kafka_api_key_secret']['value']
GOOGLE_APPLICATION_CREDENTIALS = 'google-services.json'
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = GOOGLE_APPLICATION_CREDENTIALS
PROJECT_ID = config['outputs']['gcp_project_id']['value']


schema = StructType([
    StructField("id", StringType()),
    StructField("subreddit", StringType()),
    StructField("author", StringType()),
    StructField("subreddit_subscribers", StringType()),
    StructField("selftext", StringType()),
    StructField("title", StringType()),
    StructField("created_utc", TimestampType()),
    StructField("url", StringType()),
])


if __name__ == '__main__':
    packages = [
        'org.apache.spark:spark-sql-kafka-0-10_2.12:3.2.0',
        'org.apache.kafka:kafka-clients:3.2.0',
        "com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:0.30.0",
    ]
    # Replace these with your own values
    dataset_id = "reddit_post"
    table_id = "post_ai"
    bucket = "data-reddit"
    # Set the Kafka topic and bootstrap servers
    topic_name = "reddit_ai"

    spark = SparkSession.builder \
        .appName("spark") \
        .config("spark.hadoop.fs.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem") \
        .config("spark.hadoop.fs.AbstractFileSystem.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS") \
        .config("spark.hadoop.fs.gs.project.id", PROJECT_ID) \
        .config("spark.sql.execution.pythonUDF.arrow.enabled", "true") \
        .config("spark.hadoop.google.cloud.auth.service.account.enable", True) \
        .config("spark.hadoop.fs.gs.auth.service.account.json.keyfile", GOOGLE_APPLICATION_CREDENTIALS) \
        .config("spark.jars.packages", ",".join(packages)) \
        .config("spark.jars", "gcs-connector-hadoop3-2.2.10-shaded.jar") \
        .config("spark.executor.cores", "1") \
        .getOrCreate()

    # Read data from the Kafka topic
    df = spark.readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", KAFKA_BOOTSTRAP_SERVER) \
        .option("kafka.sasl.jaas.config", f'org.apache.kafka.common.security.plain.PlainLoginModule required username="{KAFKA_KEY}" password="{KAFKA_SECRET}";') \
        .option("kafka.sasl.mechanism", 'PLAIN') \
        .option("kafka.security.protocol", 'SASL_SSL') \
        .option("subscribe", topic_name) \
        .load()

    spark.udf.register("relevance_score_udf", get_relevance_mark, IntegerType())
    # Cast the value column as a string
    df = df.select(col("value").cast("string").alias("value"))
    # Parse the JSON data
    df = df.select(from_json("value", schema).alias("data")) \
        .select(
        "data.id",
        "data.subreddit",
        "data.author",
        "data.subreddit_subscribers",
        "data.selftext",
        "data.title",
        "data.created_utc",
        "data.url"
    )

    query = df.writeStream \
        .format("bigquery") \
        .option("table", f"{PROJECT_ID}.{dataset_id}.{table_id}") \
        .option("checkpointLocation", "gs://{bucket}/checkpoints/") \
        .option("temporaryGcsBucket", "{bucket}/tmp") \
        .outputMode("append") \
        .start()

    query.awaitTermination()
