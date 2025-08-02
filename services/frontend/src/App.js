import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { GamingProvider } from './contexts/GamingContext';
import { OrdersProvider } from './contexts/OrdersContext';
import Navigation from './components/Navigation';
import Home from './components/Home';
import Auth from './components/Auth';
import Gaming from './components/Gaming';
import Orders from './components/Orders';
import Analytics from './components/Analytics';
import analytics from './services/analytics';
import './App.css';

// Analytics wrapper component to track route changes
function AnalyticsWrapper({ children }) {
  const location = useLocation();

  useEffect(() => {
    // Track page view on route change
    analytics.trackPageView();
  }, [location]);

  return children;
}

function App() {
  useEffect(() => {
    // Initialize analytics when app loads
    console.log('🚀 App initialized with analytics tracking');
    
    // Track app launch event
    analytics.trackCustomEvent('app', 'launch', {
      timestamp: new Date().toISOString(),
      user_agent: navigator.userAgent,
      viewport_size: `${window.innerWidth}x${window.innerHeight}`
    });
  }, []);

  return (
    <AuthProvider>
      <GamingProvider>
        <OrdersProvider>
          <Router>
            <AnalyticsWrapper>
              <div className="App">
                <Navigation />
                <main className="main-content">
                  <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/auth" element={<Auth />} />
                    <Route path="/gaming" element={<Gaming />} />
                    <Route path="/orders" element={<Orders />} />
                    <Route path="/analytics" element={<Analytics />} />
                  </Routes>
                </main>
              </div>
            </AnalyticsWrapper>
          </Router>
        </OrdersProvider>
      </GamingProvider>
    </AuthProvider>
  );
}

export default App;
