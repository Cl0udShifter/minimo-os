<p align="center">
  <img src="assets/minimo-icon.png" width="128" alt="Minimo OS">
</p>

<h1 align="center">Minimo OS</h1>

<p align="center">Hyprland minimalista: uma ilha flutuante e um personagem feliz. Nada além do necessário.</p>

<p align="center"><a href="https://diegolede.github.io/minimo-os-web/">Site oficial</a></p>

---

## O que é

O **Minimo OS** é uma configuração completa de ambiente de desktop para Arch Linux sobre o Hyprland, com uma shell própria desenvolvida em Quickshell (QML). Toda a interface vive em uma única ilha flutuante no topo da tela, acompanhada por um pequeno personagem animado que reage às suas ações.

## Características

- **Ilha dinâmica:** Relógio, áreas de trabalho e status em uma cápsula compacta que se oculta automaticamente e ressurge ao aproximar o cursor. Ao clicar, ela se expande revelando: busca, música, volume, brilho, saturação e atalhos rápidos.
- **Personagem:** Uma esfera preta com olhos que seguem o cursor com projeção esférica real. Ele pisca, respira, ri, pisca um olho, fica tonto, boceja, saúda ao abrir a ilha e dança no ritmo da música.
- **Painéis deslizáveis:** Arraste a ilha da esquerda para a direita para ver os recursos do sistema (CPU, RAM, disco, rede, periféricos), ou da direita para a esquerda para ver os aplicativos em segundo plano na bandeja do sistema (Steam, Discord…), funcionando como a bandeja oculta do Windows 11; um clique os traz de volta para o foco.
- **Notificações:** A ilha exibe as notificações recebidas; elas pausam ao passar o mouse por cima e respeitam o modo Não Perturbe.
- **Modo Dormir:** Quando o computador fica inativo (1, 2 ou 5 minutos) o personagem adormece e exibe as letras "z". Ele acorda imediatamente ao detectar movimento de mouse ou teclado.
- **Lançador central:** `Super + B` abre um buscador centralizado de aplicativos, com navegação rápida via teclado.
- **Gravação de tela:** Botão "Gravar" integrado na ilha (wf-recorder, com gravação de áudio do sistema). Os vídeos são salvos automaticamente em `~/Vídeos/Gravações`.
- **Reprodutor de mídia:** Capa circular de álbum que gira como um vinil enquanto a música toca.
- **Wi-Fi:** Em computadores sem conexão cabeada, a ilha exibe o status da rede atual, força do sinal e as redes próximas disponíveis para conexão com suporte a senha.
- **Configurações:** Janela própria para troca de papel de parede, opções de ocultamento da ilha, animações do personagem, ajuste de monitores (resolução, frequência em Hz e escala com contagem regressiva de segurança) e controle de brilho/saturação por software.

## Capturas de Tela

| Personalização | Tela | Sobre |
|---|---|---|
| ![Personalização](docs/ajustes-personalizacion.png) | ![Tela](docs/ajustes-pantalla.png) | ![Sobre](docs/ajustes-acerca.png) |

## Requisitos

- **Arch Linux** (usuário comum com acesso ao `sudo`).
- **Hyprland 0.56 ou superior** (configuração via API Lua).
- **Pacotes oficiais (o instalador instala automaticamente):** `hyprland xdg-desktop-portal-hyprland hyprpolkitagent quickshell qt6-declarative qt6-svg qt6-wayland pipewire pipewire-pulse wireplumber cava ghostty grim slurp zenity wf-recorder adwaita-fonts networkmanager git`.
- **Opcionais:** `fuzzel wl-clipboard github-cli`.

## Instalação

Manual (recomendado):

```bash
git clone https://github.com/SEU_USUARIO/minimo-os.git ~/Projetos/minimo-os
cd ~/Projetos/minimo-os
./install.sh
```

- `--dry-run`: Executa em modo de simulação sem modificar nada no sistema.
- `--yes`: Aceita todas as confirmações automaticamente.

O instalador é **idempotente**. Ele instala os pacotes necessários, cria um backup de segurança de `~/.config/hypr` em `~/.config/hypr.bak-<data>`, vincula os arquivos de configuração do repositório via symlink, copia `minimo/monitores.lua` apenas na primeira vez (preservando configurações específicas do seu computador), copia os papéis de parede para `~/Imagens/Wallpapers` e ativa o serviço `minimo-shell.service`.

## Desinstalação

```bash
~/Projetos/minimo-os/uninstall.sh
```

Desativa a shell e restaura o último backup de `~/.config/hypr`. Não remove seus pacotes nem seus papéis de parede.

## Configuração e Ajustes

Tudo o que você precisa pode ser alterado na janela de **Configurações** (botão na ilha ou atalho `Super + ,`):

- **Personalização:** papel de parede, ocultar a ilha automaticamente, personagem animado e tempo de espera para dormir.
- **Tela:** resolução, frequência (Hz) e escala por monitor (com reversão de segurança em 15 s se você não confirmar), além de brilho e saturação.
- **Minimo OS:** versão e informações do sistema.

As preferências do usuário ficam salvas em `~/.config/minimo-os/state.json`. A configuração do Hyprland reside em `hypr/` e pode ser customizada livremente.

Comandos úteis via terminal (IPC do Quickshell):

```bash
qs -p ~/Projetos/minimo-os/minimo-shell ipc call launcher toggle
qs -p ~/Projetos/minimo-os/minimo-shell ipc call settings toggle
qs -p ~/Projetos/minimo-os/minimo-shell ipc call recorder toggle
qs -p ~/Projetos/minimo-os/minimo-shell ipc call character list
```

## Estrutura do Projeto

```
minimo-os/
├── install.sh / uninstall.sh   Instalação e desinstalação automatizadas
├── hypr/
│   ├── hyprland.lua            Ponto de entrada do Hyprland
│   ├── minimo.lua              Atalhos específicos da shell
│   └── minimo/                 Aparência, entrada, monitores, regras e atalhos
├── minimo-shell/               Shell gráfica desenvolvida em Quickshell (QML)
│   ├── Island/                 Ilha dinâmica e seus painéis
│   ├── Character/              Personagem animado e reações visuais
│   ├── Launcher/               Lançador de aplicativos central (Super + B)
│   ├── Settings/               Janela de Configurações
│   ├── Wallpaper/              Renderizador de papel de parede
│   ├── Common/                 Estado compartilhado, tema e serviços
│   └── assets/                 Ícones vetoriais em linha
├── systemd/                    Serviço de usuário systemd da shell
├── assets/                     Ícone do sistema e papéis de parede padrão
└── docs/                       Capturas de tela e documentação adicional
```

## Autor

Criado originalmente por **TRN1 (Diego Ledesma)**.
Adaptado e traduzido para Português do Brasil (PT-BR).

## Licença

[MIT](LICENSE) — © 2026 Diego Ledesma (TRN1).
