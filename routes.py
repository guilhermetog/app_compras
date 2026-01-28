from flask import render_template, request, redirect, url_for, flash, jsonify
from app import app, db, Product, PurchaseRecord, PriceHistory, ShoppingList, ShoppingListItem
from datetime import datetime

# Constants
DEFAULT_WEEKS_THRESHOLD = 2  # Alert threshold for low stock (weeks)
WEEKS_TO_STOCK = 4  # Default weeks of stock to maintain


@app.route('/')
def index():
    """Home page showing all products."""
    products = Product.query.all()
    low_stock_count = sum(1 for p in products if p.needs_purchase())
    return render_template('index.html', products=products, low_stock_count=low_stock_count)


@app.route('/products')
def products():
    """List all products with their details."""
    all_products = Product.query.all()
    return render_template('products.html', products=all_products)


@app.route('/product/add', methods=['GET', 'POST'])
def add_product():
    """Add a new product."""
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        
        # Validate name
        if not name:
            flash('Nome do produto é obrigatório!', 'error')
            return redirect(url_for('add_product'))
        
        # Validate numeric inputs
        try:
            stock_quantity = float(request.form.get('stock_quantity', 0))
            weekly_demand = float(request.form.get('weekly_demand', 0))
            monthly_demand = float(request.form.get('monthly_demand', 0))
            
            if stock_quantity < 0 or weekly_demand < 0 or monthly_demand < 0:
                flash('Valores não podem ser negativos!', 'error')
                return redirect(url_for('add_product'))
        except (ValueError, TypeError):
            flash('Valores inválidos fornecidos!', 'error')
            return redirect(url_for('add_product'))
        
        initial_price = request.form.get('price')
        
        # Check if product already exists
        existing_product = Product.query.filter_by(name=name).first()
        if existing_product:
            flash(f'Produto "{name}" já existe!', 'error')
            return redirect(url_for('add_product'))
        
        try:
            # Create new product
            product = Product(
                name=name,
                stock_quantity=stock_quantity,
                weekly_demand=weekly_demand,
                monthly_demand=monthly_demand
            )
            db.session.add(product)
            db.session.commit()
            
            # Add initial price if provided
            if initial_price:
                try:
                    price_value = float(initial_price)
                    if price_value < 0:
                        flash('Preço não pode ser negativo!', 'error')
                        return redirect(url_for('add_product'))
                    
                    price_history = PriceHistory(
                        product_id=product.id,
                        price=price_value
                    )
                    db.session.add(price_history)
                    db.session.commit()
                except (ValueError, TypeError):
                    flash('Preço inválido!', 'error')
                    return redirect(url_for('add_product'))
            
            flash(f'Produto "{name}" adicionado com sucesso!', 'success')
            return redirect(url_for('products'))
        except Exception as e:
            db.session.rollback()
            flash(f'Erro ao adicionar produto: {str(e)}', 'error')
            return redirect(url_for('add_product'))
    
    return render_template('add_product.html')


@app.route('/product/<int:product_id>')
def product_detail(product_id):
    """View product details including history."""
    product = Product.query.get_or_404(product_id)
    return render_template('product_detail.html', product=product)


@app.route('/product/<int:product_id>/update', methods=['POST'])
def update_product(product_id):
    """Update product stock and demand."""
    product = Product.query.get_or_404(product_id)
    
    try:
        if 'stock_quantity' in request.form:
            stock_quantity = float(request.form.get('stock_quantity'))
            if stock_quantity < 0:
                flash('Estoque não pode ser negativo!', 'error')
                return redirect(url_for('product_detail', product_id=product_id))
            product.stock_quantity = stock_quantity
            
        if 'weekly_demand' in request.form:
            weekly_demand = float(request.form.get('weekly_demand'))
            if weekly_demand < 0:
                flash('Demanda não pode ser negativa!', 'error')
                return redirect(url_for('product_detail', product_id=product_id))
            product.weekly_demand = weekly_demand
            
        if 'monthly_demand' in request.form:
            monthly_demand = float(request.form.get('monthly_demand'))
            if monthly_demand < 0:
                flash('Demanda não pode ser negativa!', 'error')
                return redirect(url_for('product_detail', product_id=product_id))
            product.monthly_demand = monthly_demand
        
        db.session.commit()
        flash(f'Produto "{product.name}" atualizado!', 'success')
    except (ValueError, TypeError):
        flash('Valores inválidos fornecidos!', 'error')
    except Exception as e:
        db.session.rollback()
        flash(f'Erro ao atualizar produto: {str(e)}', 'error')
    
    return redirect(url_for('product_detail', product_id=product_id))


@app.route('/product/<int:product_id>/purchase', methods=['POST'])
def record_purchase(product_id):
    """Record a purchase for a product."""
    product = Product.query.get_or_404(product_id)
    
    try:
        quantity = float(request.form.get('quantity'))
        price_per_unit = float(request.form.get('price_per_unit'))
        
        if quantity <= 0 or price_per_unit < 0:
            flash('Quantidade deve ser positiva e preço não pode ser negativo!', 'error')
            return redirect(url_for('product_detail', product_id=product_id))
        
        total_price = quantity * price_per_unit
        
        # Create purchase record
        purchase = PurchaseRecord(
            product_id=product_id,
            quantity=quantity,
            price_per_unit=price_per_unit,
            total_price=total_price
        )
        db.session.add(purchase)
        
        # Update stock
        product.stock_quantity += quantity
        
        # Add to price history
        price_history = PriceHistory(
            product_id=product_id,
            price=price_per_unit
        )
        db.session.add(price_history)
        
        db.session.commit()
        flash(f'Compra registrada para "{product.name}"!', 'success')
    except (ValueError, TypeError):
        flash('Valores inválidos fornecidos!', 'error')
    except Exception as e:
        db.session.rollback()
        flash(f'Erro ao registrar compra: {str(e)}', 'error')
    
    return redirect(url_for('product_detail', product_id=product_id))


