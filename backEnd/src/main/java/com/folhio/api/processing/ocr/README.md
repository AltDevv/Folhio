# OCR no backend Java

Este pacote contem a ponte entre Spring Boot e Python.

## Classe principal

`ReconhecimentoPythonClient`

Ela:

1. localiza a pasta do backend;
2. encontra `backEnd/document-processing/ocr-python/.venv/Scripts/python.exe`;
3. chama `backEnd/document-processing/ocr-python/scripts/run_ocr.py`;
4. le o JSON gerado;
5. converte cada item em `ItemTextoOcr`.

## O Java treina modelo?

Não.

O Java consome modelos que foram preparados na pasta `backEnd/document-processing/ocr-python`.
O treinamento fica separado para não misturar dependencias de IA com Spring Boot.

## Caminhos esperados

```text
Folhio/
  backEnd/
    document-processing/
      ocr-python/
        .venv/Scripts/python.exe
        scripts/run_ocr.py
        config/ocr_models.json
  front/
```

## Como usar em um service Java

```java
List<ItemTextoOcr> items = reconhecimentoPythonClient.reconhecer(imagePath);
for (ItemTextoOcr item : items) {
    System.out.println(item.text());
}
```

Depois disso, outro service pode transformar os textos em DOCX, PDF pesquisável ou outro formato.


