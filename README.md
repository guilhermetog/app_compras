# App de Gestão de Compras 🛒

**Aplicativo mobile** para gerenciamento de produtos e planejamento de compras mensais. Desenvolvido em **Flutter** com interface elegante e moderna. Sistema data-driven com persistência em banco de dados SQLite.

## 📋 Funcionalidades

### Gerenciamento de Produtos
- ✅ Adicionar produtos por nome (cadastro manual)
- ✅ Entidade única de produto com propriedades:
  - Nome do produto
  - Quantidade em estoque
  - Demanda semanal/mensal
  - Registro de compras
  - Histórico de preços
  - Previsão de falta/escassez

### Controle de Estoque
- ✅ Monitoramento de quantidade em estoque
- ✅ Cálculo automático de previsão de falta baseado na demanda
- ✅ Atualização de estoque após compras
- ✅ Histórico completo de compras

### Listas de Compras
- ✅ Criação de listas de compras personalizadas
- ✅ Adição automática de produtos com estoque baixo
- ✅ Adição manual de produtos à lista
- ✅ Cálculo de orçamento estimado por lista
- ✅ Conclusão de lista com atualização automática de estoque

### Orçamento Mensal
- ✅ Cálculo de orçamento mensal baseado em:
  - Produtos indisponíveis/faltantes
  - Demanda mensal configurada
  - Quantidade em estoque atual
  - Histórico de preços

### Sistema de Alertas
- ✅ Alertas automáticos para produtos que precisam ser comprados
- ✅ Classificação por urgência (crítico, urgente, atenção)
- ✅ Previsão de semanas até acabar o estoque

### API REST
- ✅ Endpoints JSON para integração mobile
- ✅ `/api/products` - Lista todos os produtos
- ✅ `/api/alerts` - Lista produtos com estoque baixo

## 🚀 Instalação e Execução

### Requisitos
- Flutter SDK 3.0.0 ou superior
- Android Studio / Xcode (para desenvolvimento Android/iOS)
- Dispositivo móvel ou emulador

### Passo a Passo

1. Clone o repositório:
```bash
git clone https://github.com/guilhermetog/app_compras.git
cd app_compras
```

2. Instale as dependências do Flutter:
```bash
flutter pub get
```

3. Execute o aplicativo:

**No emulador/dispositivo Android:**
```bash
flutter run
```

**No emulador/dispositivo iOS (macOS apenas):**
```bash
flutter run -d ios
```

**Gerar APK para Android:**
```bash
flutter build apk --release
```

**Gerar IPA para iOS:**
```bash
flutter build ios --release
```

### Versão Web Legada (Flask)

Uma versão web anterior em Flask está preservada nos arquivos `app.py`, `routes.py` e `templates/`. Para executá-la:

```bash
pip install -r requirements.txt
python app.py
```

## 📖 Como Usar

### 1. Adicionar Produtos
1. Acesse "Produtos" no menu
2. Clique em "Adicionar Produto"
3. Preencha:
   - Nome do produto
   - Quantidade inicial em estoque
   - Demanda semanal (quanto você consome por semana)
   - Demanda mensal (quanto você consome por mês)
   - Preço unitário (opcional, para cálculo de orçamento)

### 2. Monitorar Estoque
- Na página de produtos, veja o status de cada item
- Produtos com badge vermelho "Precisa Comprar" estão com estoque baixo
- Clique em "Ver Detalhes" para ver histórico completo

### 3. Registrar Compras
1. Acesse os detalhes do produto
2. Use o formulário "Registrar Compra"
3. Informe quantidade e preço
4. O estoque será atualizado automaticamente

### 4. Criar Lista de Compras
1. Acesse "Listas de Compras"
2. Clique em "Nova Lista"
3. Dê um nome à lista
4. Marque a opção para adicionar produtos em falta automaticamente
5. Adicione ou remova itens conforme necessário
6. Ao concluir, o estoque será atualizado

### 5. Consultar Orçamento
- Acesse "Orçamento" no menu
- Veja o valor total necessário para compras do mês
- Detalhamento por produto com cálculos baseados em demanda e estoque

### 6. Ver Alertas
- Acesse "Alertas" no menu
- Veja produtos que precisam de atenção
- Classificação por urgência (crítico < 1 semana, urgente < 2 semanas)

## 🏗️ Arquitetura

