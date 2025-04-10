#!/bin/bash

#caminho para o arquivo temporário de sessão
TEMP_SESSION_FILE="/tmp/git_users_manager_session"

# Tempo limite em segundos (5 minutos)
SESSION_TIMEOUT=300 

# Caminho para o arquivo de configuração
CONFIG_FILE="$HOME/.git_users.conf"
ENCRYPTED_CONFIG_FILE="$HOME/.git_users.conf.enc"

# Caminho para os arquivos do Git
GIT_CREDENTIALS_FILE="$HOME/.git-credentials"
ENCRYPTED_CREDENTIALS_FILE="$HOME/.git-credentials.enc"

# Senha para criptografia (inicialmente configurada)
ENCRYPTION_KEY=""

# Função para salvar a senha de sessão
function save_session {
    local password=$1
    echo "$(date +%s) $password" > "$TEMP_SESSION_FILE"
    chmod 600 "$TEMP_SESSION_FILE" # Define permissões seguras
}

# Função para criptografar um arquivo
function encrypt_file {
    local decrypted_file=$1
    local encrypted_file=$2
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$decrypted_file" -out "$encrypted_file" -k "$ENCRYPTION_KEY"
    rm -f "$decrypted_file" # Remove o arquivo original
}

function get_encryption_key {
    if ! load_session; then
        read -sp "Digite a senha: " ENCRYPTION_KEY
        echo
        save_session "$ENCRYPTION_KEY"
    fi
}

# Função para descriptografar um arquivo
function decrypt_file {
    local encrypted_file=$1
    local decrypted_file=$2
    get_encryption_key
    # Testa se a senha está correta antes de descriptografar
    if ! openssl enc -aes-256-cbc -pbkdf2 -d -in "$encrypted_file" -k "$ENCRYPTION_KEY" -out "$decrypted_file" 2>/dev/null; then
        echo "Erro: Senha incorreta"
        rm -f $TEMP_SESSION_FILE
        rm -f "$decrypted_file" # Remove o arquivo original
        exit 1
    fi
}

# Função para carregar a senha de sessão
function load_session {
    if [[ -f "$TEMP_SESSION_FILE" ]]; then
        local current_time=$(date +%s)
        local session_time
        local saved_password

        read session_time saved_password < "$TEMP_SESSION_FILE"

        # Verifica se o token ainda está dentro do limite de tempo
        if (( current_time - session_time <= SESSION_TIMEOUT )); then
            ENCRYPTION_KEY="$saved_password"
            save_session "$ENCRYPTION_KEY"
            return 0
        fi
    fi

    # Se o token não for válido, remove o arquivo temporário
    rm -f "$TEMP_SESSION_FILE"
    return 1
}

# Função para exibir ajuda
function show_help {
    echo "Uso:"
    echo "  alter user <username>          - Altera o usuário Git."
    echo "  add user <username>            - Adiciona um novo usuário Git."
    echo "  remove user <username>         - Remove um usuário Git."
    echo "  show user                      - Exibe o usuário Git configurado."
    echo "  change password     - Altera a senha usada na criptografia."
    echo "  list users                     - Lista todos os usuários salvos."
}

