# Cifras

Aplicativo Flutter para registrar cifras sem letras. Cadastre músicas com tom,
andamento e fórmula de compasso, organize a estrutura em intro, verso,
pré-refrão, refrão, ponte, solo e final, e distribua os acordes por compassos.

## Como usar

1. Crie uma cifra e informe o nome da música; artista, tom e BPM são opcionais.
   Escolha também a fórmula de compasso, como 4/4, 3/4, 2/4 ou 6/8 (padrão: 4/4).
2. Abra a música e adicione uma seção.
3. Ao adicionar uma seção, escolha sua fórmula de compasso (o padrão é a fórmula
   da música) e o tipo da seção. Distribua os acordes pelos compassos; compassos
   extras podem ser removidos antes de salvar. Exemplo de acordes separados por
   compasso: `Am G/B | C | F Dm | E7`.
4. As cifras ficam salvas localmente em SQLite no dispositivo.

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
