# Documentação Técnica - App Compras Mobile

## Visão Geral

O **App Compras** é um aplicativo mobile desenvolvido em Flutter para gerenciamento inteligente de produtos e compras. O aplicativo oferece uma interface elegante e moderna baseada em Material Design, com suporte para Android e iOS.

## Arquitetura

### Camadas da Aplicação

```
┌─────────────────────────────────────┐
│          UI Layer (Screens)         │
│  - Home, Products, Lists, Budget    │
│  - Material Design Components       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│        Business Logic Layer         │
│  - Product shortage prediction      │
│  - Budget calculation               │
│  - Alert generation                 │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Data Layer (Models)         │
│  - Product, PurchaseRecord          │
│  - PriceHistory, ShoppingList       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      Persistence Layer (SQLite)     │
│  - DatabaseService                  │
│  - Local SQLite Database            │
└─────────────────────────────────────┘
```

## Telas Implementadas

### 1. Home Screen (Tela Inicial)
- **Propósito**: Dashboard com visão geral do sistema
- **Funcionalidades**:
  - Cards de estatísticas com gradientes elegantes
  - Total de produtos, produtos em falta, estoque total
  - Lista de produtos recentes
  - Botões de ação rápida
  - Pull-to-refresh

### 2. Products Screen (Tela de Produtos)
- **Propósito**: Listagem completa de produtos
- **Funcionalidades**:
  - Lista de todos os produtos cadastrados
  - Informações de estoque, demanda e previsão
  - Status visual (OK ou Precisa Comprar)
  - Navegação para detalhes do produto
  - Floating Action Button para adicionar produto

### 3. Add Product Screen (Adicionar Produto)
- **Propósito**: Cadastro de novos produtos
- **Funcionalidades**:
  - Formulário validado com campos:
    - Nome do produto (obrigatório)
    - Quantidade em estoque
    - Demanda semanal
    - Demanda mensal
    - Preço unitário (opcional)
  - Validação de valores negativos
  - Feedback visual de erros

### 4. Product Detail Screen (Detalhes do Produto)
- **Propósito**: Visualização detalhada e registro de compras
- **Funcionalidades**:
  - Informações completas do produto
  - Indicador visual de status (OK/Crítico)
  - Formulário para registrar compras
  - Histórico de compras com preços
  - Atualização automática de estoque

### 5. Shopping Lists Screen (Listas de Compras)
- **Propósito**: Gerenciamento de listas de compras
- **Funcionalidades**:
  - Lista de todas as listas criadas
  - Status (Ativa/Concluída)
  - Data de criação
  - FAB para criar nova lista

### 6. Create Shopping List Screen (Criar Lista)
- **Propósito**: Criação de novas listas de compras
- **Funcionalidades**:
  - Nome da lista
  - Opção de auto-adicionar produtos em falta
  - Cálculo automático de quantidades necessárias

### 7. Shopping List Detail Screen (Detalhes da Lista)
- **Propósito**: Gerenciamento de itens da lista
- **Funcionalidades**:
  - Orçamento total estimado
  - Lista de itens com quantidades e preços
  - Adicionar/remover produtos
  - Concluir lista e atualizar estoque automaticamente
  - Long press para remover itens

### 8. Budget Screen (Orçamento Mensal)
- **Propósito**: Cálculo de orçamento mensal
- **Funcionalidades**:
  - Header com valor total em gradiente
  - Lista detalhada de produtos necessários
  - Cálculo baseado em demanda mensal e estoque
  - Informações de quantidade e preço por produto

### 9. Alerts Screen (Alertas)
- **Propósito**: Visualização de produtos críticos
- **Funcionalidades**:
  - Classificação por urgência:
    - Crítico (< 1 semana)
    - Urgente (< 2 semanas)
    - Atenção (< 3 semanas)
  - Cores diferenciadas por nível de urgência
  - Semanas restantes até acabar o estoque
  - Navegação direta para produto

## Modelos de Dados

### Product
```dart
- id: int
- name: String
- stockQuantity: double
- weeklyDemand: double
- monthlyDemand: double
- createdAt: DateTime
```

### PurchaseRecord
```dart
- id: int
- productId: int
- quantity: double
- pricePerUnit: double
- totalPrice: double
- purchasedAt: DateTime
```

