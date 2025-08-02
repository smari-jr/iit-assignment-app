import React, { useState } from 'react';
import { useGaming } from '../contexts/GamingContext';
import { useOrders } from '../contexts/OrdersContext';
import { useAuth } from '../contexts/AuthContext';
import analytics from '../services/analytics';
import './Gaming.css';

const GamingComponent = () => {
  const { products, loading, error, createProduct } = useGaming();
  const { addToCart, cart, getCartItemCount } = useOrders();
  const { user } = useAuth();
  const [showAddProduct, setShowAddProduct] = useState(false);
  const [newProduct, setNewProduct] = useState({
    name: '',
    description: '',
    price: '',
    category: 'action',
    platform: 'pc',
    imageUrl: ''
  });

  const handleAddToCart = (product) => {
    addToCart(product, 1);
    
    // Track add to cart event
    analytics.trackCustomEvent('product', 'add_to_cart', {
      product_id: product.id,
      product_name: product.name,
      product_price: product.price,
      product_category: product.category,
      user_id: user?.id
    });
    
    alert(`${product.name} added to cart!`);
  };

  const handleProductView = (product) => {
    // Track product view event
    analytics.trackCustomEvent('product', 'view', {
      product_id: product.id,
      product_name: product.name,
      product_price: product.price,
      product_category: product.category,
      user_id: user?.id
    });
  };

  const handleCreateProduct = async (e) => {
    e.preventDefault();
    try {
      const productData = {
        ...newProduct,
        price: parseFloat(newProduct.price),
        stock: 100 // Default stock
      };
      
      await createProduct(productData);
      
      // Track product creation event
      analytics.trackCustomEvent('product', 'create', {
        product_name: productData.name,
        product_price: productData.price,
        product_category: productData.category,
        user_id: user?.id
      });
      
      setNewProduct({
        name: '',
        description: '',
        price: '',
        category: 'action',
        platform: 'pc',
        imageUrl: ''
      });
      setShowAddProduct(false);
      alert('Product created successfully!');
    } catch (error) {
      // Track product creation failure
      analytics.trackCustomEvent('product', 'create_failed', {
        error: error.message,
        user_id: user?.id
      });
      
      alert('Failed to create product: ' + error.message);
    }
  };

  const handleProductChange = (e) => {
    setNewProduct({
      ...newProduct,
      [e.target.name]: e.target.value
    });
  };

  if (loading) {
    return <div className="loading">Loading games...</div>;
  }

  if (error) {
    return <div className="error">Error: {error}</div>;
  }

  return (
    <div className="gaming-container">
      <div className="gaming-header">
        <h2>🎮 Gaming Store</h2>
        <div className="header-actions">
          <div className="cart-info">
            Cart: {getCartItemCount()} items
          </div>
          {user && (
            <button 
              onClick={() => setShowAddProduct(true)}
              className="add-product-btn"
            >
              Add New Game
            </button>
          )}
        </div>
      </div>

      {showAddProduct && (
        <div className="modal-overlay">
          <div className="modal">
            <h3>Add New Game</h3>
            <form onSubmit={handleCreateProduct}>
              <div className="form-group">
                <label>Game Name:</label>
                <input
                  type="text"
                  name="name"
                  value={newProduct.name}
                  onChange={handleProductChange}
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Description:</label>
                <textarea
                  name="description"
                  value={newProduct.description}
                  onChange={handleProductChange}
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Price ($):</label>
                <input
                  type="number"
                  name="price"
                  value={newProduct.price}
                  onChange={handleProductChange}
                  step="0.01"
                  min="0"
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Category:</label>
                <select
                  name="category"
                  value={newProduct.category}
                  onChange={handleProductChange}
                >
                  <option value="action">Action</option>
                  <option value="adventure">Adventure</option>
                  <option value="rpg">RPG</option>
                  <option value="strategy">Strategy</option>
                  <option value="sports">Sports</option>
                  <option value="racing">Racing</option>
                  <option value="simulation">Simulation</option>
                </select>
              </div>
              
              <div className="form-group">
                <label>Platform:</label>
                <select
                  name="platform"
                  value={newProduct.platform}
                  onChange={handleProductChange}
                >
                  <option value="pc">PC</option>
                  <option value="ps5">PlayStation 5</option>
                  <option value="xbox">Xbox</option>
                  <option value="switch">Nintendo Switch</option>
                  <option value="mobile">Mobile</option>
                </select>
              </div>
              
              <div className="form-group">
                <label>Image URL:</label>
                <input
                  type="url"
                  name="imageUrl"
                  value={newProduct.imageUrl}
                  onChange={handleProductChange}
                />
              </div>
              
              <div className="modal-actions">
                <button type="submit" className="create-btn">Create Game</button>
                <button 
                  type="button" 
                  onClick={() => setShowAddProduct(false)}
                  className="cancel-btn"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="products-grid">
        {products.length === 0 ? (
          <div className="no-products">
            <p>No games available yet.</p>
            {user && (
              <button 
                onClick={() => setShowAddProduct(true)}
                className="add-first-product-btn"
              >
                Add the First Game
              </button>
            )}
          </div>
        ) : (
          products.map((product) => (
            <div 
              key={product.id} 
              className="product-card"
              onClick={() => handleProductView(product)}
            >
              {product.imageUrl && (
                <img 
                  src={product.imageUrl} 
                  alt={product.name}
                  className="product-image"
                />
              )}
              <div className="product-info">
                <h3>{product.name}</h3>
                <p className="product-description">{product.description}</p>
                <div className="product-details">
                  <span className="category">{product.category}</span>
                  <span className="platform">{product.platform}</span>
                </div>
                <div className="product-footer">
                  <span className="price">${product.price}</span>
                  {user && (
                    <button 
                      onClick={(e) => {
                        e.stopPropagation(); // Prevent triggering product view
                        handleAddToCart(product);
                      }}
                      className="add-to-cart-btn"
                    >
                      Add to Cart
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default GamingComponent;
