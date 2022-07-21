import json
import os
import subprocess
import sys
import threading
from contextlib import suppress

import click

DATABASES = {}
THREADS = []
HELPER = 'Executa uma instância do celery / beat / flower pra cada tenant'
PROMPT = """Digite o APP ou seu número correspondente:
    1 - celery
    2 - flower
    3 - beat
    4 - flower/beat"""


@click.command()
@click.option('--application', type=str, prompt=PROMPT, help=HELPER)
def main(application):
    choices = ["celery", "flower", "beat", "flower/beat"]
    with suppress(Exception):
        application = choices[(int(application) - 1)]
    if application not in choices:
        print(f"Opção inválida -> {application}")
        return
    application = "worker" if application == "celery" else application
    try:
        DATABASES = json.loads(os.getenv("DATABASE_URLS", '{}'))

    except Exception as e:
        print("Erro ao processar a variável DATABASES")
        print(e)
        sys.exit(1)
    if not DATABASES:
        print(f"Variával DATABASE_URLS está vazia =>{DATABASES}")
    port = 5566
    for app in application.split("/"):
        for db in DATABASES.items():
            THREADS.append(
                threading.Thread(target=celery_process, args=[*db, app, port])
            )
            port += 1

    for i in range(len(THREADS)):
        THREADS[i].start()


def celery_process(key, value, app, port):
    print(f"Starting {app} from tenant {key}")
    database = json.dumps({"default": value}, indent=4)
    cmd = f"DATABASE_URLS='{database}' celery -A project {app} -l INFO"
    if app == "flower":
        cmd = (
            f"DATABASE_URLS='{database}' celery -A project flower "
            f"--address=0.0.0.0 --port={port} "
            "--basic_auth=$FLOWER_ADMIN_USER:$FLOWER_ADMIN_PASSWORD"
        )
    subprocess.Popen(cmd, shell=True)


if __name__ == "__main__":
    main()
