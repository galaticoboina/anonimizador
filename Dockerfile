FROM python:3.8.18-slim-bookworm

WORKDIR /opt/app

# Instalar ferramentas essenciais e dependências
RUN apt-get update && apt-get install -y \
    gcc python3-dev build-essential \
    pandoc git-lfs libreoffice \
    ca-certificates curl gnupg \
    poppler-utils

# Configurar repositório e instalar Node.js 18
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs

# Clonar o repositório auxiliar iris-lfs-storage e fazer pull dos LFS
RUN git clone https://gitlab.com/diogoalmiro/iris-lfs-storage.git
RUN cd iris-lfs-storage && git lfs pull

# Criar ambiente virtual Python
RUN python -m venv env

# Copiar e instalar dependências Python
COPY requirements.txt ./
RUN env/bin/pip install --no-cache-dir --upgrade pip
RUN env/bin/pip install --no-cache-dir -r requirements.txt

# Definir variável ambiente para python no virtualenv
ENV PYTHON_COMMAND=/opt/app/env/bin/python

# Copiar package.json para Node.js
COPY package*.json ./

# Instalar dependências Node.js
RUN npm ci

# Definir variável ambiente para React
ENV PUBLIC_URL="."

# Variáveis de build para o frontend
ARG TITLE="Anonimizador"
ARG VERSION_DATE="01/01/1990"
ARG VERSION_COMMIT="0000000"

# Copiar código da aplicação
COPY . .

# Build da aplicação React
RUN REACT_APP_VERSION_DATE=${VERSION_DATE} REACT_APP_VERSION_COMMIT=${VERSION_COMMIT} REACT_APP_TITLE=${TITLE} npm run build

# Mover modelos para pasta python-cli
RUN mv iris-lfs-storage/model-best/ ./python-cli/
RUN mv iris-lfs-storage/model-gpt/ ./python-cli/

# Expor a porta
EXPOSE 7998

# Comando default para arrancar a app
CMD [ "npm", "run", "proxy" ]
