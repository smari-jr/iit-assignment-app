import React, { useEffect, useState } from 'react';
import { useOrders } from '../contexts/OrdersContext';
import { useAuth } from '../contexts/AuthContext';
import './Orders.css';

const OrdersComponent = () => {
  const { 
    orders, 
    cart, 
    loading, 
    error, 
    loadOrders, 
    createOrder, 
    cancelOrder,
    removeFromCart,
    clearCart,
    getCartTotal,
    getCartItemCount
  } = useOrders();
  const { user } = useAuth();
  const [showCart, setShowCart] = useState(false);
  const [shippingAddress, setShippingAddress] = useState({
    street: '',
    city: '',
    state: '',
    zipCode: '',
    country: 'USA'
  });

  useEffect(() => {
    if (user && user.id) {
      loadOrders();
    }
  }, [user, loadOrders]);

  const handleAddressChange = (e) => {
    setShippingAddress({
      ...shippingAddress,
      [e.target.name]: e.target.value
    });
  };

  const handleCreateOrder = async () => {
    if (cart.length === 0) {
      alert('Your cart is empty!');
      return;
    }

    if (!shippingAddress.street || !shippingAddress.city) {
      alert('Please fill in shipping address!');
      return;
    }

    try {
      const orderData = {
        totalAmount: getCartTotal(),
        currency: 'USD',
        paymentMethod: 'credit_card',
        shippingAddress,
        billingAddress: shippingAddress,
        items: cart
      };

      await createOrder(orderData);
      alert('Order placed successfully!');
      setShowCart(false);
      setShippingAddress({
        street: '',
        city: '',
        state: '',
        zipCode: '',
        country: 'USA'
      });
    } catch (error) {
      alert('Failed to create order: ' + error.message);
    }
  };

  const handleCancelOrder = async (orderId) => {
    if (window.confirm('Are you sure you want to cancel this order?')) {
      try {
        await cancelOrder(orderId);
        alert('Order cancelled successfully!');
      } catch (error) {
        alert('Failed to cancel order: ' + error.message);
      }
    }
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: '#ffc107',
      processing: '#007bff',
      shipped: '#17a2b8',
      delivered: '#28a745',
      cancelled: '#dc3545'
    };
    return colors[status] || '#6c757d';
  };

  if (!user) {
    return (
      <div className="orders-container">
        <div className="no-auth">
          <h2>Please login to view your orders</h2>
          <p>You need to be authenticated to view and manage your orders.</p>
          <p>Please go to the <strong>Auth</strong> tab to login or register.</p>
        </div>
      </div>
    );
  }

  if (loading) {
    return <div className="loading">Loading orders...</div>;
  }

  if (error) {
    return <div className="error">Error: {error}</div>;
  }

  return (
    <div className="orders-container">
      <div className="orders-header">
        <h2>🛒 My Orders</h2>
        <div className="header-actions">
          <button 
            onClick={() => setShowCart(true)}
            className="cart-btn"
            disabled={cart.length === 0}
          >
            Cart ({getCartItemCount()}) - ${getCartTotal().toFixed(2)}
          </button>
        </div>
      </div>

      {/* Cart Modal */}
      {showCart && (
        <div className="modal-overlay">
          <div className="modal">
            <h3>Shopping Cart</h3>
            
            {cart.length === 0 ? (
              <p>Your cart is empty</p>
            ) : (
              <>
                <div className="cart-items">
                  {cart.map((item) => (
                    <div key={item.id} className="cart-item">
                      <div className="item-info">
                        <h4>{item.productName}</h4>
                        <p>Quantity: {item.quantity}</p>
                        <p>Price: ${item.productPrice}</p>
                      </div>
                      <div className="item-actions">
                        <span className="item-total">${item.totalPrice.toFixed(2)}</span>
                        <button 
                          onClick={() => removeFromCart(item.id)}
                          className="remove-btn"
                        >
                          Remove
                        </button>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="cart-total">
                  <strong>Total: ${getCartTotal().toFixed(2)}</strong>
                </div>

                <div className="shipping-form">
                  <h4>Shipping Address</h4>
                  <div className="form-group">
                    <input
                      type="text"
                      name="street"
                      placeholder="Street Address"
                      value={shippingAddress.street}
                      onChange={handleAddressChange}
                      required
                    />
                  </div>
                  <div className="form-row">
                    <input
                      type="text"
                      name="city"
                      placeholder="City"
                      value={shippingAddress.city}
                      onChange={handleAddressChange}
                      required
                    />
                    <input
                      type="text"
                      name="state"
                      placeholder="State"
                      value={shippingAddress.state}
                      onChange={handleAddressChange}
                      required
                    />
                  </div>
                  <div className="form-row">
                    <input
                      type="text"
                      name="zipCode"
                      placeholder="ZIP Code"
                      value={shippingAddress.zipCode}
                      onChange={handleAddressChange}
                      required
                    />
                    <input
                      type="text"
                      name="country"
                      placeholder="Country"
                      value={shippingAddress.country}
                      onChange={handleAddressChange}
                      required
                    />
                  </div>
                </div>
              </>
            )}

            <div className="modal-actions">
              {cart.length > 0 && (
                <>
                  <button onClick={handleCreateOrder} className="checkout-btn">
                    Place Order
                  </button>
                  <button onClick={clearCart} className="clear-cart-btn">
                    Clear Cart
                  </button>
                </>
              )}
              <button onClick={() => setShowCart(false)} className="close-btn">
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Orders List */}
      <div className="orders-list">
        {orders.length === 0 ? (
          <div className="no-orders">
            <p>You haven't placed any orders yet.</p>
            <p>Browse our games and start shopping!</p>
          </div>
        ) : (
          orders.map((order) => (
            <div key={order.id} className="order-card">
              <div className="order-header">
                <div className="order-info">
                  <h3>Order #{order.orderNumber}</h3>
                  <p className="order-date">{formatDate(order.createdAt)}</p>
                </div>
                <div className="order-status">
                  <span 
                    className="status-badge"
                    style={{ backgroundColor: getStatusColor(order.status) }}
                  >
                    {order.status.toUpperCase()}
                  </span>
                </div>
              </div>

              <div className="order-details">
                <div className="order-items">
                  <h4>Items:</h4>
                  {order.items && order.items.map((item) => (
                    <div key={item.id} className="order-item">
                      <span>{item.productName}</span>
                      <span>Qty: {item.quantity}</span>
                      <span>${item.totalPrice}</span>
                    </div>
                  ))}
                </div>

                <div className="order-summary">
                  <div className="total-amount">
                    <strong>Total: ${order.totalAmount}</strong>
                  </div>
                  <div className="payment-info">
                    <span>Payment: {order.paymentStatus}</span>
                    <span>Method: {order.paymentMethod}</span>
                  </div>
                </div>
              </div>

              {order.status === 'pending' && (
                <div className="order-actions">
                  <button 
                    onClick={() => handleCancelOrder(order.id)}
                    className="cancel-order-btn"
                  >
                    Cancel Order
                  </button>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default OrdersComponent;
