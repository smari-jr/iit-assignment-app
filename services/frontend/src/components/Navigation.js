import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useOrders } from '../contexts/OrdersContext';
import './Navigation.css';

const Navigation = () => {
  const { user, logout } = useAuth();
  const { getCartItemCount } = useOrders();
  const location = useLocation();

  const handleLogout = () => {
    logout();
  };

  const isActive = (path) => {
    return location.pathname === path;
  };

  return (
    <nav className="navigation">
      <div className="nav-container">
        {/* Logo */}
        <Link to="/" className="nav-logo">
          <span className="logo-icon">🎮</span>
          <span className="logo-text">GameStore</span>
        </Link>

        {/* Navigation Links */}
        <div className="nav-links">
          <Link 
            to="/" 
            className={`nav-link ${isActive('/') ? 'active' : ''}`}
          >
            <span className="nav-icon">🏠</span>
            Home
          </Link>
          
          <Link 
            to="/gaming" 
            className={`nav-link ${isActive('/gaming') ? 'active' : ''}`}
          >
            <span className="nav-icon">🎯</span>
            Games
          </Link>
          
          <Link 
            to="/orders" 
            className={`nav-link ${isActive('/orders') ? 'active' : ''}`}
          >
            <span className="nav-icon">📦</span>
            Orders
            {getCartItemCount() > 0 && (
              <span className="cart-badge">{getCartItemCount()}</span>
            )}
          </Link>
          
          <Link 
            to="/analytics" 
            className={`nav-link ${isActive('/analytics') ? 'active' : ''}`}
          >
            <span className="nav-icon">📊</span>
            Analytics
          </Link>
        </div>

        {/* User Section */}
        <div className="nav-user">
          {user ? (
            <div className="user-menu">
              <div className="user-info">
                <span className="user-avatar">👤</span>
                <span className="user-name">{user.username || user.email}</span>
              </div>
              <button onClick={handleLogout} className="logout-btn">
                <span className="nav-icon">🚪</span>
                Logout
              </button>
            </div>
          ) : (
            <Link to="/auth" className="login-link">
              <span className="nav-icon">🔐</span>
              Login
            </Link>
          )}
        </div>

        {/* Mobile Menu Toggle */}
        <div className="mobile-menu-toggle">
          <span></span>
          <span></span>
          <span></span>
        </div>
      </div>
    </nav>
  );
};

export default Navigation;