# Função para adicionar um novo usuário
function add_user {
    local username=$1

    # Verifica se o arquivo criptografado existe
    if [[ ! -s "$ENCRYPTED_CONFIG_FILE" ]]; then
        rm -f "$ENCRYPTED_CONFIG_FILE"  # Remove o arquivo
    fi

    # Verifica se o arquivo dcriptografado existe e se o arquivo de configuração está vazio
    if [[ (! -f "$ENCRYPTED_CONFIG_FILE") && (! -f "$CONFIG_FILE") ]]; then

        # Cria o arquivo de configuração
        touch "$ENCRYPTED_CONFIG_FILE"

        # Solicita a senha de criptografia
        read -sp "Digite a senha a ser usada na criptografia dos seus dados: " password
        echo
        read -sp "Confirme a senha: " confirm_password
        echo

        # Valida as senhas fornecidas
        if [[ "$password" != "$confirm_password" ]]; then
            echo "Erro: As senhas não coincidem."
            exit 1
        fi

        # Atualiza a senha de criptografia
        ENCRYPTION_KEY="$password"
    else

        decrypt_file "$ENCRYPTED_CONFIG_FILE" "$CONFIG_FILE"

        # Verifica se o usuário já existe no arquivo
        if grep -q "^$username " "$CONFIG_FILE"; then
            echo "Erro: O usuário '$username' já existe no arquivo de configuração."
            encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"
            exit 1
        fi
    fi

    # Solicita as informações do novo usuário
    echo "Adicionando um novo usuário Git: $username"
    read -p "Digite o e-mail do novo usuário: " email
    read -sp "Digite o personal acess token(PAT): " password
    echo

    # Valida as informações fornecidas
    if [[ -z "$email" || -z "$password" ]]; then
        echo "Erro: E-mail ou senha inválidos."
        encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"
        exit 1
    fi

    # Adiciona as informações ao arquivo de configuração
    echo "$username $email $password" >> "$CONFIG_FILE"
    encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"
    echo "Usuário '$username' adicionado com sucesso!"
}

# Função para alterar o usuário Git
function alter_user {
    local username=$1

    # Verifica se o arquivo criptografado existe ou está vazio
    if [[ ((! -f "$ENCRYPTED_CONFIG_FILE")) || (! -s "$ENCRYPTED_CONFIG_FILE") ]]; then
        rm -f "$ENCRYPTED_CONFIG_FILE"  # Remove o arquivo
        echo "Nenhum usuário Git encontrado. Utilize o comando \"add user <username>\" para adicionar um novo usuário."
        exit 1
    fi

    decrypt_file "$ENCRYPTED_CONFIG_FILE" "$CONFIG_FILE"

    # Busca o e-mail e senha no arquivo de configuração
    USER_INFO=$(grep "^$username " "$CONFIG_FILE")

    if [[ -z "$USER_INFO" ]]; then
        echo "Erro: Usuário '$username' não encontrado no arquivo de configuração."
        encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"
        exit 1
    fi

    # Extrai e-mail e senha
    EMAIL=$(echo "$USER_INFO" | awk '{print $2}')
    PASSWORD=$(echo "$USER_INFO" | awk '{print $3}')

    # Atualiza o arquivo .gitconfig
    echo "Atualizando o usuário Git no arquivo .gitconfig..."
    git config --global user.name "$username"
    git config --global user.email "$EMAIL"

    # Atualiza o arquivo .git-credentials
    echo "Atualizando o arquivo .git-credentials..."
    echo "https://${username}:${PASSWORD}@github.com" > "$GIT_CREDENTIALS_FILE"
    encrypt_file "$GIT_CREDENTIALS_FILE" "$ENCRYPTED_CREDENTIALS_FILE"


    echo "Usuário Git alterado para:"
    echo "  Nome: $username"
    echo "  E-mail: $EMAIL"
}

# Função para exibir o usuário Git atualmente configurado
function show_user {
    local username=$(git config --global user.name)
    local email=$(git config --global user.email)

    # Checa se o usuário Git está configurado corretamente
    if [[ -z "$username" || -z "$email" ]]; then
        echo "Nenhum usuário Git configurado no momento."
    else
        echo "Usuário Git configurado:"
        echo "  Nome: $username"
        echo "  E-mail: $email"
    fi
}