@app.route('/shopping-lists')
def shopping_lists():
    """View all shopping lists."""
    lists = ShoppingList.query.order_by(ShoppingList.created_at.desc()).all()
    return render_template('shopping_lists.html', lists=lists)


@app.route('/shopping-list/create', methods=['GET', 'POST'])
def create_shopping_list():
    """Create a new shopping list."""
    if request.method == 'POST':
        name = request.form.get('name')
        auto_add = request.form.get('auto_add') == 'on'
        
        # Create shopping list
        shopping_list = ShoppingList(name=name)
        db.session.add(shopping_list)
        db.session.commit()
        
        # Auto-add products that need purchase
        if auto_add:
            products = Product.query.all()
            for product in products:
                if product.needs_purchase():
                    # Calculate quantity needed for WEEKS_TO_STOCK weeks
                    shortage = product.predict_shortage()
                    if shortage is not None:
                        quantity_needed = max(0, (WEEKS_TO_STOCK * product.weekly_demand) - product.stock_quantity)
                        if quantity_needed > 0:
                            item = ShoppingListItem(
                                shopping_list_id=shopping_list.id,
                                product_id=product.id,
                                quantity=quantity_needed
                            )
                            db.session.add(item)
            db.session.commit()
        
        flash(f'Lista de compras "{name}" criada!', 'success')
        return redirect(url_for('shopping_list_detail', list_id=shopping_list.id))
    
    return render_template('create_shopping_list.html')


@app.route('/shopping-list/<int:list_id>')
def shopping_list_detail(list_id):
    """View shopping list details."""
    shopping_list = ShoppingList.query.get_or_404(list_id)
    products_not_in_list = []
    
    # Get products not in this list
    existing_product_ids = [item.product_id for item in shopping_list.items]
    products_not_in_list = Product.query.filter(~Product.id.in_(existing_product_ids)).all() if existing_product_ids else Product.query.all()
    
    return render_template('shopping_list_detail.html', 
                         shopping_list=shopping_list,
                         products_not_in_list=products_not_in_list)


@app.route('/shopping-list/<int:list_id>/add-item', methods=['POST'])
def add_item_to_list(list_id):
    """Add an item to a shopping list."""
    shopping_list = ShoppingList.query.get_or_404(list_id)
    
    product_id = int(request.form.get('product_id'))
    quantity = float(request.form.get('quantity'))
    
    # Check if item already exists
    existing_item = ShoppingListItem.query.filter_by(
        shopping_list_id=list_id,
        product_id=product_id
    ).first()
    
    if existing_item:
        existing_item.quantity += quantity
    else:
        item = ShoppingListItem(
            shopping_list_id=list_id,
            product_id=product_id,
            quantity=quantity
        )
        db.session.add(item)
    
    db.session.commit()
    flash('Item adicionado à lista!', 'success')
    return redirect(url_for('shopping_list_detail', list_id=list_id))


@app.route('/shopping-list/<int:list_id>/complete', methods=['POST'])
def complete_shopping_list(list_id):
    """Mark shopping list as completed and update stock."""
    shopping_list = ShoppingList.query.get_or_404(list_id)
    
    # Update stock for each item
    for item in shopping_list.items:
        product = Product.query.get(item.product_id)
        if product:
            product.stock_quantity += item.quantity
    
    shopping_list.is_completed = True
    db.session.commit()
    
    flash('Lista de compras concluída e estoque atualizado!', 'success')
    return redirect(url_for('shopping_lists'))


@app.route('/budget')
def monthly_budget():
    """Calculate monthly budget based on demand and stock."""
    products = Product.query.all()
    budget_items = []
    total_budget = 0.0
    
    for product in products:
        if product.monthly_demand > 0:
            # Calculate how much we need to buy this month
            quantity_needed = max(0, product.monthly_demand - product.stock_quantity)
            if quantity_needed > 0:
                price = product.get_latest_price()
                item_total = quantity_needed * price
                total_budget += item_total
                
                budget_items.append({
                    'product': product,
                    'quantity_needed': quantity_needed,
                    'price': price,
                    'total': item_total
                })
    
    return render_template('budget.html', 
                         budget_items=budget_items,
                         total_budget=total_budget)


@app.route('/alerts')
def alerts():
    """View products that need attention."""
    products = Product.query.all()
    low_stock_products = [p for p in products if p.needs_purchase()]
    
    return render_template('alerts.html', products=low_stock_products)


# API endpoints for potential mobile integration
@app.route('/api/products')
def api_products():
    """API endpoint to get all products."""
    products = Product.query.all()
    return jsonify([{
        'id': p.id,
        'name': p.name,
        'stock_quantity': p.stock_quantity,
        'weekly_demand': p.weekly_demand,
        'monthly_demand': p.monthly_demand,
        'needs_purchase': p.needs_purchase(),
        'latest_price': p.get_latest_price()
    } for p in products])


@app.route('/api/alerts')
def api_alerts():
    """API endpoint to get products needing purchase."""
    products = Product.query.all()
    low_stock = [p for p in products if p.needs_purchase()]
    return jsonify([{
        'id': p.id,
        'name': p.name,
        'stock_quantity': p.stock_quantity,
        'weeks_until_shortage': p.predict_shortage()
    } for p in low_stock])
