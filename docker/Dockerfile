FROM python:3.11-slim

WORKDIR /app

# Instala dependências leves
RUN pip install --no-cache-dir duckdb boto3
# Instala as extensões DuckDB necessárias durante o build
RUN python -c "import duckdb; con=duckdb.connect(); con.execute('INSTALL httpfs'); con.execute('INSTALL aws'); con.close()"

COPY src/app.py .

CMD ["python", "app.py"]