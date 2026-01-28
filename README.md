# App de Gestão de Compras 🛒

Aplicativo web para gerenciamento de produtos e planejamento de compras mensais. Sistema data-driven com persistência em banco de dados SQLite.

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
- Python 3.8 ou superior
- pip (gerenciador de pacotes Python)

### Passo a Passo

1. Clone o repositório:
```bash
git clone https://github.com/guilhermetog/app_compras.git
cd app_compras
```

2. Instale as dependências:
```bash
pip install -r requirements.txt
```

3. (Opcional) Configure variáveis de ambiente:
```bash
export SECRET_KEY="sua-chave-secreta-aqui"
export FLASK_DEBUG=true  # Apenas para desenvolvimento
```

4. Execute o aplicativo:
```bash
python app.py
```

5. Acesse no navegador:
```
http://localhost:5000
```

### Configuração de Produção

Para ambientes de produção, configure as seguintes variáveis de ambiente:
- `SECRET_KEY`: Chave secreta para sessões (obrigatório)
- `FLASK_DEBUG`: False (padrão)
- `FLASK_HOST`: 0.0.0.0 (padrão)
- `FLASK_PORT`: 5000 (padrão)

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
- **Backend**: Python Flask
- **Banco de Dados**: SQLite com SQLAlchemy ORM
- **Frontend**: HTML5 + CSS3 (responsivo)
- **Persistência**: Data-driven com modelos relacionais

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

## 📱 Expansão Mobile

O sistema já possui endpoints API REST que podem ser consumidos por aplicativos mobile:

- `GET /api/products` - Lista de produtos com status
- `GET /api/alerts` - Produtos que precisam de compra

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

- [ ] Integração com API pública de produtos (Google Shopping, etc)
- [ ] Categorização de produtos
- [ ] Gráficos de consumo e tendências
- [ ] Notificações push/email para alertas
- [ ] Múltiplos usuários e autenticação
- [ ] Exportar listas para PDF/Excel
- [ ] Código de barras/QR code para produtos
- [ ] Comparação de preços entre compras

## 📄 Licença

Este projeto está sob a licença MIT.

## 👤 Autor

Guilherme Togni
