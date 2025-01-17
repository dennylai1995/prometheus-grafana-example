from prometheus_client import start_http_server, Counter
import random
import time

REQUEST_COUNT = Counter('app_requests_total', 'Total app requests')

def process_request():
    REQUEST_COUNT.inc()
    time.sleep(random.uniform(0.5, 1.5))
    
if __name__ == "__main__":
    prometheus_cli_port = 8000
    start_http_server(prometheus_cli_port)
    print(f'Prometheus client running on port [{prometheus_cli_port}]')
    while True:
        process_request()