# Cifras

Aplicativo Flutter para registrar cifras sem letras. Cadastre músicas com tom,
andamento e fórmula de compasso, organize a estrutura em intro, verso,
pré-refrão, refrão, ponte, solo e final, e distribua os acordes por compassos.

## Identidade visual

- Verde-floresta `#24574C` para marca e ações principais.
- Creme `#FAF7F0` para superfícies, com verde suave `#E7EFE8` nos destaques.
- Âmbar `#F1B85B` para as notas da marca; argila `#8F4F2B` como cor secundária.
- O ícone combina uma pauta musical com duas notas. Seu vetor original está em
  [assets/brand/cifras-icon.svg](assets/brand/cifras-icon.svg).

## Como usar

1. Crie uma cifra e informe o nome da música; artista, tom e BPM são opcionais.
   Escolha também a fórmula de compasso, como 4/4, 3/4, 2/4 ou 6/8 (padrão: 4/4).
2. Abra a música e adicione uma seção.
3. Ao adicionar uma seção, escolha sua fórmula de compasso (o padrão é a fórmula
   da música) e o tipo da seção. Busque cada acorde pelo nome no dicionário e
   distribua-os pelos compassos; compassos
   extras podem ser removidos antes de salvar. Exemplo de acordes separados por
   compasso: `Am G/B | C | F Dm | E7`.
4. Abra **Dicionário de acordes** na biblioteca para buscar acordes e consultar
   seus diagramas de violão ou teclado. Na tela da cifra, também escolha
   **Violão** ou **Teclado** e toque em um acorde para ver sua forma. No violão,
   alterne entre as cinco formas CAGED para acordes maiores e menores.
5. As cifras ficam salvas localmente em SQLite no dispositivo.
6. No menu da biblioteca, use **Exportar JSON** para gerar um backup completo
   das cifras e escolher onde salvar o arquivo `cifras.json`. Use
   **Importar JSON** para selecionar um backup salvo; a importação substitui
   todo o repertório atual após confirmação.

## Executar

```sh
flutter pub get
flutter run
```

## Validar

```sh
flutter analyze
flutter test
```
