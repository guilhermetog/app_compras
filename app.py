from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///products.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Models
class Product(db.Model):
    """
    Product entity with properties:
    - name: product name
    - stock_quantity: current stock quantity
    - weekly_demand: average weekly demand
    - monthly_demand: average monthly demand
    - created_at: creation timestamp
    """
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False, unique=True)
    stock_quantity = db.Column(db.Float, default=0.0)
    weekly_demand = db.Column(db.Float, default=0.0)
    monthly_demand = db.Column(db.Float, default=0.0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    purchase_records = db.relationship('PurchaseRecord', backref='product', lazy=True, cascade='all, delete-orphan')
    price_history = db.relationship('PriceHistory', backref='product', lazy=True, cascade='all, delete-orphan')
    
    def predict_shortage(self):
        """
        Predict if product will run out based on weekly demand and current stock.
        Returns weeks until shortage.
        """
        if self.weekly_demand == 0:
            return None
        weeks_remaining = self.stock_quantity / self.weekly_demand
        return weeks_remaining
    
    def needs_purchase(self, weeks_threshold=2):
        """
        Check if product needs to be purchased based on shortage prediction.
        Default threshold is 2 weeks.
        """
        shortage = self.predict_shortage()
        if shortage is None:
            return False
        return shortage < weeks_threshold
    
    def get_latest_price(self):
        """Get the most recent price from price history."""
        if self.price_history:
            return sorted(self.price_history, key=lambda x: x.recorded_at, reverse=True)[0].price
        return 0.0


class PurchaseRecord(db.Model):
    """
    Purchase record for tracking product purchases.
    """
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey('product.id'), nullable=False)
    quantity = db.Column(db.Float, nullable=False)
    price_per_unit = db.Column(db.Float, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    purchased_at = db.Column(db.DateTime, default=datetime.utcnow)


class PriceHistory(db.Model):
    """
    Price history for tracking product price changes over time.
    """
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey('product.id'), nullable=False)
    price = db.Column(db.Float, nullable=False)
    recorded_at = db.Column(db.DateTime, default=datetime.utcnow)


class ShoppingList(db.Model):
    """
    Shopping list to organize purchases.
    """
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_completed = db.Column(db.Boolean, default=False)
    
    items = db.relationship('ShoppingListItem', backref='shopping_list', lazy=True, cascade='all, delete-orphan')
    
    def calculate_total_budget(self):
        """Calculate total budget for this shopping list."""
        total = 0.0
        for item in self.items:
            product = Product.query.get(item.product_id)
            if product:
                price = product.get_latest_price()
                total += price * item.quantity
        return total


class ShoppingListItem(db.Model):
    """
    Item in a shopping list.
    """
    id = db.Column(db.Integer, primary_key=True)
    shopping_list_id = db.Column(db.Integer, db.ForeignKey('shopping_list.id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('product.id'), nullable=False)
    quantity = db.Column(db.Float, nullable=False)
    
    product = db.relationship('Product')


# Create tables
with app.app_context():
    db.create_all()

# Import routes after models are defined
from routes import *

if __name__ == '__main__':
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    host = os.environ.get('FLASK_HOST', '0.0.0.0')
    port = int(os.environ.get('FLASK_PORT', 5000))
    app.run(debug=debug_mode, host=host, port=port)