### Tecnologias
- **Framework**: Flutter 3.0+
- **Linguagem**: Dart
- **Banco de Dados**: SQLite com sqflite package
- **UI**: Material Design
- **Plataformas**: Android e iOS
- **Persistência**: Data-driven com modelos relacionais

### Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── models/                   # Modelos de dados
│   ├── product.dart
│   ├── purchase_record.dart
│   ├── price_history.dart
│   └── shopping_list.dart
├── screens/                  # Telas do aplicativo
│   ├── home_screen.dart
│   ├── products_screen.dart
│   ├── add_product_screen.dart
│   ├── product_detail_screen.dart
│   ├── shopping_lists_screen.dart
│   ├── create_shopping_list_screen.dart
│   ├── shopping_list_detail_screen.dart
│   ├── budget_screen.dart
│   └── alerts_screen.dart
└── services/                 # Serviços e lógica de negócio
    └── database_service.dart
```

### Modelos de Dados

#### Product (Produto)
- `id`: Identificador único
- `name`: Nome do produto (único)
- `stock_quantity`: Quantidade em estoque
- `weekly_demand`: Demanda semanal
- `monthly_demand`: Demanda mensal
- `created_at`: Data de criação

#### PurchaseRecord (Registro de Compra)
- `id`: Identificador único
- `product_id`: Referência ao produto
- `quantity`: Quantidade comprada
- `price_per_unit`: Preço por unidade
- `total_price`: Valor total
- `purchased_at`: Data da compra

#### PriceHistory (Histórico de Preços)
- `id`: Identificador único
- `product_id`: Referência ao produto
- `price`: Preço registrado
- `recorded_at`: Data do registro

#### ShoppingList (Lista de Compras)
- `id`: Identificador único
- `name`: Nome da lista
- `created_at`: Data de criação
- `is_completed`: Status de conclusão

#### ShoppingListItem (Item da Lista)
- `id`: Identificador único
- `shopping_list_id`: Referência à lista
- `product_id`: Referência ao produto
- `quantity`: Quantidade a comprar

### Funcionalidades Inteligentes

#### Previsão de Falta
```python
def predict_shortage(self):
    """Calcula semanas até acabar o estoque"""
    if self.weekly_demand == 0:
        return None
    return self.stock_quantity / self.weekly_demand
```

#### Necessidade de Compra
```python
def needs_purchase(self, weeks_threshold=2):
    """Verifica se precisa comprar (threshold padrão: 2 semanas)"""
    shortage = self.predict_shortage()
    if shortage is None:
        return False
    return shortage < weeks_threshold
```

## 📱 Características Mobile

### Interface Moderna
- Design elegante baseado em Material Design
- Navegação intuitiva com bottom navigation bar
- Animações fluidas e responsivas
- Temas e cores consistentes

### Funcionalidades Mobile
- **Pull-to-refresh** em todas as listas
- **Gestos nativos** (long press para deletar)
- **Formulários validados** com feedback imediato
- **Diálogos e bottom sheets** para interações rápidas
- **Navegação stack-based** com transições suaves
- **Ícones e badges** para status visual

## 🔒 Segurança

O aplicativo implementa várias camadas de segurança:

- ✅ Validação de entrada em todos os formulários
- ✅ Proteção contra valores negativos/inválidos
- ✅ Tratamento de erros de banco de dados com rollback
- ✅ Configuração segura via variáveis de ambiente
- ✅ SECRET_KEY configurável (não hardcoded)
- ✅ Debug mode desabilitado por padrão em produção

**Nota**: Para uso em produção, sempre configure uma SECRET_KEY forte e única através de variáveis de ambiente.

## 🔮 Possíveis Melhorias Futuras

- [ ] Sincronização em nuvem (Firebase/Supabase)
- [ ] Compartilhamento de listas entre usuários
- [ ] Integração com API pública de produtos
- [ ] Categorização de produtos
- [ ] Gráficos de consumo e tendências
- [ ] Notificações push para alertas
- [ ] Autenticação e múltiplos usuários
- [ ] Exportar listas para PDF
- [ ] Scanner de código de barras
- [ ] Comparação de preços entre compras
- [ ] Modo escuro (dark mode)
- [ ] Suporte a múltiplos idiomas

## 📄 Licença

Este projeto está sob a licença MIT.

## 👤 Autor

Guilherme Togni
