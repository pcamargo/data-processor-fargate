import os
import duckdb

AWS_REGION = 'us-east-1'

def get_conn():
    print("getting connection...")
    con = duckdb.connect(database=":memory:")
    aws_region = os.getenv("AWS_REGION", AWS_REGION)

    con.execute("LOAD aws;")
    con.execute(f"SET s3_region='{aws_region}';")

    con.execute(f"""
        CREATE OR REPLACE SECRET s3_secret (
            TYPE s3,
            PROVIDER credential_chain,
            REGION '{aws_region}'
        );
    """)

    return con

def process_data():
    s3_bucket = os.environ["S3_BUCKET"]

    query = f"""
        CREATE TABLE result_data AS
        SELECT 
            t1.PassengerId,
            t1.Name,
            t1.Sex,
            t1.Age
        FROM 's3://{s3_bucket}/titanic/raw/*.parquet' t1
        WHERE t1.Survived = 1;
    """

    con = get_conn()
    con.execute(query)

    output_path = f"s3://{s3_bucket}/titanic/curated/data.parquet"

    con.execute(f"""
        COPY result_data TO '{output_path}' 
        (FORMAT PARQUET, COMPRESSION 'SNAPPY');
    """)

if __name__ == '__main__':
    print("=== STARTING PROCESSING ON AWS FARGATE + DUCKDB ===")
    process_data()
