import io
import zipfile
import requests
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
BRONZE_DIR = BASE_DIR / "data" / "bronze"
BRONZE_DIR.mkdir(parents=True, exist_ok=True)

YEARS = [2023, 2024]
BASE_URL = "https://dados.cvm.gov.br/dados/CIA_ABERTA/DOC/DFP/DADOS/dfp_cia_aberta_{year}.zip"

def download_and_extract_cvm_data(year: int):
    url = BASE_URL.format(year=year)
    print(f"Baixando dados da CVM para o ano {year}...")

    response = requests.get(url, timeout=60)
    response.raise_for_status()

    with zipfile.ZipFile(io.BytesIO(response.content)) as zip_ref:
        target_dir = BRONZE_DIR / str(year)
        target_dir.mkdir(parents=True, exist_ok=True)
        zip_ref.extractall(target_dir)
        print(f"Arquivos de {year} salvos em: {target_dir}")

def main():
    for year in YEARS:
        try:
            download_and_extract_cvm_data(year)
        except Exception as e:
            print(f"Erro ao processar o ano {year}: {e}")

if __name__ == "__main__":
    main()
