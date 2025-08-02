import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import './Home.css';

const Home = () => {
  const { user } = useAuth();

  return (
    <div className="home-container">
      {/* Hero Section */}
      <section className="hero-section">
        <div className="hero-content">
          <h1 className="hero-title">
            Welcome to <span className="gradient-text">GameStore</span>
          </h1>
          <p className="hero-subtitle">
            Discover amazing games, track your orders, and analyze your gaming experience
            with our comprehensive microservices platform.
          </p>
          {user ? (
            <div className="hero-actions">
              <Link to="/gaming" className="cta-button primary">
                🎮 Browse Games
              </Link>
              <Link to="/orders" className="cta-button secondary">
                📦 My Orders
              </Link>
            </div>
          ) : (
            <div className="hero-actions">
              <Link to="/auth" className="cta-button primary">
                🚀 Get Started
              </Link>
              <Link to="/gaming" className="cta-button secondary">
                🎯 Explore Games
              </Link>
            </div>
          )}
        </div>
        <div className="hero-visual">
          <div className="floating-card">
            <div className="card-icon">🎮</div>
            <h3>Gaming Service</h3>
            <p>Discover & Purchase Games</p>
          </div>
          <div className="floating-card">
            <div className="card-icon">📦</div>
            <h3>Order Management</h3>
            <p>Track Your Purchases</p>
          </div>
          <div className="floating-card">
            <div className="card-icon">📊</div>
            <h3>Analytics</h3>
            <p>Monitor Performance</p>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="features-section">
        <div className="section-header">
          <h2>Platform Features</h2>
          <p>Experience the power of modern microservices architecture</p>
        </div>
        
        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">🎯</div>
            <h3>Gaming Marketplace</h3>
            <p>Browse through our extensive collection of games, add them to your cart, and make secure purchases.</p>
            <ul>
              <li>✅ Extensive game catalog</li>
              <li>✅ Secure checkout process</li>
              <li>✅ Real-time inventory</li>
              <li>✅ User reviews & ratings</li>
            </ul>
          </div>

          <div className="feature-card">
            <div className="feature-icon">📦</div>
            <h3>Order Management</h3>
            <p>Track your orders, manage your cart, and handle returns with our comprehensive order system.</p>
            <ul>
              <li>✅ Real-time order tracking</li>
              <li>✅ Order history</li>
              <li>✅ Cart management</li>
              <li>✅ Easy returns process</li>
            </ul>
          </div>

          <div className="feature-card">
            <div className="feature-icon">📊</div>
            <h3>Analytics Dashboard</h3>
            <p>Get insights into your gaming habits, spending patterns, and platform usage with detailed analytics.</p>
            <ul>
              <li>✅ User activity metrics</li>
              <li>✅ Revenue tracking</li>
              <li>✅ Popular games insights</li>
              <li>✅ System health monitoring</li>
            </ul>
          </div>
        </div>
      </section>

      {/* Technology Stack */}
      <section className="tech-section">
        <div className="section-header">
          <h2>Built with Modern Technology</h2>
          <p>Powered by cutting-edge microservices architecture</p>
        </div>
        
        <div className="tech-grid">
          <div className="tech-item">
            <div className="tech-icon">⚛️</div>
            <h4>React Frontend</h4>
            <p>Modern, responsive user interface</p>
          </div>
          <div className="tech-item">
            <div className="tech-icon">🚀</div>
            <h4>Node.js Services</h4>
            <p>Scalable backend microservices</p>
          </div>
          <div className="tech-item">
            <div className="tech-icon">🐘</div>
            <h4>PostgreSQL</h4>
            <p>Reliable data persistence</p>
          </div>
          <div className="tech-item">
            <div className="tech-icon">📈</div>
            <h4>ClickHouse</h4>
            <p>High-performance analytics</p>
          </div>
          <div className="tech-item">
            <div className="tech-icon">🐳</div>
            <h4>Docker</h4>
            <p>Containerized deployment</p>
          </div>
          <div className="tech-item">
            <div className="tech-icon">🔒</div>
            <h4>JWT Auth</h4>
            <p>Secure authentication</p>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="stats-section">
        <div className="stats-grid">
          <div className="stat-item">
            <div className="stat-number">1000+</div>
            <div className="stat-label">Games Available</div>
          </div>
          <div className="stat-item">
            <div className="stat-number">50K+</div>
            <div className="stat-label">Active Users</div>
          </div>
          <div className="stat-item">
            <div className="stat-number">99.9%</div>
            <div className="stat-label">Uptime</div>
          </div>
          <div className="stat-item">
            <div className="stat-number">24/7</div>
            <div className="stat-label">Support</div>
          </div>
        </div>
      </section>

      {/* Call to Action */}
      <section className="cta-section">
        <div className="cta-content">
          <h2>Ready to Start Gaming?</h2>
          <p>Join thousands of gamers who trust our platform for their gaming needs.</p>
          {user ? (
            <div className="cta-actions">
              <Link to="/gaming" className="cta-button primary large">
                🎮 Start Gaming Now
              </Link>
            </div>
          ) : (
            <div className="cta-actions">
              <Link to="/auth" className="cta-button primary large">
                🚀 Create Account
              </Link>
              <Link to="/gaming" className="cta-button secondary large">
                🎯 Browse Games
              </Link>
            </div>
          )}
        </div>
      </section>
    </div>
  );
};

export default Home;
