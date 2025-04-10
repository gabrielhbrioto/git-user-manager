
# README - Git User Manager 🚀

Bem-vindo ao **Git User Manager**, um script Bash simples e eficiente para gerenciar usuários Git em seu ambiente local. Ele permite que você alterne rapidamente entre usuários, configure novas credenciais e mantenha suas informações seguras usando criptografia AES-256.

---

## 🛠️ Funcionalidades

- **Adicionar usuários Git** com nome, e-mail e Personal Access Token (PAT).
- **Alternar entre usuários** Git configurados.
- **Listar usuários salvos**.
- **Remover usuários** do sistema.
- **Alterar a senha de criptografia** usada para proteger suas informações.
- **Armazenamento seguro de credenciais** com criptografia AES-256 e um tempo limite de sessão configurável.

---

## 📋 Requisitos

1. **Linux ou outro sistema que suporte Bash.**
2. **OpenSSL** instalado.
3. **Git** configurado no sistema.

---

## 📦 Instalação

1. Clone este repositório ou copie o script para o seu ambiente local:
   ```bash
   git clone https://github.com/seu-usuario/git-user-manager.git
   cd git-user-manager
   ```

2. Conceda permissão de execução ao script:
   ```bash
   chmod +x git-user-manager.sh
   ```

3. Opcional: Mova o script para um diretório do sistema para uso global:
   ```bash
   sudo mv git-user-manager.sh /usr/local/bin/git_user_manager
   ```

---

## 🗑️ Desinstalação

Se você apenas clonou o repositório, basta excluir a pasta:

```
rm -rf git-user-manager
```
Se você movimentou o script para um diretório do sistema (`como /usr/local/bin`) para uso global, remova o arquivo com:

```
sudo rm /usr/local/bin/git_user_manager
```

Pronto! O `git_user_manager` foi completamente removido do seu sistema.

---

## ⚙️ Uso

O Git User Manager possui diversos comandos para gerenciar seus usuários. Veja a lista completa:

### **Adicionar Usuário**
Adicione um novo usuário com nome, e-mail e PAT:
```bash
git_user_manager add user <username>
```

### **Alterar Usuário**
Altere para um usuário Git configurado:
```bash
git_user_manager alter user <username>
```

### **Exibir Usuário Atual**
Exibe o usuário Git atualmente configurado:
```bash
git_user_manager show user
```

### **Listar Usuários**
Lista todos os usuários salvos no sistema:
```bash
git_user_manager list users
```

### **Remover Usuário**
Remove um usuário do sistema:
```bash
git_user_manager remove user <username>
```

### **Alterar Senha de Criptografia**
Altere a senha usada para proteger seus dados:
```bash
git_user_manager change password
```

---

## 🔒 Segurança

- As credenciais dos usuários são protegidas usando **criptografia AES-256**.
- A senha de criptografia pode ser alterada a qualquer momento.
- As credenciais são armazenadas em um arquivo criptografado, com um tempo limite de sessão configurável (5 minutos por padrão, com a sessão reiniciada a cada uso do comando).

---

## 🌟 Exemplo de Uso

1. **Adicionar um novo usuário:**
   ```bash
   git_user_manager add user junior
   ```

2. **Alternar para o usuário `gabrielhbrioto`:**
   ```bash
   git_user_manager alter user junior
   ```

3. **Listar todos os usuários salvos:**
   ```bash
   git_user_manager list users
   ```

---

## 🛡️ Cuidados

- **Personal Access Tokens (PATs):** Certifique-se de usar tokens ao invés de senhas no GitHub para autenticação.
- **Senha de Criptografia:** Escolha uma senha forte e única para proteger seus dados.

---

## 📜 Licença

Este projeto é de uso pessoal e distribuído sob a licença MIT. Sinta-se à vontade para modificá-lo e adaptá-lo às suas necessidades. 😊

---

## 📧 Contato

Se você tiver dúvidas ou sugestões, sinta-se à vontade para entrar em contato:

- **Autor:** Gabriel Henrique Brioto
- **E-mail:** gabriel.h.brioto@gmail.com

Happy coding! 🚀
