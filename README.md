# App Minhas Viagens - Mapas e Geolocalização

Aplicativo Flutter que permite ao usuário marcar locais no mapa, buscar regiões por texto, favoritar viagens, visualizar informações detalhadas de localização (cidade, estado, país, CEP, etc.), e salvar esses locais manualmente.

Conta com funcionalidades de:

• Geolocalização

• Busca textual por cidade, estado e país

• Marcação de pontos no mapa com Flutter Map (OpenStreetMap)

• Tema escuro/claro

• Filtragem em tempo real

• Favoritos (em memória)

• Interface intuitiva e moderna

## Funcionalidades:
• Marcar local manualmente tocando no mapa

• Buscar país, cidade ou estado por texto (usando Nominatim)

• Obter endereço via reverse geocoding

• Favoritar viagens

• Alternar tema claro/escuro

• Filtro por nome, cidade, estado ou país

• Deletar viagens

• Ver localização atual no mapa

## Tecnologias Utilizadas:

• Flutter:	Para o framework de interface

• Dart:	Linguagem principal do app

• Geolocator:	Obtenção de localização do dispositivo

• http:	Requisições REST com API

• flutter_map: 	Exibição do mapa com OpenStreetMap

• latlong2:	Suporte a coordenadas geográficas

## Dependências:
Adicione ao seu pubspec.yaml:

    dependencies:
      flutter:
        sdk: flutter
      http: ^0.13.6
      flutter_map: ^6.1.0
      geolocator: ^11.0.0
      latlong2: ^0.9.0
E execute:


    flutter pub get
## Permissões Necessárias

### Android

Abra android/app/src/main/AndroidManifest.xml e adicione:


    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.INTERNET"/>

## Como Executar o Projeto
### Localmente

    flutter run

### Web
Compile para web:


    flutter build web

Isso vai gerar os arquivos em: build/web/
Para testar localmente:

    flutter serve

Ou suba a pasta build/web para Netlify, GitHub Pages ou Vercel.

## Testes Visuais:

• Ao iniciar o app, a splash screen é exibida

• Clique no botão "+" para abrir o mapa

• Toque no mapa ou busque um local por texto

• Clique em "Salvar local" ou no botão de check (✔️)

• O local será adicionado à lista com nome, endereço e coordenadas

• Use a barra de busca para filtrar

• Clique na estrela para favoritar

## Video:

https://github.com/user-attachments/assets/be6d2ff6-a9ca-4c4e-9efb-1261ccee2700

 ## Link para testar a versão web:

https://melodic-truffle-afad02.netlify.app/
