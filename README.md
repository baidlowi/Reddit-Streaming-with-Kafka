# <p align="center"><strong> Technology News Discussion Reddit Streaming with Kafka </strong><p>
<div align="center">
  <a href="https://www.terraform.io/" target="_blank" >
  <img alt="Terraform" src="https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/6468cc31-a08c-48a3-ad75-55df01fbfe98" width="90" height="40"/>
  </a>
  
  <a href="https://confluent.cloud/" target="_blank" >
  <img alt="Confluent-kafka" src="https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/96156fb5-35c3-493d-a1cf-86a9797e35cc" width="180" height="30"/>
  </a>

  <a href="https://spark.apache.org/docs/latest/api/python/getting_started/install.html" target="_blank" >
  <img alt="Reddit" src="https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/4f3285a8-f9c2-4189-8c45-08d5343504ad" width="100" height="40"/>
  </a>

  <a href="https://console.cloud.google.com/storage" target="_blank" >
  <img alt="GCS" src="https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/5964198a-daba-4780-94bd-293c13788e1a" width="100" height="35"/>
  </a>

  <a href="https://console.cloud.google.com/bigquery" target="_blank" >
  <img alt="BigQuery" src="https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/a1774580-1f4c-4367-a86b-c26f1851953b" width="80" height="35"/>
  </a>
</div><br>

## Problem Definition



## Solution Overview
**Kafka** is a powerful tool for stream processing. It provides a number of benefits that can help you to build reliable and scalable streaming applications. 
**Kafka** can be used to stream real-time data to analytics platforms, such as Hadoop or Spark. This allows to analyze data as it is being generated, which can help us to make better decisions in real time. 
**Kafka** can be used to integrate data from different sources. This allows to build a single view of our data, which can help us to make better decisions.

Currently there is only one data source - reddit. It is possible to add more data sources in the future.
- [Producer](producer.py) for Kafka is written in python.
- [Consumer](consumer.py) is written in pySpark

![image](https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/5e301737-ba0c-4d85-9cbf-202c85ce1802)


Target table is partitioned by `date` column. And clustered by `subreddit`.

### Tools
- Google Cloud Platform (GCP): Cloud-based auto-scaling platform by Google
- Google Cloud Storage (GCS): Data Lake
- BigQuery: Data Warehouse
- Terraform: Infrastructure-as-Code (IaC)
- Confluent Kafka: Streaming System Apache Kafka
- Apache Spark: Data Processing and Loader


## Step Guide to Run It

- Clone this repo and download gcs connector jar
  ```
  git clone https://github.com/baidlowi/Reddit-Streaming-with-Kafka && cd Reddit-Streaming-with-Kafka
  wget https://repo1.maven.org/maven2/com/google/cloud/bigdataoss/gcs-connector/hadoop3-2.2.10/gcs-connector-hadoop3-2.2.10-shaded.jar
  ```

- Create [google project](https://console.cloud.google.com) and store credentials in `google-services.json` file
- Sign-up https://confluent.cloud, create new key and enviroment to get variables
  <a href="https://confluent.cloud/settings/api-keys/create" target="_blank" >
  <img alt="api-key" src="https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/9db18b65-ba5d-4715-8b6f-6f5deb429c6b"/></a>
   - `Cloud API Key` = Confluent Cloud API Key
   - `API Secret` = Confluent Cloud API Secret
   - `Environment ID` = The ID Environment from Kafka cluster like `'env-'`
     
     ![image](https://github.com/baidlowi/Reddit-Streaming-with-Kafka/assets/79616397/8f1f5f89-72d8-4d23-a116-11963706ec28)

- Copy `terraform/variables.tf.example` to `terraform/variables.tf` and replace `<YOUR VALUE HERE>` with your values

- Create infrastructure using terraform
  ```
  cd terraform
  terraform init
  terraform apply
  ```
  
- In main directory `/Reddit-Streaming-with-Kafka` Install Java and Setup `JAVA_HOME`
  ```
  wget https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
  tar xzfv openjdk-11.0.2_linux-x64_bin.tar.gz

  export JAVA_HOME="${HOME}/jdk-11.0.2"
  export PATH="${JAVA_HOME}/bin:${PATH}"
  ```
  
- Setup python virtual environment activate it and install dependencies
  ```
  apt install virtualenv
  python3 -m venv kafka
  source kafka/bin/activate
  pip install -r requirements.txt
  ```

- Setup Local Confluent Kafka
  ```
  wget https://s3-us-west-2.amazonaws.com/confluent.cloud/confluent-cli/archives/latest/confluent_latest_linux_amd64.tar.gz
  tar xzfv confluent_latest_linux_amd64.tar.gz
  export PATH="${HOME}/bin:${PATH}"
  confluent version
  ```
  
- Start Confluent Kafka and Create Topic
  ```
  confluent local kafka start
  confluent local kafka topic create reddit
  ```
  
- Start running producer and consumer
  - ```
    python kafka/producer.py
    ```
  - ```
    python kafka/consumer.py
    ```

- Create visualization. An example can be seen here. 
  - lookerstudio.google.com does not support git versioning yet. So you need to do it manually.

## Make Visualization