# Função para alterar a senha de criptografia
function change_encryption_password {

    # Verifica se o arquivo criptografado existe ou está vazio
    if [[ ((! -f "$ENCRYPTED_CONFIG_FILE")) || (! -s "$ENCRYPTED_CONFIG_FILE") ]]; then
        rm -f "$ENCRYPTED_CONFIG_FILE"  # Remove o arquivo
        echo "Nenhum usuário Git encontrado. Utilize o comando \"add user <username>\" para adicionar um novo usuário."
        exit 1
    fi

    decrypt_file "$ENCRYPTED_CONFIG_FILE" "$CONFIG_FILE"

    # Solicita a nova senha
    read -sp "Digite a nova senha: " new_password
    echo
    read -sp "Confirme a nova senha: " confirm_password
    echo

    # Valida as senhas fornecidas
    if [[ "$new_password" != "$confirm_password" ]]; then
        echo "Erro: As senhas não coincidem."
        exit 1
    fi

    # Atualiza a senha de criptografia
    ENCRYPTION_KEY="$new_password"

    # Recriptografa os arquivos com a nova senha
    encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"
    rm -f "$TEMP_SESSION_FILE" # Remove o arquivo de sessão

    echo "Senha de criptografia alterada com sucesso!"
}

# Função para listar todos os usuários salvos
function list_users {

    # Verifica se o arquivo criptografado existe ou está vazio
    if [[ ((! -f "$ENCRYPTED_CONFIG_FILE")) || (! -s "$ENCRYPTED_CONFIG_FILE") ]]; then
        rm -f "$ENCRYPTED_CONFIG_FILE"  # Remove o arquivo
        echo "Nenhuma senha configurada. Utilize o comando \"add user <username>\" para adicionar um novo usuário e configurar uma senha."
        exit 1
    fi

    decrypt_file "$ENCRYPTED_CONFIG_FILE" "$CONFIG_FILE"

    # Lista os usuários salvos
    echo "Usuários salvos:"
    awk '{print $1}' "$CONFIG_FILE"

    # Recriptografa o arquivo
    encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"

}

# Função para remover um usuário
function remove_user {
    local username=$1

    # Verifica se o arquivo criptografado existe ou está vazio
    if [[ ((! -f "$ENCRYPTED_CONFIG_FILE")) || (! -s "$ENCRYPTED_CONFIG_FILE") ]]; then
        rm -f "$ENCRYPTED_CONFIG_FILE"  # Remove o arquivo
        echo "Nenhum usuário Git encontrado. Utilize o comando \"add user <username>\" para adicionar um novo usuário."
        exit 1
    fi

    decrypt_file "$ENCRYPTED_CONFIG_FILE" "$CONFIG_FILE"

    # Verifica se o usuário existe no arquivo
    if ! grep -q "^$username " "$CONFIG_FILE"; then
        echo "Erro: Usuário '$username' não encontrado no arquivo de configuração."
        encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"
        exit 1
    fi

    # Remove o usuário do arquivo
    sed -i "/^$username /d" "$CONFIG_FILE"
    local current_username=$(git config --global user.name)

    if [[ "$username" = "$current_username" ]]; then
        echo "sinal"
        git config --global --unset user.name
        git config --global --unset user.email
    fi

    # Recriptografa o arquivo
    encrypt_file "$CONFIG_FILE" "$ENCRYPTED_CONFIG_FILE"

    echo "Usuário '$username' removido com sucesso!"
}

# Certifique-se de que pelo menos um comando foi fornecido
if [[ "$#" -lt 2 ]]; then
    show_help
    exit 1
fi

# Comando principal
COMMAND="$1 $2"

# Executa o comando correspondente
case "$COMMAND" in
    "alter user")
        if [[ -z "$3" ]]; then
            echo "Erro: Nome de usuário não especificado."
            show_help
            exit 1
        fi
        alter_user "$3"
        ;;
    "add user")
        if [[ -z "$3" ]]; then
            echo "Erro: Nome de usuário não especificado."
            show_help
            exit 1
        fi
        add_user "$3"
        ;;
    "remove user")
        if [[ -z "$3" ]]; then
            echo "Erro: Nome de usuário não especificado."
            show_help
            exit 1
        fi
        remove_user "$3"
        ;;
    "show user")
        show_user
        ;;
    "change password")
        change_encryption_password
        ;;
    "list users")
        list_users
        ;;
    *)
        echo "Erro: Comando inválido."
        show_help
        exit 1
        ;;
esac