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
   da música) e o tipo da seção. Distribua os acordes pelos compassos; compassos
   extras podem ser removidos antes de salvar. Exemplo de acordes separados por
   compasso: `Am G/B | C | F Dm | E7`.
4. As cifras ficam salvas localmente em SQLite no dispositivo.
5. No Android, toque em **Sincronizar com Google Drive** para enviar ou
   restaurar o banco. Na primeira sincronização e quando os dois lados tiverem
   alterações, escolha qual versão manter; a outra versão será substituída.

### Configurar o Google Drive (Android)

1. No Google Cloud Console, crie ou selecione um projeto e habilite a **Google
   Drive API**.
2. Configure a tela de consentimento OAuth e crie clientes OAuth para Android
   (application ID definido em `android/app/build.gradle.kts` e SHA-1 da chave
   de assinatura) e Web.
3. Crie um arquivo `.env` na raiz do projeto com o client ID OAuth Web:

   ```json
   {
     "GOOGLE_SERVER_CLIENT_ID": "SEU_CLIENT_ID_WEB"
   }
   ```

   O arquivo `.env` é ignorado pelo Git. Inicie o app com:

   ```sh
   flutter run --dart-define-from-file=.env
   ```

4. Para distribuição, cadastre também a impressão digital SHA-1 da chave de
   produção. O client ID é público; não coloque client secrets no app.

O aplicativo usa o escopo `drive.file` e grava um arquivo `cifras.db` na raiz
do Drive da conta escolhida. A autenticação e a habilitação da API precisam
estar configuradas no Google Cloud antes de sincronizar.

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