### PriceHistory
```dart
- id: int
- productId: int
- price: double
- recordedAt: DateTime
```

### ShoppingList
```dart
- id: int
- name: String
- createdAt: DateTime
- isCompleted: bool
```

### ShoppingListItem
```dart
- id: int
- shoppingListId: int
- productId: int
- quantity: double
```

## Design System

### Paleta de Cores

```
Primary Color:    #2c3e50 (Dark Blue)
Success Color:    #27ae60 (Green)
Warning Color:    #f39c12 (Orange)
Danger Color:     #e74c3c (Red)
Info Color:       #3498db (Blue)
Background:       #f5f5f5 (Light Gray)
```

### Gradientes Utilizados

```
Purple-Pink:  #667eea → #764ba2
Pink-Red:     #f093fb → #f5576c
Blue-Cyan:    #4facfe → #00f2fe
```

### Componentes

- **Cards**: Elevação 2, border radius 12
- **Botões**: Elevados com cores semânticas
- **Badges**: Border radius 12, cores contextuais
- **Bottom Navigation**: 5 itens com ícones
- **Forms**: Outlined inputs com validação

## Funcionalidades Inteligentes

### 1. Previsão de Falta
```dart
double? predictShortage() {
  if (weeklyDemand == 0) return null;
  return stockQuantity / weeklyDemand;
}
```

### 2. Necessidade de Compra
```dart
bool needsPurchase({double weeksThreshold = 2}) {
  final shortage = predictShortage();
  if (shortage == null) return false;
  return shortage < weeksThreshold;
}
```

### 3. Cálculo de Orçamento Mensal
- Considera demanda mensal configurada
- Subtrai estoque atual
- Multiplica pelo último preço registrado

### 4. Auto-preenchimento de Listas
- Identifica produtos com estoque baixo
- Calcula quantidade para 4 semanas de estoque
- Adiciona automaticamente à lista

## Navegação

```
Main Navigator (Bottom Navigation)
├── Home
├── Products
│   ├── Add Product
│   └── Product Detail
├── Shopping Lists
│   ├── Create Shopping List
│   └── Shopping List Detail
├── Budget
└── Alerts
```

## Persistência de Dados

- **Banco**: SQLite local
- **Package**: sqflite
- **Localização**: Databases path do dispositivo
- **Nome**: app_compras.db
- **Versão**: 1

## Interações do Usuário

### Gestos
- **Tap**: Navegar, selecionar
- **Long Press**: Deletar itens (shopping list)
- **Pull-to-Refresh**: Atualizar listas
- **Swipe**: Navegação stack (back)

### Feedback Visual
- **SnackBars**: Confirmações e erros
- **CircularProgressIndicator**: Loading states
- **Badges coloridos**: Status de produtos
- **Gradientes**: Cards de estatísticas

## Validações

### Produtos
- Nome obrigatório e não vazio
- Valores numéricos não negativos
- Produtos únicos por nome

### Compras
- Quantidade maior que zero
- Preço não negativo
- Todos os campos obrigatórios

### Listas
- Nome obrigatório
- Ao menos um item para concluir

## Performance

### Otimizações
- Queries otimizadas com índices
- Lazy loading de dados relacionados
- Pull-to-refresh ao invés de auto-refresh
- ListView.builder para listas grandes
- Navegação stack-based eficiente

## Compatibilidade

- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 11+
- **Flutter**: 3.0.0+
- **Dart**: 3.0.0+

## Testes

- Testes unitários para modelos
- Validação de lógica de negócio
- Testes de previsão de falta
- Testes de conversão de dados

## Migração da Versão Web

O aplicativo mantém 100% das funcionalidades da versão web Flask:
- ✅ Mesmos modelos de dados
- ✅ Mesma lógica de negócio
- ✅ Mesmas funcionalidades
- ✅ Interface melhorada para mobile
- ✅ Experiência nativa mobile

## Próximos Passos

1. Adicionar sincronização em nuvem
2. Implementar compartilhamento de listas
3. Scanner de código de barras
4. Modo escuro (dark mode)
5. Notificações push
6. Gráficos e relatórios
