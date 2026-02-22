# Flugo Chat — Desafio Flutter

<p align="center">
  <img src="assets/flugo-logo.png" width="120" alt="Flugo Chat Logo"/>
</p>

<p align="center">
  Sistema de chat em tempo real desenvolvido com <strong>Flutter</strong> e <strong>Firebase</strong>,
  focado em usabilidade, design moderno e arquitetura organizada.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Firebase-Realtime%20DB-FFCA28?logo=firebase" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" />
</p>

---

## 🚀 Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| 🔐 **Autenticação** | Cadastro e login com Firebase Authentication |
| 💬 **Chat em tempo real** | Mensagens instantâneas via Firebase Realtime Database |
| 👥 **Multi-usuário** | Múltiplos usuários no mesmo chat geral |
| 🎨 **Diferenciação visual** | Suas mensagens à direita, dos outros à esquerda |
| ⏱️ **Informações** | Nome, horário e foto de perfil em cada mensagem |
| 📜 **Rolagem automática** | Vai para a última mensagem ao enviar/receber |
| ↩️ **Responder** | Reply em mensagens específicas (estilo WhatsApp) |
| ✏️ **Editar/Apagar** | Edição e exclusão de mensagens próprias |
| 👁️ **Visualizações** | Veja quem leu cada mensagem com nome e foto |
| 🖼️ **Foto de perfil** | Upload e atualização de foto em tempo real |
| 🔔 **Notificações** | Notificações locais para novas mensagens |

---

## 📂 Estrutura de Pastas

```
flugo_chat/
├── android/                        # Configurações nativas Android
├── assets/                         # Imagens, SVGs e ícones do app
│   ├── flugo-logo.png
│   ├── flugo-logo.svg
│   ├── flugo-tranparente.png
│   └── flugo-tranparente.svg
├── lib/
│   ├── main.dart                   # Ponto de entrada do aplicativo
│   ├── app.dart                    # Tema global, cores e configurações
│   ├── firebase_options.dart       # Configurações geradas pelo Firebase CLI
│   ├── core/
│   │   └── formatters.dart         # Utilitários de formatação (datas, horas)
│   └── features/
│       ├── auth/                   # Módulo de Autenticação
│       │   ├── auth_gate.dart      # Redireciona: Login ou Chat conforme sessão
│       │   ├── auth_service.dart   # Integração com Firebase Auth + validações
│       │   ├── login_page.dart     # Tela de login com validação em tempo real
│       │   ├── register_page.dart  # Tela de cadastro com confirmação de senha
│       │   └── profile_page.dart   # Tela de perfil (nome e foto)
│       └── chat/                   # Módulo de Chat
│           ├── chat_page.dart      # Tela principal do chat
│           ├── chat_service.dart   # Integração com Firebase Realtime Database
│           ├── message_model.dart  # Modelo de dados da mensagem e leitura
│           ├── message_bubble.dart # Widget de balão de mensagem customizado
│           └── notification_service.dart # Notificações locais
├── pubspec.yaml                    # Dependências e assets do projeto
└── README.md
```

---

## 🛠️ Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — versão 3.10 ou superior
- [Android Studio](https://developer.android.com/studio) ou VS Code com extensão Flutter
- [Git](https://git-scm.com/)
- Conta no [Firebase](https://firebase.google.com/) com projeto configurado

Para verificar se o ambiente está correto:

```bash
flutter doctor
```

---

## ⚙️ Configuração do Projeto

### 1. Clonar o repositório

```bash
git clone https://github.com/seu-usuario/flugo_chat.git
cd flugo_chat
```

### 2. Instalar dependências

```bash
flutter pub get
```

### 3. Configurar o Firebase

O arquivo `lib/firebase_options.dart` e o `google-services.json` já devem estar configurados para o projeto Firebase vinculado. Caso precise reconfigurar:

```bash
# Instale o Firebase CLI
npm install -g firebase-tools

# Instale o FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure o Firebase no projeto
flutterfire configure
```

---

## 📱 Como Testar no Celular (Depuração USB)

Ideal para desenvolvimento e testes rápidos durante o desenvolvimento:

1. No celular, vá em **Configurações → Sobre o telefone** e toque **7 vezes** em **Número da Versão** para ativar as **Opções do Desenvolvedor**

2. Em **Opções do Desenvolvedor**, ative:
   - ✅ **Depuração USB**
   - ✅ **Instalar via USB**

3. Conecte o celular ao computador via cabo USB e autorize a depuração quando solicitado

4. Verifique se o dispositivo é reconhecido:
   ```bash
   flutter devices
   ```

5. Execute o app:
   ```bash
   flutter run
   ```

---

## 📦 Como Gerar o APK (Para Instalação)

Use este método para gerar um APK e instalar em qualquer celular Android, sem precisar de cabo.

### Passo a passo

**1. Limpar o projeto**
```bash
flutter clean
```

**2. Obter dependências**
```bash
flutter pub get
```

**3. Gerar os ícones do app** *(apenas se alterou o ícone)*
```bash
dart run flutter_launcher_icons
```

**4. Gerar o APK de release**
```bash
flutter build apk --release
```

**5. Localizar o APK gerado**

O arquivo estará em:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Instalar no celular

**Opção A — Via cabo USB:**
```bash
flutter install
```

**Opção B — Transferir o arquivo:**
- Envie o `app-release.apk` por WhatsApp, Google Drive, e-mail ou cabo USB
- No celular, abra o arquivo e toque em **Instalar**
- Se aparecer aviso de segurança, ative **"Instalar apps desconhecidos"** nas configurações

---

## 🔥 Firebase — Configuração necessária

No console do Firebase, certifique-se de ter habilitado:

| Serviço | Configuração |
|---|---|
| **Authentication** | Ativar provedor: E-mail/Senha |
| **Realtime Database** | Criar banco e configurar regras |
| **Storage** | Ativar para upload de fotos de perfil |

### Regras do Realtime Database (desenvolvimento)

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

---

## 🎨 Design

O app utiliza **Dark Mode** como tema padrão com a paleta de cores da Flugo:

| Cor | Hex | Uso |
|---|---|---|
| 🟢 Verde Esmeralda | `#22C55E` | Primária, botões, destaques |
| 🔵 Slate 900 | `#0F172A` | Fundo principal |
| 🔵 Slate 800 | `#1E293B` | Cards e superfícies |
| ⚪ Slate 400 | `#94A3B8` | Textos secundários |
| 🔴 Red 500 | `#EF4444` | Erros e alertas |

---

## 👨‍💻 Autor

Desenvolvido como parte do **Desafio Flutter — Flugo**.