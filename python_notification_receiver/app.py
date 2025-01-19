from fastapi import FastAPI
import structlog
import uvicorn

log = structlog.get_logger()

app = FastAPI()

@app.post("/notify")
def register_a_notification(body: dict):
    log.info(f'>> Received notification: {body}')
    
    return "OK"

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8100)